# WebOS build status

_Last update: 2026-11-20 — v1.01 (Ashen): first maintenance rebuild; refined greyscale, dropdown panels, menu/music keys, sessions, zram and updater fixes._

## Status: v1.01 ready to build

- Version 1.01; ISO `webos-1.01-Ashen-amd64.iso`.
- Hyprland 0.57 reads `~/.config/hypr/hyprland.lua`; the rice is Lua
  (`hyprland.lua` + `webos-colors.lua`), and `hyprland.conf` is gone.
- SDDM is the shipped greeter and offers exactly the session chosen in the
  installer; that session is also seeded in `/var/lib/sddm/state.conf`.
- Plasma lives in the opt-in `@plasma` set. Non-Plasma profiles unmerge it and
  remove its session entry, so the greeter never shows a desktop you did not
  choose.
- Keys: `Super+Q` terminal (kitty), `Super+Shift+Return` foot, `Super+C` close
  window, `Super+D` / `Super+R` webos-menu, `Super+M` music dropdown,
  `Super+Shift+S` screenshot snip, `Super+Shift+Escape` exit Hyprland.
- zram swap starts at boot with priority 100 (zstd with lzo-rle fallback), and
  `ananicy-cpp.initd` is enabled and started by the installer.
- `webos-update` now updates the kernel and regenerates GRUB, not just @world.
- Kitty transparency is restored (kitty owns alpha 0.82; no stacked compositor
  opacity), uses `auto` bold/italic faces and a greyscale ANSI ramp, and the
  fastfetch card uses chafa symbol art in a soft-white framed box.
- The mono bar hides the LAN IPv4 address and battery percentage. Its right
  cluster is ▧ waypaper, clock, tray, ▾ performance and ⏻ power; the cpu,
  memory and pulseaudio pills (and their aliases) are gone. `webos-music` and
  `webos-stats` provide the music and performance dropdowns.
- The installer progress panel lists finished stages, shows the real stage
  count, and runs helpers with null stdio so nothing paints over the TUI.
- All `sanus-*` names renamed to `webos-*` (packages, binaries, paths, overlay).
- Installer toggles: Firefox (firefox-bin), Discord, OpenCode, Spotify — prebuilt.
- Steam/Wine/winetricks/protontricks/goverlay dropped: image is 64-bit only
  (`ABI_X86="64"`); Steam needs multilib. Kernel has IA32 emulation, so Flatpak
  Steam works. Multilib rebuild planned for a future release.
- Fastfetch card: 16x16 chafa symbol logo (webos.txt fallback) + display,
  uptime, cpu, gpu, terminal, memory, disk, packages, shell, datetime — ten
  modules, framed in a soft-white box with greyscale output/separators.
- `/usr/share/webos/WEBOS-INFO.txt` ships a full system brief for OpenCode.
- Reused chroot: Portage config refreshed, profile symlink repointed, legacy
  `sanus-*` packages removed.

### v8 (verified locally earlier)

- ISO: `build/webos-1.01-Ashen-amd64.iso` (4.0G), historical verification sha256 `1db24ab5…`
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

- ISO: `build/webos-1.01-Ashen-amd64.iso` (3.7G), historical verification sha256 `4e63e90c33b050d7…`
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
