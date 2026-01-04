#@TYPE: Machine
#@NAME: SolidRun LX2160A CEX-7
#@SOC: LSCH3
#@DESCRIPTION: Machine configuration for SolidRun LX2160A Rev 1.0 COM-Express Type 7 Module

MACHINEOVERRIDES =. "lx2160a-cex7:"

DTB_LOAD = "0x90000000"
UBOOT_ENTRYPOINT = "0x80080000"

UBOOT_CONFIG ??= "tfa-secure-boot tfa"
UBOOT_CONFIG[tfa] = "lx2160acex7_tfa_defconfig,,u-boot-dtb.bin"
UBOOT_CONFIG[tfa-secure-boot] = "lx2160ardb_tfa_SECURE_BOOT_defconfig,,u-boot-dtb.bin"

ATF_PLATFORM ?= "lx2160acex7"

LX2160A_BUS_SPEED ?= "700"
LX2160A_CPU_SPEED ?= "2000"
LX2160A_DDR_SPEED ?= "2900"

UEFI_XSPIBOOT ?= "LX2160ARDB_EFI_NORBOOT.fd"

EXTRA_IMAGEDEPENDS += "management-complex mc-utils rcw ls2-phy ddr-phy qoriq-atf"

# select DPL/DPC source (config/lx2160a/LX2160A-<MC_FLAVOUR>)
MC_FLAVOUR ?= "CEX7"

RCW_FOLDER ?= "lx2160acex7"
RCW_BOARDS ?= "lx2160acex7 lx2160acex7_rev2"

# generate sd-bootable wic image
WKS_FILE ?= "lx2160a-bootimg-mmc.wks.in"
