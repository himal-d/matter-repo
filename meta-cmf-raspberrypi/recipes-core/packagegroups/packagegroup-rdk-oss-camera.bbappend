RDEPENDS_packagegroup-rdk-oss-camera_append = "	\
                        v4l-utils \
                        rms \
                        kvs \
                        cvr \
                        thumbnail \
                        mongoose \
                        sysint \
                        netkit-telnet \
                        parodus \
                        wpa-supplicant \
                        libcamera \
                        libcamera-gst \
                        pipewire \
                        pwstream \
                        webrtc \
			media-session \
			wireplumber \
			mediastreamer \
"

RDEPENDS_packagegroup-rdk-oss-camera_append = "${@oe.utils.conditional("ENABLE_PIPEWIRE", "1", "", "mediastreamer", d)}"

RDEPENDS_packagegroup-rdk-oss-camera_remove = "cryptsetup"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "iksemel"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "smartmontools"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "dhcp-client"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "dhcp-server"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "dhcp-server-config"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "nodejs"
RDEPENDS_packagegroup-rdk-oss-camera_remove = "wireless-tools"
