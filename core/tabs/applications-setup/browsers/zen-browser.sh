#!/bin/sh -e

. ../../common-script.sh

installZenBrowser() {
    if ! brewprogram_exists zen; then
        printf "%b\n" "${YELLOW}Installing Zen Browser...${RC}"
        brew install --cask zen
        if [ $? -ne 0 ]; then
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