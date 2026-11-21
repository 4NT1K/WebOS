# WebOS roadmap

Planned work beyond **v1.02 (Ashen)**. Nothing here is a promise of a date; items
move up when they unblock gaming or the install experience.

## Next release (priority)

- **Multilib image + native Steam.** Rebuild the toolchain with `abi_x86_32` so
  `games-util/steam-launcher`, Wine/Proton 32-bit prefixes, winetricks,
  protontricks and goverlay can be preinstalled as binary packages. This is the
  main blocker for shipping Steam in the installer.
- ~~**Flatpak preinstalled** with Flathub enabled~~ — **shipped in v1.01, unchanged in v1.02**:
  Flatpak + Flathub are really installed, so Steam, Bottles, Heroic and other
  apps install without a source build. `com.valvesoftware.Steam` is the fallback
  for the current 64-bit-only image.
- **Installer:** Steam toggle becomes real once multilib lands; keep the current
  “recorded only” behaviour until then.
- ~~**`WEBOS-INFO.txt` refresh**~~ — **done for v1.02**: the system brief now
  documents the refined palette, ten-module fastfetch card, dropdown panels and
  current keybinds. Keep refreshing it whenever packages, keys or paths change.

## Desktop / rice

- Theme switcher and accent-colour picker (`webos-rice --theme`, `--accent`).
- Graphical wallpaper picker in the WebOS Settings entry.
- A single WebOS Settings hub (display, audio, network, theme, gaming) built on
  KDE System Settings modules.
- Hyprland: per-monitor workspaces, gesture config, optional rounded corners
  toggle, HDR/VRR helpers.
- Plasma: Plasma Login Manager (PLM) instead of SDDM once it is stable on OpenRC.

## Gaming

- Steam preinstall + first-run Proton setup (see multilib above).
- Gamescope session polish: HDR, VRR, per-game launch profiles.
- Handheld support: ROG Ally / Legion Go / Steam Deck controller mapping and
  TDP control in the WebOS Settings hub.
- Optional MangoHud/GameMode toggles per game, plus a benchmark helper.
- Better NVIDIA handling: runtime driver selection, hybrid graphics switching.

## Install / system

- Optional LUKS full-disk encryption and TPM unlock in the TUI installer.
- Btrfs + snapper rollback profile, and a “reset to stock” option.
- Secure Boot signing (shim + MOK) for the ISO and installed system.
- Smaller ISO: split optional apps into a post-install download set.
- ARM64 image (Asahi/ROCK 5 class hardware) once the desktop stack is verified.

## Updates / infra

- ~~`webos-update` wrapper~~ — **shipped in v1.01, improved in v1.02**:
  `sudo webos-update` (sync, `@world`, depclean, config merges, Flatpak, rice,
  reboot check, plus `--fast`, `--strict-use`, `--buildpkg` and `--no-compile`).
- Signed release artefacts and reproducible ISO builds in CI.
- Automated QEMU install tests (serial console) on every release.
- Ventoy persistence profile and a recovery/rescue entry on the ISO.

## Docs

- Per-app setup guides (Discord, Spotify, OpenCode, Lutris/Heroic, Flatpak Steam).
- Troubleshooting matrix for common GPU/audio/Wi-Fi issues.
- Contribution guide for the overlay and rice.
