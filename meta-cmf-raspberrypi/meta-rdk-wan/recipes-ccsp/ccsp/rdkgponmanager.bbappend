EXTRA_OECONF_remove_kirkstone = " --with-ccsp-platform=bcm --with-ccsp-arch=arm "

DEPENDS_append = " libsyswrapper"
LDFLAGS_append = " -lsecure_wrapper"
