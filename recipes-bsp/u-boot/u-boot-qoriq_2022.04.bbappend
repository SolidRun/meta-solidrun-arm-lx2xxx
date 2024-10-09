# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/2022.04-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-add-solidrun-lx2160-cex7-board-support.patch \
            file://0002-pci-ls_pcie_g4-Wait-100ms-for-Link-Up-in-ls_pcie_g4_.patch \
            file://0003-pci-ls_pcie-Wait-100ms-for-Link-Up-in-ls_pcie_probe.patch \
            file://0004-fsl-lsch3-update-calculation-of-ddr-clock-rate-to-in.patch \
"
