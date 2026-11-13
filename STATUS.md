# WebOS build status

_Last update: 2026-11-13 07:45 UTC — auto-refreshed every 5 minutes_

## Current phase

**E2E install test running (QEMU TCG, no KVM)**

- Install finished: **INSTALL_RC=0 (success)** — bootloader installed, initramfs built, install recorded. Verifying installed system now.
- QEMU elapsed: 0s. Post-install checks: ESP `EFI/WebOS/grubx64.efi`, sudoers.d, `DISPLAYMANAGER="sddm"`, runlevel `display-manager`, hostname `webos-test`, kernel `6.12.0-webos`.

## ISO

- Path: `build/webos-1.0-Ashen-amd64.iso`
- Size: 3.7G
- sha256: `af463b757793abfc…`

## Already verified

- Fixed installer rebuilt and copied into the shipped rootfs
- ISO rebuilt with kernel 6.12.0-webos and the fixed installer
- Live ISO verified earlier: squashfs extract clean (577,159 files), ::gentoo repo (161,101 entries), WebOS os-release, tty1–6 autologin, SDDM + Hyprland/Plasma sessions, 0 stale `sanusos` names
- Source committed and pushed (`71c61cf`)
