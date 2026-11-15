//! The wizard: what page we are on, what the user typed, and the thread that
//! actually installs.
//!
//! The UI thread never touches a disk. It owns a [`Receiver`] and drains it in
//! `tick()`, which the event loop calls on every pass. The worker owns a
//! [`Runner`] and sends [`Msg`]s back. That is the whole concurrency design:
//! one channel, one direction, no locks around the terminal.

use std::path::PathBuf;
use std::sync::mpsc::{self, Receiver};

use ratatui::layout::Rect;

use anyhow::Result;
use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};

use crate::config::{
    Encryption, Filesystem, Firmware, InstallConfig, Profile, SwapChoice,
};
use crate::disk::{self, Disk};
use crate::exec::{Msg, Runner};
use crate::install;

/// The pages, in order.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Step {
    Welcome,
    Disk,
    Filesystem,
    Encryption,
    Locale,
    User,
    Options,
    Extras,
    Summary,
    Install,
    Done,
}

impl Step {
    pub fn title(self) -> &'static str {
        match self {
            Step::Welcome => "Welcome",
            Step::Disk => "Target disk",
            Step::Filesystem => "Filesystem",
            Step::Encryption => "Encryption",
            Step::Locale => "Region",
            Step::User => "Account",
            Step::Options => "System options",
            Step::Extras => "Extra features",
            Step::Summary => "Summary",
            Step::Install => "Installing",
            Step::Done => "Finished",
        }
    }

    pub fn index(self) -> usize {
        match self {
            Step::Welcome => 0,
            Step::Disk => 1,
            Step::Filesystem => 2,
            Step::Encryption => 3,
            Step::Locale => 4,
            Step::User => 5,
            Step::Options => 6,
            Step::Extras => 7,
            Step::Summary => 8,
            Step::Install => 9,
            Step::Done => 10,
        }
    }

    /// How many pages come before the install starts (used for the sidebar).
    pub const STEPS: [Step; 9] = [
        Step::Welcome,
        Step::Disk,
        Step::Filesystem,
        Step::Encryption,
        Step::Locale,
        Step::User,
        Step::Options,
        Step::Extras,
        Step::Summary,
    ];

    fn next(self) -> Step {
        match self {
            Step::Welcome => Step::Disk,
            Step::Disk => Step::Filesystem,
            Step::Filesystem => Step::Encryption,
            Step::Encryption => Step::Locale,
            Step::Locale => Step::User,
            Step::User => Step::Options,
            Step::Options => Step::Extras,
            Step::Extras => Step::Summary,
            Step::Summary => Step::Install,
            Step::Install | Step::Done => self,
        }
    }

    fn prev(self) -> Step {
        match self {
            Step::Welcome => Step::Welcome,
            Step::Disk => Step::Welcome,
            Step::Filesystem => Step::Disk,
            Step::Encryption => Step::Filesystem,
            Step::Locale => Step::Encryption,
            Step::User => Step::Locale,
            Step::Options => Step::User,
            Step::Extras => Step::Options,
            Step::Summary => Step::Extras,
            Step::Install | Step::Done => self,
        }
    }
}

fn on_off(v: bool) -> &'static str {
    if v {
        "yes"
    } else {
        "no"
    }
}

pub struct App {
    // ── configuration the wizard edits ───────────────────────────────────
    pub cfg: InstallConfig,

    // ── navigation ───────────────────────────────────────────────────────
    pub step: Step,
    pub cursor: usize,
    pub field: usize,
    pub editing: bool,
    pub input: String,
    pub confirm_wipe: bool,

    // ── machine state ────────────────────────────────────────────────────
    pub disks: Vec<Disk>,

    // Last list panel the UI rendered — used for mouse hit-testing.
    pub list_area: Option<Rect>,

    // ── install worker ───────────────────────────────────────────────────
    pub installing: bool,
    pub done: bool,
    pub installed: bool,
    pub started: bool,
    pub phase: String,
    pub progress: f32,
    pub log: Vec<String>,
    pub log_offset: usize,
    pub error: Option<String>,
    pub should_quit: bool,

    // ── environment ──────────────────────────────────────────────────────
    pub dry_run: bool,
    pub yes: bool,
    pub log_path: PathBuf,
    pub prefilled: bool,

    rx: Option<Receiver<Msg>>,
}

impl App {
    pub fn new(dry_run: bool, yes: bool, log: Option<PathBuf>) -> Result<Self> {
        let disks = disk::enumerate();
        // The firmware we booted from is the best guess for the firmware we
        // should install for; the user can override it with `f`.
        let cfg = InstallConfig {
            firmware: if disk::is_efi() {
                Firmware::Uefi
            } else {
                Firmware::Bios
            },
            ..Default::default()
        };

        Ok(Self {
            cfg,
            step: Step::Welcome,
            cursor: 0,
            field: 0,
            editing: false,
            input: String::new(),
            confirm_wipe: false,
            disks,
            installing: false,
            done: false,
            installed: false,
            started: false,
            phase: String::new(),
            progress: 0.0,
            log: Vec::new(),
            log_offset: 0,
            error: None,
            should_quit: false,
            dry_run,
            yes,
            log_path: log.unwrap_or_else(|| PathBuf::from("/var/log/webos-install.log")),
            prefilled: false,
            list_area: None,
            rx: None,
        })
    }

    /// Adopt a configuration from `--config` and jump to the summary.
    pub fn apply_config(&mut self, cfg: InstallConfig) -> Result<()> {
        self.cfg = cfg;
        self.prefilled = true;
        self.goto(Step::Summary);
        Ok(())
    }

    // ── the event-loop contract ──────────────────────────────────────────

    pub fn tick(&mut self) {
        let msgs: Vec<Msg> = match &self.rx {
            Some(rx) => {
                let mut v = Vec::new();
                while let Ok(m) = rx.try_recv() {
                    v.push(m);
                }
                v
            }
            None => Vec::new(),
        };
        for m in msgs {
            self.handle_msg(m);
        }

        // Unattended installs skip the summary's confirmation.
        if self.step == Step::Summary && self.yes && !self.started {
            self.start_install();
        }
    }

    pub fn scroll_log(&mut self, delta: i32) {
        if delta < 0 {
            self.log_offset = self.log_offset.saturating_add((-delta) as usize);
        } else {
            self.log_offset = self.log_offset.saturating_sub(delta as usize);
        }
    }

    fn handle_msg(&mut self, m: Msg) {
        match m {
            Msg::Phase(p) => self.phase = p,
            Msg::Progress(v) => self.progress = v.clamp(0.0, 1.0),
            Msg::Line(l) => {
                self.log.push(l);
                // Do not let a chatty command grow the log without bound.
                if self.log.len() > 50_000 {
                    self.log.drain(0..10_000);
                }
            }
            Msg::Done => self.finish(true, None),
            Msg::Failed(e) => self.finish(false, Some(e)),
        }
    }

    fn finish(&mut self, ok: bool, err: Option<String>) {
        self.installing = false;
        self.done = true;
        self.installed = ok;
        self.error = err;
        self.rx = None;
        self.step = Step::Done;
        self.phase = if ok { "Finished".into() } else { "Failed".into() };
        if ok {
            self.progress = 1.0;
        }
    }

    pub fn start_install(&mut self) {
        if self.installing || self.done {
            return;
        }
        let errs = self.cfg.validate();
        if !errs.is_empty() {
            self.error = Some(errs.join("; "));
            return;
        }

        self.installing = true;
        self.started = true;
        self.step = Step::Install;
        self.log.clear();
        self.log_offset = 0;
        self.progress = 0.0;
        self.phase = "Starting".into();
        self.error = None;

        let (tx, rx) = mpsc::channel();
        self.rx = Some(rx);

        let cfg = self.cfg.clone();
        let path = self.log_path.clone();
        let dry = self.dry_run;

        std::thread::spawn(move || match Runner::new(path, tx.clone(), dry) {
            Ok(r) => match install::run(&cfg, &r) {
                Ok(()) => r.finish(),
                Err(e) => r.fail(&e),
            },
            Err(e) => {
                let _ = tx.send(Msg::Failed(format!("{e:#}")));
            }
        });
    }

    // ── navigation helpers ───────────────────────────────────────────────

    pub fn goto(&mut self, step: Step) {
        self.step = step;
        self.editing = false;
        self.input.clear();
        self.error = None;
        self.confirm_wipe = false;
        self.field = 0;
        self.sync_cursor();
    }

    fn sync_cursor(&mut self) {
        match self.step {
            Step::Disk => {
                self.cursor = self
                    .disks
                    .iter()
                    .position(|d| d.path == self.cfg.disk)
                    .unwrap_or(0);
            }
            Step::Filesystem => {
                self.cursor = Filesystem::ALL
                    .iter()
                    .position(|f| *f == self.cfg.filesystem)
                    .unwrap_or(0);
            }
            Step::Encryption => {
                self.cursor = Encryption::ALL
                    .iter()
                    .position(|e| *e == self.cfg.encryption)
                    .unwrap_or(0);
            }
            _ => self.cursor = 0,
        }
    }

    // ── text fields ──────────────────────────────────────────────────────

    pub fn field_count(&self, step: Step) -> usize {
        match step {
            Step::Encryption => {
                if self.cfg.encryption == Encryption::Luks {
                    1
                } else {
                    0
                }
            }
            Step::Locale => 3,
            Step::User => 5,
            _ => 0,
        }
    }

    pub fn field_label(&self, step: Step, i: usize) -> &'static str {
        match (step, i) {
            (Step::Encryption, 0) => "Passphrase",
            (Step::Locale, 0) => "Timezone",
            (Step::Locale, 1) => "Locale",
            (Step::Locale, 2) => "Console keymap",
            (Step::User, 0) => "Full name",
            (Step::User, 1) => "Username",
            (Step::User, 2) => "Hostname",
            (Step::User, 3) => "Password",
            (Step::User, 4) => "Root password",
            _ => "",
        }
    }

    pub fn field_help(&self, step: Step, i: usize) -> &'static str {
        match (step, i) {
            (Step::Encryption, 0) => "at least 8 characters; required to unlock the disk at boot",
            (Step::Locale, 0) => "e.g. Europe/Berlin",
            (Step::Locale, 1) => "e.g. en_US.UTF-8",
            (Step::Locale, 2) => "e.g. us, de, dvorak",
            (Step::User, 0) => "only used for display",
            (Step::User, 1) => "lowercase letters, digits, _ and -",
            (Step::User, 2) => "the name of this machine",
            (Step::User, 3) => "used to log in and to sudo",
            (Step::User, 4) => "leave empty to disable the root account",
            _ => "",
        }
    }

    pub fn field_secret(&self, step: Step, i: usize) -> bool {
        matches!((step, i), (Step::Encryption, 0) | (Step::User, 3) | (Step::User, 4))
    }

    pub fn field_value(&self, step: Step, i: usize) -> String {
        match (step, i) {
            (Step::Encryption, 0) => self.cfg.luks_passphrase.clone(),
            (Step::Locale, 0) => self.cfg.timezone.clone(),
            (Step::Locale, 1) => self.cfg.locale.clone(),
            (Step::Locale, 2) => self.cfg.keymap.clone(),
            (Step::User, 0) => self.cfg.full_name.clone(),
            (Step::User, 1) => self.cfg.username.clone(),
            (Step::User, 2) => self.cfg.hostname.clone(),
            (Step::User, 3) => self.cfg.user_password.clone(),
            (Step::User, 4) => self.cfg.root_password.clone(),
            _ => String::new(),
        }
    }

    fn set_field(&mut self, step: Step, i: usize, v: String) {
        match (step, i) {
            (Step::Encryption, 0) => self.cfg.luks_passphrase = v,
            (Step::Locale, 0) => self.cfg.timezone = v,
            (Step::Locale, 1) => self.cfg.locale = v,
            (Step::Locale, 2) => self.cfg.keymap = v,
            (Step::User, 0) => self.cfg.full_name = v,
            (Step::User, 1) => self.cfg.username = v,
            (Step::User, 2) => self.cfg.hostname = v,
            (Step::User, 3) => self.cfg.user_password = v,
            (Step::User, 4) => self.cfg.root_password = v,
            _ => {}
        }
    }

    /// What the field shows: the committed value, or the live input while the
    /// user is typing in it.
    pub fn field_display(&self, step: Step, i: usize) -> String {
        let raw = if self.editing && i == self.field {
            self.input.clone()
        } else {
            self.field_value(step, i)
        };
        if self.field_secret(step, i) {
            "•".repeat(raw.chars().count())
        } else {
            raw
        }
    }

    fn begin_edit(&mut self) {
        self.input = self.field_value(self.step, self.field);
        self.editing = true;
    }

    fn commit_field(&mut self) {
        let i = self.field;
        let v = self.input.clone();
        self.set_field(self.step, i, v);
        self.editing = false;
    }

    fn advance_field(&mut self) {
        if self.field + 1 < self.field_count(self.step) {
            self.field += 1;
        } else {
            self.goto(self.step.next());
        }
    }

    // ── options / extras ─────────────────────────────────────────────────

    pub fn options(&self) -> Vec<(String, String)> {
        vec![
            ("Swap".into(), self.cfg.swap.label().into()),
            ("Profile".into(), self.cfg.profile.label().into()),
            ("NVIDIA driver".into(), on_off(self.cfg.nvidia).into()),
            ("Bluetooth".into(), on_off(self.cfg.enable_bluetooth).into()),
            ("SSH server".into(), on_off(self.cfg.enable_sshd).into()),
            ("Firewall (nftables)".into(), on_off(self.cfg.enable_firewall).into()),
            ("GRUB bootloader".into(), on_off(self.cfg.use_grub).into()),
        ]
    }

    fn toggle_option(&mut self, i: usize) {
        match i {
            0 => {
                let i = SwapChoice::ALL
                    .iter()
                    .position(|s| *s == self.cfg.swap)
                    .unwrap_or(0);
                self.cfg.swap = SwapChoice::ALL[(i + 1) % SwapChoice::ALL.len()];
            }
            1 => {
                let i = Profile::ALL
                    .iter()
                    .position(|p| *p == self.cfg.profile)
                    .unwrap_or(0);
                self.cfg.profile = Profile::ALL[(i + 1) % Profile::ALL.len()];
            }
            2 => self.cfg.nvidia = !self.cfg.nvidia,
            3 => self.cfg.enable_bluetooth = !self.cfg.enable_bluetooth,
            4 => self.cfg.enable_sshd = !self.cfg.enable_sshd,
            5 => self.cfg.enable_firewall = !self.cfg.enable_firewall,
            6 => self.cfg.use_grub = !self.cfg.use_grub,
            _ => {}
        }
    }

    pub fn extras(&self) -> Vec<(String, String)> {
        vec![
            ("Gaming stack".into(), on_off(self.cfg.install_gaming).into()),
            ("Steam (64-bit note)".into(), on_off(self.cfg.install_steam).into()),
            ("Firefox".into(), on_off(self.cfg.install_firefox).into()),
            ("Discord".into(), on_off(self.cfg.install_discord).into()),
            ("Vesktop (Vencord)".into(), on_off(self.cfg.install_vesktop).into()),
            ("OpenCode".into(), on_off(self.cfg.install_opencode).into()),
            ("Spotify".into(), on_off(self.cfg.install_spotify).into()),
            ("Waypaper (wallpapers)".into(), on_off(self.cfg.install_waypaper).into()),
            ("Fish shell".into(), on_off(self.cfg.install_fish).into()),
            ("Zsh shell".into(), on_off(self.cfg.install_zsh).into()),
            ("Flatpak".into(), on_off(self.cfg.install_flatpak).into()),
        ]
    }

    fn toggle_extra(&mut self, i: usize) {
        match i {
            0 => self.cfg.install_gaming = !self.cfg.install_gaming,
            1 => self.cfg.install_steam = !self.cfg.install_steam,
            2 => self.cfg.install_firefox = !self.cfg.install_firefox,
            3 => self.cfg.install_discord = !self.cfg.install_discord,
            4 => self.cfg.install_vesktop = !self.cfg.install_vesktop,
            5 => self.cfg.install_opencode = !self.cfg.install_opencode,
            6 => self.cfg.install_spotify = !self.cfg.install_spotify,
            7 => self.cfg.install_waypaper = !self.cfg.install_waypaper,
            8 => self.cfg.install_fish = !self.cfg.install_fish,
            9 => self.cfg.install_zsh = !self.cfg.install_zsh,
            10 => self.cfg.install_flatpak = !self.cfg.install_flatpak,
            _ => {}
        }
    }

    fn toggle_firmware(&mut self) {
        self.cfg.firmware = match self.cfg.firmware {
            Firmware::Uefi => Firmware::Bios,
            Firmware::Bios => Firmware::Uefi,
        };
    }

    fn select_disk(&mut self) -> bool {
        let Some(d) = self.disks.get(self.cursor) else {
            self.error = Some("no disk selected".into());
            return false;
        };
        self.cfg.disk = d.path.clone();
        self.cfg.disk_model = d.model.clone();
        self.cfg.disk_size_gib = d.size_bytes as f64 / (1024.0 * 1024.0 * 1024.0);
        true
    }

    // ── mouse ───────────────────────────────────────────────────────────

    /// How many entries the current step can select.
    fn selection_len(&self) -> usize {
        match self.step {
            Step::Disk => self.disks.len(),
            Step::Filesystem => Filesystem::ALL.len(),
            Step::Encryption => Encryption::ALL.len(),
            Step::Options => self.options().len(),
            Step::Extras => self.extras().len(),
            Step::Locale | Step::User => self.field_count(self.step),
            _ => 0,
        }
    }

    /// The currently selected entry on the current step.
    fn selection_index(&self) -> usize {
        match self.step {
            Step::Locale | Step::User => self.field,
            _ => self.cursor,
        }
    }

    fn set_selection(&mut self, idx: usize) {
        match self.step {
            Step::Locale | Step::User => self.field = idx,
            _ => self.cursor = idx,
        }
    }

    /// Mouse wheel movement — scroll the selection up (negative) or down.
    pub fn scroll_selection(&mut self, delta: i32) {
        if self.editing {
            return;
        }
        let n = self.selection_len();
        if n == 0 {
            return;
        }
        let cur = self.selection_index() as i64;
        let next = (cur + delta as i64).clamp(0, n as i64 - 1) as usize;
        self.set_selection(next);
    }

    /// Mouse click inside a rendered list moves the selection to that row.
    pub fn click_select(&mut self, x: u16, y: u16) {
        let Some(area) = self.list_area else {
            return;
        };
        if x < area.x || x >= area.x + area.width || y < area.y || y >= area.y + area.height {
            return;
        }
        let row = (y - area.y) as usize;
        let n = self.selection_len();
        if row >= n {
            return;
        }
        self.set_selection(row);
    }

    /// Move the selection to `row` (the GUI hits rows directly).
    pub fn select_row(&mut self, row: usize) {
        let n = self.selection_len();
        if n == 0 || row >= n {
            return;
        }
        self.set_selection(row);
    }

    /// Begin editing the text field at `i` (the GUI focuses by clicking).
    pub fn focus_field(&mut self, i: usize) {
        if !matches!(self.step, Step::Locale | Step::User | Step::Encryption) {
            return;
        }
        if i >= self.field_count(self.step) {
            return;
        }
        self.field = i;
        self.begin_edit();
    }

    // ── key handling ─────────────────────────────────────────────────────

    pub fn on_key(&mut self, key: KeyEvent) {
        if self.editing {
            self.key_editing(key);
            return;
        }

        match self.step {
            Step::Welcome => self.key_welcome(key),
            Step::Disk => self.key_disk(key),
            Step::Filesystem => self.key_filesystem(key),
            Step::Encryption => self.key_encryption(key),
            Step::Locale | Step::User => self.key_text(key),
            Step::Options => self.key_options(key),
            Step::Extras => self.key_extras(key),
            Step::Summary => self.key_summary(key),
            Step::Install | Step::Done => {}
        }
    }

    fn key_editing(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Enter | KeyCode::Tab => {
                self.commit_field();
                self.advance_field();
            }
            KeyCode::BackTab => {
                self.commit_field();
                self.field = self.field.saturating_sub(1);
            }
            KeyCode::Esc => {
                // Abandon the edit but keep what was already committed.
                self.editing = false;
                self.input.clear();
            }
            KeyCode::Backspace => {
                self.input.pop();
            }
            KeyCode::Char(c) if !key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.input.push(c);
            }
            _ => {}
        }
    }

    fn key_welcome(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Enter | KeyCode::Char(' ') => self.goto(Step::Disk),
            KeyCode::Char('q') => self.should_quit = true,
            _ => {}
        }
    }

    fn key_disk(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => self.cursor = self.cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                if self.cursor + 1 < self.disks.len() {
                    self.cursor += 1;
                }
            }
            KeyCode::Char('f') => self.toggle_firmware(),
            KeyCode::Enter => {
                if self.select_disk() {
                    self.goto(Step::Filesystem);
                }
            }
            KeyCode::Esc => self.goto(Step::Welcome),
            _ => {}
        }
    }

    fn commit_filesystem(&mut self) {
        if let Some(f) = Filesystem::ALL.get(self.cursor) {
            self.cfg.filesystem = *f;
        }
    }

    fn key_filesystem(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => self.cursor = self.cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                if self.cursor + 1 < Filesystem::ALL.len() {
                    self.cursor += 1;
                }
            }
            KeyCode::Enter => {
                self.commit_filesystem();
                self.goto(Step::Encryption);
            }
            KeyCode::Esc => self.goto(Step::Disk),
            _ => {}
        }
    }

    fn commit_encryption(&mut self) {
        if let Some(e) = Encryption::ALL.get(self.cursor) {
            self.cfg.encryption = *e;
        }
    }

    fn key_encryption(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => self.cursor = self.cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                if self.cursor + 1 < Encryption::ALL.len() {
                    self.cursor += 1;
                }
            }
            KeyCode::Enter => {
                self.commit_encryption();
                if self.cfg.encryption == Encryption::Luks
                    && self.cfg.luks_passphrase.len() < 8
                {
                    // Make the user set a passphrase before moving on.
                    self.field = 0;
                    self.begin_edit();
                    self.error =
                        Some("set a LUKS passphrase of at least 8 characters".into());
                } else {
                    self.goto(self.step.next());
                }
            }
            KeyCode::Esc => self.goto(self.step.prev()),
            _ => {}
        }
    }

    fn key_text(&mut self, key: KeyEvent) {
        let n = self.field_count(self.step);
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => self.field = self.field.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                if self.field + 1 < n {
                    self.field += 1;
                }
            }
            KeyCode::Tab => {
                if self.field + 1 < n {
                    self.field += 1;
                }
            }
            KeyCode::BackTab => self.field = self.field.saturating_sub(1),
            KeyCode::Enter => self.begin_edit(),
            KeyCode::Esc => self.goto(self.step.prev()),
            _ => {}
        }
    }

    fn key_options(&mut self, key: KeyEvent) {
        let n = self.options().len();
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => self.cursor = self.cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                if self.cursor + 1 < n {
                    self.cursor += 1;
                }
            }
            KeyCode::Enter | KeyCode::Char(' ') | KeyCode::Left | KeyCode::Right => {
                let i = self.cursor;
                self.toggle_option(i);
            }
            KeyCode::Tab => self.goto(Step::Extras),
            KeyCode::Esc => self.goto(Step::User),
            _ => {}
        }
    }

    fn key_extras(&mut self, key: KeyEvent) {
        let n = self.extras().len();
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => self.cursor = self.cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                if self.cursor + 1 < n {
                    self.cursor += 1;
                }
            }
            KeyCode::Enter | KeyCode::Char(' ') | KeyCode::Left | KeyCode::Right => {
                let i = self.cursor;
                self.toggle_extra(i);
            }
            KeyCode::Tab => self.goto(Step::Summary),
            KeyCode::Esc => self.goto(Step::Options),
            _ => {}
        }
    }

    fn key_summary(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Enter => {
                if !self.yes && !self.confirm_wipe {
                    // One deliberate press to arm, one to fire.
                    self.confirm_wipe = true;
                } else {
                    self.start_install();
                }
            }
            KeyCode::Esc => self.goto(Step::Extras),
            _ => {}
        }
    }

    // ── for the UI ───────────────────────────────────────────────────────

    pub fn warnings(&self) -> Vec<String> {
        self.cfg.validate()
    }

    /// The kernel command line we are about to install, for the summary page.
    pub fn cmdline_preview(&self) -> String {
        // No UUID is known before partitioning, so show a placeholder.
        let uuid = if self.cfg.encryption == Encryption::Luks {
            "<luks-uuid>"
        } else {
            "<root-uuid>"
        };
        crate::bootloader::kernel_cmdline(&self.cfg, uuid)
    }
}
