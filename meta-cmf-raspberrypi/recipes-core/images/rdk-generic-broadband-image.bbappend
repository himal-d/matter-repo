# ----------------------------------------------------------------------------

SYSTEMD_TOOLS = "systemd-analyze systemd-bootchart"

# systemd-bootchart doesn't currently build with musl libc
SYSTEMD_TOOLS_remove_libc-musl = "systemd-bootchart"

IMAGE_INSTALL_append = " ${SYSTEMD_TOOLS}"

#REFPLTB-349 Needed for Firmware upgrade - to create file system of dual partition
IMAGE_INSTALL_append = " e2fsprogs breakpad-staticdev"

#Opensync Integration 
IMAGE_INSTALL_append =" ${@bb.utils.contains('DISTRO_FEATURES', 'Opensync', ' mt76 opensync openvswitch', '', d)}"

#Beegol agent Support
IMAGE_INSTALL_append =" ${@bb.utils.contains('DISTRO_FEATURES', 'beegol_agent', ' ba', '', d)}"

#Asterisk Support
IMAGE_INSTALL_append =" ${@bb.utils.contains('DISTRO_FEATURES', 'Asterisk', ' hal-voice-asterisk', '', d)}"

require image-exclude-files.inc

remove_unused_file() {
    for i in ${REMOVED_FILE_LIST} ; do rm -rf ${IMAGE_ROOTFS}/$i ; done
}

ROOTFS_POSTPROCESS_COMMAND_append = "remove_unused_file; "


ROOTFS_POSTPROCESS_COMMAND_append = "add_busybox_fixes; "

add_busybox_fixes() {
                if [  -d ${IMAGE_ROOTFS}/bin ]; then
			cd  ${IMAGE_ROOTFS}/bin
                        rm ${IMAGE_ROOTFS}/bin/ps
			ln -sf  /bin/busybox.nosuid  ps
			ln -sf  /bin/busybox.nosuid  ${IMAGE_ROOTFS}/usr/bin/awk
			cd -
                fi
}

KERNEL_DEVICETREE_remove_kirkstone = " \
               overlays/vc4-fkms-v3d-pi4.dtbo \
               overlays/wm8960-soundcard.dtbo \
"
# ----------------------------------------------------------------------------
