#!/bin/sh -e

. ../../common-script.sh

installIina() {
    if ! brewprogram_exists iina; then
        printf "%b\n" "${YELLOW}Installing IINA...${RC}"
        if ! brew install --cask iina; then
            printf "%b\n" "${RED}Failed to install IINA. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}IINA installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}IINA is already installed.${RC}"
    fi
}

checkEnv
installIina