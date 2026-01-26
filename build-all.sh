#!/usr/bin/env bash
set -euo pipefail

APP_NAME="osutil"
OUT_DIR="dist"

# Detect OS
OS="$(uname -s)"
echo "==> Detected OS: $OS"

# Install required tools
echo "==> Installing required tools..."
cargo install cargo-zigbuild 2>/dev/null || true

mkdir -p "$OUT_DIR"

# Install Rust targets based on OS
echo "==> Ensuring Rust targets are installed"
rustup target add \
  x86_64-unknown-linux-musl \
  aarch64-unknown-linux-musl \
  armv7-unknown-linux-musleabihf

if [[ "$OS" == "Darwin" ]]; then
    rustup target add x86_64-apple-darwin aarch64-apple-darwin
fi

########################################
# Linux (musl) - builds on both Linux and macOS
########################################
echo "==> Building Linux (musl)"
cargo zigbuild --release --target x86_64-unknown-linux-musl --all-features
cp target/x86_64-unknown-linux-musl/release/$APP_NAME "$OUT_DIR/${APP_NAME}-linux-x86_64"

cargo zigbuild --release --target aarch64-unknown-linux-musl --all-features
cp target/aarch64-unknown-linux-musl/release/$APP_NAME "$OUT_DIR/${APP_NAME}-linux-aarch64"

cargo zigbuild --release --target armv7-unknown-linux-musleabihf --all-features
cp target/armv7-unknown-linux-musleabihf/release/$APP_NAME "$OUT_DIR/${APP_NAME}-linux-armv7"

########################################
# Platform-specific builds
########################################
if [[ "$OS" == "Darwin" ]]; then
    ########################################
    # macOS (Darwin) - only builds on macOS
    ########################################
    echo "==> Building macOS (Darwin) with full features"
    cargo build --release --target x86_64-apple-darwin --all-features
    cp target/x86_64-apple-darwin/release/$APP_NAME "$OUT_DIR/${APP_NAME}-macos-x86_64"

    cargo build --release --target aarch64-apple-darwin --all-features
    cp target/aarch64-apple-darwin/release/$APP_NAME "$OUT_DIR/${APP_NAME}-macos-arm64"
else
    echo "==> Skipping macOS (requires macOS to build with full features)"
fi

########################################
# Done
########################################
echo ""
echo "==> Build complete! Binaries in $OUT_DIR/:"
ls -lh "$OUT_DIR"

echo ""
echo "Build summary:"
echo "  - Linux x86_64, aarch64, armv7: ✓"
if [[ "$OS" == "Darwin" ]]; then
    echo "  - macOS x86_64, arm64: ✓"
else
    echo "  - macOS: skipped (run on macOS)"
fi
