#!/bin/bash

cat << EOF > ${zfs_utils_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${zfs_utils_pkgname}"
pkgname=("${zfs_utils_pkgname}" "${zfs_dkms_pkgname}")
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
depends=("${spl_pkgname}")
makedepends=(${zfs_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}"
        "zfs-utils.bash-completion-r1"
        "zfs-utils.initcpio.install"
        "zfs-utils.initcpio.hook")
sha256sums=("${zfs_src_hash}"
            "${zfs_bash_completion_hash}"
            "${zfs_initcpio_install_hash}"
            "${zfs_initcpio_hook_hash}")
license=("CDDL")

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --with-mounthelperdir=/usr/bin \\
                --libdir=/usr/lib --datadir=/usr/share --includedir=/usr/include \\
                --with-udevdir=/lib/udev --libexecdir=/usr/lib/zfs-${zol_version} \\
                --with-config=user
    make
}

package_${zfs_utils_pkgname}() {
    pkgdesc="Kernel module support files for the Zettabyte File System."
    groups=("${archzfs_package_group}")
    provides=("zfs-utils")
    install=zfs-utils.install
    conflicts=(${zfs_utils_conflicts})
    ${zfs_utils_replaces}
    
    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install

    # Remove uneeded files
    rm -r "\${pkgdir}"/etc/init.d
    rm -r "\${pkgdir}"/usr/lib/dracut

    # move module tree /lib -> /usr/lib
    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib

    # Autoload the zfs module at boot
    mkdir -p "\${pkgdir}/etc/modules-load.d"
    printf "%s\n" "zfs" > "\${pkgdir}/etc/modules-load.d/zfs.conf"

    # Install the support files
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.hook "\${pkgdir}"/usr/lib/initcpio/hooks/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.install "\${pkgdir}"/usr/lib/initcpio/install/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.bash-completion-r1 "\${pkgdir}"/usr/share/bash-completion/completions/zfs
}

package_${zfs_dkms_pkgname}() {
    pkgdesc="Kernel modules for the Zettabyte File System."
    depends+=("${zfs_utils_pkgname}=\${pkgver}-\${pkgrel}" "dkms")
    provides=("zfs")
    conflicts=("zfs-git" "zfs-lts")

    dkmsdir="\${pkgdir}/usr/src/zfs-\${pkgver}"
    install -d "\${dkmsdir}"
    cp -a ${zfs_workdir}/. \${dkmsdir}

    cd "\${dkmsdir}"
    make clean
    make distclean
    find . -name ".git*" -print0 | xargs -0 rm -fr --
    scripts/dkms.mkconf -v \${pkgver} -f dkms.conf -n zfs
    chmod g-w,o-w -R .
}

EOF

pkgbuild_cleanup "${zfs_utils_pkgbuild_path}/PKGBUILD"
