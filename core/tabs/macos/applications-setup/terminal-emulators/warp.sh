#!/bin/sh -e

. ../../common-script.sh

installWarp() {
    if ! brewprogram_exists warp; then
        printf "%b\n" "${YELLOW}Installing Warp...${RC}"
        if ! brew install --cask warp; then
            printf "%b\n" "${RED}Failed to install Warp. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Warp installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Warp is already installed.${RC}"
    fi
}

checkEnv
installWarp
