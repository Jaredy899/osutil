#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installRust() {
    printf "%b\n" "${YELLOW}Installing Rust via mise...${RC}"
    ensureMise
    mise use -g rust@latest

    if command_exists rustup; then
        rustup component add rustfmt clippy || true
    fi

    printf "%b\n" "${GREEN}Rust installed via mise. Restart your shell or run: eval \"\$(mise activate bash)\"${RC}"
}

checkEnv
installRust
