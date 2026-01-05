# SolidRun LX2160A Yocto BSP

## Build Instructions

Start in a **new empty directory** with plenty of free disk space - at least 30GB, Then:

1. download the build recipes:

   ```
   repo init -u https://github.com/nxp-qoriq/yocto-sdk.git -b scarthgap -m ls-6.6.52-2.2.0.xml
   repo sync
   git clone -b scarthgap https://github.com/SolidRun/meta-solidrun-arm-lx2xxx.git sources/meta-solidrun-arm-lx2xxx
   ```

2. Initialise a build directory with example configuration files based on lx2160ardb, and appropriate shell environment variables:

       source ./setup-env -m lx2160ardb-rev2 -b build

3. Adapt example configuration files for SolidRun LX2160A Honeycomb:

   - edit `build_lx2160acex7-rev2/conf/bblayers.conf`:

     Append path to meta-solidrun-arm-lx2xxx:

         BBLAYERS += " <insert-your-workdir>/sources/meta-solidrun-arm-lx2xxx"

   - edit `build_lx2160acex7/conf/local.conf`:

     Set machine to `lx2160a-rev2-honeycomb`:

     ```diff
     -MACHINE ??= 'lx2160ardb-rev2'
     +MACHINE ??= 'lx2160a-rev2-honeycomb'
     ```

     Enable generating sd bootable image (wic). append:

     ```
     IMAGE_FSTYPES:append = " wic.gz wic.bmap "
     # break dependency cycle with core-image-minimal used as initramfs
     IMAGE_FSTYPES:remove:pn-core-image-minimal = "wic.gz wic.bmap"
     ```

   - See below for additional configuration options.

4. Build nxp image `fsl-image-networking`:

       bitbake fsl-image-networking

5. Find resulting image ready for programming:

       ls -lh tmp/deploy/images/
       ls -lh tmp/deploy/images/lx2160a-clearfog-cx/

Note: The build environment and ability to run `bitbake` is lost when closing the terminal or rebooting.
It can be restored at any time by entering the build directory and sourcing the aut-generated `SOURCE_THIS` file:

```
cd <insert-your-workdir>/build
source SOURCE_THIS
```

## Options

### Supported Machines

This Layer supports the following machines:

| Machine                  | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| lx2160a-clearfog-cx      | LX2160A COM-Express 7 on Clearfog-CX, LX2160A Silicon 1.0 (preview version)    |
| lx2160a-honeycomb        | LX2160A COM-Express 7 on Honeycomb, LX2160A Silicon 1.0 (preview version)      |
| lx2160a-rev2-cex6-evb    | SolidRun-internal Evaluation Board, LX2160A Silicon 2.0 (production version)   |
| lx2160a-rev2-clearfog-cx | LX2160A COM-Express 7 on Clearfog-CX, LX2160A Silicon 2.0 (production version) |
| lx2160a-rev2-honeycomb   | LX2160A COM-Express 7 on Honeycomb, LX2160A Silicon 2.0 (production version)   |
| lx2160a-rev2-half-twins  | LX2160A COM-Express 7 on Twins, LX2160A Silicon 2.0 (production version)       |
| lx2162a-rev2-clearfog    | LX2162A SoM on Clearfog                                                        |
| lx216xa-solidrun         | Generic LX2160A & LX2162A without Bootloader                                   |

### Supported Images

This Layer supports the following images:

| Image                     | Description                                                                    |
| ------------------------- | ------------------------------------------------------------------------------ |
| fsl-image-networking      | Typical networking features and basic cli utilities                            |
| fsl-image-networking-full | Demo of all packages tested by NXP including dpdk, dpdk examples and vpp       |

### Image Types (wic)

This layer can generate a range of image types by `WKS_FILE` in local.conf:

- `lx2160a-bootimg-mmc.wks.in` (default): Bootloader & Kernel & RootFS, for SD or eMMC.
- `lx2160a-bootimg-xspi.wks.in`: Bootloader only, for SPI Flash.
- `lx2160a-rootimg.wks.in`: Kernel & RootFS only, for any block storage.

### DDR Clock

DDR Clock can be configured in local.conf using `LX2160A_DDR_SPEED`, supported values are:

- `2400`
- `2600`
- `2666`
- `2900` only for LX2162A, and LX2160A binned 2GHz and higher (default)
- `3200` only for LX2160A binned 2.2GHz

### CPU Clock

CPU (Cortex A72) Clock can be configured in local.conf using `LX2160A_CPU_SPEED`, supported values are:

- `2000` (default, recommended)
- `2200` (for over-clocking, or for specifically purchased 2.2GHz binned SoC)

### Bus Clock

Bus clock can be configured in local.conf using `LX2160A_BUS_SPEED`, supported values are:

- `650`
- `700` only for LX2160A binned 2GHz and higher (default)
- `750` (for over-clocking, or for specifically purchased 2.2GHz binned SoC)

### MC DPC & DPL

Management Complex configuration can be configured in local.conf using `MC_FLAVOUR`, `MC_DPC` and `MC_DPL` variables, supported values are:

- `MC_FLAVOUR=CEX6`:

   - `MC_DPC=evb-s1_3-s2_0-dpc.dtb MC_DPL=evb-s1_3-s2_0-dpl.dtb`

- `MC_FLAVOUR=CEX7`:

   - `MC_DPC=clearfog-cx-s1_8-s2_0-dpc.dtb MC_DPL=clearfog-cx-s1_8-s2_0-dpl.dtb`

Additional configurations are added by patching `mc-utils` package and adding files at `LX2160A-<MC_FLAVOUR>/`.

## Known Issues

### `setup-env` script requires bash

On shells other than bash the nxp `setup-env` script fails unintuitively, e.g. below with zsh:

```
source ./setup-env -m lx2160ardb-rev2 -b build
./setup-env:159: no matches found: /opt/workspace/YOCTO/lx2k-scarthgap/sources/meta-fsl*/*/*/conf/machine
lx2160ardb-rev2 is not supported by this build setup.
Usage: . setup-env -m <machine>
usage:3: no matches found: /opt/workspace/YOCTO/lx2k-scarthgap/sources/meta-fsl*/*/*/conf/machine

    Supported machines:


    Optional parameters:
    * [-m machine]: the target machine to be built.
    * [-j jobs]:    number of jobs for make to spawn during the compilation stage.
    * [-t tasks]:   number of BitBake tasks that can be issued in parallel.
    * [-b path]:    non-default path of project build folder.
    * [-d path]:    non-default path of DL_DIR (downloaded source)
    * [-c path]:    non-default path of SSTATE_DIR (shared state Cache)
    * [-h]:         help
```

Ensure using a `bash` shell.

### permission error in disable_network

Bitbake can fail with a confusing permission error while trying to disable it's child processes network access:

```
ERROR: PermissionError: [Errno 1] Operation not permitted

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/opt/workspace/YOCTO/imx8-scarthgap/sources/poky/bitbake/bin/bitbake-worker", line 278, in child
    bb.utils.disable_network(uid, gid)
  File "/opt/workspace/YOCTO/imx8-scarthgap/sources/poky/bitbake/lib/bb/utils.py", line 1696, in disable_network
    with open("/proc/self/uid_map", "w") as f:
PermissionError: [Errno 1] Operation not permitted

ERROR: Task (virtual:native:/opt/workspace/YOCTO/imx8-scarthgap/sources/poky/meta/recipes-devtools/autoconf/autoconf_2.72e.bb:do_unpack) failed with exit code '1'
```

See [Ubuntu Bug 2056555](https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/2056555) for more details.

As a workaround apparmor "unprivileged_userns" profile can be temporarily disabled:

    sudo apparmor_parser -R /etc/apparmor.d/unprivileged_userns

## Maintainer Notes

### Patching Linux / U-Boot / ATF / RCW / DPL / DPC / etc.:

Development is done in [lx2160a_build: branch "develop-ls-6.6.52-2.2.0"](https://github.com/SolidRun/lx2160a_build/tree/develop-ls-6.6.52-2.2.0) first, it serves as the reference BSP for HW validation.
Patches should be copied without changes from lx2160a_build to this layer.
