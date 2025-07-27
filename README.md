# osutil

A cross-platform system utility tool with a modern TUI interface.

## Features

- **Cross-platform support**: Windows, macOS, and Linux
- **Modern TUI interface**: Built with Ratatui for a responsive and intuitive experience
- **Extensible script system**: Easy to add new scripts and utilities
- **Smart script execution**: Automatically detects interactive and heavy-operation scripts
- **Performance optimized**: PowerShell scripts with heavy operations run in separate terminals

## Installation

### Windows
```powershell
# Download and run the installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Jaredy899/osutil/main/install-windows.ps1" -OutFile "install-windows.ps1"
.\install-windows.ps1
```

### macOS
```bash
curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install-macos.sh | bash
```

### Linux
```bash
curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install-linux.sh | bash
```

## PowerShell Script Performance

On Windows, osutil automatically detects PowerShell scripts that would benefit from running in separate terminal windows:

### Automatic Detection

Scripts are automatically launched in separate terminals if they contain:

**Interactive elements:**
- `Read-Host` commands
- `Console::ReadLine` or `Console::ReadKey`
- `pause` commands

**Heavy operations:**
- `Invoke-WebRequest` or `Start-BitsTransfer` (downloads)
- `Install-Module` or `Install-PackageProvider` (package installations)
- `Add-WindowsCapability` (Windows features)
- `Get-WindowsUpdate` or `Install-WindowsUpdate` (system updates)
- `winget install`, `choco install`, `scoop install` (package managers)
- `Expand-Archive` (file extraction)
- `Start-Process` (process launching)
- `Invoke-RestMethod` or `Invoke-Expression` (API calls)
- Script execution with `& $localPath` or `& $scriptPath`

### Force All PowerShell Scripts to Run in Separate Terminals

If you want all PowerShell scripts to run in separate terminals for maximum performance, set the environment variable:

```powershell
$env:OSUTIL_FORCE_POWERSHELL_SEPARATE = "1"
```

Or set it permanently:
```powershell
[Environment]::SetEnvironmentVariable("OSUTIL_FORCE_POWERSHELL_SEPARATE", "1", "User")
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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
