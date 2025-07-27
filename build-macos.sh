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

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Function to build for a specific target
build_target() {
    local target=$1
    local binary_name=$2
    
    echo "Building for $target..."
    
    # Build the target
    cargo build --release --target "$target" --all-features
    
    # Copy binary to build directory
    if [ -f "target/$target/release/$binary_name" ]; then
        cp "target/$target/release/$binary_name" "$BUILD_DIR/"
        echo "✓ Built $binary_name for $target"
    else
        echo "✗ Failed to build for $target"
        return 1
    fi
}

# Install required targets
echo "Installing required targets..."
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build for Intel Macs (x86_64)
echo "Building for macOS Intel (x86_64)..."
build_target "x86_64-apple-darwin" "osutil" || echo "macOS Intel build failed"

# Build for Apple Silicon (ARM64)
echo "Building for macOS ARM (aarch64)..."
build_target "aarch64-apple-darwin" "osutil" || echo "macOS ARM build failed"

# Create universal binary if both builds succeeded
if [ -f "target/x86_64-apple-darwin/release/osutil" ] && [ -f "target/aarch64-apple-darwin/release/osutil" ]; then
    echo "Creating universal macOS binary..."
    lipo -create \
        target/x86_64-apple-darwin/release/osutil \
        target/aarch64-apple-darwin/release/osutil \
        -output "$BUILD_DIR/osutil-macos"
    echo "✓ Created universal macOS binary"
else
    echo "⚠ Could not create universal binary - one or both architectures failed"
fi

echo ""
echo "Build completed! Binaries in $BUILD_DIR/:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- macOS Intel: target/x86_64-apple-darwin/release/osutil"
echo "- macOS ARM: target/aarch64-apple-darwin/release/osutil"
echo "- Universal: $BUILD_DIR/osutil-macos (if both builds succeeded)" 