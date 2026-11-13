# WebOS build status

_Last update: 2026-11-13 07:44 UTC — auto-refreshed every 5 minutes_

## Current phase

**E2E install test running (QEMU TCG, no KVM)**

- Current step: **Unmounting** — rsync 11,347,373,799B  99%   12.2MB/s    0:15:33
- QEMU elapsed: 0s. Post-install checks: ESP `EFI/WebOS/grubx64.efi`, sudoers.d, `DISPLAYMANAGER="sddm"`, runlevel `display-manager`, hostname `webos-test`, kernel `6.12.0-webos`, copied install log.

## ISO

- Path: `build/webos-1.0-Ashen-amd64.iso`
- Size: 3.7G
- sha256: `af463b757793abfc…`

## Already verified

- Fixed installer rebuilt and copied into the shipped rootfs
- ISO rebuilt with kernel 6.12.0-webos and the fixed installer
- Live ISO verified earlier: squashfs extract clean (577,159 files), ::gentoo repo (161,101 entries), WebOS os-release, tty1–6 autologin, SDDM + Hyprland/Plasma sessions, 0 stale `sanusos` names
- Source committed and pushed (`71c61cf`)
