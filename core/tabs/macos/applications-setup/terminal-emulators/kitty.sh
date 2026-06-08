#!/bin/sh -e

. ../../common-script.sh

installKitty() {
    if ! brewprogram_exists kitty; then
        printf "%b\n" "${YELLOW}Installing Kitty...${RC}"
        if ! brew install --cask kitty; then
            printf "%b\n" "${RED}Failed to install Kitty. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Kitty installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
    fi
}

checkEnv
installKitty
