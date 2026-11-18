//! The windowed installer, drawn with egui.
//!
//! This is the GUI face of the same wizard the TUI drives: it owns an
//! [`App`], feeds it synthetic crossterm key events, and renders its pages
//! with egui. Nothing here writes to disk — [`App`] still owns the worker.

use std::cell::RefCell;
use std::rc::Rc;

use crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use egui::{
    Align2, CentralPanel, Context, FontId, Frame, Key, Modifiers, Pos2, Rect, Sense,
    Stroke, StrokeKind, Ui, ViewportCommand,
};

use crate::app::{App, Step};
use crate::config::{Encryption, Filesystem};
use crate::theme;

/// How the last rendered list panel looked, for click hit-testing.
#[derive(Clone)]
struct ListHit {
    rect: Rect,
    rows: usize,
    row_h: f32,
}

pub struct InstallerGui {
    app: Rc<RefCell<App>>,
    list: RefCell<Option<ListHit>>,
    fields: RefCell<Vec<Rect>>,
    pub closed: bool,
}

impl InstallerGui {
    pub fn new(app: App) -> Self {
        Self {
            app: Rc::new(RefCell::new(app)),
            list: RefCell::new(None),
            fields: RefCell::new(Vec::new()),
            closed: false,
        }
    }

    fn app(&self) -> &Rc<RefCell<App>> {
        &self.app
    }

    // ── input ────────────────────────────────────────────────────────────

    fn on_input(&mut self, ctx: &Context) {
        if ctx.input(|i| i.viewport().close_requested()) {
            self.closed = true;
            self.app().borrow_mut().should_quit = true;
            ctx.send_viewport_cmd(ViewportCommand::Close);
            return;
        }

        let mut app = self.app().borrow_mut();
        let events = ctx.input(|i| i.raw.events.clone());

        for ev in events {
            match ev {
                egui::Event::Key {
                    key,
                    pressed: true,
                    repeat,
                    modifiers,
                    ..
                } => {
                    if repeat {
                        continue;
                    }
                    if modifiers.ctrl && matches!(key, Key::C | Key::Q) {
                        app.should_quit = true;
                        continue;
                    }
                    if let Some((code, mods)) = map_key(key, modifiers) {
                        app.on_key(KeyEvent::new_with_kind(code, mods, KeyEventKind::Press));
                    }
                }
                egui::Event::Text(t) | egui::Event::Paste(t) => {
                    for c in t.chars() {
                        app.on_key(KeyEvent::new_with_kind(
                            KeyCode::Char(c),
                            KeyModifiers::NONE,
                            KeyEventKind::Press,
                        ));
                    }
                }
                egui::Event::MouseWheel {
                    delta, modifiers, ..
                } => {
                    if modifiers.ctrl || delta.y.abs() < 0.5 {
                        continue;
                    }
                    // egui's positive delta means the content moves down, i.e.
                    // the wheel went up — the same direction as the TUI's
                    // ScrollUp, which moves the selection up.
                    let dy = -(delta.y.round() as i32);
                    if app.installing {
                        app.scroll_log(dy);
                    } else {
                        app.scroll_selection(dy);
                    }
                }
                egui::Event::PointerButton {
                    pos,
                    button: egui::PointerButton::Primary,
                    pressed: true,
                    ..
                } => {
                    let list = self.list.borrow().as_ref().cloned();
                    if let Some(l) = list {
                        if l.rect.contains(pos) && l.rows > 0 {
                            let row = (((pos.y - l.rect.min.y) / l.row_h).floor() as usize)
                                .min(l.rows - 1);
                            app.select_row(row);
                            if app.step == Step::Options {
                                // Clicking an option toggles it, the way a
                                // CachyOS-style installer would.
                                app.on_key(KeyEvent::new_with_kind(
                                    KeyCode::Enter,
                                    KeyModifiers::NONE,
                                    KeyEventKind::Press,
                                ));
                            }
                            continue;
                        }
                    }
                    let fields = self.fields.borrow().clone();
                    for (i, r) in fields.iter().enumerate() {
                        if r.contains(pos) {
                            app.focus_field(i);
                            break;
                        }
                    }
                }
                _ => {}
            }
        }

        if app.should_quit {
            ctx.send_viewport_cmd(ViewportCommand::Close);
        }
        if app.installing {
            // Keep the progress bar and log moving while the worker runs.
            ctx.request_repaint();
        }
    }

    // ── drawing ──────────────────────────────────────────────────────────

    fn draw(&self, ctx: &Context) {
        CentralPanel::default().frame(Frame::NONE).show(ctx, |ui| {
            let screen = ui.max_rect();
            ui.painter().rect_filled(screen, 0.0, theme::E_BASE);
            *self.list.borrow_mut() = None;
            self.fields.borrow_mut().clear();

            ui.add_space(24.0);
            self.header(ui);
            ui.add_space(12.0);

            {
                let app = self.app().borrow();
                match app.step {
                    Step::Welcome => self.page_welcome(ui, &app),
                    Step::Disk => self.page_disk(ui, &app),
                    Step::Filesystem => self.page_filesystem(ui, &app),
                    Step::Encryption => self.page_encryption(ui, &app),
                    Step::Locale | Step::User => self.page_text(ui, &app),
                    Step::Options => self.page_options(ui, &app),
                    Step::Extras => self.page_extras(ui, &app),
                    Step::Dotfiles => self.page_dotfiles(ui, &app),
                    Step::Summary => self.page_summary(ui, &app),
                    Step::Install => self.page_install(ui, &app),
                    Step::Done => self.page_done(ui, &app),
                }
            }

            self.footer(ui, screen);
        });
    }

    fn header(&self, ui: &mut Ui) {
        let app = self.app().borrow();
        let title = format!("WebOS Installer  ·  {}", app.step.title());
        ui.label(
            egui::RichText::new(title)
                .color(theme::E_TEXT)
                .size(20.0)
                .strong(),
        );
        ui.add_space(6.0);

        let total = Step::STEPS.len();
        let frac = (app.step.index() as f32 / (total - 1) as f32).clamp(0.0, 1.0);
        let rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(ui.available_width(), 4.0));
        ui.painter().rect_filled(rect, 2.0, theme::E_BASE_SOFT);
        if frac > 0.0 {
            ui.painter().rect_filled(
                Rect::from_min_size(rect.min, egui::Vec2::new(rect.width() * frac, 4.0)),
                2.0,
                theme::E_TEXT,
            );
        }
        ui.add_space(4.0);
        ui.label(
            egui::RichText::new(format!(
                "step {} of {}",
                app.step.index() + 1,
                total
            ))
            .color(theme::E_TEXT_FAINT)
            .size(11.0),
        );
    }

    fn footer(&self, ui: &mut Ui, screen: Rect) {
        let app = self.app().borrow();

        let hint = match app.step {
            Step::Welcome => "Enter  continue",
            Step::Disk => "↑↓  select · Enter  continue · Esc  back · f  firmware",
            Step::Filesystem => "↑↓  select · Enter  continue · Esc  back",
            Step::Encryption => "↑↓  select · Enter  continue · Esc  back",
            Step::Locale | Step::User => "Tab  next field · Enter  edit · Esc  back",
            Step::Options => "click / ↑↓  toggle · Enter  continue · Esc  back",
            Step::Extras => "click / ↑↓  toggle · Enter  continue · Esc  back",
            Step::Dotfiles => "click / ↑↓  choose dotfiles · Enter  continue · Esc  back",
            Step::Summary => "Enter  install · Esc  back",
            Step::Install => "installing — the disk is being written",
            Step::Done => "installation finished",
        };

        let footer_rect = Rect::from_min_size(
            Pos2::new(screen.min.x, screen.max.y - 48.0),
            egui::Vec2::new(screen.width(), 48.0),
        );
        ui.painter()
            .rect_filled(footer_rect, 0.0, theme::E_BASE_SOFT);
        ui.painter().hline(
            egui::Rangef::new(footer_rect.min.x, footer_rect.max.x),
            footer_rect.min.y,
            Stroke::new(1.0_f32, theme::E_BORDER),
        );

        // Buttons sit on the right; the hint lives on the left.
        let button_h = 34.0;
        let button_w = 130.0;
        let gap = 10.0;

        let next_label = match app.step {
            Step::Summary => {
                if app.confirm_wipe {
                    "Confirm install"
                } else {
                    "Install"
                }
            }
            Step::Done => "Quit",
            _ => "Next",
        };

        let show_back = !matches!(app.step, Step::Welcome | Step::Install | Step::Done);

        let mut x = screen.max.x - button_w;
        let y = footer_rect.min.y + (footer_rect.height() - button_h) / 2.0;

        // Next / Install / Quit
        let next_rect = Rect::from_min_size(Pos2::new(x, y), egui::Vec2::new(button_w, button_h));
        let primary = matches!(app.step, Step::Summary | Step::Done);
        if self.button(ui, next_rect, next_label, primary) {
            let mut app = self.app().borrow_mut();
            if app.step == Step::Done {
                app.should_quit = true;
            } else {
                app.on_key(KeyEvent::new_with_kind(
                    KeyCode::Enter,
                    KeyModifiers::NONE,
                    KeyEventKind::Press,
                ));
            }
        }
        x -= button_w + gap;

        if show_back {
            let back_rect =
                Rect::from_min_size(Pos2::new(x, y), egui::Vec2::new(button_w, button_h));
            if self.button(ui, back_rect, "Back", false) {
                let mut app = self.app().borrow_mut();
                app.on_key(KeyEvent::new_with_kind(
                    KeyCode::Esc,
                    KeyModifiers::NONE,
                    KeyEventKind::Press,
                ));
            }
        }

        // Hint + error, left-aligned.
        let mut text = hint.to_string();
        if let Some(err) = &app.error {
            text = format!("{text}    ·    {err}");
        }
        ui.painter().text(
            Pos2::new(footer_rect.min.x + 16.0, footer_rect.center().y),
            Align2::LEFT_CENTER,
            text,
            FontId::proportional(13.0),
            if app.error.is_some() {
                theme::E_URGENT
            } else {
                theme::E_TEXT_DIM
            },
        );
    }

    fn button(&self, ui: &mut Ui, rect: Rect, label: &str, primary: bool) -> bool {
        ui.allocate_new_ui(egui::UiBuilder::new().max_rect(rect), |ui| {
            let (fill, text_color, stroke) = if primary {
                (theme::E_TEXT, theme::E_BASE, theme::E_TEXT)
            } else {
                (theme::E_BASE_SOFT, theme::E_TEXT, theme::E_BORDER)
            };
            let btn = egui::Button::new(
                egui::RichText::new(label)
                    .color(text_color)
                    .strong(),
            )
            .fill(fill)
            .stroke(Stroke::new(1.0_f32, stroke))
            .corner_radius(8.0);
            ui.add_sized(rect.size(), btn).clicked()
        })
        .inner
    }

    // ── pages ────────────────────────────────────────────────────────────

    fn page_welcome(&self, ui: &mut Ui, app: &App) {
        ui.add_space(28.0);
        for line in theme::LOGO {
            ui.label(
                egui::RichText::new(line)
                    .color(theme::E_ACCENT)
                    .size(18.0)
                    .strong(),
            );
        }
        ui.add_space(16.0);
        ui.label(
            egui::RichText::new("A lightweight Gentoo-based gaming system.")
                .color(theme::E_TEXT)
                .size(16.0),
        );
        ui.add_space(8.0);
        ui.label(
            egui::RichText::new(
                "This will erase the disk you choose and install WebOS on it.",
            )
            .color(theme::E_WARN),
        );
        ui.label(
            egui::RichText::new("Nothing is written until you confirm the summary.")
                .color(theme::E_TEXT_DIM),
        );
        ui.add_space(8.0);
        if app.disks.is_empty() {
            ui.label(
                egui::RichText::new(
                    "No installable disks were found. Attach one and restart.",
                )
                .color(theme::E_URGENT)
                .strong(),
            );
        } else {
            ui.label(
                egui::RichText::new(format!("{} disk(s) found.", app.disks.len()))
                    .color(theme::E_GOOD),
            );
        }
    }

    fn page_disk(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let row_h = 52.0;

        if app.disks.is_empty() {
            ui.label(
                egui::RichText::new("no candidate disks")
                    .color(theme::E_URGENT)
                    .strong(),
            );
            return;
        }

        let n = app.disks.len();
        let list_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h * n as f32));
        *self.list.borrow_mut() = Some(ListHit {
            rect: list_rect,
            rows: n,
            row_h,
        });

        for (i, d) in app.disks.iter().enumerate() {
            let rect = Rect::from_min_size(
                ui.cursor().min + egui::Vec2::new(0.0, i as f32 * row_h),
                egui::Vec2::new(w, row_h - 6.0),
            );
            let sel = i == app.cursor;
            let resp = ui.allocate_rect(rect, Sense::click());
            let stroke = if sel { theme::E_TEXT } else { theme::E_BORDER };
            ui.painter().rect(
                rect,
                8.0,
                if sel { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
                Stroke::new(if sel { 2.0 } else { 1.0_f32 }, stroke),
                StrokeKind::Inside,
            );
            let pad = 12.0;
            ui.painter().text(
                Pos2::new(rect.min.x + pad, rect.min.y + 8.0),
                Align2::LEFT_TOP,
                format!("{}    {}", d.path, d.human_size()),
                FontId::proportional(15.0),
                theme::E_TEXT,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + pad, rect.min.y + 30.0),
                Align2::LEFT_TOP,
                format!("{} {}", d.kind(), d.model),
                FontId::proportional(12.0),
                if resp.hovered() {
                    theme::E_TEXT
                } else {
                    theme::E_TEXT_DIM
                },
            );
        }
        ui.add_space(8.0);
        ui.label(
            egui::RichText::new(format!("firmware: {}", app.cfg.firmware.label()))
                .color(theme::E_TEXT_FAINT)
                .size(12.0),
        );
    }

    fn page_filesystem(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let row_h = 62.0;
        let all = Filesystem::ALL;
        let n = all.len();

        let list_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h * n as f32));
        *self.list.borrow_mut() = Some(ListHit {
            rect: list_rect,
            rows: n,
            row_h,
        });

        for (i, f) in all.iter().enumerate() {
            let rect = Rect::from_min_size(
                ui.cursor().min + egui::Vec2::new(0.0, i as f32 * row_h),
                egui::Vec2::new(w, row_h - 8.0),
            );
            let sel = i == app.cursor;
            let resp = ui.allocate_rect(rect, Sense::click());
            ui.painter().rect(
                rect,
                8.0,
                if sel { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
                Stroke::new(if sel { 2.0 } else { 1.0_f32 }, if sel { theme::E_TEXT } else { theme::E_BORDER }),
                StrokeKind::Inside,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + 8.0),
                Align2::LEFT_TOP,
                f.label(),
                FontId::proportional(16.0),
                theme::E_TEXT,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + 30.0),
                Align2::LEFT_TOP,
                f.note(),
                FontId::proportional(12.0),
                if resp.hovered() { theme::E_TEXT } else { theme::E_TEXT_DIM },
            );
        }
    }

    fn page_encryption(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let row_h = 62.0;
        let all = Encryption::ALL;
        let n = all.len();

        let list_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h * n as f32));
        *self.list.borrow_mut() = Some(ListHit {
            rect: list_rect,
            rows: n,
            row_h,
        });

        for (i, e) in all.iter().enumerate() {
            let rect = Rect::from_min_size(
                ui.cursor().min + egui::Vec2::new(0.0, i as f32 * row_h),
                egui::Vec2::new(w, row_h - 8.0),
            );
            let sel = i == app.cursor;
            ui.allocate_rect(rect, Sense::click());
            ui.painter().rect(
                rect,
                8.0,
                if sel { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
                Stroke::new(if sel { 2.0 } else { 1.0_f32 }, if sel { theme::E_TEXT } else { theme::E_BORDER }),
                StrokeKind::Inside,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + 8.0),
                Align2::LEFT_TOP,
                e.label(),
                FontId::proportional(16.0),
                theme::E_TEXT,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + 30.0),
                Align2::LEFT_TOP,
                e.note(),
                FontId::proportional(12.0),
                theme::E_TEXT_DIM,
            );
        }

        if app.cfg.encryption == Encryption::Luks {
            ui.add_space(16.0);
            let field_rect = Rect::from_min_size(
                ui.cursor().min,
                egui::Vec2::new(w, 52.0),
            );
            let sel = app.field == 0;
            self.field_row(ui, field_rect, "Passphrase", &app.field_display(Step::Encryption, 0), sel);
            self.fields.borrow_mut().push(field_rect);
            ui.label(
                egui::RichText::new(app.field_help(Step::Encryption, 0))
                    .color(theme::E_TEXT_FAINT)
                    .size(12.0),
            );
        }
    }

    fn page_text(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let n = app.field_count(app.step);

        for i in 0..n {
            let rect = Rect::from_min_size(
                ui.cursor().min,
                egui::Vec2::new(w, 56.0),
            );
            let sel = i == app.field;
            self.field_row(ui, rect, app.field_label(app.step, i), &app.field_display(app.step, i), sel);
            self.fields.borrow_mut().push(rect);
            ui.add_space(4.0);
            ui.painter().text(
                Pos2::new(rect.min.x + 12.0, ui.cursor().min.y),
                Align2::LEFT_TOP,
                app.field_help(app.step, i),
                FontId::proportional(11.0),
                theme::E_TEXT_FAINT,
            );
            ui.add_space(22.0);
        }
    }

    fn field_row(&self, ui: &mut Ui, rect: Rect, label: &str, value: &str, selected: bool) {
        let _resp = ui.allocate_rect(rect, Sense::click());
        ui.painter().rect(
            rect,
            8.0,
            if selected { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
            Stroke::new(if selected { 2.0 } else { 1.0_f32 }, if selected { theme::E_TEXT } else { theme::E_BORDER }),
            StrokeKind::Inside,
        );
        ui.painter().text(
            Pos2::new(rect.min.x + 14.0, rect.min.y + 8.0),
            Align2::LEFT_TOP,
            label,
            FontId::proportional(12.0),
            if selected { theme::E_TEXT } else { theme::E_TEXT_DIM },
        );
        let shown = if value.is_empty() { "—" } else { value };
        ui.painter().text(
            Pos2::new(rect.min.x + 14.0, rect.min.y + 26.0),
            Align2::LEFT_TOP,
            shown,
            FontId::proportional(15.0),
            if value.is_empty() {
                theme::E_TEXT_FAINT
            } else {
                theme::E_TEXT
            },
        );
    }

    fn page_options(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let row_h = 46.0;
        let options = app.options();
        let n = options.len();

        let list_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h * n as f32));
        *self.list.borrow_mut() = Some(ListHit {
            rect: list_rect,
            rows: n,
            row_h,
        });

        for (i, (label, value)) in options.iter().enumerate() {
            let rect = Rect::from_min_size(
                ui.cursor().min + egui::Vec2::new(0.0, i as f32 * row_h),
                egui::Vec2::new(w, row_h - 6.0),
            );
            let sel = i == app.cursor;
            ui.allocate_rect(rect, Sense::click());
            ui.painter().rect(
                rect,
                8.0,
                if sel { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
                Stroke::new(if sel { 2.0 } else { 1.0_f32 }, if sel { theme::E_TEXT } else { theme::E_BORDER }),
                StrokeKind::Inside,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + rect.height() / 2.0),
                Align2::LEFT_CENTER,
                label,
                FontId::proportional(15.0),
                theme::E_TEXT,
            );
            ui.painter().text(
                Pos2::new(rect.max.x - 14.0, rect.min.y + rect.height() / 2.0),
                Align2::RIGHT_CENTER,
                value,
                FontId::proportional(15.0),
                theme::E_TEXT_DIM,
            );
        }
    }

    fn page_extras(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let row_h = 46.0;
        let options = app.extras();
        let n = options.len();

        let list_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h * n as f32));
        *self.list.borrow_mut() = Some(ListHit {
            rect: list_rect,
            rows: n,
            row_h,
        });

        for (i, (label, value)) in options.iter().enumerate() {
            let rect = Rect::from_min_size(
                ui.cursor().min + egui::Vec2::new(0.0, i as f32 * row_h),
                egui::Vec2::new(w, row_h - 6.0),
            );
            let sel = i == app.cursor;
            ui.allocate_rect(rect, Sense::click());
            ui.painter().rect(
                rect,
                8.0,
                if sel { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
                Stroke::new(if sel { 2.0 } else { 1.0_f32 }, if sel { theme::E_TEXT } else { theme::E_BORDER }),
                StrokeKind::Inside,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + rect.height() / 2.0),
                Align2::LEFT_CENTER,
                label,
                FontId::proportional(15.0),
                theme::E_TEXT,
            );
            ui.painter().text(
                Pos2::new(rect.max.x - 14.0, rect.min.y + rect.height() / 2.0),
                Align2::RIGHT_CENTER,
                value,
                FontId::proportional(15.0),
                theme::E_TEXT_DIM,
            );
        }
    }

    fn page_dotfiles(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let row_h = 56.0;
        let options = app.dotfiles();
        let n = options.len();

        let list_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h * n as f32));
        *self.list.borrow_mut() = Some(ListHit {
            rect: list_rect,
            rows: n,
            row_h,
        });

        for (i, (label, selected)) in options.iter().enumerate() {
            let rect = Rect::from_min_size(
                ui.cursor().min + egui::Vec2::new(0.0, i as f32 * row_h),
                egui::Vec2::new(w, row_h - 6.0),
            );
            let sel = i == app.cursor;
            ui.allocate_rect(rect, Sense::click());
            ui.painter().rect(
                rect,
                8.0,
                if sel { theme::E_ROW_SEL } else { theme::E_BASE_SOFT },
                Stroke::new(if sel { 2.0 } else { 1.0_f32 }, if sel { theme::E_TEXT } else { theme::E_BORDER }),
                StrokeKind::Inside,
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.min.y + rect.height() / 2.0),
                Align2::LEFT_CENTER,
                label,
                FontId::proportional(15.0),
                theme::E_TEXT,
            );
            if !selected.is_empty() {
                ui.painter().text(
                    Pos2::new(rect.max.x - 14.0, rect.min.y + rect.height() / 2.0),
                    Align2::RIGHT_CENTER,
                    "selected",
                    FontId::proportional(13.0),
                    theme::E_TEXT_DIM,
                );
            }
        }
    }

    fn page_summary(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();
        let c = &app.cfg;
        let mut lines: Vec<(String, String)> = Vec::new();
        lines.push((
            "Disk".into(),
            format!("{}  ({})", c.disk, c.disk_model),
        ));
        lines.push(("Firmware".into(), c.firmware.label().to_string()));
        lines.push(("Layout".into(), c.layout_summary()));
        lines.push(("Profile".into(), c.profile.label().to_string()));
        lines.push(("Dotfiles".into(), c.dotfiles.label().to_string()));
        lines.push((
            "User".into(),
            format!("{} (host {})", c.username, c.hostname),
        ));
        lines.push((
            "Region".into(),
            format!("{} · {} · {}", c.timezone, c.locale, c.keymap),
        ));
        lines.push((
            "Gaming".into(),
            if c.install_gaming { "yes" } else { "no" }.to_string(),
        ));
        lines.push((
            "Apps".into(),
            format!("steam={} firefox={} discord={} opencode={} spotify={}",
                if c.install_steam {"yes"} else {"no"},
                if c.install_firefox {"yes"} else {"no"},
                if c.install_discord {"yes"} else {"no"},
                if c.install_opencode {"yes"} else {"no"},
                if c.install_spotify {"yes"} else {"no"}),
        ));
        lines.push((
            "GPU".into(),
            if c.nvidia { "NVIDIA" } else { "Mesa" }.to_string(),
        ));

        let row_h = 34.0;
        for (i, (k, v)) in lines.iter().enumerate() {
            let rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, row_h));
            ui.painter().rect_filled(
                rect,
                0.0,
                if i % 2 == 0 {
                    theme::E_BASE_SOFT
                } else {
                    theme::E_BASE
                },
            );
            ui.painter().text(
                Pos2::new(rect.min.x + 14.0, rect.center().y),
                Align2::LEFT_CENTER,
                k,
                FontId::proportional(14.0),
                theme::E_TEXT_DIM,
            );
            ui.painter().text(
                Pos2::new(rect.max.x - 14.0, rect.center().y),
                Align2::RIGHT_CENTER,
                v,
                FontId::proportional(14.0),
                theme::E_TEXT,
            );
        }

        ui.add_space(12.0);
        ui.label(
            egui::RichText::new(app.cmdline_preview())
                .color(theme::E_TEXT_FAINT)
                .size(11.0)
                .monospace(),
        );

        let warnings = app.warnings();
        if !warnings.is_empty() {
            ui.add_space(10.0);
            for w in &warnings {
                ui.label(
                    egui::RichText::new(format!("⚠ {w}"))
                        .color(theme::E_WARN)
                        .size(13.0),
                );
            }
        }

        ui.add_space(8.0);
        ui.label(
            egui::RichText::new(
                "Installing erases the target disk. This cannot be undone.",
            )
            .color(theme::E_URGENT)
            .strong(),
        );
    }

    fn page_install(&self, ui: &mut Ui, app: &App) {
        let w = ui.available_width();

        let frac = app.progress.clamp(0.0, 1.0);
        let pct = (frac * 100.0).round() as i32;
        let bar_color = theme::e_progress_color(frac);
        let phase = if app.phase.is_empty() {
            "starting…".to_string()
        } else {
            app.phase.clone()
        };

        // Progress box: keep the bar and label inside a bordered container.
        let box_h = 76.0;
        let box_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, box_h));
        ui.painter().rect_filled(box_rect, 8.0, theme::E_BASE_SOFT);
        ui.painter().rect_stroke(
            box_rect,
            8.0,
            egui::Stroke::new(1.0_f32, theme::E_BORDER),
            egui::StrokeKind::Inside,
        );

        let label = format!("{:>3}%  {}", pct, phase);
        ui.painter().text(
            Pos2::new(box_rect.min.x + 14.0, box_rect.min.y + 14.0),
            Align2::LEFT_CENTER,
            label,
            FontId::proportional(14.0),
            bar_color,
        );
        ui.painter().text(
            Pos2::new(box_rect.max.x - 14.0, box_rect.min.y + 14.0),
            Align2::RIGHT_CENTER,
            format!(
                "stage {}/{}",
                (app.completed.len() + 1).min(app.stage_total()),
                app.stage_total()
            ),
            FontId::proportional(12.0),
            theme::E_TEXT_DIM,
        );

        let track_rect = Rect::from_min_size(
            Pos2::new(box_rect.min.x + 12.0, box_rect.min.y + 30.0),
            egui::Vec2::new(box_rect.width() - 24.0, 12.0),
        );
        ui.painter().rect_filled(track_rect, 6.0, theme::E_BASE);
        ui.painter().rect_stroke(
            track_rect,
            6.0,
            egui::Stroke::new(1.0_f32, theme::E_BORDER),
            egui::StrokeKind::Inside,
        );
        if frac > 0.0 {
            let fill_w = (track_rect.width() * frac).max(6.0).min(track_rect.width());
            ui.painter().rect_filled(
                Rect::from_min_size(track_rect.min, egui::Vec2::new(fill_w, track_rect.height())),
                6.0,
                bar_color,
            );
        }

        // Finished stages, most recent kept when space is short. The box is
        // ~76 px tall and the label is a single line, so keep the text inside
        // the border instead of letting it paint past the edge.
        let mut done: Vec<String> = Vec::new();
        let mut used = 0usize;
        for name in app.completed.iter().rev() {
            let w = name.chars().count() + 2; // "✓ "
            if used + w > 64 {
                break;
            }
            used += w + 2; // separator
            done.push(format!("✓ {name}"));
        }
        done.reverse();
        let checklist = if done.is_empty() {
            "waiting for the first stage".to_string()
        } else {
            done.join("  ")
        };
        ui.painter().text(
            Pos2::new(box_rect.min.x + 14.0, box_rect.min.y + 58.0),
            Align2::LEFT_CENTER,
            checklist,
            FontId::proportional(12.0),
            theme::E_TEXT_DIM,
        );
        ui.allocate_rect(box_rect, egui::Sense::hover());
        ui.add_space(12.0);

        ui.label(
            egui::RichText::new("Log")
                .color(theme::E_TEXT_DIM)
                .size(13.0)
                .strong(),
        );
        ui.add_space(6.0);

        let log_rect = Rect::from_min_size(ui.cursor().min, egui::Vec2::new(w, ui.available_height() - 8.0));
        ui.painter()
            .rect_filled(log_rect, 6.0, theme::E_BASE_SOFT);
        let start = app.log_offset.min(app.log.len());
        let mut y = log_rect.min.y + 8.0;
        for line in &app.log[start..] {
            ui.painter().text(
                Pos2::new(log_rect.min.x + 12.0, y),
                Align2::LEFT_TOP,
                line.clone(),
                FontId::monospace(12.0),
                theme::E_TEXT_DIM,
            );
            y += 14.0;
            if y > log_rect.max.y - 10.0 {
                break;
            }
        }
    }

    fn page_done(&self, ui: &mut Ui, app: &App) {
        ui.add_space(40.0);
        if app.installed {
            ui.label(
                egui::RichText::new("Installation complete.")
                    .color(theme::E_GOOD)
                    .size(22.0)
                    .strong(),
            );
            ui.add_space(8.0);
            ui.label(
                egui::RichText::new("Reboot, remove the installation medium, and enjoy WebOS.")
                    .color(theme::E_TEXT),
            );
        } else {
            ui.label(
                egui::RichText::new("Installation did not complete.")
                    .color(theme::E_URGENT)
                    .size(22.0)
                    .strong(),
            );
            ui.add_space(8.0);
            if let Some(err) = &app.error {
                ui.label(
                    egui::RichText::new(err.clone())
                        .color(theme::E_URGENT)
                        .size(14.0),
                );
            }
            ui.label(
                egui::RichText::new("The log was written to /var/log/webos-install.log.")
                    .color(theme::E_TEXT_DIM),
            );
        }
    }

}

impl eframe::App for InstallerGui {
    fn update(&mut self, ctx: &Context, _frame: &mut eframe::Frame) {
        self.app().borrow_mut().tick();
        self.on_input(ctx);
        self.draw(ctx);
    }
}

/// Run the windowed installer. Returns the wizard state once the window closes.
pub fn run_gui(app: App) -> anyhow::Result<App> {
    let gui = InstallerGui::new(app);
    let app_rc = gui.app().clone();

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("WebOS Installer")
            .with_fullscreen(true),
        ..Default::default()
    };

    let creator: eframe::AppCreator = Box::new(move |_cc| Ok(Box::new(gui)));
    eframe::run_native("WebOS Installer", options, creator)
        .map_err(|e| anyhow::anyhow!("GUI failed to start: {e}"))?;

    let app = Rc::try_unwrap(app_rc)
        .map_err(|_| anyhow::anyhow!("GUI state is still borrowed"))?
        .into_inner();
    Ok(app)
}

// ── key translation ───────────────────────────────────────────────────────

fn map_key(key: Key, modifiers: Modifiers) -> Option<(KeyCode, KeyModifiers)> {
    let mods = crossterm_mods(modifiers);
    let code = match key {
        Key::ArrowUp => KeyCode::Up,
        Key::ArrowDown => KeyCode::Down,
        Key::ArrowLeft => KeyCode::Left,
        Key::ArrowRight => KeyCode::Right,
        Key::Enter => KeyCode::Enter,
        Key::Escape => KeyCode::Esc,
        Key::Tab => KeyCode::Tab,
        Key::Backspace => KeyCode::Backspace,
        Key::Delete => KeyCode::Delete,
        Key::Home => KeyCode::Home,
        Key::End => KeyCode::End,
        Key::PageUp => KeyCode::PageUp,
        Key::PageDown => KeyCode::PageDown,
        // Characters arrive through Event::Text / Event::Paste instead, so
        // that typing into a field produces exactly one key per character.
        _ => return None,
    };
    Some((code, mods))
}

fn crossterm_mods(m: Modifiers) -> KeyModifiers {
    let mut out = KeyModifiers::NONE;
    if m.ctrl || m.command {
        out |= KeyModifiers::CONTROL;
    }
    if m.alt {
        out |= KeyModifiers::ALT;
    }
    if m.shift {
        out |= KeyModifiers::SHIFT;
    }
    out
}
