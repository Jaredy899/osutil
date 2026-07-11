#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installNode() {
    printf "%b\n" "${YELLOW}Installing Node.js via mise...${RC}"
    ensureMise
    mise use -g node@latest

    if command_exists corepack; then
        corepack enable || true
        corepack prepare yarn@stable --activate || true
        corepack prepare pnpm@latest --activate || true
    fi

    printf "%b\n" "${GREEN}Node.js installed via mise. Restart your shell or run: eval \"\$(mise activate zsh)\"${RC}"
}

checkEnv
installNode
