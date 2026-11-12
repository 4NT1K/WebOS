//! SanusOS installer.
//!
//! A single static binary, a keyboard, and no dependencies beyond a live
//! SanusOS medium. It partitions a disk, unwraps the live filesystem onto it,
//! and configures the result.
//!
//! Design rules:
//!   * Nothing is written to disk until the summary page is confirmed.
//!   * Every command that touches a disk is logged verbatim, and the log is
//!     copied to the new system as /var/log/sanus-install.log.
//!   * The installer never guesses a disk. It must be chosen explicitly.
//!   * `--config file.toml --yes` performs an unattended install from a
//!     recorded configuration, which is how SanusOS CI tests installs.

mod app;
mod bootloader;
mod config;
mod disk;
mod exec;
mod gui;
mod install;
mod rootfs;
mod theme;
mod ui;

use std::io::{self, IsTerminal};
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::Duration;

use anyhow::{Context, Result};
use crossterm::event::{
    self, EnableMouseCapture, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers, MouseButton,
    MouseEvent, MouseEventKind,
};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;

use app::App;
use config::InstallConfig;

const VERSION: &str = env!("CARGO_PKG_VERSION");

const USAGE: &str = "\
SanusOS installer

USAGE:
    sanus-installer [OPTIONS]

OPTIONS:
    -c, --config <FILE>   Load answers from a TOML file and skip those pages
    -y, --yes             Do not prompt for the final confirmation
    -d, --dry-run         Go through the whole wizard, but write nothing
    -l, --log <FILE>      Write the command log to FILE (default: /var/log/sanus-install.log)
        --check           Print what the installer found (disks, firmware, rootfs) and exit
        --gui             Use the windowed egui installer (mouse + keyboard)
    -h, --help            Print this help
    -V, --version         Print the version

KEYS:
    Tab / Shift-Tab   next / previous field
    ↑ ↓ ← →           move the selection
    Enter             confirm the page and continue
    Esc               go back a page
    Ctrl-C            quit without touching the disk

MOUSE:
    Wheel Up/Down    move the selection
    Left click       select the item under the pointer
";

#[derive(Debug, Default)]
struct Args {
    config: Option<PathBuf>,
    yes: bool,
    dry_run: bool,
    log: Option<PathBuf>,
    check: bool,
    gui: bool,
}

fn parse_args() -> Result<Option<Args>> {
    let mut args = Args::default();
    let mut it = std::env::args().skip(1);

    while let Some(a) = it.next() {
        match a.as_str() {
            "-c" | "--config" => {
                args.config = Some(PathBuf::from(it.next().context("--config needs a file")?))
            }
            "-y" | "--yes" => args.yes = true,
            "-d" | "--dry-run" => args.dry_run = true,
            "-l" | "--log" => {
                args.log = Some(PathBuf::from(it.next().context("--log needs a file")?))
            }
            "--check" => args.check = true,
            "--gui" => args.gui = true,
            "-h" | "--help" => {
                print!("{USAGE}");
                return Ok(None);
            }
            "-V" | "--version" => {
                println!("sanus-installer {VERSION}");
                return Ok(None);
            }
            other => anyhow::bail!("unknown argument: {other}\n\n{USAGE}"),
        }
    }
    Ok(Some(args))
}

fn main() -> ExitCode {
    match run() {
        Ok(code) => code,
        Err(e) => {
            // Make sure we never leave the terminal in raw mode on the way out.
            let _ = restore_terminal();
            eprintln!("sanus-installer: {e:#}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<ExitCode> {
    let args = match parse_args()? {
        Some(a) => a,
        None => return Ok(ExitCode::SUCCESS),
    };

    if args.check {
        return preflight();
    }

    if unsafe { libc::geteuid() } != 0 {
        anyhow::bail!("sanus-installer must run as root");
    }

    let mut app = App::new(args.dry_run, args.yes, args.log.clone())?;

    if let Some(path) = &args.config {
        let text = std::fs::read_to_string(path)
            .with_context(|| format!("reading {}", path.display()))?;
        let cfg: InstallConfig = toml::from_str(&text)
            .with_context(|| format!("parsing {}", path.display()))?;
        app.apply_config(cfg)?;
    }

    install_panic_hook();

    if args.gui {
        // The windowed installer owns its own rendering; no terminal needed.
        let app = gui::run_gui(app)?;
        return Ok(if app.installed {
            ExitCode::SUCCESS
        } else {
            ExitCode::from(2)
        });
    }

    if !io::stdin().is_terminal() || !io::stdout().is_terminal() {
        anyhow::bail!(
            "sanus-installer needs a terminal. Use --check to inspect this machine,\n\
             --gui for the windowed installer, or --config FILE --yes for an unattended install."
        );
    }

    setup_terminal()?;
    let result = event_loop(&mut app);
    restore_terminal()?;
    result?;

    if app.installed {
        Ok(ExitCode::SUCCESS)
    } else {
        Ok(ExitCode::from(2))
    }
}

fn preflight() -> Result<ExitCode> {
    println!("sanus-installer {VERSION} — preflight\n");

    println!("firmware      : {}", if disk::is_efi() { "UEFI" } else { "BIOS/legacy" });
    println!("root fs       : {}", rootfs::describe());
    match rootfs::locate() {
        Ok(src) => println!("install source: {src}"),
        Err(e) => println!("install source: NOT FOUND ({e})"),
    }
    println!("target root   : {}", install::TARGET);
    println!();

    let disks = disk::enumerate();
    if disks.is_empty() {
        println!("no candidate disks found");
    } else {
        println!("{:<16} {:>10}  MODEL", "DEVICE", "SIZE");
        for d in &disks {
            println!("{:<16} {:>10}  {}", d.path, d.human_size(), d.model);
        }
    }

    let missing = exec::missing_tools(&[
        "sgdisk", "mkfs.btrfs", "mkfs.ext4", "mkfs.xfs", "mkswap", "mount",
        "blkid", "rsync", "tar", "chroot", "grub-install",
    ]);
    if !missing.is_empty() {
        println!("\nwarning: missing tools: {}", missing.join(", "));
    }
    Ok(ExitCode::SUCCESS)
}

fn setup_terminal() -> Result<()> {
    enable_raw_mode().context("enabling raw mode")?;
    let mut out = io::stdout();
    execute!(out, EnterAlternateScreen).context("entering alternate screen")?;
    execute!(out, EnableMouseCapture).context("enabling mouse capture")?;
    Ok(())
}

fn restore_terminal() -> Result<()> {
    let mut out = io::stdout();
    let _ = execute!(out, LeaveAlternateScreen);
    let _ = disable_raw_mode();
    Ok(())
}

fn install_panic_hook() {
    let prev = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        let _ = restore_terminal();
        prev(info);
    }));
}

fn event_loop(app: &mut App) -> Result<()> {
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    terminal.clear()?;

    loop {
        app.tick();

        terminal.draw(|f| ui::draw(f, app))?;

        if app.should_quit {
            return Ok(());
        }

        if event::poll(Duration::from_millis(80))? {
            match event::read()? {
                Event::Key(key) if key.kind != KeyEventKind::Release => handle_key(app, key),
                Event::Mouse(m) => handle_mouse(app, m),
                Event::Resize(_, _) => {}
                _ => {}
            }
        }
    }
}

fn handle_mouse(app: &mut App, m: MouseEvent) {
    if app.installing {
        // Only scrolling is allowed while the worker owns the disk.
        match m.kind {
            MouseEventKind::ScrollUp => app.scroll_log(-1),
            MouseEventKind::ScrollDown => app.scroll_log(1),
            _ => {}
        }
        return;
    }
    if app.done {
        return;
    }

    match m.kind {
        MouseEventKind::ScrollUp => app.scroll_selection(-1),
        MouseEventKind::ScrollDown => app.scroll_selection(1),
        MouseEventKind::Down(MouseButton::Left) => app.click_select(m.column, m.row),
        _ => {}
    }
}

fn handle_key(app: &mut App, key: KeyEvent) {
    // Global keys first.
    match (key.code, key.modifiers) {
        (KeyCode::Char('c'), KeyModifiers::CONTROL) => {
            if !app.installing {
                app.should_quit = true;
            }
            return;
        }
        (KeyCode::Char('q'), KeyModifiers::ALT) => {
            if !app.installing {
                app.should_quit = true;
            }
            return;
        }
        _ => {}
    }

    if app.installing {
        // Only scrolling is allowed while the worker owns the disk.
        match key.code {
            KeyCode::Up => app.scroll_log(-1),
            KeyCode::Down => app.scroll_log(1),
            KeyCode::PageUp => app.scroll_log(-10),
            KeyCode::PageDown => app.scroll_log(10),
            _ => {}
        }
        return;
    }

    if app.done {
        match key.code {
            KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q') => app.should_quit = true,
            _ => {}
        }
        return;
    }

    app.on_key(key);
}
