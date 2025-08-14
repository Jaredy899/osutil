#!/bin/sh -e

. ../common-script.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing Zig (via Homebrew)...${RC}"
    if brewprogram_exists zig; then
        printf "%b\n" "${GREEN}Zig already installed. Skipping.${RC}"
        return 0
    fi
    if ! brew install zig; then
        printf "%b\n" "${RED}Failed to install Zig with Homebrew.${RC}"
        exit 1
    fi
    printf "%b\n" "${GREEN}Zig installed. Verify with: zig version${RC}"
}

checkEnv
installZig


