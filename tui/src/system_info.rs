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
        let mut entries = Vec::new();

        push_entry(&mut entries, "Distro", Some(detect_distro()));
        push_entry(&mut entries, "Kernel", command_output("uname", &["-r"]));
        push_entry(&mut entries, "CPU", detect_cpu());
        push_entry(&mut entries, "Memory", detect_memory());
        push_entry(&mut entries, "Disk", detect_disk());
        push_entry(&mut entries, "GPU", detect_gpu());

        (!entries.is_empty()).then_some(Self { entries })
    }

    pub fn entries_len(&self) -> usize {
        self.entries.len()
    }

    pub fn render_lines(&self, theme: &Theme, max_width: usize) -> Vec<Line<'static>> {
        self.entries
            .iter()
            .map(|entry| {
                let label = format!("{} : ", entry.label);
                let value_width = max_width.saturating_sub(label.len());
                let value = truncate(&entry.value, value_width);

                Line::from(vec![
                    Span::styled(label, Style::default().fg(theme.tab_color()).bold()),
                    Span::raw(value),
                ])
            })
            .collect()
    }
}

fn truncate(value: &str, max_width: usize) -> String {
    if value.chars().count() <= max_width {
        return value.to_string();
    }

    if max_width <= 3 {
        return ".".repeat(max_width);
    }

    let mut truncated = value.chars().take(max_width - 3).collect::<String>();
    truncated.push_str("...");
    truncated
}

fn push_entry(entries: &mut Vec<InfoEntry>, label: &'static str, value: Option<String>) {
    if let Some(value) = value
        && !value.is_empty()
    {
        entries.push(InfoEntry { label, value });
    }
}

fn command_output(program: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(program).args(args).output().ok()?;

    if !output.status.success() {
        return None;
    }

    let value = String::from_utf8_lossy(&output.stdout).trim().to_string();
    (!value.is_empty()).then_some(value)
}

#[cfg(target_os = "linux")]
fn detect_distro() -> String {
    fs::read_to_string("/etc/os-release")
        .ok()
        .and_then(|data| parse_os_release(&data))
        .unwrap_or_else(|| "Unknown Linux".to_string())
}

#[cfg(not(target_os = "linux"))]
fn detect_distro() -> String {
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
                    .map(|(_, value)| value.trim().to_string())
            })
        })
        .or_else(|| command_output("uname", &["-m"]))
}

#[cfg(target_os = "macos")]
fn detect_cpu() -> Option<String> {
    command_output("sysctl", &["-n", "machdep.cpu.brand_string"])
}

#[cfg(not(any(target_os = "linux", target_os = "macos")))]
fn detect_cpu() -> Option<String> {
    None
}

#[cfg(target_os = "linux")]
fn detect_memory() -> Option<String> {
    let data = fs::read_to_string("/proc/meminfo").ok()?;
    let total_kib = meminfo_value(&data, "MemTotal")?;
    let available_kib = meminfo_value(&data, "MemAvailable")?;
    let used_kib = total_kib.saturating_sub(available_kib);

    Some(format!(
        "{:.1} GiB / {:.1} GiB",
        kib_to_gib(used_kib),
        kib_to_gib(total_kib)
    ))
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
    let [_, size, used, _, _, ..] = columns.as_slice() else {
        return None;
    };

    Some(format!("{used} / {size}"))
}

#[cfg(target_os = "linux")]
fn detect_gpu() -> Option<String> {
    let output = command_output("lspci", &[])?;
    output.lines().find_map(|line| {
        if line.contains("VGA compatible controller")
            || line.contains("3D controller")
            || line.contains("Display controller")
        {
            line.split_once(':')
                .map(|(_, value)| value.trim().to_string())
        } else {
            None
        }
    })
}

#[cfg(target_os = "macos")]
fn detect_gpu() -> Option<String> {
    command_output("system_profiler", &["SPDisplaysDataType"]).and_then(|output| {
        output.lines().find_map(|line| {
            line.trim()
                .strip_prefix("Chipset Model:")
                .map(|value| value.trim().to_string())
        })
    })
}

#[cfg(not(any(target_os = "linux", target_os = "macos")))]
fn detect_gpu() -> Option<String> {
    None
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

    pretty_name.or_else(|| match (name, version) {
        (Some(name), Some(version)) => Some(format!("{name} {version}")),
        (Some(name), None) => Some(name),
        _ => None,
    })
}

#[cfg(target_os = "linux")]
fn clean_os_release_value(value: &str) -> String {
    value
        .trim()
        .trim_matches('"')
        .replace("\\\"", "\"")
        .replace("\\\\", "\\")
}
