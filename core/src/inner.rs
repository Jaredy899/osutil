use crate::{Command, ListNode, Tab};
use ego_tree::{NodeMut, Tree};
use include_dir::{include_dir, Dir};
use serde::Deserialize;
use std::{
    ops::{Deref, DerefMut},
    path::{Path, PathBuf},
    rc::Rc,
};

#[cfg(not(windows))]
use std::{
    fs::File,
    io::{BufRead, BufReader, Read},
};
use temp_dir::TempDir;

#[cfg(not(windows))]
use std::os::unix::fs::PermissionsExt;

const TAB_DATA: Dir = include_dir!("$CARGO_MANIFEST_DIR/tabs");

// Allow the unused TempDir to be stored for later destructor call
#[allow(dead_code)]
pub struct TabList(pub Vec<Tab>, TempDir);

// Implement deref to allow Vec<Tab> methods to be called on TabList
impl Deref for TabList {
    type Target = Vec<Tab>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for TabList {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}
impl IntoIterator for TabList {
    type Item = Tab;
    type IntoIter = std::vec::IntoIter<Self::Item>;

    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}

pub fn get_tabs(validate: bool) -> TabList {
    let (temp_dir, tab_files) = TabDirectories::get_tabs();

    let tabs: Vec<_> = tab_files
        .into_iter()
        .map(|path| {
            let directory = path.parent().unwrap().to_owned();
            println!("Trying to read: {:?}", path);
            let data = std::fs::read_to_string(&path).unwrap_or_else(|e| {
                panic!("Failed to read tab data at {:?}: {}", path, e);
            });
            let mut tab_data: TabEntry = toml::from_str(&data).expect("Failed to parse tab data");

            if validate {
                filter_entries(&mut tab_data.data);
            }
            (tab_data, directory)
        })
        .collect();

    let tabs: Vec<Tab> = tabs
        .into_iter()
        .map(|(TabEntry { name, data }, directory)| {
            let mut tree = Tree::new(Rc::new(ListNode {
                name: "root".to_string(),
                description: String::new(),
                command: Command::None,
                task_list: String::new(),
                multi_select: false,
            }));
            let mut root = tree.root_mut();
            create_directory(data, &mut root, &directory, validate, true);
            Tab { name, tree }
        })
        .collect();

    if tabs.is_empty() {
        panic!("No tabs found");
    }
    TabList(tabs, temp_dir)
}

#[derive(Deserialize)]
struct TabDirectories {
    directories: Vec<PathBuf>,
}

#[derive(Deserialize)]
struct TabEntry {
    name: String,
    data: Vec<Entry>,
}

#[derive(Deserialize)]
struct Entry {
    name: String,
    #[allow(dead_code)]
    #[serde(default)]
    description: String,
    #[serde(default)]
    preconditions: Option<Vec<Precondition>>,
    #[serde(flatten)]
    entry_type: EntryType,
    #[serde(default)]
    task_list: String,
    #[serde(default = "default_true")]
    multi_select: bool,
}

fn default_true() -> bool {
    true
}

#[derive(Deserialize)]
#[serde(rename_all = "snake_case")]
enum EntryType {
    Entries(Vec<Entry>),
    Command(String),
    Script(PathBuf),
}

impl Entry {
    fn is_supported(&self) -> bool {
        self.preconditions.as_deref().is_none_or(|preconditions| {
            preconditions.iter().all(
                |Precondition {
                     matches,
                     data,
                     values,
                 }| {
                    match data {
                        SystemDataType::Environment(var_name) => std::env::var(var_name)
                            .is_ok_and(|var| values.contains(&var) == *matches),
                        SystemDataType::ContainingFile(file) => std::fs::read_to_string(file)
                            .is_ok_and(|data| {
                                values
                                    .iter()
                                    .all(|matching| data.contains(matching) == *matches)
                            }),
                        SystemDataType::CommandExists => values
                            .iter()
                            .all(|command| which::which(command).is_ok() == *matches),
                        SystemDataType::FileExists => values.iter().all(|p| Path::new(p).is_file()),
                    }
                },
            )
        })
    }
}

#[derive(Deserialize)]
struct Precondition {
    // If true, the data must be contained within the list of values.
    // Otherwise, the data must not be contained within the list of values
    matches: bool,
    data: SystemDataType,
    values: Vec<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "snake_case")]
enum SystemDataType {
    Environment(String),
    ContainingFile(PathBuf),
    FileExists,
    CommandExists,
}

fn filter_entries(entries: &mut Vec<Entry>) {
    entries.retain_mut(|entry| {
        if !entry.is_supported() {
            return false;
        }
        if let EntryType::Entries(entries) = &mut entry.entry_type {
            filter_entries(entries);
            !entries.is_empty()
        } else {
            true
        }
    });
}

fn create_directory(
    data: Vec<Entry>,
    node: &mut NodeMut<Rc<ListNode>>,
    command_dir: &Path,
    validate: bool,
    parent_multi_select: bool,
) {
    for entry in data {
        let multi_select = parent_multi_select && entry.multi_select;

        match entry.entry_type {
            EntryType::Entries(entries) => {
                let mut node = node.append(Rc::new(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::None,
                    task_list: String::new(),
                    multi_select,
                }));
                create_directory(entries, &mut node, command_dir, validate, multi_select);
            }
            EntryType::Command(command) => {
                node.append(Rc::new(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::Raw(command),
                    task_list: String::new(),
                    multi_select,
                }));
            }
            EntryType::Script(script) => {
                let script_base_path = command_dir.join(&script);
                let script_path = if cfg!(windows) {
                    script_base_path.with_extension("ps1")
                } else {
                    script_base_path.with_extension("sh")
                };

                if script_path.exists() {
                    if let Some((executable, args)) = get_shebang(&script_path, validate) {
                        node.append(Rc::new(ListNode {
                            name: entry.name,
                            description: entry.description,
                            command: Command::LocalFile {
                                executable,
                                args,
                                file: script_path,
                            },
                            task_list: entry.task_list,
                            multi_select,
                        }));
                    }
                }
            }
        }
    }
}

#[cfg(windows)]
fn get_shebang(script_path: &Path, validate: bool) -> Option<(String, Vec<String>)> {
    if script_path.extension() == Some(std::ffi::OsStr::new("ps1")) {
        let executable = "powershell.exe".to_string();
        let is_valid = !validate || which::which(&executable).is_ok();
        if is_valid {
            Some((
                executable,
                vec![
                    "-NoProfile".to_string(),
                    "-ExecutionPolicy".to_string(),
                    "Bypass".to_string(),
                    "-File".to_string(),
                    script_path.to_string_lossy().to_string(),
                ],
            ))
        } else {
            None
        }
    } else {
        None
    }
}

#[cfg(not(windows))]
fn get_shebang(script_path: &Path, validate: bool) -> Option<(String, Vec<String>)> {
    let default_executable = || {
        if script_path.extension() == Some(std::ffi::OsStr::new("sh")) {
            let mut args = vec!["-e".to_string()];
            args.push(script_path.to_string_lossy().to_string());
            Some(("/bin/sh".into(), args))
        } else {
            None
        }
    };

    let script_file = match File::open(script_path) {
        Ok(file) => file,
        Err(_) => return default_executable(),
    };
    let mut reader = BufReader::new(script_file);

    let mut two_chars = [0; 2];
    if reader.read_exact(&mut two_chars).is_err() || two_chars != *b"#!" {
        return default_executable();
    }

    let first_line = match reader.lines().next() {
        Some(Ok(line)) => line,
        _ => return default_executable(),
    };

    let mut parts = first_line.split_whitespace();
    let Some(executable) = parts.next() else {
        return default_executable();
    };

    let is_valid = !validate || is_executable(Path::new(executable));

    is_valid.then(|| {
        let mut args: Vec<String> = parts.map(ToString::to_string).collect();
        args.push(script_path.to_string_lossy().to_string());
        (executable.to_string(), args)
    })
}

#[cfg(windows)]
#[allow(dead_code)]
fn is_executable(path: &Path) -> bool {
    path.is_file()
}

#[cfg(not(windows))]
fn is_executable(path: &Path) -> bool {
    path.metadata()
        .map(|metadata| metadata.is_file() && metadata.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

impl TabDirectories {
    fn get_tabs() -> (TempDir, Vec<PathBuf>) {
        let temp_dir = TempDir::with_prefix("macutil_scripts").unwrap();
        TAB_DATA
            .extract(&temp_dir)
            .expect("Failed to extract the saved directory");

        // Determine the platform and load the appropriate tabs.toml
        let platform = Self::detect_platform();
        let platform_tabs_file = temp_dir.path().join(platform).join("tabs.toml");
        let fallback_tabs_file = temp_dir.path().join("tabs.toml");
        
        let (tab_files, use_platform_paths) = if platform_tabs_file.exists() {
            (std::fs::read_to_string(&platform_tabs_file).expect("Failed to read platform tabs.toml"), true)
        } else {
            (std::fs::read_to_string(&fallback_tabs_file).expect("Failed to read tabs.toml"), false)
        };
        
        let data: Self = toml::from_str(&tab_files).expect("Failed to parse tabs.toml");
        let tab_paths = data
            .directories
            .iter()
            .map(|path| {
                if use_platform_paths {
                    temp_dir.path().join(platform).join(path).join("tab_data.toml")
                } else {
                    temp_dir.path().join(path).join("tab_data.toml")
                }
            })
            .collect();
        (temp_dir, tab_paths)
    }

    fn detect_platform() -> &'static str {
        if cfg!(target_os = "windows") {
            "windows"
        } else if cfg!(target_os = "macos") {
            "macos"
        } else {
            "linux"
        }
    }
}
