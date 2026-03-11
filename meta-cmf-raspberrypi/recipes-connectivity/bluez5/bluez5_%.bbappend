
do_install_append() {
   sed -i '/Description=Bluetooth service/a Requires=hciuart.service' ${D}${systemd_unitdir}/system/bluetooth.service
   sed -i '/Description=Bluetooth service/a After=hciuart.service' ${D}${systemd_unitdir}/system/bluetooth.service
   sed -i '/BusName=org.bluez/a ExecStartPre=/bin/sleep 5' ${D}${systemd_unitdir}/system/bluetooth.service
}
