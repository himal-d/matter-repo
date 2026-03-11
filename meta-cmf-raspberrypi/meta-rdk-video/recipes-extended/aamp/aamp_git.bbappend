FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'wpe-2.28', 'file://0001-Find-JSC-include-path.patch;apply=no', '', d)}"
SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'wpe-2.28', 'file://0001-Updated-Find-JSC-include-path.patch;apply=no', '', d)}"

EXTRA_OECMAKE_remove = " -DCMAKE_USE_CLEARKEY=1"
EXTRA_OECMAKE_remove = " -DCMAKE_USE_WIDEVINE=1"
EXTRA_OECMAKE_remove = " -DCMAKE_USE_PLAYREADY=1"
EXTRA_OECMAKE += " -DCMAKE_WPEFRAMEWORK_REQUIRED=1"

CXXFLAGS += "-DNO_NATIVE_AV -DPLAYBINTEST_WESTEROSSINK"

DEPENDS += "wpe-webkit"

ADDAAMPPLAYER="${@bb.utils.contains("DISTRO_FEATURES", "build_rne", "1", "0", d)}"

# we need to patch to code for aamp for wpe-webkit_2.28
do_aamp_rpi_patches() {
    cd ${S}
    # Try to apply both aamp patches
    # For stable2 branch, 0001-Find-JSC-include-path.patch should succeed, and
    #                     0001-Updated-Find-JSC-include-path.patch fail
    # For dev-sprint branch, 0001-Find-JSC-include-path.patch should fail, and
    #                        0001-Updated-Find-JSC-include-path.patch should succeed.

    if [ ! -e aamp_rpi_patch1_applied ]; then
        if [ -f ${WORKDIR}/0001-Find-JSC-include-path.patch ]; then
            bbnote "Patching 0001-Find-JSC-include-path.patch"
            patch -p1 < ${WORKDIR}/0001-Find-JSC-include-path.patch || echo "ERROR or Patch already applied"
            touch aamp_rpi_patch1_applied
        fi
    fi

    if [ ! -e aamp_rpi_patch2_applied ]; then
        if [ -f ${WORKDIR}/0001-Updated-Find-JSC-include-path.patch ]; then
            bbnote "Patching 0001-Updated-Find-JSC-include-path.patch"
            patch -p1 < ${WORKDIR}/0001-Updated-Find-JSC-include-path.patch || echo "ERROR or Patch already applied"
            touch aamp_rpi_patch2_applied
        fi
    fi
}
addtask aamp_rpi_patches after do_unpack before do_configure

do_install_append() {
if [ "${ADDAAMPPLAYER}" = "1" ]; then
    install -d ${D}/home/root/aamprefplayer
    cp -r ${S}/test/ReferencePlayer/* ${D}/home/root/aamprefplayer/
fi

if [ ! -f ${D}/opt/aamp.cfg ]; then
    install -d ${D}/opt
fi
echo "useWesterosSink=1" >> ${D}/opt/aamp.cfg
}

FILES_${PN} += "${@bb.utils.contains("DISTRO_FEATURES", "build_rne", "/home/root/", "", d)}"
FILES_${PN} += "/opt/aamp.cfg"
