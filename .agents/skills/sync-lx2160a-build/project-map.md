# Project map: lx2160a_build ↔ meta-solidrun-arm-lx2xxx (scarthgap)

This file is the single source of truth for how every file in the SolidRun reference BSP
[lx2160a_build](https://github.com/SolidRun/lx2160a_build) corresponds to this Yocto layer.
It is read by humans, by LLM agents following [SKILL.md](SKILL.md), and parsed by [check-sync.sh](check-sync.sh).

Parsing rules for the machine-readable tables (between `<!-- map:NAME -->` and `<!-- /map -->`):

- one row per line, cells separated by `|`, backticks are ignored
- header and separator rows are skipped
- `*` is a glob matching any characters including `/`

**Only mapped or deliberately excluded items belong here.** Anything in lx2160a_build that is not covered by a row
is reported by check-sync.sh as a TODO, on every sync, until it is either implemented in the layer (and mapped
here) or excluded here with a reason. This is how feature omissions are discovered: a row is never added just to
silence a TODO. Only the maintainer decides that an omission is permanent (`n/a` with reason); until then it
lives in `SYNC_TODO.md`.

**This file is maintained by the operator, never changed during a sync.** When a sync implements something
that needs a new or changed row, the agent proposes the exact change in its final report; the operator applies it.

## Branch parameters

Everything specific to this layer branch. When forking the skill for another Yocto branch, update this table first.

<!-- map:parameters -->
| key             | value                                     |
| --------------- | ----------------------------------------- |
| yocto_series    | scarthgap                                 |
| layer_compat    | LAYERSERIES_COMPAT_solidrun-lx2xxx        |
| pr_base         | scarthgap                                 |
| reference_repo   | https://github.com/SolidRun/lx2160a_build |
| reference_branch | develop-ls-6.6.52-2.2.0                   |
| nxp_release     | lf-6.6.52-2.2.0                           |
| mc_release      | mc_release_10.39.0                        |
<!-- /map -->

## Patch directories

Patches are copied byte-for-byte; each is listed as `file://` in the bbappend, in numeric order.

<!-- map:patches -->
| lx2160a_build dir     | layer dir                           | bbappend                                         |
| ---------------- | ----------------------------------- | ------------------------------------------------ |
| patches/atf      | recipes-bsp/atf/2.10-solidrun       | recipes-bsp/atf/qoriq-atf_2.10.bbappend          |
| patches/u-boot   | recipes-bsp/u-boot/2024.04-solidrun | recipes-bsp/u-boot/u-boot-qoriq_2024.04.bbappend |
| patches/linux    | recipes-kernel/linux/6.6-solidrun   | recipes-kernel/linux/linux-qoriq_6.6.bbappend    |
| patches/rcw      | recipes-bsp/rcw/files               | recipes-bsp/rcw/rcw_git.bbappend                 |
| patches/mc-utils | recipes-bsp/mc-utils/files          | recipes-bsp/mc-utils/mc-utils_%.bbappend         |
<!-- /map -->

## Byte-identical files

<!-- map:files -->
| lx2160a_build file                                    | layer file                                            | referenced by                                    |
| ------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------ |
| configs/u-boot/lx2k_additions.config             | recipes-bsp/u-boot/2024.04-solidrun/additions.cfg     | recipes-bsp/u-boot/u-boot-qoriq_2024.04.bbappend |
| configs/linux/*.rules                            | recipes-core/udev/files/*                             | recipes-core/udev/udev-solidrun-lx2xxx.bb        |
<!-- /map -->

A row may contain one `*` in both file columns; every matching lx2160a_build file must exist byte-identical at
the corresponding layer path and be referenced in the recipe. So a new `configs/linux/*.rules` file only needs
a copy in `recipes-core/udev/files/` and entries in both `SRC_URI` and `do_install` of `udev-solidrun-lx2xxx.bb`.

## Kernel configuration

lx2160a_build `configs/linux/lx2k_additions.config` is one file, split by `# <comment>` lines into blocks.
The layer has one fragment per topic in `recipes-kernel/linux/6.6-solidrun/<fragment>.cfg`.
Every option of a block must appear in its fragment, with the same value, and nowhere else.
lx2160a_build is mirrored exactly: options it moves between blocks move between fragments, and options the
kernel does not know (reported as INFO) are copied as well.
Options before the first comment belong to block `(start)`.
Lines of the form `# CONFIG_FOO is not set` are options, not comments.

Each block goes into the fragment **named after its comment**: lowercase, every run of non-alphanumeric
characters replaced by one dash (`# disable imx gpu/vpu drivers` → `disable-imx-gpu-vpu-drivers`).
The table below lists only the **exceptions** to this rule (older fragments named differently);
a new block needs no row - check-sync.sh derives its fragment and reports it as missing until it exists.

<!-- map:kconfig -->
| lx2160a_build block comment                        | fragment                |
| --------------------------------------------- | ----------------------- |
| (start)                                       | compressed-modules      |
| lx2160 boards                                 | lx216x-solidrun-drivers |
| lx2162 clearfog                               | lx216x-solidrun-drivers |
| c45 phy driver modules don't auto-load ...    | lx216x-solidrun-drivers |
| confuses netdev order if loaded late (module) | lx216x-solidrun-drivers |
| lx2160 half-twins                             | lx216x-solidrun-drivers |
| packet generator                              | pktgen                  |
| intel 10Gbps pci nics                         | ixgbe                   |
| Full NFTABLES                                 | nftables-full           |
| docker support                                | docker                  |
| usb serial adapters                           | usbserial               |
| sctp module                                   | sctp                    |
| kernel debugger                               | kgdb                    |
<!-- /map -->

A new fragment is modelled on `sctp`:

- `<fragment>.cfg` with the options
- `<fragment>.scc` with `define KFEATURE_DESCRIPTION "<comment>"`, `define KFEATURE_COMPATIBILITY board`, `kconf non-hardware <fragment>.cfg`
- three lines in `linux-qoriq_6.6.bbappend`, each appended after the existing ones of the same kind:
  `SRC_URI:append = " file://<fragment>.scc"`, `SRC_URI:append = " file://<fragment>.cfg"`,
  `DELTA_KERNEL_DEFCONFIG:append = " <fragment>.cfg "`

lx2160a_build merges `arch/arm64/configs/defconfig` + `lsdk.config` + `lx2k_additions.config`;
the layer gets the first two from `linux-qoriq` (`KERNEL_DEFCONFIG ?= "defconfig"` in `lx216xa-solidrun.inc`
plus meta-qoriq's own `DELTA_KERNEL_DEFCONFIG`), so only `lx2k_additions.config` is mapped.

## Build host dependencies

lx2160a_build `docker/Dockerfile` is the build host of runme.sh: a long list of general tools for building
all components and the distro images. Yocto builds its own native tools and recipes declare their own
dependencies, so the Dockerfile is not ported, and a package in it is **not** by itself a dependency of any
recipe. Do not add `DEPENDS` for Dockerfile packages, and do not search the Dockerfile for candidates.

The exception is a lx2160a_build commit whose message (or diff) states that a specific component needs a
specific tool for a specific change. Only then:

1. Check whether Yocto already handles that need: `DEPENDS` and task `[depends]` of the recipe, its includes
   and classes, or `bitbake-getvar -r <recipe> DEPENDS` in a build environment. Look at how other recipes
   (e.g. in poky) solve the same need, and whether that solution reaches the recipe built here.
   If it is handled: nothing to do, mention it in the report.
2. If not, add `DEPENDS += "<tool>-native"` (plus task dependencies if the tool is needed before
   `do_compile`, e.g. during configuration) to this layer's bbappend of that recipe, and explain it in the
   commit message.
3. If the native recipe lives in a layer not listed in `LAYERDEPENDS_solidrun-lx2xxx` (`conf/layer.conf`),
   keep it as a TODO item: adding a layer dependency is a maintainer decision.

## runme.sh TARGET → MACHINE

Each label of the `case "${TARGET}"` block in runme.sh without a row is a TODO.
`machine` is a space separated list of `conf/machine/<name>.conf`, or `n/a` with a reason.
For mapped rows check-sync.sh compares the runme.sh variables with the machine configuration:
`ATF_PLATFORM`, `ATF_DISABLE_S5`, `DPC`→`MC_DPC`, `DPL`→`MC_DPL`, `DEFAULT_FDT_FILE`→`UBOOT_FDT_FILE`,
`UBOOT_FDT`, `UBOOT_ETHPRIME`, `UBOOT_DEFCONFIG`→`UBOOT_CONFIG[tfa]`.
It also checks that the SerDes protocols in the label (fields 4-6, `*` = any) are what the machine's
`RCWAUTO`/`RCWSD`/`RCWEMMC`/`RCWXSPI` build. A SerDes variant the machine does not build by default is **not**
covered by that machine, even if DPC/DPL are shared and local.conf overrides could select it: such a variant
stays a TODO until the layer supports it explicitly (documented machine or option).

<!-- map:targets -->
| runme.sh TARGET label              | machine                                        | reason / notes |
| ---------------------------------- | ---------------------------------------------- | -------------- |
| LX2160A_CEX6_EVB_3_3_*             | lx2160a-rev2-cex6-evb                          | SolidRun-internal evaluation board |
| LX2160A_CEX7_CLEARFOG-CX_0_0_0     | n/a                                            | SerDes-less base configuration for bring-up of new boards, not a product |
| LX2160A_CEX7_CLEARFOG-CX_18_5_*    | lx2160a-clearfog-cx lx2160a-rev2-clearfog-cx   | RCW* SerDes 18_5_2 |
| LX2160A_CEX7_HONEYCOMB_8_5_*       | lx2160a-honeycomb lx2160a-rev2-honeycomb       | RCW* SerDes 8_5_2 |
| LX2160A_CEX7_HALF-TWINS_8S_9_2     | lx2160a-rev2-half-twins                        | |
| LX2160A_CEX7_TWINS-RIGHT_8S_9_2    | lx2160a-rev2-twins-right                       | |
| LX2160A_CEX7_TWINS-LEFT_8S_9_2     | lx2160a-rev2-twins-left                        | |
| LX2162A_SOM_CLEARFOG_0_0_0         | n/a                                            | SerDes-less base configuration for bring-up of new boards, not a product |
| LX2162A_SOM_CLEARFOG_18_9_0        | lx2162a-rev2-clearfog                          | RCWAUTO SerDes 18_9_0 |
<!-- /map -->

Every layer machine must be covered by a TARGET row above, or listed here with a reason;
otherwise it builds something lx2160a_build does not provide, and check-sync.sh reports it as a TODO.

<!-- map:machines -->
| machine           | reason |
| ----------------- | ------ |
| lx216xa-solidrun  | generic LX2160A/LX2162A machine without boot loader, no runme.sh counterpart |
<!-- /map -->

Rev 1 machines (`lx2160a-clearfog-cx`, `lx2160a-honeycomb`) correspond to runme.sh `CPU_REVISION=1`.

## runme.sh options

runme.sh is configured by environment variables declared as `: ${VAR:=default}`.
Each such option is a user-visible feature of lx2160a_build; one without a row is a TODO.
`layer variable` is a variable that must be used somewhere in this layer (checked), or `-`.

<!-- map:options -->
| runme.sh option    | layer variable    | counterpart / reason |
| ------------------ | ----------------- | -------------------- |
| RELEASE            | -                 | NXP release; checked against branch parameter nxp_release, a change means BSP rebase |
| CPU_SPEED          | LX2160A_CPU_SPEED | local.conf option (README "CPU Clock") |
| DDR_SPEED          | LX2160A_DDR_SPEED | local.conf option (README "DDR Clock") |
| BUS_SPEED          | LX2160A_BUS_SPEED | local.conf option (README "Bus Clock") |
| CPU_REVISION       | -                 | choice of machine: lx2160a-* (silicon rev 1) or lx2160a-rev2-* |
| TARGET             | -                 | choice of MACHINE, see table "runme.sh TARGET → MACHINE" |
| BOOTSOURCE         | BOOTTYPE          | machine BOOTTYPE / RCW* variables; images for all boot sources are built |
| SECURE             | -                 | secure boot is handled differently in Yocto (meta-qoriq secure boot support, e.g. UBOOT_CONFIG tfa-secure-boot) |
| SHALLOW            | -                 | git clone depth of runme.sh; bitbake fetcher has its own mirror logic |
| CCACHE_DISABLE     | -                 | compiler cache of runme.sh; bitbake uses sstate-cache |
| DISTRO             | -                 | Debian/Ubuntu rootfs of runme.sh; Yocto builds its own images |
| UBUNTU_VERSION     | -                 | see DISTRO |
| UBUNTU_ROOTFS_SIZE | -                 | see DISTRO |
| DEBIAN_VERSION     | -                 | see DISTRO |
| DEBIAN_ROOTFS_SIZE | -                 | see DISTRO |
| APTPROXY           | -                 | see DISTRO |
<!-- /map -->

### Hints for unmapped items

Background for items that are deliberately **not** in the tables above, so they keep being reported as TODO.
Use it to write a meaningful `SYNC_TODO.md` entry; it is not a reason to map them.

- `ATF_DEBUG` - selects an ATF debug build: compile-time options setting debug output verbosity
  (`ATF_DEBUG=true` makes runme.sh build ATF as `debug` with `DEBUG=1 LOG_LEVEL=40 DDR_DEBUG=yes DDR_PHY_DEBUG=yes`,
  i.e. verbose BL2/BL31 and DDR training logs on the console). Not implemented in the layer so far,
  to avoid adding many layer-specific global (local.conf) variables; a possible implementation would be an
  opt-in variable in the `qoriq-atf` bbappend.

## Components cloned by runme.sh → Yocto recipes

runme.sh clones `QORIQ_COMPONENTS` from `https://github.com/nxp-qoriq/<component>` with `git clone -b <ref>`
(or at an explicit `COMMIT=`), then applies `patches/<component>/*.patch` with `git am`.
On nxp-qoriq the release names are normally **tags** (fixed), but `-b` silently falls back to a **branch** of
the same name, which moves. Either way the base revision must equal the effective `SRCREV` of the Yocto recipe,
otherwise patches were validated against different code than Yocto builds.
Note `git describe` in a build/ checkout may print a newer tag name for the same commit; compare hashes, not names.

<!-- map:components -->
| component         | runme.sh ref        | recipe            | variable    |
| ----------------- | ------------------- | ----------------- | ----------- |
| u-boot            | lf-6.6.52-2.2.0     | u-boot-qoriq      | SRCREV      |
| atf               | lf-6.6.52-2.2.0     | qoriq-atf         | SRCREV      |
| ddr-phy-binary    | lf-6.6.52-2.2.0     | qoriq-atf         | SRCREV_ddr  |
| rcw               | lf-6.6.52-2.2.0     | rcw               | SRCREV      |
| restool           | lf-6.6.52-2.2.0     | restool           | SRCREV      |
| mc-utils          | mc_release_10.39.0  | mc-utils          | SRCREV      |
| qoriq-mc-binary   | mc_release_10.39.0  | management-complex | SRCREV     |
| linux             | lf-6.6.52-2.2.0     | linux-qoriq       | SRCREV      |
| dpdk              | lf-6.6.52-2.2.0     | dpdk              | SRCREV      |
| cst               | lf-6.6.52-2.2.0     | qoriq-cst         | SRCREV      |
| mdio-proxy-module | lf-6.6.52-2.2.0     | mdio-proxy-module | SRCREV      |
| optee_os          | lf-6.6.52-2.2.0     | optee-os-qoriq    | SRCREV      |
<!-- /map -->

The effective SRCREV is **not** simply the one in the `.bb`: meta-qoriq overrides several in `.bbappend`s
(e.g. `rcw`, `restool`, `mc-utils`). Authoritative: `bitbake-getvar -r <recipe> SRCREV` in a build environment.
Without one, check-sync.sh resolves it as: highest-priority `.bbappend` with a hard `=` assignment,
else the highest-priority `.bb`/`.inc` (priorities: this layer 15, meta-qoriq 8, meta-freescale 5).

## Not applicable to Yocto

Every tracked lx2160a_build file must match a row here or one of the tables above.
`review` rows are not ported mechanically, but every lx2160a_build commit touching them must be read and
judged; anything relevant goes into the layer by hand or into `SYNC_TODO.md`.

<!-- map:not-applicable -->
| lx2160a_build path                         | kind   | reason |
| ------------------------------------- | ------ | ------ |
| .devcontainer/*                       | n/a    | developer environment of lx2160a_build |
| .vscode/*                             | n/a    | developer environment of lx2160a_build |
| .github/*                             | n/a    | CI of lx2160a_build; the layer has its own .github/workflows/build.yml |
| .gitignore                            | n/a    | lx2160a_build repository housekeeping |
| docker/*                              | review | build container for runme.sh, not ported; only a package whose commit says which change needs it is checked (see "Build host dependencies") |
| configs/buildroot/*                   | n/a    | buildroot is not applicable for Yocto |
| patches/ramdisk_rootfs_arm64.ext4.gz  | n/a    | Yocto builds its own initramfs image (INITRAMFS_IMAGE_BUNDLE) |
| runme.sh                              | review | targets and components are checked via the tables above; other changes (new options, build steps) need judgement |
| README.md                             | review | port user-relevant notes (new boards, options, known issues) to the layer README.md |
| vpp.md                                | review | VPP usage notes; Yocto counterpart is recipes-solidrun/images/vpp-oci-image.bb |
<!-- /map -->
