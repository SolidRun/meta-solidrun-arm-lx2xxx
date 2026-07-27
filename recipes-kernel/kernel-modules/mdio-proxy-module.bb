SUMMARY = "MDIO proxy module"
DESCRIPTION = "Builds out-of-tree mdio-proxy kernel module"
LICENSE = "BSD-3-Clause OR GPL-2.0-or-later"

SRC_URI = "git://github.com/nxp-qoriq/mdio-proxy-module.git;protocol=https;branch=master"
LIC_FILES_CHKSUM = "file://LICENSE;md5=6f933bdd5214942fcfafa90f40740dfc"
SRCREV = "lf-6.6.52-2.2.0"
S = "${WORKDIR}/git"

inherit module
