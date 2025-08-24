#!/usr/bin/env bash
set -euo pipefail

APP_NAME="osutil"
OUT_DIR="dist"
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
if cross build --release --target x86_64-pc-windows-gnu; then
  cp target/x86_64-pc-windows-gnu/release/${APP_NAME}.exe "$OUT_DIR/${APP_NAME}-windows-x86_64-gnu.exe"
else
  echo "⚠️  Windows GNU build failed. Use Windows CI (MSVC) for official builds."
fi

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
if cross build --release --target x86_64-unknown-freebsd; then
  cp target/x86_64-unknown-freebsd/release/$APP_NAME "$OUT_DIR/${APP_NAME}-freebsd-x86_64"
else
  echo "⚠️  FreeBSD build failed. Consider building natively on FreeBSD or using Cirrus CI."
fi

########################################
# Done
########################################
echo "==> All builds complete. Binaries are in $OUT_DIR/"
ls -lh "$OUT_DIR"
