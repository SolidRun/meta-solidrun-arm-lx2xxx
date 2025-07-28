# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/2024.04-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-pci-ls_pcie_g4-Wait-100ms-for-Link-Up-in-ls_pcie_g4_.patch \
            file://0002-pci-ls_pcie-Wait-100ms-for-Link-Up-in-ls_pcie_probe.patch \
            file://0003-fsl-lsch3-update-calculation-of-ddr-clock-rate-to-in.patch \
            file://0004-armv8-lx2160a-enable-workaround-for-SPI-erratum-A-05.patch \
            file://0005-cmd-tlv_eeprom-don-t-fail-boot-when-reading-eeprom-f.patch \
            file://0006-cmd-tlv_eeprom-support-specifying-tlv-eeprom-in-DT-a.patch \
            file://0007-gpio-mpc8xxx-fix-build-on-layerscape-arch.patch \
            file://0008-arch-arm-dts-fsl-lx2160a.dtsi-add-pcs-phys.patch \
            file://0009-arch-arm-dts-fsl-lx2160a.dtsi-add-psci-node.patch \
            file://0010-net-phy-marvell10g-add-support-for-88e2580-phy.patch \
            file://0011-add-solidrun-lx2160-cex7-board-support.patch \
            file://0012-board-solidrun-lx2160cex7-add-support-for-lx2162-som.patch \
            file://0013-board-solidrun-lx2160cex7-add-support-for-lx2162-cle.patch \
            file://0014-board-solidrun-lx2160cex7-add-support-for-clearfog-c.patch \
            file://0015-board-solidrun-lx2160cex7-configure-fan-controller-d.patch \
            file://0016-board-solidrun-lx2160cex7-fix-read-rcw-from-dcsr-mem.patch \
            file://0017-board-solidrun-lx2160cex7-add-support-for-half-twins.patch \
            file://0018-lib-optee-always-copy-optee-to-OS-DTB-regardless-if-.patch \
            file://0019-board-solidrun-lx2160cex7-fix-xspi-flash-compatible-.patch \
            file://0020-board-solidrun-lx2160acex7-fix-serdes-lane-dpmac-swa.patch \
            file://0021-lib-optee-fix-adding-optee-subnode-if-not-present.patch \
            file://0022-board-solidrun-lx2160cex7-setup-retimers-for-active-.patch \
            file://0023-board-solidrun-disable-some-unused-config-options.patch \
            file://0024-board-solidrun-lx2160acex7-fix-various-mistakes-in-s.patch \
            file://0025-board-solidrun-lx2160acex7-disable-disabled-ports-pr.patch \
            file://0026-cmd-add-ds250dfx10-control.patch \
            file://0027-cmd-ds250dfx10-add-prbs-validation-command-for-timed.patch \
            file://0028-board-solidrun-lx2160acex7-fixup-sata-pci-port-statu.patch \
            file://0029-board-solidrun-lx2160acex7-service-watchdog-before-s.patch \
            file://0030-board-solidrun-lx2160acex7-fix-secondary-pci-ports-s.patch \
            file://0031-cmd-ds250dfx10-fix-colour-for-less-than-2048-add-leg.patch \
            file://0032-board-solidrun-lx2160acex7-fix-lx2162-clearfog-retim.patch \
            file://0033-cmd-ds250dfx10-add-machine-readable-markers-before-a.patch \
            file://0034-pci-ls_pcie-ls_pcie_g4-fix-compiler-warning-for-dela.patch \
            file://0035-board-solidrun-lx2160acex7-change-fan-speed-for-lx21.patch \
            file://0036-cmd-ds250dfx10-change-eye-diagram-commabd-behaviour.patch \
"

# Override default fdtfile for boards without dedicated uboot config
SRC_URI:append:lx2160a-rev2-cex6-evb = " file://lx2160acex6-evb-fdtfile.cfg"
SRC_URI:append:lx2160a-honeycomb = " file://lx2160acex7-honeycomb-fdtfile.cfg"
SRC_URI:append:lx2160a-rev2-honeycomb = " file://lx2160acex7-honeycomb-fdtfile.cfg"
SRC_URI:append:lx2162a-rev2-clearfog = " file://lx2162asom-clearfog-fdtfile.cfg"

# do_configure step requires merge_config.sh in the path, provided by kern-tools-native package.
# While poky/meta/recipes-bsp/u-boot/u-boot-configure.inc lists this dependency, it is missing a space and does not take effect.
# Repeat dependency here surrounded by spaces.
DEPENDS:append = " kern-tools-native "
