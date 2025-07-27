# OSutil

A simple utility tool for system management and application setup, now supporting Linux, macOS, and Windows.

## Installation

### Quick Install (Recommended)

#### Linux
```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install-linux.sh)
```

#### macOS
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install-macos.sh)
```

#### Windows
```powershell
irm https://raw.githubusercontent.com/Jaredy899/osutil/main/install-windows.ps1 | iex
```

**Troubleshooting Windows Installation:**

If you encounter download errors, try these steps:

1. **Check PowerShell execution policy:**
   ```powershell
   Get-ExecutionPolicy
   ```
   If it's "Restricted", run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Run the diagnostic script:**
   ```powershell
   irm https://raw.githubusercontent.com/Jaredy899/osutil/main/test-powershell-connection.ps1 | iex
   ```

3. **Manual installation:**
   - Download the latest release from: https://github.com/Jaredy899/osutil/releases
   - Extract and run `osutil-windows.exe`

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Jaredy899/osutil.git
cd osutil

# Build for all platforms
cargo xtask build

# Or build for current platform only
cargo build --release
```

## Usage

Run the application:

```bash
# If installed via script
osutil

# If built from source
./target/release/osutil
```

For development:

```bash
cargo run
```

## Features

- Application setup and management
- System configuration tools
- Terminal-based user interface
- Cross-platform support (Linux, macOS, Windows)

## Supported Platforms

- **Linux**: x86_64-unknown-linux-gnu
- **macOS**: x86_64-apple-darwin and aarch64-apple-darwin (Apple Silicon)
- **Windows**: x86_64-pc-windows-msvc

## License

This project is licensed under the MIT License - see the LICENSE file for details.
