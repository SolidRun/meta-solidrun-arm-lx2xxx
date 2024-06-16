# SolidRun LX2160A Yocto BSP

## Build Instructions

Start in a **new empty directory** with plenty of free disk space - at least 30GB, Then:

1. download the build recipes:

   ```
   repo init -u https://github.com/nxp-qoriq/yocto-sdk.git -b kirkstone -m ls-5.15.71-2.2.0.xml
   repo sync
   git clone https://github.com/SolidRun/meta-solidrun-arm-lx2xxx.git sources/meta-solidrun-arm-lx2xxx
   ```

2. Initialise a build directory with example configuration files based on lx2160ardb, and appropriate shell environment variables:

       source ./setup-env -m lx2160ardb-rev2 -b build_lx2160acex7-rev2

3. Adapt example configuration files for SolidRun LX2160A CEX7:

   - edit `build_lx2160acex7-rev2/conf/bblayers.conf`:

     Append path to meta-solidrun-arm-lx2xxx:

         BBLAYERS += " <insert-your-workdir>/sources/meta-solidrun-arm-lx2xxx"

   - edit `build_lx2160acex7/conf/local.conf`:

     Set machine to `lx2160acex7-rev2`:

     ```diff
     -MACHINE ??= 'lx2160ardb-rev2'
     +MACHINE ??= 'lx2160acex7-rev2'
     ```

   - See below for additional configuration options.

4. Build nxp image `fsl-image-networking`:

       bitbake fsl-image-networking

5. Generate bootable disk image:

   NXP QorIQ Layers by default do not assemble full bootable disk images,
   users are expected to install all components to various offsets manually.

   SolidRun provides [wic](https://docs.yoctoproject.org/dev/dev-manual/wic.html) configuration files for generating bootable disk images from the build artifacts.
   This process can be launched after a successful build:

   - SD-Card / eMMC (includes rootfs):

         wic create lx2160a-bootimg-sd -e fsl-image-networking

     This generates a bootable disk image named `lx2160a-bootimg-sd.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to SD-Card or eMMC data partition, from the previously built `fsl-image-networking` target.

Note: The build environment and ability to run `bitbake` is lost when closing the terminal or rebooting.
It can be restored at any time by entering the build directory and sourcing the aut-generated `SOURCE_THIS` file:

```
cd <insert-your-workdir>/build_lx2160acex7-rev2
source SOURCE_THIS
```

## Options

### Supported Machines

This Layer supports the following machines:

| Machine          | Description                                                                                |
| ---------------- | ------------------------------------------------------------------------------------------ |
| lx2160acex7      | LX2160A COM-Express 7 on Clearfog-CX / Honeycomb LX2160A Silicon 1.0 (preview version)     |
| lx2160acex7-rev2 | LX2160A COM-Express 7 on Clearfog-CX / Honeycomb, LX2160A Silicon 2.0 (production version) |

### DDR Clock

DDR Clock can be configured in local.conf using `LX2160A_DDR_SPEED`, supported values are:

- `2400`
- `2600`
- `2900`
- `3200` (default)

### CPU Clock

CPU (Cortex A72) Clock can be configured in local.conf using `LX2160A_CPU_SPEED`, supported values are:

- `2000` (default, recommended)
- `2200` (for over-clocking, or for specifically purchased 2.2GHz binned SoC)

## Maintainer Notes

### Patching Linux / U-Boot / ATF / RCW / DPL / DPC / etc.:

Development is done in [lx2160a_build: branch "develop-ls-5.15.71-2.2.0"](https://github.com/SolidRun/lx2160a_build/tree/develop-ls-5.15.71-2.2.0) first, it serves as the reference BSP for HW validation.
Patches should be copied without changes from lx2160a_build to this layer.
