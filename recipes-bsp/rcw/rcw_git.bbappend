# Add this layer to SRC_URI search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add SolidRun patches
SRC_URI += "file://0001-lx2162aqds-re-enable-dpmac11.patch \
            file://0002-add-loadc-jumpc-and-jump-to-pbi-instructions.patch \
            file://0003-lx2160asi-add-bootlocptr-script-for-automatic-boot-f.patch \
            file://0004-lx2160asi-add-procedure-splitting-sd1-lanes-A-D-40GE.patch \
            file://0005-lx2160asi-add-procedure-converting-sd1-lanes-g-h-fro.patch \
            file://0006-solidrun-add-script-generating-configs-from-template.patch \
            file://0007-add-configuration-solidrun-lx2160a-cex-7-on-clearfog.patch \
            file://0008-add-configuration-for-lx2162a-som-and-clearfog-evalu.patch \
            file://0009-add-configuration-solidrun-internal-lx2160a-cex6-eva.patch \
            file://0010-add-configuration-solidrun-internal-lx2160acex7-twin.patch \
            file://0011-lx2162asom_rev2-disable-mac7-10-apply-mac5-6-default.patch \
            file://0012-lx2160acex7-clearfog-cx-add-configurations-for-SD3-3.patch \
            file://0013-lx2162asom_rev2-generate-config-for-sd1-protocol-3-4.patch \
            file://0014-lx2162asom_rev2-remove-duplicate-pbi-command-disabli.patch \
            file://0015-lx2162asom_rev2-fix-SD1-protocol-3-clocking.patch \
            file://0016-lx2160acex7-lx2162asom-remove-serdes-equalization-se.patch \
            file://0017-lx2160acex7-twins-add-dedicated-half-twins-configura.patch \
"

# set BOARD_TARGETS recipe variable from machine config RCW_BOARDS if defined
BOARD_TARGETS = "${@d.getVar('RCW_BOARDS') or d.getVar('M')}"
