#!/bin/sh -e

. ../common-script.sh

installRuby() {
    printf "%b\n" "${YELLOW}Installing Ruby via mise...${RC}"

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest stable Ruby
    mise use -g ruby@latest

    printf "%b\n" "${GREEN}Ruby installed via mise. Restart your shell or source your shell profile to use Ruby.${RC}"
}

checkEnv
installRuby


