# webos-installer

The WebOS installer: one statically-ish linked binary, a keyboard, and a
black terminal. It partitions a disk, unpacks the live system onto it, and
configures the result — including GRUB and the kernel command line.

It is deliberately small. There is no Python, no GTK, no Calamares, and no
package manager running inside the installer. Everything it needs is either
part of the live medium or a small external tool (`sgdisk`, `mkfs.*`, `mount`,
`rsync`/`tar`, `chroot`, `grub-install`).

## Building

```sh
cargo build --release          # -> target/release/webos-installer
cargo build --release --offline   # what the ebuild does, from vendor/
```

The release profile is tuned for size (`opt-level = "z"`, LTO, `panic = "abort"`,
stripped). The resulting binary is around 1 MB and has no runtime dependencies
beyond libc.

## Running

```sh
webos-installer                    # interactive wizard
webos-installer --check            # print what it can see, then exit
webos-installer -c answers.toml -y # unattended install
webos-installer -d                 # dry run: walk the wizard, write nothing
```

`--config FILE --yes` is how WebOS CI exercises installs: the wizard is
skipped, the summary is auto-confirmed, and every command is logged.

### Options

| Flag | Meaning |
| --- | --- |
| `-c`, `--config FILE` | Load answers from a TOML file (see below) and jump to the summary |
| `-y`, `--yes` | Do not ask for the final confirmation |
| `-d`, `--dry-run` | Run the whole pipeline but execute nothing |
| `-l`, `--log FILE` | Command log (default `/var/log/webos-install.log`) |
| `--check` | Print disks, firmware, and install source, then exit |
| `-h`, `--help` | Usage |
| `-V`, `--version` | Version |

### Keys

| Key | Action |
| --- | --- |
| `↑` `↓` / `k` `j` | Move the selection, or move between fields |
| `←` `→` | Cycle a value (on the options page) |
| `Tab` / `Shift-Tab` | Next / previous field |
| `Enter` | Confirm the page, or start editing the selected field |
| `Esc` | Go back a page (or cancel the current edit) |
| `Ctrl-C` | Quit without touching the disk (disabled once the install starts) |

While the install is running only scrolling is accepted. The worker owns the
disk; the UI cannot change anything until it reports `Done` or `Failed`.

## Answer file

Any field of `InstallConfig` may be set. Unknown keys are rejected, and missing
keys take their defaults. A copy of the effective configuration is written to
`/etc/webos/install.toml` inside the new system, so a machine can be rebuilt
from its own record:

```sh
webos-installer --config /etc/webos/install.toml --yes
```

```toml
disk = "/dev/nvme0n1"
firmware = "uefi"          # "uefi" | "bios"
filesystem = "btrfs"       # "btrfs" | "ext4" | "xfs"
encryption = "luks"        # "none" | "luks"
swap = "zram"              # "zram" | "partition" | "none"
luks_passphrase = "correct horse battery staple"
esp_size_mib = 512
swap_size_mib = 4096

hostname = "webos"
username = "player"
full_name = "Player One"
user_password = "hunter2"
root_password = ""

timezone = "Europe/Berlin"
locale = "en_US.UTF-8"
keymap = "us"

profile = "full"           # "full" | "minimal"
install_gaming = true
nvidia = false
enable_bluetooth = true
enable_sshd = false
enable_firewall = false
use_grub = true
```

## Design rules

1. **Nothing is written until the summary is confirmed.** The partition table is
   the first thing that changes, and it changes after a deliberate second
   `Enter` (or immediately with `--yes`).
2. **The installer never guesses a disk.** It must be selected explicitly.
3. **Every command is logged verbatim**, and the log is copied into the new
   system as `/var/log/webos-install.log`.
4. **One code path.** The interactive wizard and `--config --yes` fill the same
   `InstallConfig` and run the same `install::run`.

## Layout of the source

| File | Responsibility |
| --- | --- |
| `main.rs` | argument parsing, terminal setup, the event loop |
| `app.rs` | wizard state, key handling, the install worker thread |
| `ui.rs` | rendering (ratatui); pure functions of `App` |
| `theme.rs` | the Ashen palette, shared with the rice |
| `config.rs` | `InstallConfig` and its validation |
| `disk.rs` | finding disks, detecting firmware |
| `rootfs.rs` | locating the system to install |
| `install.rs` | the actual install recipe |
| `bootloader.rs` | GRUB installation and the kernel command line |
| `exec.rs` | running commands, logging, reporting to the UI |

## How it is installed

The installer is packaged as `app-admin/webos-installer`, which builds this
crate with `cargo build --release --offline` from the vendored dependencies in
`vendor/` (see `vendor.sh`) and installs the binary as
`/usr/bin/webos-installer`. It is on the live medium and in the installed
system.
