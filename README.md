# MacUtil

A simple utility tool for system management and application setup, now supporting Linux, macOS, and Windows.

## Installation

### Quick Install (Recommended)

#### Linux
```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-linux.sh)
```

#### macOS
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-macos.sh)
```

#### Windows
```powershell
irm https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-windows.ps1 | iex
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Jaredy899/jaredmacutil.git
cd jaredmacutil

# Build for all platforms
cargo xtask build

# Or build for current platform only
cargo build --release
```

## Usage

Run the application:

```bash
# If installed via script
macutil

# If built from source
./target/release/macutil
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
