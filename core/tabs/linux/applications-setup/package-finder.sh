#!/bin/sh -e

. ../common-script.sh

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies for pkg-tui...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm fzf coreutils
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf coreutils
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf coreutils
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf coreutils
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add fzf coreutils
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf coreutils
            ;;
        moss)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf uutils-coreutils
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy fzf coreutils
            ;;
        rpm-ostree)
            "$ESCALATION_TOOL" "$PACKAGER" install --allow-inactive fzf coreutils
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    printf "%b\n" "${GREEN}Dependencies installed.${RC}"
}

ensureRustToolchain() {
    if command_exists rustc; then
        return 0
    fi

    printf "%b\n" "${YELLOW}Rust toolchain not found. Installing via rustup...${RC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal

    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi

    if command_exists rustup; then
        rustup default stable >/dev/null 2>&1 || true
    fi

    if ! command_exists rustc; then
        printf "%b\n" "${RED}Failed to install Rust toolchain.${RC}"
        exit 1
    fi
}

buildPkgTui() {
    printf "%b\n" "${YELLOW}Building pkg-tui Rust utility...${RC}"
    ensureRustToolchain

    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi

    script_dir=$(dirname "$(realpath "$0")")
    rust_source="$script_dir/pkg-tui.rs"
    if [ ! -f "$rust_source" ]; then
        printf "%b\n" "${RED}Missing Rust source file: $rust_source${RC}"
        exit 1
    fi

    tmpdir=$(mktemp -d)
    binfile="$tmpdir/pkg-tui"
    rustc --edition=2021 -O "$rust_source" -o "$binfile"

    if [ "$PACKAGER" = "eopkg" ] || [ "$PACKAGER" = "moss" ] || [ "$PACKAGER" = "rpm-ostree" ]; then
        target="/usr/bin/pkg-tui"
    else
        target="/usr/local/bin/pkg-tui"
    fi

    "$ESCALATION_TOOL" mv "$binfile" "$target"
    "$ESCALATION_TOOL" chmod +x "$target"
    rm -rf "$tmpdir"
    printf "%b\n" "${GREEN}pkg-tui installed to ${target}${RC}"

    printf "%b\n" "${YELLOW}Pre-warming package cache (first run optimization)...${RC}"
    "$target" --refresh-cache >/dev/null 2>&1 || printf "%b\n" "${YELLOW}Cache warm-up failed; pkg-tui will refresh on first use.${RC}"
}

addAlias() {
    if ! grep -q "alias pfind=" "$HOME/.bashrc"; then
        echo "alias pfind='pkg-tui'" >> "$HOME/.bashrc"
        printf "%b\n" "${GREEN}Alias 'pfind' added to .bashrc${RC}"
    else
        printf "%b\n" "${CYAN}Alias 'pfind' already exists in .bashrc${RC}"
    fi

    printf "%b\n" "${GREEN}pkg-tui installation complete.${RC}"
    printf "%b\n" "${CYAN}Run 'pfind' or 'pkg-tui' to start.${RC}"
}

# Main
checkEnv
checkEscalationTool
installDependencies
buildPkgTui
# addAlias