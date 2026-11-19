//! The part that actually touches the disk.
//!
//! Everything here is driven by [`InstallConfig`] and reports through
//! [`Runner`]. It is deliberately linear and readable: if an install goes
//! wrong, the log should read like a recipe, not like a state machine.

use std::path::Path;

use anyhow::{bail, Context, Result};

use crate::bootloader;
use crate::config::{Encryption, Filesystem, InstallConfig, Profile, SwapChoice};
use crate::disk;
use crate::exec::Runner;
use crate::rootfs::{self, Source};

/// Where the new system is assembled before it is configured.
pub const TARGET: &str = "/mnt/webos";

/// The name the LUKS container is opened as.
pub(crate) const CRYPT_NAME: &str = "webos_crypt";

#[derive(Debug, Default, Clone)]
pub struct Partitions {
    pub esp: Option<String>,
    pub bios_boot: Option<String>,
    pub swap: Option<String>,
    pub root_raw: String,
    /// Where root actually lives: the LUKS mapper if encrypted, else root_raw.
    pub root: String,
}

fn strs(v: &[String]) -> Vec<&str> {
    v.iter().map(String::as_str).collect()
}

/// The whole install. Returns Ok only if the target is bootable.
pub fn run(cfg: &InstallConfig, r: &Runner) -> Result<()> {
    let result = run_inner(cfg, r);
    if result.is_err() {
        // The live overlay is thrown away at reboot, so a failed install must
        // leave its log somewhere the user can actually find it.
        preserve_log(r);
    }
    result
}

/// Copy the command log onto the target (and the live root) after a failure.
fn preserve_log(r: &Runner) {
    for dst in [
        format!("{TARGET}/var/log/webos-install.log"),
        format!("{TARGET}/root/webos-install.log"),
    ] {
        if let Some(dir) = Path::new(&dst).parent() {
            let _ = std::fs::create_dir_all(dir);
        }
        let _ = std::fs::copy(r.log_path(), &dst);
    }
}

fn run_inner(cfg: &InstallConfig, r: &Runner) -> Result<()> {
    r.phase("Preparing");
    let src = match rootfs::locate() {
        Ok(src) => src,
        Err(_) => {
            // The live squashfs may not have been auto-mounted; mount it and
            // look again before giving up.
            rootfs::ensure_mounted("/run/webos/rootfs")
                .context("locating the install source")?;
            rootfs::locate().context("locating the install source")?
        }
    };
    r.info(format!("install source: {src}"));

    let disks = disk::enumerate();
    let target = disks
        .iter()
        .find(|d| d.path == cfg.disk)
        .with_context(|| format!("{} is no longer present", cfg.disk))?;
    disk::verify_target(target)?;
    r.info(format!(
        "target: {} — {} {} ({})",
        target.path,
        target.model,
        target.human_size(),
        target.kind()
    ));

    let missing = crate::exec::missing_tools(&[
        "sgdisk", "mkswap", "mount", "blkid", "rsync", "tar", "chroot", "grub-install",
    ]);
    if !missing.is_empty() {
        bail!("missing required tools: {}", missing.join(", "));
    }

    teardown_target(r);

    // ── 1. partition ─────────────────────────────────────────────────────
    let parts = partition(r, cfg)?;
    r.progress(0.08);

    // ── 2. encrypt ───────────────────────────────────────────────────────
    let parts = encrypt(r, cfg, parts)?;
    r.progress(0.15);

    // ── 3. filesystems ───────────────────────────────────────────────────
    make_filesystems(r, cfg, &parts)?;
    mount_target(r, cfg, &parts)?;
    r.progress(0.24);

    // ── 4. copy the system ───────────────────────────────────────────────
    copy_rootfs(r, &src)?;
    fix_root_ownership(r)?;
    r.progress(0.62);

    // ── 5. fstab, crypttab ───────────────────────────────────────────────
    write_fstab(r, cfg, &parts)?;
    r.progress(0.66);

    // ── 6-8. configure, initramfs, bootloader, record ────────────────────
    // /dev, /proc, /sys and /run must stay mounted for every chroot step;
    // grub-install and dracut both need them.
    enter_chroot(r)?;
    let result = (|| {
        configure_in_chroot(r, cfg, &parts)?;
        r.progress(0.88);

        build_initramfs(r, cfg, &parts)?;
        bootloader::install(r, cfg, &parts)?;
        r.progress(0.97);

        record_install(r, cfg, &parts)
    })();
    let _ = leave_chroot(r);
    result?;

    r.phase("Unmounting");
    teardown_target(r);
    r.progress(1.0);
    Ok(())
}

// ────────────────────────────────────────────────────────────── partitioning ─

fn partition(r: &Runner, cfg: &InstallConfig) -> Result<Partitions> {
    r.phase("Partitioning");
    r.info(format!("wiping the partition table on {}", cfg.disk));
    r.run("sgdisk", &["--zap-all", &cfg.disk])?;

    let mut p = Partitions::default();
    let mut idx: u32 = 1;

    match cfg.firmware {
        crate::config::Firmware::Uefi => {
            let dev = disk::partition_path(&cfg.disk, idx);
            let a = vec![
                "-n".into(),
                format!("{idx}:0:+{}M", cfg.esp_size_mib),
                "-t".into(),
                format!("{idx}:ef00"),
                "-c".into(),
                format!("{idx}:WEBOS_ESP"),
                cfg.disk.clone(),
            ];
            r.run("sgdisk", &strs(&a))?;
            p.esp = Some(dev);
            idx += 1;
        }
        crate::config::Firmware::Bios => {
            let dev = disk::partition_path(&cfg.disk, idx);
            let a = vec![
                "-n".into(),
                format!("{idx}:0:+2M"),
                "-t".into(),
                format!("{idx}:ef02"),
                "-c".into(),
                format!("{idx}:WEBOS_BIOS"),
                cfg.disk.clone(),
            ];
            r.run("sgdisk", &strs(&a))?;
            p.bios_boot = Some(dev);
            idx += 1;
        }
    }

    if cfg.swap == SwapChoice::Partition {
        let dev = disk::partition_path(&cfg.disk, idx);
        let a = vec![
            "-n".into(),
            format!("{idx}:0:+{}M", cfg.swap_size_mib),
            "-t".into(),
            format!("{idx}:8200"),
            "-c".into(),
            format!("{idx}:WEBOS_SWAP"),
            cfg.disk.clone(),
        ];
        r.run("sgdisk", &strs(&a))?;
        p.swap = Some(dev);
        idx += 1;
    }

    let root = disk::partition_path(&cfg.disk, idx);
    let a = vec![
        "-n".into(),
        format!("{idx}:0:0"),
        "-t".into(),
        format!("{idx}:8300"),
        "-c".into(),
        format!("{idx}:WEBOS_ROOT"),
        cfg.disk.clone(),
    ];
    r.run("sgdisk", &strs(&a))?;
    p.root_raw = root;

    r.run("sgdisk", &["--print", &cfg.disk])?;
    disk::settle();

    if !Path::new(&p.root_raw).exists() {
        bail!(
            "{} did not appear after partitioning — the kernel may not have \
             re-read the table",
            p.root_raw
        );
    }
    Ok(p)
}

// ──────────────────────────────────────────────────────────────── encryption ─

fn encrypt(r: &Runner, cfg: &InstallConfig, mut p: Partitions) -> Result<Partitions> {
    if cfg.encryption != Encryption::Luks {
        p.root = p.root_raw.clone();
        return Ok(p);
    }

    r.phase("Encrypting");
    r.info("formatting the LUKS2 container (argon2id)");

    let a = vec![
        "--batch-mode".to_string(),
        "--type".into(),
        "luks2".into(),
        "--pbkdf".into(),
        "argon2id".into(),
        "--cipher".into(),
        "aes-xts-plain64".into(),
        "--key-size".into(),
        "512".into(),
        "--label".into(),
        "WEBOS_CRYPT".into(),
        p.root_raw.clone(),
    ];
    r.run_stdin("cryptsetup", &strs(&a), &cfg.luks_passphrase)?;

    r.run("cryptsetup", &["open", &p.root_raw, CRYPT_NAME])?;
    p.root = format!("/dev/mapper/{CRYPT_NAME}");

    if !Path::new(&p.root).exists() {
        bail!("{} did not appear after cryptsetup open", p.root);
    }
    Ok(p)
}

// ────────────────────────────────────────────────────────────── filesystems ─

fn make_filesystems(r: &Runner, cfg: &InstallConfig, p: &Partitions) -> Result<()> {
    r.phase("Creating filesystems");

    if let Some(esp) = &p.esp {
        r.run("mkfs.vfat", &["-F", "32", "-n", "WEBOS_ESP", esp])?;
    }

    if let Some(swap) = &p.swap {
        r.run("mkswap", &["-L", "WEBOS_SWAP", swap])?;
    }

    match cfg.filesystem {
        Filesystem::Btrfs => {
            r.run("mkfs.btrfs", &["-f", "-L", "WEBOS", &p.root])?;
        }
        Filesystem::Ext4 => {
            r.run("mkfs.ext4", &["-F", "-L", "WEBOS", "-m", "1", &p.root])?;
        }
        Filesystem::Xfs => {
            r.run("mkfs.xfs", &["-f", "-L", "WEBOS", &p.root])?;
        }
    }
    Ok(())
}

fn mount_target(r: &Runner, cfg: &InstallConfig, p: &Partitions) -> Result<()> {
    r.phase("Mounting");
    std::fs::create_dir_all(TARGET).context("creating the target mountpoint")?;

    if cfg.filesystem == Filesystem::Btrfs {
        // Create the subvolume layout on a scratch mount, then remount by
        // subvolume. This is the same shape a fresh CachyOS/Arch btrfs install
        // uses, so snapper and timeshift work out of the box.
        let opts = "compress=zstd:1,noatime,ssd,space_cache=v2,discard=async";
        r.run("mount", &["-o", opts, &p.root, TARGET])?;

        for sv in ["@", "@home", "@snapshots", "@cache", "@log", "@tmp"] {
            let path = format!("{TARGET}/{sv}");
            r.run("btrfs", &["subvolume", "create", &path])?;
        }
        r.run("umount", &[TARGET])?;

        let root_opts = format!("{opts},subvol=@");
        r.run("mount", &["-o", &root_opts, &p.root, TARGET])?;

        for (sv, sub) in [
            ("@home", "home"),
            ("@snapshots", ".snapshots"),
            ("@cache", "var/cache"),
            ("@log", "var/log"),
            ("@tmp", "var/tmp"),
        ] {
            let dir = format!("{TARGET}/{sub}");
            std::fs::create_dir_all(&dir).with_context(|| format!("creating {dir}"))?;
            let opts = format!("{opts},subvol={sv}");
            r.run("mount", &["-o", &opts, &p.root, &dir])?;
        }
    } else {
        r.run("mount", &["-o", "noatime", &p.root, TARGET])?;
    }

    // ESP goes on last so the copy step cannot fill it.
    if let Some(esp) = &p.esp {
        let dir = format!("{TARGET}/boot/efi");
        std::fs::create_dir_all(&dir).with_context(|| format!("creating {dir}"))?;
        r.run("mount", &["-o", "umask=0077", esp, &dir])?;
    }

    if let Some(swap) = &p.swap {
        let _ = r.try_run("swapon", &[swap.as_str()]);
    }
    Ok(())
}

// ───────────────────────────────────────────────────────────────── copying ──

fn fix_root_ownership(r: &Runner) -> Result<()> {
    r.phase("Fixing filesystem ownership");
    // Never mass-chown the tree: `chown` clears setuid/setgid bits, and a
    // `! -gid 0` test used to catch system-owned helpers such as
    // /usr/libexec/dbus-daemon-launch-helper (root:messagebus, 4754) and
    // leave them 0110 root:root. That is what broke polkitd's D-Bus
    // activation. Only the build-generated trees are normalised here; every
    // other owner/group/mode is copied verbatim from the live medium.
    let script = r#"
set -euo pipefail
T="${1}"
chown 0:0 "$T" 2>/dev/null || true
for d in etc/portage usr/local/portage etc/skel; do
  [ -e "$T/$d" ] || continue
  chown -R 0:0 "$T/$d" 2>/dev/null || true
done
mkdir -p "$T"/{dev,proc,sys,run,tmp,home,mnt,media,var/tmp}
chown 0:0 "$T/dev" "$T/proc" "$T/sys" "$T/run" "$T/home" "$T/mnt" "$T/media" "$T/var" "$T/var/tmp" 2>/dev/null || true
chmod 1777 "$T/tmp" "$T/var/tmp"

# dbus-daemon-launch-helper must be setuid root and group messagebus, or
# polkitd cannot be activated over the system bus (no authentication agent).
H="$T/usr/libexec/dbus-daemon-launch-helper"
if [ -e "$H" ]; then
  chown 0:messagebus "$H" 2>/dev/null || chown 0:101 "$H" 2>/dev/null || true
  chmod 4754 "$H"
fi
"#;
    r.run("bash", &["-c", script, "--", TARGET])
}

fn copy_rootfs(r: &Runner, src: &Source) -> Result<()> {
    r.phase("Copying the system");

    match src {
        Source::Dir(dir) => {
            let from = format!("{}/", dir.display());
            let to = format!("{TARGET}/");
            r.info("this is the slow part; the bar tracks rsync's own progress");
            r.run_progress(
                "rsync",
                &[
                    "-rlptDHAX",
                    "--numeric-ids",
                    "--one-file-system",
                    "--info=progress2",
                    "--no-inc-recursive",
                    "--exclude=/proc/**",
                    "--exclude=/sys/**",
                    "--exclude=/dev/**",
                    "--exclude=/run/**",
                    "--exclude=/tmp/**",
                    "--exclude=/var/tmp/**",
                    "--exclude=/mnt/**",
                    "--exclude=/media/**",
                    "--exclude=/lost+found",
                    "--exclude=/etc/machine-id",
                    "--exclude=/etc/ssh/ssh_host_*",
                    &from,
                    &to,
                ],
                0.24,
                0.38,
            )?;
        }
        Source::Tarball(path) => {
            let a = vec![
                "--xattrs".to_string(),
                "--acls".into(),
                "--numeric-owner".into(),
                "-xpf".into(),
                path.display().to_string(),
                "-C".into(),
                TARGET.to_string(),
            ];
            r.run("tar", &strs(&a))?;
        }
    }

    // A machine-id is generated on first boot; an empty file is the marker
    // that tells systemd/OpenRC to do so.
    r.write_target(Path::new(TARGET), "/etc/machine-id", "")?;
    let _ = std::fs::remove_file(format!("{TARGET}/etc/ssh/ssh_host_rsa_key"));
    Ok(())
}

// ───────────────────────────────────────────────────────────────── fstab ────

fn uuid_of(r: &Runner, dev: &str) -> String {
    r.capture("blkid", &["-s", "UUID", "-o", "value", dev])
        .unwrap_or_default()
}

fn write_fstab(r: &Runner, cfg: &InstallConfig, p: &Partitions) -> Result<()> {
    r.phase("Writing /etc/fstab");
    let target = Path::new(TARGET);
    let root_uuid = uuid_of(r, &p.root_raw);
    let btrfs = cfg.filesystem == Filesystem::Btrfs;
    let opts = if btrfs {
        "compress=zstd:1,noatime,ssd,space_cache=v2,discard=async"
    } else {
        "noatime"
    };

    let mut fstab = String::from(
        "# /etc/fstab — generated by the WebOS installer.\n\
         # <device>  <mountpoint>  <type>  <options>  <dump>  <pass>\n\n",
    );

    if btrfs {
        fstab.push_str(&format!(
            "UUID={root_uuid}  /           btrfs  {opts},subvol=@           0 0\n"
        ));
        fstab.push_str(&format!(
            "UUID={root_uuid}  /home       btrfs  {opts},subvol=@home       0 0\n"
        ));
        fstab.push_str(&format!(
            "UUID={root_uuid}  /.snapshots btrfs  {opts},subvol=@snapshots  0 0\n"
        ));
        fstab.push_str(&format!(
            "UUID={root_uuid}  /var/cache  btrfs  {opts},subvol=@cache      0 0\n"
        ));
        fstab.push_str(&format!(
            "UUID={root_uuid}  /var/log    btrfs  {opts},subvol=@log        0 0\n"
        ));
        fstab.push_str(&format!(
            "UUID={root_uuid}  /var/tmp    btrfs  {opts},subvol=@tmp        0 0\n"
        ));
    } else {
        fstab.push_str(&format!(
            "UUID={root_uuid}  /  {}  {}  0 1\n",
            cfg.filesystem.label(),
            opts
        ));
    }

    if let Some(esp) = &p.esp {
        let esp_uuid = uuid_of(r, esp);
        fstab.push_str(&format!(
            "\n# UEFI system partition\nUUID={esp_uuid}  /boot/efi  vfat  umask=0077,shortname=winnt  0 2\n"
        ));
    }

    if let Some(swap) = &p.swap {
        let swap_uuid = uuid_of(r, swap);
        fstab.push_str(&format!("\n# swap\nUUID={swap_uuid}  none  swap  sw  0 0\n"));
    }

    if cfg.swap == SwapChoice::Zram {
        fstab.push_str(
            "\n# Swap is provided by zram (see /etc/local.d/webos.start).\n\
             # No on-disk swap: it costs a partition and buys nothing on an SSD.\n",
        );
    }

    fstab.push_str("\n# tmpfs, so the browser cache never touches the SSD.\n");
    fstab.push_str("tmpfs  /tmp  tmpfs  rw,nosuid,nodev,noatime,mode=1777,size=50%  0 0\n");

    r.write_target(target, "/etc/fstab", &fstab)?;

    // crypttab, if we encrypted.
    if cfg.encryption == Encryption::Luks {
        let crypttab = format!(
            "# /etc/crypttab — generated by the WebOS installer.\n\
             # <name>  <device>  <keyfile>  <options>\n\
             {CRYPT_NAME}  UUID={root_uuid}  none  luks,discard\n"
        );
        r.write_target(target, "/etc/crypttab", &crypttab)?;
    }

    Ok(())
}

// ──────────────────────────────────────────────────────────────── chroot ─────

fn enter_chroot(r: &Runner) -> Result<()> {
    for (src, dst) in [
        ("/dev", "/dev"),
        ("/proc", "/proc"),
        ("/sys", "/sys"),
        ("/run", "/run"),
    ] {
        let target = format!("{TARGET}{dst}");
        std::fs::create_dir_all(&target).ok();
        r.run("mount", &["--rbind", src, &target])?;
    }
    // /sys must not be shared, or grub-install can misbehave on EFI.
    let _ = r.try_run("mount", &["--make-rslave", &format!("{TARGET}/sys")]);
    Ok(())
}

fn leave_chroot(r: &Runner) -> Result<()> {
    for dst in ["/run", "/sys", "/proc", "/dev"] {
        let target = format!("{TARGET}{dst}");
        let _ = r.try_run("umount", &["-R", &target]);
        let _ = r.try_run("umount", &["-l", &target]);
    }
    Ok(())
}

pub(crate) fn in_chroot(r: &Runner, script: &str) -> Result<()> {
    let path = format!("{TARGET}/tmp/webos-chroot.sh");
    if !r.dry_run() {
        std::fs::create_dir_all(format!("{TARGET}/tmp")).ok();
        std::fs::write(&path, script).with_context(|| format!("writing {path}"))?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o755)).ok();
        }
    }
    r.run("chroot", &[TARGET, "/bin/bash", "/tmp/webos-chroot.sh"])?;
    let _ = std::fs::remove_file(&path);
    Ok(())
}

fn configure_in_chroot(r: &Runner, cfg: &InstallConfig, p: &Partitions) -> Result<()> {
    r.phase("Configuring the system");

    let mut s = String::new();
    s.push_str("#!/bin/bash\n");
    s.push_str("set -euo pipefail\n");
    s.push_str("export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n");
    s.push_str("export WEBOS_OS=1\n\n");

    // ── hostname ─────────────────────────────────────────────────────────
    s.push_str(&format!("echo '{}' > /etc/hostname\n", cfg.hostname));
    s.push_str(&format!(
        "cat > /etc/hosts <<'EOF'\n\
         # WebOS\n\
         127.0.0.1   localhost\n\
         ::1         localhost\n\
         127.0.1.1   {h}.localdomain {h}\n\
         EOF\n\n",
        h = cfg.hostname
    ));

    // ── locale ───────────────────────────────────────────────────────────
    s.push_str(&format!(
        "cat > /etc/locale.gen <<'EOF'\n{}\nEOF\n",
        cfg.locale
    ));
    s.push_str("locale-gen || true\n");
    s.push_str(&format!(
        "cat > /etc/env.d/02locale <<'EOF'\nLANG=\"{l}\"\nLC_ALL=\"{l}\"\nEOF\n",
        l = cfg.locale
    ));
    s.push_str("env-update || true\n\n");

    // ── machine-id ───────────────────────────────────────────────────────
    // The live image ships an empty /etc/machine-id (it is excluded from the
    // copy); dbus, sddm and systemd-tmpfiles all need a real 32-hex id.
    s.push_str(
        r#"mkdir -p /var/lib/dbus
cur=$(tr -d '\n\r' < /etc/machine-id 2>/dev/null || true)
if [[ ${#cur} -ne 32 ]]; then
    MID=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
    if [[ ${#MID} -ne 32 ]]; then MID=$(cat /proc/sys/kernel/random/uuid | tr -d '-'); fi
    printf '%s\n' "$MID" > /etc/machine-id
    printf '%s\n' "$MID" > /var/lib/dbus/machine-id
    cur=$MID
fi
[[ ${#cur} -eq 32 ]] || { echo 'failed to generate machine-id' >&2; exit 1; }
chmod 444 /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
"#,
    );

    // ── timezone, clock ──────────────────────────────────────────────────
    s.push_str(&format!(
        "ln -sf /usr/share/zoneinfo/{tz} /etc/localtime\n",
        tz = cfg.timezone
    ));
    s.push_str(&format!("echo '{}' > /etc/timezone\n", cfg.timezone));
    s.push_str("hwclock --systohc --utc || true\n\n");

    // ── console keymap (OpenRC) ──────────────────────────────────────────
    s.push_str(&format!(
        "cat > /etc/conf.d/keymaps <<'EOF'\nkeymap=\"{k}\"\nwindowkeys=\"yes\"\nEOF\n\n",
        k = cfg.keymap
    ));

    // ── users ────────────────────────────────────────────────────────────
    s.push_str(&format!(
        "for g in wheel audio video render input plugdev gamemode usb kvm seat; do getent group \"$g\" >/dev/null 2>&1 || groupadd -r \"$g\" 2>/dev/null || groupadd \"$g\" 2>/dev/null || true; done\n\
         useradd --create-home --shell /bin/bash '{u}' 2>/dev/null || true\n\
         usermod -aG wheel,audio,video,render,input,plugdev,gamemode,usb,kvm,seat '{u}' 2>/dev/null || true\n\
         chown -R '{u}:{u}' '/home/{u}' 2>/dev/null || true\n",
        u = cfg.username
    ));
    s.push_str(&format!(
        "echo '{u}:{p}' | chpasswd\n",
        u = cfg.username,
        p = cfg.user_password.replace('\'', "'\\''")
    ));
    if !cfg.root_password.is_empty() {
        s.push_str(&format!(
            "echo 'root:{p}' | chpasswd\n",
            p = cfg.root_password.replace('\'', "'\\''")
        ));
    } else {
        s.push_str("passwd -l root || true\n");
    }
    // sudo is installed without /etc/sudoers.d on some stages; creating it is
    // mandatory, because `cat > /etc/sudoers.d/...` aborts the whole configure
    // step under `set -e` when the directory is missing.
    s.push_str("install -d -m 0750 /etc/sudoers.d\n");
    s.push_str("cat > /etc/sudoers.d/10-webos <<'EOF'\n");
    s.push_str("%wheel ALL=(ALL:ALL) ALL\n");
    s.push_str("%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/webos-gaming, /usr/bin/webos-rice\n");
    s.push_str("EOF\nchmod 0440 /etc/sudoers.d/10-webos\n\n");

    // ── remove the live-medium glue ──────────────────────────────────────
    // The target must not autologin root and must not offer the live menu.
    // 40-iso.sh patched /etc/inittab for the live boot and left a backup;
    // the live medium may also have enabled the OpenRC agetty.tty1 service.
    // Restore / undo both BEFORE configuring services or applying the rice,
    // so the result is a normal login (Minimal) or SDDM on tty1 (Full).
    s.push_str("# remove the live-medium glue (restore a normal login)\n");
    s.push_str("if [[ -f /etc/inittab.webos-orig ]]; then mv -f /etc/inittab.webos-orig /etc/inittab; fi\n");
    s.push_str("rm -f /etc/webos-live /etc/conf.d/agetty.tty1 \\\n");
    s.push_str("      /etc/profile.d/99-webos-live.sh /usr/local/bin/webos-live-session\n");
    // If sysvinit's inittab already spawns a getty on tty1, the OpenRC agetty
    // service is redundant there; drop it so the two cannot fight over the VT.
    s.push_str("if [[ -f /etc/inittab ]] && \\\n");
    s.push_str("   grep -qE '^[[:space:]]*[^#][^:]*:[^:]*:[^:]*.*tty1' /etc/inittab; then\n");
    s.push_str("  rc-update del agetty.tty1 default >/dev/null 2>&1 || true\n");
    s.push_str("fi\n\n");

    // ── services (OpenRC) ────────────────────────────────────────────────
    let mut services = vec![
        "dbus",
        "elogind",
        "NetworkManager",
        "syslog-ng",
        "acpid",
        "webos",
        "irqbalance",
    ];
    if cfg.enable_bluetooth {
        services.push("bluetooth");
    }
    if cfg.enable_sshd {
        services.push("sshd");
    }
    if cfg.enable_firewall {
        services.push("nftables");
    }
    // The image ships SDDM (gui-apps/sddm), driven by Gentoo's generic
    // `display-manager` OpenRC service. There is no greetd in the image, so
    // enabling one would silently do nothing and leave the user at a console.
    if cfg.profile.has_gui() {
        s.push_str("cat > /etc/conf.d/display-manager <<'EOF'\nCHECKVT=7\nDISPLAYMANAGER=\"sddm\"\nEOF\n");
        services.push("display-manager");
    }
    s.push_str("for svc in ");
    s.push_str(&services.join(" "));
    s.push_str("; do\n  if [[ -x /etc/init.d/$svc ]]; then rc-update add \"$svc\" default >/dev/null 2>&1 || true; fi\ndone\n");
    // app-admin/ananicy-cpp installs its OpenRC script as ananicy-cpp.initd on
    // Gentoo. The short name silently does nothing, so probe both and start it
    // now as well as enabling it for the next boot.
    s.push_str(
        "for svc in ananicy-cpp.initd ananicy-cpp; do\n\
           if [[ -x /etc/init.d/$svc ]]; then\n\
             rc-update add \"$svc\" default >/dev/null 2>&1 || true\n\
             rc-service \"$svc\" start >/dev/null 2>&1 || true\n\
             break\n\
           fi\n\
         done\n",
    );
    // A minimal install keeps the console getty; no display manager.
    if cfg.profile == Profile::Minimal {
        s.push_str("rc-update del display-manager default >/dev/null 2>&1 || true\n");
    }
    s.push('\n');

    // ── apply the rice ───────────────────────────────────────────────────
    if cfg.profile.uses_rice() && Path::new(&format!("{TARGET}/usr/bin/webos-rice")).exists() {
        s.push_str("webos-rice --system --force || true\n");
        if Path::new(&format!("{TARGET}/usr/bin/webos-dotfiles")).exists() {
            s.push_str(&format!(
                "webos-dotfiles --apply {id} --system --force || true\n",
                id = cfg.dotfiles.id()
            ));
        }
        s.push_str(&format!(
            "chown -R {u}:{u} /home/{u}/.config /home/{u}/.local 2>/dev/null || true\n",
            u = cfg.username
        ));
    }
    // ── default session ──────────────────────────────────────────────────
    // SDDM must offer exactly ONE session: the profile chosen in the wizard.
    // An earlier build symlinked every installed desktop (WebOS, Plasma,
    // gamescope) into the greeter, which left a confusing list at login. The
    // chosen session is also seeded in state.conf so it is the default.
    if cfg.profile.has_gui() {
        let session = cfg.profile.session();
        let link = format!(
            "if [ -f /usr/share/wayland-sessions/{s} ]; then\n\
               ln -sfn /usr/share/wayland-sessions/{s} /usr/share/webos/sessions/wayland/{s}\n\
             elif [ -f /usr/share/xsessions/{s} ]; then\n\
               ln -sfn /usr/share/xsessions/{s} /usr/share/webos/sessions/x11/{s}\n\
             fi\n",
            s = session
        );
        s.push_str(&format!(
            "install -d -m 0755 /var/lib/sddm /etc/sddm.conf.d\n\
             cat > /var/lib/sddm/state.conf <<'EOF'\n\
             [Last]\n\
             Session={session}\n\
             User={u}\n\
             EOF\n\
             chown -R sddm:sddm /var/lib/sddm 2>/dev/null || true\n\
             # WebOS-owned session directory: only the chosen desktop is linked,\n\
             # so the greeter shows one session instead of every installed one.\n\
             install -d -m 0755 /usr/share/webos/sessions/wayland /usr/share/webos/sessions/x11\n\
             rm -f /usr/share/webos/sessions/wayland/*.desktop /usr/share/webos/sessions/x11/*.desktop\n\
             {link}\
             cat > /etc/sddm.conf.d/20-webos-session.conf <<'EOF'\n\
             [Wayland]\n\
             SessionDir=/usr/share/webos/sessions/wayland\n\
             [X11]\n\
             SessionDir=/usr/share/webos/sessions/x11\n\
             EOF\n\n",
            u = cfg.username
        ));
    }

    // ── profile-specific defaults ────────────────────────────────────────
    // The installer copies the live rootfs, so a profile that is NOT selected
    // must be actively removed. Otherwise a Full/Noctalia install inherits
    // the other desktop and SDDM shows sessions the user never asked for.
    if cfg.profile != Profile::Noctalia {
        s.push_str(
            "emerge --quiet --unmerge gui-apps/noctalia >/dev/null 2>&1 || true\n\
             rm -f /usr/share/wayland-sessions/webos-noctalia.desktop\n\
             rm -rf /usr/share/webos/noctalia /etc/skel/.config/noctalia /root/.config/noctalia\n",
        );
    }
    // Plasma lives in its own @plasma set and is not part of @desktop. Remove
    // any Plasma desktop that came from an older live image, but keep
    // kde-plasma/systemsettings: the Hyprland settings menu uses it.
    if cfg.profile != Profile::Plasma {
        s.push_str(
            "if command -v qlist >/dev/null 2>&1; then\n\
               plasma_pkgs=\"$(qlist -I | grep '^kde-plasma/' | grep -v '^kde-plasma/systemsettings-' || true)\"\n\
             else\n\
               plasma_pkgs=\"$(find /var/db/pkg/kde-plasma -mindepth 1 -maxdepth 1 -type d -printf '=%f\\n' 2>/dev/null | grep -v '^=systemsettings-' || true)\"\n\
             fi\n\
             if [[ -n \"$plasma_pkgs\" ]]; then\n\
               emerge --quiet --unmerge $plasma_pkgs >/dev/null 2>&1 || true\n\
             fi\n\
             rm -f /usr/share/wayland-sessions/plasma.desktop\n\
             rm -f /usr/share/webos/sessions/wayland/plasma.desktop\n",
        );
    } else {
        // Plasma is opt-in: install the desktop set and theme it like WebOS.
        // qt6ct conflicts with plasma-meta, so let Plasma own Qt theming.
        s.push_str(
            "if [[ -f /etc/portage/sets/plasma ]]; then\n\
               emerge --quiet --noreplace @plasma >/dev/null 2>&1 || true\n\
             fi\n\
             emerge --quiet --unmerge gui-apps/qt6ct >/dev/null 2>&1 || true\n\
             if command -v webos-plasma-setup >/dev/null 2>&1; then\n\
               webos-plasma-setup >/dev/null 2>&1 || true\n\
             fi\n",
        );
    }
    if cfg.profile == Profile::Minimal {
        s.push_str("cat > /etc/portage/package.mask/20-no-desktop <<'EOF'\n");
        s.push_str("webos-desktop/webos-desktop\nwebos-theme/webos-theme\nEOF\n");
    }

    // ── GPU selection ────────────────────────────────────────────────────
    if cfg.nvidia {
        s.push_str("if [[ -x /usr/bin/eselect ]]; then eselect opengl set nvidia 2>/dev/null || true; fi\n");
    } else {
        s.push_str("if [[ -x /usr/bin/eselect ]]; then eselect opengl set xorg 2>/dev/null || true; fi\n");
    }
    s.push('\n');

    // ── optional applications / shells / features (best-effort) ──────────
    if cfg.profile.has_gui() {
        s.push_str("emerge_app() { emerge --quiet --noreplace \"$@\" >/dev/null 2>&1 || true; }\n");
        s.push_str("remove_app() { emerge --quiet --unmerge \"$@\" >/dev/null 2>&1 || true; }\n");
        if cfg.install_firefox {
            s.push_str("emerge_app www-client/firefox-bin\n");
        } else {
            s.push_str("remove_app www-client/firefox-bin\n");
        }
        // Steam is 32-bit only and this image is 64-bit (ABI_X86=\"64\").
        // Record the choice instead of pulling in a multilib rebuild.
        if cfg.install_steam {
            s.push_str("mkdir -p /etc/webos && printf 'Steam needs a 32-bit (multilib) runtime; not included in this image.\\n' > /etc/webos/steam-unavailable.txt\n");
        }
        if cfg.install_discord {
            s.push_str("emerge_app net-im/discord\n");
        } else {
            s.push_str("remove_app net-im/discord\n");
        }
        if cfg.install_vesktop {
            s.push_str("emerge_app net-im/vesktop-bin || emerge_app net-im/vesktop\n");
        }
        if cfg.install_opencode {
            s.push_str("emerge_app dev-util/opencode-bin\n");
        } else {
            s.push_str("remove_app dev-util/opencode-bin\n");
        }
        if cfg.install_spotify {
            s.push_str("emerge_app media-sound/spotify\n");
        } else {
            s.push_str("remove_app media-sound/spotify\n");
        }
        if cfg.install_waypaper {
            s.push_str("emerge_app gui-apps/waypaper\n");
        }
        if cfg.install_fish {
            s.push_str("emerge_app app-shells/fish\n");
        }
        if cfg.install_zsh {
            s.push_str("emerge_app app-shells/zsh app-shells/zsh-completions\n");
        }
        if cfg.install_flatpak {
            s.push_str("emerge_app sys-apps/flatpak\n");
            s.push_str("if command -v flatpak >/dev/null 2>&1; then flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true; fi\n");
        }
    }

    // ── record the install choices ───────────────────────────────────────
    s.push_str("mkdir -p /etc/webos\n");
    s.push_str("cat > /etc/webos/install.toml <<'EOF'\n");
    s.push_str(&format!(
        "# Written by the WebOS installer on {}.\n\
         # Re-running `webos-installer --config /etc/webos/install.toml`\n\
         # reproduces this install exactly.\n\n{}",
        chrono_now(),
        toml::to_string_pretty(cfg).unwrap_or_default()
    ));
    s.push_str("EOF\n");
    // The OS version comes from the installed /etc/os-release (written from
    // branding/os-release), never a hard-coded string that goes stale.
    s.push_str(
        "chmod 0600 /etc/webos/install.toml\n\
         _webos_ver=\"$( . /etc/os-release 2>/dev/null; printf '%s' \"${VERSION:-${VERSION_ID:-unknown}}\" )\"\n\
         printf 'WebOS %s\\n' \"${_webos_ver:-unknown}\" > /etc/webos-release\n\n",
    );

    // ── purge anything machine-specific from the live medium ─────────────
    s.push_str("rm -f /etc/ssh/ssh_host_* || true\n");
    s.push_str("rm -rf /root/.cache/* /home/*/.cache/* 2>/dev/null || true\n");
    s.push_str("rm -rf /tmp/* /var/tmp/* 2>/dev/null || true\n");

    let _ = p;
    in_chroot(r, &s)
}

// ────────────────────────────────────────────────────────────── initramfs ────

fn build_initramfs(r: &Runner, cfg: &InstallConfig, p: &Partitions) -> Result<()> {
    r.phase("Building the initramfs");

    let kver = r
        .capture("chroot", &[TARGET, "/bin/bash", "-lc", "ls /lib/modules | sort -V | tail -n1"])
        .unwrap_or_default();
    if kver.is_empty() {
        bail!("no kernel modules found in the new system — did the copy succeed?");
    }
    r.info(format!("kernel {kver}"));

    let mut extra = String::new();
    if cfg.encryption == Encryption::Luks {
        extra.push_str(" --add crypt --add dm ");
    }
    if cfg.filesystem == Filesystem::Btrfs {
        extra.push_str(" --add btrfs ");
    }
    // `--add` selects dracut *modules*, not kernel drivers; nvidia has no
    // dracut module. The driver is pulled in by force_drivers in nvidia.conf.

    let nvidia_extra = if cfg.nvidia {
        "printf 'blacklist nouveau\\n' > /etc/modprobe.d/blacklist-nouveau.conf\n\
         rm -f /usr/lib/dracut/dracut.conf.d/10-nvidia-drivers.conf\n\
         printf 'force_drivers+=\" nvidia nvidia_modeset nvidia_uvm nvidia_drm \"\\n' > /etc/dracut.conf.d/nvidia.conf\n"
    } else {
        ""
    };

    let script = format!(
        "#!/bin/bash\nset -euo pipefail\n\
         export PATH=/usr/sbin:/usr/bin:/sbin:/bin\n\
         mkdir -p /etc/dracut.conf.d\n\
         cat > /etc/dracut.conf.d/10-webos.conf <<'EOF'\n\
         force_drivers+=\" overlay squashfs loop isofs sr_mod sd_mod ahci nvme usb-storage xhci_pci virtio_blk virtio_pci btrfs dm_crypt \"\n\
         compress=\"zstd\"\n\
         hostonly=\"yes\"\n\
         early_microcode=\"yes\"\n\
         EOF\n\
         {nvidia_extra}\
         dracut --force --kver {kver}{extra} /boot/initramfs-{kver}.img\n",
        kver = kver,
        extra = extra,
        nvidia_extra = nvidia_extra
    );
    let _ = p;
    in_chroot(r, &script)
}

// ──────────────────────────────────────────────────────────────── record ─────

fn record_install(r: &Runner, cfg: &InstallConfig, _p: &Partitions) -> Result<()> {
    r.phase("Recording the install");
    // Copy our own log into the new system so the user can see what happened.
    if !r.dry_run() {
        let dst_dir = format!("{TARGET}/var/log");
        std::fs::create_dir_all(&dst_dir).ok();
        let dst = format!("{dst_dir}/webos-install.log");
        let _ = std::fs::copy(r.log_path(), &dst);
    }
    let _ = cfg;
    Ok(())
}

fn teardown_target(r: &Runner) {
    // Best effort, deepest first.
    let candidates = [
        format!("{TARGET}/var/tmp"),
        format!("{TARGET}/var/log"),
        format!("{TARGET}/var/cache"),
        format!("{TARGET}/.snapshots"),
        format!("{TARGET}/home"),
        format!("{TARGET}/boot/efi"),
        TARGET.to_string(),
    ];
    for c in candidates {
        let _ = r.try_run("umount", &["-R", c.as_str()]);
        let _ = r.try_run("umount", &["-l", c.as_str()]);
    }
    let _ = r.try_run("cryptsetup", &["close", CRYPT_NAME]);
}

fn chrono_now() -> String {
    // No chrono dependency for one timestamp: ask date(1).
    std::process::Command::new("date")
        .arg("-u")
        .arg("+%Y-%m-%dT%H:%M:%SZ")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "unknown".into())
}
