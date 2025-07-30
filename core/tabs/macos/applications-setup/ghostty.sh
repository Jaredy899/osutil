#!/bin/sh -e

. ../common-script.sh

installGhostty() {
    if ! brewprogram_exists ghostty; then
        if ! brew install --cask ghostty; then
            printf "%b\n" "${RED}Failed to install Ghostty. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Ghostty installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Ghostty is already installed.${RC}"
    fi
}

checkEnv
installGhostty