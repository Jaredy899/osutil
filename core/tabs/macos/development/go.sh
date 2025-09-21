#!/bin/sh -e

. ../common-script.sh

installGo() {
    printf "%b\n" "${YELLOW}Installing Go via mise...${RC}"

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest stable Go
    mise use -g go@latest

    printf "%b\n" "${GREEN}Go installed via mise. Restart your shell or source your shell profile to use Go.${RC}"
}

checkEnv
installGo


