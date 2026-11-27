# Building WebOS

This is the full walkthrough for turning the source tree into
`build/webos-1.034-Ashen-amd64.iso`.

WebOS is a source distribution, so a cold build compiles a toolchain, a
kernel, a desktop and a gaming stack. Budget **several hours** and a real
machine; the pipeline is designed for a Gentoo host with root access.

---

## 1. What you need

| Requirement | Why |
| --- | --- |
| A **Gentoo** host (or a container that looks like one) | `build.sh` refuses other hosts unless `WEBOS_FORCE=1`. |
| **root** | `bootstrap`, `kernel`, `rootfs` and `iso` mount filesystems and chroot. |
| **~40 GB** free in the build directory | stage3 + portage snapshot + chroot + rootfs + ISO staging. |
| **~8 GB RAM** (16 GB comfortable) | `MAKEOPTS` and `EMERGE_DEFAULT_OPTS` assume parallelism; lower them on small machines. |
| Host tools | `curl tar xz zstd gzip sha256sum git` plus, for the ISO stage, `mksquashfs grub-mkrescue mformat xorriso`. |
| **network access** | `fetch` downloads the stage3, the portage snapshot and clones the three third-party ebuild overlays. |
| `dev-lang/rust` (or `rust-bin`) | Only needed to vendor the installer crate during `fetch`. |

`./build.sh status` reports which of these are present.

The build is **not** a sandboxed bootstrap: the stages run inside a chroot made
from a Gentoo **stage3**, not on your host root. Your host only provides the
kernel, the tools above, and the network.

---

## 2. Quick start

```bash
git clone https://github.com/4NT1K/WebOS && cd WebOS
sudo ./build.sh fetch       # stage3 + portage snapshot + kernel patchset + vendor
sudo ./build.sh bootstrap   # unpack stage3, apply config/, emerge @world
sudo ./build.sh kernel      # build sys-kernel/webos-kernel
sudo ./build.sh rootfs      # emerge the WebOS sets, build the installer, apply the rice
sudo ./build.sh iso         # squashfs + initramfs + hybrid GRUB image
```

or, all of it:

```bash
sudo ./build.sh all
```

Output:

```
build/webos-1.034-Ashen-amd64.iso
build/webos-1.034-Ashen-amd64.iso.sha256
```

`make iso`, `make kernel`, etc. are thin wrappers over the same stages.

---

## 3. Environment knobs

Every knob is optional. They are read by `scripts/lib/common.sh`.

| Variable | Default | Effect |
| --- | --- | --- |
| `WEBOS_ARCH` | `amd64` | Target architecture (`amd64` or `arm64`). |
| `WEBOS_STAGE3_VARIANT` | `openrc` | Which stage3 flavour to unpack (`openrc`, `systemd`, `nomultilib`). |
| `WEBOS_JOBS` | `nproc` | Parallelism for `emerge`, `make` and `egencache`. |
| `WEBOS_BUILD_DIR` | `./build` | Where the chroot, downloads, rootfs and ISO live. |
| `WEBOS_MIRROR` | `https://distfiles.gentoo.org` | Gentoo **distfiles** mirror for stage3 and the kernel tarball. |
| `WEBOS_PORTAGE_MIRROR` | `https://snapshots.gentoo.org` | Portage **snapshot** mirror. |
| `WEBOS_KERNEL_SERIES` | `6.12` | Kernel series; also selects the patchset entries to fetch. |
| `WEBOS_FORCE` | unset | Run on a non-Gentoo host (unsupported). |
| `WEBOS_DEBUG` | unset | Echo every command the pipeline runs. |

Example: build on a 6-core laptop from a local mirror.

```bash
sudo WEBOS_JOBS=6 \
     WEBOS_MIRROR=https://mirror.example.net/gentoo \
     WEBOS_PORTAGE_MIRROR=https://mirror.example.net/gentoo-snapshots \
     ./build.sh all
```

---

## 4. The stages, in detail

### `fetch` — `scripts/00-fetch.sh`

1. Resolves the newest `latest-stage3-amd64-openrc.txt` on the mirror and
   downloads the stage3 (with its published `.sha256` sidecar when there is
   one). The path is recorded in `build/.stage3-path`.
2. Resolves and downloads the newest `portage-YYYYMMDD.tar.*` snapshot.
   Recorded in `build/.portage-path`.
3. Runs `kernel/fetch-patches.sh`, which downloads the patchset described in
   `kernel/patchset.conf` into `build/cache/kernel-patches/`. Entries whose hash
   column is `auto` are pinned **in place** on first fetch; a mismatch against
   an existing pin is fatal.
4. Shallow-clones the three third-party ebuild overlays that WebOS builds
   against — `::guru`, `::hyproverlay` and `::steam-overlay` — into
   `build/cache/repos/` (see §10).
5. Runs `installer/vendor.sh` (`cargo generate-lockfile` + `cargo vendor`) so
   the installer can be built with no network later.

Nothing needs root; downloads are resumable (`curl --continue-at -`).

### `bootstrap` — `scripts/10-bootstrap.sh`

1. Unpacks the stage3 into `build/chroot` (skipping `/dev`).
2. Unpacks the portage snapshot into `/var/db/repos/gentoo`.
3. Installs `config/` into the chroot: `make.conf`, the `package.*` trees,
   every `repos.conf/*.conf` (`gentoo`, `webos`, `guru`, `hyproverlay`,
   `steam-overlay`), `sets/`, and the `world` file.
4. Copies the whole `overlay/` to `/usr/local/portage/webos` **inside** the
   chroot, and materialises the cached third-party overlays under
   `/var/db/repos/`, so `emerge` needs no host bind mounts.
5. Mounts `/proc /sys /dev …` into the chroot, selects the
   `webos:default/linux/<arch>/webos` profile, and emerges `@world`.

This is the long stage: it builds the toolchain and the base system from source.

### `kernel` — `scripts/20-kernel.sh`

1. Refreshes the overlay copy inside the chroot and drops the resolved patch
   series into `/var/cache/webos/patches` (the eclass reads it from there).
2. Runs `egencache` so the freshly-copied ebuilds are visible.
3. Regenerates the Manifests for `sys-kernel/webos-kernel-sources` and
   `sys-kernel/webos-kernel` with `ebuild … manifest`. The committed Manifests
   pin `linux-6.12.tar.xz` and `patch-6.12.119.xz`; `kernel-2.eclass` unpacks
   the base tarball and applies the stable patch to reach 6.12.119.
4. Emerges `sys-kernel/webos-kernel-sources` and `sys-kernel/webos-kernel`.
5. Writes the installed release (e.g. `6.12.119-webos`) to
   `build/.kernel-release`.

### `rootfs` — `scripts/30-rootfs.sh`

1. Refreshes the overlay and the `sets/` inside the chroot.
2. Emerges `@base @desktop @gaming @webos-installer`.
3. Builds the installer tarball from `installer/` (`Cargo.toml`, `Cargo.lock`,
   `src/`, `vendor/`, `.cargo/`) and drops it into the chroot's `DISTDIR`,
   then regenerates the installer Manifest with `scripts/lib/mkmanifest.sh`.
4. Emerges `app-admin/webos-installer` (offline `cargo build --release`).
5. Installs branding (`os-release`, `issue`, `lsb-release`, logo).
6. Emerges `webos-theme/webos-theme` and runs its config hook.
7. `rsync`s the chroot into `build/rootfs`, excluding `/proc /sys /dev /tmp
   /var/tmp /var/cache /usr/src` and the module build trees. `/var/db/repos`,
   including the third-party overlays, is shipped in the rootfs.

`build/rootfs` is the finished system. The ISO stage and the installer both
consume it.

### `iso` — `scripts/40-iso.sh`

1. Copies the kernel image to `/boot/vmlinuz-webos`.
2. Builds a live initramfs **inside the chroot** with `dracut`, enabling
   `dmsquash-live` and `pollcdrom` (see the stage script for the exact module
   and driver list).
3. Copies `build/rootfs` to `build/live-root`, overlays `livecd/` on top, and
   patches the live getty for root autologin (both the OpenRC `agetty.tty1`
   path and the sysvinit `/etc/inittab` path; the latter is backed up as
   `/etc/inittab.webos-orig`).
4. Compresses it to `/live/webos.squashfs` (zstd, 1 MiB blocks).
5. Writes `/webos/version` and substitutes `@VOLID@` / `@VERSION_FULL@` in
   `livecd/boot/grub/grub.cfg`.
6. Builds a **hybrid** BIOS+UEFI image with `grub-mkrescue` and writes the
   `.sha256`.

---

## 5. Rebuilding one thing

The stages are idempotent enough to re-run individually.

**Rebuild one package** (inside the chroot):

```bash
sudo ./build.sh status              # confirms the chroot exists
sudo WEBOS_DEBUG=1 ./build.sh rootfs   # or enter the chroot yourself
```

There is no `enter` subcommand; mount and chroot by hand if you want a shell:

```bash
sudo mount --rbind /proc build/chroot/proc   # repeat for sys, dev, dev/pts
sudo chroot build/chroot /bin/bash
```

**Rebuild just the installer**, on the host, no chroot:

```bash
make installer          # == make -C installer release
installer/target/release/webos-installer --version
```

**Rebuild just the kernel**: `sudo ./build.sh kernel`, then `iso` (the ISO
embeds a copy of the kernel and a freshly built initramfs).

**Re-apply the rice** inside a running system:

```bash
sudo emerge --config webos-theme/webos-theme
webos-rice --user        # for the current user
webos-rice --doctor      # check what the compositor picked up
```

---

## 6. Bumping the kernel

1. Edit `branding/version` → `WEBOS_KERNEL_SERIES`.
2. Update `kernel/patchset.conf`: change the `target-series` column and the
   `sha256` column back to `auto` for any patch that moved.
3. Add a matching `sys-kernel/webos-kernel/webos-kernel-<PV>.ebuild` and
   `sys-kernel/webos-kernel-sources/webos-kernel-sources-<PV>.ebuild` (bump
   `PV`; the eclass derives the series from it).
4. Point the `kernel/webos-fragment.config` symlink at the (single) fragment —
   it is shared by both packages, so there is usually nothing to change.
5. `./build.sh fetch` to re-pin the hashes, then `kernel` and `iso`.

Because the Manifests for the kernel packages are regenerated at build time
(step 3 of the `kernel` stage), a bump does not require committing new hashes.

---

## 7. Offline and mirrored builds

* **Stage3 + snapshot**: point `WEBOS_MIRROR` / `WEBOS_PORTAGE_MIRROR` at a
  local mirror. `fetch` caches into `build/downloads`, so a second run is
  offline for those files.
* **Installer**: `installer/vendor.sh` vendors the crates; the ebuild then
  builds with `CARGO_NET_OFFLINE=true`, so the chroot needs no crates.io.
* **Kernel patches**: `kernel/fetch-patches.sh --verify` re-checks every pinned
  hash without downloading. Run it in CI to catch an upstream rewrite.

---

## 8. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `missing host tool: …` | Install the tool listed; the ISO stage needs `grub-mkrescue` and `mformat` (from `sys-boot/grub` and `sys-fs/mtools`). |
| `WebOS builds on Gentoo` | You are on another distro. Set `WEBOS_FORCE=1` (unsupported) or build on Gentoo. |
| `chroot not bootstrapped` | Run `./build.sh bootstrap` first. |
| `installer/vendor is missing` | Run `./build.sh fetch` with `cargo` on `PATH`. |
| `stage3 checksum mismatch` | A truncated download. Delete the file in `build/downloads` and re-run `fetch`. |
| `HASH MISMATCH … refusing to continue` | Upstream rewrote a kernel patch. Review the diff and re-pin deliberately in `kernel/patchset.conf`. |
| `could not resolve stage3` | The mirror layout changed or the network is down; try another `WEBOS_MIRROR`. |
| Out of disk | `./build.sh clean` removes the rootfs/ISO staging but keeps the chroot; `./build.sh distclean` removes everything. |

Unmounting: every stage installs an `EXIT` trap that unmounts the chroot. If a
stage is killed hard, run `./build.sh distclean` (it umounts first) or
`umount -R build/chroot` by hand.

---

## 9. What lands where

| Path | Contents |
| --- | --- |
| `build/downloads/` | stage3, portage snapshot, `.sha256` sidecars. |
| `build/cache/kernel-patches/` | resolved patch series, `series`, `INDEX`, `.lock`. |
| `build/cache/repos/` | shallow clones of `::guru`, `::hyproverlay`, `::steam-overlay`. |
| `build/chroot/` | the build root (stage3 + portage tree + everything emerged). |
| `build/rootfs/` | the exported, ready-to-install system. |
| `build/live-root/` | `rootfs` + `livecd/` before squashfs. |
| `build/iso-staging/` | the ISO tree handed to `grub-mkrescue`. |
| `build/webos-1.034-Ashen-amd64.iso` | the deliverable. |

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the pieces fit together and
[`RELEASE.md`](RELEASE.md) for the release checklist.

---

## 10. Ebuild repositories

WebOS builds against five repositories. Their `repos.conf` files live in
`config/repos.conf/` and are installed into the chroot verbatim.

| Repo | Location | Source | Priority | Provides |
| --- | --- | --- | --- | --- |
| `gentoo` | `/var/db/repos/gentoo` | rsync snapshot (unpacked by `fetch`/`bootstrap`) | `-1000` | the base system |
| `webos` | `/usr/local/portage/webos` | this tree's `overlay/` | `100` | our kernel, sets, theme, installer |
| `guru` | `/var/db/repos/guru` | <https://github.com/gentoo-mirror/guru.git> | `-2000` | `mangohud`, `goverlay`, `cliphist`, `nwg-look`, `corectrl`, `lact`, `nerdfonts`, `swayimg`, … |
| `hyproverlay` | `/var/db/repos/hyproverlay` | <https://codeberg.org/hyproverlay/hyproverlay.git> | `-2000` | `hyprland` and the `hypr*` tooling |
| `steam-overlay` | `/var/db/repos/steam-overlay` | <https://github.com/anyc/steam-overlay.git> | `-2000` | `steam-launcher` |

**Priority** is "higher wins". `webos` overrides everything; `gentoo` wins over
the third-party overlays, so those are only ever consulted for packages the base
system does not carry itself.

The third-party overlays are cloned into `build/cache/repos/` by `fetch` and
copied into the chroot by `bootstrap`. They keep their `.git`, so on the
installed system `emerge --sync` (or `emaint sync -a`) updates them. They are
shipped in the `rootfs` under `/var/db/repos`, so installed packages from those
overlays stay resolvable without a first-use re-sync.
