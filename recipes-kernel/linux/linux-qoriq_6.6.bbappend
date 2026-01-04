# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/6.6-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-arm64-dts-freescale-Add-support-for-LX2162-SoM-Clear.patch \
            file://0002-arm64-dts-fsl-lx2162a-som-add-description-for-rtc.patch \
            file://0003-arm64-dts-fsl-lx2162a-clearfog-add-alias-for-i2c-bus.patch \
            file://0004-arm64-dts-lx2160a-cex7-add-interrupts-for-rtc-and-et.patch \
            file://0005-arm64-dts-lx2160a-clearfog-itx-enable-pcie-nodes-for.patch \
            file://0006-rtc-pcf2127-clear-minute-second-interrupt.patch \
            file://0007-arm64-dts-lx2160a-extend-32-bit-and-add-64-bit-pci-r.patch \
            file://0008-phy-lynx-28g-check-return-value-when-calling-lynx_28.patch \
            file://0009-net-phy-marvell10g-add-support-for-88e2580-multi-gig.patch \
            file://0010-net-phy-create-driver-for-ds250df4x10-retimer.patch \
            file://0011-arm64-dts-lx2162-clearfog-add-description-for-retime.patch \
            file://0012-arm64-dts-lx2160a-clearfog-cx-add-description-for-re.patch \
            file://0013-arm64-dts-add-description-for-solidrun-lx2160a-cex6-.patch \
            file://0014-arm64-dts-lx2160a-extend-32-bit-and-add-16-64-bit-pc.patch \
            file://0015-driver-core-release-resources-to-fix-standalone-dpaa.patch \
            file://0016-firmware-psci-issue-hard-reset-if-poweroff-fails.patch \
            file://0017-arm64-dts-lx2162a-clearfog-set-sfp-connector-leds-fu.patch \
            file://0018-Revert-driver-core-release-resources-to-fix-standalo.patch \
            file://0019-driver-core-print-name-of-bound-resources-preventing.patch \
            file://0020-net-dpaa2-mac-fully-release-dpmac-resources-on-dpni-.patch \
            file://0021-arm64-dts-fsl-lx2162a-sr-som-add-crypto-rtc-aliases-.patch \
            file://0022-arm64-dts-fsl-lx2160a-cex7-add-rtc-alias.patch \
            file://0023-arm64-dts-add-description-for-lx2160a-cex7-on-half-t.patch \
"

# Enable non-default kernel configs
SRC_URI:append = " file://amdgpu.scc"
SRC_URI:append = " file://lx2160acex6-drivers.scc"
SRC_URI:append = " file://lx2160acex7-clearfog-cx-drivers.scc"
SRC_URI:append = " file://lx2162asom-clearfog-drivers.scc"
SRC_URI:append = " file://pktgen.scc"
SRC_URI:append = " file://nftables-full.scc"
SRC_URI:append = " file://docker.scc"

# linux-qoriq_6.6.bb does not support scc style fragments, add to DELTA_KERNEL_DEFCONFIG instead.
SRC_URI:append = " file://amdgpu.cfg"
SRC_URI:append = " file://lx2160acex6-drivers.cfg"
SRC_URI:append = " file://lx2160acex7-clearfog-cx-drivers.cfg"
SRC_URI:append = " file://lx2162asom-clearfog-drivers.cfg"
SRC_URI:append = " file://pktgen.cfg"
SRC_URI:append = " file://nftables-full.cfg"
SRC_URI:append = " file://docker.cfg"
DELTA_KERNEL_DEFCONFIG:append = " amdgpu.cfg "
DELTA_KERNEL_DEFCONFIG:append = " lx2160acex6-drivers.cfg "
DELTA_KERNEL_DEFCONFIG:append = " lx2160acex7-clearfog-cx-drivers.cfg "
DELTA_KERNEL_DEFCONFIG:append = " lx2162asom-clearfog-drivers.cfg "
DELTA_KERNEL_DEFCONFIG:append = " pktgen.cfg "
DELTA_KERNEL_DEFCONFIG:append = " nftables-full.cfg "
DELTA_KERNEL_DEFCONFIG:append = " docker.cfg "
