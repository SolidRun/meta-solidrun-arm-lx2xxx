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
"

PLATFORM:lx2162a-som = "lx2162asom"
PLATFORM:lx2160a-cex6 = "lx2160acex6"
PLATFORM:lx2160a-cex7 = "lx2160acex7"
