//! Finding disks, and knowing what kind of firmware we booted from.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{bail, Result};

#[derive(Debug, Clone)]
pub struct Disk {
    /// Full device node, e.g. /dev/nvme0n1
    pub path: String,
    /// Kernel name, e.g. nvme0n1
    pub name: String,
    pub model: String,
    pub size_bytes: u64,
    pub removable: bool,
    pub rotational: bool,
}

impl Disk {
    pub fn human_size(&self) -> String {
        human(self.size_bytes)
    }

    pub fn kind(&self) -> &'static str {
        if self.removable {
            "removable"
        } else if self.rotational {
            "hdd"
        } else {
            "ssd"
        }
    }
}

/// `nvme0n1` -> `nvme0n1p1`, `sda` -> `sda1`, `mmcblk0` -> `mmcblk0p1`.
pub fn partition_path(disk: &str, index: u32) -> String {
    let name = disk.trim_start_matches("/dev/");
    if name.starts_with("nvme")
        || name.starts_with("mmcblk")
        || name.starts_with("nbd")
        || name.starts_with("loop")
    {
        format!("{disk}p{index}")
    } else {
        format!("{disk}{index}")
    }
}

pub fn human(bytes: u64) -> String {
    const GIB: f64 = 1024.0 * 1024.0 * 1024.0;
    const MIB: f64 = 1024.0 * 1024.0;
    let b = bytes as f64;
    if b >= GIB {
        format!("{:.1} GiB", b / GIB)
    } else if b >= MIB {
        format!("{:.0} MiB", b / MIB)
    } else {
        format!("{bytes} B")
    }
}

/// Every block device that could plausibly hold an operating system.
///
/// We deliberately ignore loop, ram, zram, dm-*, md*, sr*, fd* and nbd* — the
/// live medium's own loop devices are the most common way for an installer to
/// offer to destroy itself.
pub fn enumerate() -> Vec<Disk> {
    let mut out = Vec::new();
    let Ok(entries) = fs::read_dir("/sys/block") else {
        return out;
    };

    for entry in entries.flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if is_ignored(&name) {
            continue;
        }
        let base = PathBuf::from("/sys/block").join(&name);

        let size_bytes = read_trim(&base.join("size"))
            .and_then(|s| s.parse::<u64>().ok())
            .map(|sectors| sectors * 512)
            .unwrap_or(0);

        // Anything under 2 GiB is a USB stick, a card reader or a firmware
        // partition, not an install target.
        if size_bytes < 2 * 1024 * 1024 * 1024 {
            continue;
        }

        let model = read_trim(&base.join("device/model"))
            .filter(|m| !m.is_empty())
            .unwrap_or_else(|| name.clone());

        let removable = read_trim(&base.join("removable")).as_deref() == Some("1");
        let rotational = read_trim(&base.join("queue/rotational")).as_deref() == Some("1");

        out.push(Disk {
            path: format!("/dev/{name}"),
            name,
            model,
            size_bytes,
            removable,
            rotational,
        });
    }

    out.sort_by(|a, b| a.name.cmp(&b.name));
    out
}

fn is_ignored(name: &str) -> bool {
    const PREFIXES: [&str; 9] = ["loop", "ram", "zram", "dm-", "md", "sr", "fd", "nbd", "rbd"];
    PREFIXES.iter().any(|p| name.starts_with(p))
}

fn read_trim(path: &Path) -> Option<String> {
    fs::read_to_string(path).ok().map(|s| s.trim().to_string())
}

/// Did we boot in UEFI mode?
pub fn is_efi() -> bool {
    Path::new("/sys/firmware/efi").is_dir()
}

/// Wait for the kernel to notice new partitions.
pub fn settle() {
    let _ = std::process::Command::new("udevadm")
        .args(["settle", "--timeout=10"])
        .status();
    let _ = std::process::Command::new("partprobe")
        .arg("-s")
        .status();
    std::thread::sleep(std::time::Duration::from_millis(600));
}

/// Is anything currently mounted from this disk? Refuse to touch it if so.
pub fn in_use(disk: &Disk) -> Result<Vec<String>> {
    let mounts = fs::read_to_string("/proc/mounts").unwrap_or_default();
    let hits: Vec<String> = mounts
        .lines()
        .filter_map(|l| l.split_whitespace().next())
        .filter(|dev| dev.starts_with(&disk.path))
        .map(|s| s.to_string())
        .collect();
    Ok(hits)
}

/// Sanity check before we hand a device to sgdisk.
pub fn verify_target(disk: &Disk) -> Result<()> {
    if !Path::new(&disk.path).exists() {
        bail!("{} does not exist", disk.path);
    }
    if disk.size_bytes < 8 * 1024 * 1024 * 1024 {
        bail!(
            "{} is only {}; WebOS needs at least 8 GiB",
            disk.path,
            disk.human_size()
        );
    }
    let mounted = in_use(disk)?;
    if !mounted.is_empty() {
        bail!(
            "{} has mounted partitions ({}); unmount them first",
            disk.path,
            mounted.join(", ")
        );
    }
    Ok(())
}
