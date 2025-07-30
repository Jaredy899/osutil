# Publishing Instructions

## Automated Release

1. Update version in `Cargo.toml` (workspace package section)
2. Commit and push changes
3. Create and push a tag: `git tag v1.0.0 && git push origin v1.0.0`
4. The GitHub Actions workflow will automatically:
   - Build for Linux, macOS (x86_64 & ARM), and Windows
   - Create a release with all platform binaries

## Version Management

The workspace uses a single version defined in the root `Cargo.toml`:

```toml
[workspace.package]
version = "1.0.0"
```

All crates in the workspace inherit this version via `version.workspace = true`.

## Installation

Users can install osutil using platform-specific commands:

### macOS & Linux

```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install.sh)
```

### Windows

```powershell
irm https://raw.githubusercontent.com/Jaredy899/osutil/main/install-windows.ps1 | iex
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

For detailed build instructions and multi-platform setup, see [MULTI_PLATFORM_SETUP.md](MULTI_PLATFORM_SETUP.md).
