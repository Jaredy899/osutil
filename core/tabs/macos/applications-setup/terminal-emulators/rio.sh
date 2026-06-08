#!/bin/sh -e

. ../../common-script.sh

installRio() {
    if ! brewprogram_exists rio; then
        printf "%b\n" "${YELLOW}Installing Rio...${RC}"
        if ! brew install --cask rio; then
            printf "%b\n" "${RED}Failed to install Rio. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Rio installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Rio is already installed.${RC}"
    fi
}

checkEnv
installRio
