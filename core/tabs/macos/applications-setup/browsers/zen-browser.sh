#!/bin/sh -e

. ../../common-script.sh

installZenBrowser() {
    if ! brewprogram_exists zen-browser; then
        printf "%b\n" "${YELLOW}Installing Zen Browser...${RC}"
        if ! brew install --cask zen-browser; then
            printf "%b\n" "${RED}Failed to install Zen Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Zen Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Zen Browser is already installed.${RC}"
    fi
}

checkEnv
installZenBrowser