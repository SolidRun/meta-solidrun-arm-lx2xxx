require recipes-extended/images/container-base.bb

IMAGE_INSTALL:append = " \
    vpp \
    vpp-data \
    vpp-plugins \
    vpp-plugins-data \
"

OCI_IMAGE_ENTRYPOINT = "${bindir}/vpp"
