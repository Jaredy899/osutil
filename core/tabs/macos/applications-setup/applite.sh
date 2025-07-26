#!/bin/sh -e

. ../common-script.sh

installApplite() {
    if ! brewprogram_exists applite; then
        if ! brew install --cask applite; then
            printf "%b\n" "${RED}Failed to install Applite. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Applite installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Applite is already installed.${RC}"
    fi
}

checkEnv
installApplite