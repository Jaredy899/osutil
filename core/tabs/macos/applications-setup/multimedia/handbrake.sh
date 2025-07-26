#!/bin/sh -e

. ../../common-script.sh

installHandbrake() {
    if ! brewprogram_exists handbrake; then
        printf "%b\n" "${YELLOW}Installing Handbrake...${RC}"
        if ! brew install --cask handbrake; then
            printf "%b\n" "${RED}Failed to install Handbrake. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Handbrake installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Handbrake is already installed.${RC}"
    fi
}

checkEnv
installHandbrake