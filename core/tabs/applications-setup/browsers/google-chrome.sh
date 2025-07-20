#!/bin/sh -e

. ../../common-script.sh

installChrome() {
    if ! brewprogram_exists google-chrome; then
        printf "%b\n" "${YELLOW}Installing Google Chrome...${RC}"
        if ! brew install --cask google-chrome; then
            printf "%b\n" "${RED}Failed to install Google Chrome Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Google Chrome Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Google Chrome Browser is already installed.${RC}"
    fi
}

checkEnv
installChrome