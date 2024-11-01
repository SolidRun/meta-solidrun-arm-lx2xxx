# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add SolidRun patches
SRC_URI += "file://0001-add-solidrun-lx2160-cex7-based-clearfog-cx-dpl-dpc.patch \
            file://0002-add-solidrun-lx2160-cex6-based-evaluation-board-dpl-.patch \
            file://0003-add-configuration-for-lx2162a-som-and-clearfog-board.patch \
            file://0004-lx2162-som-clearfog-enable-dpni-connections.patch \
            file://0005-lx2160acex7-clearfog-cx-configure-qsfp-ports-type-ph.patch \
"
