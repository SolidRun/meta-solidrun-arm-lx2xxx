# select DPL/DPC (config/lx2160a/LX2160A-<MC_FLAVOUR>/<DPL/DPC>)
# variable consumed in wks files
MC_DPC ?= "clearfog-cx-s1_8-s2_0-dpc.dtb"
MC_DPL ?= "clearfog-cx-s1_8-s2_0-dpl.dtb"

# select RCW
BOOTTYPE ?= "flexspi_nor sd emmc auto"
RCWXSPI ?= "clearfog-cx/rcw_${LX2160A_CPU_SPEED}_${LX2160A_BUS_SPEED}_${LX2160A_DDR_SPEED}_18_5_2_xspi"
RCWSD ?= "clearfog-cx/rcw_${LX2160A_CPU_SPEED}_${LX2160A_BUS_SPEED}_${LX2160A_DDR_SPEED}_18_5_2_sdhc"
RCWEMMC ?= "clearfog-cx/rcw_${LX2160A_CPU_SPEED}_${LX2160A_BUS_SPEED}_${LX2160A_DDR_SPEED}_18_5_2_sdhc"
RCWAUTO ?= "clearfog-cx/rcw_${LX2160A_CPU_SPEED}_${LX2160A_BUS_SPEED}_${LX2160A_DDR_SPEED}_18_5_2_auto"

# select DTB
UBOOT_FDT ?= "fsl-lx2160a-clearfog-cx"
UBOOT_FDT_FILE ?= "freescale/fsl-lx2160a-clearfog-cx.dtb"

# secondary (backup) boot flash on the carrier, see LX2160A_BOOTFLASH in lx216xa-solidrun.inc
LX216XA_BOOTFLASH_SIZE_secondary ?= "4M"
LX216XA_BOOTFLASH_TYPE_secondary ?= "W25Q32"
# The carrier selects the secondary flash at boot (BIOS_DIS0# override),
# which swaps xspi chip-selects 0 and 1: machine override xspi-swapped-cs.
LX216XA_BOOTFLASH_OVERRIDES_primary = ""
LX216XA_BOOTFLASH_OVERRIDES_secondary = "xspi-swapped-cs:"
MACHINEOVERRIDES =. "${LX216XA_BOOTFLASH_OVERRIDES_${LX2160A_BOOTFLASH}}"
