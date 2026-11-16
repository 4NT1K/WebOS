<p align="center">
  <img src="assets/webos-cobweb-logo-512.png" alt="WebOS cobweb logo" width="160" />
</p>

# WebOS

A lightweight, source-built gaming operating system based on **Gentoo** (OpenRC), with its own kernel, installer, and Deep Black desktop experience for **Hyprland** and **KDE Plasma**.

| | |
|---|---|
| **Version** | 1.02 (Ashen) |
| **Base** | Gentoo (OpenRC + elogind, WebOS overlay/profile) |
| **Kernel** | `sys-kernel/webos-kernel` — vanilla LTS + gaming-oriented tuning, `-webos` localversion |
| **Init** | OpenRC (default) |
| **Desktops** | Hyprland (Wayland, default) + KDE Plasma 6 |
| **Installer** | `webos-installer` — custom Rust TUI/GUI wizard with profile + feature/app/shell customization |
| **Filesystem** | btrfs (default, subvolumes), ext4, xfs; LUKS2 option |
| **Bootloader** | GRUB2 (BIOS + UEFI) |
| **Arch** | amd64 (64-bit image, `ABI_X86="64"`) |
| **ISO** | `webos-1.02-Ashen-amd64.iso` |

WebOS aims for a fast, gaming-focused desktop with a consistent monochrome “Deep Black / frosted glass” look, prebuilt desktop/gaming essentials, and a simple update flow on top of Gentoo/Portage.

## What’s in 1.02

- **1.02 fix release:** repaired the `webos-theme` package merge (file collisions) that could leave the ISO without `webos-shell`, the waybar config, portal prefs and dark-mode defaults.
- **Settings/devices:** new `webos-settings` launcher; under Hyprland it offers `wdisplays`/`nwg-displays` and `hyprctl devices` so monitors and input devices are actually visible (KDE device panels require a Plasma session).
- **Portals/auth:** portal overrides moved to `/etc/xdg-desktop-portal` (no package collisions); Hyprland session restarts portals and starts the polkit agent with fallbacks.
- **Branding:** white spiderweb WebOS logo, WebOS identity across boot/login/desktop (OpenRC boot branding patched to WebOS), no Gentoo welcome/identity leaks.
- **Deep Black / monochrome theme parity (Hyprland + KDE Plasma):** pure-black frosted surfaces (~60% opacity, strong blur), monochrome palette (`#000000` bg, `#F2F2F2` fg, `#FFFFFF` labels, `#8C8C8C` dim, greyscale ANSI), white accents/cursor, custom default wallpaper, dark mode enabled by default.
- **Terminal stack:** kitty + fish + fastfetch themed to match; Konsole profile/colorscheme aligned for Plasma. Fastfetch shows the WebOS cobweb logo image in kitty with themed system info.
- **Hyprland UI:** frosted-glass top bar (waybar, ArchEclipse-inspired) with workspaces/window/music/system modules, wallpaper launcher, smoother animations, more reliable autostart/wallpaper, `Super+I` settings, and improved portal/auth session wiring.
- **Desktops/sessions:** Hyprland (xdg-desktop-portal-hyprland/gtk/wlr, hyprpolkitagent + fallbacks) and KDE Plasma (xdg-desktop-portal-kde, polkit-kde-authentication-agent-1), with session separation for menus where appropriate.
- **Installer customization:** separate **System options** and **Extra features** pages with profiles and selectable apps/features/shells/services (Gaming stack, Steam note, Firefox, Discord, Vesktop, OpenCode, Spotify, Waypaper, Fish, Zsh, Flatpak, NVIDIA, Bluetooth, SSH, firewall, GRUB).
- **Updates & packaging:** `webos-update` for sync/@world/depclean/config/flatpak/rice flow; build-time-only Portage overlays disabled on installed systems to avoid missing-repo warnings.

> UI note: the top bar/music-player experience is an Archeclipse-inspired approximation using **Hyprland + waybar** (not a 1:1 Quickshell clone).

## Key features

- **Two desktop experiences:** Hyprland (Wayland) and KDE Plasma 6 on one image.
- **Gaming-oriented stack:** gamescope, gamemode, MangoHud, vkBasalt, vkd3d-proton, Lutris, Heroic, PipeWire/WirePlumber, Vulkan/Mesa tooling (and NVIDIA driver support option).
- **Prebuilt essentials:** Firefox, Discord, OpenCode, Spotify, Dolphin, kitty, waybar, wofi, mako, mpv/imv and more (no compile during install for included apps).
- **WebOS tooling:** `webos-installer`, `webos-update`, `webos-rice`, `webos-fastfetch`, `webos-shell`, `webos-session`, `webos-wallpaper`, `webos-shot`, `webos-gaming`, `webos-plasma-setup`, `webos-settings`.

## Install

Download the latest release ISO (split parts + checksums): **[Releases](https://github.com/4NT1K/WebOS/releases)**

Reassemble and verify (Linux/macOS):
```bash
cat webos-1.02-Ashen-amd64.iso.part-* > webos-1.02-Ashen-amd64.iso
sha256sum -c SHA256SUMS.txt
```

Windows (PowerShell/CMD):
```bat
copy /b webos-1.02-Ashen-amd64.iso.part-* webos-1.02-Ashen-amd64.iso
```

Flash with Ventoy, Rufus, balenaEtcher, or `dd` (UEFI supported). Boot the live medium and run:
```bash
webos-installer
```

Unattended install:
```bash
webos-installer -c /etc/webos/install.toml -y
```

## Package management & updates

WebOS uses **Portage** (Gentoo) and **OpenRC**. There is no binary host configured by default, so `emerge` builds from source.

```bash
sudo emerge --sync
sudo emerge -av <package>
sudo emerge -avuDN @world
```

One-command updater:
```bash
sudo webos-update           # sync, update world, depclean, config updates, flatpak, rice
sudo webos-update --check   # dry run
```

- Enabled repos in image config: `gentoo`, `webos` (local overlay), and build-time third-party overlays; some are disabled on installed systems under `/etc/portage/repos.conf.disabled`.
- See installed docs: `/usr/share/webos/WEBOS-INFO.txt`

## Steam / 32-bit note

This image is **64-bit only** (no multilib runtime shipped). Native 32-bit Steam/Wine stacks are not included yet.
- **Flatpak Steam** works (kernel has 32-bit emulation): install Flatpak + Flathub, then `com.valvesoftware.Steam`.
- Distrobox is another option.
- Native multilib/Steam support is on the roadmap.

## Repository layout

```text
WebOS/
├── build.sh                  # build entry point
├── config/                   # Portage config, repos, sets, profile bits
├── kernel/                   # kernel config/patchset
├── overlay/                  # WebOS Gentoo overlay (ebuilds, theme/rice, tools)
├── installer/                # Rust installer (webos-installer)
├── livecd/                   # live-medium overlay
├── branding/                 # os-release, logos, version, issue
├── scripts/                  # build pipeline stages (00-fetch … 50-check)
└── docs/                     # build/architecture/release docs
```

## Building (from source)

WebOS is built on a Gentoo-capable host with the required tools and disk space.

```bash
git clone https://github.com/4NT1K/WebOS && cd WebOS
sudo ./build.sh fetch      # stage3, snapshots, overlays, patchset, vendor deps
sudo ./build.sh bootstrap  # unpack/apply config/base system
sudo ./build.sh kernel     # build webos-kernel
sudo ./build.sh rootfs     # emerge sets, installer, rice, branding
sudo ./build.sh iso        # squashfs/initramfs/GRUB hybrid ISO
# or
sudo ./build.sh all
```

Output: `build/webos-1.02-Ashen-amd64.iso`

See [`docs/BUILD.md`](docs/BUILD.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and [`docs/RELEASE.md`](docs/RELEASE.md) for details.

## Design rules

1. **Everything is an ebuild where practical.** System components and theme are packaged in the overlay.
2. **No silent patching.** Kernel patch sources/hashes are tracked and verified.
3. **The rice is a package.** `webos-theme`/`webos-rice` can re-apply the look idempotently.
4. **Installer installs the built system.** The live/install flow uses the produced rootfs + your choices.

## Roadmap

Planned work beyond 1.02 is tracked in [`ROADMAP.md`](ROADMAP.md) (multilib/native Steam, binhost, encryption/install UX improvements, handheld support, richer UI shell experiments, etc.).

## License

MIT for the build system, installer, rice and docs (where applicable). Ebuilds follow Gentoo conventions (typically GPL-2.0). See [`LICENSE`](LICENSE).
