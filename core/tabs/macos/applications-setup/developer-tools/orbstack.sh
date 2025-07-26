#!/bin/sh -e

. ../../common-script.sh

installOrbstack() {
    if ! brewprogram_exists orbstack; then
        printf "%b\n" "${YELLOW}Installing Orbstack...${RC}"
        if ! brew install --cask orbstack; then
            printf "%b\n" "${RED}Failed to install Orbstack. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Orbstack installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Orbstack is already installed.${RC}"
    fi
}

checkEnv
installOrbstack