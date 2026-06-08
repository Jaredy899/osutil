#!/bin/sh -e

. ../../common-script.sh

installTabby() {
    if ! brewprogram_exists tabby; then
        printf "%b\n" "${YELLOW}Installing Tabby...${RC}"
        if ! brew install --cask tabby; then
            printf "%b\n" "${RED}Failed to install Tabby. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Tabby installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Tabby is already installed.${RC}"
    fi
}

checkEnv
installTabby
