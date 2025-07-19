# Publishing Instructions

## Automated Release (Recommended)

1. Update version in `Cargo.toml` (workspace package section)
2. Commit and push changes
3. Create and push a tag: `git tag v1.0.0 && git push origin v1.0.0`
4. The GitHub Actions workflow will automatically:
   - Build for Linux (x86_64 and aarch64) and macOS
   - Create a release with all binaries
   - Upload to GitHub Releases

## Manual Release (Legacy)

1. Set Cargo.toml and core/cargo.toml version
2. Publish macutil_core
3. Set Tui/cargo.toml core version to new version
4. Publish macutil_tui
5. Run GitHub release action manually
6. Update AUR macutil

## Version Management

The workspace uses a single version defined in the root `Cargo.toml`:
```toml
[workspace.package]
version = "1.0.0"
```

All crates in the workspace inherit this version via `version.workspace = true`.
