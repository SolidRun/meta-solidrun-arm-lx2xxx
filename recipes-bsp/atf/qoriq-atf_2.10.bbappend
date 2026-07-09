# ensure bc command is available during the build
DEPENDS += "bc-native"

# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/2.10-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-fiptool-disable-pedantic-flag-to-avoid-errors-with-o.patch \
            file://0002-plat-nxp-lx2160a-auto-boot.patch \
            file://0003-dcfg-Take-into-account-MEM_PLL_CFG_SHIFT-for-ddr-fre.patch \
            file://0004-lx2160a-assert-optional-S5-gpio-from-Makefile-consta.patch \
            file://0005-lx2160a-support-flexible-value-for-CONFIG_DDR_NODIMM.patch \
            file://0006-plat-nxp-layerscape-mmap-dynamic-configuration-regio.patch \
            file://0007-lx2160a-support-flushing-i2c-bus-before-ddr-init.patch \
            file://0008-nxp-ddr-dump-SPD-EEPROM-content-on-debug-builds.patch \
            file://0009-nxp-ddr-disarm-error-when-using-non-identical-DIMMs.patch \
            file://0010-nxp-ddr-add-debug-output-for-dimm-parameters-parsed-.patch \
            file://0011-plat-lx2160a-fix-building-without-NXP_NV_SW_MAINT_LA.patch \
            file://0012-plat-lx2160a-fix-boot-without-spi-flash-disable-non-.patch \
            file://0013-add-separate-platform-for-solidrun-cex7-module.patch \
            file://0014-add-separate-platform-for-solidrun-lx2162a-som.patch \
            file://0015-add-separate-platform-for-solidrun-internal-cex6-eva.patch \
            file://0016-psci-add-build-time-flag-to-disable-SYSTEM_OFF-funct.patch \
            file://0017-plat-lx2160a-support-build-time-override-for-fip-off.patch \
            file://0018-feat-driver-nxp-xspi-add-W25Q32-flash-info.patch \
            file://0019-plat-l2160acex7-add-build-time-settings-for-w25q32-f.patch \
            file://0020-plat-lx2160a-add-mechanism-for-board-specific-soc_ea.patch \
"

# set PLATFORM recipe variable from generic machine config ATF_PLATFORM if defined
PLATFORM = "${@d.getVar('ATF_PLATFORM') or d.getVar('MACHINE')}"

# extra solidrun build-time options
EXTRA_OEMAKE += " DISABLE_S5=${@d.getVar('ATF_DISABLE_S5') or '0'} "

# override original do_compile adding size check for rcwimg
# large images must be avoided such that no bl2 is generated for dysfunctional BOOTTYPE,
# ensuring later steps relying on them will fail.
#
#--- a/meta-qoriq-bsp/recipes-bsp/atf/qoriq-atf_2.10.bb
#+++ b/meta-qoriq-bsp/recipes-bsp/atf/qoriq-atf_2.10.bb
#@@ -82,6 +82,9 @@ python() {
# do_configure[noexec] = "1"
#
# do_compile() {
#+    # clean previous artifacts
#+    rm -f *.bin *.pbl *.pri *.pub
#+
#     if [ ! -f ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/srk.pri ]; then
#        ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/gen_keys 1024
#     else
#@@ -93,6 +96,7 @@ do_compile() {
#         ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/input_files/gen_fusescr/${chassistype}/input_fuse_file
#
#     for d in ${BOOTTYPE}; do
#+        rcwsize_max=4072
#         case $d in
#         nor)
#             rcwimg="${RCWNOR}${RCW_SUFFIX}"
#@@ -110,6 +114,8 @@ do_compile() {
#             ;;
#         auto)
#             rcwimg="${RCWAUTO}${RCW_SUFFIX}"
#+            # for auto-boot atf create_pbl does not append any additional instructions
#+            rcwsize_max=4096
#             ;;
#         sd)
#             rcwimg="${RCWSD}${RCW_SUFFIX}"
#@@ -120,9 +126,16 @@ do_compile() {
#         flexspi_nor)
#             rcwimg="${RCWXSPI}${RCW_SUFFIX}"
#             uefiboot="${UEFI_XSPIBOOT}"
#-            ;;
#+            ;;
#         esac
#-
#+
#+        # check size
#+        rcwsize=$(stat -c "%s" ${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/${rcwimg})
#+        if [ ${rcwsize} -gt ${rcwsize_max} ]; then
#+            echo "Skipping boot-type ${d} because ${rcwimg} exceeds ${rcwsize_max} byte in size"
#+            continue
#+        fi
#+
# 	if [ -f ${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/$rcwimg ]; then
#             make V=1 realclean
#             if [ -f rot_key.pem ];then
#
do_compile:lx216xa-sr() {
    # clean previous artifacts
    rm -f *.bin *.pbl *.pri *.pub

    if [ ! -f ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/srk.pri ]; then
       ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/gen_keys 1024
    else
       cp ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/srk.pri .
       cp ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/srk.pub .
    fi

    ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/gen_fusescr \
        ${RECIPE_SYSROOT_NATIVE}/usr/bin/cst/input_files/gen_fusescr/${chassistype}/input_fuse_file

    for d in ${BOOTTYPE}; do
        rcwsize_max=4072
        case $d in
        nor)
            rcwimg="${RCWNOR}${RCW_SUFFIX}"
            uefiboot="${UEFI_NORBOOT}"
            ;;
        nand)
            rcwimg="${RCWNAND}${RCW_SUFFIX}"
            ;;
        qspi)
            rcwimg="${RCWQSPI}${RCW_SUFFIX}"
            uefiboot="${UEFI_QSPIBOOT}"
            if [ -n "${SECURE_EXTENTION}" ] && [ "${MACHINE}" = ls1046ardb ]; then
                rcwimg="RR_FFSSPPPH_1133_5559/rcw_1600_qspiboot_sben.bin"
            fi
            ;;
        auto)
            rcwimg="${RCWAUTO}${RCW_SUFFIX}"
            # for auto-boot atf create_pbl does not append any additional instructions
            rcwsize_max=4096
            ;;
        sd)
            rcwimg="${RCWSD}${RCW_SUFFIX}"
            ;;
        emmc)
            rcwimg="${RCWEMMC}${RCW_SUFFIX}"
            ;;
        flexspi_nor)
            rcwimg="${RCWXSPI}${RCW_SUFFIX}"
            uefiboot="${UEFI_XSPIBOOT}"
            ;;
        esac

        # check size
        rcwsize=$(stat -c "%s" ${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/${rcwimg})
        if [ ${rcwsize} -gt ${rcwsize_max} ]; then
            echo "Skipping boot-type ${d} because ${rcwimg} exceeds ${rcwsize_max} byte in size"
            continue
        fi

	if [ -f ${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/$rcwimg ]; then
            make V=1 realclean
            if [ -f rot_key.pem ];then
                mkdir -p build/${PLATFORM}/release/
                cp *.pem build/${PLATFORM}/release/
            fi

            oe_runmake V=1 all fip pbl ${FIP_DDR} PLAT=${PLATFORM} BOOT_MODE=${d} RCW=${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/${rcwimg} BL33=${UBOOT_BINARY}
            cp build/${PLATFORM}/release/bl2_${d}${SECURE_EXTENTION}.pbl .
            cp build/${PLATFORM}/release/fip.bin fip_uboot${SECURE_EXTENTION}.bin
            if [ -e build/${PLATFORM}/release/fuse_fip.bin ]; then
                cp build/${PLATFORM}/release/fuse_fip.bin .
            fi

            if [ -e build/${PLATFORM}/release/ddr_fip_sec.bin ] && [ ! -f ddr_fip_sec.bin ]; then
                cp build/${PLATFORM}/release/ddr_fip_sec.bin .
            fi

            if [ -e build/${PLATFORM}/release/rot_key.pem ] && [ ! -f rot_key.pem ]; then
                cp build/${PLATFORM}/release/*.pem .
            fi

            if [ -n "${PLATFORM_ADDITIONAL_TARGET}" ]; then
                make V=1 realclean
                oe_runmake V=1 all fip pbl PLAT=${PLATFORM_ADDITIONAL_TARGET} BOOT_MODE=${d} RCW=${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/${rcwimg} BL33=${UBOOT_BINARY}
                cp build/${PLATFORM_ADDITIONAL_TARGET}/release/bl2_${d}${SECURE_EXTENTION}.pbl bl2_${d}${SECURE_EXTENTION}_${PLATFORM_ADDITIONAL_TARGET}.pbl
                cp build/${PLATFORM_ADDITIONAL_TARGET}/release/fip.bin fip_uboot${SECURE_EXTENTION}_${PLATFORM_ADDITIONAL_TARGET}.bin
                if [ -e build/${PLATFORM_ADDITIONAL_TARGET}/release/fuse_fip.bin ]; then
                    cp build/${PLATFORM_ADDITIONAL_TARGET}/release/fuse_fip.bin fuse_fip_${PLATFORM_ADDITIONAL_TARGET}.bin
                fi
            fi

            if [ -z "${SECURE_EXTENTION}" -a -f "${DEPLOY_DIR_IMAGE}/uefi/${PLATFORM}/${uefiboot}" ]; then
                make V=1 realclean
                oe_runmake V=1 all fip pbl PLAT=${PLATFORM} BOOT_MODE=${d} RCW=${DEPLOY_DIR_IMAGE}/rcw/${RCW_FOLDER}/${rcwimg} BL33=${DEPLOY_DIR_IMAGE}/uefi/${PLATFORM}/${uefiboot}
                cp build/${PLATFORM}/release/fip.bin fip_uefi.bin
            fi
        fi
        rcwimg=""
        uefiboot=""
    done
}
