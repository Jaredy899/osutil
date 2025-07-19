#!/bin/sh -e

. ../../common-script.sh

installJetBrainsToolBox() {
    if ! brewprogram_exists jetbrains-toolbox; then
        printf "%b\n" "${YELLOW}Installing Jetbrains Toolbox...${RC}"
        brew install --cask jetbrains-toolbox
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Jetbrains Toolbox. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Successfully installed Jetbrains Toolbox.${RC}"
    else
        printf "%b\n" "${GREEN}Jetbrains toolbox is already installed.${RC}"
    fi
}

checkEnv
installJetBrainsToolBox