EAPI=8

DESCRIPTION="WebOS base system — init, networking, storage, diagnostics"
HOMEPAGE="https://github.com/ugss96/WebOS/"
SRC_URI=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

# Everything a WebOS machine needs to boot, mount, network and repair itself.
# Deliberately excludes the desktop and the gaming stack; those are separate
# packages so a server or a minimal install can skip them.
RDEPEND="
	app-admin/ananicy-cpp
	app-admin/eclean-kernel
	app-admin/sudo
	app-admin/syslog-ng
	app-arch/libarchive
	app-misc/ca-certificates
	app-misc/mc
	app-portage/eix
	app-portage/gentoolkit
	app-portage/portage-utils
	app-shells/starship
	app-shells/zsh
	app-shells/zsh-completions
	dev-debug/ltrace
	dev-debug/strace
	dev-libs/glib
	dev-util/perf
	net-analyzer/iftop
	net-analyzer/nethogs
	net-dns/openresolv
	net-firewall/nftables
	net-misc/iputils
	net-misc/networkmanager
	net-vpn/networkmanager-openvpn
	sys-apps/hdparm
	sys-apps/kmod
	sys-apps/pacman
	sys-apps/less
	sys-apps/man-db
	sys-apps/man-pages
	sys-apps/nvme-cli
	sys-apps/openrc
	sys-apps/smartmontools
	sys-apps/systemd-utils[udev]
	sys-apps/util-linux
	sys-apps/which
	sys-auth/elogind
	sys-auth/nss-mdns
	sys-auth/pambase
	sys-auth/polkit
	sys-auth/rtkit
	app-misc/tmux
	sys-apps/irqbalance
	sys-fs/udiskie
	sys-fs/udisks
	sys-libs/timezone-data
	sys-power/cpupower
	sys-power/powertop
	sys-power/thermald
	sys-process/numactl
	sys-process/procps
	sys-process/psmisc
	sys-process/time
"
