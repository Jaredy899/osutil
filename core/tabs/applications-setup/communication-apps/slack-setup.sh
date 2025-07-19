#!/bin/sh -e

. ../../common-script.sh

installSlack() {
    if ! brewprogram_exists slack; then
        printf "%b\n" "${YELLOW}Installing Slack...${RC}"
        brew install --cask slack
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Slack. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Slack installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Slack is already installed.${RC}"
    fi
}

checkEnv
installSlack