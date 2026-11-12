EAPI=8

ETYPE="sources"

K_NOUSENAME="yes"
K_NOSETEXTRAVERSION="yes"
K_SECURITY_UNSUPPORTED="1"
K_DEBLOB_AVAILABLE="0"

inherit kernel-2
detect_version
detect_arch

inherit sanus-kernel

DESCRIPTION="SanusOS Linux kernel sources (upstream LTS + the SanusOS patch series)"
HOMEPAGE="https://sanusos.org/ https://www.kernel.org/"
SRC_URI="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.tar.xz"

LICENSE="GPL-2"
SLOT="6.12"
KEYWORDS="~amd64 ~arm64"
IUSE=""

S="${WORKDIR}/linux-6.12"

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
	sanus_apply_patchset
	if [[ -f ${FILESDIR}/sanus-fragment.config ]]; then
		cp "${FILESDIR}/sanus-fragment.config" "${S}/sanus-fragment.config" || die
	fi
	eapply_user
}

src_install() {
	local srcdir="/usr/src/linux-${PV}"
	dodir "${srcdir}"
	cp -a . "${ED}${srcdir}/" || die "failed to install kernel sources"
	rm -f "${ED}${srcdir}/.config" "${ED}${srcdir}/vmlinux" "${ED}${srcdir}/Module.symvers" 2>/dev/null || true
	rm -rf "${ED}${srcdir}/.git" 2>/dev/null || true
	fowners -R root:root "${srcdir}" 2>/dev/null || true
}
