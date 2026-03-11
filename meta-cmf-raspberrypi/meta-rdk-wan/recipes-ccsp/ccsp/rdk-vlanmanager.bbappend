LDFLAGS_aarch64 += " -lutctx -lprivilege  -lbreakpadwrapper "
EXTRA_OECONF_remove_kirkstone  = " --with-ccsp-platform=bcm --with-ccsp-arch=arm "
