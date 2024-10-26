# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/2022.04-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-add-solidrun-lx2160-cex7-board-support.patch \
            file://0002-pci-ls_pcie_g4-Wait-100ms-for-Link-Up-in-ls_pcie_g4_.patch \
            file://0003-pci-ls_pcie-Wait-100ms-for-Link-Up-in-ls_pcie_probe.patch \
            file://0004-fsl-lsch3-update-calculation-of-ddr-clock-rate-to-in.patch \
            file://0005-armv8-lx2160a-enable-workaround-for-SPI-erratum-A-05.patch \
            file://0006-configs-lx2160-cex7-enable-additional-drivers.patch \
"

# Override default fdtfile for boards without dedicated uboot config
SRC_URI:append:lx2160acex6-rev2 = " file://lx2160acex6-evb-fdtfile.cfg"

# do_configure step requires merge_config.sh in the path, provided by kern-tools-native package.
# While poky/meta/recipes-bsp/u-boot/u-boot-configure.inc lists this dependency, it is missing a space and does not take effect.
# Repeat dependency here surrounded by spaces.
DEPENDS:append = " kern-tools-native "
