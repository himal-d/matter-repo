do_install_append() {
 if [ -f ${D}${systemd_unitdir}/system/memcr.service ];then
        sed -i '/Environment=DUMPSDIR=/c\Environment=DUMPSDIR=/tmp/data/memcr' ${D}${systemd_unitdir}/system/memcr.service
 fi
}
