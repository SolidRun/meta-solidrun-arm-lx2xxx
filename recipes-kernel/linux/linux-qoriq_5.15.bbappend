# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/5.15-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-arm64-dts-lx2160a-cex7-add-gpio-hog-for-fan-controll.patch \
"
