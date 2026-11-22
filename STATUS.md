# WebOS build status

_Last update: 2026-11-22 — v1.02 (Ashen): active maintenance; compact music dropdown with spinning vinyl, live volume drag, Spotify-guarded hidden spectrum and honest binary-first updater controls._

## Status: v1.02 — active maintenance; theme r49 committed

- Version 1.02; target ISO `webos-1.02-Ashen-amd64.iso`.
- Theme r49 is committed on `main`. Run `bash scripts/50-check.sh` before the
  next rootfs/ISO rebuild.
- Hyprland 0.57 reads `~/.config/hypr/hyprland.lua`; the rice is Lua
  (`hyprland.lua` + `webos-colors.lua`), and `hyprland.conf` is gone.
- SDDM is the shipped greeter and offers exactly the session chosen in the
  installer; that session is also seeded in `/var/lib/sddm/state.conf`.
- Plasma lives in the opt-in `@plasma` set. Non-Plasma profiles unmerge it and
  remove its session entry, so the greeter never shows a desktop you did not
  choose.
- Keys: `Super+Q` terminal (kitty), `Super+Shift+Return` foot, `Super+C` close
  window, `Super+D` / `Super+R` webos-menu, `Super+M` music dropdown,
  `Super+Shift+S` screenshot snip, `Super+Escape` hyprlock,
  `Super+scroll` workspaces 1-5, `Super+Shift+Escape` exit Hyprland.
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
  count, and captures helper output into the progress/log panel so nothing
  paints over the TUI.
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

### Historical v1.01 ISO artifact (superseded by v1.02)

- Published v1.01 ISO: `webos-1.01-Ashen-amd64.iso`, sha256
  `e8351089a4aaefe0d1d4afa11f2d939f94d54bc5979fabfa0355bf77157f3d90`.
- Older verification lines below are kept for provenance.
- Pre-release v1.01 ISO: `build/webos-1.01-Ashen-amd64.iso` (3.7G), verified sha256 `4e63e90c33b050d7…`
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

### Historical verification snapshot (earlier v8 build)

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
- USB copy to Ventoy `/dev/sdc1`: checksum-verified and unmounted; the earlier
  "in progress (watcher will notify)" note was superseded.

## Known remaining risk

- NVIDIA RTX 4060 (Ada) remains **unverified on the user's hardware**. The
  proprietary `nvidia-drivers` (open modules) is installed and shipped in the
  image, `nouveau` is blacklisted, and the installer writes the
  `nvidia.conf` (`force_drivers`) entry plus `nvidia-drm.modeset=1` as-is — do
  not remove those. Earlier GSP/DP errors on this GPU were seen under `nouveau`;
  an on-hardware Wayland check (Hyprland/Plasma) is still due.
- Limine bootloader and CachyOS-style login tweaks not implemented.
