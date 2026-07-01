# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add SolidRun patches
SRC_URI += "file://0001-add-solidrun-lx2160-cex7-based-clearfog-cx-dpl-dpc.patch \
            file://0002-add-solidrun-lx2160-cex6-based-evaluation-board-dpl-.patch \
            file://0003-add-configuration-for-lx2162a-som-and-clearfog-board.patch \
            file://0004-lx2162-som-clearfog-enable-dpni-connections.patch \
            file://0005-lx2160acex7-clearfog-cx-configure-qsfp-ports-type-ph.patch \
            file://0006-lx2160acex7-clearfog-cx-add-qsfp-40g-4x-10g-configur.patch \
            file://0007-lx2160acex7-add-configuration-for-solidrun-internal-.patch \
            file://0008-lx2160acex7-clearfog-cx-s1_8-s2_0-dpc-allow-modifyin.patch \
            file://0009-lx2160acex7-twins-change-mac-type-from-phy-to-backpl.patch \
            file://0010-lx2160acex7-twins-add-separate-half-twins-configurat.patch \
            file://0011-lx2160acex7-twins-enable-network-interfaces-by-defau.patch \
"
