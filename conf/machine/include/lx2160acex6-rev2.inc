#@TYPE: Machine
#@NAME: SolidRun LX2160A CEX-6
#@SOC: LSCH3
#@DESCRIPTION: Machine configuration for SolidRun Internal LX2160A Rev 2.0 COM-Express Type 6 Module

MACHINEOVERRIDES =. "lx2160a-cex6:"

DTB_LOAD = "0x90000000"
UBOOT_ENTRYPOINT = "0x80080000"

UBOOT_CONFIG ??= "tfa-secure-boot tfa"
UBOOT_CONFIG[tfa] = "lx2160acex7_tfa_defconfig,,u-boot-dtb.bin"
UBOOT_CONFIG[tfa-secure-boot] = "lx2160ardb_tfa_SECURE_BOOT_defconfig,,u-boot-dtb.bin"

ATF_PLATFORM ?= "lx2160acex6"

LX2160A_BUS_SPEED ?= "700"
LX2160A_CPU_SPEED ?= "2000"
LX2160A_DDR_SPEED ?= "2900"

UEFI_XSPIBOOT ?= "LX2160ARDB_EFI_NORBOOT.fd"

EXTRA_IMAGEDEPENDS += "management-complex mc-utils rcw ls2-phy ddr-phy qoriq-atf"

# select DPL/DPC source (config/lx2160a/LX2160A-<MC_FLAVOUR>)
MC_FLAVOUR ?= "CEX6"

# select rev2 rcw
RCW_FOLDER ?= "lx2160acex6_rev2"
RCW_BOARDS ?= "lx2160acex6_rev2"

# generate sd-bootable wic image
WKS_FILE ?= "lx2160a-bootimg-mmc.wks.in"
