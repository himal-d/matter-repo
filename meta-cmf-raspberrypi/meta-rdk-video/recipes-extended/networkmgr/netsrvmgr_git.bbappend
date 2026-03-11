FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PACKAGECONFIG_remove = "lostfound"
EXTRA_OECONF_append = " --enable-nlmonitor --enable-iarm --enable-route-support"
EXTRA_OEMAKE="IARM_LFLAGS=-lIARMBus -ldbus-1"

SRC_URI += "file://RDKUI-624-temporary-netsrvmgr-fix.patch;apply=no"

addtask netsrv_patches after do_unpack do_patch before do_configure

do_netsrv_patches() {
    cd ${S}
    if [ ! -e patch_applied ]; then
        bbnote "Patching RDKUI-624-temporary-netsrvmgr-fix.patch from '${S}/../'"
        patch -p1 < ${WORKDIR}/RDKUI-624-temporary-netsrvmgr-fix.patch
        touch patch_applied
    fi
}
