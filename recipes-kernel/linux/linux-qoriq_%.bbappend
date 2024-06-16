# Workaround for DTBs in vendor-prefixed subfolders:
# The established standard for DTBs in U-Boot on arm64,
# is to organise them in sub-folders with vendor prefix.
# I.e. U-Boot sets "fdtfile=freescale/fsl-lx2160a-clearfog.cx.dtb".
#
# Yocto supports this already [1], nxp qoriq yocto kirkstone release
# has not picked up this patch.
# [1] https://git.yoctoproject.org/poky/commit/meta/classes/kernel-devicetree.bbclass?h=kirkstone&id=ab21fd0ec11adb6f6f30c3f4c4a38cdaa1ea4903
#
# Patch do_install and do_deploy to install the vendor-prefixed DTBs.

do_install:append() {
	for dtbf in ${KERNEL_DEVICETREE}; do
		dtb=`normalize_dtb "$dtbf"`
		dtb_ext=${dtb##*.}
		dtb_base_name=`basename $dtb .$dtb_ext`
		dtb_path=`get_real_dtb_path_in_kernel "$dtb"`
		dtb_prefix=`dirname $dtb`
		install -v -m 0644 -D $dtb_path ${D}/${KERNEL_IMAGEDEST}/$dtb_prefix/$dtb_base_name.$dtb_ext
	done
}

FILES:${KERNEL_PACKAGE_NAME}-devicetree:append = " /${KERNEL_IMAGEDEST}/*/*.dtb /${KERNEL_IMAGEDEST}/*/*.dtbo"

do_deploy:append() {
	for dtbf in ${KERNEL_DEVICETREE}; do
		dtb=`normalize_dtb "$dtbf"`
		dtb_ext=${dtb##*.}
		dtb_base_name=`basename $dtb .$dtb_ext`
		dtb_prefix=`dirname $dtb`
		install -m 0644 -D ${D}/${KERNEL_IMAGEDEST}/$dtb_prefix/$dtb_base_name.$dtb_ext $deployDir/$dtb_prefix/$dtb_base_name-${KERNEL_DTB_NAME}.$dtb_ext
		if [ "${KERNEL_IMAGETYPE_SYMLINK}" = "1" ] ; then
			ln -sf $dtb_base_name-${KERNEL_DTB_NAME}.$dtb_ext $deployDir/$dtb_prefix/$dtb_base_name.$dtb_ext
		fi
		if [ -n "${KERNEL_DTB_LINK_NAME}" ] ; then
			ln -sf $dtb_base_name-${KERNEL_DTB_NAME}.$dtb_ext $deployDir/$dtb_prefix/$dtb_base_name-${KERNEL_DTB_LINK_NAME}.$dtb_ext
		fi
	done
}
