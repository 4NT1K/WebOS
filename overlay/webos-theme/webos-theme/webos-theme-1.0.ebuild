EAPI=8

DESCRIPTION="WebOS rice — the black/transparent Hyprland theme, dotfiles and session glue"
HOMEPAGE="https://github.com/4NT1K/WebOS/"
SRC_URI=""

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

# Only what the rice itself needs at runtime. The desktop stack proper is
# pulled in by webos-desktop/webos-desktop.
RDEPEND="
	app-misc/brightnessctl
	app-misc/jq
	gui-apps/grim
	gui-apps/slurp
	gui-apps/nwg-displays
	gui-apps/wdisplays
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
# they are written (with a one-time backup) by `webos-rice --system` in
# pkg_postinst. That keeps the tree free of file collisions with gtk+,
# gui-libs/greetd, gui-wm/hyprland and friends.

S="${WORKDIR}"

src_install() {
	# --- 1. the rice, kept pristine under /usr/share/webos/rice ----------
	insinto /usr/share/webos/rice
	doins -r "${FILESDIR}"/rice/. || die "failed to install rice"

	# --- 2. branding assets ---------------------------------------------
	insinto /usr/share/webos
	newins "${FILESDIR}"/rice/wallpapers/webos-wallpaper.svg logo.svg
	if [[ -f "${FILESDIR}"/system/webos-logo.png ]]; then
		newins "${FILESDIR}"/system/webos-logo.png webos-logo.png
	fi
	insinto /usr/share/webos/wallpaper
	if [[ -f "${FILESDIR}"/rice/wallpapers/webos-wallpaper.png ]]; then
		newins "${FILESDIR}"/rice/wallpapers/webos-wallpaper.png webos-wallpaper.png
		if [[ -f "${FILESDIR}"/rice/wallpapers/webos-wallpaper-dark.png ]]; then
			newins "${FILESDIR}"/rice/wallpapers/webos-wallpaper-dark.png webos-wallpaper-dark.png
		else
			newins "${FILESDIR}"/rice/wallpapers/webos-wallpaper.png webos-wallpaper-dark.png
		fi
	fi

	# --- 3. session environment -----------------------------------------
	insinto /etc/profile.d
	newins "${FILESDIR}"/system/profile.d-webos.sh webos.sh
	insinto /etc/environment.d
	newins "${FILESDIR}"/system/environment.d-webos.conf 10-webos.conf
	insinto /etc
	newins "${FILESDIR}"/system/locale.conf locale.conf
	insinto /etc/xdg
	newins "${FILESDIR}"/system/xdg/kcm-about-distrorc kcm-about-distrorc
	insinto /usr/local/share/applications
	newins "${FILESDIR}"/system/desktop-overrides/kdesystemsettings.desktop kdesystemsettings.desktop
	newins "${FILESDIR}"/system/desktop-overrides/systemsettings.desktop systemsettings.desktop
	insinto /usr/share/icons/default
	newins "${FILESDIR}"/system/icons-default/index.theme index.theme

	# xdg-desktop-portal defaults (Hyprland session). Install to /etc so we
	# do not collide with portals.conf / hyprland-portals.conf owned by the
	# xdg-desktop-portal and hyprland packages.
	insinto /etc/xdg-desktop-portal
	if compgen -G "${FILESDIR}"/system/xdg-desktop-portal/*.conf > /dev/null; then
		doins "${FILESDIR}"/system/xdg-desktop-portal/*.conf
	fi

	# --- 4. Wayland/X session entries -----------------------------------
	# Named `webos`, not `hyprland`, so we never collide with the upstream
	# package's own desktop file.
	insinto /usr/share/wayland-sessions
	newins "${FILESDIR}"/system/webos.desktop webos.desktop
	newins "${FILESDIR}"/system/webos-gamescope.desktop webos-gamescope.desktop
	insinto /usr/share/xsessions
	newins "${FILESDIR}"/system/webos.desktop webos.desktop

	# --- 4b. application entries ----------------------------------------
	insinto /usr/share/applications
	newins "${FILESDIR}"/system/webos-settings.desktop webos-settings.desktop

	# --- 5. OpenRC: first-boot glue -------------------------------------
	exeinto /etc/local.d
	newexe "${FILESDIR}"/system/local.d-webos.start webos.start

	# --- 5b. per-login glue ---------------------------------------------
	insinto /etc/xdg/autostart
	newins "${FILESDIR}"/system/webos-rice-autostart.desktop webos-rice.desktop
	newins "${FILESDIR}"/system/webos-plasma-setup.desktop webos-plasma-setup.desktop

	# --- 6. helper binaries ---------------------------------------------
	exeinto /usr/bin
	newexe "${FILESDIR}"/system/webos-rice webos-rice
	newexe "${FILESDIR}"/system/webos-session webos-session
	newexe "${FILESDIR}"/system/webos-wallpaper webos-wallpaper
	newexe "${FILESDIR}"/system/webos-shot webos-shot
	newexe "${FILESDIR}"/system/webos-gaming webos-gaming
	newexe "${FILESDIR}"/system/webos-shell webos-shell
	newexe "${FILESDIR}"/system/webos-fastfetch webos-fastfetch
	newexe "${FILESDIR}"/system/webos-update webos-update
	newexe "${FILESDIR}"/system/webos-plasma-setup webos-plasma-setup
	newexe "${FILESDIR}"/system/webos-settings webos-settings

	# --- 7. docs ---------------------------------------------------------
	dodoc "${FILESDIR}"/rice/README.rice
	insinto /usr/share/webos
	newins "${FILESDIR}"/WEBOS-INFO.txt WEBOS-INFO.txt
}

pkg_postinst() {
	elog "WebOS rice installed under /usr/share/webos/rice."
	elog ""

	if [[ -x ${EROOT}/usr/bin/webos-wallpaper ]]; then
		${EROOT}/usr/bin/webos-wallpaper || ewarn "wallpaper generation failed (is rsvg-convert or magick installed?)"
	fi

	if [[ -x ${EROOT}/usr/bin/webos-rice ]]; then
		${EROOT}/usr/bin/webos-rice --system || ewarn "webos-rice --system reported a problem"
	fi

	elog "Re-apply the rice for your own user at any time:"
	elog "  webos-rice --user"
	elog ""
	elog "Check whether the compositor picked everything up:"
	elog "  webos-rice --doctor"
}

pkg_config() {
	# `emerge --config webos-theme/webos-theme` re-applies everything
	# idempotently, including for every account in /home.
	einfo "Re-applying the WebOS rice"
	${EROOT}/usr/bin/webos-rice --system --force || die "webos-rice failed"
}
