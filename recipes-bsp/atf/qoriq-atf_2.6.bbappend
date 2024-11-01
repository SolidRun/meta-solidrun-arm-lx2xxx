# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/qoriq-atf-2.6:"

# Add SolidRun patches
SRC_URI += "file://0001-plat-nxp-lx2160a-auto-boot.patch \
            file://0002-dcfg-Take-into-account-MEM_PLL_CFG_SHIFT-for-ddr-fre.patch \
            file://0003-lx2160acex7-assert-SUS_S5-GPIO-to-poweroff-the-COM.patch \
            file://0004-lx2160acex6-assert-IRQ0-GPIO-to-poweroff-the-EVB.patch \
            file://0005-lx2160a-assert-optional-S5-gpio-from-Makefile-consta.patch \
            file://0006-add-separate-platform-for-solidrun-cex7-module.patch \
            file://0007-lx2160a-support-flexible-value-for-CONFIG_DDR_NODIMM.patch \
            file://0008-add-separate-platform-for-solidrun-internal-cex6-eva.patch \
            file://0009-lx2160a-support-flushing-i2c-bus-before-ddr-init.patch \
            file://0010-lx2160acex6-flush-i2c-bus-with-spd-eeprom-before-ddr.patch \
            file://0011-lx2160acex7-flush-i2c-bus-with-spd-eeprom-before-ddr.patch \
            file://0012-plat-lx2160a-fix-building-without-NXP_NV_SW_MAINT_LA.patch \
            file://0013-plat-lx2160a-fix-boot-without-spi-flash-disable-non-.patch \
            file://0014-add-separate-platform-for-solidrun-lx2162a-som.patch \
"

PLATFORM:lx2160a-cex6 = "lx2160acex6"
PLATFORM:lx2160a-cex7 = "lx2160acex7"
PLATFORM:lx2162a-som = "lx2162asom"
