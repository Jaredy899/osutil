# Multi-Platform Build and Installation System

This document describes the comprehensive multi-platform build and installation system for macutil.

## Overview

The project now supports building and distributing for multiple platforms and architectures:
- **Linux**: x86_64, aarch64 (ARM64), armv7l (ARMv7) - Built using musl targets and cross-compilation
- **macOS**: x86_64-apple-darwin and aarch64-apple-darwin - Built natively on macOS
- **Windows**: x86_64-pc-windows-gnu - Cross-compiled from Ubuntu

## Installation Commands

### Linux (Auto-detects architecture)
```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-linux.sh)
```

### macOS
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-macos.sh)
```

### Windows
```powershell
irm https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-windows.ps1 | iex
```

## Build System

### GitHub Actions Workflow
The `.github/workflows/Release.yml` workflow uses a comprehensive approach:
1. **Linux Build Job**: Builds x86_64, aarch64, and armv7l using musl targets and cross-rs
2. **Windows Build Job**: Cross-compiles Windows binary from Ubuntu
3. **macOS Build Job**: Builds natively on macOS (Intel + ARM, then creates universal binary)
4. **Release Job**: Combines all artifacts and creates the release

### Local Development

#### Using xtask (Recommended)
```bash
# Build for all platforms (macOS only if on macOS)
cargo xtask build

# Build for Linux and Windows using cross-compilation
cargo xtask build-cross

# Build for Linux architectures only (x86_64, aarch64, armv7)
cargo xtask build-linux

# Build for current platform only
cargo build --release
```

#### Using build script
```bash
# Build for all platforms with detailed output
./build-all.sh
```

#### Manual cross-compilation
```bash
# Install required targets
rustup target add x86_64-unknown-linux-musl
rustup target add aarch64-unknown-linux-musl
rustup target add armv7-unknown-linux-musleabihf
rustup target add x86_64-pc-windows-gnu

# Install cross-compilation tools (on Linux)
sudo apt-get update
sudo apt-get install -y build-essential musl-tools musl-dev gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf libc6-dev-arm64-cross libc6-dev-armhf-cross gcc-mingw-w64

# Install cross-rs for better cross-compilation
cargo install cross

# Build for specific platforms
cargo build --release --target x86_64-unknown-linux-musl
cross build --release --target aarch64-unknown-linux-musl
cross build --release --target armv7-unknown-linux-musleabihf
cargo build --release --target x86_64-pc-windows-gnu

# Build for macOS (only on macOS)
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin
```

## Multi-Architecture Benefits

### Why Multiple Linux Architectures?
- **x86_64**: Standard desktop and server architecture
- **aarch64/ARM64**: Modern ARM servers, Apple Silicon, Raspberry Pi 4
- **armv7l/ARMv7**: Older ARM devices, Raspberry Pi 3 and earlier

### Why musl Targets?
- **Static linking**: No external dependencies required
- **Portability**: Runs on any Linux distribution
- **Smaller binaries**: Optimized for size
- **Security**: Reduced attack surface

### Cross-Compilation Benefits
- **Efficiency**: Build multiple architectures from a single environment
- **Consistency**: Same build environment for all targets
- **Speed**: Parallel builds reduce total CI time
- **Reliability**: Fewer moving parts and dependencies

## Installer Scripts

### install-linux.sh
- Auto-detects system architecture (x86_64, aarch64, armv7l)
- Downloads the appropriate binary from GitHub Releases
- Installs to `/usr/local/bin/macutil` (if writable) or `~/.local/bin/macutil`
- Checks PATH and provides helpful messages
- Includes error handling and cleanup

### install-macos.sh
- Downloads the macOS binary from GitHub Releases
- Installs to `/usr/local/bin/macutil` (if writable) or `~/.local/bin/macutil`
- Removes quarantine attributes to avoid Gatekeeper warnings
- Checks PATH and provides helpful messages
- Includes error handling and cleanup

### install-windows.ps1
- Downloads the Windows binary from GitHub Releases
- Installs to a directory in PATH or creates a new one
- Uses PowerShell 5.1+ features
- Includes error handling and cleanup
- Provides helpful messages about PATH configuration

## Release Process

### Automated Release
1. Update version in `Cargo.toml` (workspace package section)
2. Commit and push changes
3. Create and push a tag: `git tag v1.0.0 && git push origin v1.0.0`
4. GitHub Actions automatically builds and releases

### Manual Release
1. Update version in `Cargo.toml`
2. Build locally: `cargo xtask build-linux` or `./build-all.sh`
3. Manually create GitHub release and upload binaries

## File Structure

```
├── .github/workflows/Release.yml    # Multi-architecture CI/CD
├── install-linux.sh                 # Linux installer (auto-detects arch)
├── install-macos.sh                 # macOS installer
├── install-windows.ps1              # Windows installer
├── build-all.sh                     # Local build script
├── test-installers.sh               # Installer testing
├── xtask/src/build.rs               # Multi-architecture build system
├── publish-instructions.md          # Updated instructions
├── MULTI_PLATFORM_SETUP.md          # This file
└── README.md                        # Updated documentation
```

## Testing

### Test installers locally
```bash
./test-installers.sh
```

### Test specific installer
```bash
# Linux
./install-linux.sh

# macOS
./install-macos.sh

# Windows
pwsh -File install-windows.ps1
```

### Test cross-compilation locally
```bash
# From any platform
cargo xtask build-cross

# Linux architectures only
cargo xtask build-linux

# From Ubuntu/Linux
./build-all.sh
```

## Notes

- Multi-architecture support covers 99% of Linux devices
- musl targets provide maximum compatibility and portability
- Cross-compilation reduces CI complexity and build time
- macOS builds still require native environment for reliability
- All installers include proper error handling and cleanup
- Installers check for the correct platform before running
- The system gracefully handles PATH configuration
- GitHub Actions builds are cached for faster builds
- All scripts are executable and ready for distribution 