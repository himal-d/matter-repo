do_compile_append() {

   if [ "${@bb.utils.contains("DISTRO_FEATURES", "DOBBY_CONTAINERS", "yes", "no", d)}" = "yes" ]; then
        sed -i 's/[[:space:]]*$//g' ${WORKDIR}/cmdline.txt
        sed -i 's/$/ cgroup_enable=memory cgroup_memory=1/' ${WORKDIR}/cmdline.txt
   fi
}
