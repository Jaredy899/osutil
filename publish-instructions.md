# Publishing Instructions

## Automated Release

1. Update version in `Cargo.toml` (workspace package section)
2. Commit and push changes
3. Create and push a tag: `git tag v1.0.0 && git push origin v1.0.0`
4. The GitHub Actions workflow will automatically:
   - Build for macOS
   - Create a release with the macOS binary
   - Upload to GitHub Releases

## Manual Release (Alternative)

If you need to create a release without pushing a tag, you can:

1. Update version in `Cargo.toml` (workspace package section)
2. Build locally: `cargo build --release`
3. Manually create a GitHub release and upload the binary from `target/release/macutil`

## Version Management

The workspace uses a single version defined in the root `Cargo.toml`:

```toml
[workspace.package]
version = "1.0.0"
```

All crates in the workspace inherit this version via `version.workspace = true`.

## Available Workflows

- **Release**: Automated release on tag push (macOS only)
- **rust**: Rust linting and formatting checks

## Installation

Users can install macutil using:

```bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/start.sh)
```

Or download the binary directly from GitHub Releases.
