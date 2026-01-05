require conf/machine/include/qoriq-arm64.inc
DEFAULTTUNE ?= "cortexa72-crypto"
require conf/machine/include/arm/armv8a/tune-cortexa72.inc

MACHINE_FEATURES:append = " optee "

KERNEL_CLASSES  = " kernel-fitimage "
KERNEL_IMAGETYPES = "fitImage Image.gz"

# install Image.gz to "Image" filename because wic image extlinux.conf generator does not recognise Image.gz.
# U-Boot decompresses it fine regardless
IMAGE_BOOT_FILES = " Image.gz;Image "

KERNEL_DEFCONFIG ?= "defconfig"

SERIAL_CONSOLES:qoriq-arm64 = "115200;ttyAMA0"
SERIAL_CONSOLES ?= "115200;ttyAMA0"
SERIAL_CONSOLES_CHECK ?= "${SERIAL_CONSOLES}"

USE_VT = "0"

MACHINE_ESSENTIAL_EXTRA_RDEPENDS:append = " udev-solidrun "

# generate sd-bootable wic image
WKS_FILE = "lx2160a-bootimg-mmc.wks.in"
WIC_CREATE_EXTRA_ARGS:remove = "--no-fstab-update"

# generate kernel image with appended initramfs
INITRAMFS_IMAGE_BUNDLE = "1"
