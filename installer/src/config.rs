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

/// Desktop dotfiles/look applied to the installed account.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Dotfiles {
    Ashen,
    Jakoolit,
    Mono,
    Minimal,
}

impl Dotfiles {
    pub const ALL: [Dotfiles; 4] = [
        Dotfiles::Ashen,
        Dotfiles::Mono,
        Dotfiles::Jakoolit,
        Dotfiles::Minimal,
    ];

    pub fn label(self) -> &'static str {
        match self {
            Dotfiles::Ashen => "Ashen (WebOS default)",
            Dotfiles::Jakoolit => "JaKooLit glass",
            Dotfiles::Mono => "Mono (monochrome)",
            Dotfiles::Minimal => "Minimal bar",
        }
    }

    pub fn note(self) -> &'static str {
        match self {
            Dotfiles::Ashen => "Deep Black rice: frosted top bar, music, wallpaper, portals.",
            Dotfiles::Jakoolit => "JaKooLit-inspired frosted top bar with player, workspaces and tray.",
            Dotfiles::Mono => "Flat monochrome bar, grayscale kitty and square mako. Light and fast.",
            Dotfiles::Minimal => "Plain low-resource top bar; no extra modules or scripts.",
        }
    }

    pub fn id(self) -> &'static str {
        match self {
            Dotfiles::Ashen => "ashen",
            Dotfiles::Jakoolit => "jakoolit",
            Dotfiles::Mono => "mono",
            Dotfiles::Minimal => "minimal",
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
    /// Hyprland, SDDM, the full WebOS rice, the gaming stack.
    Full,
    /// niri compositor with the WebOS look, SDDM, the gaming stack.
    Niri,
    /// Hyprland + the Noctalia shell, SDDM, the gaming stack.
    Noctalia,
    /// KDE Plasma instead of the WebOS rice: SDDM, same gaming stack.
    Plasma,
    /// No graphical session: a TTY login and the base system.
    Minimal,
}

impl Profile {
    pub const ALL: [Profile; 5] = [
        Profile::Full,
        Profile::Niri,
        Profile::Noctalia,
        Profile::Plasma,
        Profile::Minimal,
    ];

    pub fn label(self) -> &'static str {
        match self {
            Profile::Full => "WebOS — Hyprland + gaming",
            Profile::Niri => "WebOS — Niri + gaming",
            Profile::Noctalia => "WebOS — Noctalia shell + gaming",
            Profile::Plasma => "KDE Plasma + gaming",
            Profile::Minimal => "Minimal — TTY only",
        }
    }

    pub fn note(self) -> &'static str {
        match self {
            Profile::Full => {
                "Hyprland desktop, SDDM login, the WebOS rice and dotfiles, Steam, Proton, MangoHud."
            }
            Profile::Niri => {
                "niri scrollable-tiling Wayland compositor with the WebOS look, SDDM, gaming stack."
            }
            Profile::Noctalia => {
                "Hyprland + Noctalia: a monochrome Wayland shell (bar, notifications, launcher) with SDDM."
            }
            Profile::Plasma => {
                "KDE Plasma (Wayland) desktop, SDDM login, Steam, Proton, MangoHud."
            }
            Profile::Minimal => {
                "Base system only. Boots to a console. You can emerge a desktop later."
            }
        }
    }

    /// Whether this profile boots a graphical session.
    pub fn has_gui(self) -> bool {
        !matches!(self, Profile::Minimal)
    }

    /// Whether this profile uses the WebOS rice/dotfiles (Hyprland or niri).
    pub fn uses_rice(self) -> bool {
        matches!(self, Profile::Full | Profile::Niri | Profile::Noctalia)
    }

    /// The SDDM session .desktop name for this profile.
    pub fn session(self) -> &'static str {
        match self {
            Profile::Full => "webos.desktop",
            Profile::Niri => "webos-niri.desktop",
            Profile::Noctalia => "webos-noctalia.desktop",
            Profile::Plasma => "plasma.desktop",
            Profile::Minimal => "",
        }
    }
}

fn default_dotfiles() -> Dotfiles {
    Dotfiles::Ashen
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
    #[serde(default = "default_dotfiles")]
    pub dotfiles: Dotfiles,
    pub install_gaming: bool,
    #[serde(default = "default_true")]
    pub install_steam: bool,
    #[serde(default = "default_true")]
    pub install_firefox: bool,
    #[serde(default)]
    pub install_discord: bool,
    #[serde(default)]
    pub install_opencode: bool,
    #[serde(default)]
    pub install_spotify: bool,
    #[serde(default)]
    pub install_vesktop: bool,
    #[serde(default)]
    pub install_waypaper: bool,
    #[serde(default)]
    pub install_fish: bool,
    #[serde(default)]
    pub install_zsh: bool,
    #[serde(default)]
    pub install_flatpak: bool,
    pub nvidia: bool,
    pub enable_bluetooth: bool,
    pub enable_sshd: bool,
    pub enable_firewall: bool,
    pub use_grub: bool,
}

fn default_true() -> bool { true }

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
            dotfiles: Dotfiles::Ashen,
            install_gaming: true,
            install_steam: true,
            install_firefox: true,
            install_discord: false,
            install_opencode: false,
            install_spotify: false,
            install_vesktop: false,
            install_waypaper: false,
            install_fish: true,
            install_zsh: true,
            install_flatpak: false,
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
