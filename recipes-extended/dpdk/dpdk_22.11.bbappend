# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/22.11-solidrun:"

do_install:append() {
    # install hugepages setup script
    install -v -m0755 ${S}/usertools/dpdk-hugepages.py ${D}${bindir}/
    install -v -m0755 ${S}/usertools/dpdk-devbind.py ${D}${bindir}/
}
