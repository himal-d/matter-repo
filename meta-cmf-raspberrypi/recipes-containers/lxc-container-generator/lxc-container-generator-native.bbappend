FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
        file://xml/dobby_conf_htmlapp_append.xml \
        file://xml/dobby_conf_lightningapp_append.xml \
        file://xml/dobby_conf_cobalt_append.xml \
"

do_install_append() {
        install_lxc_config secure dobby_conf_htmlapp_append.xml
        install_lxc_config secure dobby_conf_lightningapp_append.xml
        install_lxc_config secure dobby_conf_cobalt_append.xml
}
