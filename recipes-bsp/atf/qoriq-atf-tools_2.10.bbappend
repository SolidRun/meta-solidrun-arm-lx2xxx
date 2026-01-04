# ensure bc command is available during the build
DEPENDS += "bc-native"

# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/2.10-solidrun:"

# Add SolidRun patches
SRC_URI += "file://0001-fiptool-disable-pedantic-flag-to-avoid-errors-with-o.patch"
