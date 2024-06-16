# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add SolidRun patches
SRC_URI += "file://0001-add-solidrun-lx2160-cex7-based-clearfog-cx-dpl-dpc.patch \
"
