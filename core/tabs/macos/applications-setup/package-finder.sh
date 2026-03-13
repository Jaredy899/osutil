#!/bin/sh -e

. ../common-script.sh

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies for pkg-tui...${RC}"

    if ! command_exists fzf; then
        brew install fzf
    fi

    if ! command_exists rustc; then
        brew install rust
    fi

    printf "%b\n" "${GREEN}Dependencies installed.${RC}"
}

buildPkgTui() {
    printf "%b\n" "${YELLOW}Building pkg-tui Rust utility...${RC}"

    script_dir="$(cd "$(dirname "$0")" && pwd)"
    rust_source="$script_dir/../../linux/applications-setup/pkg-tui.rs"
    if [ ! -f "$rust_source" ]; then
        printf "%b\n" "${RED}Missing Rust source file: $rust_source${RC}"
        exit 1
    fi

    tmpdir="$(mktemp -d)"
    binfile="$tmpdir/pkg-tui"
    rustc --edition=2021 -O "$rust_source" -o "$binfile"

    target="$(brew --prefix)/bin/pkg-tui"
    mv "$binfile" "$target"
    chmod +x "$target"
    rm -rf "$tmpdir"

    printf "%b\n" "${GREEN}pkg-tui installed to ${target}${RC}"
    printf "%b\n" "${YELLOW}Pre-warming package cache (first run optimization)...${RC}"
    "$target" --refresh-cache >/dev/null 2>&1 || printf "%b\n" "${YELLOW}Cache warm-up failed; pkg-tui will refresh on first use.${RC}"
}

# Main
checkEnv
installDependencies
buildPkgTui
