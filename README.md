# SolidRun LX2160A Yocto BSP

## Build Instructions

Start in a **new empty directory** with plenty of free disk space - at least 30GB, Then:

1. download the build recipes:

   ```
   repo init -u https://github.com/nxp-qoriq/yocto-sdk.git -b kirkstone -m ls-5.15.71-2.2.0.xml
   repo sync
   git clone -b kirkstone https://github.com/SolidRun/meta-solidrun-arm-lx2xxx.git sources/meta-solidrun-arm-lx2xxx
   ```

2. apply downstream patches to dependent layers:

   - `poky`: add support for wic images without partition table (for xspi image)

      ```
      pushd sources/poky
      git am ../../meta-solidrun-arm-lx2xxx/patches/poky/0001-wic-add-supppport-for-generating-images-without-part.patch
      popd
      ```

3. Initialise a build directory with example configuration files based on lx2160ardb, and appropriate shell environment variables:

       source ./setup-env -m lx2160ardb-rev2 -b build_lx2160acex7-rev2

4. Adapt example configuration files for SolidRun LX2160A CEX7:

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

| Machine          | Description                                                                                |
| ---------------- | ------------------------------------------------------------------------------------------ |
| lx2160acex7      | LX2160A COM-Express 7 on Clearfog-CX / Honeycomb LX2160A Silicon 1.0 (preview version)     |
| lx2160acex7-rev2 | LX2160A COM-Express 7 on Clearfog-CX / Honeycomb, LX2160A Silicon 2.0 (production version) |

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

- `700` only for LX2160A binned 2GHz and higher (default)
- `750` (for over-clocking, or for specifically purchased 2.2GHz binned SoC)

## Known Issues

## Failed to spawn fakeroot worker: [Errno 32] Broken pipe

On systems with glibc newer than 2.36 builds will fail when either:

- libfakeroot had been built against glibc later than 2.36
- host system glibc is later than 2.36

Yocto uninative package can be updated for glibc-2.40 by cherry-picking a few commits from yocto kirkstone branch into NXPs BSP:

    cd bsp/sources/poky
    git cherry-pick 2890968bbce028efc47a19213f4eff2ccaf7b979
    git cherry-pick bba090696873805e44b1f7b3278ef8369763a176
    git cherry-pick aab6fc20de9473d8d7f277332601cbae70c53320
    git cherry-pick 43b94d2b8496eae6e512c6deb291b5908b7ada47
    git cherry-pick b8fded3df36ab206eaf3bc25b75acda2544679c5
    git cherry-pick b4b545cd9d3905253c398a6a42a9bc13c42073be
    git cherry-pick ad9420b072896b6a58a571c8123bcb17a813a1e7
    git cherry-pick 529c7c30e6a1b7e1e8a5ba5ba70b8f2f2af770ec
    git cherry-pick b36affbe96b2f9063f75e11f64f5a8ead1cb5c55
    git cherry-pick 8190d9c754c9c3a1962123e1e86d99de96c1224c

Cache must also be cleared before the next build can succeed:

    cd bsp/build
    rm -rf tmp sstate-cache cache

## Maintainer Notes

### Patching Linux / U-Boot / ATF / RCW / DPL / DPC / etc.:

Development is done in [lx2160a_build: branch "develop-ls-5.15.71-2.2.0"](https://github.com/SolidRun/lx2160a_build/tree/develop-ls-5.15.71-2.2.0) first, it serves as the reference BSP for HW validation.
Patches should be copied without changes from lx2160a_build to this layer.
