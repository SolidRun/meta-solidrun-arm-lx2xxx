# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add SolidRun patches
SRC_URI += "file://0001-add-configuration-solidrun-lx2160a-cex-7-on-clearfog.patch \
"

BOARD_TARGETS:lx2160acex7 = "lx2160acex7 lx2160acex7_rev2"
BOARD_TARGETS:lx2160acex7-rev2 = "lx2160acex7 lx2160acex7_rev2"
