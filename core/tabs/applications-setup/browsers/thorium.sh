#!/bin/sh -e

. ../../common-script.sh

installThorium() {
    if ! brewprogram_exists alex313031-thorium; then
        printf "%b\n" "${YELLOW}Installing Thorium Browser...${RC}"
        brew install --cask alex313031-thorium
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Thorium Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Thorium Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Thorium Browser is already installed.${RC}"
    fi
}

checkEnv
installThorium