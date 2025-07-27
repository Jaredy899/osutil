# Publishing Instructions

## Automated Release

1. Update version in `Cargo.toml` (workspace package section)
2. Commit and push changes
3. Create and push a tag: `git tag v1.0.0 && git push origin v1.0.0`
4. The GitHub Actions workflow will automatically:
   - Build for Linux, macOS (x86_64 & ARM), and Windows
   - Create a release with all platform binaries
   - Upload platform-specific installers to GitHub Releases

## Manual Release (Alternative)

If you need to create a release without pushing a tag, you can:

1. Update version in `Cargo.toml` (workspace package section)
2. Build locally: `cargo xtask build`
3. Manually create a GitHub release and upload the binaries from `target/release/`

## Version Management

The workspace uses a single version defined in the root `Cargo.toml`:

```toml
[workspace.package]
version = "1.0.0"
```

All crates in the workspace inherit this version via `version.workspace = true`.

## Available Workflows

- **Release**: Automated release on tag push (Linux, macOS, Windows)
- **rust**: Rust linting and formatting checks

## Installation

Users can install osutil using platform-specific commands:

### Linux
```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-linux.sh)
```

### macOS
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-macos.sh)
```

### Windows
```powershell
irm https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/install-windows.ps1 | iex
```

## Local Development

To build for all platforms locally:
```bash
cargo xtask build
```

To build for the current platform only:
```bash
cargo build --release
```

## Cross-Platform Building

The project supports building for:
- Linux (x86_64-unknown-linux-gnu)
- macOS Intel (x86_64-apple-darwin)
- macOS ARM (aarch64-apple-darwin)
- Windows (x86_64-pc-windows-msvc)

Make sure you have the necessary target toolchains installed:
```bash
rustup target add x86_64-unknown-linux-gnu
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin
rustup target add x86_64-pc-windows-msvc
```
