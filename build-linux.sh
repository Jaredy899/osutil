#!/bin/bash

# Linux build script for Debian/Ubuntu systems
# This script builds the project for the current Linux platform

set -e

echo "Building osutil for Linux (Debian/Ubuntu)..."

# Check if we're on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Error: This script must be run on Linux"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo "Error: Cargo.toml not found. Please run this script from the project root."
    exit 1
fi

# Check if we're on a Debian/Ubuntu system
if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: This script is designed for Debian/Ubuntu systems (apt-get required)"
    exit 1
fi

# Function to install system dependencies
install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential curl pkg-config
    echo "✓ Build dependencies installed"
}

# Function to install Rust
install_rust() {
    if ! command -v rustc >/dev/null 2>&1; then
        echo "Rust not found. Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1090
        source ~/.cargo/env
        echo "✓ Rust installed successfully!"
    else
        echo "✓ Rust is already installed: $(rustc --version)"
    fi
}

# Function to update Rust
update_rust() {
    echo "Updating Rust toolchain..."
    rustup update
    echo "✓ Rust updated"
}

# Check and install prerequisites
echo "Checking prerequisites..."

# Install system dependencies
install_dependencies

# Install/update Rust
install_rust
update_rust

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Build for current platform
echo "Building for Linux $ARCH..."
cargo build --release --all-features

# Copy binary to build directory
if [ -f "target/release/osutil" ]; then
    cp "target/release/osutil" "$BUILD_DIR/"
    echo "✓ Built osutil for Linux $ARCH"
else
    echo "✗ Failed to build for Linux $ARCH"
    exit 1
fi

echo ""
echo "Build completed! Binary in $BUILD_DIR/:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- Linux $ARCH: $BUILD_DIR/osutil"
echo ""
echo "To install system-wide, run:"
echo "sudo cp $BUILD_DIR/osutil /usr/local/bin/" 