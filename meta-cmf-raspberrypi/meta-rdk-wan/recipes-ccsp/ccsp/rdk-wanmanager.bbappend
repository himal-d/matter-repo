CFLAGS_append = " -D_PLATFORM_RASPBERRYPI_"

#REFPLTB-2136 - Need to remove the below line once RDKInterDeviceManager functionality support is added in rpi targets.
CFLAGS_remove = " -DFEATURE_RDKB_INTER_DEVICE_MANAGER"
LDFLAGS_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'RbusBuildFlagEnable', '-lrbus', '', d)}"
