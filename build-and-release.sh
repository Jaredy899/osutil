#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting local build and release process...${NC}"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Get version from git tag
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ No git tag found. Please create a tag first:${NC}"
    echo "  git tag v1.0.0"
    echo "  git push origin v1.0.0"
    exit 1
fi

echo -e "${YELLOW}📦 Building for version: $VERSION${NC}"

# Clean and create dist directory
rm -rf dist
mkdir -p dist

# Install required tools if not present
echo -e "${YELLOW}🔧 Installing build tools...${NC}"
cargo install cargo-zigbuild --locked 2>/dev/null || true
cargo install cross --locked 2>/dev/null || true

# Build all targets
echo -e "${YELLOW}🔨 Building all targets...${NC}"

echo "==> Linux (musl)"
cargo zigbuild --release --target x86_64-unknown-linux-musl --all-features
cp target/x86_64-unknown-linux-musl/release/osutil dist/osutil-linux-x86_64

cargo zigbuild --release --target aarch64-unknown-linux-musl --all-features
cp target/aarch64-unknown-linux-musl/release/osutil dist/osutil-linux-aarch64

cargo zigbuild --release --target armv7-unknown-linux-musleabihf --all-features
cp target/armv7-unknown-linux-musleabihf/release/osutil dist/osutil-linux-armv7

echo "==> Windows (GNU)"
cargo build --release --target x86_64-pc-windows-gnu --features syntax-highlighting
cp target/x86_64-pc-windows-gnu/release/osutil.exe dist/osutil-windows-x86_64-gnu.exe

echo "==> macOS (Darwin)"
cargo zigbuild --release --target x86_64-apple-darwin --all-features
cp target/x86_64-apple-darwin/release/osutil dist/osutil-macos-x86_64

cargo zigbuild --release --target aarch64-apple-darwin --all-features
cp target/aarch64-apple-darwin/release/osutil dist/osutil-macos-arm64

echo "==> FreeBSD (x86_64)"
cross build --release --target x86_64-unknown-freebsd --all-features
cp target/x86_64-unknown-freebsd/release/osutil dist/osutil-freebsd-x86_64

# Show what we built
echo -e "${GREEN}✅ Build complete! Created files:${NC}"
ls -la dist/

# Create release
echo -e "${YELLOW}📤 Creating GitHub release...${NC}"

# Create release notes
cat > release_notes.md << EOF
## Downloads

### Linux (musl)
- **x86_64**: \`osutil-linux-x86_64\`
- **aarch64**: \`osutil-linux-aarch64\`
- **armv7l**: \`osutil-linux-armv7\`

### macOS
- **x86_64**: \`osutil-macos-x86_64\`
- **arm64**: \`osutil-macos-arm64\`

### Windows
- **x86_64 (GNU)**: \`osutil-windows-x86_64-gnu.exe\`

### FreeBSD
- **x86_64**: \`osutil-freebsd-x86_64\`

## Installation

### macOS, Linux, & FreeBSD
\`\`\`bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install.sh)
\`\`\`

### Windows
\`\`\`powershell
irm https://raw.githubusercontent.com/Jaredy899/osutil/main/install-windows.ps1 | iex
\`\`\`
EOF

# Create the release
gh release create "$VERSION" \
    --title "Release $VERSION" \
    --notes-file release_notes.md \
    dist/*

# Clean up
rm release_notes.md

echo -e "${GREEN}🎉 Release $VERSION created successfully!${NC}"
echo -e "${YELLOW}🔗 View at: https://github.com/Jaredy899/osutil/releases/tag/$VERSION${NC}"
