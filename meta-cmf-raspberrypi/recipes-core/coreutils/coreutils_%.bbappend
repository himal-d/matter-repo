#need to use busybox versions
do_install_append_broadband () {
      rm ${D}/bin/touch
      rm ${D}/bin/kill
      rm ${D}/usr/bin/du 
}
