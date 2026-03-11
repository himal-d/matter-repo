SUMMARY = "xdialserver append recipe"

do_install_prepend_client() {
	# Adding Xdial support to RPI mediaclient devices */
	sed -i 's/\"hybrid\"/\"mediaclient\"/g' ${S}/plat/scripts/startXdial.sh
}
