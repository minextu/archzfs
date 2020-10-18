#!/usr/bin/env bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
repo_dir=${script_dir}/repo

if ! source ${script_dir}/../lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi

verbose=""
git=

usage ()
{
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -g                 Use archzfs git packages"
    echo "    -v                 Enable verbose output / debug info"
    echo "    -h                 This help message"
    exit ${1}
}

setup_repo() {
    mkdir -p ${repo_dir}
    if [[ -n "${git}" ]]; then
        cp "${script_dir}/../packages/_utils/zfs-utils-git/"*.pkg.tar.zst ${repo_dir}
        cp "${script_dir}/../packages/linux/zfs-linux-git/"*.pkg.tar.zst ${repo_dir}
    else
        cp "${script_dir}/../packages/_utils/zfs-utils/"*.pkg.tar.zst ${repo_dir}
        cp "${script_dir}/../packages/linux/zfs-linux/"*.pkg.tar.zst ${repo_dir}
    fi
    repo-add "${repo_dir}/archzfs-iso.db.tar.gz" "${repo_dir}"/*.pkg.tar.zst
}

copy_templates() {
    cp ${script_dir}/pacman.conf.template ${script_dir}/pacman.conf
    sed -i "s|\#{REPO_PATH}|${repo_dir}|g" ${script_dir}/pacman.conf
    
    cp ${script_dir}/packages.x86_64.template ${script_dir}/packages.x86_64
    echo "archzfs-linux${git}" >> ${script_dir}/packages.x86_64
}

if [[ ${EUID} -ne 0 ]]; then
    error "This script must be run as root."
    exit 155;
fi

while getopts 'N:V:L:D:w:o:gvh' arg; do
    case "${arg}" in
        g) git="-git" ;;
        v) verbose="-v" ;;
        h) usage 0 ;;
        *)
           echo "Invalid argument '${arg}'"
           usage 1
           ;;
    esac
done

# build necessary zfs packages
pushd "${script_dir}/../"
./build.sh ${debug} update make utils std
popd

# create a repo using the resulting packages
setup_repo

# prepare config files
copy_templates

exec mkarchiso ${verbose} -w "${script_dir}/work" -o "${script_dir}/out${git}" "${script_dir}"

# git packages will be renamed and moved to out
if [ -n $git ]; then 
    for file in ${script_dir}/out${git}/*; do
        mv $file ${file//archlinux_zfs/archlinux_zfs_git}
    done
    mv ${script_dir}/out${git}/* ${script_dir}/out/
fi
