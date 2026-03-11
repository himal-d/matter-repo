SRCREV_machine = "${AUTOREV}"

KERNEL_VERSION_SANITY_SKIP="1"
require android-raspberrypi_5.15.inc

PE = "1"
PV = "5.15.92"

SRCREV_meta="0b65b80aa112614e8ab129f2d832b8cf050e7a4a"

SRC_URI += "file://powersave.cfg \
            file://android-drivers.cfg \
            file://video-drivers.cfg \
            git://git.yoctoproject.org/yocto-kernel-cache;type=kmeta;name=meta;branch=yocto-5.10;destsuffix=kernel-meta \
            file://disable_nnp_lsm_check.patch \
            "
