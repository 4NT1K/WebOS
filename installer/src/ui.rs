//! Drawing the wizard.
//!
//! Nothing here owns state: every page is a pure function of [`App`]. The
//! palette lives in `theme.rs`; if a colour changes there, it changes here.

use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Gauge, List, ListItem, Paragraph, Wrap};
use ratatui::Frame;

use crate::app::{App, Step};
use crate::config::{Encryption, Filesystem};
use crate::theme;

/// Entry point, called once per frame.
pub fn draw(f: &mut Frame, app: &mut App) {
    // Paint the whole screen black first; the terminal may be any colour.
    f.render_widget(Block::default().style(theme::base()), f.area());

    match app.step {
        Step::Install | Step::Done => draw_install(f, app),
        _ => draw_wizard(f, app),
    }
}

// ────────────────────────────────────────────────────────────── the wizard ────

fn draw_wizard(f: &mut Frame, app: &mut App) {
    let area = f.area();
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(6),
            Constraint::Length(2),
        ])
        .split(area);

    draw_header(f, rows[0], app, None);

    let cols = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Length(22), Constraint::Min(40)])
        .split(rows[1]);

    draw_sidebar(f, cols[0], app);
    draw_page(f, cols[1], app);
    draw_footer(f, rows[2], footer_keys(app.step), app.error.as_deref());
}

fn draw_header(f: &mut Frame, area: Rect, app: &App, phase: Option<&str>) {
    let left = Line::from(vec![
        Span::styled("WEBOS", theme::accent_bold()),
        Span::styled("OS", theme::title()),
        Span::styled("  installer", theme::dim()),
    ]);

    let right_text = match phase {
        Some(p) => format!("{p}  "),
        None => format!("{}/8  ", app.step.index().min(7) + 1),
    };

    let block = Block::default()
        .borders(Borders::BOTTOM)
        .border_style(Style::default().fg(theme::BORDER));
    let inner = block.inner(area);
    f.render_widget(block, area);

    let cols = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Min(20), Constraint::Length(right_text.len() as u16 + 2)])
        .split(inner);

    f.render_widget(Paragraph::new(left), cols[0]);
    f.render_widget(
        Paragraph::new(Line::from(Span::styled(right_text, theme::dim())))
            .alignment(ratatui::layout::Alignment::Right),
        cols[1],
    );
}

fn draw_sidebar(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let mut lines: Vec<Line> = Vec::new();
    for step in Step::STEPS {
        let here = step == app.step;
        let done = step.index() < app.step.index();
        let marker = if here {
            "▸"
        } else if done {
            "✓"
        } else {
            "·"
        };
        let style = if here {
            theme::accent_bold()
        } else if done {
            theme::good()
        } else {
            theme::faint()
        };
        lines.push(Line::from(vec![
            Span::styled(format!(" {marker} "), style),
            Span::styled(step.title().to_string(), style),
        ]));
    }

    f.render_widget(Paragraph::new(lines), inner);
}

fn draw_page(f: &mut Frame, area: Rect, app: &mut App) {
    match app.step {
        Step::Welcome => page_welcome(f, area, app),
        Step::Disk => page_disk(f, area, app),
        Step::Filesystem => page_filesystem(f, area, app),
        Step::Encryption => page_encryption(f, area, app),
        Step::Locale | Step::User => page_text(f, area, app),
        Step::Options => page_options(f, area, app),
        Step::Summary => page_summary(f, area, app),
        Step::Install | Step::Done => {}
    }
}

fn page_welcome(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Welcome");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let mut lines: Vec<Line> = Vec::new();
    lines.push(Line::from(""));
    for l in theme::LOGO {
        lines.push(Line::from(Span::styled(l.to_string(), theme::accent_bold())));
    }
    lines.push(Line::from(""));
    lines.push(Line::from(Span::styled(
        "  A lightweight Gentoo-based gaming system.",
        theme::base(),
    )));
    lines.push(Line::from(""));
    lines.push(Line::from(Span::styled(
        "  This will erase the disk you choose and install WebOS on it.",
        theme::warn(),
    )));
    lines.push(Line::from(Span::styled(
        "  Nothing is written until you confirm the summary.",
        theme::dim(),
    )));
    lines.push(Line::from(""));

    if app.disks.is_empty() {
        lines.push(Line::from(Span::styled(
            "  No installable disks were found. Attach one and restart.",
            theme::urgent(),
        )));
    } else {
        lines.push(Line::from(Span::styled(
            format!("  {} disk(s) detected.", app.disks.len()),
            theme::good(),
        )));
    }

    if app.dry_run {
        lines.push(Line::from(""));
        lines.push(Line::from(Span::styled(
            "  DRY RUN — no command will actually run.",
            theme::warn(),
        )));
    }

    f.render_widget(Paragraph::new(lines).wrap(Wrap { trim: false }), inner);
}

fn page_disk(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Choose the disk to install onto");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(4), Constraint::Length(3)])
        .split(inner);

    app.list_area = Some(rows[0]);

    if app.disks.is_empty() {
        f.render_widget(
            Paragraph::new(Line::from(Span::styled(
                "no candidate disks",
                theme::urgent(),
            ))),
            rows[0],
        );
    } else {
        let items: Vec<ListItem> = app
            .disks
            .iter()
            .enumerate()
            .map(|(i, d)| {
                let line = Line::from(vec![
                    Span::styled(format!("{:<14}", d.path), theme::base()),
                    Span::styled(format!("{:>10}  ", d.human_size()), theme::dim()),
                    Span::styled(format!("{:<10} ", d.kind()), theme::faint()),
                    Span::styled(d.model.clone(), theme::dim()),
                ]);
                let item = ListItem::new(line);
                if i == app.cursor {
                    item.style(theme::selected())
                } else {
                    item
                }
            })
            .collect();
        f.render_widget(List::new(items), rows[0]);
    }

    let info = Line::from(vec![
        Span::styled("firmware: ", theme::dim()),
        Span::styled(app.cfg.firmware.label().to_string(), theme::base()),
        Span::styled("   (f to change)", theme::faint()),
    ]);
    f.render_widget(Paragraph::new(info), rows[1]);
}

fn page_filesystem(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Filesystem");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(5), Constraint::Min(2)])
        .split(inner);

    app.list_area = Some(rows[0]);

    let items: Vec<ListItem> = Filesystem::ALL
        .iter()
        .enumerate()
        .map(|(i, fs)| {
            let item = ListItem::new(Line::from(Span::styled(
                fs.label().to_string(),
                theme::base(),
            )));
            if i == app.cursor {
                item.style(theme::selected())
            } else {
                item
            }
        })
        .collect();
    f.render_widget(List::new(items), rows[0]);

    if let Some(fs) = Filesystem::ALL.get(app.cursor) {
        f.render_widget(
            Paragraph::new(Line::from(Span::styled(fs.note().to_string(), theme::dim())))
                .wrap(Wrap { trim: true }),
            rows[1],
        );
    }
}

fn page_encryption(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Encryption");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let has_field = app.cfg.encryption == Encryption::Luks;
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(4),
            Constraint::Length(if has_field { 4 } else { 0 }),
            Constraint::Min(1),
        ])
        .split(inner);

    app.list_area = Some(rows[0]);

    let items: Vec<ListItem> = Encryption::ALL
        .iter()
        .enumerate()
        .map(|(i, e)| {
            let item = ListItem::new(Line::from(Span::styled(
                e.label().to_string(),
                theme::base(),
            )));
            if i == app.cursor {
                item.style(theme::selected())
            } else {
                item
            }
        })
        .collect();
    f.render_widget(List::new(items), rows[0]);

    if has_field {
        let line = Line::from(vec![
            Span::styled("Passphrase: ", theme::dim()),
            Span::styled(app.field_display(Step::Encryption, 0), theme::base()),
        ]);
        let mut p = Paragraph::new(line);
        if app.editing && app.field == 0 {
            p = p.style(theme::accent());
        }
        f.render_widget(p, rows[1]);
    }

    f.render_widget(
        Paragraph::new(Line::from(Span::styled(
            "LUKS2, aes-xts-plain64, argon2id. The passphrase is required at every boot.",
            theme::faint(),
        )))
        .wrap(Wrap { trim: true }),
        rows[2],
    );
}

fn page_text(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel(app.step.title());
    let inner = block.inner(area);
    f.render_widget(block, area);

    let n = app.field_count(app.step);
    let mut lines: Vec<Line> = Vec::new();
    for i in 0..n {
        let active = i == app.field;
        let label = app.field_label(app.step, i);
        let value = app.field_display(app.step, i);

        let label_style = if active {
            theme::accent_bold()
        } else {
            theme::dim()
        };
        let value_style = if active && app.editing {
            theme::accent()
        } else {
            theme::base()
        };

        lines.push(Line::from(vec![
            Span::styled(format!("{label:<16}"), label_style),
            Span::styled(if value.is_empty() && active && app.editing {
                "█".to_string()
            } else if active && app.editing {
                format!("{value}█")
            } else if value.is_empty() {
                "—".to_string()
            } else {
                value
            }, value_style),
        ]));

        if active {
            let help = app.field_help(app.step, i);
            if !help.is_empty() {
                lines.push(Line::from(Span::styled(
                    format!("{:<16}{help}", ""),
                    theme::faint(),
                )));
            }
        }
    }

    f.render_widget(Paragraph::new(lines).wrap(Wrap { trim: false }), inner);
}

fn page_options(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Options");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(4), Constraint::Length(2)])
        .split(inner);

    app.list_area = Some(rows[0]);

    let items: Vec<ListItem> = app
        .options()
        .iter()
        .enumerate()
        .map(|(i, (label, value))| {
            let line = Line::from(vec![
                Span::styled(format!("{label:<22}"), theme::dim()),
                Span::styled(value.clone(), theme::base()),
            ]);
            let item = ListItem::new(line);
            if i == app.cursor {
                item.style(theme::selected())
            } else {
                item
            }
        })
        .collect();
    f.render_widget(List::new(items), rows[0]);

    let help = if app.cursor == 1 {
        app.cfg.profile.note().to_string()
    } else {
        "Enter/Space cycles a value.".to_string()
    };
    f.render_widget(
        Paragraph::new(Line::from(Span::styled(help, theme::faint()))).wrap(Wrap { trim: true }),
        rows[1],
    );
}

fn page_summary(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Summary");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(6), Constraint::Length(4)])
        .split(inner);

    let c = &app.cfg;
    let mut lines: Vec<Line> = Vec::new();
    let row = |k: &str, v: String, style: Style, lines: &mut Vec<Line>| {
        lines.push(Line::from(vec![
            Span::styled(format!("  {k:<18}"), theme::dim()),
            Span::styled(v, style),
        ]));
    };

    row("Disk", format!("{}  ({})", c.disk, c.disk_model), theme::base(), &mut lines);
    row(
        "Firmware",
        c.firmware.label().to_string(),
        theme::base(),
        &mut lines,
    );
    row("Layout", c.layout_summary(), theme::base(), &mut lines);
    row(
        "Profile",
        c.profile.label().to_string(),
        theme::base(),
        &mut lines,
    );
    row(
        "User",
        format!("{} (host {})", c.username, c.hostname),
        theme::base(),
        &mut lines,
    );
    row(
        "Region",
        format!("{} · {} · {}", c.timezone, c.locale, c.keymap),
        theme::base(),
        &mut lines,
    );
    row(
        "Gaming",
        if c.install_gaming { "yes" } else { "no" }.to_string(),
        theme::base(),
        &mut lines,
    );
    row(
        "GPU",
        if c.nvidia { "NVIDIA" } else { "Mesa" }.to_string(),
        theme::base(),
        &mut lines,
    );
    row("cmdline", app.cmdline_preview(), theme::faint(), &mut lines);
    lines.push(Line::from(""));

    if app.prefilled {
        lines.push(Line::from(Span::styled(
            "  Loaded from a configuration file.",
            theme::accent(),
        )));
    }

    let warnings = app.warnings();
    for w in &warnings {
        lines.push(Line::from(Span::styled(
            format!("  ! {w}"),
            theme::urgent(),
        )));
    }
    if warnings.is_empty() {
        lines.push(Line::from(Span::styled(
            "  No problems found.",
            theme::good(),
        )));
    }

    f.render_widget(Paragraph::new(lines).wrap(Wrap { trim: false }), rows[0]);

    let prompt = if app.error.is_some() {
        Line::from(Span::styled(
            app.error.clone().unwrap_or_default(),
            theme::urgent(),
        ))
    } else if !warnings.is_empty() {
        Line::from(Span::styled(
            "Fix the problems above before installing (Esc to go back).",
            theme::urgent(),
        ))
    } else if app.confirm_wipe || app.yes {
        Line::from(Span::styled(
            format!("Press Enter again to ERASE {} and install.", app.cfg.disk),
            theme::warn(),
        ))
    } else {
        Line::from(Span::styled(
            "Press Enter to review the final confirmation.",
            theme::dim(),
        ))
    };
    f.render_widget(Paragraph::new(prompt).wrap(Wrap { trim: true }), rows[1]);
}

// ─────────────────────────────────────────────────────────── the install ──────

fn draw_install(f: &mut Frame, app: &mut App) {
    let area = f.area();
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Length(3),
            Constraint::Min(5),
            Constraint::Length(2),
        ])
        .split(area);

    draw_header(f, rows[0], app, Some(&app.phase));

    let ratio = app.progress.clamp(0.0, 1.0) as f64;
    let gauge = Gauge::default()
        .block(panel(""))
        .ratio(ratio)
        .gauge_style(
            Style::default()
                .fg(theme::ACCENT)
                .bg(theme::BASE_SOFT)
                .add_modifier(Modifier::BOLD),
        )
        .label(format!(
            "{:>3.0}%  {}",
            ratio * 100.0,
            if app.phase.is_empty() { "starting" } else { &app.phase }
        ));
    f.render_widget(gauge, rows[1]);

    draw_log(f, rows[2], app);

    if app.step == Step::Done {
        let (style, text) = if app.installed {
            (
                theme::good(),
                "Install complete. Remove the medium and press Enter to reboot.",
            )
        } else {
            (
                theme::urgent(),
                "Install FAILED. The log above says why; press Enter to exit.",
            )
        };
        let mut lines = vec![Line::from(Span::styled(text, style))];
        if let Some(e) = &app.error {
            lines.push(Line::from(Span::styled(e.clone(), theme::dim())));
        }
        lines.push(Line::from(Span::styled(
            format!("log: {}", app.log_path.display()),
            theme::faint(),
        )));
        f.render_widget(
            Paragraph::new(lines).wrap(Wrap { trim: true }),
            rows[3],
        );
    } else {
        f.render_widget(
            Paragraph::new(Line::from(Span::styled(
                "↑↓ scroll   Ctrl-C abort",
                theme::faint(),
            ))),
            rows[3],
        );
    }
}

fn draw_log(f: &mut Frame, area: Rect, app: &mut App) {
    let block = panel("Log");
    let inner = block.inner(area);
    f.render_widget(block, area);

    let height = inner.height as usize;
    let total = app.log.len();
    let start = total.saturating_sub(height).saturating_sub(app.log_offset);

    let lines: Vec<Line> = app
        .log
        .iter()
        .skip(start)
        .take(height)
        .map(|l| {
            let style = if l.starts_with("──") {
                theme::accent()
            } else if l.starts_with("!!") {
                theme::urgent()
            } else if l.starts_with('$') {
                theme::faint()
            } else if l.starts_with("  ") {
                theme::dim()
            } else {
                theme::base()
            };
            Line::from(Span::styled(l.clone(), style))
        })
        .collect();

    f.render_widget(Paragraph::new(lines), inner);
}

// ───────────────────────────────────────────────────────────────── pieces ────

fn panel(title: &str) -> Block<'_> {
    let mut b = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(theme::BORDER))
        .style(theme::base());
    if !title.is_empty() {
        b = b.title(Line::from(Span::styled(format!(" {title} "), theme::dim())));
    }
    b
}

fn draw_footer(f: &mut Frame, area: Rect, keys: &str, error: Option<&str>) {
    let line = if let Some(e) = error {
        Line::from(Span::styled(format!(" {e}"), theme::urgent()))
    } else {
        Line::from(Span::styled(format!(" {keys}"), theme::faint()))
    };
    f.render_widget(Paragraph::new(line), area);
}

fn footer_keys(step: Step) -> &'static str {
    match step {
        Step::Welcome => "Enter begin    q quit    Ctrl-C quit",
        Step::Disk => "↑↓ choose    f firmware    Enter next    Esc back",
        Step::Filesystem => "↑↓ choose    Enter next    Esc back",
        Step::Encryption => "↑↓ choose    Enter next    Esc back",
        Step::Locale | Step::User => {
            "↑↓ field    Enter edit    Tab next    Esc back    Ctrl-C quit"
        }
        Step::Options => "↑↓ choose    Enter/Space cycle    Esc back",
        Step::Summary => "Enter install    Esc back    Ctrl-C quit",
        Step::Install | Step::Done => "↑↓ scroll    Ctrl-C quit",
    }
}
