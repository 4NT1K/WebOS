//! Where does the system we are about to install actually live?
//!
//! On a WebOS live medium the answer is a squashfs mounted by dracut's
//! `dmsquash-live` module. In CI, and for `--check`, it can also be a
//! directory or a tarball that someone pointed us at with SANUS_ROOTFS.
//!
//! The installer never assumes: it looks in a fixed list of places, verifies
//! that what it found is really a WebOS root, and says so out loud.

use std::path::{Path, PathBuf};

use anyhow::{bail, Context, Result};

#[derive(Debug, Clone)]
pub enum Source {
    /// A directory tree that can be rsynced straight onto the target.
    Dir(PathBuf),
    /// A compressed tarball of a root filesystem.
    Tarball(PathBuf),
}

impl std::fmt::Display for Source {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Source::Dir(p) => write!(f, "{} (directory)", p.display()),
            Source::Tarball(p) => write!(f, "{} (tarball)", p.display()),
        }
    }
}

/// Directories that may hold a mounted live root, most likely first.
const DIR_CANDIDATES: &[&str] = &[
    "/run/initramfs/live",
    "/run/initramfs/live/LiveOS",
    "/run/rootfs",
    "/run/sanus/rootfs",
    "/mnt/live",
    "/live",
];

/// Tarballs that may hold a root filesystem, most likely first.
const TARBALL_CANDIDATES: &[&str] = &[
    "/run/initramfs/live/sanus/rootfs.tar.zst",
    "/run/initramfs/live/rootfs.tar.zst",
    "/run/sanus/rootfs.tar.zst",
    "/opt/sanus/rootfs.tar.zst",
];

pub fn locate() -> Result<Source> {
    // An explicit override always wins.
    if let Some(p) = std::env::var_os("SANUS_ROOTFS") {
        let path = PathBuf::from(p);
        if path.is_dir() {
            return Ok(Source::Dir(path));
        }
        if path.is_file() {
            return Ok(Source::Tarball(path));
        }
        bail!("SANUS_ROOTFS points at {} which does not exist", path.display());
    }

    for cand in DIR_CANDIDATES {
        let path = Path::new(cand);
        if is_sanus_root(path) {
            return Ok(Source::Dir(path.to_path_buf()));
        }
    }

    for cand in TARBALL_CANDIDATES {
        let path = Path::new(cand);
        if path.is_file() {
            return Ok(Source::Tarball(path.to_path_buf()));
        }
    }

    // Last resort: a squashfs sitting on the live medium that dracut did not
    // auto-mount. We cannot mount it here (that is the caller's job), so just
    // report it clearly.
    for cand in ["/run/initramfs/live/live/sanus.squashfs", "/live/sanus.squashfs"] {
        if Path::new(cand).is_file() {
            bail!(
                "found the live image at {cand} but it is not mounted.\n\
                 Boot the live medium normally (the installer expects it at \
                 /run/initramfs/live), or mount it yourself and set SANUS_ROOTFS."
            );
        }
    }

    bail!("could not find a WebOS root filesystem to install from")
}

/// Is this directory plausibly a WebOS/SanusOS root?
pub fn is_sanus_root(path: &Path) -> bool { // keep name for compatibility
    if !path.is_dir() {
        return false;
    }
    // A root fs always has these two.
    if !path.join("etc").is_dir() || !path.join("usr").is_dir() {
        return false;
    }
    // And, on WebOS/SanusOS, this one.
    if path.join("etc/webos-release").is_file() || path.join("etc/sanus-release").is_file() {
        return true;
    }
    // Fall back to any os-release that mentions us.
    let os_release = path.join("etc/os-release");
    if let Ok(text) = std::fs::read_to_string(&os_release) {
        if text.contains("ID=webos") || text.contains("ID=sanus") || text.contains("WebOS") || text.contains("SanusOS") {
            return true;
        }
    }
    // A Gentoo root with our overlay and our kernel is good enough for CI.
    path.join("usr/local/portage/sanus").is_dir()
}

/// One-line description for the preflight output.
pub fn describe() -> String {
    match locate() {
        Ok(Source::Dir(p)) => format!("directory {}", p.display()),
        Ok(Source::Tarball(p)) => {
            let size = std::fs::metadata(&p).map(|m| m.len()).unwrap_or(0);
            format!("tarball {} ({})", p.display(), crate::disk::human(size))
        }
        Err(_) => "not found".to_string(),
    }
}

/// Mount the squashfs image from the live medium at `mountpoint`, if needed.
pub fn ensure_mounted(mountpoint: &str) -> Result<()> {
    let mp = Path::new(mountpoint);
    if is_sanus_root(mp) {
        return Ok(());
    }
    std::fs::create_dir_all(mp).context("creating live mountpoint")?;

    for image in ["/run/initramfs/live/live/sanus.squashfs", "/live/sanus.squashfs"] {
        if Path::new(image).is_file() {
            let status = std::process::Command::new("mount")
                .args(["-t", "squashfs", "-o", "loop,ro", image, mountpoint])
                .status()
                .context("mounting the live squashfs")?;
            if status.success() {
                return Ok(());
            }
        }
    }
    bail!("could not mount the live filesystem at {mountpoint}")
}
