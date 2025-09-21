#!/bin/sh -e

. ../common-script.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing Zig via mise...${RC}"

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest stable Zig
    mise use -g zig@latest

    printf "%b\n" "${GREEN}Zig installed via mise. Restart your shell or source your shell profile to use Zig.${RC}"
}

checkEnv
installZig
