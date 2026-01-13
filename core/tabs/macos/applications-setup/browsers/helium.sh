#!/bin/sh -e

. ../../common-script.sh

installHelium() {
    if ! brewprogram_exists helium-browser; then
        printf "%b\n" "${YELLOW}Installing Helium Browser...${RC}"
        if ! brew install --cask helium-browser; then
            printf "%b\n" "${RED}Failed to install Helium Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Helium Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Helium Browser is already installed.${RC}"
    fi
}

checkEnv
installHelium
