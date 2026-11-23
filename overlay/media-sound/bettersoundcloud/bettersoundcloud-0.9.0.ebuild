EAPI=8

DESCRIPTION="BetterSoundCloud — an ad-free SoundCloud desktop client"
HOMEPAGE="https://github.com/AlirezaKJ/BetterSoundCloud"
SRC_URI="https://github.com/AlirezaKJ/BetterSoundCloud/releases/download/v${PV}/BetterSoundCloud-${PV}-linux-x86_64.AppImage"
S="${WORKDIR}/squashfs-root"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

# Electron bundles its own heavy libraries; only base desktop pieces are needed.
RDEPEND="
	sys-apps/dbus
	x11-libs/libX11
	x11-libs/libxcb
"

src_unpack() {
	# AppImages need FUSE to execute. Extract instead so WebOS works without it.
	cd "${WORKDIR}" || die
	"${DISTDIR}/${A}" --appimage-extract >/dev/null || die "AppImage extraction failed"
	[[ -d "${S}" ]] || die "AppImage did not produce squashfs-root"
}

src_install() {
	local dest="/opt/bettersoundcloud"
	dodir "${dest}"
	cp -a "${S}/." "${ED}${dest}/" || die

	# Wrapper: call the upstream AppRun so its PATH/LD_LIBRARY_PATH setup and
	# user-namespace sandbox detection stay authoritative.
	cat > "${T}/bettersoundcloud" <<-EOF || die
	#!/usr/bin/env bash
	exec "${dest}/AppRun" "\$@"
	EOF
	dobin "${T}/bettersoundcloud"

	cat > "${T}/bettersoundcloud.desktop" <<-EOF || die
	[Desktop Entry]
	Name=BetterSoundCloud
	Exec=/usr/bin/bettersoundcloud %U
	Terminal=false
	Type=Application
	Icon=bettersoundcloud
	StartupWMClass=BetterSoundCloud
	Categories=AudioVideo;
	Comment=BetterSoundCloud — an ad-free desktop client for SoundCloud
	EOF
	insinto /usr/share/applications
	doins "${T}/bettersoundcloud.desktop"

	local size
	for size in 16 22 24 32 48 64 128 256 512; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		doins "${S}/usr/share/icons/hicolor/${size}x${size}/apps/bettersoundcloud.png"
	done

	dodoc "${S}/LICENSE.electron.txt"
}

pkg_postinst() {
	elog "BetterSoundCloud is installed to ${ROOT}/opt/bettersoundcloud."
	elog "Launch it with 'bettersoundcloud' or from the application menu."
}
