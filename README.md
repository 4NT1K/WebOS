<p align="center">
  <img src="assets/webos-cobweb-logo-512.png" alt="WebOS cobweb logo" width="160" />
</p>

# WebOS

A lightweight, source-built gaming operating system based on **Gentoo** (OpenRC), with its own kernel, installer, and Deep Black desktop experience for **Hyprland** and **regular Plasma**.

| | |
|---|---|
| **Version** | 1.02 (Ashen) |
| **Base** | Gentoo (OpenRC + elogind, WebOS overlay/profile) |
| **Kernel** | `sys-kernel/webos-kernel` — vanilla LTS + gaming-oriented tuning, `-webos` localversion |
| **Init** | OpenRC (default) |
| **Desktops** | Hyprland with the monochrome rice (default); regular Plasma (Wayland) is an opt-in profile |
| **Installer** | `webos-installer` — custom Rust TUI/GUI wizard with session profiles and feature/app customization |
| **Filesystem** | btrfs (default, subvolumes), ext4, xfs; LUKS2 option |
| **Bootloader** | GRUB2 (BIOS + UEFI) |
| **Arch** | amd64 (64-bit image, `ABI_X86="64"`) |
| **ISO** | `webos-1.02-Ashen-amd64.iso` |

WebOS aims for a fast, gaming-focused desktop with one consistent greyscale look — floating rounded top-bar capsules, near-opaque panels and rounded windows — prebuilt desktop/gaming essentials, and a simple update flow on top of Gentoo/Portage.

## What’s in 1.02

- **Hyprland config that actually loads:** Hyprland 0.57 reads `~/.config/hypr/hyprland.lua` and ignores `hyprland.conf`. The rice is now a Lua config plus a `webos-colors.lua` palette module, with `~/.config/hypr/local.lua` loaded for personal tweaks.
- **Session reliability:** SDDM shows exactly the one session chosen in the installer (WebOS or regular Plasma), seeded in `/var/lib/sddm/state.conf`. Portals and a polkit agent start from `webos-portals` on OpenRC; `webos-session` applies the rice before launch; waybar and fastfetch have system-wide fallbacks and reliable autostart.
- **One look, no appearance page:** the refined Ashen greyscale rice — floating rounded top-bar capsules on a near-opaque bar, rounded windows — is the only WebOS appearance and is applied to every install. `webos-dotfiles` remains available for advanced users but the installer no longer asks.
- **Installer:** desktop profile choices are Hyprland, regular Plasma and TTY-only; the chosen session is seeded for the installed user. Plasma comes from the opt-in `@plasma` set and is removed from non-Plasma installs. The progress panel lists finished stages at 100%, shows the real stage count, and no helper command can paint over the TUI.
- **Fixes:** repaired `webos-theme` merge collisions that could leave an ISO without `webos-shell`, waybar config, portal prefs or dark-mode defaults; portal overrides live under `/etc/xdg-desktop-portal`.
- **Settings/devices:** `webos-settings` launcher; under Hyprland use `wdisplays` and compositor device tools (KDE device panels require a Plasma session).
- **Branding & theme:** soft-white spiderweb WebOS logo and WebOS identity (no Gentoo welcome/identity leaks). Refined Ashen greyscale parity across Hyprland and regular Plasma (#000000 base, #D8D8D8 text, #E8E8E8 accents, #7A7A7A dim); translucent kitty (opacity 0.82, `auto` fonts) with a chafa-symbol cobweb fastfetch card, and `Super+Shift+S` screenshot snips.
- **Hyprland UI:** near-opaque top bar (waybar) — left: workspaces and window title; centre: mpris pill that toggles the music dropdown; right: ▧ waypaper, clock, tray, ▾ performance, ⏻ power. `webos-menu` backs Super+D / Super+R, Super+M toggles a compact square music card with a per-song visualizer, and `webos-stats` opens the corner performance panel. Both dropdowns dismiss on outside click.
- **Updates & packaging:** `webos-update` sync/@world/depclean/config/kernel+GRUB/flatpak/rice flow — no manual kernel or software updates needed. Gentoo x86-64-v3 binpkgs are used by default via `--getbinpkg`, with `--fast`, `--strict-use`, `--buildpkg` and `--no-compile` controls; third-party overlays ship in the image so @world stays resolvable.

> **Plasma & X11:** regular Plasma 6.8.3 in this image is **Wayland-only** (`startplasma-wayland`, no `startplasma-x11` / Plasma X11 session). X11 Plasma is not available in 1.02 without adding X11 session packages.

## Colourways (dynamic accents)

The Deep Black base and grey text ramp never change, so CJK glyphs and kaomoji stay readable on every wallpaper. Only accents follow the colourway:

- **Automatic:** waypaper runs `webos-accent "$wallpaper"` after each wallpaper change. It extracts a bright, saturated colour and retints Hyprland borders, waybar, GTK 3/4, kitty, wofi and Spicetify.
- **Signature crimson:** `webos-accent --apply /usr/share/webos/colourways/webos-crimson.json`
- **Any colour:** `webos-accent --apply '#ee0001'`
- **Back to Ashen soft-white:** `webos-accent --reset`

Presets live in `overlay/webos-theme/webos-theme/files/colourways/` and install to `/usr/share/webos/colourways/`.

## Screenshots

| Terminal | Top bar |
|---|---|
| ![WebOS fastfetch card and health check](docs/screenshots/01-terminal.png) | ![Waybar](docs/screenshots/02-waybar.png) |

| Music card | Music over wallpaper |
|---|---|
| ![Music card](docs/screenshots/03-music-card.png) | ![Music over wallpaper](docs/screenshots/06-music-background.png) |

| Performance | Launcher |
|---|---|
| ![Performance panel](docs/screenshots/04-stats.png) | ![Curated application launcher](docs/screenshots/05-launcher.png) |

## Key features

- **Two desktop experiences:** Hyprland (Wayland) by default, with regular Plasma available through the opt-in profile.
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

WebOS uses **Portage** (Gentoo) and **OpenRC**. The Gentoo **x86-64-v3 binhost is configured by default** with source fallback: `emerge` prefers matching prebuilt binaries and builds from source when a binary does not match.

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

- Enabled repos in image config: `gentoo`, `webos` (local overlay), and the three third-party overlays (`guru`, `hyproverlay`, `steam-overlay`), which ship in the image and stay enabled on installed systems.
- See installed docs: `/usr/share/webos/WEBOS-INFO.txt`

## Steam / 32-bit note

This image is **64-bit only** (no multilib runtime shipped). Native 32-bit Steam/Wine stacks are not included yet.
- **Flatpak Steam** works (kernel has 32-bit emulation). Flatpak and Flathub are preinstalled, so just install `com.valvesoftware.Steam`.
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

See [`docs/BUILD.md`](docs/BUILD.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and [`docs/RELEASE.md`](docs/RELEASE.md) for details. If you are maintaining WebOS or pushing out updates, start with [`docs/MAINTENANCE.txt`](docs/MAINTENANCE.txt).

## Design rules

1. **Everything is an ebuild where practical.** System components and theme are packaged in the overlay.
2. **No silent patching.** Kernel patch sources/hashes are tracked and verified.
3. **The rice is a package.** `webos-theme`/`webos-rice` can re-apply the look idempotently.
4. **Installer installs the built system.** The live/install flow uses the produced rootfs + your choices.

## Roadmap

Planned work beyond 1.02 is tracked in [`ROADMAP.md`](ROADMAP.md) (multilib/native Steam, encryption/install UX improvements, handheld support, richer UI shell experiments, etc.).

## License

MIT for the build system, installer, rice and docs (where applicable). Ebuilds follow Gentoo conventions (typically GPL-2.0). See [`LICENSE`](LICENSE).
