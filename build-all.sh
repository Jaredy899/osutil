#!/usr/bin/env bash
set -euo pipefail

APP_NAME="osutil"
OUT_DIR="dist"

# Install required tools
echo "==> Installing required tools..."
cargo install cargo-zigbuild cross 2>/dev/null || true

# Install mingw-w64 for Windows builds (or ensure zig is available)
if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 && ! (command -v zig >/dev/null 2>&1 && zig targets | grep -q x86_64-windows); then
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y gcc-mingw-w64-x86-64
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm mingw-w64-gcc
    elif command -v brew >/dev/null 2>&1; then
        brew install mingw-w64
    fi
fi

mkdir -p "$OUT_DIR"

echo "==> Ensuring Rust targets are installed"
rustup target add \
  x86_64-unknown-linux-musl \
  aarch64-unknown-linux-musl \
  armv7-unknown-linux-musleabihf \
  x86_64-pc-windows-gnu \
  x86_64-apple-darwin \
  aarch64-apple-darwin \
  x86_64-unknown-freebsd

########################################
# Linux (musl)
########################################
echo "==> Building Linux (musl)"
cargo zigbuild --release --target x86_64-unknown-linux-musl
cp target/x86_64-unknown-linux-musl/release/$APP_NAME "$OUT_DIR/${APP_NAME}-linux-x86_64"

cargo zigbuild --release --target aarch64-unknown-linux-musl
cp target/aarch64-unknown-linux-musl/release/$APP_NAME "$OUT_DIR/${APP_NAME}-linux-aarch64"

cargo zigbuild --release --target armv7-unknown-linux-musleabihf
cp target/armv7-unknown-linux-musleabihf/release/$APP_NAME "$OUT_DIR/${APP_NAME}-linux-armv7"

########################################
# Windows (GNU)
########################################
echo "==> Building Windows (GNU)"
cargo build --release --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/${APP_NAME}.exe "$OUT_DIR/${APP_NAME}-windows-x86_64-gnu.exe"

########################################
# macOS (Darwin)
########################################
echo "==> Building macOS (Darwin)"
cargo zigbuild --release --target x86_64-apple-darwin
cp target/x86_64-apple-darwin/release/$APP_NAME "$OUT_DIR/${APP_NAME}-macos-x86_64"

cargo zigbuild --release --target aarch64-apple-darwin
cp target/aarch64-apple-darwin/release/$APP_NAME "$OUT_DIR/${APP_NAME}-macos-arm64"

########################################
# FreeBSD
########################################
echo "==> Building FreeBSD (x86_64)"
cross build --release --target x86_64-unknown-freebsd
cp target/x86_64-unknown-freebsd/release/$APP_NAME "$OUT_DIR/${APP_NAME}-freebsd-x86_64"

########################################
# Done
########################################
echo "==> All builds complete. Binaries are in $OUT_DIR/"
ls -lh "$OUT_DIR"
