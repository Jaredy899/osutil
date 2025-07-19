#!/bin/sh -e

. ../../common-script.sh

installLibreWolf() {
    if ! brewprogram_exists librewolf; then
        printf "%b\n" "${YELLOW}Installing Librewolf...${RC}"
        brew install --cask librewolf
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install LibreWolf Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}LibreWolf Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}LibreWolf Browser is already installed.${RC}"
    fi
}

checkEnv
installLibreWolf