PACKAGECONFIG_remove = " playready provisioning"

DEPENDS += "atk libgcrypt libwebp"

PACKAGECONFIG_append = " rpi"
PACKAGECONFIG_remove = "native_audio"
PACKAGECONFIG[rpi] = "-DUSE_WPEWEBKIT_BACKEND_BCM_RPI=ON,,"

EXTRA_OECMAKE += "${@bb.utils.contains('WPE_BACKEND', 'gstreamergl', '-DUSE_KEY_INPUT_HANDLING_LINUX_INPUT=ON', '', d)}"

RDEPS_EXTRA_append = " \
    gstreamer1.0-plugins-bad-hls \
    shared-mime-info \
    wpe-webkit-web-inspector-plugin \
    libgpg-error \
    tts \
    ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', 'gstreamer1.0-plugins-good-video4linux2 ', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', '', 'gstreamer1.0-omx', d)} \
    ${@bb.utils.contains('LICENSE_FLAGS_WHITELIST', 'commercial', 'gstreamer1.0-plugins-bad-faad', '', d)} \
    gstreamer1.0-plugins-base-opengl \
    gstreamer1.0-plugins-good-mpg123 \
"

# RDK Distro excludes shared-mime-info for dunfell builds
RDEPS_EXTRA_remove = " \
    shared-mime-info \
    gstreamer1.0-plugins-bad-dataurisrc \
"
