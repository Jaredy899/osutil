use crate::{float::FloatContent, hint::Shortcut, shortcuts, theme::Theme};
#[cfg(not(windows))]
use oneshot::channel;
use oneshot::Receiver;
use osutil_core::Command;
use portable_pty::{ChildKiller, ExitStatus, MasterPty, PtySize};
#[cfg(not(windows))]
use portable_pty::{CommandBuilder, NativePtySystem, PtySystem};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers, MouseEvent, MouseEventKind},
    prelude::*,
    symbols::border,
    widgets::Block,
};
use std::{
    fs::File,
    io::{Result, Write},
    sync::{atomic::AtomicBool, Arc, Mutex},
    thread::JoinHandle,
};

#[cfg(not(windows))]
use std::sync::atomic::Ordering;
use time::{macros::format_description, OffsetDateTime};
use tui_term::widget::PseudoTerminal;
use vt100_ctt::{Parser, Screen};

// Dummy PTY for error cases
#[allow(dead_code)]
struct DummyPty;

impl portable_pty::MasterPty for DummyPty {
    fn resize(&self, _size: portable_pty::PtySize) -> anyhow::Result<()> {
        Ok(())
    }

    fn get_size(&self) -> anyhow::Result<portable_pty::PtySize> {
        Ok(portable_pty::PtySize {
            rows: 24,
            cols: 80,
            pixel_width: 0,
            pixel_height: 0,
        })
    }

    fn take_writer(&self) -> anyhow::Result<Box<dyn Write + Send>> {
        Ok(Box::new(std::io::sink()))
    }

    fn try_clone_reader(&self) -> anyhow::Result<Box<dyn std::io::Read + Send>> {
        Ok(Box::new(std::io::empty()))
    }

    #[cfg(unix)]
    fn tty_name(&self) -> Option<std::path::PathBuf> {
        None
    }

    #[cfg(unix)]
    fn process_group_leader(&self) -> Option<i32> {
        None
    }

    #[cfg(unix)]
    fn as_raw_fd(&self) -> Option<i32> {
        None
    }
}

pub struct RunningCommand {
    /// A buffer to save all the command output (accumulates, until the command exits)
    buffer: Arc<Mutex<Vec<u8>>>,
    /// A handle for the thread running the command
    command_thread: Option<JoinHandle<ExitStatus>>,
    /// A handle to kill the running process; it's an option because it can only be used once
    child_killer: Option<Receiver<Box<dyn ChildKiller + Send + Sync>>>,
    /// A join handle for the thread that reads command output and sends it to the main thread
    _reader_thread: JoinHandle<()>,
    /// Virtual terminal (pty) handle, used for resizing the pty
    pty_master: Box<dyn MasterPty + Send>,
    /// Used for sending keys to the emulated terminal (or child stdin on Windows)
    writer: Box<dyn Write + Send>,
    /// Only set after the process has ended
    status: Option<ExitStatus>,
    log_path: Option<String>,
    scroll_offset: usize,
    #[cfg(windows)]
    child_pid: Option<u32>,
}

impl FloatContent for RunningCommand {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        // Define the block for the terminal display
        let block = if !self.is_finished() {
            // Display a block indicating the command is running
            Block::bordered()
                .border_set(border::ROUNDED)
                .title_top(Line::from("Running the command....").centered())
                .title_style(Style::default().reversed())
                .title_bottom(Line::from("Press Ctrl-C to KILL the command"))
        } else {
            // Display a block with the command's exit status
            let title_line = if self.get_exit_status().success() {
                Line::styled(
                    "SUCCESS! Press <ENTER> to close this window",
                    Style::default().fg(theme.success_color()).reversed(),
                )
            } else {
                Line::styled(
                    "FAILED! Press <ENTER> to close this window",
                    Style::default().fg(theme.fail_color()).reversed(),
                )
            };

            let log_path = if let Some(log_path) = &self.log_path {
                Line::from(format!(" Log saved: {log_path} "))
            } else {
                Line::from(" Press 'l' to save command log ")
            };

            Block::bordered()
                .border_set(border::ROUNDED)
                .title_top(title_line.centered())
                .title_bottom(log_path.centered())
        };

        // Calculate the inner size of the terminal area, considering borders
        let inner_size = block.inner(area).as_size();
        // Process the buffer and create the pseudo-terminal widget
        let screen = self.screen(inner_size);
        let pseudo_term = PseudoTerminal::new(&screen).block(block);

        // Render the widget on the frame
        frame.render_widget(pseudo_term, area);
    }

    fn handle_mouse_event(&mut self, event: &MouseEvent) -> bool {
        match event.kind {
            MouseEventKind::ScrollUp => {
                self.scroll_offset = self.scroll_offset.saturating_add(1);
            }
            MouseEventKind::ScrollDown => {
                self.scroll_offset = self.scroll_offset.saturating_sub(1);
            }
            _ => {}
        }
        true
    }
    /// Handle key events of the running command "window". Returns true when the "window" should be
    /// closed
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            // Handle Ctrl-C to kill the command
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.kill_child();
            }
            // Close the window when Enter is pressed and the command is finished
            KeyCode::Enter if self.is_finished() => {
                return true;
            }
            KeyCode::PageUp => {
                self.scroll_offset = self.scroll_offset.saturating_add(10);
            }
            KeyCode::PageDown => {
                self.scroll_offset = self.scroll_offset.saturating_sub(10);
            }
            KeyCode::Char('l') if self.is_finished() => {
                if let Ok(log_path) = self.save_log() {
                    self.log_path = Some(log_path);
                }
            }
            // Pass other key events to the terminal
            _ => self.handle_passthrough_key_event(key),
        }
        false
    }

    fn is_finished(&self) -> bool {
        // Check if the command thread has finished
        if let Some(command_thread) = &self.command_thread {
            command_thread.is_finished()
        } else {
            true
        }
    }

    fn get_shortcut_list(&self) -> (&str, Box<[Shortcut]>) {
        if self.is_finished() {
            (
                "Finished command",
                shortcuts!(
                    ("Close window", ["Enter", "q"]),
                    ("Scroll up", ["Page up"]),
                    ("Scroll down", ["Page down"]),
                    ("Save log", ["l"]),
                ),
            )
        } else {
            (
                "Running command",
                shortcuts!(
                    ("Kill the command", ["CTRL-c"]),
                    ("Scroll up", ["Page up"]),
                    ("Scroll down", ["Page down"]),
                ),
            )
        }
    }
}
pub static TERMINAL_UPDATED: AtomicBool = AtomicBool::new(true);

impl RunningCommand {
    #[cfg(not(windows))]
    pub fn new(commands: &[&Command]) -> Self {
        let pty_system = NativePtySystem::default();

        // Build the command based on the provided Command enum variant
        let mut cmd: CommandBuilder = CommandBuilder::new("sh");
        cmd.arg("-c");

        // All the merged commands are passed as a single argument to reduce the overhead of rebuilding the command arguments for each and every command
        let mut script = String::new();
        for command in commands {
            match command {
                Command::Raw(prompt) => script.push_str(&format!("{prompt}\n")),
                Command::LocalFile {
                    executable,
                    args,
                    file,
                } => {
                    if let Some(parent_directory) = file.parent() {
                        script.push_str(&format!("cd {}\n", parent_directory.display()));
                    }
                    script.push_str(executable);
                    for arg in args {
                        script.push(' ');
                        script.push_str(arg);
                    }
                    script.push('\n'); // Ensures that each command is properly separated for execution preventing directory errors
                }
                Command::None => panic!("Command::None was treated as a command"),
            }
        }

        cmd.arg(script);

        // Open a pseudo-terminal with initial size
        let pair = pty_system
            .openpty(PtySize {
                rows: 24, // Initial number of rows (will be updated dynamically)
                cols: 80, // Initial number of columns (will be updated dynamically)
                pixel_width: 0,
                pixel_height: 0,
            })
            .unwrap();

        let (tx, rx) = channel();
        // Thread waiting for the child to complete
        let command_handle = std::thread::spawn(move || {
            let mut child = pair.slave.spawn_command(cmd).unwrap();
            let killer = child.clone_killer();
            tx.send(killer).unwrap();
            child.wait().unwrap()
        });

        let mut reader = pair.master.try_clone_reader().unwrap(); // This is a reader, this is where we

        // A buffer, shared between the thread that reads the command output, and the main tread.
        // The main thread only reads the contents
        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));
        TERMINAL_UPDATED.store(true, Ordering::Release);
        let reader_handle = {
            // Arc is just a reference, so we can create an owned copy without any problem
            let command_buffer = command_buffer.clone();
            // The closure below moves all variables used into it, so we can no longer use them,
            // that's why command_buffer.clone(), because we need to use command_buffer later
            std::thread::spawn(move || {
                let mut buf = [0u8; 8192];
                loop {
                    let size = reader.read(&mut buf).unwrap(); // Can block here
                    if size == 0 {
                        break; // EOF
                    }
                    let mut mutex = command_buffer.lock(); // Only lock the mutex after the read is
                                                           // done, to minimise the time it is opened
                    let command_buffer = mutex.as_mut().unwrap();
                    command_buffer.extend_from_slice(&buf[0..size]);
                    TERMINAL_UPDATED.store(true, Ordering::Release);
                    // The mutex is closed here automatically
                }
                TERMINAL_UPDATED.store(true, Ordering::Release);
            })
        };

        let writer = pair.master.take_writer().unwrap();
        Self {
            buffer: command_buffer,
            command_thread: Some(command_handle),
            child_killer: Some(rx),
            _reader_thread: reader_handle,
            pty_master: pair.master,
            writer,
            status: None,
            log_path: None,
            scroll_offset: 0,
        }
    }

    #[allow(dead_code)]
    pub fn new_with_names(commands: &[&Command], _script_names: &[String]) -> Self {
        #[cfg(not(windows))]
        {
            Self::new(commands)
        }

        #[cfg(windows)]
        {
            // Use Windows-specific implementation
            use crate::windows_runner::WindowsCommandRunner;
            let command = commands.first().expect("No commands provided");

            let windows_runner = WindowsCommandRunner::new(command);

            Self {
                buffer: windows_runner.buffer,
                command_thread: windows_runner.command_thread,
                child_killer: None,
                _reader_thread: windows_runner._reader_thread,
                pty_master: Box::new(DummyPty),
                writer: windows_runner.stdin_writer,
                status: windows_runner.status,
                log_path: None,
                scroll_offset: 0,
                child_pid: windows_runner.child_pid,
            }
        }

        // Windows-specific fallback removed (unused)
    }

    fn screen(&mut self, size: Size) -> Screen {
        // Resize the emulated pty
        if let Err(e) = self.pty_master.resize(PtySize {
            rows: size.height,
            cols: size.width,
            pixel_width: 0,
            pixel_height: 0,
        }) {
            // Log the error but don't panic - this allows the TUI to continue
            eprintln!("Failed to resize PTY: {e}");
        }

        // Process the buffer with a parser with the current screen size
        // We don't actually need to create a new parser every time, but it is so much easier this
        // way, and doesn't cost that much
        let mut parser = Parser::new(size.height, size.width, 1000);
        if let Ok(mutex) = self.buffer.lock() {
            parser.process(&mutex);
            // Adjust the screen content based on the scroll offset
            parser.screen_mut().set_scrollback(self.scroll_offset);
        }
        parser.screen().clone()
    }

    /// This function will block if the command is not finished
    fn get_exit_status(&mut self) -> ExitStatus {
        if self.command_thread.is_some() {
            if let Some(handle) = self.command_thread.take() {
                if let Ok(exit_status) = handle.join() {
                    self.status = Some(exit_status.clone());
                    return exit_status;
                }
            }
        }
        // Return a default exit status if we can't get the real one
        self.status
            .as_ref()
            .cloned()
            .unwrap_or_else(|| ExitStatus::with_exit_code(1))
    }

    /// Send SIGHUB signal, *not* SIGKILL or SIGTERM, to the child process
    pub fn kill_child(&mut self) {
        if !self.is_finished() {
            #[cfg(not(windows))]
            {
                if let Some(rx) = self.child_killer.take() {
                    if let Ok(mut killer) = rx.recv() {
                        if let Err(e) = killer.kill() {
                            eprintln!("Failed to kill child process: {e}");
                        }
                    }
                }
            }
            #[cfg(windows)]
            {
                if let Some(pid) = self.child_pid {
                    let _ = std::process::Command::new("taskkill")
                        .args(["/T", "/F", "/PID", &pid.to_string()])
                        .spawn();
                }
            }
        }
    }

    fn save_log(&self) -> Result<String> {
        let mut log_path = std::env::temp_dir();
        let date_format = format_description!("[year]-[month]-[day]-[hour]-[minute]-[second]");
        log_path.push(format!(
            "osutil_log_{}.log",
            OffsetDateTime::now_local()
                .unwrap_or(OffsetDateTime::now_utc())
                .format(&date_format)
                .unwrap()
        ));

        let mut file = File::create(&log_path)?;
        let buffer = self.buffer.lock().unwrap();
        file.write_all(&buffer)?;

        Ok(log_path.to_string_lossy().into_owned())
    }

    /// Get PowerShell executable (prefer PowerShell 7, fallback to PowerShell 5)
    #[cfg(windows)]
    #[allow(dead_code)]
    fn get_powershell_executable() -> Option<String> {
        // First try PowerShell 7 (pwsh.exe)
        let pwsh = "pwsh.exe";
        let pwsh_valid = which::which(pwsh).is_ok()
            || std::path::Path::new("C:\\Program Files\\PowerShell\\7\\pwsh.exe").exists()
            || std::path::Path::new("C:\\Program Files (x86)\\PowerShell\\7\\pwsh.exe").exists();

        if pwsh_valid {
            return Some(pwsh.to_string());
        }

        // Fallback to PowerShell 5 (powershell.exe)
        let powershell = "powershell.exe";
        let powershell_valid = which::which(powershell).is_ok()
            || std::path::Path::new(
                "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
            )
            .exists();

        if powershell_valid {
            Some(powershell.to_string())
        } else {
            None
        }
    }

    /// Launch an interactive PowerShell script in a separate terminal window
    #[cfg(windows)]
    #[allow(dead_code)]
    pub fn launch_in_separate_terminal(command: &Command, script_name: Option<String>) -> Self {
        if let Command::LocalFile {
            executable: _,
            args: _,
            file,
        } = command
        {
            // Get PowerShell executable (prefer 7, fallback to 5)
            let powershell_exe = match Self::get_powershell_executable() {
                Some(exe) => exe,
                None => {
                    // No PowerShell found - show error
                    let message = "ERROR!\r\n\r\nNo PowerShell installation found.\r\n\r\nPlease install PowerShell 7 from: https://github.com/PowerShell/PowerShell/releases\r\n\r\nOr ensure PowerShell 5 is available in the system PATH.\r\n\r\nPress Enter to continue...";

                    return Self {
                        buffer: Arc::new(Mutex::new(message.as_bytes().to_vec())),
                        command_thread: None,
                        child_killer: None,
                        _reader_thread: std::thread::spawn(|| {}),
                        pty_master: Box::new(DummyPty),
                        writer: Box::new(std::io::sink()),
                        status: Some(ExitStatus::with_exit_code(1)),
                        log_path: None,
                        scroll_offset: 0,
                    };
                }
            };

            // Launch in a new PowerShell window with the script file
            let result = std::process::Command::new("cmd")
                .args([
                    "/c",
                    "start",
                    &powershell_exe,
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    &file.to_string_lossy(),
                ])
                .spawn();

            match result {
                Ok(_) => {
                    // Use TOML name if available, otherwise use filename
                    let display_name = if let Some(name) = script_name {
                        if name.len() > 25 {
                            format!("{}...", &name[..22])
                        } else {
                            name
                        }
                    } else {
                        let script_name = file.file_name().unwrap_or_default().to_string_lossy();
                        if script_name.len() > 15 {
                            format!("{}...", &script_name[..12])
                        } else {
                            script_name.to_string()
                        }
                    };

                    // Create a properly formatted multi-line message
                    let message = format!("SUCCESS!\r\n\r\nScript '{display_name}' launched in separate terminal.\r\n\r\nPress Enter to continue...");

                    // Create a dummy RunningCommand that shows success
                    Self {
                        buffer: Arc::new(Mutex::new(message.into_bytes())),
                        command_thread: None,
                        child_killer: None,
                        _reader_thread: std::thread::spawn(|| {}),
                        pty_master: Box::new(DummyPty),
                        writer: Box::new(std::io::sink()),
                        status: Some(ExitStatus::with_exit_code(0)),
                        log_path: None,
                        scroll_offset: 0,
                    }
                }
                Err(e) => {
                    // Truncate error message if it's too long
                    let error_msg = e.to_string();
                    let display_error = if error_msg.len() > 20 {
                        format!("{}...", &error_msg[..17])
                    } else {
                        error_msg
                    };

                    // Create a properly formatted multi-line error message
                    let message = format!("ERROR!\r\n\r\nFailed to launch script: {display_error}.\r\n\r\nFalling back to TUI...");

                    // Create a dummy RunningCommand that shows error
                    Self {
                        buffer: Arc::new(Mutex::new(message.into_bytes())),
                        command_thread: None,
                        child_killer: None,
                        _reader_thread: std::thread::spawn(|| {}),
                        pty_master: Box::new(DummyPty),
                        writer: Box::new(std::io::sink()),
                        status: Some(ExitStatus::with_exit_code(1)),
                        log_path: None,
                        scroll_offset: 0,
                    }
                }
            }
        } else {
            // Fallback for non-LocalFile commands
            Self {
                buffer: Arc::new(Mutex::new(
                    "ERROR!\r\n\r\nCannot launch in separate terminal.\r\n\r\nFalling back to TUI...".as_bytes().to_vec()
                )),
                command_thread: None,
                child_killer: None,
                _reader_thread: std::thread::spawn(|| {}),
                pty_master: Box::new(DummyPty),
                writer: Box::new(std::io::sink()),
                status: Some(ExitStatus::with_exit_code(1)),
                log_path: None,
                scroll_offset: 0,
            }
        }
    }

    /// Convert the KeyEvent to pty key codes, and send them to the virtual terminal
    fn handle_passthrough_key_event(&mut self, key: &KeyEvent) {
        let input_bytes = match key.code {
            KeyCode::Char(ch) => {
                let raw_utf8 = || ch.to_string().into_bytes();

                match ch.to_ascii_uppercase() {
                    _ if key.modifiers != KeyModifiers::CONTROL => raw_utf8(),
                    // https://github.com/fyne-io/terminal/blob/master/input.go
                    // https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
                    '2' | '@' | ' ' => vec![0],
                    '3' | '[' => vec![27],
                    '4' | '\\' => vec![28],
                    '5' | ']' => vec![29],
                    '6' | '^' => vec![30],
                    '7' | '-' | '_' => vec![31],
                    c if ('A'..='_').contains(&c) => {
                        let ascii_val = c as u8;
                        let ascii_to_send = ascii_val - 64;
                        vec![ascii_to_send]
                    }
                    _ => raw_utf8(),
                }
            }
            KeyCode::Enter => vec![b'\n'],
            KeyCode::Backspace => vec![0x7f],
            KeyCode::Left => vec![27, 91, 68],
            KeyCode::Right => vec![27, 91, 67],
            KeyCode::Up => vec![27, 91, 65],
            KeyCode::Down => vec![27, 91, 66],
            KeyCode::Tab => vec![9],
            KeyCode::Home => vec![27, 91, 72],
            KeyCode::End => vec![27, 91, 70],
            KeyCode::BackTab => vec![27, 91, 90],
            KeyCode::Delete => vec![27, 91, 51, 126],
            KeyCode::Insert => vec![27, 91, 50, 126],
            KeyCode::Esc => vec![27],
            _ => return,
        };

        // Send the keycodes to the virtual terminal
        if let Err(e) = self.writer.write_all(&input_bytes) {
            // Log the error but don't panic - this allows the TUI to continue
            eprintln!("Failed to write to PTY: {e}");
        }

        // Flush the writer to ensure the data is sent immediately
        if let Err(e) = self.writer.flush() {
            eprintln!("Failed to flush PTY writer: {e}");
        }
    }
}
