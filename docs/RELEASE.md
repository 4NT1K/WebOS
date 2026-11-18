# Releasing WebOS

This is the checklist for cutting a WebOS release. A release is a signed,
checksummed ISO built from a frozen tree, plus the notes that describe it.

---

## 1. Versioning

The single source of truth is `branding/version`:

```sh
WEBOS_NAME="WebOS"
WEBOS_CODENAME="Ashen"
WEBOS_VERSION="1.0"
WEBOS_VERSION_FULL="1.0-Ashen"
WEBOS_ID="webos"
WEBOS_HOME="https://github.com/4NT1K/WebOS"
WEBOS_KERNEL_SERIES="6.12"
```

* `WEBOS_VERSION` — the marketing version (`1.0`). Used in the ISO label.
* `WEBOS_VERSION_FULL` — `WEBOS_VERSION` + codename (`1.0-Ashen`). Used in
  `os-release`, the ISO filename, and the live GRUB menu.
* `WEBOS_CODENAME` — the release name (`Ashen`).

The ISO filename is derived, not written down anywhere:

```
build/${WEBOS_ID}-${WEBOS_VERSION_FULL}-${WEBOS_ARCH}.iso
→ build/webos-1.0-Ashen-amd64.iso
```

**The installer has its own version.** `installer/Cargo.toml`'s `version`
(`1.0.0`) is what names the installer tarball
(`webos-installer-1.0.0.tar.gz`) and the ebuild. Bump it independently of
`branding/version` when the installer changes.

### Codename policy

Codenames are single words, alphabetical-ish, and evocative of the aesthetic
(Ashen). A codename is assigned when a release line opens, not per point
release: `1.0.x` all ship as Ashen.

---

## 2. Before you build

- [ ] `branding/version` has the intended `WEBOS_VERSION` /
      `WEBOS_VERSION_FULL` / `WEBOS_CODENAME`.
- [ ] `installer/Cargo.toml` version is bumped if the installer changed, and
      the matching `webos-installer-<PV>.ebuild` exists.
- [ ] Kernel: `branding/version`'s `WEBOS_KERNEL_SERIES` matches the ebuilds
      and `kernel/patchset.conf`.
- [ ] Every overlay package has a `Manifest` and a `metadata.xml`.
- [ ] `config/repos.conf/` lists every repository the tree needs
      (`gentoo`, `webos`, and the third-party overlays), each with the intended
      priority.
- [ ] Every atom resolved from `guru` / `hyproverlay` / `steam-overlay` still
      exists in that overlay at the pinned commit you build against.
      and `sys-apps/pacman` is in the world and in `webos-base`'s RDEPEND.
- [ ] `docs/` reflects reality (BUILD.md, ARCHITECTURE.md, this file).
- [ ] `README.md` reflects reality (tree layout, build commands).
- [ ] `CHANGELOG` / release notes drafted (see §6).

---

## 3. Verify the tree

Run the integrity checks. They are cheap and catch the boring mistakes:

```bash
./scripts/50-check.sh
```

It checks:

1. every package directory has a `Manifest` and `metadata.xml`;
2. `branding/os-release`'s `ID` matches `branding/version`;
3. `kernel/patchset.conf` has at least one pinned source;
4. `installer/Cargo.toml` parses (`cargo metadata`);
5. every `scripts/*.sh` (and `build.sh`) passes `bash -n`;
6. the core rice files exist.

Then, where the tools are available:

```bash
make lint                       # shellcheck + cargo clippy + pkgcheck
cargo clippy --manifest-path installer/Cargo.toml --all-targets -- -D warnings
kernel/fetch-patches.sh --verify    # catch upstream patch rewrites
```

`make check` degrades gracefully when `shellcheck` / `pkgcheck` are not
installed; a release should be made where they *are*.

---

## 4. Build the release

From a clean tree (or at least a clean `build/rootfs` and `build/iso-staging`):

```bash
sudo ./build.sh clean
sudo ./build.sh all
```

`build.sh all` is `fetch → bootstrap → kernel → rootfs → iso`. It prints the
ISO path and its SHA-256 when it finishes.

Confirm the kernel that went in:

```bash
cat build/.kernel-release        # e.g. 6.12.0-webos
```

---

## 5. Smoke test the ISO

Never publish an ISO you have not booted.

```bash
qemu-system-x86_64 -m 4096 -enable-kvm -cdrom build/webos-1.0-Ashen-amd64.iso -boot d
```

- [ ] GRUB menu appears with the three WebOS entries and the "first hard
      disk" entry.
- [ ] The live medium boots to the WebOS live menu on tty1.
- [ ] `webos-installer --check` finds the firmware, the install source and the
      candidate disks.
- [ ] A **BIOS** install completes and reboots into Hyprland.
- [ ] A **UEFI** install completes and reboots into Hyprland.
- [ ] A **btrfs + LUKS2** install completes, prompts for the passphrase, and
      reboots into Hyprland.
- [ ] The installed system does **not** autologin and does **not** show the
      live menu (`/etc/webos-live` is gone, `/etc/inittab` is restored).
- [ ] `uname -r` reports `…-webos`.
- [ ] `cat /etc/os-release` reports `ID=webos`, `VERSION="1.0 (Ashen)"`.
- [ ] `webos-rice --doctor` is clean; the desktop is black/transparent.
- [ ] A Steam game launches (gamescope/MangoHud as configured).
- [ ] `/etc/webos/install.toml` exists and re-running
      `webos-installer --config /etc/webos/install.toml --yes` is valid.

Record the firmware(s) and GPU(s) you tested. An untested GPU is an untested
release.

---

## 6. Release notes

Write notes that say what changed, not what the ISO contains. Include:

* the version, codename, and the kernel series/release;
* the base: Gentoo snapshot date and profile;
* kernel patches in this release (from `kernel/patchset.conf`);
* new/changed packages (the meta sets and the rice are the usual suspects);
* installer changes (flags, defaults, answer-file keys);
* known issues and the hardware you validated against.

A short template:

```markdown
# WebOS 1.0 "Ashen"

Kernel: 6.12.0-webos (BORE, fsync, ntsync, BBRv3, AMD P-State EPP, MGLRU)
Base:   Gentoo <snapshot date>, profile webos:default/linux/amd64/webos
Desktop: Hyprland (Wayland), SDDM
Installer: webos-installer 1.0.0

## Highlights
- …

## Changes
- …

## Known issues
- …

## Validated hardware
- UEFI, AMD (RADV) …
- BIOS, AMD (RADV) …
```

---

## 7. Checksums and signing

`40-iso.sh` already writes `build/webos-1.0-Ashen-amd64.iso.sha256`. Verify it,
then produce stronger artefacts:

```bash
cd build
sha256sum -c webos-1.0-Ashen-amd64.iso.sha256

# BLAKE2b alongside SHA-256
b2sum webos-1.0-Ashen-amd64.iso > webos-1.0-Ashen-amd64.iso.b2

# Detached, ASCII-armoured signature
gpg --armor --detach-sign webos-1.0-Ashen-amd64.iso
```

Publish, together:

```
webos-1.0-Ashen-amd64.iso
webos-1.0-Ashen-amd64.iso.sha256
webos-1.0-Ashen-amd64.iso.b2
webos-1.0-Ashen-amd64.iso.asc
RELEASE-NOTES-1.0-Ashen.md
```

Announce the **signing key fingerprint** in the release notes and on the
website, so users can verify the `.asc` out of band. Do not rely on the
checksum file alone: it travels next to the thing it checks.

---

## 8. Reproducibility notes

WebOS is not bit-for-bit reproducible yet, and the release notes should say
so honestly. What *is* deterministic:

* the kernel patch series — `kernel/fetch-patches.sh --verify` fails on any
  upstream rewrite;
* the installer — built `--locked --offline` from vendored crates;
* the rice — owned by `webos-theme`, re-applied idempotently.

What is not, and why:

* the Gentoo **snapshot** and **stage3** are date-stamped downloads;
* the third-party overlays (`guru`, `hyproverlay`, `steam-overlay`) are
  shallow-cloned at their moving HEAD, so the exact ebuild that satisfies an
  overlay atom can change between builds;
  packages overlay at moving HEAD, and pacman consumes Arch's moving repos.
* `make.conf` targets `-march=x86-64-v3`, but a native rebuild differs;
* `grub-mkrescue`, `mksquashfs` and `dracut` embed timestamps.

The build records the kernel release and the ISO gets a `.sha256`, which is
enough to verify a download, not to reproduce it.

---

## 9. Tag and publish

The tree is not a git repository in this sandbox; on the real project:

```bash
git tag -s v1.0-Ashen -m "WebOS 1.0 (Ashen)"
git push origin v1.0-Ashen
```

Then upload the artefacts from §7 to the release page, and update:

* the website's download page and signing-key page;
* the mirror list, if you run mirrors;
* `README.md` / `docs/` if anything user-facing changed.

---

## 10. Post-release

* Open the next codename and bump `branding/version` on `main`.
* Re-pin the kernel patchset if upstream moved (`kernel/fetch-patches.sh`).
* Refresh the Gentoo snapshot for the next `fetch`.
* File anything the smoke test only *worked around* as a bug, not a note.
