#!/bin/bash

# Multi-architecture build script
# This script builds the project for Linux (x86_64, aarch64, armv7), macOS, and Windows

set -e

echo "Building macutil for all platforms and architectures..."

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
    cargo build --release --target "$target"
    
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
echo "Current platform: $PLATFORM"

# Install required targets for Linux builds
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
    echo "Installing cross-rs..."
    cargo install cross
fi

# Build for Linux architectures
echo "Building for Linux architectures..."

# Build x86_64 Linux (native or cross-compiled)
echo "Building for Linux x86_64..."
if [[ "$PLATFORM" == "Linux" ]]; then
    cargo build --target-dir=build --release --target=x86_64-unknown-linux-musl --all-features
    cp ./build/x86_64-unknown-linux-musl/release/macutil "$BUILD_DIR/"
else
    build_target "x86_64-unknown-linux-musl" "macutil" || echo "Linux x86_64 build failed"
fi

# Build aarch64 Linux (using cross-rs if available)
echo "Building for Linux aarch64..."
if command -v cross &> /dev/null; then
    cross build --target-dir=build --release --target=aarch64-unknown-linux-musl --all-features
    cp ./build/aarch64-unknown-linux-musl/release/macutil "$BUILD_DIR/macutil-aarch64"
else
    build_target "aarch64-unknown-linux-musl" "macutil" || echo "Linux aarch64 build failed"
    if [ -f "$BUILD_DIR/macutil" ]; then
        mv "$BUILD_DIR/macutil" "$BUILD_DIR/macutil-aarch64"
    fi
fi

# Build armv7 Linux (using cross-rs if available)
echo "Building for Linux armv7..."
if command -v cross &> /dev/null; then
    cross build --target-dir=build --release --target=armv7-unknown-linux-musleabihf --all-features
    cp ./build/armv7-unknown-linux-musleabihf/release/macutil "$BUILD_DIR/macutil-armv7l"
else
    build_target "armv7-unknown-linux-musleabihf" "macutil" || echo "Linux armv7 build failed"
    if [ -f "$BUILD_DIR/macutil" ]; then
        mv "$BUILD_DIR/macutil" "$BUILD_DIR/macutil-armv7l"
    fi
fi

# Build for Windows (cross-compiled from any platform)
echo "Building for Windows..."
build_target "x86_64-pc-windows-gnu" "macutil.exe" || echo "Windows build failed"

# Build for macOS (only if on macOS)
if [[ "$PLATFORM" == "Darwin"* ]]; then
    echo "Building for macOS..."
    rustup target add x86_64-apple-darwin
    rustup target add aarch64-apple-darwin
    
    build_target "x86_64-apple-darwin" "macutil" || echo "macOS x86_64 build failed"
    build_target "aarch64-apple-darwin" "macutil" || echo "macOS ARM build failed"
    
    # Create universal binary if both builds succeeded
    if [ -f "target/x86_64-apple-darwin/release/macutil" ] && [ -f "target/aarch64-apple-darwin/release/macutil" ]; then
        echo "Creating universal macOS binary..."
        lipo -create \
            target/x86_64-apple-darwin/release/macutil \
            target/aarch64-apple-darwin/release/macutil \
            -output "$BUILD_DIR/macutil-macos"
        echo "✓ Created universal macOS binary"
    fi
else
    echo "Not on macOS, skipping macOS builds"
    echo "Note: macOS builds require native macOS environment"
fi

echo ""
echo "Build completed! Binaries are in the $BUILD_DIR directory:"
ls -la "$BUILD_DIR/"

echo ""
echo "Build Summary:"
echo "- Linux x86_64: Built using musl target"
echo "- Linux aarch64: Built using cross-rs and musl target"
echo "- Linux armv7: Built using cross-rs and musl target"
echo "- Windows: Built using cross-compilation"
echo "- macOS: Built natively (requires macOS environment)"

echo ""
echo "To create a release:"
echo "1. Update version in Cargo.toml"
echo "2. Commit and push changes"
echo "3. Create and push a tag: git tag v1.0.0 && git push origin v1.0.0"
echo "4. GitHub Actions will automatically build and release for all platforms" 