#!/bin/bash

# FreeBSD build script
# This script builds the project for FreeBSD (x86_64 and aarch64)

set -e

echo "Building osutil for FreeBSD..."

# Check if we're on FreeBSD
if [[ "$(uname -s)" != "FreeBSD"* ]]; then
    echo "Error: This script must be run on FreeBSD"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo "Error: Cargo.toml not found. Please run this script from the project root."
    exit 1
fi

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

    # Install FreeBSD targets for native and cross-compilation
    rustup target add x86_64-unknown-freebsd
    rustup target add aarch64-unknown-freebsd

    echo "✓ Rust targets installed"
}

# Function to build for a specific target
build_target() {
    local target=$1
    local binary_name=$2

    echo "Building for $target..."

    case "$target" in
        x86_64-unknown-freebsd)
            cargo build --release --target "$target" --all-features
            ;;
        aarch64-unknown-freebsd)
            # For cross-compilation, we might need additional tools
            # Check if we can build natively first
            if [[ "$(uname -m)" == "aarch64" ]]; then
                cargo build --release --target "$target" --all-features
            else
                echo "Cross-compilation to aarch64 from $(uname -m) may require additional setup"
                # Try with cross if available, otherwise skip
                if command -v cross >/dev/null 2>&1; then
                    cross build --release --target "$target" --all-features
                else
                    echo "Skipping aarch64 build - cross-compilation tools not available"
                    return 0
                fi
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

# Install/update Rust
install_rust
update_rust

# Install Rust targets
install_rust_targets

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Build for all architectures
echo "Building for all FreeBSD architectures..."

# Build x86_64 (native on most systems)
build_target "x86_64-unknown-freebsd" "osutil-freebsd-x86_64"

# Build aarch64 (if possible)
build_target "aarch64-unknown-freebsd" "osutil-freebsd-aarch64"

echo ""
echo "Build completed! Binaries in $BUILD_DIR/:"
ls -la "$BUILD_DIR/" | grep freebsd

echo ""
echo "Build Summary:"
echo "- FreeBSD x86_64: $BUILD_DIR/osutil-freebsd-x86_64"
echo "- FreeBSD aarch64: $BUILD_DIR/osutil-freebsd-aarch64"
echo ""
echo "To install system-wide, run:"
echo "sudo cp $BUILD_DIR/osutil-freebsd-x86_64 /usr/local/bin/osutil"
