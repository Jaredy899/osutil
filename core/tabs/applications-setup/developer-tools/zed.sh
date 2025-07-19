#!/bin/sh -e

. ../../common-script.sh

installZed() {
    if ! brewprogram_exists zed; then
        printf "%b\n" "${CYAN}Installing Zed.${RC}"
        brew install --cask zed
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Zed. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Zed installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Zed is already installed.${RC}"
    fi
}

checkEnv
installZed