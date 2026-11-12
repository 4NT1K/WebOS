# WebOS

A lightweight, source-built gaming operating system based on **Gentoo**, with its own
kernel, its own installer, and a clean black / transparent desktop.

```
      .------.
     /        \
    |  VELO   |
    |  SNUS   |
     \        /
      '------'
```

| | |
|---|---|
| **Codename** | Ashen |
| **Base** | Gentoo (OpenRC + elogind, `sanus` profile) |
| **Kernel** | `sys-kernel/sanus-kernel` — vanilla LTS + gaming patchset, `-sanusos` localversion |
| **Init** | OpenRC (systemd variant documented, not default) |
| **Desktop** | Hyprland (Wayland) with blur + true transparency |
| **Installer** | `sanus-installer` — custom Rust TUI wizard |
| **Filesystem** | Btrfs (default, subvolumes + snapshots), ext4, xfs; optional LUKS2 |
| **Bootloader** | GRUB2 (BIOS + UEFI), systemd-boot optional |
| **Target** | x86_64, ~2 GB RAM idle-friendly, tuned for Steam/Proton/gamescope |

WebOS is not a fork of Arch or of CachyOS. It targets the same *experience* CachyOS
does — a fast, gaming-first desktop with performance patches and sane defaults — but it is
built the Gentoo way: your binaries come from source, the toolchain is yours, and the
kernel is tuned for your machine.

---

## Why it is light

* **No GNOME/KDE stack.** Hyprland + Waybar + a small set of Wayland tools.
* **No systemd.** OpenRC + elogind. Faster boot, fewer daemons, no journal bloat.
* **Compiled for gaming, not for generality.** `-O2 -march=native`-capable, LTO-able,
  `USE` flags trimmed to what a gaming desktop actually needs.
* **Kernel tuned, not patched-to-death.** BORE scheduler, fsync/ntsync, BBRv3, zstd
  zram, `CONFIG_HZ=1000`, sched-ext available. Nothing that costs frames.
* **Idle target:** ~450 MB RAM with the desktop up, no browser.

## Why it games

* `steam`, `gamescope` (with the SteamOS session), `gamemode`, `mangohud`, `vkbasalt`,
  `goverlay`, `lact`, `corectrl`, `ananicy-cpp`, `irqbalance`, `thermald`.
* `wine-staging` + a first-class `sanus-proton` helper that installs Proton-GE.
* Mesa RADV/ANV + `vulkan-loader`, optional NVIDIA `nvidia-drivers` via a module set.
* `pipewire`/`wireplumber` low-latency audio, `scx_*` schedulers for per-game tuning.
* Applications install with **pacman** from the Arch repositories
  (`core`, `extra`, `multilib`): `sudo pacman -S steam firefox`. The base
  system stays source-built (Portage); only applications come from Arch.

---

## Repository layout

```
sanusos/
├── build.sh                  # one entry point: ./build.sh all
├── Makefile                  # convenience wrappers
├── config/                   # portage config injected into the build chroot
│   ├── make.conf             # CFLAGS, USE, FEATURES, BINHOST off
│   ├── package.use/          # per-package USE overrides
│   ├── package.accept_keywords/
│   ├── package.license/
│   ├── package.mask/
│   ├── repos.conf/           # gentoo, sanus, third-party overlays, arch
│   └── world                 # the WebOS package world file
├── kernel/
│   ├── sanus-fragment.config # merge_config fragment applied over defconfig
│   ├── patchset.conf         # upstream patch sources (BORE, fsync, BBRv3, ...)
│   └── fetch-patches.sh      # resolves + verifies the patch series
├── overlay/                  # the WebOS Gentoo overlay ("sanus")
│   ├── metadata/layout.conf
│   ├── profiles/sanus/
│   ├── sys-kernel/sanus-kernel/
│   ├── sys-kernel/sanus-kernel-sources/
│   ├── app-admin/sanus-installer/
│   ├── sanus-base/sanus-base/
│   ├── sanus-desktop/sanus-desktop/
│   ├── sanus-gaming/sanus-gaming/
│   └── sanus-theme/sanus-theme/
├── installer/                # Rust TUI installer (crate: sanus-installer)
│   ├── Cargo.toml            # ratatui + crossterm; release profile tuned for size
│   ├── vendor.sh             # cargo vendor -> vendor/ + .cargo/ for offline builds
│   └── src/{main,app,ui,theme,config,disk,rootfs,install,bootloader,exec}.rs
├── desktop/                  # Hyprland rice + theming, installed by sanus-theme
│   ├── hypr/  waybar/  wofi/  foot/  kitty/  gtk-3.0/  gtk-4.0/  kvantum/
│   └── wallpapers/           # (symlink to overlay/sanus-theme/.../files/rice)
├── livecd/                   # live-medium overlay: autologin, live menu, grub.cfg
│   ├── boot/grub/grub.cfg    # ISO GRUB config (@VOLID@ / @VERSION_FULL@ substituted)
│   ├── etc/                  # live marker, autologin glue
│   └── usr/local/bin/        # sanus-live-session
├── branding/                 # os-release, issue, lsb-release, logo, version
├── scripts/                  # build pipeline stages (00-fetch … 50-check)
└── docs/                     # BUILD.md, ARCHITECTURE.md, RELEASE.md
```

## Building

WebOS builds **on Gentoo** (or any host with `bubblewrap`/`chroot` + the Gentoo
tools). It needs root, ~40 GB free disk, and a few hours for a cold `@world`.

```bash
git clone https://github.com/sanusos/sanusos && cd sanusos
sudo ./build.sh fetch      # stage3 + portage snapshot + patchset + vendor the installer
sudo ./build.sh bootstrap  # unpack stage3, apply config/, emerge base
sudo ./build.sh kernel     # build sys-kernel/sanus-kernel
sudo ./build.sh rootfs     # emerge sanus-base/desktop/gaming, build installer, apply rice
sudo ./build.sh iso        # squashfs + initramfs + GRUB hybrid ISO
# or just:
sudo ./build.sh all
```

The `fetch` stage also runs `installer/vendor.sh` (`cargo vendor`), which is
what lets `app-admin/sanus-installer` build with `--locked --offline` inside
the chroot — the build never talks to crates.io. If `cargo` is not installed
when you fetch, the installer cannot be built; install `dev-lang/rust` and
re-run `./build.sh fetch`.

### Ebuild repositories

WebOS builds against five repositories, wired up in `config/repos.conf/`:

| Repo | Priority | Source | Provides |
|---|---|---|---|
| `sanus` | `100` | this tree (`/usr/local/portage/sanus`) | the kernel, installer, metas, theme |
| `gentoo` | `-1000` | Gentoo snapshot | the base system |
| `guru` | `-2000` | `gentoo-mirror/guru` | `mangohud`, `goverlay`, `lact`, `corectrl`, fonts, Wayland tools |
| `hyproverlay` | `-2000` | `codeberg.org/hyproverlay/hyproverlay` | `hyprland`, `waybar`, `hyprlock`, … |
| `steam-overlay` | `-2000` | `anyc/steam-overlay` | `steam-launcher` |

Higher priority wins, so `sanus` overrides `gentoo`, which overrides the
third-party overlays; the overlays are only consulted for packages `::gentoo`
does not carry. `fetch` shallow-clones them into `build/cache/repos/`,
`bootstrap` materialises them under `/var/db/repos/`, and Portage re-syncs
them on first use on an installed system (they are not shipped in the rootfs).

### Installing applications

`sys-apps/pacman` — pulled from the `arch` ebuild repository — is the
application package manager. Once installed, applications come from the Arch
repositories that `/etc/pacman.conf` points at (`core`, `extra`, `multilib`):

```bash
sudo pacman -S firefox steam
sudo pacman -S steam   # Steam, from multilib/extra as applicable
```

The Arch repositories themselves are declared in
`overlay/sys-apps/pacman/files/pacman.conf`; the `::arch` ebuild repository
carries pacman and the Arch-sourced packages.

Output: `build/sanus-1.0-Ashen-amd64.iso` (~1.6 GB).


See [`docs/BUILD.md`](docs/BUILD.md) for the full walkthrough, prerequisites,
mirrors, and how to bump the kernel or rebuild a single package;
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for how the pieces fit together;
[`docs/RELEASE.md`](docs/RELEASE.md) for the release checklist.

Before a release, or after touching the tree:

```bash
./scripts/50-check.sh    # manifests, metadata, branding, patchset, shell syntax
make lint                # shellcheck + cargo clippy + pkgcheck (skips what is absent)
```

## Design rules

1. **Everything is an ebuild.** No hand-copied binaries into the rootfs except the
   installer, which is itself built and installed by `app-admin/sanus-installer`.
2. **Nothing is patched silently.** Kernel patches live in `kernel/patchset.conf` with
   URLs + hashes, and `fetch-patches.sh` refuses to build on a mismatch.
3. **The rice is a package.** `sanus-theme` owns every dotfile under `desktop/`, so
   `emerge --config sanus-theme` re-applies the aesthetic idempotently.
4. **The installer is not special.** It installs the same rootfs the ISO was built from,
   plus your choices. No hidden third-party install path.

## Status

This is the buildable source tree: overlay, ebuilds, kernel config, patch resolver,
installer, rice, ISO pipeline, and docs. It is designed to be run on a Gentoo host;
`build.sh` will refuse to run on a non-Gentoo system unless `SANUS_FORCE=1`.

## License

MIT for the build system, installer, rice and docs. Ebuilds are GPL-2.0 (Gentoo
convention). See [`LICENSE`](LICENSE).
