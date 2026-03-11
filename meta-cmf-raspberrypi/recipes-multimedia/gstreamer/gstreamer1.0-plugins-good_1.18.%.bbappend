#removing the patch for 64bit builds, where -mfloat-abi=hard flag was introduced which is not available on 64bit gcc.
SRC_URI_remove_aarch64 = "file://0001-gst-plugins-good-stubs-soft.h-not-existing-error.patch"

# Revert RDKTV-26035: remove v4l2 plugin
PACKAGECONFIG_append = " v4l2"
