require conf/machine/include/qoriq-arm64.inc
DEFAULTTUNE ?= "cortexa72-crypto"
require conf/machine/include/arm/armv8a/tune-cortexa72.inc

MACHINEOVERRIDES =. "fsl-lsch3:lx2160a:"

MACHINE_FEATURES:append = " optee "

KERNEL_CLASSES  = " kernel-fitimage "
KERNEL_IMAGETYPES = "fitImage"

KERNEL_DEFCONFIG ?= "defconfig"

SERIAL_CONSOLES ?= "115200;ttyAMA0"
SERIAL_CONSOLES_CHECK ?= "${SERIAL_CONSOLES}"

USE_VT = "0"
