# OSutil

A cross-platform system utility tool with a modern TUI interface.

## Features

- **Cross-platform support**: Windows, macOS, and Linux
- **Modern TUI interface**: Built with Ratatui for a responsive and intuitive experience
- **Extensible script system**: Easy to add new scripts and utilities
- **Smart script execution**: Automatically detects interactive and heavy-operation scripts
- **Performance optimized**: PowerShell scripts with heavy operations run in separate terminals

## Installation

### macOS & Linux

```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install.sh)
```

### Windows

```powershell
irm https://raw.githubusercontent.com/Jaredy899/osutil/main/install-windows.ps1 | iex
```

## Usage

Run the application:

```bash
osutil
```

Use arrow keys to navigate, Enter to select, and Esc to go back.

## Development

### Prerequisites

- Rust 1.70+
- Cargo

### Build

```bash
cargo build --release
```

### Run in development mode

```bash
cargo run
```

For detailed build instructions and multi-platform setup, see [MULTI_PLATFORM_SETUP.md](MULTI_PLATFORM_SETUP.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
