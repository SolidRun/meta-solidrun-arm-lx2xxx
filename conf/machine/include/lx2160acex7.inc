#@TYPE: Machine
#@NAME: SolidRun LX2160A CEX-7
#@SOC: LSCH3
#@DESCRIPTION: Machine configuration for SolidRun LX2160A Rev 1.0 COM-Express Type 7 Module

require conf/machine/include/qoriq-arm64.inc
DEFAULTTUNE ?= "cortexa72-crypto"
require conf/machine/include/arm/armv8a/tune-cortexa72.inc

MACHINEOVERRIDES =. "lx2160a-cex7:fsl-lsch3:lx2160a:"

MACHINE_FEATURES:append = " optee "

KERNEL_CLASSES  = " kernel-fitimage "
KERNEL_IMAGETYPES = "fitImage"

DTB_LOAD = "0x90000000"
UBOOT_ENTRYPOINT = "0x80080000"

UBOOT_CONFIG ?= "tfa-secure-boot tfa"
UBOOT_CONFIG[tfa] = "lx2160acex7_tfa_defconfig,,u-boot-dtb.bin"
UBOOT_CONFIG[tfa-secure-boot] = "lx2160ardb_tfa_SECURE_BOOT_defconfig,,u-boot-dtb.bin"

KERNEL_DEFCONFIG ?= "defconfig"

SERIAL_CONSOLES ?= "115200;ttyS0 115200;ttyS1 115200;ttyAMA0"
SERIAL_CONSOLES_CHECK ?= "${SERIAL_CONSOLES}"

LX2160A_BUS_SPEED ?= "700"
LX2160A_CPU_SPEED ?= "2000"
LX2160A_DDR_SPEED ?= "2900"

UEFI_XSPIBOOT ?= "LX2160ARDB_EFI_NORBOOT.fd"

EXTRA_IMAGEDEPENDS += "management-complex mc-utils rcw ls2-phy ddr-phy uefi qoriq-atf inphi"
USE_VT = "0"

# install the vendor-prefixed dtbs
# Note: must keep the non-prefixed versions in place,
# to ensure bootimg-partition.py does not mess with extlinux.conf fdtdir
IMAGE_BOOT_FILES:append = "${KERNEL_DEVICETREE}"

# select DPL/DPC source (config/lx2160a/LX2160A-<MC_FLAVOUR>)
MC_FLAVOUR ?= "CEX7"

RCW_FOLDER ?= "lx2160acex7"
