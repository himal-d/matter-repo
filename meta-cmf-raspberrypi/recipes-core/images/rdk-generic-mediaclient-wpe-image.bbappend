require recipes-core/images/rdk-generic-mediaclient-wpe-image.bb
require recipes-core/images/add-non-root-user-group.inc

IMAGE_INSTALL_append = " \
   bluealsa  \
   hdhomerun \
   rdkapps \
   parodus \
   tr69hostif \
   alsa-utils \
   alsa-lib \
"

IMAGE_INSTALL_remove = " \
    westeros-init \
    wpe-webkit-init \
"
# Space is required for firmware upgrade
IMAGE_ROOTFS_EXTRA_SPACE = "524288"

ROOTFS_POSTPROCESS_COMMAND += "append_version; "

append_version() {
        echo "JENKINS_JOB=0" >> ${IMAGE_ROOTFS}/version.txt
        echo "JENKINS_BUILD_NUMBER=0" >> ${IMAGE_ROOTFS}/version.txt
}

fixes_tty1_removal() {
    if [ -f ${IMAGE_ROOTFS}/etc/systemd/system/getty.target.wants/getty@tty1.service ]; then
            rm -f "${IMAGE_ROOTFS}/etc/systemd/system/getty.target.wants/getty@tty1.service"
    fi
}
