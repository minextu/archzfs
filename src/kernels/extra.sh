# For build.sh
mode_name="extra"
mode_desc="Select and use extra packages (dkms-sorted)"


update_dkms-sorted_pkgbuilds() {
    pkg_list=("dkms-sorted")
    local cmd="cd '${script_dir}/packages/extra/dkms-sorted' && "
    cmd+="git submodule update --init . && "
    cmd+="git pull -q origin master"
    run_cmd_show_and_capture_output_no_dry_run "${cmd}"
}
