EAPI=8

DESCRIPTION="SanusOS installer — a black, keyboard-driven TUI wizard"
HOMEPAGE="https://sanusos.org/"
SRC_URI="sanus-installer-${PV}.tar.gz"
S="${WORKDIR}/sanus-installer-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

# The tarball is produced by the SanusOS build system from the `installer/`
# directory and dropped into DISTDIR (see scripts/30-rootfs.sh), so there is
# nothing to fetch from a mirror.
RESTRICT="mirror"

# Gentoo no longer carries virtual/rust; depend on either implementation.
# Prefer rust-bin so a normal install does not build the compiler from source.
BDEPEND="|| ( dev-lang/rust-bin dev-lang/rust )"

# The tarball contains Cargo.toml, Cargo.lock, src/, README.md, and the
# vendored crate sources under vendor/ plus .cargo/config.toml. That is what
# lets the build run with no network at all.

src_compile() {
	export CARGO_HOME="${T}/cargo-home"
	export CARGO_NET_OFFLINE=true
	cargo build --release --locked --offline || die "cargo build failed"
}

src_install() {
	dobin target/release/sanus-installer
	dodoc README.md
}

pkg_postinst() {
	elog "The SanusOS installer is installed as /usr/bin/sanus-installer."
	elog ""
	elog "  sanus-installer --check              inspect this machine"
	elog "  sanus-installer -c FILE -y           unattended install"
	elog "  sanus-installer -d                   dry run"
}
