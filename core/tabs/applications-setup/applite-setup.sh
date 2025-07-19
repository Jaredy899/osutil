#!/bin/sh -e

. ../common-script.sh

installApplite() {
    if ! brewprogram_exists applite; then
        brew install --cask applite
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Kitty. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Kitty installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
    fi
}

checkEnv
installApplite