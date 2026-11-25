EAPI=8

ETYPE="sources"

K_NOUSENAME="yes"
K_NOSETEXTRAVERSION="yes"
K_DEBLOB_AVAILABLE="0"

inherit kernel-2
detect_version
detect_arch

inherit webos-kernel

DESCRIPTION="WebOS Linux kernel sources (upstream LTS + the WebOS patch series)"
HOMEPAGE="https://github.com/4NT1K/WebOS/ https://www.kernel.org/"
# kernel-2.eclass handles three-component versions as base tarball + stable
# patch. Let detect_version() supply both; do not pin the combined tarball.
SRC_URI="${KERNEL_URI}"

LICENSE="GPL-2"
SLOT="6.12"
KEYWORDS="~amd64 ~arm64"
IUSE=""

S="${WORKDIR}/linux-6.12.119"

RDEPEND="
	>=sys-devel/bc-1.06.95
	>=sys-devel/flex-2.5.35
	>=sys-devel/bison-1.875
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-arch/xz-utils
	sys-apps/which
"

src_prepare() {
	default
	webos_apply_patchset
	if [[ -f ${FILESDIR}/webos-fragment.config ]]; then
		cp "${FILESDIR}/webos-fragment.config" "${S}/webos-fragment.config" || die
	fi
	eapply_user
}

src_install() {
	# Keep the build-tree path stable across patch releases: build.sh prepares
	# /usr/src/linux-${WEBOS_KERNEL_SERIES} for DKMS/NVIDIA module builds.
	local srcdir="/usr/src/linux-${SLOT}"
	dodir "${srcdir}"
	cp -a . "${ED}${srcdir}/" || die "failed to install kernel sources"
	rm -f "${ED}${srcdir}/.config" "${ED}${srcdir}/vmlinux" "${ED}${srcdir}/Module.symvers" 2>/dev/null || true
	rm -rf "${ED}${srcdir}/.git" 2>/dev/null || true
	fowners -R root:root "${srcdir}" 2>/dev/null || true
}
