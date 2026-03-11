#ESDK support - Avoid conflict of file install by linux-firmware , mt76 and linux-firmware-rpidistro in dunfell
do_install_append_broadband () {
        rm ${D}${nonarch_base_libdir}/firmware/mt76*bin
        rm ${D}${nonarch_base_libdir}/firmware/mediatek/mt76*bin
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43430-sdio.AP6212.txt
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43430-sdio.raspberrypi,3-model-b.txt
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43430-sdio.MUR1DX.txt
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43430-sdio.Hampoo-D2D3_Vi8A1.txt
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43430-sdio.bin
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43455-sdio.raspberrypi,3-model-b-plus.txt
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43455-sdio.bin
        rm ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43455-sdio.clm_blob
}
