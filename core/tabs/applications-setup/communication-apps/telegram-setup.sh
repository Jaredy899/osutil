#!/bin/sh -e

. ../../common-script.sh

installTelegram() {
    if ! brewprogram_exists telegram-desktop; then
        printf "%b\n" "${YELLOW}Installing Telegram...${RC}"
        brew install --cask telegram-desktop
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Telegram. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Telegram installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Telegram is already installed.${RC}"
    fi
}

checkEnv
installTelegram