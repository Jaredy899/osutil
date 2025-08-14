#!/bin/sh -e

. ../common-script.sh

installRust() {
    if command -v rustup >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}rustup detected. Updating to latest stable...${RC}"
        rustup default stable
        rustup update stable
        rustup component add rustfmt clippy
        printf "%b\n" "${GREEN}Rust toolchain is up-to-date (stable).${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing rustup and setting stable toolchain...${RC}"
    if ! brew install rustup-init; then
        printf "%b\n" "${RED}Failed to install rustup-init with Homebrew.${RC}"
        exit 1
    fi

    rustup-init -y

    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi

    rustup default stable
    rustup component add rustfmt clippy

    printf "%b\n" "${GREEN}Rust (stable) installed. Restart your shell or source \"$HOME/.cargo/env\" to update PATH.${RC}"
}

checkEnv
installRust


