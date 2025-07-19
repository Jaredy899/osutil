#!/bin/sh -e

. ../../common-script.sh

installThunderBird() {
    if ! brewprogram_exists thunderbird; then
        printf "%b\n" "${YELLOW}Installing Thunderbird...${RC}"
        brew install --cask thunderbird
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Thunderbird. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Thunderbird installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Thunderbird is already installed.${RC}"
    fi
}

checkEnv
installThunderBird