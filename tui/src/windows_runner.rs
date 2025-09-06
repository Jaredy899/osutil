use crate::running_command::TERMINAL_UPDATED;
use osutil_core::Command;
use portable_pty::ExitStatus;
use std::io::{Read, Write};
use std::process::{Command as StdCommand, Stdio};
use std::sync::{atomic::Ordering, Arc, Mutex};
use std::thread::JoinHandle;

pub struct WindowsCommandRunner {
    pub buffer: Arc<Mutex<Vec<u8>>>,
    pub command_thread: Option<JoinHandle<ExitStatus>>,
    pub _reader_thread: JoinHandle<()>,
    pub status: Option<ExitStatus>,
    pub stdin_writer: Box<dyn Write + Send>,
    pub child_pid: Option<u32>,
}

struct WindowsStdin(Arc<Mutex<std::process::ChildStdin>>);
impl Write for WindowsStdin {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        if let Ok(mut guard) = self.0.lock() {
            let result = guard.write(buf);
            // Ensure immediate flush for interactive input
            let _ = guard.flush();
            result
        } else {
            Ok(0)
        }
    }
    fn flush(&mut self) -> std::io::Result<()> {
        if let Ok(mut guard) = self.0.lock() {
            guard.flush()
        } else {
            Ok(())
        }
    }
}

impl WindowsCommandRunner {
    pub fn new(command: &Command) -> Self {
        let (executable, args) = match command {
            Command::Raw(prompt) => (
                "cmd.exe".to_string(),
                vec!["/c".to_string(), prompt.clone()],
            ),
            Command::LocalFile {
                executable,
                args,
                file: _,
            } => (executable.clone(), args.clone()),
            Command::None => panic!("Command::None was treated as a command"),
        };

        let mut cmd = StdCommand::new(&executable);
        for arg in &args {
            cmd.arg(arg);
        }

        // Set working directory if it's a LocalFile command
        if let Command::LocalFile { file, .. } = command {
            if let Some(parent_directory) = file.parent() {
                cmd.current_dir(parent_directory);
            }
        }

        // Mark that we are running under the OSutil TUI so scripts can avoid Start-Process
        cmd.env("OSUTIL_TUI_MODE", "1");
        // Hints for better ANSI behavior
        cmd.env("TERM", "xterm-256color");
        cmd.env("COLORTERM", "truecolor");
        cmd.env("ANSICON", "1");

        // Capture both stdout and stderr, enable stdin for interactive input
        cmd.stdout(Stdio::piped());
        cmd.stderr(Stdio::piped());
        cmd.stdin(Stdio::piped());

        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));

        match cmd.spawn() {
            Ok(mut child) => {
                let mut stdout = child.stdout.take().unwrap();
                let mut stderr = child.stderr.take().unwrap();
                let stdin = Arc::new(Mutex::new(child.stdin.take().unwrap()));
                let stdin_writer: Box<dyn Write + Send> = Box::new(WindowsStdin(stdin));
                let pid = child.id();

                let buffer_clone = command_buffer.clone();
                let reader_handle = std::thread::spawn(move || {
                    let mut stdout_buf = [0u8; 1024];
                    let mut stderr_buf = [0u8; 1024];

                    // Read stdout
                    loop {
                        match stdout.read(&mut stdout_buf) {
                            Ok(0) => break,
                            Ok(size) => {
                                if let Ok(mut mutex) = buffer_clone.lock() {
                                    mutex.extend_from_slice(&stdout_buf[0..size]);
                                    TERMINAL_UPDATED.store(true, Ordering::Release);
                                }
                            }
                            Err(_) => break,
                        }
                    }

                    // Read stderr
                    loop {
                        match stderr.read(&mut stderr_buf) {
                            Ok(0) => break,
                            Ok(size) => {
                                if let Ok(mut mutex) = buffer_clone.lock() {
                                    mutex.extend_from_slice(&stderr_buf[0..size]);
                                    TERMINAL_UPDATED.store(true, Ordering::Release);
                                }
                            }
                            Err(_) => break,
                        }
                    }
                });

                let command_handle = std::thread::spawn(move || match child.wait() {
                    Ok(status) => {
                        if let Some(code) = status.code() {
                            ExitStatus::with_exit_code(code as u32)
                        } else {
                            ExitStatus::with_exit_code(1)
                        }
                    }
                    Err(_) => ExitStatus::with_exit_code(1),
                });

                Self {
                    buffer: command_buffer,
                    command_thread: Some(command_handle),
                    _reader_thread: reader_handle,
                    status: None,
                    stdin_writer,
                    child_pid: Some(pid),
                }
            }
            Err(e) => {
                let error_msg = format!("Failed to execute command: {e}\r\n");
                Self {
                    buffer: Arc::new(Mutex::new(error_msg.as_bytes().to_vec())),
                    command_thread: None,
                    _reader_thread: std::thread::spawn(|| {}),
                    status: Some(ExitStatus::with_exit_code(1)),
                    stdin_writer: Box::new(std::io::sink()),
                    child_pid: None,
                }
            }
        }
    }

    #[allow(dead_code)]
    pub fn get_exit_status(&mut self) -> ExitStatus {
        if self.command_thread.is_some() {
            if let Some(handle) = self.command_thread.take() {
                if let Ok(exit_status) = handle.join() {
                    self.status = Some(exit_status.clone());
                    return exit_status;
                }
            }
        }

        self.status
            .clone()
            .unwrap_or_else(|| ExitStatus::with_exit_code(1))
    }
}
