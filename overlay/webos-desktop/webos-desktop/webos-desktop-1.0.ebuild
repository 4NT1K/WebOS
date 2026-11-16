EAPI=8

DESCRIPTION="WebOS desktop — Hyprland, Wayland, the black/transparent rice"
HOMEPAGE="https://github.com/4NT1K/WebOS/"
SRC_URI=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="bluetooth browser"

RDEPEND="
	app-misc/fastfetch
	app-misc/ranger
	app-misc/zellij
	dev-libs/libdbusmenu
	app-misc/cliphist
	app-misc/nwg-look
	gui-apps/foot
	gui-apps/grim
	gui-apps/hypridle
	gui-apps/hyprlock
	gui-apps/hyprpaper
	gui-apps/hyprsunset
	gui-apps/kanshi
	gui-apps/mako
	gui-apps/slurp
	gui-apps/nwg-displays
	gui-apps/wdisplays
	gui-apps/swaybg
	gui-apps/tuigreet
	gui-apps/waybar
	gui-apps/wlogout
	gui-apps/wl-clipboard
	gui-apps/wlr-randr
	gui-apps/wofi
	gui-apps/qt6ct
	gui-libs/greetd
	gui-libs/wlroots
	gui-libs/xdg-desktop-portal-hyprland
	gui-libs/xdg-desktop-portal-wlr
	gui-wm/hyprland
	media-fonts/fontawesome
	media-fonts/inter
	media-fonts/jetbrains-mono
	media-fonts/nerdfonts
	media-fonts/noto
	media-fonts/noto-emoji
	media-gfx/imv
	media-gfx/swayimg
	media-sound/cava
	media-sound/pavucontrol
	media-sound/playerctl
	media-sound/pulsemixer
	media-video/mpv
	media-video/pipewire
	media-video/wireplumber
	lxqt-base/lxqt-policykit
	net-misc/networkmanager
	sys-apps/xdg-desktop-portal-gtk
	sys-process/btop
	x11-libs/gtk+:3
	x11-libs/gtk+:4
	x11-misc/pcmanfm
	x11-misc/xdg-user-dirs
	x11-terms/kitty
	x11-terms/wezterm
	x11-themes/adwaita-icon-theme
	x11-themes/arc-theme
	x11-themes/kvantum
	x11-themes/papirus-icon-theme
	webos-theme/webos-theme
	bluetooth? (
		net-wireless/blueman
		net-wireless/bluez
	)
	browser? ( www-client/firefox )
"
