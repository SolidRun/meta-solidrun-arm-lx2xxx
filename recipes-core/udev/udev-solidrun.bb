SUMMARY = "SolidRun Udev Rules"
DESCRIPTION = "Udev Rules for SolidRun Products"
SECTION = "kernel"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add Sources
SRC_URI += "file://99-leds-lx2160a-clearfog-twins.rules \
            file://99-leds-lx2162a-clearfog.rules \
"

# install rules
do_install() {
    install -v -m 0755 -d ${D}${sysconfdir}/udev/rules.d
    install -v -m 0644 ${WORKDIR}/99-leds-lx2160a-clearfog-twins.rules ${D}${sysconfdir}/udev/rules.d/
    install -v -m 0644 ${WORKDIR}/99-leds-lx2162a-clearfog.rules ${D}${sysconfdir}/udev/rules.d/
}

FILES:${PN} = " \
    ${sysconfdir}/udev/rules.d/*.rules \
"
