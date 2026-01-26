use crate::{float::FloatContent, hint::Shortcut, shortcuts, theme::Theme};
use oneshot::{channel, Receiver};
use osutil_core::Command;
use portable_pty::{
    ChildKiller, CommandBuilder, ExitStatus, MasterPty, NativePtySystem, PtySize, PtySystem,
};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers, MouseEvent, MouseEventKind},
    prelude::*,
    symbols::border,
    widgets::Block,
};
use std::{
    fs::File,
    io::{Read, Result, Write},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    thread::JoinHandle,
};
use time::{macros::format_description, OffsetDateTime};
use tui_term::widget::PseudoTerminal;
use vt100_ctt::{Parser, Screen};

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
    /// Used for sending keys to the emulated terminal
    writer: Box<dyn Write + Send>,
    /// Only set after the process has ended
    status: Option<ExitStatus>,
    log_path: Option<String>,
    scroll_offset: usize,
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
            // Pass Enter key to running command for user input
            KeyCode::Enter if !self.is_finished() => {
                self.handle_passthrough_key_event(key);
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

/// Get the shell and argument for Unix platforms
fn get_shell() -> (&'static str, &'static str) {
    ("sh", "-c")
}

impl RunningCommand {
    pub fn new(commands: &[&Command]) -> Self {
        let pty_system = NativePtySystem::default();

        // Get platform-specific shell
        let (shell, shell_arg) = get_shell();

        // Build the command based on the provided Command enum variant
        let mut cmd: CommandBuilder = CommandBuilder::new(shell);
        cmd.arg(shell_arg);

        // Set environment variables needed for interactive TUI tools
        cmd.env("TERM", "xterm-256color");
        cmd.env("COLORTERM", "truecolor");
        cmd.env("FORCE_COLOR", "1");
        cmd.env("NO_COLOR", "");
        // Mark that we are running under the OSutil TUI so scripts can detect this
        cmd.env("OSUTIL_TUI_MODE", "1");

        // Build the script from all commands
        let mut script = String::new();

        for command in commands {
            match command {
                Command::Raw(prompt) => {
                    script.push_str(prompt);
                    script.push('\n');
                }
                Command::LocalFile {
                    executable,
                    args,
                    file,
                } => {
                    // Change to the script's directory first
                    if let Some(parent_directory) = file.parent() {
                        script.push_str(&format!("cd '{}'\n", parent_directory.display()));
                    }

                    // Add the command
                    script.push_str(executable);
                    for arg in args {
                        script.push(' ');
                        script.push_str(arg);
                    }
                    script.push('\n');
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

        let mut reader = pair.master.try_clone_reader().unwrap();

        // A buffer, shared between the thread that reads the command output, and the main thread.
        // The main thread only reads the contents
        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));
        TERMINAL_UPDATED.store(true, Ordering::Release);
        let reader_handle = {
            let command_buffer = command_buffer.clone();
            std::thread::spawn(move || {
                let mut buf = [0u8; 8192];
                loop {
                    match reader.read(&mut buf) {
                        Ok(size) => {
                            if size == 0 {
                                break; // EOF
                            }
                            let mut mutex = command_buffer.lock();
                            let command_buffer = mutex.as_mut().unwrap();
                            command_buffer.extend_from_slice(&buf[0..size]);
                            TERMINAL_UPDATED.store(true, Ordering::Release);
                        }
                        Err(e) => {
                            eprintln!("Error reading from terminal: {}", e);
                            break;
                        }
                    }
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

    /// Create a new RunningCommand with script names (for logging purposes)
    /// This is now just an alias for new() since script names are not currently used
    pub fn new_with_names(commands: &[&Command], _script_names: &[String]) -> Self {
        Self::new(commands)
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

    /// Kill the child process
    pub fn kill_child(&mut self) {
        if !self.is_finished() {
            if let Some(rx) = self.child_killer.take() {
                if let Ok(mut killer) = rx.recv() {
                    if let Err(e) = killer.kill() {
                        eprintln!("Failed to kill child process: {e}");
                    }
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
            KeyCode::Enter => vec![b'\r'],
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
            eprintln!("Failed to write to terminal: {}", e);
        }
        // Ensure the data is flushed immediately, especially important for Enter key
        if let Err(e) = self.writer.flush() {
            eprintln!("Failed to flush terminal: {}", e);
        }
    }
}
