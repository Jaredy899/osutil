#!/bin/sh -e

. ../../common-script.sh

installAlacritty() {
    if ! brewprogram_exists alacritty; then
        printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
        if ! brew install --cask alacritty; then
            printf "%b\n" "${RED}Failed to install Alacritty. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Alacritty installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Alacritty is already installed.${RC}"
    fi
}

checkEnv
installAlacritty
