# rootfs_copy_core_image (meta-qoriq fsl-utils.bbclass) copies the fsl-image-networking cpio.gz
# during do_rootfs, but meta-qoriq only orders it before do_image_complete
do_rootfs[depends] += "fsl-image-networking:do_image_complete"
