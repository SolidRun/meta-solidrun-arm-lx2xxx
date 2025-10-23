FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-vlib-unix-fix-plugin-loading-error-messages.patch"

EXTRA_OECMAKE:append = " -DVPP_USE_SYSTEM_DPDK=ON "
