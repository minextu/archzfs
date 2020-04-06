#!/bin/bash

cat << EOF > ${zfs_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${zfs_pkgname}"
pkgname=("${zfs_pkgname}" "${zfs_pkgname}-headers")

${zfs_set_commit}
_zfsver="${zfs_pkgver}"
_kernelver="${kernel_version}"
_extramodules="${kernel_mod_path}"

pkgver="\${_zfsver}_\$(echo \${_kernelver} | sed s/-/./g)"
pkgrel=${zfs_pkgrel}
makedepends=(${linux_headers_depends} ${zfs_makedepends})
arch=("x86_64")
url="https://zfsonlinux.org/"
source=("${zfs_src_target}"
        "linux-5.5-compat-blkg_tryget.patch"
        "linux-5.6-compat-struct-proc_ops.patch"
        "linux-5.6-compat-timestamp_truncate.patch"
        "linux-5.6-compat-ktime_get_raw_ts64.patch"
        "linux-5.6-compat-time_t.patch")
sha256sums=("${zfs_src_hash}"
            "daae58460243c45c2c7505b1d88dcb299ea7d92bcf3f41d2d30bc213000bb1da"
            "05ca889a89b1e57d55c1b7d4d3013398a3e5a69d0fad27278aad701f0bb6e802"
            "5ad4393b334a8f685212f47b44e98dc468c70214ee5dbbab24cc95c4f310ae39"
            "7c6ebee72d864160b376fc18017c81f499f177b7d9265f565de859139805a277"
            "06f7ade5adcbfe77cb234361f8b2aca6d6e78fcd136da6d3a70048b5e92c62bb")
license=("CDDL")
depends=("kmod" "${zfs_utils_pkgname}" ${linux_depends})

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-\${_zfsver} --with-config=kernel \\
                --with-linux=/usr/lib/modules/\${_extramodules}/build \\
                --with-linux-obj=/usr/lib/modules/\${_extramodules}/build
    make
}

package_${zfs_pkgname}() {
    pkgdesc="Kernel modules for the Zettabyte File System."
    install=zfs.install
    provides=("zfs" "spl")
    groups=("${archzfs_package_group}")
    conflicts=("zfs-dkms" "zfs-dkms-git" "zfs-dkms-rc" "spl-dkms" "spl-dkms-git" ${zfs_conflicts})
    ${zfs_replaces}

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib

    # Remove src dir
    rm -r "\${pkgdir}"/usr/src
}

package_${zfs_pkgname}-headers() {
    pkgdesc="Kernel headers for the Zettabyte File System."
    provides=("zfs-headers" "spl-headers")
    conflicts=("zfs-headers" "zfs-dkms" "zfs-dkms-git" "zfs-dkms-rc" "spl-dkms" "spl-dkms-git" "spl-headers")

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/\${_extramodules}/Module.symvers
}

EOF

if [[ ! ${archzfs_package_group} =~ -git$ ]] && [[ ! ${archzfs_package_group} =~ -rc$ ]]; then
    sed -E -i "/^build()/i prepare() {\n\
    cd \"${zfs_workdir}\"\n\
    patch -Np1 -i \${srcdir}/linux-5.5-compat-blkg_tryget.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-struct-proc_ops.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-timestamp_truncate.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-time_t.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-ktime_get_raw_ts64.patch\n}" ${zfs_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
