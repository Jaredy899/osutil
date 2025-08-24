# Multi-Platform Build and Installation System

This document describes the comprehensive multi-platform build and installation system for osutil.

## Overview

The project now supports building and distributing for multiple platforms and architectures:

- **Linux**: x86_64, aarch64 (ARM64), armv7l (ARMv7) - Built using musl targets and cross-compilation
- **macOS**: x86_64-apple-darwin and aarch64-apple-darwin - Built natively on macOS
- **Windows**: x86_64-pc-windows-msvc (native, self-contained)

## Installation Commands

### macOS & Linux (Auto-detects platform and architecture)

```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install.sh)
```

### Windows

```powershell
irm https://raw.githubusercontent.com/Jaredy899/osutil/main/install-windows.ps1 | iex
```

## Build System

### GitHub Actions Workflow

The `.github/workflows/Release.yml` workflow uses a comprehensive approach:

1. **Linux Build Job**: Builds x86_64, aarch64, and armv7l using musl targets and cross-rs
2. **Windows Build Job**: MSVC build on Windows (self-contained, no external dependencies)
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

# Install cross-compilation tools (on Linux)
sudo apt-get update
sudo apt-get install -y build-essential musl-tools musl-dev gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf libc6-dev-arm64-cross libc6-dev-armhf-cross

# Install cross-rs for better cross-compilation
cargo install cross

# Build for specific platforms
cargo build --release --target x86_64-unknown-linux-musl
cross build --release --target aarch64-unknown-linux-musl
cross build --release --target armv7-unknown-linux-musleabihf

# Build for Windows (MSVC)
echo '[target.x86_64-pc-windows-msvc]' >> .cargo/config.toml
echo 'rustflags = ["-C", "target-feature=+crt-static"]' >> .cargo/config.toml
cargo build --release --target x86_64-pc-windows-msvc --no-default-features

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

### Windows Build

The project uses the MSVC toolchain for Windows builds:

- **MSVC Build** (`x86_64-pc-windows-msvc`):
  - Built natively on Windows
  - Self-contained executable with no external dependencies
  - No Visual C++ Redistributable required
  - Works on all Windows systems without additional installations
  - Built with `--no-default-features` to exclude Unix-specific dependencies
  - Uses static linking (`+crt-static`) to include all runtime dependencies
  - Optimized with LTO and stripping for smaller file size

## Installer Scripts

### install.sh (macOS & Linux)

- Auto-detects operating system (macOS or Linux)
- Auto-detects system architecture (x86_64, aarch64, armv7l)
- Downloads the appropriate binary from GitHub Releases
- Removes quarantine attributes on macOS to avoid Gatekeeper warnings
- Includes error handling and cleanup
- Unified script for both platforms

### install-windows.ps1

- Downloads the Windows binary from GitHub Releases (no external dependencies)
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

```text
├── .github/workflows/Release.yml    # Multi-architecture CI/CD
├── install.sh                       # Unified installer (macOS & Linux)
├── install-windows.ps1              # Windows installer
├── build-all.sh                     # Local build script
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
# macOS & Linux
./install.sh

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
