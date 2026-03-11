BBMASK .= "|meta-rdk/recipes-common/rdk-oss-ssa/"
BBMASK .= "|meta-rdk/recipes-support/base64"

BBMASK .= "|meta-rdk-voice/recipes-wpe/wpeframework/thunder-services_git.bbappend"

BBMASK .= "|openembedded-core/meta/recipes-multimedia/gstreamer/gstreamer1.0-plugins-ugly_1.8.3.bb"

BBMASK .= "|meta-cmf-raspberrypi/recipes-extended/rms/"
BBMASK .= "|meta-cmf-raspberrypi/recipes-extended/tdkb/"
BBMASK .= "|meta-cmf-raspberrypi/recipes-extended/tdkc/"
BBMASK .= "|meta-cmf-raspberrypi/recipes-multimedia/cvr/"
BBMASK .= "|meta-cmf-raspberrypi/recipes-multimedia/mediastreamer/"

# this bbappend holds old revision and checksum values which is not applicable for dunfell builds
# as meta-raspberrypi has the latest revision and it's checksum values
BBMASK .= "|meta-cmf-raspberrypi/recipes-bsp/bootfiles/bcm2835-bootfiles.bbappend"

# update kmod to version_29 in dunfell for ACK5_15
BBMASK .= "${@bb.utils.contains('DISTRO_FEATURES', 'dunfell', ' |openembedded-core/meta/recipes-kernel/kmod/kmod_git.bb', '', d)}"

BBMASK .= "${@bb.utils.contains('DISTRO_FEATURES', 'kirkstone', ' |meta-cmf-raspberrypi/recipes-kernel/kmod/kmod_29.bb', '', d)}"

# mediaframework device components have not been opensourced yet.
BBMASK_append_ipclient .= "|meta-cmf-raspberrypi/meta-rdk-video/recipes-extended/mediaframework/rmfgeneric_%.bbappend"

# Upgrade libbsd in dunfel to the default version
BBMASK .= "|meta-rdk-ext/recipes-support/libbsd/"

# Mask out gstreamer1.0-plugins-bad_1.18.%.bbappend in meta-rdk-ext so that hls can be added back.
# This is due to the remove directive in gstreamer1.0-plugins-bad_1.18.%.bbappend is always applied and has to be masked.
BBMASK .= "|meta-rdk-ext/recipes-multimedia/gstreamer/gstreamer1.0_1.18/gstreamer1.0-plugins-bad_1.18.%.bbappend"
