EAPI=8

DESCRIPTION="WebOS gaming stack — Steam, Proton, gamescope, MangoHud, tuning"
HOMEPAGE="https://github.com/ugss96/WebOS/"
SRC_URI=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+amd +nvidia +steam tuning"

REQUIRED_USE="^^ ( amd nvidia )"

RDEPEND="
	app-arch/cabextract
	app-arch/innoextract
	app-arch/unrar
	app-emulation/protontricks
	app-emulation/vkd3d-proton
	app-emulation/winetricks
	app-emulation/wine-staging
	dev-util/vulkan-tools
	games-emulation/dosbox-staging
	games-engines/scummvm
	games-util/gamemode
	games-util/game-device-udev-rules
	games-util/goverlay
	games-util/mangohud
	gui-wm/gamescope
	media-gfx/vkBasalt
	media-libs/libglvnd
	media-libs/libva
	media-libs/mesa
	media-libs/vulkan-layers
	media-libs/vulkan-loader
	virtual/libudev
	steam? (
		games-util/heroic-bin
		games-util/lutris
		games-util/steam-launcher
	)
	tuning? (
		app-admin/ananicy-cpp
		app-misc/corectrl
		sys-apps/earlyoom
		sys-apps/msr-tools
		sys-apps/preload
		sys-apps/lact
		sys-kernel/scx
		sys-power/RyzenAdj
		sys-power/thermald
	)
	amd? ( media-libs/mesa[video_cards_radeonsi,video_cards_amdgpu] )
	nvidia? (
		media-libs/nv-codec-headers
		x11-drivers/nvidia-drivers
	)
"
