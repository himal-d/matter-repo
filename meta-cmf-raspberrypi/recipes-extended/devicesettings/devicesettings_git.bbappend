FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://devicesettings_audio_level_init.patch;apply=0"

do_devicesettings_patches() {
    cd ${S}
    if [ ! -e devicesettings_audio_level_init_patch_applied ]; then
        if [ -f ${WORKDIR}/devicesettings_audio_level_init.patch ]; then
            bbnote "Patching devicesettings_audio_level_init.patch"
            patch -p1 < ${WORKDIR}/devicesettings_audio_level_init.patch
        fi

        touch devicesettings_audio_level_init_patch_applied
    fi
}
addtask devicesettings_patches after do_unpack before do_configure
