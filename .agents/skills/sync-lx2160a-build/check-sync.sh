#!/bin/bash
#
# Static consistency checks between the SolidRun reference BSP lx2160a_build and this layer.
# All mappings are read from project-map.md next to this script.
# Network use is limited to 'git ls-remote' (disable with -o); NXP component repositories are never
# cloned or fetched - existing lx2160a_build build/<component> checkouts are used if present.
#
# Output lines start with OK / WARN / FAIL / TODO.
#   FAIL: the layer contradicts a mapping in project-map.md - must be fixed.
#   TODO: lx2160a_build has something project-map.md does not cover (feature omission), or a layer machine
#         has no lx2160a_build counterpart - implement and map it, or list it in SYNC_TODO.md.
#         TODOs are rediscovered on every run until mapped.
#   INFO: findings about lx2160a_build itself (e.g. config options unknown to the kernel) - mention them in the
#         report to the user only; the layer still mirrors lx2160a_build exactly.
# Exit status is 1 if any FAIL was reported, 0 otherwise.
#
set -u

usage() {
	cat <<EOF
Usage: $0 [-s <yocto-sources-dir>] [-o] [-r <since-commit>] <lx2160a_build-dir>

  -s DIR  directory containing meta-qoriq, meta-freescale, ... (e.g. <yocto>/sources);
          enables comparing component base revisions with recipe SRCREVs
  -o      offline: do not query github (git ls-remote) for component release refs
  -r REV  list lx2160a_build commits after REV (default: trailer of the last sync commit)
EOF
	exit 2
}

SOURCES=
OFFLINE=0
SINCE=
while getopts "s:or:h" o; do
	case $o in
	s) SOURCES=$OPTARG ;;
	o) OFFLINE=1 ;;
	r) SINCE=$OPTARG ;;
	*) usage ;;
	esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage

REF=$(cd "$1" && pwd) || exit 2
SKILLDIR=$(cd "$(dirname "$0")" && pwd)
LAYER=$(git -C "$SKILLDIR" rev-parse --show-toplevel) || exit 2
MAP=$SKILLDIR/project-map.md
TODOFILE=$LAYER/SYNC_TODO.md

FAILS=0
WARNS=0
INFOS=0
TODOS=0
TODO_KEYS=()
ok() { echo "OK    $*"; }
info() { echo "INFO  $*"; INFOS=$((INFOS + 1)); }
warn() { echo "WARN  $*"; WARNS=$((WARNS + 1)); }
fail() { echo "FAIL  $*"; FAILS=$((FAILS + 1)); }
# todo <key> <message>: SYNC_TODO.md must have an item **<key>**
todo() { echo "TODO  $2"; TODOS=$((TODOS + 1)); TODO_KEYS+=("$1"); }
section() { echo; echo "== $*"; }

# print rows of table <name> from project-map.md, cells separated by TAB
map() {
	awk -v name="$1" '
	index($0, "<!-- map:" name " -->") { on = 1; n = 0; next }
	on && index($0, "<!-- /map -->") { on = 0 }
	on && /^\|/ {
		n++; if (n <= 2) next
		gsub(/`/, ""); line = $0
		sub(/^\|/, "", line); sub(/\|[ \t]*$/, "", line)
		k = split(line, c, "|"); out = ""
		for (i = 1; i <= k; i++) { gsub(/^[ \t]+|[ \t]+$/, "", c[i]); out = out (i > 1 ? "\t" : "") c[i] }
		print out
	}' "$MAP"
}

param() { map parameters | awk -F'\t' -v k="$1" '$1 == k { print $2 }'; }

###############################################################################
section "Branch parameters"
SERIES=$(param yocto_series)
COMPAT_VAR=$(param layer_compat)
REF_BRANCH=$(param reference_branch)
NXP_RELEASE=$(param nxp_release)
MC_RELEASE=$(param mc_release)
compat=$(sed -n "s/^${COMPAT_VAR}[ \t]*=[ \t]*\"\(.*\)\"/\1/p" "$LAYER/conf/layer.conf")
if [ "$compat" = "$SERIES" ]; then
	ok "layer series $compat matches skill series $SERIES"
else
	fail "layer series '$compat' != skill series '$SERIES': this skill copy belongs to another branch, stop"
	exit 1
fi

###############################################################################
section "lx2160a_build checkout"
ubranch=$(git -C "$REF" rev-parse --abbrev-ref HEAD)
uhead=$(git -C "$REF" rev-parse HEAD)
echo "      $REF @ $ubranch $uhead"
[ "$ubranch" = "$REF_BRANCH" ] && ok "branch $ubranch" || fail "lx2160a_build branch is '$ubranch', expected '$REF_BRANCH'"
if [ -n "$(git -C "$REF" status --porcelain --untracked-files=no)" ]; then
	warn "lx2160a_build checkout has uncommitted changes to tracked files"
fi
if behind=$(git -C "$REF" rev-list --count HEAD..@{u} 2>/dev/null); then
	[ "$behind" = 0 ] && ok "up to date with last fetch of @{u}" || warn "lx2160a_build checkout is $behind commits behind @{u} - pull first"
fi

###############################################################################
# classify <lx2160a_build path>: prints "<kind>\t<detail>"
#   kind: patches | file | kconfig | n/a | review | unmapped
PATCH_ROWS=$(map patches)
FILE_ROWS=$(map files)
NA_ROWS=$(map not-applicable)
classify() {
	local f=$1 a b c
	while IFS=$'\t' read -r a b c; do
		[[ $f == "$a"/* ]] && { printf 'patches\t%s\n' "$a"; return; }
	done <<<"$PATCH_ROWS"
	while IFS=$'\t' read -r a b c; do
		# shellcheck disable=SC2053 # glob match intended
		[[ $f == $a ]] && { printf 'file\t%s\n' "$b"; return; }
	done <<<"$FILE_ROWS"
	[ "$f" = configs/linux/lx2k_additions.config ] && { printf 'kconfig\t%s\n' "$f"; return; }
	while IFS=$'\t' read -r a b c; do
		# shellcheck disable=SC2053 # glob match intended
		[[ $f == $a ]] && { printf '%s\t%s\n' "$b" "$c"; return; }
	done <<<"$NA_ROWS"
	printf 'unmapped\t\n'
}

section "Sync range"
if [ -z "$SINCE" ]; then
	SINCE=$(git -C "$LAYER" log -1 --format=%B --grep='^lx2160a_build: ' |
		sed -n 's/^lx2160a_build: .* @ \([0-9a-f]\{7,40\}\)$/\1/p' | tail -1)
	[ -n "$SINCE" ] && echo "      last sync trailer: $SINCE"
fi
if [ -z "$SINCE" ]; then
	warn "no 'lx2160a_build: <branch> @ <sha>' trailer found in layer history; pass -r <since-commit>"
elif ! git -C "$REF" rev-parse -q --verify "$SINCE^{commit}" >/dev/null; then
	fail "since-commit $SINCE not found in lx2160a_build checkout"
else
	count=$(git -C "$REF" rev-list --count "$SINCE..HEAD")
	echo "      $count lx2160a_build commits in $SINCE..HEAD:"
	git -C "$REF" log --reverse --format='%h' "$SINCE..HEAD" | while read -r h; do
		kinds=$(git -C "$REF" diff-tree --no-commit-id --name-only -r "$h" | while read -r p; do
			IFS=$'\t' read -r k d < <(classify "$p")
			case $k in
			patches) echo "$d" ;;
			file | kconfig) echo "$p" ;;
			*) echo "$k:$p" ;;
			esac
		done | sort -u | tr '\n' ' ')
		echo "      $(git -C "$REF" log -1 --format='%h %ad %s' --date=short "$h")"
		echo "            -> $kinds"
	done
fi

###############################################################################
section "lx2160a_build file coverage"
uncovered=0
while read -r f; do
	IFS=$'\t' read -r k d < <(classify "$f")
	case $k in
	unmapped) todo "$f" "lx2160a_build file $f is not in project-map.md"; uncovered=$((uncovered + 1)) ;;
	n/a | review | patches | file | kconfig) ;;
	*) fail "project-map.md not-applicable row for $f has unknown kind '$k'" ;;
	esac
done < <(git -C "$REF" ls-tree -r --name-only HEAD)
[ $uncovered = 0 ] && ok "every tracked lx2160a_build file is mapped"

###############################################################################
section "Patches"
while IFS=$'\t' read -r updir ldir bbappend; do
	ups=$(cd "$REF/$updir" && ls -1 -- *.patch 2>/dev/null)
	los=$(cd "$LAYER/$ldir" && ls -1 -- *.patch 2>/dev/null)
	refs=$(grep -o 'file://[^ "\\]*\.patch' "$LAYER/$bbappend" | sed 's|file://||')
	bad=0
	for p in $(comm -23 <(echo "$ups") <(echo "$los")); do fail "$updir/$p missing in $ldir"; bad=1; done
	for p in $(comm -13 <(echo "$ups") <(echo "$los")); do fail "$ldir/$p not in lx2160a_build $updir"; bad=1; done
	for p in $(comm -12 <(echo "$ups") <(echo "$los")); do
		cmp -s "$REF/$updir/$p" "$LAYER/$ldir/$p" || { fail "$ldir/$p differs from lx2160a_build"; bad=1; }
	done
	if [ "$refs" != "$ups" ]; then
		fail "$bbappend SRC_URI patch list differs from lx2160a_build $updir (order or content):"
		diff <(echo "$ups") <(echo "$refs") | sed -n 's/^\([<>]\)/            \1/p'
		bad=1
	fi
	[ $bad = 0 ] && ok "$updir: $(echo "$ups" | grep -c .) patches identical and referenced in order"
done <<<"$PATCH_ROWS"

###############################################################################
section "Byte-identical files"
# rows may use one '*' in both columns: configs/linux/*.rules -> recipes-core/udev/files/*
REF_FILES=$(git -C "$REF" ls-tree -r --name-only HEAD)
while IFS=$'\t' read -r pat lpat ref; do
	matched=0
	while IFS= read -r upf; do
		# shellcheck disable=SC2053 # glob match intended
		[[ $upf == $pat ]] || continue
		matched=1
		if [[ $pat == *'*'* ]]; then
			lf=${lpat%%\**}${upf#"${pat%%\**}"}
		else
			lf=$lpat
		fi
		if [ ! -f "$LAYER/$lf" ]; then
			fail "$lf missing (copy of lx2160a_build $upf)"
		elif ! cmp -s "$REF/$upf" "$LAYER/$lf"; then
			fail "$lf differs from lx2160a_build $upf"
		elif ! grep -qF "$(basename "$lf")" "$LAYER/$ref"; then
			fail "$lf not referenced in $ref"
		else
			ok "$lf"
		fi
	done <<<"$REF_FILES"
	[ $matched = 0 ] && warn "project-map.md files row $pat matches no lx2160a_build file"
done <<<"$FILE_ROWS"

###############################################################################
section "Kernel configuration"
KDIR=$LAYER/recipes-kernel/linux/6.6-solidrun
KBB=$LAYER/recipes-kernel/linux/linux-qoriq_6.6.bbappend
KMAP=$(map kconfig)
# "<block>\t<CONFIG_NAME>\t<line>" for each option of lx2160a_build config
kopts() {
	awk '
	BEGIN { b = "(start)" }
	/^[ \t]*$/ { next }
	/^# CONFIG_[A-Za-z0-9_]+ is not set/ { print b "\t" $2 "\t" $0; next }
	/^CONFIG_/ { split($0, a, "="); print b "\t" a[1] "\t" $0; next }
	/^#/ { b = $0; sub(/^#[ \t]*/, "", b); sub(/[ \t]+$/, "", b); next }
	{ print "?\t?\t" $0 }' "$1"
}
UPK=$(kopts "$REF/configs/linux/lx2k_additions.config")
# fragment name derived from a block comment: lowercase, non-alphanumerics replaced by single dashes
slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-//' -e 's/-$//'; }
# "<block>\t<fragment>": exception from the kconfig table, otherwise derived from the comment
KBLK=$(echo "$UPK" | cut -f1 | awk '!s[$0]++ && $0 != "?"' | while IFS= read -r blk; do
	fr=$(echo "$KMAP" | awk -F'\t' -v b="$blk" '$1 == b { print $2 }')
	printf '%s\t%s\n' "$blk" "${fr:-$(slug "$blk")}"
done)
# all block comments, including ones directly followed by another comment (they hold no options)
KCOMMENTS=$( { echo "(start)"; grep '^#' "$REF/configs/linux/lx2k_additions.config" |
	grep -vE '^# CONFIG_[A-Za-z0-9_]+ is not set' | sed -e 's/^#[ \t]*//' -e 's/[ \t]*$//'; })
while IFS=$'\t' read -r b fr; do
	echo "$KCOMMENTS" | grep -qxF -- "$b" || warn "project-map.md kconfig row '$b' no longer exists in lx2160a_build"
done <<<"$KMAP"
bad=0
for frag in $(echo "$KBLK" | cut -f2 | sort -u); do
	expected=$(while IFS=$'\t' read -r b fr; do
		[ "$fr" = "$frag" ] && echo "$UPK" | awk -F'\t' -v b="$b" '$1 == b { print $3 }'
	done <<<"$KBLK" | sort -u)
	if [ ! -f "$KDIR/$frag.cfg" ]; then
		fail "fragment $frag.cfg missing (block(s) $(echo "$KBLK" | awk -F'\t' -v f="$frag" '$2 == f { printf "%s\"# %s\"", (n++ ? ", " : ""), $1 }')):"
		echo "$expected" | sed 's/^/            + /'
		bad=1
		continue
	fi
	actual=$(kopts "$KDIR/$frag.cfg" | cut -f3 | sort -u)
	missing=$(comm -23 <(echo "$expected") <(echo "$actual"))
	extra=$(comm -13 <(echo "$expected") <(echo "$actual"))
	[ -n "$missing" ] && { fail "$frag.cfg lacks lx2160a_build options:"; echo "$missing" | sed 's/^/            + /'; bad=1; }
	[ -n "$extra" ] && { fail "$frag.cfg has options not in its lx2160a_build blocks:"; echo "$extra" | sed 's/^/            - /'; bad=1; }
	[ -f "$KDIR/$frag.scc" ] || { fail "$frag.scc missing"; bad=1; }
	for pat in "file://$frag.scc" "file://$frag.cfg" "DELTA_KERNEL_DEFCONFIG:append = \" $frag.cfg \""; do
		grep -qF "$pat" "$KBB" || { fail "linux-qoriq_6.6.bbappend lacks: $pat"; bad=1; }
	done
done
for f in "$KDIR"/*.cfg; do
	frag=$(basename "$f" .cfg)
	echo "$KBLK" | cut -f2 | grep -qxF "$frag" || warn "layer-only kernel fragment $frag.cfg (no lx2160a_build block)"
done
[ $bad = 0 ] && ok "kernel config blocks match fragments"

# report lx2160a_build config options that the patched source tree does not define (needs build/<src> checkout)
unknown_options() {
	local src=$REF/build/$1 cfg=$REF/$2 syms
	if [ ! -d "$src/.git" ]; then
		echo "      skipped: no build/$1 checkout, validity of $2 options not checked (do not clone it for this)"
		return
	fi
	syms=$(git -C "$src" grep -hoE '^[[:space:]]*(menu)?config[[:space:]]+[A-Za-z0-9_]+' -- '*Kconfig*' |
		awk '{ print "CONFIG_" $2 }' | sort -u)
	kopts "$cfg" | cut -f2 | grep '^CONFIG_' | sort -u | comm -23 - <(echo "$syms") | while read -r o; do
		info "$2: $o is not defined in build/$1 ($(git -C "$src" describe --tags --always)) - copied anyway"
	done
}
unknown_options linux configs/linux/lx2k_additions.config
unknown_options u-boot configs/u-boot/lx2k_additions.config

###############################################################################
section "runme.sh TARGET -> MACHINE"
# "<label>\t<VAR>\t<value>" for each assignment, "<label>\t\t" for each label
TGT=$(awk '
	/case "\$\{TARGET\}" in/ { on = 1; next }
	on && /^[ \t]*esac/ { exit }
	!on { next }
	/^[ \t]*#/ || /^[ \t]*;;/ { next }
	/^[ \t]*[^ \t=]+\)[ \t]*$/ {
		l = $0; gsub(/[ \t)]/, "", l); n = split(l, labels, "|")
		for (i = 1; i <= n; i++) print labels[i] "\t\t"
		next
	}
	/^[ \t]*[A-Z_0-9]+=/ {
		v = $0; sub(/^[ \t]*/, "", v); var = v; sub(/=.*/, "", var); sub(/^[^=]*=/, "", v)
		sub(/[ \t]+#.*$/, "", v); gsub(/"/, "", v)
		for (i = 1; i <= n; i++) print labels[i] "\t" var "\t" v
	}' "$REF/runme.sh")
TMAP=$(map targets)

# print "VAR\tvalue" as evaluated from a machine conf and the layer includes it requires
machine_vars() {
	expand() {
		local line inc
		while IFS= read -r line; do
			if [[ $line =~ ^(require|include)[[:space:]]+(conf/machine/[^[:space:]]+) ]]; then
				inc=$LAYER/${BASH_REMATCH[2]}
				[ -f "$inc" ] && expand <"$inc"
			else
				printf '%s\n' "$line"
			fi
		done
	}
	expand <"$LAYER/conf/machine/$1.conf" | awk '
	/^[ \t]*#/ { next }
	match($0, /^[ \t]*[A-Za-z0-9_]+(\[[a-z0-9-]+\])?[ \t]*(\?\?=|\?=|=)/) {
		s = substr($0, 1, RLENGTH); v = substr($0, RLENGTH + 1)
		var = s; sub(/[ \t]*(\?\?=|\?=|=)$/, "", var); gsub(/[ \t]/, "", var)
		op = s; sub(/^[^?=]*/, "", op)
		gsub(/^[ \t]*"|"[ \t]*$/, "", v)
		if (op == "=" || !(var in val)) val[var] = v
	}
	END { for (k in val) print k "\t" val[k] }'
}

while IFS= read -r label; do
	[ "$label" = "*" ] && continue
	row=$(echo "$TMAP" | awk -F'\t' -v l="$label" '$1 == l')
	if [ -z "$row" ]; then
		todo "$label" "runme.sh TARGET $label is not in project-map.md"
		continue
	fi
	machines=$(echo "$row" | cut -f2)
	note=$(echo "$row" | cut -f3)
	if [ "$machines" = n/a ]; then
		if [ -z "$note" ]; then
			fail "TARGET $label is n/a without a reason"
		else
			ok "TARGET $label n/a: $note"
		fi
		continue
	fi
	for m in $machines; do
		if [ ! -f "$LAYER/conf/machine/$m.conf" ]; then
			fail "TARGET $label: machine $m.conf does not exist"
			continue
		fi
		mv=$(machine_vars "$m")
		mget() { echo "$mv" | awk -F'\t' -v k="$1" '$1 == k { print $2 }'; }
		rget() { echo "$TGT" | awk -F'\t' -v l="$label" -v k="$1" '$1 == l && $2 == k { print $3 }'; }
		diffs=
		for pair in ATF_PLATFORM:ATF_PLATFORM DPC:MC_DPC DPL:MC_DPL DEFAULT_FDT_FILE:UBOOT_FDT_FILE \
			UBOOT_FDT:UBOOT_FDT UBOOT_ETHPRIME:UBOOT_ETHPRIME UBOOT_DEFCONFIG:"UBOOT_CONFIG[tfa]"; do
			rv=$(rget "${pair%%:*}")
			[ -z "$rv" ] && continue
			yv=$(mget "${pair#*:}")
			[ "${pair#*:}" = "UBOOT_CONFIG[tfa]" ] && yv=${yv%%,*}
			[ "$rv" = "$yv" ] || diffs="$diffs ${pair%%:*}='$rv'/${pair#*:}='$yv'"
		done
		rv=$(rget ATF_DISABLE_S5)
		yv=$(mget ATF_DISABLE_S5)
		[ "${rv:-0}" = "${yv:-0}" ] || diffs="$diffs ATF_DISABLE_S5='${rv:-0}'/'${yv:-0}'"
		# SerDes protocols of the label (fields 4-6, '*' = any) must be what the machine's RCW builds
		lserdes=$(echo "$label" | cut -d_ -f4-6)
		for rcwvar in RCWAUTO RCWSD RCWEMMC RCWXSPI; do
			rcw=$(mget $rcwvar)
			[ -z "$rcw" ] && continue
			mserdes=$(echo "$rcw" | sed -n 's/.*_\([0-9A-Z]*_[0-9]*_[0-9]*\)_[a-z]*$/\1/p')
			# shellcheck disable=SC2053 # label may contain a glob
			[[ $mserdes == $lserdes ]] || diffs="$diffs SerDes='$lserdes'/$rcwvar='$mserdes'"
		done
		if [ -n "$diffs" ]; then
			fail "TARGET $label vs $m:$diffs"
		else
			ok "TARGET $label -> $m"
		fi
	done
done < <(echo "$TGT" | cut -f1 | awk '!s[$0]++')
while IFS= read -r label; do
	echo "$TGT" | cut -f1 | grep -qxF -- "$label" || warn "project-map.md TARGET row $label no longer exists in runme.sh"
done < <(echo "$TMAP" | cut -f1)
MMAP=$(map machines)
for f in "$LAYER"/conf/machine/*.conf; do
	m=$(basename "$f" .conf)
	echo "$TMAP" | cut -f2 | tr ' ' '\n' | grep -qxF "$m" && continue
	echo "$MMAP" | cut -f1 | grep -qxF "$m" && { ok "machine $m without TARGET: $(echo "$MMAP" | awk -F'\t' -v m="$m" '$1 == m { print $2 }')"; continue; }
	todo "$m" "layer machine $m is not covered by any runme.sh TARGET row (RCW: $(machine_vars "$m" | awk -F'\t' '$1 ~ /^RCW(AUTO|SD)$/ { printf "%s ", $2 }'))"
done

###############################################################################
section "runme.sh options"
OMAP=$(map options)
# trace_option <VAR>: print every runme.sh line using VAR, and for each 'case' or 'if' statement on VAR
# the case labels and the variables assigned in it ("derived variables"), plus every line using those
trace_option() {
	local opt=$1 derived d labels
	grep -nE "\\\$\{?$opt\b" "$REF/runme.sh" | sed 's/^/            /'
	derived=$(awk -v o="$opt" '
		!on && $0 ~ "^[ \t]*(case|if) .*\\$\\{?" o "([^A-Za-z0-9_]|$)" { on = 1; depth = 0; next }
		on && /^[ \t]*(case|if) / { depth++ }
		on && /^[ \t]*(esac|fi)([ \t;]|$)/ { if (depth == 0) on = 0; else depth--; next }
		on && /^[ \t]*[^ \t=]+\)[ \t]*$/ { l = $0; gsub(/[ \t]/, "", l); print "label\t" l; next }
		on && /^[ \t]*[A-Z_0-9]+=/ { v = $0; sub(/^[ \t]*/, "", v); sub(/=.*/, "", v); print "var\t" v }
	' "$REF/runme.sh")
	[ -z "$derived" ] && return
	labels=$(echo "$derived" | awk -F'\t' '$1 == "label" { printf "%s ", $2 }')
	[ -n "$labels" ] && echo "            case labels: $labels"
	for d in $(echo "$derived" | awk -F'\t' '$1 == "var" && !s[$2]++ { print $2 }'); do
		echo "            derived $d:"
		grep -nE "\\\$\{?$d\b" "$REF/runme.sh" | sed 's/^/                /'
	done
}
# "<VAR>\t<default>" for each ': ${VAR:=default}' line
OPTS=$(sed -n 's/^:[ \t]*\${\([A-Za-z0-9_]*\):=\(.*\)}[ \t]*$/\1\t\2/p' "$REF/runme.sh")
while IFS=$'\t' read -r opt def; do
	row=$(echo "$OMAP" | awk -F'\t' -v o="$opt" '$1 == o')
	if [ -z "$row" ]; then
		todo "$opt" "runme.sh option $opt (default '$def') has no counterpart in project-map.md; trace:"
		trace_option "$opt"
		continue
	fi
	var=$(echo "$row" | cut -f2)
	why=$(echo "$row" | cut -f3)
	if [ -z "$why" ]; then
		fail "option $opt row has no counterpart / reason"
	elif [ -n "$var" ] && [ "$var" != - ] && ! grep -rqw --include='*.conf' --include='*.inc' --include='*.bb' \
		--include='*.bbappend' --include='*.wks*' -- "$var" "$LAYER/conf" "$LAYER"/recipes-* "$LAYER/wic"; then
		fail "option $opt: layer variable $var is not used anywhere in the layer"
	else
		ok "option $opt: $why"
	fi
done <<<"$OPTS"
while IFS= read -r opt; do
	echo "$OPTS" | cut -f1 | grep -qxF -- "$opt" || warn "project-map.md option row $opt no longer exists in runme.sh"
done < <(echo "$OMAP" | cut -f1)

###############################################################################
section "Component base revisions"
COMPONENTS=$(sed -n 's/^QORIQ_COMPONENTS="\(.*\)"/\1/p' "$REF/runme.sh")
CMAP=$(map components)
for c in $COMPONENTS; do
	echo "$CMAP" | cut -f1 | grep -qxF "$c" || todo "$c" "runme.sh component $c is not in project-map.md"
done
rel=$(sed -n 's/^: \${RELEASE:=\(.*\)}/\1/p' "$REF/runme.sh")
[ "${rel/ls/lf}" = "$NXP_RELEASE" ] || fail "runme.sh RELEASE ${rel/ls/lf} != nxp_release $NXP_RELEASE (BSP rebase? fork the skill)"
grep -q "CHECKOUT=$MC_RELEASE" "$REF/runme.sh" || fail "runme.sh no longer checks out $MC_RELEASE for mc components"
if grep -qE '^[[:space:]]*COMMIT=[0-9a-f]' "$REF/runme.sh"; then
	warn "runme.sh pins some component to a COMMIT - review the clone logic manually:"
	grep -nE '^[[:space:]]*COMMIT=[0-9a-f]' "$REF/runme.sh" | sed 's/^/            /'
fi

if [ -z "$SOURCES" ]; then
	warn "no -s <yocto-sources-dir> given: recipe SRCREVs not compared"
else
	# layers as "<priority>\t<dir>", this layer instead of any other copy of it
	LAYERS=$(
		{
			echo "$LAYER/conf/layer.conf"
			find "$SOURCES" -maxdepth 4 -path '*/conf/layer.conf' | grep -v '/meta-solidrun-arm-lx2xxx/'
		} | while read -r lc; do
			p=$(sed -n 's/^BBFILE_PRIORITY_[^ =]*[ \t]*=[ \t]*"\([0-9]*\)".*/\1/p' "$lc" | head -1)
			printf '%s\t%s\n' "${p:-0}" "$(dirname "$(dirname "$lc")")"
		done | sort -rn
	)
	# effective_srcrev <recipe> <var>: highest-priority bbappend with hard '=', else .bb/.inc
	effective_srcrev() {
		local r=$1 v=$2 kind prio dir f val
		for kind in bbappend bb; do
			while IFS=$'\t' read -r prio dir; do
				if [ $kind = bbappend ]; then
					files=$(find "$dir" -name "${r}_*.bbappend" -o -name "${r}.bbappend" 2>/dev/null)
				else
					files=$(find "$dir" \( -name "${r}_*.bb" -o -name "${r}.bb" -o -name "${r}*.inc" \) 2>/dev/null)
				fi
				for f in $files; do
					val=$(sed -n "s/^[ \t]*${v}[ \t]*=[ \t]*\"\([0-9a-f]\{40\}\)\".*/\1/p" "$f" | tail -1)
					[ -n "$val" ] && { printf '%s\t%s\n' "$val" "${f#"$SOURCES"/}"; return; }
				done
			done <<<"$LAYERS"
		done
	}
	while IFS=$'\t' read -r comp ref recipe var; do
		read -r yrev yfile < <(effective_srcrev "$recipe" "$var" | tr '\t' ' ')
		npatch=$(ls "$REF/patches/$comp/"*.patch 2>/dev/null | wc -l)
		lrev=
		if [ -d "$REF/build/$comp/.git" ]; then
			lrev=$(git -C "$REF/build/$comp" rev-parse -q --verify "HEAD~$npatch" 2>/dev/null)
		fi
		rrev=
		if [ $OFFLINE = 0 ]; then
			# git clone -b accepts tags and branches; nxp-qoriq release names are usually tags
			refs=$(git ls-remote "https://github.com/nxp-qoriq/$comp" "refs/tags/$ref^{}" "refs/tags/$ref" "refs/heads/$ref" 2>/dev/null)
			rrev=$(echo "$refs" | awk -v r="refs/tags/$ref^{}" '$2 == r { print $1 }')
			[ -z "$rrev" ] && rrev=$(echo "$refs" | awk -v r="refs/tags/$ref" '$2 == r { print $1 }')
			[ -z "$rrev" ] && rrev=$(echo "$refs" | awk -v r="refs/heads/$ref" '$2 == r { print $1 }')
			[ -z "$rrev" ] && warn "$comp: could not resolve $ref on github"
		fi
		if [ -z "$yrev" ]; then
			todo "$comp" "$comp: no SRCREV found for recipe $recipe ($var) - check with bitbake-getvar"
			continue
		fi
		msg="$comp: $recipe $var=${yrev:0:12} ($yfile)"
		bad=
		[ -n "$rrev" ] && [ "$rrev" != "$yrev" ] && bad="$bad github $ref=${rrev:0:12}"
		[ -n "$lrev" ] && [ "$lrev" != "$yrev" ] && bad="$bad build/$comp base=${lrev:0:12}"
		if [ -n "$bad" ]; then
			todo "$comp" "$msg differs from lx2160a_build:$bad"
		elif [ -z "$rrev$lrev" ]; then
			warn "$msg - no lx2160a_build base revision to compare (offline and no build/$comp checkout; run without -o)"
		else
			ok "$msg"
		fi
	done <<<"$CMAP"
fi

###############################################################################
section "Layer dependencies"
# Every layer providing something this layer uses (bbappend base recipes, required/included files,
# DEPENDS/RDEPENDS/IMAGE_INSTALL/[depends] entries) must be listed in LAYERDEPENDS_<collection>.
# A reference is satisfied if any listed layer provides it; otherwise the highest-priority provider is named.
COLL=$(sed -n 's/^BBFILE_COLLECTIONS[ \t]*+=[ \t]*"[ \t]*\([^ "]*\).*/\1/p' "$LAYER/conf/layer.conf")
LDEPS=$(sed -n "s/^LAYERDEPENDS_${COLL}[ \t]*=[ \t]*\"\(.*\)\"/\1/p" "$LAYER/conf/layer.conf" | tr ' ' '\n' |
	sed 's/:.*//' | grep .)
if [ -z "$SOURCES" ]; then
	warn "no -s <yocto-sources-dir> given: LAYERDEPENDS_${COLL} not checked"
else
	# "<priority>\t<collection>\t<dir>" of all other layers
	OTHER=$(find "$SOURCES" -maxdepth 4 -path '*/conf/layer.conf' | grep -v '/meta-solidrun-arm-lx2xxx/' |
		while read -r lc; do
			c=$(sed -n 's/^BBFILE_COLLECTIONS[ \t]*+=[ \t]*"[ \t]*\([^ "]*\).*/\1/p' "$lc" | head -1)
			p=$(sed -n 's/^BBFILE_PRIORITY_[^ =]*[ \t]*=[ \t]*"\([0-9]*\)".*/\1/p' "$lc" | head -1)
			[ -n "$c" ] && printf '%s\t%s\t%s\n' "${p:-0}" "$c" "$(dirname "$(dirname "$lc")")"
		done | sort -rn)
	# recipe index "<recipe file basename without .bb>\t<collection>"
	RIDX=$(while IFS=$'\t' read -r p c d; do
		find "$d" -name '*.bb' -printf "%f\t$c\n" | sed 's/\.bb\t/\t/'
	done <<<"$OTHER")
	LOCAL_RECIPES=$(find "$LAYER"/recipes-* -name '*.bb' -printf '%f\n' | sed 's/\.bb$//')
	# providers <match>: collections (priority order) providing a recipe; <match> is an awk condition on $1
	providers() { echo "$RIDX" | awk -F'\t' "$1 { print \$2 }" | awk '!s[$0]++'; }
	# need <reference description> <providers>: satisfied if any provider is listed
	USED=
	REPORTED=
	need() {
		local what=$1 provs=$2 c
		[ -z "$provs" ] && { warn "layer dependencies: no provider found for $what"; return; }
		for c in $provs; do
			echo "$LDEPS" | grep -qxF "$c" && { USED="$USED $c"; return; }
		done
		c=$(echo "$provs" | head -1)
		# report each missing layer once per referenced item
		case "$REPORTED" in *"|$c $what|"*) return ;; esac
		REPORTED="$REPORTED|$c $what|"
		fail "LAYERDEPENDS_${COLL} lacks '$c', which provides $what"
		USED="$USED $c"
	}
	nfail=$FAILS
	# 1. bbappends need their base recipe
	while IFS= read -r f; do
		b=$(basename "$f" .bbappend)
		case $b in
		*_%) cond="index(\$1, \"${b%\%}\") == 1" ;;
		*_*) cond="\$1 == \"$b\"" ;;
		*) cond="\$1 == \"$b\" || index(\$1, \"${b}_\") == 1" ;;
		esac
		need "the base recipe of ${f#"$LAYER"/}" "$(providers "$cond")"
	done < <(find "$LAYER"/recipes-* -name '*.bbappend')
	# 2. required/included files, searched in the other layers (BBPATH)
	while IFS=$'\t' read -r f inc; do
		[ -f "$LAYER/$inc" ] && continue
		provs=$(while IFS=$'\t' read -r p c d; do [ -f "$d/$inc" ] && echo "$c"; done <<<"$OTHER")
		need "$inc (required by ${f#"$LAYER"/})" "$provs"
	done < <(grep -rHE '^[[:space:]]*(require|include)[[:space:]]+[^ $]+/[^ ]+' "$LAYER/conf" "$LAYER"/recipes-* \
		--include='*.bb' --include='*.bbappend' --include='*.inc' --include='*.conf' |
		sed -E 's/^([^:]*):[[:space:]]*(require|include)[[:space:]]+([^ ]+).*/\1\t\3/')
	# 3. recipes named in dependency variables (packages are mapped to their recipe by dropping -suffixes)
	while IFS=$'\t' read -r f tok; do
		n=${tok%%:*}
		case $n in '' | *'$'* | virtual/* | *'}'* | *'{'*) continue ;; esac
		# try the full name first (e.g. kern-tools-native_git.bb), then without -native / -suffixes
		first=1
		while :; do
			echo "$LOCAL_RECIPES" | grep -qE "^${n}(_|$)" && continue 2
			provs=$(providers "\$1 == \"$n\" || index(\$1, \"${n}_\") == 1")
			[ -n "$provs" ] && break
			[ "${n%-*}" = "$n" ] && break
			if [ $first = 1 ] && [ "${n%-native}" != "$n" ]; then n=${n%-native}; else n=${n%-*}; fi
			first=0
		done
		need "$n (from ${f#"$LAYER"/})" "$provs"
	done < <(find "$LAYER/conf" "$LAYER"/recipes-* \( -name '*.bb' -o -name '*.bbappend' -o -name '*.inc' -o -name '*.conf' \) |
		while read -r f; do
			awk -v f="$f" '
				# join continuation lines
				{ while (/\\$/ && (getline nxt) > 0) { sub(/\\$/, " "); $0 = $0 nxt } }
				/^[[:space:]]*#/ || /LAYERDEPENDS/ { next }
				/^[[:space:]]*([A-Za-z_]*DEPENDS|RDEPENDS|IMAGE_INSTALL)[A-Za-z0-9_:${}-]*[[:space:]]*(\+=|=|\?=|:append[^=]*=|\.=|=\.)/ ||
				/\[depends\]/ {
					v = $0; sub(/^[^"]*"/, "", v); sub(/".*$/, "", v)
					n = split(v, t, /[ \t]+/)
					for (i = 1; i <= n; i++) if (t[i] != "") print f "\t" t[i]
				}' "$f"
		done | sort -u)
	[ $FAILS = "$nfail" ] && ok "LAYERDEPENDS_${COLL} covers every layer used"
	for c in $LDEPS; do
		echo "$USED" | tr ' ' '\n' | grep -qxF "$c" ||
			warn "LAYERDEPENDS_${COLL} lists '$c', but nothing in this layer uses it"
	done
fi

###############################################################################
section "Layer working tree"
if out=$(git -C "$LAYER" diff --check HEAD -- . ':!*.patch'); then
	ok "no whitespace errors in uncommitted changes (patches excluded)"
else
	fail "whitespace errors:"
	echo "$out" | sed 's/^/            /'
fi

section "SYNC_TODO.md"
# the file always exists and keeps its header; no "- [ ]" items means no open points
if [ ! -f "$TODOFILE" ]; then
	fail "SYNC_TODO.md does not exist - it must always exist (with an empty list when there are no open points)"
else
	head -n 1 "$TODOFILE" | grep -qxF '# Sync TODO: lx2160a_build' ||
		warn "SYNC_TODO.md title must be exactly '# Sync TODO: lx2160a_build' (shas belong in '##' sections)"
	head -n 8 "$TODOFILE" | grep -q 'LLM agent' ||
		warn "SYNC_TODO.md lacks the note that it is generated and maintained by an LLM agent (see SKILL.md)"
	items=$(grep -c '^[[:space:]]*- \[ \]' "$TODOFILE")
	# '##' sync sections and '###' groups must not be empty
	while IFS= read -r h; do
		warn "SYNC_TODO.md heading without open items, remove it: $h"
	done < <(awk '
		function f2() { if (h2 != "" && n2 == 0) print h2 }
		function f3() { if (h3 != "" && n3 == 0) print h3 }
		/^## / { f3(); f2(); h2 = $0; n2 = 0; h3 = ""; next }
		/^### / { f3(); h3 = $0; n3 = 0; next }
		/^[[:space:]]*- \[ \]/ { n2++; n3++ }
		END { f3(); f2() }' "$TODOFILE")
	while IFS= read -r h; do
		warn "SYNC_TODO.md uses a non-standard group heading (see SKILL.md step 2): $h"
	done < <(grep '^### ' "$TODOFILE" |
		grep -vxE '### (Boards and SerDes variants|Layer machines|runme\.sh options|Files|Components|Other findings)')
	if [ "$items" = 0 ] && ! grep -qx 'No open points.' "$TODOFILE"; then
		warn "SYNC_TODO.md has no open items but lacks the line 'No open points.'"
	fi
	if [ $TODOS -gt 0 ]; then
		missing=0
		for k in "${TODO_KEYS[@]}"; do
			grep -qF -- "**$k**" "$TODOFILE" || { fail "SYNC_TODO.md has no item '**$k**'"; missing=1; }
		done
		[ $missing = 0 ] && ok "all $TODOS TODO items are listed in SYNC_TODO.md ($items open items)"
	elif [ "$items" -gt 0 ]; then
		warn "SYNC_TODO.md lists $items open items but this script found no TODO items - make sure they are manual findings"
	else
		ok "no TODO items, SYNC_TODO.md has no open items"
	fi
fi
echo
echo "Summary: $FAILS FAIL, $WARNS WARN, $TODOS TODO, $INFOS INFO"
[ $FAILS = 0 ]
