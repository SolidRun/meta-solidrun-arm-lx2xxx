# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/qoriq-atf-2.6:"

# Add SolidRun patches
SRC_URI += "file://0001-plat-nxp-lx2160a-auto-boot.patch \
            file://0002-dcfg-Take-into-account-MEM_PLL_CFG_SHIFT-for-ddr-fre.patch \
"

PLATFORM:lx2160acex7 = "lx2160ardb"
PLATFORM:lx2160acex7-rev2 = "lx2160ardb"
