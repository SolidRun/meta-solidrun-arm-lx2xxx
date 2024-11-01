# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/5.15-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-arm64-dts-lx2160a-cex7-add-gpio-hog-for-fan-controll.patch \
            file://0002-net-phy-Add-support-for-AQR113C-EPHY.patch \
            file://0003-phy-lynx-28g-add-support-for-specifying-unmanaged-la.patch \
            file://0004-arm64-dts-add-description-for-solidrun-lx2160a-cex6-.patch \
            file://0005-Revert-arm64-dts-lx2160a-update-PCIe-nodes-to-match-.patch \
            file://0006-arm64-dts-lx2160a-clearfog-itx-enable-pcie-nodes-for.patch \
            file://0007-arm64-dts-lx2160a-extend-32-bit-and-add-64-bit-pci-r.patch \
            file://0008-arm64-dts-lx2160a-cex6-evb-update-spi-bus-descriptio.patch \
            file://0009-arm64-dts-lx2160a-cex6-enable-optee-os.patch \
            file://0010-arm64-dts-lx2160a-cex7-enable-optee-os.patch \
            file://0011-arm64-dts-lx2160a-describe-the-SerDes-block-2.patch \
            file://0012-arm64-dts-freescale-Add-support-for-LX2162-SoM-Clear.patch \
            file://0013-arm64-dts-fsl-lx2162a-som-add-description-for-rtc.patch \
            file://0014-arm64-dts-fsl-lx2162a-clearfog-add-alias-for-i2c-bus.patch \
            file://0015-arm64-dts-lx2162a-sr-som-enable-optee-os.patch \
            file://0016-phy-lynx-28g-configure-more-equalization-params-for-.patch \
            file://0017-phy-lynx-28g-add-support-for-25GBASER.patch \
            file://0018-net-dpaa2-mac-add-25gbase-r-support.patch \
            file://0019-net-phy-marvell10g-add-initial-support-for-88x2580.patch \
            file://0020-phy-add-of_phy_get_by_index.patch \
            file://0021-net-dpaa2-add-support-for-retimer-phys.patch \
            file://0022-net-phy-create-driver-for-ds250df4x10-retimer.patch \
            file://0023-arm64-dts-lx2162-clearfog-add-description-for-retime.patch \
            file://0024-arm64-dts-lx2160a-clearfog-itx-set-fixed-link-for-qs.patch \
            file://0025-arm64-dts-lx2160a-clearfog-cx-add-description-for-re.patch \
"

# Enable non-default kernel configs
SRC_URI:append = " file://amdgpu.scc"
SRC_URI:append = " file://lx2160acex6-drivers.scc"
SRC_URI:append = " file://lx2160acex7-clearfog-cx-drivers.scc"
SRC_URI:append = " file://lx2162asom-clearfog-drivers.scc"

# linux-qoriq_5.15.bb does not support scc style fragments, add to DELTA_KERNEL_DEFCONFIG instead.
SRC_URI:append = " file://amdgpu.cfg"
SRC_URI:append = " file://lx2160acex6-drivers.cfg"
SRC_URI:append = " file://lx2160acex7-clearfog-cx-drivers.cfg"
SRC_URI:append = " file://lx2162asom-clearfog-drivers.cfg"
DELTA_KERNEL_DEFCONFIG:append = " amdgpu.cfg "
DELTA_KERNEL_DEFCONFIG:append = " lx2160acex6-drivers.cfg "
DELTA_KERNEL_DEFCONFIG:append = " lx2160acex7-clearfog-cx-drivers.cfg "
DELTA_KERNEL_DEFCONFIG:append = " lx2162asom-clearfog-drivers.cfg "
