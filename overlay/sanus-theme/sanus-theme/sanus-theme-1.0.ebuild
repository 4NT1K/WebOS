EAPI=8

DESCRIPTION="SanusOS rice — the black/transparent Hyprland theme, dotfiles and session glue"
HOMEPAGE="https://sanusos.org/"
SRC_URI=""

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

# Only what the rice itself needs at runtime. The desktop stack proper is
# pulled in by sanus-desktop/sanus-desktop.
RDEPEND="
	app-misc/brightnessctl
	app-misc/jq
	gui-apps/grim
	gui-apps/slurp
	gui-apps/swaybg
	gui-apps/wl-clipboard
	media-fonts/inter
	media-fonts/jetbrains-mono
	media-fonts/nerdfonts
	media-sound/playerctl
	x11-libs/libnotify
	|| (
		gnome-base/librsvg
		media-gfx/imagemagick
	)
"

# Files that another package owns are NOT installed from this package's image;
# they are written (with a one-time backup) by `sanus-rice --system` in
# pkg_postinst. That keeps the tree free of file collisions with gtk+,
# gui-libs/greetd, gui-wm/hyprland and friends.

S="${WORKDIR}"

src_install() {
	# --- 1. the rice, kept pristine under /usr/share/sanus/rice ----------
	insinto /usr/share/sanus/rice
	doins -r "${FILESDIR}"/rice/. || die "failed to install rice"

	# --- 2. branding assets ---------------------------------------------
	insinto /usr/share/sanus
	newins "${FILESDIR}"/rice/wallpapers/sanus-wallpaper.svg logo.svg

	# --- 3. session environment -----------------------------------------
	insinto /etc/profile.d
	newins "${FILESDIR}"/system/profile.d-sanus.sh sanus.sh
	insinto /etc/environment.d
	newins "${FILESDIR}"/system/environment.d-sanus.conf 10-sanus.conf

	# --- 4. Wayland/X session entries -----------------------------------
	# Named `sanus`, not `hyprland`, so we never collide with the upstream
	# package's own desktop file.
	insinto /usr/share/wayland-sessions
	newins "${FILESDIR}"/system/sanus.desktop sanus.desktop
	newins "${FILESDIR}"/system/sanus-gamescope.desktop sanus-gamescope.desktop
	insinto /usr/share/xsessions
	newins "${FILESDIR}"/system/sanus.desktop sanus.desktop

	# --- 5. OpenRC: first-boot glue -------------------------------------
	exeinto /etc/local.d
	newexe "${FILESDIR}"/system/local.d-sanus.start sanus.start

	# --- 6. helper binaries ---------------------------------------------
	exeinto /usr/bin
	newexe "${FILESDIR}"/system/sanus-rice sanus-rice
	newexe "${FILESDIR}"/system/sanus-session sanus-session
	newexe "${FILESDIR}"/system/sanus-wallpaper sanus-wallpaper
	newexe "${FILESDIR}"/system/sanus-shot sanus-shot
	newexe "${FILESDIR}"/system/sanus-gaming sanus-gaming

	# --- 7. docs ---------------------------------------------------------
	dodoc "${FILESDIR}"/rice/README.rice
}

pkg_postinst() {
	elog "SanusOS rice installed under /usr/share/sanus/rice."
	elog ""

	if [[ -x ${EROOT}/usr/bin/sanus-wallpaper ]]; then
		${EROOT}/usr/bin/sanus-wallpaper || ewarn "wallpaper generation failed (is rsvg-convert or magick installed?)"
	fi

	if [[ -x ${EROOT}/usr/bin/sanus-rice ]]; then
		${EROOT}/usr/bin/sanus-rice --system || ewarn "sanus-rice --system reported a problem"
	fi

	elog "Re-apply the rice for your own user at any time:"
	elog "  sanus-rice --user"
	elog ""
	elog "Check whether the compositor picked everything up:"
	elog "  sanus-rice --doctor"
}

pkg_config() {
	# `emerge --config sanus-theme/sanus-theme` re-applies everything
	# idempotently, including for every account in /home.
	einfo "Re-applying the SanusOS rice"
	${EROOT}/usr/bin/sanus-rice --system --force || die "sanus-rice failed"
}
