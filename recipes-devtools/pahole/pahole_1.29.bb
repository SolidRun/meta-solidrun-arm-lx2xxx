# Backport from meta-openembedded whinlatter (f52f32952cb9717949f8bc3d3ccf6c4c5a59521f),
# with S set for scarthgap.
# scarthgap has pahole 1.25, whose parallel BTF encoding (-j, used by the kernel) is not reproducible:
# the kernel build links vmlinux more than once (e.g. again for the modules), so modules get BTF of a
# different vmlinux than the deployed kernel image and fail to load ("failed to validate module BTF").
# Since pahole 1.29 BTF encoding is always reproducible.
SUMMARY = "Shows and manipulates data structure layout"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

DEPENDS = "elfutils zlib libbpf"

# Depends on MACHINE_ARCH libbpf
PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_HOST = "(x86_64|i.86|arm|aarch64|riscv64|powerpc|powerpc64|mips64).*-linux"

SRCREV = "b9cc7963051b2099795129450f9b70c81950d02f"
SRC_URI = "git://git.kernel.org/pub/scm/devel/pahole/pahole.git;branch=master \
           file://0001-Use-usr-bin-env-python3-instead-of-just-usr-bin-pyth.patch \
           file://0001-btf_encoder-Fix-elf_functions-cleanup-on-error.patch"

# scarthgap: git sources are unpacked to ${WORKDIR}/git (whinlatter uses ${UNPACKDIR}/${BP})
S = "${WORKDIR}/git"

inherit cmake pkgconfig

PACKAGECONFIG[python3] = ",,python3,python3-core"

EXTRA_OECMAKE = "-D__LIB=${@os.path.relpath(d.getVar('libdir'), d.getVar('prefix') + '/')} -DCMAKE_BUILD_TYPE=Release -DLIBBPF_EMBEDDED=OFF"

FILES:${PN} =  "${bindir}/pahole \
		${libdir}/libdwarves.so* \
		${libdir}/libdwarves_reorganize.so*"

PACKAGES += "${PN}-extra"
FILES:${PN}-extra = "${datadir} ${bindir} ${libdir}/libdwarves_emit.so*"
RDEPENDS:${PN}-extra += "bash python3-core"

BBCLASSEXTEND = "native nativesdk"
