#!/bin/sh -e

. ../../common-script.sh

installOBS() {
    if ! brewprogram_exists obs; then
        printf "%b\n" "${YELLOW}Installing OBS...${RC}"
        if ! brew install --cask obs; then
            printf "%b\n" "${RED}Failed to install OBS. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}OBS installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}OBS is already installed.${RC}"
    fi
}

checkEnv
installOBS