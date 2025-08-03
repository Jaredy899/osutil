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
update_rust

# Create build directory
BUILD_DIR="build"
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

# Create universal binary
echo "Creating universal macOS binary..."
lipo -create \
    target/x86_64-apple-darwin/release/osutil \
    target/aarch64-apple-darwin/release/osutil \
    -output "$BUILD_DIR/osutil-macos"
echo "✓ Created universal macOS binary"

echo ""
echo "Build completed! Binary in $BUILD_DIR/:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- macOS Universal: $BUILD_DIR/osutil-macos"
echo ""
echo "To install system-wide, run:"
echo "sudo cp $BUILD_DIR/osutil-macos /usr/local/bin/osutil" 