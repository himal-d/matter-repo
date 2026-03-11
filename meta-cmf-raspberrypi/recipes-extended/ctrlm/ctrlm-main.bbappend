FILESEXTRAPATHS_append := "${THISDIR}/files/:"

SRC_URI += "file://0001-remove-jenkins-version-check.patch;apply=0"

addtask do_apply_patch after do_unpack before do_configure

do_apply_patch() {
    cd ${S}
    if [ ! -e patch_applied ]; then
        bbnote "Patching 0001-remove-jenkins-version-check.patch"
        patch -p1 < ${WORKDIR}/0001-remove-jenkins-version-check.patch
        touch patch_applied
    fi
}

do_configure_append() {
    echo '{
    "voice" : {
    "url_src_ptt"                :  "aows://127.0.0.1",
    "require_secure_url"         :  false,
    "save_last_utterance"        : [true, true],
    "server_hosts"               : [ "*localhost.test" ]
    }
    }' > ${CTRLM_CONFIG_OEM_ADD}
}
