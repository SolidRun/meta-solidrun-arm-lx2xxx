# select DTBs
KERNEL_DEVICETREE ?= " \
	freescale/fsl-lx2160a-clearfog-cx.dtb \
	freescale/fsl-lx2160a-honeycomb.dtb \
"

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
