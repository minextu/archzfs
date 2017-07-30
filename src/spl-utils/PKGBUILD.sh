#!/bin/bash

cat << EOF > ${spl_utils_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${spl_utils_pkgname}"
pkgname=("${spl_utils_pkgname}" "${spl_dkms_pkgname}")
pkgver=${spl_pkgver}
pkgrel=${spl_pkgrel}

arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}")
sha256sums=("${spl_src_hash}")
license=("GPL")
provides=("spl-utils")
makedepends=(${spl_makedepends})
build() {
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin --with-config=user
    make
}

package_${spl_utils_pkgname}() {
    pkgdesc="Solaris Porting Layer kernel module support files."
    groups=("${archzfs_package_group}")
    conflicts=(${spl_utils_conflicts})
    ${spl_utils_replaces}
    
    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
}

package_${spl_dkms_pkgname}() {
    pkgdesc="Solaris Porting Layer kernel modules."
    depends+=("${spl_utils_pkgname}=\${pkgver}-\${pkgrel}" "dkms")
    provides=("spl")
    conflicts=("spl-git" "spl-lts")

    dkmsdir="\${pkgdir}/usr/src/spl-\${pkgver}"
    install -d "\${dkmsdir}"
    cp -a ${spl_workdir}/. \${dkmsdir}

    cd "\${dkmsdir}"
    make clean
    make distclean
    find . -name ".git*" -print0 | xargs -0 rm -fr --
    scripts/dkms.mkconf -v \${pkgver} -f dkms.conf -n spl
    chmod g-w,o-w -R .
}

EOF

pkgbuild_cleanup "${spl_utils_pkgbuild_path}/PKGBUILD"
