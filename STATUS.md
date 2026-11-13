# WebOS build status

_Last update: 2026-11-13 07:50 UTC — auto-refreshed every 5 minutes_

## Current phase

**Uploading release assets to GitHub**

- Splitting + uploading ISO parts (2 GiB asset limit): /tmp/opencode/webos-release/webos-1.0-Ashen-amd64.iso.part-00 1.9G,/tmp/opencode/webos-release/webos-1.0-Ashen-amd64.iso.part-01 1.9G,.
- Release: https://github.com/4NT1K/WebOS/releases/tag/v1.0

## ISO

- Path: `build/webos-1.0-Ashen-amd64.iso`
- Size: 3.7G
- sha256: `af463b757793abfc…`

## Already verified

- Fixed installer rebuilt and copied into the shipped rootfs
- ISO rebuilt with kernel 6.12.0-webos and the fixed installer
- Live ISO verified earlier: squashfs extract clean (577,159 files), ::gentoo repo (161,101 entries), WebOS os-release, tty1–6 autologin, SDDM + Hyprland/Plasma sessions, 0 stale `sanusos` names
- Source committed and pushed (`71c61cf`)
