EAPI=8

inherit toolchain-funcs

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
	dev-python/pillow
	gui-apps/grim
	gui-apps/slurp
	gui-apps/wdisplays
	gui-apps/swaybg
	gui-apps/waypaper
	gui-apps/wl-clipboard
	gui-libs/gtk-layer-shell[introspection]
	media-fonts/inter
	media-fonts/jetbrains-mono
	media-fonts/nerdfonts
	media-gfx/chafa
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
# gui-apps/sddm, gui-wm/hyprland and friends.

S="${WORKDIR}"

src_install() {
	# --- 1. the rice, kept pristine under /usr/share/webos/rice ----------
	insinto /usr/share/webos/rice
	doins -r "${FILESDIR}"/rice/. || die "failed to install rice"

	# --- 1b. selectable dotfiles profiles -------------------------------
	insinto /usr/share/webos/dotfiles
	doins -r "${FILESDIR}"/dotfiles/. || die "failed to install dotfiles profiles"

	# --- 2. branding assets ---------------------------------------------
	insinto /usr/share/webos
	# The logo, not the wallpaper: webos-wallpaper.svg is a 3840x2160 black
	# rectangle, so using it here made hyprlock and the KDE About page draw an
	# invisible black square. webos-logo.svg is the real 512x512 mark.
	newins "${FILESDIR}"/rice/wallpapers/webos-logo.svg logo.svg
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

	# --- 2b. system-wide fallbacks (work even before the user rice) ------
	insinto /etc/xdg/kitty
	newins "${FILESDIR}"/rice/kitty/kitty.conf kitty.conf
	insinto /etc/xdg/waybar
	newins "${FILESDIR}"/rice/waybar/config.jsonc config.jsonc
	newins "${FILESDIR}"/rice/waybar/style.css style.css
	insinto /etc/sddm.conf.d
	newins "${FILESDIR}"/system/sddm-webos.conf 10-webos.conf

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

	# --- 4. Wayland session entries --------------------------------------
	# Named `webos`, not `hyprland`, so we never collide with the upstream
	# package's own desktop file. Only Wayland entries are installed: Hyprland
	# cannot run under X11, and a duplicate xsessions/webos.desktop made SDDM
	# show the same session twice. The mono rice is the only WebOS look.
	insinto /usr/share/wayland-sessions
	newins "${FILESDIR}"/system/webos.desktop webos.desktop
	newins "${FILESDIR}"/system/webos-gamescope.desktop webos-gamescope.desktop

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

	# Show the fastfetch card in interactive bash/zsh/fish shells that were
	# not started through webos-shell (TTYs, ssh, other terminals). The
	# WEBOS_FASTFETCH_SHOWN guard keeps it from printing twice.
	insinto /etc/bash/bashrc.d
	newins "${FILESDIR}"/system/bashrc.d-webos-fastfetch.bash 00-webos-fastfetch.bash
	insinto /etc/zsh
	newins "${FILESDIR}"/system/zshrc-webos-fastfetch zshrc
	insinto /etc/fish/conf.d
	newins "${FILESDIR}"/system/fish-conf-webos.fish 00-webos-fastfetch.fish

	# --- 6. helper binaries ---------------------------------------------
	exeinto /usr/bin
	newexe "${FILESDIR}"/system/webos-rice webos-rice
	newexe "${FILESDIR}"/system/webos-session webos-session
	newexe "${FILESDIR}"/system/webos-portals webos-portals
	newexe "${FILESDIR}"/system/webos-autostart webos-autostart
	newexe "${FILESDIR}"/system/webos-dotfiles webos-dotfiles
	newexe "${FILESDIR}"/system/webos-wallpaper webos-wallpaper

	# Seed waypaper with the WebOS wallpaper folder + hyprpaper backend
	insinto /etc/skel/.config/waypaper
	newins "${FILESDIR}"/system/waypaper-config.ini config.ini
	newexe "${FILESDIR}"/system/webos-shot webos-shot
	newexe "${FILESDIR}"/system/webos-gaming webos-gaming
	newexe "${FILESDIR}"/system/webos-shell webos-shell
	newexe "${FILESDIR}"/system/webos-fastfetch webos-fastfetch
	newexe "${FILESDIR}"/system/webos-update webos-update
	newexe "${FILESDIR}"/system/webos-plasma-setup webos-plasma-setup
	newexe "${FILESDIR}"/system/webos-settings webos-settings
	newexe "${FILESDIR}"/system/webos-menu webos-menu
	newexe "${FILESDIR}"/system/webos-chafa-logo webos-chafa-logo
	newexe "${FILESDIR}"/system/webos-music webos-music
	newexe "${FILESDIR}"/system/webos-workspace-scroll webos-workspace-scroll
	# Waybar IPC shim: rewrites legacy workspace dispatches for Hyprland 0.57.
	insinto /usr/lib/webos
	newins "${FILESDIR}"/system/waybar-ipc-shim.c waybar-ipc-shim.c
	$(tc-getCC) -shared -fPIC -o "${D}"/usr/lib/webos/waybar-ipc-shim.so \
		"${D}"/usr/lib/webos/waybar-ipc-shim.c -ldl || die "failed to build waybar IPC shim"
	rm -f "${D}"/usr/lib/webos/waybar-ipc-shim.c
	newexe "${FILESDIR}"/system/webos-refresh webos-refresh
	newexe "${FILESDIR}"/system/webos-stats webos-stats

	# WebOS browser/player theming (Firefox chrome + Spicetify user.css)
	insinto /usr/share/webos/rice/firefox
	doins "${FILESDIR}"/rice/firefox/userChrome.css
	doins "${FILESDIR}"/rice/firefox/userContent.css
	doins "${FILESDIR}"/rice/firefox/user.js
	insinto /usr/share/webos/rice/spotify
	doins "${FILESDIR}"/rice/spotify/spotify
	insinto /usr/share/webos/rice/vesktop
	doins "${FILESDIR}"/rice/vesktop/Acrylic-Harmony.theme.css
	doins "${FILESDIR}"/rice/vesktop/webos-transparent.css
	doins "${FILESDIR}"/rice/vesktop/quickCss.css
	insinto /usr/share/webos/rice/spicetify
	doins "${FILESDIR}"/rice/spicetify/user.css

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
