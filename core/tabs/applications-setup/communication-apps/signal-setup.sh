#!/bin/sh -e

. ../../common-script.sh

installSignal() {
    if ! brewprogram_exists signal; then
        printf "%b\n" "${YELLOW}Installing Signal...${RC}"
        brew install --cask signal
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Signal. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Signal installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Signal is already installed.${RC}"
    fi
}

checkEnv
installSignal