#!/bin/sh -e

. ../../common-script.sh

installZellij() {
    if ! brewprogram_exists zellij; then
        printf "%b\n" "${YELLOW}Installing Zellij...${RC}"
        if ! brew install zellij; then
            printf "%b\n" "${RED}Failed to install Zellij. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Zellij installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Zellij is already installed.${RC}"
    fi
}

checkEnv
installZellij
