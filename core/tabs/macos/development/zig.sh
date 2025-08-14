#!/bin/sh -e

. ../common-script.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing Zig (via Homebrew)...${RC}"
    if ! brew install zig; then
        printf "%b\n" "${RED}Failed to install Zig with Homebrew.${RC}"
        exit 1
    fi
    printf "%b\n" "${GREEN}Zig installed. Verify with: zig version${RC}"
}

checkEnv
installZig


