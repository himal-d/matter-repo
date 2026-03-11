DEPENDS += " westeros"

inherit coverity

# add userland depends only if no vc4graphics enabled also remove userland as meta-wpe won't allow to override
RDEPENDS_${PN}_remove = "${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', 'userland', '', d)}" 
RDEPENDS_${PN}_append = " ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', '', 'userland', d)}"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://rdkshell_keymapping.json \
            file://wpeframework.conf \
            file://cardselect_rpi4.sh \
           "

do_install_append() {
    if ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', 'true', 'false', d)}; then
        sed -i '/Environment=.*LD_PRELOAD=/ c\Environment="LD_PRELOAD=/usr/lib/libwesteros_gl.so.0"' ${D}${systemd_unitdir}/system/wpeframework.service
    fi

    install -d ${D}${systemd_unitdir}/system/wpeframework.service.d
    install -D -m 0644 ${WORKDIR}/rdkshell_keymapping.json  ${D}${sysconfdir}
    install -D -m 0644 ${WORKDIR}/wpeframework.conf ${D}${systemd_unitdir}/system/wpeframework.service.d/

    if ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', 'true', 'false', d)}; then
        echo "Environment=\"WESTEROS_SINK_USE_FREERUN=1\"" >> ${D}${systemd_unitdir}/system/wpeframework.service.d/wpeframework.conf
        echo "Environment=\"WESTEROS_GL_USE_GENERIC_AVSYNC=1\"" >> ${D}${systemd_unitdir}/system/wpeframework.service.d/wpeframework.conf
        echo "Environment=\"WESTEROS_GL_USE_REFRESH_LOCK=1\"" >> ${D}${systemd_unitdir}/system/wpeframework.service.d/wpeframework.conf
    fi
    echo "RDKSHELL_COMPOSITOR_TYPE=surface" >> ${D}${sysconfdir}/wpeframework/WPEFramework.env
    echo "SESSION_SERVER_ENV_VARS=\"XDG_RUNTIME_DIR=/tmp;RIALTO_SINKS_RANK=0;GST_REGISTRY=/tmp/rialto-server-gstreamer-cache.bin;WAYLAND_DISPLAY=wayland-0\"" >> ${D}${sysconfdir}/wpeframework/WPEFramework.env
    sed -i "/KillMode=mixed/aTimeoutStopSec=15" ${D}${systemd_unitdir}/system/wpeframework.service
}

do_install_append_raspberrypi4() {
    echo "Environment=\"WESTEROS_DRM_CARD=/dev/dri/card1\"" >> ${D}${systemd_unitdir}/system/wpeframework.service.d/wpeframework.conf
    echo "WESTEROS_DRM_CARD=/dev/dri/card1" >> ${D}${sysconfdir}/wpeframework/WPEFramework.env
    sed -i '/^ExecStart=.*/i ExecStartPre=-/lib/rdk/cardselect_rpi4.sh' ${D}${systemd_unitdir}/system/wpeframework.service
    install -Dm755 ${WORKDIR}/cardselect_rpi4.sh ${D}${base_libdir}/rdk/cardselect_rpi4.sh
}

FILES_${PN} += "${systemd_unitdir}/system/wpeframework.service.d/wpeframework.conf"
FILES_${PN} += "${sysconfdir}/rdkshell_keymapping.json"
FILES_${PN}_append_raspberrypi4 += "${base_libdir}/rdk/cardselect_rpi4.sh"
