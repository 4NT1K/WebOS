# WebOS build status

_Last update: 2026-11-14 01:10 UTC — v7 verified, copied to USB_

## Status: VERIFIED (not published)

- ISO: `build/webos-1.0-Ashen-amd64.iso` (3.7G), sha256 `4e63e90c33b050d7…`
- v7 fixes:
  - install copy preserves setuid/setgid (`rsync -rlptDHAX --chown=0:0`); no recursive `chown -R`
  - `scripts/40-iso.sh` normalizes ownership without stripping setuid bits
  - user creation robust: groups ensured (`wheel,audio,video,render,input,plugdev,gamemode,usb,kvm,seat`)
  - guaranteed 32-char `/etc/machine-id` + `/var/lib/dbus/machine-id` (symlink verified)
  - `sanus-session` tolerates missing `XDG_RUNTIME_DIR`
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
