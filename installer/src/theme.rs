//! The Ashen palette, in one place.
//!
//! These are the same values as `hypr/webos-colors.conf` and
//! `waybar/style.css`. If you change one, change all three.

use ratatui::style::{Color, Modifier, Style};

/// Deep black background. Terminals that support it will also blur behind the
/// window, because WebOS runs the installer inside foot/kitty. Icons and the
/// cursor are white on top of that deep black.
pub const BASE: Color = Color::Rgb(5, 5, 8);   // deep black
pub const BASE_SOFT: Color = Color::Rgb(8, 8, 11);

pub const TEXT: Color = Color::Rgb(240, 240, 245);   // white
pub const TEXT_DIM: Color = Color::Rgb(154, 163, 173);
pub const TEXT_FAINT: Color = Color::Rgb(91, 100, 112);

pub const ACCENT: Color = Color::Rgb(240, 240, 245);   // white: icons + cursor
pub const ACCENT_DIM: Color = Color::Rgb(150, 155, 165);

pub const BORDER: Color = Color::Rgb(38, 40, 46);
pub const URGENT: Color = Color::Rgb(248, 113, 113);
pub const ORANGE: Color = Color::Rgb(251, 146, 60);
pub const WARN: Color = Color::Rgb(251, 191, 36);
pub const GOOD: Color = Color::Rgb(134, 239, 172);

/// Progress/gauge colour: 0-25 red, 26-50 orange, 51-75 yellow, 76-100 green.
pub fn progress_color(ratio: f64) -> Color {
    let pct = (ratio * 100.0).round() as i32;
    if pct <= 25 {
        URGENT
    } else if pct <= 50 {
        ORANGE
    } else if pct <= 75 {
        WARN
    } else {
        GOOD
    }
}

pub fn base() -> Style {
    Style::default().bg(BASE).fg(TEXT)
}

pub fn dim() -> Style {
    Style::default().bg(BASE).fg(TEXT_DIM)
}

pub fn faint() -> Style {
    Style::default().bg(BASE).fg(TEXT_FAINT)
}

pub fn accent() -> Style {
    Style::default().bg(BASE).fg(ACCENT)
}

pub fn accent_bold() -> Style {
    Style::default().bg(BASE).fg(ACCENT).add_modifier(Modifier::BOLD)
}

pub fn selected() -> Style {
    Style::default()
        .bg(ACCENT_DIM)
        .fg(TEXT)
        .add_modifier(Modifier::BOLD)
}

pub fn title() -> Style {
    Style::default().bg(BASE).fg(TEXT).add_modifier(Modifier::BOLD)
}

pub fn urgent() -> Style {
    Style::default().bg(BASE).fg(URGENT)
}

pub fn warn() -> Style {
    Style::default().bg(BASE).fg(WARN)
}

pub fn good() -> Style {
    Style::default().bg(BASE).fg(GOOD)
}

/// The wordmark, as it appears on the welcome page: WebOS.
pub const LOGO: [&str; 6] = [
    " __        __   _     ___  ____  ",
    " \\ \\      / /__| |__ / _ \\/ ___| ",
    "  \\ \\ /\\ / / _ \\ '_ \\ | | \\___ \\ ",
    "   \\ V  V /  __/ |_) | |_| |___) |",
    "    \\_/\\_/ \\___|_.__/ \\___/|____/ ",
    "                                 ",
];

// ── egui equivalents (used by the windowed installer) ─────────────────────
//
// Same values, different colour type. Keep these in lockstep with the ratatui
// constants above and with `hypr/webos-colors.conf` / `waybar/style.css`.

use egui::Color32;

pub const E_BASE: Color32 = Color32::from_rgb(5, 5, 8);
pub const E_BASE_SOFT: Color32 = Color32::from_rgb(8, 8, 11);
pub const E_ROW_SEL: Color32 = Color32::from_rgb(24, 26, 32);

pub const E_TEXT: Color32 = Color32::from_rgb(240, 240, 245);
pub const E_TEXT_DIM: Color32 = Color32::from_rgb(154, 163, 173);
pub const E_TEXT_FAINT: Color32 = Color32::from_rgb(91, 100, 112);

pub const E_ACCENT: Color32 = Color32::from_rgb(240, 240, 245);

pub const E_BORDER: Color32 = Color32::from_rgb(38, 40, 46);
pub const E_URGENT: Color32 = Color32::from_rgb(248, 113, 113);
pub const E_ORANGE: Color32 = Color32::from_rgb(251, 146, 60);
pub const E_WARN: Color32 = Color32::from_rgb(251, 191, 36);
pub const E_GOOD: Color32 = Color32::from_rgb(134, 239, 172);

/// Progress/gauge colour: 0-25 red, 26-50 orange, 51-75 yellow, 76-100 green.
pub fn e_progress_color(ratio: f32) -> Color32 {
    let pct = (ratio * 100.0).round() as i32;
    if pct <= 25 {
        E_URGENT
    } else if pct <= 50 {
        E_ORANGE
    } else if pct <= 75 {
        E_WARN
    } else {
        E_GOOD
    }
}
