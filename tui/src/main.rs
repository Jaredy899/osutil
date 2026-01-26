mod cli;
mod confirmation;
mod filter;
mod float;
mod floating_text;
mod hint;
mod root;
mod running_command;
mod state;
mod theme;

use crate::cli::Args;
use clap::Parser;
use ratatui::{
    backend::CrosstermBackend,
    crossterm::{
        event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyEventKind},
        style::ResetColor,
        terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
        ExecutableCommand,
    },
    Terminal,
};
use running_command::TERMINAL_UPDATED;
use state::AppState;
use std::sync::atomic::{AtomicBool, Ordering as AtomicOrdering};
use std::{
    io::{stdout, Result, Stdout},
    sync::atomic::Ordering,
    time::Duration,
};

// Ensure we restore the terminal at most once
static TERMINAL_CLEANED: AtomicBool = AtomicBool::new(false);

fn cleanup_terminal(mouse_enabled: bool) {
    if TERMINAL_CLEANED.swap(true, AtomicOrdering::AcqRel) {
        return;
    }
    let _ = disable_raw_mode();
    let mut out = stdout();
    let _ = out.execute(LeaveAlternateScreen);
    if mouse_enabled {
        let _ = out.execute(DisableMouseCapture);
    }
    let _ = out.execute(ResetColor);
    let _ = out.execute(ratatui::crossterm::cursor::Show);
}

struct TerminalCleanupGuard {
    mouse: bool,
}

impl Drop for TerminalCleanupGuard {
    fn drop(&mut self) {
        cleanup_terminal(self.mouse);
    }
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut state = AppState::new(args.clone());

    stdout().execute(EnterAlternateScreen)?;
    if args.mouse {
        stdout().execute(EnableMouseCapture)?;
    }

    enable_raw_mode()?;
    let _cleanup_guard = TerminalCleanupGuard { mouse: args.mouse };

    // Ensure cleanup on panic and Ctrl-C
    {
        let mouse_flag = args.mouse;
        std::panic::set_hook(Box::new(move |_| {
            cleanup_terminal(mouse_flag);
        }));
    }
    {
        let mouse_flag = args.mouse;
        let _ = ctrlc::set_handler(move || {
            cleanup_terminal(mouse_flag);
            std::process::exit(130);
        });
    }

    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    run(&mut terminal, &mut state)?;

    // restore terminal
    cleanup_terminal(args.mouse);

    Ok(())
}

fn run(terminal: &mut Terminal<CrosstermBackend<Stdout>>, state: &mut AppState) -> Result<()> {
    loop {
        // Wait briefly for an input event
        if !event::poll(Duration::from_millis(50))? {
            // No input event: if there was output, reset the flag
            let _ =
                TERMINAL_UPDATED.compare_exchange(true, false, Ordering::AcqRel, Ordering::Acquire);
            // Redraw periodically to reflect any new output
            terminal.draw(|frame| state.draw(frame)).unwrap();
            continue;
        }

        // It's guaranteed that the `read()` won't block when the `poll()`
        // function returns `true`
        match event::read()? {
            Event::Key(key) => {
                if key.kind != KeyEventKind::Press && key.kind != KeyEventKind::Repeat {
                    continue;
                }

                if !state.handle_key(&key) {
                    return Ok(());
                }
            }
            Event::Mouse(mouse_event) => {
                if !state.handle_mouse(&mouse_event) {
                    return Ok(());
                }
            }
            _ => {}
        }
        terminal.draw(|frame| state.draw(frame)).unwrap();
    }
}
