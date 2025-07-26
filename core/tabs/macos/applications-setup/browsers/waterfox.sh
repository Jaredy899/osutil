#!/bin/sh -e

. ../../common-script.sh

installWaterfox() {
    if ! brewprogram_exists waterfox; then
        printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
        if ! brew install --cask waterfox; then
            printf "%b\n" "${RED}Failed to install Waterfox Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Waterfox Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Waterfox is already installed.${RC}"
    fi
}

checkEnv
installWaterfox
