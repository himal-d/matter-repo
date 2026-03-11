
LINUX_RPI_KMETA_BRANCH ?= "yocto-5.4"

SRCREV_machine = "${AUTOREV}"
SRCREV_meta = "5d52d9eea95fa09d404053360c2351b2b91b323b"

KERNEL_VERSION_SANITY_SKIP="1"
require android-raspberrypi_5.10.inc

PE = "1"
PV = "5.10.82"

SRC_URI += "file://powersave.cfg \
            file://android-drivers.cfg \
            file://disable_nnp_lsm_check.patch \
            "
