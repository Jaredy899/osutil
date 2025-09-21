#!/bin/sh -e

. ../common-script.sh

installJava() {
    printf "%b\n" "${YELLOW}Installing Java via mise...${RC}"

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest LTS Java (prefer 21, fallback to 17)
    if mise ls-remote java | grep -q "21\."; then
        mise use -g java@21
    else
        mise use -g java@17
    fi

    printf "%b\n" "${GREEN}Java installed via mise. Restart your shell or source your shell profile to use Java.${RC}"
}

checkEnv
installJava


