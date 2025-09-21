#!/bin/sh -e

. ../common-script.sh

installNode() {
    printf "%b\n" "${YELLOW}Installing Node.js via mise...${RC}"

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest Node.js
    mise use -g node@latest

    # Enable Corepack (yarn/pnpm)
    if command_exists corepack; then
        corepack enable || true
        corepack prepare yarn@stable --activate || true
        corepack prepare pnpm@latest --activate || true
    fi

    printf "%b\n" "${GREEN}Node.js installed via mise. Restart your shell or source your shell profile to use Node.js.${RC}"
}

checkEnv
installNode


