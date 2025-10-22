# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/21.11-solidrun:"

SRC_URI:append = " \
                  file://0001-bus-fslmc-fix-invalid-use-of-default-vfio-config.patch \
                  file://0002-examples-fix-linker-errors-when-building-with-shared.patch \
"

# build with shared libraries to reduce sizer of apps and examples
# shrinks dpdk-tools.rpm from 31M to 360k, dpdk-examples from 91M to 980k, ...
EXTRA_OEMESON:append = " --default-library shared "
