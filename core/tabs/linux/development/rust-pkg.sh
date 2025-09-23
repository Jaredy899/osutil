#!/bin/sh -e

. ../common-script.sh

installRust() {
    printf "%b\n" "${YELLOW}Installing Rust via rustup...${RC}"

    # Ensure curl and bash are available
    "$ESCALATION_TOOL" "$PACKAGER" install -y curl bash

    # Install rustup if not already installed
    if ! command_exists rustup; then
        printf "%b\n" "${YELLOW}Installing rustup...${RC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
    fi

    # Install latest stable Rust
    printf "%b\n" "${YELLOW}Installing latest stable Rust...${RC}"
    rustup install stable
    rustup default stable

    # Install additional components
    printf "%b\n" "${YELLOW}Installing additional Rust components...${RC}"
    rustup component add rustfmt
    rustup component add clippy

    # Ensure cargo is in PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"

    printf "%b\n" "${GREEN}Rust installed successfully!${RC}"
    printf "%b\n" "${CYAN}Rust version: $(rustc --version)${RC}"
    printf "%b\n" "${CYAN}Cargo version: $(cargo --version)${RC}"
}

checkEnv
installRust
