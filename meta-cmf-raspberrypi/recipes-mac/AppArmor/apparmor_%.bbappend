python __anonymous() {
    machine_image_name = d.getVar('MACHINE')
    if 'raspberrypi' in machine_image_name:
        d.setVar('APPARMOR_PLATFORM_PROFILE', 'rpi4')
}
SRC_URI += "${CMF_GIT_ROOT}/rdk/components/platform/apparmor_profiles/${APPARMOR_PLATFORM_PROFILE};protocol=${RDK_GIT_PROTOCOL};branch=${CMF_GIT_BRANCH};destsuffix=git/apparmor-platform;name=apparmor-platform"
