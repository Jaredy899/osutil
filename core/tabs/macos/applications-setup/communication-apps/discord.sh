#!/bin/sh -e

. ../../common-script.sh

installDiscord() {
    if ! brewprogram_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        if ! brew install --cask discord; then
            printf "%b\n" "${RED}Failed to install Discord. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Discord installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Discord is already installed.${RC}"
    fi
}

checkEnv
installDiscord