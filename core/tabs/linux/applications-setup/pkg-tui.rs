use std::collections::HashSet;
use std::env;
use std::fs;
use std::io::Write;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::Duration;

const DEFAULT_AVAILABLE_TTL_SECS: u64 = 86_400;
const DEFAULT_INSTALLED_TTL_SECS: u64 = 120;

#[derive(Clone, Copy, Debug)]
enum Action {
    Install,
    Remove,
}

#[derive(Clone, Copy, Debug)]
enum CacheKind {
    Available,
    Installed,
}

impl CacheKind {
    fn suffix(self) -> &'static str {
        match self {
            Self::Available => "available",
            Self::Installed => "installed",
        }
    }

    fn default_ttl(self) -> Duration {
        match self {
            Self::Available => Duration::from_secs(DEFAULT_AVAILABLE_TTL_SECS),
            Self::Installed => Duration::from_secs(DEFAULT_INSTALLED_TTL_SECS),
        }
    }

    fn env_ttl_key(self) -> &'static str {
        match self {
            Self::Available => "PKG_TUI_AVAILABLE_TTL",
            Self::Installed => "PKG_TUI_INSTALLED_TTL",
        }
    }
}

#[derive(Clone, Copy, Debug)]
enum PackageManager {
    Nala,
    Apt,
    Yay,
    Pacman,
    Dnf,
    RpmOstree,
    Zypper,
    Apk,
    Eopkg,
    Moss,
    XbpsInstall,
    Pkg,
    Brew,
}

impl PackageManager {
    fn from_name(name: &str) -> Option<Self> {
        match name.to_ascii_lowercase().as_str() {
            "nala" => Some(Self::Nala),
            "apt" | "apt-get" => Some(Self::Apt),
            "yay" => Some(Self::Yay),
            "pacman" => Some(Self::Pacman),
            "dnf" => Some(Self::Dnf),
            "rpm-ostree" => Some(Self::RpmOstree),
            "zypper" => Some(Self::Zypper),
            "apk" => Some(Self::Apk),
            "eopkg" => Some(Self::Eopkg),
            "moss" => Some(Self::Moss),
            "xbps-install" | "xbps" => Some(Self::XbpsInstall),
            "pkg" => Some(Self::Pkg),
            "brew" | "homebrew" => Some(Self::Brew),
            _ => None,
        }
    }

    fn probe_binary(self) -> &'static str {
        match self {
            Self::Nala => "nala",
            Self::Apt => "apt",
            Self::Yay => "yay",
            Self::Pacman => "pacman",
            Self::Dnf => "dnf",
            Self::RpmOstree => "rpm-ostree",
            Self::Zypper => "zypper",
            Self::Apk => "apk",
            Self::Eopkg => "eopkg",
            Self::Moss => "moss",
            Self::XbpsInstall => "xbps-install",
            Self::Pkg => "pkg",
            Self::Brew => "brew",
        }
    }

    fn detect() -> Option<Self> {
        if let Ok(requested) = env::var("PKG_TUI_MANAGER") {
            if let Some(manager) = Self::from_name(requested.trim()) {
                let available = if matches!(manager, Self::RpmOstree) {
                    Path::new("/run/ostree-booted").exists() && command_exists(manager.probe_binary())
                } else {
                    command_exists(manager.probe_binary())
                };
                if available {
                    return Some(manager);
                }
            }
        }

        if Path::new("/run/ostree-booted").exists() && command_exists("rpm-ostree") {
            return Some(Self::RpmOstree);
        }

        let managers = [
            ("nala", Self::Nala),
            ("apt", Self::Apt),
            ("yay", Self::Yay),
            ("pacman", Self::Pacman),
            ("dnf", Self::Dnf),
            ("zypper", Self::Zypper),
            ("apk", Self::Apk),
            ("eopkg", Self::Eopkg),
            ("xbps-install", Self::XbpsInstall),
            ("pkg", Self::Pkg),
            ("moss", Self::Moss),
            ("brew", Self::Brew),
        ];

        managers
            .iter()
            .find_map(|(binary, manager)| command_exists(binary).then_some(*manager))
    }

    fn name(self) -> &'static str {
        match self {
            Self::Nala => "nala",
            Self::Apt => "apt",
            Self::Yay => "yay",
            Self::Pacman => "pacman",
            Self::Dnf => "dnf",
            Self::RpmOstree => "rpm-ostree",
            Self::Zypper => "zypper",
            Self::Apk => "apk",
            Self::Eopkg => "eopkg",
            Self::Moss => "moss",
            Self::XbpsInstall => "xbps-install",
            Self::Pkg => "pkg",
            Self::Brew => "brew",
        }
    }
}

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let manager = PackageManager::detect().ok_or_else(|| {
        "No supported package manager found (apt, pacman, dnf, rpm-ostree, zypper, apk, eopkg, xbps-install, pkg, moss, brew).".to_string()
    })?;

    let args: Vec<String> = env::args().collect();
    match args.get(1).map(String::as_str) {
        Some("--preview") => {
            let package = args
                .get(2)
                .ok_or_else(|| "Usage: pkg-tui --preview <package>".to_string())?;
            preview_package(manager, sanitize_package_name(package));
            Ok(())
        }
        Some("--refresh-cache") => {
            let _ = package_list(manager, CacheKind::Available, true)?;
            let _ = package_list(manager, CacheKind::Installed, true)?;
            println!("Cache refreshed for {}.", manager.name());
            Ok(())
        }
        Some("--help") | Some("-h") => {
            print_help();
            Ok(())
        }
        Some(unknown) => Err(format!("Unknown argument: {unknown}")),
        None => interactive_mode(manager),
    }
}

fn print_help() {
    println!("pkg-tui");
    println!("  Interactive package lookup/installer with cache.");
    println!();
    println!("Usage:");
    println!("  pkg-tui                    Launch interactive mode");
    println!("  pkg-tui --preview <name>   Show package info");
    println!("  pkg-tui --refresh-cache    Refresh cache now");
    println!();
    println!("Cache controls:");
    println!(
        "  PKG_TUI_AVAILABLE_TTL={} (seconds)",
        DEFAULT_AVAILABLE_TTL_SECS
    );
    println!(
        "  PKG_TUI_INSTALLED_TTL={} (seconds)",
        DEFAULT_INSTALLED_TTL_SECS
    );
    println!("  PKG_TUI_MANAGER=<manager>  (optional forced manager)");
}

fn interactive_mode(manager: PackageManager) -> Result<(), String> {
    if !command_exists("fzf") {
        return Err("fzf is required but was not found in PATH.".to_string());
    }

    let available = package_list(manager, CacheKind::Available, false)?;
    if available.is_empty() {
        return Err(format!("No packages found for {}.", manager.name()));
    }

    let installed = package_list(manager, CacheKind::Installed, false)?;
    let installed_set: HashSet<&str> = installed.iter().map(String::as_str).collect();

    let display_lines: Vec<String> = available
        .iter()
        .map(|name| {
            if installed_set.contains(name.as_str()) {
                format!("\x1b[32m{name} ✅\x1b[0m")
            } else {
                name.clone()
            }
        })
        .collect();

    let Some((action, selected_packages)) = run_fzf(manager, &display_lines)? else {
        return Ok(());
    };

    match action {
        Action::Install => println!("Installing: {}", selected_packages.join(" ")),
        Action::Remove => println!("Removing: {}", selected_packages.join(" ")),
    }

    run_action(manager, action, &selected_packages)?;

    let _ = package_list(manager, CacheKind::Installed, true);
    match action {
        Action::Install => println!("Install complete: {}", selected_packages.join(" ")),
        Action::Remove => println!("Remove complete: {}", selected_packages.join(" ")),
    }
    Ok(())
}

fn run_fzf(
    manager: PackageManager,
    display_lines: &[String],
) -> Result<Option<(Action, Vec<String>)>, String> {
    let header = format!(
        "{} | Enter/Alt-i: Install | Alt-r: Remove",
        manager.name()
    );

    let mut child = Command::new("fzf")
        .args([
            "--multi",
            "--ansi",
            "--exact",
            "--tiebreak=begin,length",
            "--preview",
            "pkg-tui --preview {1}",
            "--preview-window",
            "down:30%:wrap",
            "--expect",
            "enter,alt-i,alt-r",
            "--header",
            header.as_str(),
            "--color",
            "pointer:green,marker:green",
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .map_err(|error| format!("Failed to launch fzf: {error}"))?;

    {
        let stdin = child
            .stdin
            .as_mut()
            .ok_or_else(|| "Failed to open fzf stdin.".to_string())?;
        for line in display_lines {
            writeln!(stdin, "{line}").map_err(|error| format!("Failed writing to fzf: {error}"))?;
        }
    }

    let output = child
        .wait_with_output()
        .map_err(|error| format!("Failed to wait for fzf: {error}"))?;

    if !output.status.success() {
        let exit_code = output.status.code().unwrap_or_default();
        if exit_code == 130 || exit_code == 1 {
            return Ok(None);
        }
        return Err(format!("fzf exited with status code {exit_code}."));
    }

    let text = String::from_utf8_lossy(&output.stdout);
    if text.trim().is_empty() {
        return Ok(None);
    }

    let mut lines = text.lines();
    let key = lines.next().unwrap_or_default().trim();

    let selected_packages: Vec<String> = lines
        .map(sanitize_package_name)
        .filter(|pkg| !pkg.is_empty())
        .collect();

    if selected_packages.is_empty() {
        return Ok(None);
    }

    let action = if key == "alt-r" {
        Action::Remove
    } else {
        Action::Install
    };

    Ok(Some((action, selected_packages)))
}

fn preview_package(manager: PackageManager, package: String) {
    if package.is_empty() {
        return;
    }

    let (program, args) = match manager {
        PackageManager::Nala => ("nala", vec!["show".to_string(), package]),
        PackageManager::Apt => ("apt", vec!["show".to_string(), package]),
        PackageManager::Yay => ("yay", vec!["-Si".to_string(), package]),
        PackageManager::Pacman => ("pacman", vec!["-Si".to_string(), package]),
        PackageManager::Dnf => ("dnf", vec!["info".to_string(), package]),
        PackageManager::RpmOstree => ("rpm-ostree", vec!["search".to_string(), package]),
        PackageManager::Zypper => ("zypper", vec!["info".to_string(), package]),
        PackageManager::Apk => ("apk", vec!["info".to_string(), "-d".to_string(), package]),
        PackageManager::Eopkg => ("eopkg", vec!["info".to_string(), package]),
        PackageManager::Moss => ("moss", vec!["info".to_string(), package]),
        PackageManager::XbpsInstall => ("xbps-query", vec!["-RS".to_string(), package]),
        PackageManager::Pkg => ("pkg", vec!["info".to_string(), package]),
        PackageManager::Brew => (
            "brew",
            vec!["info".to_string(), "--formula".to_string(), package],
        ),
    };

    match Command::new(program).args(&args).output() {
        Ok(output) => {
            let stdout = String::from_utf8_lossy(&output.stdout);
            let stderr = String::from_utf8_lossy(&output.stderr);
            print!("{stdout}");
            if !stderr.is_empty() {
                print!("{stderr}");
            }
        }
        Err(error) => {
            eprintln!("Failed to run preview command for {program}: {error}");
        }
    }
}

fn run_action(manager: PackageManager, action: Action, packages: &[String]) -> Result<(), String> {
    if packages.is_empty() {
        return Ok(());
    }

    let (program, mut base_args, requires_escalation) = action_command(manager, action);
    base_args.extend(packages.iter().cloned());

    let is_root = current_uid() == Some(0);
    let escalation_tool = detect_escalation_tool();

    let (exec_program, exec_args) = if requires_escalation && !is_root {
        let tool = escalation_tool.ok_or_else(|| {
            "No supported escalation tool found (sudo-rs, sudo, doas).".to_string()
        })?;
        let mut args = vec![program.to_string()];
        args.extend(base_args);
        (tool, args)
    } else {
        (program.to_string(), base_args)
    };

    let status = Command::new(&exec_program)
        .args(&exec_args)
        .status()
        .map_err(|error| format!("Failed to execute {exec_program}: {error}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!(
            "Command failed: {} {}",
            exec_program,
            exec_args.join(" ")
        ))
    }
}

fn action_command(manager: PackageManager, action: Action) -> (&'static str, Vec<String>, bool) {
    match (manager, action) {
        (PackageManager::Nala, Action::Install) => {
            ("nala", vec!["install".into(), "-y".into()], true)
        }
        (PackageManager::Nala, Action::Remove) => {
            ("nala", vec!["remove".into(), "-y".into()], true)
        }
        (PackageManager::Apt, Action::Install) => {
            ("apt", vec!["install".into(), "-y".into()], true)
        }
        (PackageManager::Apt, Action::Remove) => {
            ("apt", vec!["autoremove".into(), "-y".into()], true)
        }
        (PackageManager::Yay, Action::Install) => {
            ("yay", vec!["-S".into(), "--noconfirm".into()], false)
        }
        (PackageManager::Yay, Action::Remove) => {
            ("yay", vec!["-R".into(), "--noconfirm".into()], false)
        }
        (PackageManager::Pacman, Action::Install) => {
            ("pacman", vec!["-S".into(), "--noconfirm".into()], true)
        }
        (PackageManager::Pacman, Action::Remove) => {
            ("pacman", vec!["-R".into(), "--noconfirm".into()], true)
        }
        (PackageManager::Dnf, Action::Install) => {
            ("dnf", vec!["install".into(), "-y".into()], true)
        }
        (PackageManager::Dnf, Action::Remove) => {
            ("dnf", vec!["remove".into(), "-y".into()], true)
        }
        (PackageManager::RpmOstree, Action::Install) => ("rpm-ostree", vec!["install".into()], true),
        (PackageManager::RpmOstree, Action::Remove) => {
            ("rpm-ostree", vec!["uninstall".into()], true)
        }
        (PackageManager::Zypper, Action::Install) => {
            ("zypper", vec!["install".into(), "-y".into()], true)
        }
        (PackageManager::Zypper, Action::Remove) => {
            ("zypper", vec!["remove".into(), "-y".into()], true)
        }
        (PackageManager::Apk, Action::Install) => ("apk", vec!["add".into()], true),
        (PackageManager::Apk, Action::Remove) => ("apk", vec!["del".into()], true),
        (PackageManager::Eopkg, Action::Install) => {
            ("eopkg", vec!["install".into(), "-y".into()], true)
        }
        (PackageManager::Eopkg, Action::Remove) => {
            ("eopkg", vec!["remove".into(), "-y".into()], true)
        }
        (PackageManager::Moss, Action::Install) => ("moss", vec!["install".into(), "-y".into()], false),
        (PackageManager::Moss, Action::Remove) => ("moss", vec!["remove".into(), "-y".into()], false),
        (PackageManager::XbpsInstall, Action::Install) => {
            ("xbps-install", vec!["-y".into()], true)
        }
        (PackageManager::XbpsInstall, Action::Remove) => ("xbps-remove", vec!["-y".into()], true),
        (PackageManager::Pkg, Action::Install) => ("pkg", vec!["install".into(), "-y".into()], true),
        (PackageManager::Pkg, Action::Remove) => ("pkg", vec!["remove".into(), "-y".into()], true),
        (PackageManager::Brew, Action::Install) => (
            "brew",
            vec!["install".into(), "--formula".into()],
            false,
        ),
        (PackageManager::Brew, Action::Remove) => (
            "brew",
            vec!["uninstall".into(), "--formula".into()],
            false,
        ),
    }
}

fn package_list(
    manager: PackageManager,
    kind: CacheKind,
    force_refresh: bool,
) -> Result<Vec<String>, String> {
    let cache_path = cache_path(manager, kind)?;
    let ttl = cache_ttl(kind);

    if !force_refresh {
        if let Some(cached) = read_cache_if_fresh(&cache_path, ttl) {
            return Ok(cached);
        }
    }

    let list = fetch_package_list(manager, kind)?;
    if list.is_empty() {
        if !force_refresh {
            if let Some(stale) = read_cache_any_age(&cache_path) {
                return Ok(stale);
            }
        }
        return Ok(list);
    }

    write_cache(&cache_path, &list)?;
    Ok(list)
}

fn fetch_package_list(manager: PackageManager, kind: CacheKind) -> Result<Vec<String>, String> {
    let raw = match (manager, kind) {
        (PackageManager::Nala, CacheKind::Available) | (PackageManager::Apt, CacheKind::Available) => {
            run_capture("apt-cache", &["pkgnames"])?
        }
        (PackageManager::Yay, CacheKind::Available) => run_capture("yay", &["-Slq"])?,
        (PackageManager::Pacman, CacheKind::Available) => run_capture("pacman", &["-Slq"])?,
        (PackageManager::Dnf, CacheKind::Available) => {
            run_capture("dnf", &["repoquery", "--qf", "%{name}\\n", "--quiet"])?
        }
        (PackageManager::RpmOstree, CacheKind::Available) => {
            run_capture("rpm", &["-qa", "--qf", "%{NAME}\\n"])?
        }
        (PackageManager::Zypper, CacheKind::Available) => {
            run_shell_capture("zypper se -s | awk 'NR>2 {print $2; print $3}' | grep -v '^[|]' | sort -u")?
        }
        (PackageManager::Apk, CacheKind::Available) => {
            run_shell_capture("apk search -v | awk -F'-[0-9]' '{print $1}'")?
        }
        (PackageManager::Eopkg, CacheKind::Available) => run_capture("eopkg", &["list-available"])?,
        (PackageManager::Moss, CacheKind::Available) => run_capture("moss", &["list", "available"])?,
        (PackageManager::XbpsInstall, CacheKind::Available) => {
            run_shell_capture("xbps-query -Rs '' | awk '{print $2}'")?
        }
        (PackageManager::Pkg, CacheKind::Available) => run_shell_capture("pkg search . | awk '{print $1}'")?,
        (PackageManager::Brew, CacheKind::Available) => run_capture("brew", &["formulae"])?,

        (PackageManager::Nala, CacheKind::Installed) | (PackageManager::Apt, CacheKind::Installed) => {
            run_capture("dpkg-query", &["-W", "-f=${Package}\\n"])?
        }
        (PackageManager::Yay, CacheKind::Installed) => run_capture("yay", &["-Qq"])?,
        (PackageManager::Pacman, CacheKind::Installed) => run_capture("pacman", &["-Qq"])?,
        (PackageManager::Dnf, CacheKind::Installed)
        | (PackageManager::RpmOstree, CacheKind::Installed)
        | (PackageManager::Zypper, CacheKind::Installed) => {
            run_capture("rpm", &["-qa", "--qf", "%{NAME}\\n"])?
        }
        (PackageManager::Apk, CacheKind::Installed) => {
            run_shell_capture("apk info | awk -F'-[0-9]' '{print $1}'")?
        }
        (PackageManager::Eopkg, CacheKind::Installed) => run_capture("eopkg", &["list-installed"])?,
        (PackageManager::Moss, CacheKind::Installed) => run_capture("moss", &["list", "installed"])?,
        (PackageManager::XbpsInstall, CacheKind::Installed) => {
            run_shell_capture("xbps-query -l | awk '{print $2}'")?
        }
        (PackageManager::Pkg, CacheKind::Installed) => run_capture("pkg", &["query", "-a", "%n"])?,
        (PackageManager::Brew, CacheKind::Installed) => {
            run_capture("brew", &["list", "--formula"])?
        }
    };

    let parsed = match manager {
        PackageManager::Eopkg => parse_eopkg_lines(&raw),
        PackageManager::Moss => parse_moss_lines(&raw),
        _ => parse_lines(&raw),
    };
    Ok(parsed)
}

fn parse_lines(raw: &str) -> Vec<String> {
    normalize_packages(raw.lines().map(|line| line.trim()))
}

fn parse_eopkg_lines(raw: &str) -> Vec<String> {
    let cleaned = strip_ansi(raw);
    normalize_packages(cleaned.lines().filter_map(|line| {
        let trimmed = line.trim();
        if trimmed.is_empty()
            || trimmed.starts_with("Repository")
            || trimmed.starts_with("Installed packages")
        {
            return None;
        }
        trimmed.split_whitespace().next()
    }))
}

fn parse_moss_lines(raw: &str) -> Vec<String> {
    normalize_packages(raw.lines().filter_map(|line| {
        let token = line.split_whitespace().next()?;
        if token.eq_ignore_ascii_case("name")
            || token.eq_ignore_ascii_case("available")
            || token.eq_ignore_ascii_case("installed")
            || token.starts_with('-')
        {
            return None;
        }
        Some(token)
    }))
}

fn normalize_packages<'a>(lines: impl IntoIterator<Item = &'a str>) -> Vec<String> {
    let mut set = HashSet::new();

    for line in lines {
        let candidate = line.trim();
        if candidate.is_empty() {
            continue;
        }
        let package = sanitize_package_name(candidate);
        if !package.is_empty() {
            set.insert(package);
        }
    }

    let mut sorted: Vec<String> = set.into_iter().collect();
    sorted.sort_unstable();
    sorted
}

fn sanitize_package_name(input: &str) -> String {
    let cleaned = strip_ansi(input).replace("✅", "");
    cleaned
        .split_whitespace()
        .next()
        .unwrap_or_default()
        .trim_matches('"')
        .to_string()
}

fn strip_ansi(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut out = String::with_capacity(input.len());
    let mut idx = 0;
    while idx < bytes.len() {
        if bytes[idx] == 0x1b {
            idx += 1;
            if idx < bytes.len() && bytes[idx] == b'[' {
                idx += 1;
                while idx < bytes.len() {
                    let b = bytes[idx];
                    idx += 1;
                    if (b as char).is_ascii_alphabetic() {
                        break;
                    }
                }
                continue;
            }
            continue;
        }

        out.push(bytes[idx] as char);
        idx += 1;
    }
    out
}

fn cache_ttl(kind: CacheKind) -> Duration {
    env::var(kind.env_ttl_key())
        .ok()
        .and_then(|value| value.parse::<u64>().ok())
        .map(Duration::from_secs)
        .unwrap_or_else(|| kind.default_ttl())
}

fn cache_path(manager: PackageManager, kind: CacheKind) -> Result<PathBuf, String> {
    let base_dir = cache_base_dir()?;
    fs::create_dir_all(&base_dir)
        .map_err(|error| format!("Failed to create cache directory {}: {error}", base_dir.display()))?;
    Ok(base_dir.join(format!("{}-{}.txt", manager.name(), kind.suffix())))
}

fn cache_base_dir() -> Result<PathBuf, String> {
    if let Some(path) = env::var_os("XDG_CACHE_HOME") {
        return Ok(PathBuf::from(path).join("pkg-tui"));
    }

    let home = env::var_os("HOME").ok_or_else(|| {
        "Neither XDG_CACHE_HOME nor HOME is set; cannot resolve cache directory.".to_string()
    })?;
    Ok(PathBuf::from(home).join(".cache").join("pkg-tui"))
}

fn read_cache_any_age(path: &Path) -> Option<Vec<String>> {
    let content = fs::read_to_string(path).ok()?;
    let parsed = parse_lines(&content);
    (!parsed.is_empty()).then_some(parsed)
}

fn read_cache_if_fresh(path: &Path, ttl: Duration) -> Option<Vec<String>> {
    let metadata = fs::metadata(path).ok()?;
    let modified = metadata.modified().ok()?;
    let age = modified.elapsed().ok()?;
    if age > ttl {
        return None;
    }
    read_cache_any_age(path)
}

fn write_cache(path: &Path, values: &[String]) -> Result<(), String> {
    let mut payload = values.join("\n");
    if !payload.is_empty() {
        payload.push('\n');
    }
    fs::write(path, payload).map_err(|error| format!("Failed to write cache {}: {error}", path.display()))
}

fn run_capture(program: &str, args: &[&str]) -> Result<String, String> {
    let output = Command::new(program)
        .args(args)
        .output()
        .map_err(|error| format!("Failed to execute {program}: {error}"))?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).into_owned())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!(
            "{program} failed ({}): {}",
            output.status,
            stderr.trim()
        ))
    }
}

fn run_shell_capture(command: &str) -> Result<String, String> {
    let output = Command::new("sh")
        .args(["-c", command])
        .output()
        .map_err(|error| format!("Failed to execute shell command: {error}"))?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).into_owned())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!(
            "Shell command failed ({}): {}",
            output.status,
            stderr.trim()
        ))
    }
}

fn current_uid() -> Option<u32> {
    let output = Command::new("id").arg("-u").output().ok()?;
    if !output.status.success() {
        return None;
    }
    String::from_utf8_lossy(&output.stdout).trim().parse().ok()
}

fn detect_escalation_tool() -> Option<String> {
    ["sudo-rs", "sudo", "doas"]
        .iter()
        .find_map(|tool| command_exists(tool).then(|| (*tool).to_string()))
}

fn command_exists(binary: &str) -> bool {
    if binary.contains('/') {
        return is_executable(Path::new(binary));
    }

    env::var_os("PATH").is_some_and(|paths| {
        env::split_paths(&paths)
            .map(|dir| dir.join(binary))
            .any(|path| is_executable(&path))
    })
}

fn is_executable(path: &Path) -> bool {
    path.metadata()
        .map(|meta| meta.is_file() && (meta.permissions().mode() & 0o111 != 0))
        .unwrap_or(false)
}
