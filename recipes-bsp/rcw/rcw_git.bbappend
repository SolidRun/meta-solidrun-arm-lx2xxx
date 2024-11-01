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
            file://0010-add-configuration-solidrun-internal-lx2160a-cex6-eva.patch \
            file://0011-lx2160acex7-enable-A-050426-workaround-for-silicon-o.patch \
            file://0012-lx2160acex6-enable-pci-errata-workarounds-for-all-ac.patch \
            file://0013-lx2160acex6-add-configuration-for-2.2GHz-binned-soc.patch \
            file://0014-lx2162aqds-re-enable-dpmac11.patch \
            file://0015-add-configuration-for-lx2162a-som-and-clearfog-evalu.patch \
            file://0016-lx2160acex7-clearfog-cx-add-configuration-for-serdes.patch \
"

BOARD_TARGETS:lx2160a-cex6 = "lx2160acex6_rev2"
BOARD_TARGETS:lx2160a-cex7 = "lx2160acex7 lx2160acex7_rev2"
BOARD_TARGETS:lx2162a-som = "lx2162asom_rev2"
