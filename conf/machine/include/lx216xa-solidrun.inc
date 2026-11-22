require conf/machine/include/qoriq-arm64.inc
DEFAULTTUNE ?= "cortexa72-crypto"
require conf/machine/include/arm/armv8a/tune-cortexa72.inc

MACHINE_FEATURES:append = " optee "

KERNEL_CLASSES  = " kernel-fitimage "
KERNEL_IMAGETYPES = "fitImage Image.gz"

# install Image.gz to "Image" filename because wic image extlinux.conf generator does not recognise Image.gz.
# U-Boot decompresses it fine regardless
IMAGE_BOOT_FILES = " Image.gz;Image "

KERNEL_DEFCONFIG ?= "defconfig"

# select DTBs
KERNEL_DEVICETREE ?= " \
        freescale/fsl-lx2160a-cex6-evb.dtb \
        freescale/fsl-lx2160a-clearfog-cx.dtb \
        freescale/fsl-lx2160a-half-twins.dtb \
        freescale/fsl-lx2160a-honeycomb.dtb \
        freescale/fsl-lx2160a-twins-left.dtb \
        freescale/fsl-lx2160a-twins-right.dtb \
        freescale/fsl-lx2162a-clearfog.dtb \
"

# install DTBs with freescale/ prefix
IMAGE_BOOT_FILES:append = " \
    fsl-lx2160a-cex6-evb.dtb;freescale/fsl-lx2160a-cex6-evb.dtb \
    fsl-lx2160a-clearfog-cx.dtb;freescale/fsl-lx2160a-clearfog-cx.dtb \
    fsl-lx2160a-half-twins.dtb;freescale/fsl-lx2160a-half-twins.dtb \
    fsl-lx2160a-honeycomb.dtb;freescale/fsl-lx2160a-honeycomb.dtb \
    fsl-lx2160a-twins-left.dtb;freescale/fsl-lx2160a-twins-left.dtb \
    fsl-lx2160a-twins-right.dtb;freescale/fsl-lx2160a-twins-right.dtb \
    fsl-lx2162a-clearfog.dtb;freescale/fsl-lx2162a-clearfog.dtb \
"
# HACK: place one sentinel dtb without freescale/ prefix to fix wic image generated extlinux.conf fdtdir path
IMAGE_BOOT_FILES:prepend = " fsl-lx2160a-cex6-evb.dtb;sentinel.dtb "

SERIAL_CONSOLES:qoriq-arm64 = "115200;ttyAMA0"
SERIAL_CONSOLES ?= "115200;ttyAMA0"
SERIAL_CONSOLES_CHECK ?= "${SERIAL_CONSOLES}"

USE_VT = "0"

# Boot SPI flash, shared by u-boot, atf and the SPI image (lx216xa-xspi-image).
# Machine configurations define their primary boot SPI flash by
# LX216XA_BOOTFLASH_SIZE_primary (boot media layout "64M" or "4M") and
# LX216XA_BOOTFLASH_TYPE_primary (atf FLASH_TYPE), optionally a secondary boot SPI flash
# by LX216XA_BOOTFLASH_SIZE_secondary and LX216XA_BOOTFLASH_TYPE_secondary.
# LX2160A_BOOTFLASH (local.conf) selects one, like lx2160a_build runme.sh BOOTFLASH,
# recipes use e.g. ${LX216XA_BOOTFLASH_SIZE_${LX2160A_BOOTFLASH}}.
LX2160A_BOOTFLASH ??= "primary"

MACHINE_ESSENTIAL_EXTRA_RDEPENDS:append = " udev-solidrun-lx2xxx "

# generate sd-bootable wic image
WKS_FILE = "lx2160a-bootimg-mmc.wks.in"
WIC_CREATE_EXTRA_ARGS:remove = "--no-fstab-update"

# generate kernel image with appended initramfs
INITRAMFS_IMAGE_BUNDLE = "1"
