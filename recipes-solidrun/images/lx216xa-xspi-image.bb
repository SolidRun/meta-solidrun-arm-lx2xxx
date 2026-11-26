SUMMARY = "Raw XSPI Flash Image for LX2160A"
DESCRIPTION = "Stitches together RCW, ATF, U-Boot, and MC firmware into a raw binary for XSPI, \
a flashrom layout file describing its regions, and a bmap file of the blocks with content"
LICENSE = "MIT"

# This recipe doesn't produce a rootfs, it just packages binaries
inherit deploy

# bmaptool for the bmap file (python script, needs python3-native like image_types.bbclass)
DEPENDS += "bmaptool-native python3-native"
EXTRANATIVEPATH += "python3-native"

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

# flash size in MiB and regions for the boot media layout of the selected boot flash
# (LX2160A_BOOTFLASH, conf/machine/include/lx216xa-solidrun.inc)
XSPI_SIZE = "${XSPI_SIZE_${LX216XA_BOOTFLASH_SIZE_${LX2160A_BOOTFLASH}}}"
XSPI_REGIONS = "${XSPI_REGIONS_${LX216XA_BOOTFLASH_SIZE_${LX2160A_BOOTFLASH}}}"

# 64MB layout, same as lx2160a_build runme.sh do_populate_bootimg_64M:
# <name>:<offset in 512-byte blocks>:<max size in bytes>:<content>
# content is one of:
# - file in DEPLOY_DIR_IMAGE; alternatives separated by ",", the first one existing is used
# - "zero": region is filled with zeros
# - "erased": region is filled with 0xff like erased flash (e.g. u-boot environment)
XSPI_SIZE_64M = "64"
XSPI_REGIONS_64M = " \
    pbl:0:1048576:atf/bl2_auto.pbl,atf/bl2_flexspi_nor.pbl \
    fip:2048:4194304:atf/fip_uboot.bin \
    env:10240:131072:erased \
    ddr_fip:16384:2097152:ddr-phy/fip_ddr.bin \
    mc:20480:3145728:mc_app/mc.itb \
    dpl:26624:1048576:mc-utils/${MC_DPL} \
    dpc:28672:1048576:mc-utils/${MC_DPC} \
    dtb:30720:1048576:${DTB_NAME} \
    kernel:32768:50331648:Image.gz \
"

# 4MB layout, same as lx2160a_build runme.sh do_populate_bootimg_4M, without kernel
XSPI_SIZE_4M = "4"
XSPI_REGIONS_4M = " \
    pbl:0:131072:atf/bl2_auto.pbl,atf/bl2_flexspi_nor.pbl \
    ddr_fip:256:131072:ddr-phy/fip_ddr.bin \
    fip:512:1769472:atf/fip_uboot.bin \
    env:3968:65536:erased \
    mc:4352:1835008:mc_app/mc.itb \
    dtb:7936:102400:${DTB_NAME} \
    mc_sig:8136:4096:zero \
    dpc_sig:8144:4096:zero \
    dpl_sig:8152:4096:zero \
    dpc:8160:2048:mc-utils/${MC_DPC} \
    dpl:8164:14336:mc-utils/${MC_DPL} \
"

do_compile() {
    rm -f ${B}/xspi.bin ${B}/xspi.layout ${B}/xspi.bmap ${B}/xspi.sparse

    # Create a flash image filled with 0xFF (erased Flash)
    tr '\000' '\377' < /dev/zero | dd of=${B}/xspi.bin bs=1M count=${XSPI_SIZE} iflag=fullblock

    # Place each region at its offset (conv=notrunc keeps the rest),
    # and record it in a flashrom layout file (<start>:<end> <name>), like runme.sh do_layout_add
    : > ${B}/xspi.layout
    # 4KiB blocks of regions with content (<first block>:<number of blocks>), for the bmap file
    bmap_blocks=
    for region in ${XSPI_REGIONS}; do
        oldifs="$IFS"
        IFS=":"
        set -- $region
        IFS="$oldifs"
        name=$1
        offset=$2
        maxsize=$3
        content=$4

        case "$content" in
        erased)
            size=$maxsize
            tr '\000' '\377' < /dev/zero | dd of=${B}/xspi.bin conv=notrunc bs=512 seek=$offset \
                count=$(expr $size / 512) iflag=fullblock
            ;;
        zero)
            size=$maxsize
            dd if=/dev/zero of=${B}/xspi.bin conv=notrunc bs=512 seek=$offset count=$(expr $size / 512)
            ;;
        *)
            file=
            for f in $(echo "$content" | tr ',' ' '); do
                if [ -e ${DEPLOY_DIR_IMAGE}/$f ]; then
                    file=${DEPLOY_DIR_IMAGE}/$f
                    break
                fi
            done
            if [ -z "$file" ]; then
                bbfatal "xspi region $name: none of $content found in ${DEPLOY_DIR_IMAGE}"
            fi
            size=$(stat -L -c "%s" $file)
            if [ $size -gt $maxsize ]; then
                bbfatal "xspi region $name: $file is $size bytes, larger than $maxsize"
            fi
            dd if=$file of=${B}/xspi.bin conv=notrunc bs=512 seek=$offset
            ;;
        esac

        if [ $size -gt 0 ]; then
            # expr returns non-zero status when the result is 0
            start=$(expr $offset \* 512 || true)
            end=$(expr $start + $size - 1 || true)
            printf "%08x:%08x %s\n" $start $end $name >> ${B}/xspi.layout
            first=$(expr $start / 4096 || true)
            last=$(expr $end / 4096 || true)
            bmap_blocks="$bmap_blocks $first:$(expr $last - $first + 1)"
        fi
    done

    # regions must not have grown the image
    if [ $(stat -c "%s" ${B}/xspi.bin) -ne $(expr ${XSPI_SIZE} \* 1048576) ]; then
        bbfatal "xspi image exceeds ${XSPI_SIZE} MiB"
    fi

    # bmap file mapping only the blocks of regions with content, e.g. for bmaptool copy:
    # create it from a sparse copy of the image holding just these blocks,
    # so that the checksums match xspi.bin (unallocated gaps between regions are not mapped)
    truncate -s $(stat -c "%s" ${B}/xspi.bin) ${B}/xspi.sparse
    for blocks in $bmap_blocks; do
        dd if=${B}/xspi.bin of=${B}/xspi.sparse conv=notrunc bs=4096 \
            skip=${blocks%:*} seek=${blocks%:*} count=${blocks#*:}
    done
    bmaptool create -o ${B}/xspi.bmap ${B}/xspi.sparse
    rm -f ${B}/xspi.sparse
}

# deployed file names, the image for the backup boot flash is named xspi_backup like in lx2160a_build
XSPI_DEPLOY_NAME_primary = "${PN}-${MACHINE}"
XSPI_DEPLOY_NAME_secondary = "${PN}-${MACHINE}-backup"
XSPI_DEPLOY_NAME = "${XSPI_DEPLOY_NAME_${LX2160A_BOOTFLASH}}"
XSPI_LINK_NAME_primary = "xspi"
XSPI_LINK_NAME_secondary = "xspi_backup"
XSPI_LINK_NAME = "${XSPI_LINK_NAME_${LX2160A_BOOTFLASH}}"

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/xspi.bin ${DEPLOYDIR}/${XSPI_DEPLOY_NAME}.bin
    install -m 0644 ${B}/xspi.layout ${DEPLOYDIR}/${XSPI_DEPLOY_NAME}.layout
    install -m 0644 ${B}/xspi.bmap ${DEPLOYDIR}/${XSPI_DEPLOY_NAME}.bmap
    ln -sf ${XSPI_DEPLOY_NAME}.bin ${DEPLOYDIR}/${XSPI_LINK_NAME}.bin
    ln -sf ${XSPI_DEPLOY_NAME}.layout ${DEPLOYDIR}/${XSPI_LINK_NAME}.layout
    ln -sf ${XSPI_DEPLOY_NAME}.bmap ${DEPLOYDIR}/${XSPI_LINK_NAME}.bmap
}

addtask deploy after do_compile
