PROVIDES = "virtual/westeros-soc"
RPROVIDES_${PN} = "virtual/westeros-soc"

CFLAGS_append = " -I${STAGING_INCDIR}/libdrm"

# incase if enabled in bb file, it should be removed for Rpi
CFLAGS_remove = "${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', '-DWESTEROS_GL_NO_PLANES', '', d)}"
CFLAGS_append = "${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', ' -DDRM_NO_NATIVE_FENCE', '', d)}"
