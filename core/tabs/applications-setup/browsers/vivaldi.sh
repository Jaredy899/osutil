#!/bin/sh -e

. ../../common-script.sh

installVivaldi() {
    if ! brewprogram_exists vivaldi; then
        printf "%b\n" "${YELLOW}Installing Vivaldi...${RC}"
        brew install --cask vivaldi
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Vivaldi Browser. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Vivaldi Browser installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Vivaldi Browser is already installed.${RC}"
    fi
}

checkEnv
installVivaldi