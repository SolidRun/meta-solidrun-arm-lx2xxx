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
"

# Enable non-default kernel configs
SRC_URI:append = " file://amdgpu.scc"
SRC_URI:append = " file://lx2160acex6-drivers.scc"

# linux-qoriq_5.15.bb does not support scc style fragments, add to DELTA_KERNEL_DEFCONFIG instead.
SRC_URI:append = " file://amdgpu.cfg file://lx2160acex6-drivers.cfg"
DELTA_KERNEL_DEFCONFIG:append = " amdgpu.cfg lx2160acex6-drivers.cfg "
