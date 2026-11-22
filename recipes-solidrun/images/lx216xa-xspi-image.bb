SUMMARY = "Raw XSPI Flash Image for LX2160A"
DESCRIPTION = "Stitches together RCW, ATF, U-Boot, and MC firmware into a raw binary for XSPI, \
and a flashrom layout file describing its regions"
LICENSE = "MIT"

# This recipe doesn't produce a rootfs, it just packages binaries
inherit deploy

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

# flash size in MiB
XSPI_SIZE = "64"

# flash regions, same as lx2160a_build runme.sh do_populate_bootimg_64M:
# <name>:<offset in 512-byte blocks>:<max size in bytes>:<content>
# content is one of:
# - file in DEPLOY_DIR_IMAGE; alternatives separated by ",", the first one existing is used
# - "zero": region is filled with zeros
# - "none": region is left erased, but listed in the layout file (e.g. u-boot environment)
XSPI_REGIONS = " \
    pbl:0:1048576:atf/bl2_auto.pbl,atf/bl2_flexspi_nor.pbl \
    fip:2048:4194304:atf/fip_uboot.bin \
    env:10240:131072:none \
    ddr_fip:16384:2097152:ddr-phy/fip_ddr.bin \
    mc:20480:3145728:mc_app/mc.itb \
    dpl:26624:1048576:mc-utils/${MC_DPL} \
    dpc:28672:1048576:mc-utils/${MC_DPC} \
    dtb:30720:1048576:${DTB_NAME} \
    kernel:32768:50331648:Image.gz \
"

do_compile() {
    rm -f ${B}/xspi.bin ${B}/xspi.layout

    # Create a flash image filled with 0xFF (erased Flash)
    tr '\000' '\377' < /dev/zero | dd of=${B}/xspi.bin bs=1M count=${XSPI_SIZE} iflag=fullblock

    # Place each region at its offset (conv=notrunc keeps the rest),
    # and record it in a flashrom layout file (<start>:<end> <name>), like runme.sh do_layout_add
    : > ${B}/xspi.layout
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
        none)
            size=$maxsize
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
        fi
    done

    # regions must not have grown the image
    if [ $(stat -c "%s" ${B}/xspi.bin) -ne $(expr ${XSPI_SIZE} \* 1048576) ]; then
        bbfatal "xspi image exceeds ${XSPI_SIZE} MiB"
    fi
}

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/xspi.bin ${DEPLOYDIR}/${PN}-${MACHINE}.bin
    install -m 0644 ${B}/xspi.layout ${DEPLOYDIR}/${PN}-${MACHINE}.layout
    ln -sf ${PN}-${MACHINE}.bin ${DEPLOYDIR}/xspi.bin
    ln -sf ${PN}-${MACHINE}.layout ${DEPLOYDIR}/xspi.layout
}

addtask deploy after do_compile
