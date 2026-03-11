DEPENDS += "${@bb.utils.contains_any('DISTRO_FEATURES', 'dunfell kirkstone', ' libdrm mesa', ' userland', d)}"

CXXFLAGS_append = "${@bb.utils.contains_any('DISTRO_FEATURES', 'dunfell kirkstone', ' -DUSE_PLATFORM_DRM -I${STAGING_INCDIR}/libdrm', ' -DUSE_PLATFORM_USERLAND', d)}"

LDFLAGS_append = "${@bb.utils.contains_any('DISTRO_FEATURES', 'dunfell kirkstone', ' -ldrm -lgbm -ldl -lwayland-server', '  -lbcm_host -lvchostif -lwayland-server', d)}"

CXXFLAGS_append_dunfell = " ${@bb.utils.contains('MACHINE_FEATURES', 'vc4graphics', '-DUSE_MESA', '', d)}"
