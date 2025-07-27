#!/bin/bash

# Multi-architecture build script
# This script builds the project for Linux (musl), macOS, and Windows

set -e

echo "Building osutil for all platforms..."

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

# Detect current platform
PLATFORM=$(uname -s)

# Install required targets
echo "Installing required targets..."
rustup target add x86_64-unknown-linux-musl
rustup target add aarch64-unknown-linux-musl
rustup target add armv7-unknown-linux-musleabihf
rustup target add x86_64-pc-windows-gnu

# Install cross-compilation tools if on Linux
if [[ "$PLATFORM" == "Linux" ]]; then
    echo "Installing cross-compilation tools..."
    sudo apt-get update
    sudo apt-get install -y build-essential musl-tools musl-dev gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf libc6-dev-arm64-cross libc6-dev-armhf-cross gcc-mingw-w64
    
    # Install cross-rs for better cross-compilation
    cargo install cross
fi

# Build for Linux architectures (musl only)
echo "Building for Linux architectures (musl)..."

# Build x86_64 Linux (musl)
echo "Building for Linux x86_64 (musl)..."
if [[ "$PLATFORM" == "Linux" ]]; then
    cargo build --release --target=x86_64-unknown-linux-musl --all-features
    cp target/x86_64-unknown-linux-musl/release/osutil "$BUILD_DIR/"
    echo "✓ Built Linux x86_64 (musl)"
else
    if command -v cross &> /dev/null; then
        cross build --release --target=x86_64-unknown-linux-musl --all-features
        cp target/x86_64-unknown-linux-musl/release/osutil "$BUILD_DIR/"
        echo "✓ Built Linux x86_64 (musl) using cross"
    else
        echo "✗ Cross-compilation failed for Linux x86_64"
    fi
fi

# Build aarch64 Linux (musl)
echo "Building for Linux aarch64 (musl)..."
if [[ "$PLATFORM" == "Linux" ]]; then
    if cargo build --release --target=aarch64-unknown-linux-musl --all-features 2>/dev/null; then
        cp target/aarch64-unknown-linux-musl/release/osutil "$BUILD_DIR/osutil-aarch64"
        echo "✓ Built Linux aarch64 (musl)"
    elif command -v cross &> /dev/null; then
        cross build --release --target=aarch64-unknown-linux-musl --all-features
        cp target/aarch64-unknown-linux-musl/release/osutil "$BUILD_DIR/osutil-aarch64"
        echo "✓ Built Linux aarch64 (musl) using cross"
    else
        echo "✗ Failed to build Linux aarch64"
    fi
else
    if command -v cross &> /dev/null; then
        if cross build --release --target=aarch64-unknown-linux-musl --all-features; then
            cp target/aarch64-unknown-linux-musl/release/osutil "$BUILD_DIR/osutil-aarch64"
            echo "✓ Built Linux aarch64 (musl) using cross"
        else
            echo "✗ Cross-compilation failed for Linux aarch64"
        fi
    else
        echo "✗ Cross-compilation tools not available"
    fi
fi

# Build armv7 Linux (musl)
echo "Building for Linux armv7 (musl)..."
if [[ "$PLATFORM" == "Linux" ]]; then
    if cargo build --release --target=armv7-unknown-linux-musleabihf --all-features 2>/dev/null; then
        cp target/armv7-unknown-linux-musleabihf/release/osutil "$BUILD_DIR/osutil-armv7l"
        echo "✓ Built Linux armv7 (musl)"
    elif command -v cross &> /dev/null; then
        cross build --release --target=armv7-unknown-linux-musleabihf --all-features
        cp target/armv7-unknown-linux-musleabihf/release/osutil "$BUILD_DIR/osutil-armv7l"
        echo "✓ Built Linux armv7 (musl) using cross"
    else
        echo "✗ Failed to build Linux armv7"
    fi
else
    if command -v cross &> /dev/null; then
        if cross build --release --target=armv7-unknown-linux-musleabihf --all-features; then
            cp target/armv7-unknown-linux-musleabihf/release/osutil "$BUILD_DIR/osutil-armv7l"
            echo "✓ Built Linux armv7 (musl) using cross"
        else
            echo "✗ Cross-compilation failed for Linux armv7"
        fi
    else
        echo "✗ Cross-compilation tools not available"
    fi
fi

# Build for Windows
echo "Building for Windows..."
if [[ "$PLATFORM" == "Linux" ]]; then
    if cargo build --release --target=x86_64-pc-windows-gnu --all-features 2>/dev/null; then
        cp target/x86_64-pc-windows-gnu/release/osutil.exe "$BUILD_DIR/"
        echo "✓ Built Windows binary"
    elif command -v cross &> /dev/null; then
        cross build --release --target=x86_64-pc-windows-gnu --all-features
        cp target/x86_64-pc-windows-gnu/release/osutil.exe "$BUILD_DIR/"
        echo "✓ Built Windows binary using cross"
    else
        echo "✗ Failed to build Windows binary"
    fi
else
    if command -v cross &> /dev/null; then
        if cross build --release --target=x86_64-pc-windows-gnu --all-features; then
            cp target/x86_64-pc-windows-gnu/release/osutil.exe "$BUILD_DIR/"
            echo "✓ Built Windows binary using cross"
        else
            echo "✗ Cross-compilation failed for Windows"
        fi
    else
        build_target "x86_64-pc-windows-gnu" "osutil.exe" || echo "Windows build failed"
    fi
fi

# Build for macOS (only if on macOS)
if [[ "$PLATFORM" == "Darwin"* ]]; then
    echo "Building for macOS..."
    rustup target add x86_64-apple-darwin
    rustup target add aarch64-apple-darwin
    
    build_target "x86_64-apple-darwin" "osutil" || echo "macOS x86_64 build failed"
    build_target "aarch64-apple-darwin" "osutil" || echo "macOS ARM build failed"
    
    # Create universal binary if both builds succeeded
    if [ -f "target/x86_64-apple-darwin/release/osutil" ] && [ -f "target/aarch64-apple-darwin/release/osutil" ]; then
        echo "Creating universal macOS binary..."
        lipo -create \
            target/x86_64-apple-darwin/release/osutil \
            target/aarch64-apple-darwin/release/osutil \
            -output "$BUILD_DIR/osutil-macos"
        echo "✓ Created universal macOS binary"
    fi
else
    echo "Not on macOS, skipping macOS builds"
fi

echo ""
echo "Build completed! Binaries in $BUILD_DIR/:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- Linux x86_64: musl binary"
echo "- Linux aarch64: musl binary"
echo "- Linux armv7: musl binary"
echo "- Windows: x86_64 binary"
echo "- macOS: universal binary (Intel & ARM)" 