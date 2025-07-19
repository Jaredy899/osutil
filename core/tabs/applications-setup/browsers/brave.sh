#!/bin/sh -e

. ../../common-script.sh

installBrave() {
    if ! brewprogram_exists brave-browser; then
        printf "%b\n" "${YELLOW}Installing Brave...${RC}"
        brew install --cask brave-browser
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Brave Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Brave Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Brave Browser is already installed.${RC}"
    fi
}

checkEnv
installBrave