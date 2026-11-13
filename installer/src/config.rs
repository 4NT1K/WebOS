//! Everything the installer needs to know, in one serialisable struct.
//!
//! `--config file.toml --yes` deserialises this; the wizard fills the same
//! struct field by field. That means an unattended install and an interactive
//! install go through exactly the same code path.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Firmware {
    Uefi,
    Bios,
}

impl Firmware {
    pub fn label(self) -> &'static str {
        match self {
            Firmware::Uefi => "UEFI",
            Firmware::Bios => "BIOS (legacy)",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Filesystem {
    Btrfs,
    Ext4,
    Xfs,
}

impl Filesystem {
    pub const ALL: [Filesystem; 3] = [Filesystem::Btrfs, Filesystem::Ext4, Filesystem::Xfs];

    pub fn label(self) -> &'static str {
        match self {
            Filesystem::Btrfs => "btrfs",
            Filesystem::Ext4 => "ext4",
            Filesystem::Xfs => "xfs",
        }
    }

    pub fn note(self) -> &'static str {
        match self {
            Filesystem::Btrfs => {
                "Recommended. Subvolumes, transparent zstd compression, snapshots via snapper."
            }
            Filesystem::Ext4 => "The safe, boring choice. No snapshots, no compression.",
            Filesystem::Xfs => "Fast for large files; cannot be shrunk. Fine for a games drive.",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Encryption {
    None,
    Luks,
}

impl Encryption {
    pub const ALL: [Encryption; 2] = [Encryption::None, Encryption::Luks];

    pub fn label(self) -> &'static str {
        match self {
            Encryption::None => "none",
            Encryption::Luks => "LUKS2 (full disk)",
        }
    }

    pub fn note(self) -> &'static str {
        match self {
            Encryption::None => "fastest boot; the disk is readable if stolen",
            Encryption::Luks => "encrypted root; passphrase required at boot",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SwapChoice {
    None,
    Zram,
    Partition,
}

impl SwapChoice {
    pub const ALL: [SwapChoice; 3] = [
        SwapChoice::Zram,
        SwapChoice::Partition,
        SwapChoice::None,
    ];

    pub fn label(self) -> &'static str {
        match self {
            SwapChoice::None => "none",
            SwapChoice::Zram => "zram only (recommended)",
            SwapChoice::Partition => "swap partition",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Profile {
    /// Hyprland, greetd, the full rice, the gaming stack.
    Full,
    /// KDE Plasma instead of Hyprland: same greetd login, same gaming stack,
    /// but the desktop session is Plasma rather than the WebOS rice.
    Plasma,
    /// No graphical session: a TTY login and the base system.
    Minimal,
}

impl Profile {
    pub const ALL: [Profile; 3] = [Profile::Full, Profile::Plasma, Profile::Minimal];

    pub fn label(self) -> &'static str {
        match self {
            Profile::Full => "Full — Hyprland + gaming",
            Profile::Plasma => "Full — KDE Plasma + gaming",
            Profile::Minimal => "Minimal — TTY only",
        }
    }

    pub fn note(self) -> &'static str {
        match self {
            Profile::Full => {
                "Hyprland desktop, greetd login, Steam, Proton, MangoHud. ~6 GB installed."
            }
            Profile::Plasma => {
                "KDE Plasma desktop, greetd login, Steam, Proton, MangoHud. ~6 GB installed."
            }
            Profile::Minimal => {
                "Base system only. Boots to a console. You can emerge the desktop later."
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct InstallConfig {
    // ── target ────────────────────────────────────────────────────────────
    pub disk: String,
    pub disk_model: String,
    pub disk_size_gib: f64,
    pub firmware: Firmware,

    // ── layout ────────────────────────────────────────────────────────────
    pub filesystem: Filesystem,
    pub encryption: Encryption,
    pub swap: SwapChoice,
    pub luks_passphrase: String,
    pub esp_size_mib: u64,
    pub swap_size_mib: u64,

    // ── identity ──────────────────────────────────────────────────────────
    pub hostname: String,
    pub username: String,
    pub full_name: String,
    pub user_password: String,
    pub root_password: String,

    // ── region ────────────────────────────────────────────────────────────
    pub timezone: String,
    pub locale: String,
    pub keymap: String,

    // ── options ───────────────────────────────────────────────────────────
    pub profile: Profile,
    pub install_gaming: bool,
    pub nvidia: bool,
    pub enable_bluetooth: bool,
    pub enable_sshd: bool,
    pub enable_firewall: bool,
    pub use_grub: bool,
}

impl Default for InstallConfig {
    fn default() -> Self {
        Self {
            disk: String::new(),
            disk_model: String::new(),
            disk_size_gib: 0.0,
            firmware: Firmware::Uefi,

            filesystem: Filesystem::Btrfs,
            encryption: Encryption::None,
            swap: SwapChoice::Zram,
            luks_passphrase: String::new(),
            esp_size_mib: 512,
            swap_size_mib: 4096,

            hostname: "webos".into(),
            username: String::new(),
            full_name: String::new(),
            user_password: String::new(),
            root_password: String::new(),

            timezone: "UTC".into(),
            locale: "en_US.UTF-8".into(),
            keymap: "us".into(),

            profile: Profile::Full,
            install_gaming: true,
            nvidia: false,
            enable_bluetooth: true,
            enable_sshd: false,
            enable_firewall: false,
            use_grub: true,
        }
    }
}

impl InstallConfig {
    /// Problems that must be fixed before the summary page will let you pass.
    pub fn validate(&self) -> Vec<String> {
        let mut errs = Vec::new();

        if self.disk.is_empty() {
            errs.push("no target disk selected".into());
        }
        if self.username.is_empty() {
            errs.push("username is empty".into());
        } else if !self.username.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '-') {
            errs.push("username may only contain a-z, 0-9, _ and -".into());
        } else if self.username.len() > 32 {
            errs.push("username is too long (max 32)".into());
        }
        if self.hostname.is_empty() {
            errs.push("hostname is empty".into());
        }
        if self.user_password.is_empty() {
            errs.push("user password is empty".into());
        }
        if self.user_password != self.root_password && self.root_password.is_empty() {
            // Not an error, but worth saying out loud on the summary page.
        }
        if self.encryption == Encryption::Luks && self.luks_passphrase.len() < 8 {
            errs.push("LUKS passphrase must be at least 8 characters".into());
        }
        if self.filesystem == Filesystem::Xfs && self.swap == SwapChoice::Partition {
            // Perfectly legal; listed so nobody is surprised.
        }
        errs
    }

    /// Human-readable one-line summary, used by the summary page and by
    /// `--config` runs that echo what they are about to do.
    pub fn layout_summary(&self) -> String {
        let mut parts = vec![self.filesystem.label().to_string()];
        if self.encryption == Encryption::Luks {
            parts.push("LUKS2".into());
        }
        match self.swap {
            SwapChoice::None => {}
            SwapChoice::Zram => parts.push("zram".into()),
            SwapChoice::Partition => parts.push("swap partition".into()),
        }
        parts.join(" + ")
    }
}
