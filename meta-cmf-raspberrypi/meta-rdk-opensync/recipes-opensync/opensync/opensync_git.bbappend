FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
OPENSYNC_VENDOR_URI += "file://raspberrypi-rdk-broadband-target.patch;patchdir=${WORKDIR}/git/vendor/rpi"
OPENSYNC_VENDOR_URI += " ${@bb.utils.contains('DISTRO_FEATURES', 'extender', 'file://opensync-4.4.service', '', d)} "
OPENSYNC_PLATFORM_URI += " ${@bb.utils.contains('DISTRO_FEATURES', 'extender', 'file://platform-rdk.patch;patchdir=${WORKDIR}/git/platform/rdk', '', d)} "

do_configure_append() {
     if [ "${@bb.utils.contains("DISTRO_FEATURES", "OneWifi", "yes", "no", d)}" = "yes" ]; then
         sed -i 's#UNIT_LDFLAGS := $(SDK_LIB_DIR)  -lhal_wifi -lrt#UNIT_LDFLAGS := $(SDK_LIB_DIR)  -lhal_wifi -lrt -lrdk_wifihal#' ${S}/platform/rdk/src/lib/target/override.mk
     fi
}

do_install_append_extender() {
         install -d ${D}${systemd_unitdir}/system
         install -m 0644 ${WORKDIR}/opensync-4.4.service ${D}${systemd_unitdir}/system/opensync.service
         rm ${D}/etc/ppp/*
}
