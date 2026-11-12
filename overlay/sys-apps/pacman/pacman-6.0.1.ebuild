EAPI=8

DESCRIPTION="Arch Linux package manager (pacman) — SanusOS application layer"
HOMEPAGE="https://archlinux.org/"
SRC_URI="https://archive.archlinux.org/packages/p/pacman/${P}.pkg.tar.zst"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

# pacman is the application package manager; the shared libs it links against
# come from the Gentoo toolchain and base system.
RDEPEND=""

src_install() {
	install -Dm755 "${WORKDIR}/usr/bin/pacman" /usr/bin/pacman
	install -Dm755 "${WORKDIR}/usr/bin/pacman-sysuser" /usr/bin/pacman-sysuser || true
	install -Dm644 "${WORKDIR}/usr/share/man/man8/pacman.8.gz" /usr/share/man/man8/pacman.8.gz || true
	install -Dm644 "${FILESDIR}/pacman.conf" /etc/pacman.conf
}

pkg_postinst() {
	:
}
