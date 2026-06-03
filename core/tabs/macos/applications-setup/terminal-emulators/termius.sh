#!/bin/sh -e

. ../../common-script.sh

installTermius() {
    if ! brewprogram_exists termius; then
        printf "%b\n" "${YELLOW}Installing Termius...${RC}"
        if ! brew install --cask termius; then
            printf "%b\n" "${RED}Failed to install Termius. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Termius installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Termius is already installed.${RC}"
    fi
}

checkEnv
installTermius
