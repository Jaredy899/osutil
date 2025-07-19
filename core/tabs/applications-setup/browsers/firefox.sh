#!/bin/sh -e

. ../../common-script.sh

installFirefox() {
    if ! brewprogram_exists firefox; then
        printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
        brew install --cask firefox
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Firefox Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Firefox Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Firefox Browser is already installed.${RC}"
    fi
}

checkEnv
installFirefox