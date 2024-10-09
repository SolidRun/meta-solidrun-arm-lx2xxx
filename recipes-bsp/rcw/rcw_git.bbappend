# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add SolidRun patches
SRC_URI += "file://0001-add-configuration-solidrun-lx2160a-cex-7-on-clearfog.patch \
            file://0002-lx2160acex7-move-MEM_PLL_CFG-into-ddr-speed-specific.patch \
            file://0003-lx2160acex7-add-separate-configurations-for-flexspi-.patch \
            file://0004-lx2160acex7-rename-sdhc1-config-to-generic-sdhc-for-.patch \
            file://0005-add-loadc-jumpc-and-jump-to-pbi-instructions.patch \
            file://0006-lx2160acex7-add-configuration-for-both-sdhc-xspi.patch \
            file://0007-bootlocptr-reduce-size-of-pbi-section.patch \
            file://0008-lx2160acex7-change-2.2GHz-configuration-platform-clo.patch \
            file://0009-lx2160acex7-add-configuration-for-fraction-ddr-speed.patch \
"

BOARD_TARGETS:lx2160acex7 = "lx2160acex7 lx2160acex7_rev2"
BOARD_TARGETS:lx2160acex7-rev2 = "lx2160acex7 lx2160acex7_rev2"
