#!/bin/bash

# macOS build script
# This script builds the project for macOS (Intel and ARM)

set -e

echo "Building osutil for macOS..."

# Check if we're on macOS
if [[ "$(uname -s)" != "Darwin"* ]]; then
    echo "Error: This script must be run on macOS"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo "Error: Cargo.toml not found. Please run this script from the project root."
    exit 1
fi

# Function to install Xcode Command Line Tools
install_xcode_tools() {
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        echo "Please complete the Xcode Command Line Tools installation in the popup window."
        echo "After installation completes, run this script again."
        exit 1
    else
        echo "Xcode Command Line Tools are already installed"
    fi
}

# Function to install Rust
install_rust() {
    if ! command -v rustc >/dev/null 2>&1; then
        echo "Rust not found. Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1090
        source ~/.cargo/env
        echo "Rust installed successfully!"
    else
        echo "Rust is already installed: $(rustc --version)"
    fi
}

# Function to ensure we're using rustup-managed Rust
ensure_rustup_rust() {
    # Check if we're using rustup-managed Rust
    if [[ "$(which rustc)" != *".cargo/bin"* ]]; then
        echo "Warning: Using Homebrew Rust instead of rustup-managed Rust"
        echo "This may cause cross-compilation issues. Switching to rustup-managed Rust..."
        export PATH="$HOME/.cargo/bin:$PATH"
        echo "Now using: $(which rustc)"
    fi
}

# Function to update Rust
update_rust() {
    echo "Updating Rust toolchain..."
    rustup update
}

# Check and install prerequisites
echo "Checking prerequisites..."

# Install Xcode Command Line Tools
install_xcode_tools

# Install/update Rust
install_rust
ensure_rustup_rust
update_rust

# Create dist directory
BUILD_DIR="dist"
mkdir -p "$BUILD_DIR"

# Install required targets
echo "Installing required targets..."
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build for Intel Macs (x86_64)
echo "Building for macOS Intel (x86_64)..."
cargo build --release --target x86_64-apple-darwin --all-features

# Build for Apple Silicon (ARM64)
echo "Building for macOS ARM (aarch64)..."
cargo build --release --target aarch64-apple-darwin --all-features

# Copy architecture-specific binaries (no universal binary)
echo "Preparing separate macOS binaries..."
cp target/x86_64-apple-darwin/release/osutil "$BUILD_DIR/osutil-macos-x86_64"
cp target/aarch64-apple-darwin/release/osutil "$BUILD_DIR/osutil-macos-arm64"
echo "✓ Created $BUILD_DIR/osutil-macos-x86_64"
echo "✓ Created $BUILD_DIR/osutil-macos-arm64"

echo ""
echo "Build completed! Binary in $BUILD_DIR/:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- macOS x86_64: $BUILD_DIR/osutil-macos-x86_64"
echo "- macOS arm64:  $BUILD_DIR/osutil-macos-arm64"
echo ""
echo "To install system-wide, choose the correct binary for your Mac:"
echo "  Intel (x86_64): sudo cp $BUILD_DIR/osutil-macos-x86_64 /usr/local/bin/osutil"
echo "  Apple Silicon:  sudo cp $BUILD_DIR/osutil-macos-arm64 /usr/local/bin/osutil"