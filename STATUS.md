# WebOS build status

_Last update: 2026-11-13 16:25 UTC — USB copy verified_

## Status: COMPLETE — verified and published

End-to-end install test passed on the final ISO (`INSTALL_RC=0`).

## Verification

- ISO sha256 matches `.sha256`: `af463b757793abfc…`
- QEMU UEFI install on a blank 30 GiB disk: installer `INSTALL_RC=0`
- ESP (label `WEBOS_ESP`) contains `EFI/WebOS/grubx64.efi` and `EFI/BOOT/BOOTX64.EFI`
- `/boot`: `vmlinuz-6.12.0-webos` + `initramfs-6.12.0-webos.img`
- `/etc/sudoers.d/10-sanus` written (sudoers.d abort fixed)
- `/etc/conf.d/display-manager`: `DISPLAYMANAGER="sddm"`
- Runlevel `default`: `display-manager` enabled (SDDM), plus NetworkManager, dbus, elogind, syslog-ng
- Hostname `webos-test`, kernel `6.12.0-webos` in target
- Bootloader + initramfs succeeded (chroot `/dev`, `/proc`, `/sys`, `/run` kept mounted — bug fixed)
- Live ISO: squashfs full extract clean (577,159 files), `::gentoo` repo (161,101 entries),
  WebOS os-release, tty1–6 root autologin, Hyprland (`sanus.desktop`) + Plasma sessions,
  0 stale `sanusos` names

## Release

- GitHub: https://github.com/4NT1K/WebOS/releases/tag/v1.0
- Assets: `webos-1.0-Ashen-amd64.iso.part-00` (1,992,294,400) +
  `part-01` (1,957,306,368) = 3,949,600,768 bytes (matches ISO), plus `SHA256SUMS.txt`, `README.txt`

## ISO

- Path: `build/webos-1.0-Ashen-amd64.iso`
- Size: 3.7G
- sha256: `af463b757793abfce184a0b2…`

## USB

- Copied to Ventoy USB (`/dev/sdc1`) and sha256 verified against the ISO: `af463b757793abfc…`
- USB unmounted cleanly; ready to boot

## Next step for the user

Copy the ISO to the Ventoy USB stick (or `cat` the two release parts back together first).
