SUMMARY = "Raw XSPI Flash Image for LX2160A"
DESCRIPTION = "Stitches together RCW, ATF, U-Boot, and MC firmware into a raw binary for XSPI"
LICENSE = "MIT"

# This recipe doesn't produce a rootfs, it just packages binaries
inherit deploy

# Offsets in 512-byte sectors
OFFSET_BL2    = "0"
OFFSET_BL3    = "2048"
OFFSET_DDR    = "16384"
OFFSET_MC_FW  = "20480"
OFFSET_MC_DPL = "26624"
OFFSET_MC_DPC = "28672"
OFFSET_DTB    = "30720"
OFFSET_KERNEL = "32768"

# Dependencies: Ensure all firmware is built and deployed first
do_compile[depends] += " \
    qoriq-atf:do_deploy \
    ddr-phy:do_deploy \
    management-complex:do_deploy \
    mc-utils:do_deploy \
    virtual/kernel:do_deploy \
"

# Helper for the DTB filename logic we discussed earlier
DTB_NAME = "${@os.path.basename(d.getVar('UBOOT_FDT_FILE') or 'error')}"

do_compile() {
    # 1. Create a 64MB sparse file filled with 0xFF (typical for erased Flash)
    # Using 0xFF is better for Flash images than 0x00
    tr '\000' '\377' < /dev/zero | dd of=${B}/xspi.bin bs=1M count=64
    
    # 2. Use 'conv=notrunc' to write at specific offsets without wiping the rest
    dd if=${DEPLOY_DIR_IMAGE}/atf/bl2_auto.pbl  of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_BL2}
    dd if=${DEPLOY_DIR_IMAGE}/atf/fip_uboot.bin of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_BL3}
    dd if=${DEPLOY_DIR_IMAGE}/ddr-phy/fip_ddr.bin of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_DDR}
    dd if=${DEPLOY_DIR_IMAGE}/mc_app/mc.itb of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_MC_FW}
    dd if=${DEPLOY_DIR_IMAGE}/mc-utils/${MC_DPL} of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_MC_DPL}
    dd if=${DEPLOY_DIR_IMAGE}/mc-utils/${MC_DPC} of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_MC_DPC}
    dd if=${DEPLOY_DIR_IMAGE}/${DTB_NAME} of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_DTB}
    dd if=${DEPLOY_DIR_IMAGE}/Image.gz of=${B}/xspi.bin conv=notrunc bs=512 seek=${OFFSET_KERNEL}
}

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/xspi.bin ${DEPLOYDIR}/${PN}-${MACHINE}.bin
    ln -sf ${PN}-${MACHINE}.bin ${DEPLOYDIR}/xspi.bin
}

addtask deploy after do_compile
