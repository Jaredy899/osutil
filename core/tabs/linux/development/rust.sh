#!/bin/sh -e

. ../common-script.sh

installRust() {
    printf "%b\n" "${YELLOW}Installing Rust via mise...${RC}"

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest stable Rust
    mise use -g rust@latest

    # Add rustfmt and clippy components
    if command_exists rustup; then
        rustup component add rustfmt clippy || true
    fi

    printf "%b\n" "${GREEN}Rust installed via mise. Restart your shell or source your shell profile to use Rust.${RC}"
}

checkEnv
installRust


