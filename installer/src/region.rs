//! Best-effort region detection for the wizard.
//!
//! The live ISO boots in UTC, so the installer used to hand every user a UTC
//! clock and a `us` keymap. This module tries the machine's configured zone
//! first (useful when the wizard is launched from an installed system), then
//! IP geolocation, and finally falls back to UTC. Every guess is only a
//! default: the Region page remains fully editable, and `r` re-runs detection.

use std::fs;
use std::path::Path;
use std::process::{Command, Stdio};

use crate::config::InstallConfig;

/// A detected region. Only the fields the wizard can safely seed are stored;
/// locale is left alone because the user may deliberately keep `en_US.UTF-8`.
#[derive(Debug, Clone)]
pub struct RegionGuess {
    pub timezone: String,
    pub keymap: String,
    pub source: String,
}

impl RegionGuess {
    fn utc() -> Self {
        Self {
            timezone: "UTC".into(),
            keymap: "us".into(),
            source: "UTC fallback — edit on the Region page".into(),
        }
    }
}

/// Build a fresh `InstallConfig` with detected region defaults. This is used
/// only by `App::new`; `--config FILE` still wins completely.
pub fn default_with_detection() -> (InstallConfig, String) {
    let guess = detect();
    let mut cfg = InstallConfig::default();
    cfg.timezone = guess.timezone;
    cfg.keymap = guess.keymap;
    (cfg, guess.source)
}

pub fn detect() -> RegionGuess {
    // A non-UTC local zone is stronger evidence than geolocation (VPNs and
    // mobile networks can misreport a location).
    if let Some(tz) = local_timezone() {
        if !is_utc(&tz) {
            return RegionGuess {
                keymap: keymap_for(&tz, None),
                source: format!("local zone {tz} — press r to re-detect"),
                timezone: tz,
            };
        }
    }

    if let Some((tz, country)) = network_timezone() {
        let who = country
            .as_deref()
            .filter(|c| !c.is_empty())
            .unwrap_or("IP");
        return RegionGuess {
            keymap: keymap_for(&tz, country.as_deref()),
            source: format!("IP geolocation ({who}) — press r to re-detect"),
            timezone: tz,
        };
    }

    // The local zone may legitimately be UTC; keep it, but say where it came
    // from so the user knows detection did not silently pick US defaults.
    if let Some(tz) = local_timezone() {
        return RegionGuess {
            keymap: keymap_for(&tz, None),
            source: "system UTC — press r to re-detect".into(),
            timezone: tz,
        };
    }

    RegionGuess::utc()
}

fn local_timezone() -> Option<String> {
    if let Ok(text) = fs::read_to_string("/etc/timezone") {
        let tz = text.trim();
        if valid_timezone(tz) {
            return Some(tz.to_string());
        }
    }

    if let Ok(link) = fs::read_link("/etc/localtime") {
        let text = link.to_string_lossy();
        if let Some(pos) = text.find("zoneinfo/") {
            let tz = &text[pos + "zoneinfo/".len()..];
            if valid_timezone(tz) {
                return Some(tz.to_string());
            }
        }
    }

    None
}

fn network_timezone() -> Option<(String, Option<String>)> {
    // All endpoints are plain JSON. `curl` is in @webos-installer, so the
    // live medium always has it. Failures fall through to the next endpoint.
    let endpoints = [
        ("https://ipapi.co/json/", Some("country_code")),
        ("https://ipinfo.io/json", Some("country")),
        ("https://worldtimeapi.org/api/ip", None),
    ];

    for (url, country_key) in endpoints {
        let Some(body) = fetch(url) else { continue };
        let Some(tz) = json_string(&body, "timezone") else { continue };
        if !valid_timezone(&tz) {
            continue;
        }
        let country = country_key
            .and_then(|key| json_string(&body, key))
            .map(|c| c.trim().to_ascii_uppercase());
        return Some((tz, country));
    }

    None
}

fn fetch(url: &str) -> Option<String> {
    let output = Command::new("curl")
        .args(["-fsSL", "--connect-timeout", "2", "--max-time", "4", url])
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    String::from_utf8(output.stdout).ok()
}

/// Pull a JSON string value without adding a JSON dependency to the installer.
fn json_string(body: &str, key: &str) -> Option<String> {
    let marker = format!("\"{key}\"");
    let start = body.find(&marker)? + marker.len();
    let tail = &body[start..];
    let colon = tail.find(':')?;
    let raw = tail[colon + 1..].trim_start().strip_prefix('"')?;

    let mut value = String::new();
    let mut escape = false;
    for ch in raw.chars() {
        if escape {
            match ch {
                'n' => value.push('\n'),
                'r' => value.push('\r'),
                't' => value.push('\t'),
                other => value.push(other),
            }
            escape = false;
            continue;
        }
        match ch {
            '\\' => escape = true,
            '"' => return Some(value),
            other => value.push(other),
        }
    }
    None
}

fn valid_timezone(tz: &str) -> bool {
    if tz.is_empty() || tz.len() > 64 || tz.starts_with('/') || tz.contains("..") {
        return false;
    }
    if !tz
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || matches!(c, '/' | '_' | '-' | '+'))
    {
        return false;
    }
    // On a live ISO the zoneinfo tree is present. In unit tests it may not
    // be, so only enforce existence when the tree is actually there.
    let root = Path::new("/usr/share/zoneinfo");
    !root.exists() || root.join(tz).exists()
}

fn is_utc(tz: &str) -> bool {
    matches!(
        tz,
        "UTC" | "UCT" | "GMT" | "Zulu" | "Universal" | "Etc/UTC" | "Etc/GMT" | "Etc/Zulu"
    )
}

/// Suggest a console keymap from the IP country first, then the IANA zone.
/// This seeds the existing editable keymap field; it never changes system
/// files by itself.
fn keymap_for(tz: &str, country: Option<&str>) -> String {
    let by_country = match country.unwrap_or("").to_ascii_uppercase().as_str() {
        "GB" | "IE" => "gb",
        "DE" => "de",
        "AT" => "at",
        "CH" => "ch",
        "FR" => "fr",
        "BE" => "be",
        "NL" => "nl",
        "ES" => "es",
        "PT" => "pt",
        "IT" => "it",
        "SE" => "se",
        "NO" => "no",
        "FI" => "fi",
        "DK" => "dk",
        "PL" => "pl",
        "CZ" => "cz",
        "SK" => "sk",
        "HU" => "hu",
        "RO" => "ro",
        "GR" => "gr",
        "TR" => "tr",
        "RU" => "ru",
        "UA" => "ua",
        "JP" => "jp",
        "KR" => "kr",
        "BR" => "br",
        "AR" | "CL" | "CO" | "MX" | "UY" => "la",
        _ => "",
    };
    if !by_country.is_empty() {
        return by_country.into();
    }

    let by_zone = match tz {
        "Europe/London" | "Europe/Dublin" | "Europe/Jersey" | "Europe/Guernsey" => "gb",
        "Europe/Berlin" => "de",
        "Europe/Vienna" => "at",
        "Europe/Zurich" => "ch",
        "Europe/Paris" => "fr",
        "Europe/Brussels" => "be",
        "Europe/Amsterdam" => "nl",
        "Europe/Madrid" => "es",
        "Europe/Lisbon" => "pt",
        "Europe/Rome" => "it",
        "Europe/Stockholm" => "se",
        "Europe/Oslo" => "no",
        "Europe/Helsinki" => "fi",
        "Europe/Copenhagen" => "dk",
        "Europe/Warsaw" => "pl",
        "Europe/Prague" => "cz",
        "Asia/Tokyo" => "jp",
        "Asia/Seoul" => "kr",
        "America/Sao_Paulo" => "br",
        "America/Argentina/Buenos_Aires" | "America/Mexico_City" | "America/Santiago" => "la",
        _ => "us",
    };
    by_zone.into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_plain_json_string() {
        let body = r#"{"timezone":"Europe/London","country_code":"GB"}"#;
        assert_eq!(json_string(body, "timezone").as_deref(), Some("Europe/London"));
        assert_eq!(json_string(body, "country_code").as_deref(), Some("GB"));
        assert_eq!(json_string(body, "missing"), None);
    }

    #[test]
    fn rejects_unsafe_timezones() {
        assert!(valid_timezone("Europe/London"));
        assert!(!valid_timezone("../etc/passwd"));
        assert!(!valid_timezone("/etc/passwd"));
        assert!(!valid_timezone("Europe/London;rm -rf /"));
    }

    #[test]
    fn suggests_keymaps() {
        assert_eq!(keymap_for("Europe/London", Some("GB")), "gb");
        assert_eq!(keymap_for("Europe/Berlin", None), "de");
        assert_eq!(keymap_for("America/New_York", Some("US")), "us");
        assert_eq!(keymap_for("America/Sao_Paulo", Some("BR")), "br");
    }
}
