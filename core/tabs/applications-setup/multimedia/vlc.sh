#!/bin/sh -e

. ../../common-script.sh

installVLC() {
    if ! brewprogram_exists vlc; then
        printf "%b\n" "${YELLOW}Installing VLC...${RC}"
        if ! brew install --cask vlc; then
            printf "%b\n" "${RED}Failed to install VLC. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}VLC installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}VLC is already installed.${RC}"
    fi
}

checkEnv
installVLC