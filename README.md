# SolidRun LX2160A Yocto BSP

## Build Instructions

Start in a **new empty directory** with plenty of free disk space - at least 30GB, Then:

1. download the build recipes:

   ```
   repo init -u https://github.com/nxp-qoriq/yocto-sdk.git -b scarthgap -m ls-6.6.52-2.2.0.xml
   repo sync
   git clone -b scarthgap https://github.com/SolidRun/meta-solidrun-arm-lx2xxx.git sources/meta-solidrun-arm-lx2xxx
   ```

2. apply downstream patches to dependent layers:

   - `poky`: add support for wic images without partition table (for xspi image)

      ```
      pushd sources/poky
      git am ../meta-solidrun-arm-lx2xxx/patches/poky/0001-wic-add-supppport-for-generating-images-without-part.patch
      popd
      ```

3. Initialise a build directory with example configuration files based on lx2160ardb, and appropriate shell environment variables:

       source ./setup-env -m lx2160ardb-rev2 -b build_lx2160a-rev2-honeycomb

4. Adapt example configuration files for SolidRun LX2160A Honeycomb:

   - edit `build_lx2160acex7-rev2/conf/bblayers.conf`:

     Append path to meta-solidrun-arm-lx2xxx:

         BBLAYERS += " <insert-your-workdir>/sources/meta-solidrun-arm-lx2xxx"

   - edit `build_lx2160acex7/conf/local.conf`:

     Set machine to `lx2160a-rev2-honeycomb`:

     ```diff
     -MACHINE ??= 'lx2160ardb-rev2'
     +MACHINE ??= 'lx2160a-rev2-honeycomb'
     ```

   - See below for additional configuration options.

5. Build nxp image `fsl-image-networking`:

       bitbake fsl-image-networking

6. Generate bootable disk image:

   NXP QorIQ Layers by default do not assemble full bootable disk images,
   users are expected to install all components to various offsets manually.

   SolidRun provides [wic](https://docs.yoctoproject.org/dev/dev-manual/wic.html) configuration files for generating bootable disk images from the build artifacts.
   This process can be launched after a successful build:

   - SD-Card / eMMC (includes rootfs):

         wic create lx2160a-bootimg-mmc -e fsl-image-networking

     This generates a bootable disk image named `lx2160a-bootimg-mmc.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to SD-Card or eMMC data partition, from the previously built `fsl-image-networking` target.

   - SPI Flash (without rootfs):

         wic create lx2160a-bootimg-xspi -e fsl-image-networking

     This generates a bootable spi flash image named `lx2160a-bootimg-xspi.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to SPI flash, from the previously built `fsl-image-networking` target's bootloader parts.

   - SD-Card / eMMC / USB / SATA / NVMe (rootfs only):

         wic create lx2160a-rootimg -e fsl-image-networking

     This generates a bootable disk image named `lx2160a-rootimg.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to any block storage, from the previously built `fsl-image-networking`.
     It comes with kernel + rootfs only, use on separate media, together with an SD or SPI boot image.

Note: The build environment and ability to run `bitbake` is lost when closing the terminal or rebooting.
It can be restored at any time by entering the build directory and sourcing the aut-generated `SOURCE_THIS` file:

```
cd <insert-your-workdir>/build_lx2160acex7-rev2
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
| lx2162a-rev2-clearfog    | LX2162A SoM on Clearfog                                                        |

### Supported Images

This Layer supports the following images:

| Image                     | Description                                                                    |
| ------------------------- | ------------------------------------------------------------------------------ |
| fsl-image-networking      | Typical networking features and basic cli utilities                            |
| fsl-image-networking-full | Demo of all packages tested by NXP including dpdk, dpdk examples and vpp       |

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

## Maintainer Notes

### Patching Linux / U-Boot / ATF / RCW / DPL / DPC / etc.:

Development is done in [lx2160a_build: branch "develop-ls-6.6.52-2.2.0"](https://github.com/SolidRun/lx2160a_build/tree/develop-ls-6.6.52-2.2.0) first, it serves as the reference BSP for HW validation.
Patches should be copied without changes from lx2160a_build to this layer.
