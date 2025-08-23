#!/bin/bash

# Cross-platform build script for Debian/Ubuntu systems
# This script builds the project for Linux and FreeBSD architectures (x86_64, aarch64, armv7l)

set -e

echo "Building osutil for Linux and FreeBSD architectures (Debian/Ubuntu)..."

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
    sudo apt-get install -y build-essential curl pkg-config musl-tools musl-dev \
        gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf \
        libc6-dev-arm64-cross libc6-dev-armhf-cross \
        gcc-multilib g++-multilib clang llvm-dev \
        qemu-user-static binfmt-support

    # Install FreeBSD cross-compilation tools if available
    if apt-cache search freebsd | grep -q cross; then
        echo "Installing FreeBSD cross-compilation tools..."
        sudo apt-get install -y gcc-freebsd-amd64 gcc-freebsd-aarch64 || true
    fi

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

# Function to install Rust targets and cross-compilation tools
install_rust_targets() {
    echo "Installing required Rust targets..."

    # Install musl targets for cross-compilation
    rustup target add x86_64-unknown-linux-musl
    rustup target add aarch64-unknown-linux-musl
    rustup target add armv7-unknown-linux-musleabihf

    # Install FreeBSD targets for cross-compilation
    rustup target add x86_64-unknown-freebsd
    rustup target add aarch64-unknown-freebsd

    # Install cross-rs for better cross-compilation
    if ! command -v cross >/dev/null 2>&1; then
        echo "Installing cross-rs for cross-compilation..."
        cargo install cross
        echo "✓ cross-rs installed"
    else
        echo "✓ cross-rs already installed"
    fi

    echo "✓ Rust targets installed"
}

# Function to build for a specific target
build_target() {
    local target=$1
    local binary_name=$2

    echo "Building for $target..."

    case "$target" in
        x86_64-unknown-linux-musl)
            cargo build --release --target "$target" --all-features
            ;;
        aarch64-unknown-linux-musl|armv7-unknown-linux-musleabihf)
            cross build --release --target "$target" --all-features
            ;;
        x86_64-unknown-freebsd|aarch64-unknown-freebsd)
            # Try cross-compilation first, fallback to native build
            if cross build --release --target "$target" --all-features 2>/dev/null; then
                echo "✓ Cross-compiled using cross-rs"
            else
                echo "Cross-compilation failed, trying native build..."
                cargo build --release --target "$target" --all-features || {
                    echo "✗ Both cross-compilation and native build failed for $target"
                    return 1
                }
            fi
            ;;
        *)
            echo "Unknown target: $target"
            return 1
            ;;
    esac

    # Copy binary to build directory with appropriate name
    local target_dir="target/$target/release"
    if [ -f "$target_dir/osutil" ]; then
        cp "$target_dir/osutil" "$BUILD_DIR/$binary_name"
        echo "✓ Built $binary_name for $target"
    else
        echo "✗ Failed to build for $target"
        return 1
    fi
}

# Check and install prerequisites
echo "Checking prerequisites..."

# Install system dependencies
install_dependencies

# Install/update Rust
install_rust
update_rust

# Install Rust targets
install_rust_targets

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Build for all Linux architectures
echo "Building for all Linux architectures..."

# Build x86_64 (native musl)
build_target "x86_64-unknown-linux-musl" "osutil"

# Build aarch64 (cross-compiled)
build_target "aarch64-unknown-linux-musl" "osutil-aarch64"

# Build armv7l (cross-compiled)
build_target "armv7-unknown-linux-musleabihf" "osutil-armv7l"

# Build for FreeBSD architectures
echo "Building for FreeBSD architectures..."

# Build FreeBSD x86_64 (cross-compiled)
build_target "x86_64-unknown-freebsd" "osutil-freebsd-x86_64" || echo "⚠ FreeBSD x86_64 build failed - cross-compilation may not be available"

# Build FreeBSD aarch64 (cross-compiled)
build_target "aarch64-unknown-freebsd" "osutil-freebsd-aarch64" || echo "⚠ FreeBSD aarch64 build failed - cross-compilation may not be available"

echo ""
echo "Build completed! Binaries in $BUILD_DIR/:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- Linux x86_64: $BUILD_DIR/osutil"
echo "- Linux aarch64: $BUILD_DIR/osutil-aarch64"
echo "- Linux armv7l: $BUILD_DIR/osutil-armv7l"
echo "- FreeBSD x86_64: $BUILD_DIR/osutil-freebsd-x86_64"
echo "- FreeBSD aarch64: $BUILD_DIR/osutil-freebsd-aarch64"
echo ""
echo "To install system-wide on Linux, run:"
echo "sudo cp $BUILD_DIR/osutil /usr/local/bin/"
echo ""
echo "To test FreeBSD binaries with QEMU:"
echo "qemu-x86_64-static $BUILD_DIR/osutil-freebsd-x86_64 --help"
echo "qemu-aarch64-static $BUILD_DIR/osutil-freebsd-aarch64 --help" 