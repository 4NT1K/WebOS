# WebOS architecture

How the pieces of WebOS fit together: the repository, the boot flow, the
install recipe, and the decisions behind them.

---

## 1. Principles

1. **Everything is an ebuild.** Nothing is copied into the rootfs except by a
   package. The installer is itself `app-admin/sanus-installer`.
2. **Nothing is patched silently.** Kernel patches live in
   `kernel/patchset.conf` with URLs and hashes; `fetch-patches.sh` refuses to
   build on a mismatch.
3. **The rice is a package.** `sanus-theme` owns every dotfile, so
   `emerge --config sanus-theme/sanus-theme` re-applies the aesthetic
   idempotently.
4. **One install code path.** The interactive wizard and
   `--config FILE --yes` fill the same `InstallConfig` and run the same
   `install::run`.

---

## 2. Repository layout

```
WebOS/
├── build.sh                 top-level entry point (fetch → iso)
├── Makefile                 convenience wrappers (make iso, make lint, …)
├── branding/                version, os-release, issue, logo
├── config/                  Portage configuration injected into the chroot
│   ├── make.conf            CFLAGS/USE/FEATURES for the whole distro
│   ├── world                the base world file
│   ├── repos.conf/          gentoo, sanus, guru, hyproverlay, steam-overlay
│   ├── sets/{base,desktop,gaming,sanus-installer}
│   └── package.{use,accept_keywords,license,mask}/
├── kernel/                  kernel metadata (not the sources)
│   ├── patchset.conf        the patch series, with URLs and hashes
│   ├── fetch-patches.sh     resolves, downloads, pins and verifies
│   └── sanus-fragment.config → overlay/sys-kernel/sanus-kernel/files/…
├── overlay/                 the "sanus" Gentoo overlay
│   ├── metadata/, profiles/ repository metadata and the sanus profile
│   ├── eclass/sanus-kernel.eclass
│   ├── sys-kernel/sanus-kernel{,-sources}/
│   ├── app-admin/sanus-installer/
│   └── sanus-{base,desktop,gaming,theme}/
├── installer/               the Rust TUI installer crate
├── desktop → overlay/sanus-theme/sanus-theme/files/rice
├── livecd/                  live-medium overlay (autologin, live menu, grub.cfg)
├── scripts/                 the build pipeline (00-fetch … 50-check)
└── docs/                    BUILD.md, ARCHITECTURE.md, RELEASE.md
```

Two symlinks keep a single source of truth:

* `desktop` → `overlay/sanus-theme/sanus-theme/files/rice` — the rice lives in
  the package that installs it.
* `kernel/sanus-fragment.config` → the overlay's kernel fragment — the fragment
  lives with the ebuild that consumes it.

---

## 3. Layers

WebOS is four things stacked:

```
        ┌──────────────────────────────────────────────┐
        │  rice        sanus-theme  (Hyprland, Waybar…) │
        ├──────────────────────────────────────────────┤
        │  gaming      sanus-gaming (Steam, Proton…)    │
        │  desktop     sanus-desktop (Hyprland, greetd) │
        │  base        sanus-base    (OpenRC, NM, …)    │
        ├──────────────────────────────────────────────┤
        │  kernel      sanus-kernel  (LTS + patchset)   │
        ├──────────────────────────────────────────────┤
        │  base system Gentoo stage3 + our Portage cfg  │
        └──────────────────────────────────────────────┘
```

* **Base system** — Gentoo stage3 plus `config/` (make.conf, USE policy,
  keywords, masks, licenses, profile). This is what `bootstrap` produces.
* **Ebuild repositories** — `::gentoo` plus our `::sanus` overlay and three
  third-party overlays (`::guru`, `::hyproverlay`, `::steam-overlay`) that
  carry the Hyprland stack, the Steam launcher and the misc gaming tools, plus
  the Arch application packages.
  Priority is `sanus (100) > gentoo (-1000) > third-party (-2000) >
  the base stack do not carry. See [`BUILD.md`](BUILD.md#10-ebuild-repositories).
* **Package manager** — the base system and the WebOS meta sets are installed
  with Portage (the Gentoo package manager).
  repository as `sys-apps/pacman` — is the **application package manager**: once
  it is installed, applications come from the Arch repositories configured in
  `/etc/pacman.conf` (`core`, `extra`, `multilib`) via `pacman -S`. This gives a
  CachyOS-like "install apps, don't compile them" experience on top of the
  source-built Gentoo base.
* **Kernel** — `sys-kernel/sanus-kernel`, built from upstream LTS plus the
  patch series, configured by the fragment.
* **Meta sets** — `sanus-base`, `sanus-desktop`, `sanus-gaming` are pure
  metapackages (`RDEPEND` only). `config/sets/*` mirror them for build-time
  `emerge @set` convenience.
* **Rice** — `sanus-theme` owns the dotfiles and the session glue.

`config/sets/*` and the metapackage `RDEPEND` overlap on purpose: the sets are
what the build emerges, the metapackages are what an installed system can
`emerge --update` against.

---

## 4. The kernel

### Patchset

`kernel/patchset.conf` is a pipe-delimited table: `name | url | sha256 |
target-series | description`. `kernel/fetch-patches.sh` reads it and writes a
resolved series into `build/cache/kernel-patches/`:

* `*.patch` — the individual patches
* `series` — ordered absolute paths (consumed by the eclass)
* `INDEX` — human-readable table
* `.lock` — `name=sha256` lines

The hash column may be `auto`, in which case the script computes the digest and
**rewrites `patchset.conf` in place** so the pin is committed. A non-`auto`
hash is never rewritten; a mismatch aborts the build.

Shipped patches (6.12): BORE scheduler, Wine `fsync`, `ntsync` backport, TCP
BBRv3, AMD P-State EPP, `i2c-piix4` for OpenRGB, and MGLRU knobs.

### Config fragment

The kernel is configured by merging `sanus-fragment.config` over upstream
`defconfig`. `sanus-kernel.eclass` implements `sanus_merge_config`, which is
deliberately stricter than `scripts/kconfig/merge_config.sh`: each `CONFIG_*`
symbol in the fragment **replaces** whatever the base said, including a prior
`# CONFIG_FOO is not set`. `make olddefconfig` resolves anything new.

The fragment sets `CONFIG_LOCALVERSION="-webos"`, `CONFIG_HZ=1000`,
`CONFIG_PREEMPT_DYNAMIC=y`, `CONFIG_SCHED_CLASS_EXT=y` (sched-ext),
`CONFIG_SCHED_BORE=y` (harmless if the patch is absent) and the usual desktop
knobs. The installed release string is therefore `6.12.0-webos`.

### Eclass

`sanus-kernel.eclass` provides four functions shared by
`sanus-kernel` and `sanus-kernel-sources`:

| Function | Purpose |
| --- | --- |
| `sanus_apply_patchset` | Apply `series`; a missing patch is fatal. Falls back to `${FILESDIR}/*.patch` with a warning if no series was resolved. |
| `sanus_merge_config` | Deterministic Kconfig fragment merge. |
| `sanus_kernel_make` | `make` with the right `ARCH`/`CC`/`LD`/jobs. |
| `sanus_kernel_release` | Print the release string. |
| `sanus_kernel_install` | Install the image, modules, and a header tree for DKMS/out-of-tree builds. |

The sources package ships the patched tree under `/usr/src/linux-<PV>` and the
fragment alongside it, so a manual build is `make defconfig` +
`merge_config.sh` + `make`. The kernel package owns the `/usr/src/linux`
symlink so the *configured* tree is always the default.

---

## 5. The installer

A single Rust binary (`installer/`, crate `sanus-installer`), ~1 MB, release
profile `opt-level="z"`, LTO, `panic="abort"`, stripped. Dependencies: `ratatui`
+ `crossterm` for the TUI, `serde`/`toml` for the answer file, `anyhow`/
`thiserror` for errors, `libc` for the euid check.

### Source map

| File | Responsibility |
| --- | --- |
| `main.rs` | Argument parsing, terminal setup, the event loop. |
| `app.rs` | Wizard state, key handling, the install worker thread. |
| `ui.rs` | Rendering (ratatui); pure functions of `App`. |
| `theme.rs` | The Ashen palette, shared with the rice. |
| `config.rs` | `InstallConfig`, enums, validation. |
| `disk.rs` | Enumerating disks, detecting firmware, partition paths. |
| `rootfs.rs` | Locating the system to install. |
| `install.rs` | The install recipe. |
| `bootloader.rs` | GRUB installation and the kernel command line. |
| `exec.rs` | Running commands, logging, reporting to the UI. |

### Concurrency

The UI thread owns `App`; the install runs on a worker thread that reports
through a `Runner`. Once the worker starts, the UI only accepts scrolling —
`Ctrl-C` is disabled — until the worker reports `Done` or `Failed`. Nothing
touches the disk before the summary page is confirmed.

### Finding the system to install

`rootfs::locate()` looks, in order, at:

* `$SANUS_ROOTFS` (explicit override: a directory or a tarball),
* a fixed list of mounted live roots (`/run/initramfs/live`, `/run/rootfs`,
  `/run/sanus/rootfs`, …),
* a fixed list of rootfs tarballs.

A directory counts as a WebOS root if it has `etc/` and `usr/` plus either
`etc/sanus-release`, an `os-release` mentioning `ID=sanus`/`WebOS`, or a
`usr/local/portage/sanus` overlay. If only an unmounted `sanus.squashfs` is
found, `install::run` calls `rootfs::ensure_mounted("/run/sanus/rootfs")` and
looks again.

### The install recipe (`install::run`)

Linear and logged, so a failed install reads like a recipe:

1. **Prepare** — locate the source, re-check the target disk, verify required
   tools (`sgdisk mkswap mount blkid rsync tar chroot grub-install`).
2. **Partition** — `sgdisk --zap-all`, then ESP (UEFI, `ef00`) or BIOS boot
   (`ef02`), optional swap (`8200`), and a root partition (`8300`).
3. **Encrypt** — optional LUKS2 (`aes-xts-plain64`, argon2id), opened as
   `sanus_crypt`.
4. **Filesystems** — `mkfs.btrfs`/`ext4`/`xfs`; on btrfs, create the subvolumes
   `@ @home @snapshots @cache @log @tmp` and remount by subvolume with
   `compress=zstd:1,noatime,ssd,space_cache=v2,discard=async`.
5. **Copy** — `rsync -aHAX --numeric-ids --one-file-system` (or `tar` for a
   tarball source), excluding `/proc /sys /dev /run /tmp /var/tmp /mnt /media`,
   `machine-id` and SSH host keys.
6. **fstab / crypttab** — UUID-based, btrfs subvolumes, a `/tmp` tmpfs.
7. **Configure in chroot** — hostname, locale, timezone, keymap, users,
   sudoers, OpenRC services, the rice, GPU selection, `/etc/sanus/install.toml`,
   and removal of the live-medium glue (`/etc/inittab.sanus-orig` restored,
   `/etc/sanus-live` and friends deleted).
8. **Initramfs** — `dracut` inside the target, adding `crypt`/`dm` for LUKS
   and `btrfs` for btrfs.
9. **Bootloader** — GRUB (see below).
10. **Record** — copy the command log to `/var/log/sanus-install.log`, then
    unmount everything.

### Bootloader

Only GRUB is supported: it is the one bootloader that installs cleanly onto
both a UEFI ESP and a BIOS MBR from the same medium.

* UEFI: `grub-install --target=x86_64-efi --efi-directory=/boot/efi
  --bootloader-id=WebOS`, with a fallback copy to
  `/boot/efi/EFI/BOOT/BOOTX64.EFI`. If the machine booted in BIOS mode, the
  NVRAM entry is skipped (`--no-nvram`) rather than failing the install.
* BIOS: `grub-install --target=i386-pc --boot-directory=/boot`.

The kernel command line is generated by `kernel_cmdline`:

```
quiet loglevel=3 nowatchdog
root=UUID=<uuid>            # or rd.luks.name=<uuid>=sanus_crypt root=/dev/mapper/sanus_crypt
rootflags=subvol=@          # btrfs only
nvidia-drm.modeset=1 …      # nvidia only
```

`rootflags=subvol=@` is not optional on btrfs: without it the kernel mounts
subvolid 5 and finds no `/sbin/init`.

---

## 6. The rice

`sanus-theme` installs the pristine rice under `/usr/share/sanus/rice` and a
set of helper binaries (`sanus-rice`, `sanus-session`, `sanus-wallpaper`,
`sanus-shot`, `sanus-gaming`). Files that another package owns (GTK configs,
greetd's config, Hyprland's own files) are **not** shipped from the package
image; they are written by `sanus-rice --system` in `pkg_postinst`, with a
one-time backup, which keeps the tree free of file collisions.

`emerge --config sanus-theme/sanus-theme` re-applies everything idempotently,
including for every account in `/home`.

### Palette (Ashen)

| Role | Value |
| --- | --- |
| Base | `#050508` |
| Surface | `rgba(10,10,12,0.55)` |
| Text | `#f0f0f5` |
| Text (dim) | `#9aa3ad` |
| Accent | `#f0f0f5` |
| Accent glow | `#7dd3fc` |
| Urgent | `#f87171` |

The same palette is used by the installer's `theme.rs`, so the wizard and the
desktop look like one product.

### Session

Login is `greetd` + `tuigreet`. The session entries are named `sanus` (not
`hyprland`) so they never collide with the upstream package. `sanus-session`
exports the environment and starts Hyprland; `sanus-gamescope.desktop` is the
gamescope/SteamOS-style session.

---

## 7. The live medium and the ISO

The ISO is a hybrid BIOS+UEFI image built by `grub-mkrescue`:

```
/boot/grub/grub.cfg          generated from livecd/boot/grub/grub.cfg
/boot/vmlinuz-sanus          the kernel
/boot/initramfs-sanus.img    dracut, with dmsquash-live
/live/sanus.squashfs         the live system (also the install source)
/sanus/version               branding read by the live session
```

`dmsquash-live` mounts the squashfs at `/run/initramfs/live` with an
overlayfs upper layer, so the live system is writable but ephemeral. The
installer treats `/run/initramfs/live` as its source.

**Live autologin.** tty1 logs in as root and runs `sanus-live-session`, a small
menu in front of the installer. Two mechanisms cover the stage3 ambiguity:
`livecd/etc/conf.d/agetty.tty1` (OpenRC `agetty`) and an `/etc/inittab` patch
(sysvinit), the latter backed up as `/etc/inittab.sanus-orig`. The installer
restores the backup and deletes the rest of the glue, so an installed system
boots to a normal login.

**Safety net.** `sanus-live-session` and `/etc/profile.d/99-sanus-live.sh` both
check for `/etc/sanus-live` before doing anything, so the live session can
never take over a real system.

---

## 8. Boot flows

### Live medium → install

```
firmware → GRUB (hybrid) → vmlinuz-sanus + initramfs-sanus.img
        → dracut dmsquash-live mounts /live/sanus.squashfs at /run/initramfs/live
        → OpenRC boots; tty1 autologins root
        → sanus-live-session → sanus-installer
        → partition, copy /run/initramfs/live, chroot-configure
        → dracut + grub-install in the target
        → reboot into the installed system
```

### Installed system

```
firmware → GRUB → vmlinuz-6.12.0-webos + initramfs
        → root=UUID=… [rd.luks.name=…] rootflags=subvol=@
        → OpenRC → greetd (tuigreet) → sanus-session → Hyprland
```

---

## 9. Decisions and why

| Decision | Rationale |
| --- | --- |
| Gentoo base | Source-built, so the toolchain and USE flags are yours; the same *experience* as CachyOS, built the Gentoo way. |
| OpenRC + elogind | Lighter and faster than systemd; `sys-apps/systemd-utils` still provides udev. systemd is masked in the profile. |
| Hyprland | Wayland-first, compositor blur/transparency, small footprint. |
| Vanilla LTS + patchset | Fewer moving parts than a fork; patches are explicit, hashed, and few. |
| Fragment over full config | Upstream `defconfig` never rots; the fragment only states the deltas. |
| Btrfs default | Subvolumes + zstd compression + snapshots, matching what a modern gaming install expects. |
| GRUB only | One bootloader that covers BIOS and UEFI from the same medium. |
| Rust TUI installer | One static binary, no Python/GTK/Calamares, no package manager in the installer. |
| Vendored cargo deps | The ebuild builds `--offline`; the chroot never needs crates.io. |
| Rice as a package | `emerge --config` is the re-apply button; nothing is a hidden copy step. |
| Patches not vendored | Fetched and pinned at build time, so a rebuild reproduces the kernel or fails loudly. |
| pacman for applications | Arch repositories (`core`, `extra`, `multilib`) give a CachyOS-like "install apps, don't compile" path; the base system itself stays source-built. |
