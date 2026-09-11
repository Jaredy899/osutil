#!/usr/bin/env bash
# osutil release script. Run it, answer two questions, done.
#
#   ./build.sh
#     1. asks which version to build (defaults to the current one)
#     2. updates Cargo deps + version, builds Linux and macOS binaries into dist/
#     3. asks whether to commit, tag, push, and publish a GitHub release
#
# Works on Linux or macOS. Missing tools (rustup targets, cargo-zigbuild, macOS SDK) install themselves.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

APP="osutil"
OUT="dist"
TARGETS=(
    x86_64-unknown-linux-musl:linux-x86_64
    aarch64-unknown-linux-musl:linux-aarch64
    armv7-unknown-linux-musleabihf:linux-armv7
    x86_64-apple-darwin:macos-x86_64
    aarch64-apple-darwin:macos-arm64
)

########################################
# 1. Version
########################################
current="$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -n1)"
read -r -p "Version to build [$current]: " version
version="${version:-$current}"
version="${version#v}"
tag="v$version"

if git rev-parse "$tag" >/dev/null 2>&1 && [[ "$version" != "$current" ]]; then
    echo "error: tag $tag already exists" >&2
    exit 1
fi

########################################
# 2. Toolchain
########################################
if command -v mise >/dev/null 2>&1; then
    eval "$(mise env -s bash)"
    mise install
fi
# shellcheck source=/dev/null
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -x "$HOME/.cargo/bin/rustup" ]] && export PATH="$HOME/.cargo/bin:$PATH"

command -v cargo >/dev/null || { echo "error: cargo not found (https://rustup.rs)" >&2; exit 1; }
command -v zig   >/dev/null || { echo "error: zig not found (install zig or run 'mise install')" >&2; exit 1; }

sysroot="$(rustc --print sysroot)"
missing=()
for t in "${TARGETS[@]}"; do
    [[ -d "$sysroot/lib/rustlib/${t%%:*}" ]] || missing+=("${t%%:*}")
done
if (( ${#missing[@]} )); then
    if ! command -v rustup >/dev/null; then
        echo "==> Installing rustup (system Rust lacks cross targets)"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | RUSTUP_INIT_SKIP_PATH_CHECK=yes sh -s -- -y --default-toolchain stable
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    echo "==> Adding Rust targets: ${missing[*]}"
    rustup target add "${missing[@]}"
fi

command -v cargo-zigbuild >/dev/null || { echo "==> Installing cargo-zigbuild"; cargo install cargo-zigbuild --locked; }

if [[ "$(uname -s)" == "Darwin" ]]; then
    [[ -n "${SDKROOT:-}" ]] || export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
elif [[ -z "${SDKROOT:-}" || ! -d "$SDKROOT" ]]; then
    sdk_ver="${MACOSX_SDK_VERSION:-14.5}"
    cache="${XDG_CACHE_HOME:-$HOME/.cache}/osutil"
    sdk="$cache/MacOSX${sdk_ver}.sdk"
    if [[ ! -d "$sdk" ]]; then
        echo "==> Downloading macOS $sdk_ver SDK to $cache"
        mkdir -p "$cache"
        curl -fL --retry 3 -o "$cache/sdk.tar.xz" \
            "https://github.com/joseluisq/macosx-sdks/releases/download/${sdk_ver}/MacOSX${sdk_ver}.sdk.tar.xz"
        tar -xJf "$cache/sdk.tar.xz" -C "$cache"
        rm -f "$cache/sdk.tar.xz"
    fi
    export SDKROOT="$sdk"
fi

########################################
# 3. Update Cargo + build
########################################
echo "==> Setting version $version"
sed -i.bak "s/^version = \".*\"/version = \"$version\"/" Cargo.toml && rm -f Cargo.toml.bak

echo "==> Updating dependencies"
cargo update

rm -rf "$OUT"
mkdir -p "$OUT"
for t in "${TARGETS[@]}"; do
    target="${t%%:*}"
    name="${t##*:}"
    echo "==> Building $target"
    cargo zigbuild --release --target "$target" --all-features
    cp "target/$target/release/$APP" "$OUT/$APP-$name"
done

echo
echo "==> Built $tag:"
ls -lh "$OUT"
echo

########################################
# 4. Push + release
########################################
read -r -p "Commit, tag $tag, push, and publish GitHub release? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Skipped push. Binaries are in $OUT/."; exit 0; }

command -v gh >/dev/null       || { echo "error: gh CLI not found" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "error: run 'gh auth login' first" >&2; exit 1; }

git add Cargo.toml Cargo.lock
git diff --cached --quiet || git commit -m "$version"
git rev-parse "$tag" >/dev/null 2>&1 || git tag "$tag"
git push origin HEAD "$tag"

notes="$(mktemp)"
trap 'rm -f "$notes"' EXIT
cat > "$notes" <<EOF
## Downloads

### Linux (musl)
- **x86_64**: \`$APP-linux-x86_64\`
- **aarch64**: \`$APP-linux-aarch64\`
- **armv7l**: \`$APP-linux-armv7\`

### macOS
- **Intel**: \`$APP-macos-x86_64\`
- **Apple Silicon**: \`$APP-macos-arm64\`

## Installation

\`\`\`bash
sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/osutil/main/install.sh)
\`\`\`
EOF

gh release create "$tag" --title "Release $tag" --notes-file "$notes" "$OUT"/*
echo "==> Released: $(gh release view "$tag" --json url -q .url)"
