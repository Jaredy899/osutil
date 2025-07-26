#!/bin/sh -e

. ../common-script.sh

installCommanderOne() {
    if ! brewprogram_exists commander-one; then
        printf "%b\n" "${YELLOW}Installing Commander One...${RC}"
        if ! brew install --cask commander-one; then
            printf "%b\n" "${RED}Failed to install Commander One. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Commander One installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Commander One is already installed.${RC}"
    fi
}

checkEnv
installCommanderOne