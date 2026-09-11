# Publishing Instructions

```bash
./build.sh
```

That's it. The script:

1. Asks which version to build (Enter keeps the current one)
2. Sets the version in `Cargo.toml`, runs `cargo update`, and builds
   Linux (x86_64, aarch64, armv7) and macOS (Intel, Apple Silicon) binaries into `dist/`
3. Asks whether to commit, tag, push, and publish a GitHub release with the binaries

Answer `n` at step 3 to just get local binaries.

Works from Linux or macOS. Requires `zig`, Rust, and `gh` (authenticated, only for releasing).
Rust cross targets, `cargo-zigbuild`, and the macOS SDK (cached in `~/.cache/osutil`) are
installed automatically. Set `SDKROOT` to use your own macOS SDK.

## Installation

```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install.sh)
```
