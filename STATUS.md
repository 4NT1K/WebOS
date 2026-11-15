# WebOS build status

_Last update: 2026-11-14 17:08 UTC — v8 E2E+target checks passed, USB copy in progress_

## Status: v8 VERIFIED LOCALLY (not published, not on USB yet)

- ISO: `build/webos-1.0-Ashen-amd64.iso` (4.0G), sha256 `1db24ab5…`
- v8:
  - ships `x11-drivers/nvidia-drivers-595.112.07` (open modules)
  - kernel build tree prepared in stage 30; `nouveau` blacklisted
  - installer writes `nvidia.conf` (force_drivers) + `nvidia-drm.modeset=1` (no fake dracut module)
  - initramfs includes nvidia modules/firmware (`lsinitrd`: 12 nvidia entries)
  - squashfs < 4GiB (zstd 19); serial console `ttyS0` autologin on live
  - fixed live `local.d` (`#!/bin/sh`)
- E2E (QEMU, serial): `INSTALL_RC=0`, `QEMU_RC=0`
- Target checks: setuid preserved, root ownership, 32-char machine-id, nvidia modules+blacklist+dracut+grub cmdline, user groups OK
- USB copy to Ventoy `/dev/sdc1`: in progress (watcher will notify)

### v7 (verified, copied to USB earlier)

- ISO: `build/webos-1.0-Ashen-amd64.iso` (3.7G), sha256 `4e63e90c33b050d7…`
- v7 fixes:
  - install copy preserves setuid/setgid (`rsync -rlptDHAX --chown=0:0`); no recursive `chown -R`
  - `scripts/40-iso.sh` normalizes ownership without stripping setuid bits
  - user creation robust: groups ensured (`wheel,audio,video,render,input,plugdev,gamemode,usb,kvm,seat`)
  - guaranteed 32-char `/etc/machine-id` + `/var/lib/dbus/machine-id` (symlink verified)
  - `webos-session` tolerates missing `XDG_RUNTIME_DIR`
  - removed forced `radeonsi` VA-API env from Hyprland rice (NVIDIA-safe defaults)
- E2E install: `INSTALL_RC=0`
- Installed target checks (verified in QEMU image):
  - `sudo`, `su`, `pkexec`, `polkit-agent-helper-1` are `4755` (setuid restored)
  - `/`, `/etc`, `/usr` root:root
  - 32-char machine-id; dbus machine-id symlink resolves to same id
  - user groups include `wheel,audio,video,render,input,plugdev,gamemode,usb,kvm,seat`
  - ESP contains `EFI/WebOS/grubx64.efi` and `EFI/BOOT/BOOTX64.EFI`
  - `display-manager` = `sddm`; kernel `6.12.0-webos` + initramfs present
- Ventoy USB updated and checksum-verified, unmounted
- GitHub release not updated (awaiting approval)

## Known remaining risk

- NVIDIA RTX 4060 (Ada) on `nouveau` showed GSP/DP errors on the user's hardware.
  Wayland sessions (Hyprland/Plasma) may still fail on that GPU until proprietary
  `nvidia-drivers`/`nvidia-open` setup is added. Kernel cmdline currently carries
  nvidia-only params while nouveau is in use.
- Limine bootloader and CachyOS-style login tweaks not implemented.
