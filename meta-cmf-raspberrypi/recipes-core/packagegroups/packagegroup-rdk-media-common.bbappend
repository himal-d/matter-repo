RDEPENDS_packagegroup-rdk-media-common_remove = "\
    mfr-data \
"

RDEPENDS_packagegroup-rdk-media-common_append = "\
    ${@bb.utils.contains("DISTRO_FEATURES", "gstreamer1", "gstreamer1.0-libav", "gst-libav", d)} \
    ${@bb.utils.contains("DISTRO_FEATURES", "rdkshell", " rdkshell wpeframework-ui thunder-services", "", d)} \
    ${@bb.utils.contains("DISTRO_FEATURES", "bluez5", "bluez5-bluetoothd","",d)} \
    westeros-sink \
    liba52 \
    lirc \
    audiocapturemgr \
    aamp \
    tts \
    ledmgr-extended-noop \
    hdhomerun \
    rdkapps \
    ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', '', 'westeros-rpi-displaymod', d)} \
    dca \
    breakpad \
    breakpad-wrapper \
    parodus \
    libparodus \
    tr69hostif \
    iarm-set-powerstate \
    iarm-query-powerstate \
    key-simulator \
    power-state-monitor \
    sys-utils \
    rdk-gstreamer-utils \
    waymetric \
    memcapture \
    sysint-conf \
"

RDEPENDS_packagegroup-rdk-media-common_remove_ipclient = " \
    fog \
    rmfgeneric \
    rmfapp \
    rmfstreamer \
    rdkmediaplayer \
    sys-utils \
    tr69hostif \
    audiocapturemgr \
    thunder-services \
"

RDEPENDS_packagegroup-rdk-media-common_append_hybrid = "\
    gstqamtunersrc \
"
