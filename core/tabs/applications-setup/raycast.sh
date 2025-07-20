#!/bin/sh -e

. ../common-script.sh

installRaycast() {
    if ! brewprogram_exists raycast; then
        printf "%b\n" "${YELLOW}Installing Raycast...${RC}"
        if ! brew install --cask raycast; then
            printf "%b\n" "${RED}Failed to install Raycast. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Raycast installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Raycast is already installed.${RC}"
    fi
}

checkEnv
installRaycast