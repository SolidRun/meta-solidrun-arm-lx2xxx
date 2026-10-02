---
name: sync-lx2160a-build
description: Synchronise this Yocto layer (meta-solidrun-arm-lx2xxx) with the SolidRun reference BSP lx2160a_build - import new or changed patches for Linux, U-Boot, ATF, RCW and MC (DPL/DPC), kernel and u-boot config changes, udev rules and new boards, track open points in SYNC_TODO.md, verify, commit and open a pull-request that includes the open points. Use when asked to "sync with lx2160a_build", update patches from the SolidRun reference BSP, or check whether the layer is behind it.
---

# Sync meta-solidrun-arm-lx2xxx with lx2160a_build

Development happens first in the SolidRun reference BSP **lx2160a_build** (used for HW validation).
This layer must then carry the same patches **unchanged**, plus equivalent configuration.
This skill describes how to bring the layer up to date, in a way any agent or human can follow.

Terminology used throughout this skill:

- **SolidRun reference BSP**, short **lx2160a_build** - https://github.com/SolidRun/lx2160a_build, the
  source of everything synced here. Not to be confused with NXP's reference BSP / boards (below).
- **NXP BSP** - NXP's Layerscape software releases (e.g. `lf-6.6.52-2.2.0`): the `nxp-qoriq` component
  repositories that lx2160a_build patches, and the Yocto layers meta-qoriq / meta-freescale.
  NXP reference boards such as lx2160ardb are not SolidRun products.
- **This layer** - meta-solidrun-arm-lx2xxx, the Yocto layer being updated.
- "Upstream" is avoided: it usually means mainline projects (kernel.org Linux, U-Boot, TF-A, the Yocto
  Project), which are not involved in a sync.

Files in this skill directory:

- [project-map.md](project-map.md) - **read it completely first.** Branch parameters, and how every
  lx2160a_build file maps to this layer (patch dirs, config blocks → fragments, runme.sh TARGET → MACHINE,
  components → recipe SRCREVs, not-applicable files with reasons).
- [check-sync.sh](check-sync.sh) - deterministic checks of everything in project-map.md. Run it before
  and after making changes; its output is the authoritative worklist:
  - **FAIL** - the layer contradicts a mapping (missing/changed patch, wrong option, wrong machine value): fix it.
  - **TODO** - lx2160a_build has something project-map.md does not cover (new file, config block, board, runme.sh
    option, component): a possible **feature omission**. Implement it (and propose its project-map.md row), or list it in
    `SYNC_TODO.md`.
    TODOs are rediscovered on every sync until they are mapped, so nothing gets silently lost.
  - **INFO** - a finding about lx2160a_build itself, e.g. a config option the kernel/u-boot source does not define.
    Mention it in the report to the user (step 12) **only** - not in the commit, SYNC_TODO.md or project-map.md.

## Rules

1. **lx2160a_build is the source of truth.** It is the development repository; this layer follows it, also
   where lx2160a_build looks wrong. Copy lx2160a_build `*.patch` files byte-for-byte (`cp`), never regenerate,
   reformat or "fix" them; mirror config options exactly, including invalid ones. Problems are fixed
   in lx2160a_build first - point them out in the report instead.
2. **Never guess.** Anything that cannot be mapped mechanically or explained from project-map.md goes
   into `SYNC_TODO.md` (see below), not into an invented recipe change.
   project-map.md rows document what the layer implements, or what the maintainer explicitly decided not to
   implement - never propose a row only to silence a TODO.
3. **One branch, one skill.** This copy of the skill is for the Yocto series in the branch parameters.
   check-sync.sh stops if `conf/layer.conf` declares another series - then the skill must be forked.
4. **Ask before anything outward-facing.** Pushing and opening a pull-request need the user's go-ahead
   (unless the user requested an unattended run), and the **branch name always comes from the user**.
5. **The skill is read-only during a sync.** Never modify the files of this skill directory (SKILL.md,
   project-map.md, check-sync.sh) or AGENTS.md - they tell you what to do, a sync does not change them.
   If a mapping is missing or wrong (e.g. the layer now implements something that has no row yet), or an
   instruction is unclear or does not fit, **propose** the exact change in the report (step 12); the
   operator decides and applies it. Never commit skill files.
6. **Never download the components.** Do not run runme.sh, and do not clone or fetch the NXP component
   repositories (linux, u-boot, atf, dpdk, ... - `build/linux` alone is ~12 GB). The sync needs only:
   the lx2160a_build repository (~30 MB), shallow copies of meta-qoriq/meta-freescale, and `git ls-remote`.
   check-sync.sh uses `build/<component>` checkouts only if they already exist (e.g. on a maintainer's
   machine); without them it skips those checks - that is fine, do not try to make them run.

## Inputs

| input | required | default |
| --- | --- | --- |
| lx2160a_build checkout | no | `git clone --single-branch -b <reference_branch> <reference_repo>` (project-map.md) into a temporary directory; full history of that branch is needed for the sync range |
| PR branch name | for push/PR only | none - ask the user; without it stop after the local commit |
| Yocto `sources` dir (meta-qoriq, meta-freescale, ...) | recommended | none - SRCREV comparison is skipped and reported as WARN |

With an existing checkout: `git -C <dir> fetch && git -C <dir> checkout <reference_branch> && git -C <dir> pull --ff-only`.
Do not touch uncommitted or untracked files in the user's checkout.
Without a Yocto `sources` dir, create a minimal one: the SRCREV comparison only needs meta-qoriq and
meta-freescale, at the revisions pinned in the repo manifest `ls-*-sr.xml` of this layer
(`<project name="..." revision="...">`), e.g.:

```sh
mkdir -p /tmp/sources && cd /tmp/sources
git clone --depth 1 -b <meta-qoriq revision without refs/tags/, e.g. lf-6.6.52-2.2.0> https://github.com/nxp-qoriq/meta-qoriq
git init -q meta-freescale && git -C meta-freescale fetch -q --depth 1 https://github.com/Freescale/meta-freescale <meta-freescale revision> \
    && git -C meta-freescale checkout -q FETCH_HEAD
```

A full `repo init -m` + `repo sync` also works, but is not needed. Skip the SRCREV comparison only if the user agrees.

## Procedure

Overview: baseline → **start SYNC_TODO.md** → work through the items (steps 3-9), removing each one that
is resolved and adding anything that cannot be resolved → verify → commit (including SYNC_TODO.md) →
report and ask → pull-request (quoting SYNC_TODO.md).

### 1. Baseline

```sh
SKILL=.agents/skills/sync-lx2160a-build
$SKILL/check-sync.sh -s <yocto>/sources <lx2160a_build>      # add -r <sha> if no trailer exists yet
```

- **Stop conditions** - report to the user and stop instead of syncing if check-sync.sh reports:
  a layer series mismatch (another branch's skill), or a changed NXP release (`RELEASE`/`nxp_release`):
  that is a BSP rebase, not a sync.
- **Sync range:** check-sync.sh reads the `lx2160a_build: <branch> @ <sha>` trailer of the last sync commit
  in this layer. For layer history before trailers existed, determine the last synced lx2160a_build commit
  manually: the newest lx2160a_build commit whose patches/configs are all present in the layer
  (compare patch lists and `git log --date=short` of both repositories), then pass it with `-r`.
- The script lists every lx2160a_build commit in range and what it touches:
  `patches/<x>` / config files are mechanical; `review:<file>` must be read and judged;
  `n/a:<file>` is ignored (reason in project-map.md).
- Read **every** commit in range (`git show <sha>`) anyway - the subject line tells you what the change is for,
  which you need for the commit message and to judge `review` files.

### 2. Start SYNC_TODO.md

`SYNC_TODO.md` at the repository root is the list of open points. It **always exists** and always keeps its
title and note; no `- [ ]` items means there are no open points. It is part of the sync commit and of the
pull-request, so it is written **now** and kept current through every following step.

```markdown
# Sync TODO: lx2160a_build

> This file is generated and maintained by an LLM agent following
> [.agents/skills/sync-lx2160a-build](.agents/skills/sync-lx2160a-build/SKILL.md).
> Do not edit it by hand - every sync rewrites it. Decisions on open points are given to the agent,
> which implements them or proposes accepted omissions for the skill's project-map.md.

Open points of the sync with the SolidRun reference BSP lx2160a_build, i.e. what it has and this layer does not,
grouped by the sync that first found them (newest first).

## develop-ls-6.6.52-2.2.0 @ <full lx2160a_build sha> (<date of the sync>)

### Boards and SerDes variants

- [ ] **<key>** (<lx2160a_build commit or file>): <what is missing, and why it was not done>

### runme.sh options

- [ ] **<key>** ...

## develop-ls-6.6.52-2.2.0 @ <sha of an earlier sync> (<date>)

- [ ] **<key>** ...
```

With no open points at all, there are no `##` sections; the line `No open points.` follows the intro.

- The `#` title never changes and never contains a sha; the synced lx2160a_build revision is recorded per
  section and, authoritatively, in the commit trailer (step 11).
- Items stay in the section of the sync that **first** found them, so the file shows how long an omission
  has been open. New items of this sync go into a new `##` section at the top, headed with the lx2160a_build sha
  being synced now and today's date. Do not create the section if this sync finds nothing new.
- Remove a `##` section once all of its items are resolved.
- Within a `##` section, group items under these `###` headings, in this order, using only those needed:
  `### Boards and SerDes variants` (runme.sh TARGETs), `### Layer machines`, `### runme.sh options`,
  `### Files` (lx2160a_build files, config blocks), `### Components`, `### Other findings` (manual findings,
  e.g. from review files or build dependencies). Use no other `###` headings, and remove one once it is empty.
- The file is machine-managed: write its content yourself, do not preserve hand edits.
- Re-check every item of an existing SYNC_TODO.md and keep those still open in their section (rewording
  is fine), in particular manual findings of earlier syncs, which check-sync.sh cannot rediscover. The user may
  deliberately leave items unresolved for a long time.
- If the user decides about an item in the conversation (implement it, or accept the omission), act on it:
  implement it, or propose the project-map.md row with the user's reason in the report (step 12).
- Add one item per TODO line of the baseline run that is not listed yet. `<key>` is the exact key from the TODO line (TARGET label,
  option name, config block comment, component, lx2160a_build file); check-sync.sh verifies each is mentioned.
- Explain each item so the user can decide without research: use project-map.md "Hints for unmapped items"
  when the key is listed there, otherwise read the lx2160a_build code (e.g. how runme.sh uses an option).
- FAIL lines are not TODO items: they are the mechanical work of steps 3-8 and must all be fixed.

While working through steps 3-9: **remove an item as soon as it is resolved** (implemented in the layer),
and **add an item** for anything you find that cannot be resolved (with the reason). If a resolved item
still needs a project-map.md row to stop being reported, keep it out of SYNC_TODO.md and list the proposed
row in the report instead. Only the user decides that an omission is permanent; then the operator moves it
to project-map.md (`n/a` / `-` with the user's reason).

### 3. Patches (`patches/<component>`)

For each FAIL in section "Patches":

1. Copy the missing/changed files: `cp <lx2160a_build>/patches/<c>/<file> <layer dir>/`.
2. Remove layer patches that lx2160a_build deleted (`git rm`); if lx2160a_build renumbered, mirror it exactly.
3. Edit `SRC_URI` in the bbappend so the `file://` list equals the lx2160a_build sorted file list, keeping the
   existing indentation and `\` continuation style:

   ```
               file://0053-board-solidrun-lx2160acex7-select-correct-secure-job.patch \
   "
   ```

A new `patches/<dir>` for a component not yet in the layer is not mechanical: it needs a new bbappend
(check which recipe builds that component, and that its SRCREV matches - see step 8). Add it if the
mapping is unambiguous and propose the project-map.md row in the report, otherwise keep the TODO item.

### 4. configs/ and other files

**Every** tracked lx2160a_build file - in particular everything under `configs/` - must be covered by
project-map.md (tables `files`, `kconfig`, `not-applicable`); check-sync.sh reports each uncovered file as
TODO (section "lx2160a_build file coverage"), whatever its name or type.

- Known byte-identical files (table `files`, e.g. u-boot `lx2k_additions.config` → `additions.cfg`,
  `configs/linux/*.rules` → `recipes-core/udev/files/`): copy them.
- New file: find out how runme.sh uses it (`grep -n '<file name>' runme.sh`) and give it the equivalent use in
  the layer, e.g. a new `.rules` file needs a copy in `recipes-core/udev/files/`, `SRC_URI` + `do_install`
  lines in `recipes-core/udev/udev-solidrun-lx2xxx.bb` (the existing glob row covers it). Other new files
  need a project-map.md row: propose it in the report. If the equivalent is not obvious, keep the TODO item
  and describe how runme.sh uses the file.

### 5. Kernel configuration

lx2160a_build has one `configs/linux/lx2k_additions.config`; the layer splits it into topic fragments following
its `# <comment>` lines: each block goes into the fragment named after its comment, except for the older
fragments listed in table `kconfig` of project-map.md. check-sync.sh reports per fragment which options must
be added (`+`) or removed (`-`), and fragments that are missing.

Mirror lx2160a_build exactly - every fragment equals its lx2160a_build blocks, nothing more, nothing less:

- Added/changed/removed option in a known block → same change in the mapped `<fragment>.cfg`.
- **New block** (FAIL "fragment … missing") → create the fragment with exactly the name check-sync.sh
  derived, as described in project-map.md (`<fragment>.cfg`, `<fragment>.scc`, three bbappend lines).
  No project-map.md row is needed.
- An option that moved from one block to another (possibly with a new value) moves between fragments
  accordingly - never leave the old copy behind, conflicting values across fragments silently depend on
  merge order.
- Keep options in the same order as lx2160a_build within each fragment.
- Options flagged INFO (not defined in the source tree) are copied all the same; only report them.

### 6. Boards: runme.sh TARGET → MACHINE

check-sync.sh compares every runme.sh `TARGET` with its machine (ATF platform, DPC/DPL, device trees,
ethprime, u-boot defconfig, S5).

- Changed value for a mapped machine (FAIL) → update `conf/machine/<m>.conf` (or the shared include if all
  machines using it change).
- A TARGET row only covers the SerDes protocols the machine's `RCW*` actually build; check-sync.sh FAILs a row
  claiming more. A SerDes variant that could only be reached with local.conf overrides of `RCW*`/`MC_DPC`/
  `MC_DPL` is **not** supported - it stays a TODO.
- **TODO for a layer machine** → a machine that no TARGET covers builds a configuration lx2160a_build does not
  provide (e.g. a SerDes protocol runme.sh does not offer for that board). Describe the difference.
- **TODO for a TARGET** → a board or SerDes variant without a machine.
  If it is new in this sync range, it is usually a new board or SerDes variant. A new board needs a machine
  conf modelled on the closest existing one, a row in the README "Supported Machines" table, an entry in the
  CI matrix in `.github/workflows/build.yml`, and its `.dtb` in `KERNEL_DEVICETREE`/`IMAGE_BOOT_FILES`
  (`conf/machine/include/lx216xa-solidrun.inc`). Only do this if the lx2160a_build commits make the intent clear;
  otherwise keep the TODO item. When the machine exists, propose its project-map.md row in the report.

### 7. runme.sh options

Every `: ${VAR:=default}` in runme.sh is a user-visible option of lx2160a_build (table `options`).
An option without a row is reported as TODO - e.g. a new build option, or an existing feature the layer
never implemented. check-sync.sh prints a **trace** with each such TODO: every line using the option, the
labels of `case`/`if` statements on it, the variables derived there and every line using those.
Follow the trace to the end before writing the SYNC_TODO.md item, and describe:

- which boards/TARGETs it applies to (case labels, e.g. only Clearfog-CX/HoneyComb),
- every derived setting and where it ends up: u-boot `.config` symbols, ATF make variables, image layout,
- which of these the layer already has (e.g. patches present but unused) and what is missing. If the option maps to an existing or easily added machine/local.conf variable, implement
it, document it in README "Options", and propose the project-map.md row in the report; otherwise keep the
TODO item.

### 8. Component revisions

runme.sh clones each NXP component and applies patches on top. The base must be the revision the
Yocto recipe builds (effective `SRCREV`), otherwise the patches were validated on different code.
check-sync.sh compares them (needs `-s`). It resolves the base revision used by lx2160a_build with `git ls-remote` (a few bytes per
component) and additionally with `build/<component>` checkouts if they already exist - never clone them.

- Mismatch caused by a lx2160a_build commit that deliberately moves a component (e.g. "update mc firmware to
  10.x") → override `SRCREV` (and `PV`/branch if needed) in this layer's bbappend and describe it in the commit.
- Any other mismatch → keep the TODO item; do not change SRCREVs speculatively.

### 9. Review files

For each lx2160a_build commit touching `review` files (runme.sh, README.md, vpp.md, docker/): read the diff and decide.

- runme.sh build options that change what is built (e.g. new `ATF_*`/`UBOOT_*`/rcw parameters) usually need a
  machine variable or bbappend logic → implement if straightforward, otherwise add a TODO item.
- docker/ package additions are not recipe dependencies by default. Only when the commit states that a
  specific change needs the tool → follow project-map.md "Build host dependencies".
- Other runme.sh/docker changes that only affect the runme.sh build host/container (ccache, distro rootfs,
  compiler fixes for the container) → ignore, mention in the report.
- README: port user-relevant information (new boards, options, known issues) to this layer's README.md.

### 10. Verify and finalise SYNC_TODO.md

```sh
$SKILL/check-sync.sh -s <yocto>/sources <lx2160a_build>
```

- It must report **0 FAIL**; fix and re-run until it does.
- Section "Layer dependencies" (needs `-s`) FAILs when this layer uses a recipe, bbappend base, include or
  dependency from a layer missing in `LAYERDEPENDS_solidrun-lx2xxx` (`conf/layer.conf`):
  - if the use already existed before this sync, the list was incomplete: add the collection and mention it
    in the commit message;
  - if this sync introduced the use, adding a layer dependency is a maintainer decision: leave that change
    out and keep it as a TODO item (see project-map.md "Build host dependencies").
  A WARN for a listed but unused collection is reported to the user, not removed on your own.
- Every remaining TODO line must have its item in SYNC_TODO.md (the script checks this), and every item in
  SYNC_TODO.md must still be open - remove resolved ones.
- Remove `##` sections without items left. **No open points at all →** title, note, intro and the line
  `No open points.` remain. Never delete the file.
- Builds are not required locally: the pull-request CI (`.github/workflows/build.yml`) applies all patches
  and builds every machine. If the user asks for a local check, use
  `bitbake -c patch u-boot-qoriq linux-qoriq qoriq-atf rcw mc-utils` in a build directory that uses
  this checkout of the layer.

### 11. Commit

One commit for the whole sync, including SYNC_TODO.md - but never files of this skill (rule 5):

```
sync with lx2160a_build: <short summary of the most important changes>

- <one line per lx2160a_build feature or fix, user-oriented>
- ...
- open points: see SYNC_TODO.md              (only if it lists open points)

lx2160a_build: develop-ls-6.6.52-2.2.0 @ <full lx2160a_build sha>
```

The `lx2160a_build:` line is mandatory: it is the start point of the next sync.

**Authorship and sign-off belong to the LLM, not to the user.** Human-written commits in this layer carry
no `Signed-off-by`; an LLM-generated sync must have one - in the LLM's own name. Never put the user's (git
config) identity into `--author` or `Signed-off-by`; the user only appears as committer.

```sh
LLM_ID="<model name> <vendor no-reply address>"     # e.g. "Claude Opus 5.5 <noreply@anthropic.com>"
git commit --author="$LLM_ID" --trailer "Signed-off-by: $LLM_ID" -F <message file>
```

- Use your own model name and the no-reply address your vendor uses for commit attribution. If you do not
  know them, ask the user - do not fall back to the git config identity.
- Do not add a `Co-Authored-By` trailer for yourself (you are the author); drop it even if your tool adds
  one by default.
- `git commit -s` is wrong here: it signs off with the user's identity.
Open points in SYNC_TODO.md mark the sync as incomplete; it is committed anyway, so CI can verify everything else.

### 12. Report and ask

Tell the user: lx2160a_build range synced, what was changed per component, what was ignored and why,
the open points (SYNC_TODO.md), all INFO findings about lx2160a_build (e.g. invalid config options that were
copied anyway), and the final check-sync.sh summary line.

End the report with **proposed skill changes** (or "none"): every project-map.md row the layer now needs
(e.g. for a new machine or option implemented in this sync), every instruction that was unclear, wrong or
missing, each as a concrete diff with a one-line reason. Keep proposals generic - they must help future
syncs, not describe this sync's particular case. Do not apply them.

Then recommend the pull-request (step 13) and ask for the **branch name** and the go-ahead.
In an unattended run, the branch name must have been given with the task; otherwise stop here.

### 13. Pull-request (recommended)

Push the commit to the branch named by the user and open a pull-request against `pr_base` (project-map.md).
The CI then proves that all patches apply and all machines build.
PR description: the commit body, followed by the open points of SYNC_TODO.md (if it lists any) under a heading
"Open points", so reviewers see what this sync does not cover.

On GitHub's Copilot cloud agent (repository "Agents" tab) the agent creates its own `copilot/*` branch;
use the requested name in the PR title instead.
