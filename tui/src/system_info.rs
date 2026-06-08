use crate::theme::Theme;
use ratatui::{
    style::Style,
    text::{Line, Span},
};
#[cfg(target_os = "linux")]
use std::fs;
use std::process::Command;

#[derive(Clone, Debug)]
pub struct SystemInfo {
    entries: Vec<InfoEntry>,
}

#[derive(Clone, Debug)]
struct InfoEntry {
    label: &'static str,
    value: String,
}

impl SystemInfo {
    pub fn gather() -> Option<Self> {
        let entries = vec![
            InfoEntry {
                label: " OS",
                value: detect_os(),
            },
            InfoEntry {
                label: "CPU",
                value: detect_cpu().unwrap_or_else(|| "n/a".to_string()),
            },
            InfoEntry {
                label: "RAM",
                value: detect_memory().unwrap_or_else(|| "n/a".to_string()),
            },
            InfoEntry {
                label: "DISK",
                value: detect_disk().unwrap_or_else(|| "n/a".to_string()),
            },
        ];

        Some(Self { entries })
    }

    pub fn entries_len(&self) -> usize {
        self.entries.len()
    }

    pub fn render_lines(&self, theme: &Theme, max_width: usize) -> Vec<Line<'static>> {
        self.entries
            .iter()
            .map(|entry| {
                let prefix = format!("{:>4}: ", entry.label);
                let value_width = max_width.saturating_sub(prefix.len());
                let value = truncate(&entry.value, value_width);

                Line::from(vec![
                    Span::styled(
                        format!("{:>4}", entry.label),
                        Style::default().fg(theme.tab_color()).bold(),
                    ),
                    Span::styled(": ", Style::default().fg(theme.unfocused_color())),
                    Span::styled(value, Style::default().fg(theme.cmd_color())),
                ])
            })
            .collect()
    }
}

fn truncate(value: &str, max_width: usize) -> String {
    if max_width == 0 {
        return String::new();
    }

    let chars: Vec<char> = value.chars().collect();
    if chars.len() <= max_width {
        return value.to_string();
    }

    if max_width <= 3 {
        return chars.iter().take(max_width).collect();
    }

    let slice: String = chars.iter().take(max_width - 3).collect();
    format!("{slice}...")
}

fn command_output(program: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(program).args(args).output().ok()?;

    if !output.status.success() {
        return None;
    }

    let value = String::from_utf8_lossy(&output.stdout).trim().to_string();
    (!value.is_empty()).then_some(value)
}

fn strip_device_details(value: &str) -> String {
    let mut trimmed = value.trim().to_string();
    for pattern in [" @", " (", " ["] {
        if let Some(idx) = trimmed.find(pattern) {
            trimmed.truncate(idx);
            trimmed = trimmed.trim().to_string();
        }
    }
    trimmed
}

#[cfg(target_os = "linux")]
fn shorten_os(value: &str) -> String {
    let mut name = value.trim().to_string();
    if let Some(idx) = name.find(" GNU/Linux") {
        name.truncate(idx);
    }
    if name.ends_with(" Linux") {
        name.truncate(name.len() - " Linux".len());
    }
    name.trim().to_string()
}

#[cfg(target_os = "linux")]
fn detect_os() -> String {
    fs::read_to_string("/etc/os-release")
        .ok()
        .and_then(|data| parse_os_release(&data))
        .map(|name| shorten_os(&name))
        .unwrap_or_else(|| "Linux".to_string())
}

#[cfg(target_os = "macos")]
fn detect_os() -> String {
    match (
        command_output("sw_vers", &["-productName"]),
        command_output("sw_vers", &["-productVersion"]),
    ) {
        (Some(name), Some(version)) => format!("{name} {version}"),
        (Some(name), None) => name,
        _ => "macOS".to_string(),
    }
}

#[cfg(not(any(target_os = "linux", target_os = "macos")))]
fn detect_os() -> String {
    std::env::consts::OS.to_string()
}

#[cfg(target_os = "linux")]
fn detect_cpu() -> Option<String> {
    fs::read_to_string("/proc/cpuinfo")
        .ok()
        .and_then(|data| {
            data.lines().find_map(|line| {
                line.strip_prefix("model name")
                    .and_then(|line| line.split_once(':'))
                    .map(|(_, value)| strip_device_details(value))
            })
        })
        .or_else(|| command_output("uname", &["-m"]).map(|value| strip_device_details(&value)))
}

#[cfg(target_os = "macos")]
fn detect_cpu() -> Option<String> {
    command_output("sysctl", &["-n", "machdep.cpu.brand_string"])
        .map(|value| strip_device_details(&value))
}

#[cfg(not(any(target_os = "linux", target_os = "macos")))]
fn detect_cpu() -> Option<String> {
    None
}

#[cfg(target_os = "linux")]
fn detect_memory() -> Option<String> {
    let data = fs::read_to_string("/proc/meminfo").ok()?;
    let total_kib = meminfo_value(&data, "MemTotal")?;
    Some(format!("{:.1} GiB", kib_to_gib(total_kib)))
}

#[cfg(target_os = "macos")]
fn detect_memory() -> Option<String> {
    let bytes = command_output("sysctl", &["-n", "hw.memsize"])?
        .parse::<u64>()
        .ok()?;
    Some(format!("{:.1} GiB", bytes as f64 / 1024_f64.powi(3)))
}

#[cfg(not(any(target_os = "linux", target_os = "macos")))]
fn detect_memory() -> Option<String> {
    None
}

fn detect_disk() -> Option<String> {
    let output = command_output("df", &["-h", "/"])?;
    let line = output.lines().nth(1)?;
    let columns = line.split_whitespace().collect::<Vec<_>>();
    let size = columns.get(1)?;
    Some(size.to_string())
}

#[cfg(target_os = "linux")]
fn meminfo_value(data: &str, key: &str) -> Option<u64> {
    data.lines().find_map(|line| {
        line.strip_prefix(key)
            .and_then(|line| line.split_once(':'))
            .and_then(|(_, value)| value.split_whitespace().next())
            .and_then(|value| value.parse().ok())
    })
}

#[cfg(target_os = "linux")]
fn kib_to_gib(kib: u64) -> f64 {
    kib as f64 / 1024.0 / 1024.0
}

#[cfg(target_os = "linux")]
fn parse_os_release(data: &str) -> Option<String> {
    let mut name = None;
    let mut version = None;
    let mut pretty_name = None;

    for line in data.lines() {
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };

        let value = clean_os_release_value(value);

        match key {
            "PRETTY_NAME" => pretty_name = Some(value),
            "NAME" => name = Some(value),
            "VERSION_ID" => version = Some(value),
            _ => {}
        }
    }

    match (name, version, pretty_name) {
        (_, _, Some(pretty)) if pretty.chars().count() <= 24 => Some(pretty),
        (Some(name), Some(version), _) => Some(format!("{name} {version}")),
        (Some(_name), None, Some(pretty)) => Some(pretty),
        (Some(name), None, None) => Some(name),
        _ => None,
    }
}

#[cfg(target_os = "linux")]
fn clean_os_release_value(value: &str) -> String {
    value
        .trim()
        .trim_matches('"')
        .replace("\\\"", "\"")
        .replace("\\\\", "\\")
}
