#!/bin/sh -e

. ../../common-script.sh

installZoom() {
    if ! brewprogram_exists zoom; then
        printf "%b\n" "${YELLOW}Installing Zoom...${RC}"
        brew install --cask zoom
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Zoom. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Zoom installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Zoom is already installed.${RC}"
    fi
}

checkEnv
installZoom