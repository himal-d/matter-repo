#need to use busybox versions 
do_install_append_broadband() {
      rm ${D}/bin/kill
      rm ${D}/usr/bin/top
      rm ${D}/usr/bin/uptime
}
