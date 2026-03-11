FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://proc-event.cfg"

SRC_URI += "file://0001-add-support-for-port-triggering.patch"
SRC_URI_append_dunfell = " file://RPI-resolving-port-triggering-errors.patch"
SRC_URI_append_kirkstone = " file://kirkstone_resolving-port-triggering-errors.patch"

SRC_URI_append_broadband = " \
                             file://remove_unused_modules.cfg \
                             file://rdkb.cfg \
                             file://rdkb-acm.cfg \
                             file://netfilter.cfg  \
                             file://ot-br-posix.cfg  \
                             file://ble.cfg  \
"
SRC_URI_append_extender = " file://remove_unused_modules.cfg"
SRC_URI_append_extender = " \
                            file://rdkb.cfg \
                            file://rdkb-ext.cfg \
                            file://regdb.patch \
"
SRC_URI_append_extender_dunfell = " \
                            file://added_mtk_wed_header.patch \
                            file://mt76_compilation_errors_fix_5_10.patch \
"
SRC_URI_append_aarch64_broadband_dunfell = " \
                            file://added_mtk_wed_header.patch \
                            file://mt76_compilation_errors_fix_5_10.patch \ 
"
SRC_URI_append_kirkstone = "  file://added_mtk_wed_header.patch "

SRC_URI_remove = " file://0001-add-support-for-http-host-headers-cookie-url-netfilt.patch "
SRC_URI_remove_broadband =  " ${@bb.utils.contains("MACHINE_FEATURES", "vc4graphics", "file://vc4graphics.cfg", "", d)}"

do_install_append() {
    install -d ${D}${includedir}
    install -m 0644 ${B}/include/generated/autoconf.h ${D}${includedir}/autoconf.h
}

sysroot_stage_all_append () {
    install -d ${SYSROOT_DESTDIR}${includedir}
    install -m 0644 ${D}${includedir}/autoconf.h ${SYSROOT_DESTDIR}${includedir}/autoconf.h
}

do_deploy_append_refApp () {
    sed -i '1 s|$|vt.global_cursor_default=0|' ${DEPLOYDIR}/bcm2835-bootfiles/cmdline.txt
}

do_deploy_append_hybrid () {
    do_deploy_config
}

do_deploy_append_client () {
    do_deploy_config
}

do_deploy_append_ipclient () {
    do_deploy_config
}

do_deploy_config () {
    if [ "${@bb.utils.contains("DISTRO_FEATURES", "apparmor", "yes", "no", d)}" = "yes" ]; then
        if [ -f "${DEPLOYDIR}/bootfiles/cmdline.txt" ]; then
            sed -i 's/[[:space:]]*$//g' ${DEPLOYDIR}/bootfiles/cmdline.txt
            sed -i 's/$/ lsm=apparmor/' ${DEPLOYDIR}/bootfiles/cmdline.txt
        fi
    fi

    if [ "${@bb.utils.contains("DISTRO_FEATURES", "refapp", "yes", "no", d)}" = "no" ]; then
        if [ -f "${DEPLOYDIR}/bootfiles/cmdline.txt" ]; then
            sed -i 's/[[:space:]]*$//g' ${DEPLOYDIR}/bootfiles/cmdline.txt
            sed -i 's/$/ cma=256M@256M/' ${DEPLOYDIR}/bootfiles/cmdline.txt
        fi
   fi

   if [ "${@bb.utils.contains("DISTRO_FEATURES", "DOBBY_CONTAINERS", "yes", "no", d)}" = "yes" ]; then
        if [ -f "${DEPLOYDIR}/bootfiles/cmdline.txt" ]; then
            sed -i 's/[[:space:]]*$//g' ${DEPLOYDIR}/bootfiles/cmdline.txt
            sed -i 's/$/ cgroup_enable=memory cgroup_memory=1/' ${DEPLOYDIR}/bootfiles/cmdline.txt
        fi
   fi
}

PACKAGES += "kernel-autoconf"
PROVIDES += "kernel-autoconf"

FILES_kernel-autoconf = "${includedir}/autoconf.h"

KBUILD_DEFCONFIG_raspberrypi4-ext ?= "bcm2711_defconfig"

KERNEL_DEVICETREE_remove_broadband_kirkstone = " \
               overlays/vc4-fkms-v3d-pi4.dtbo \
               overlays/wm8960-soundcard.dtbo \
"
