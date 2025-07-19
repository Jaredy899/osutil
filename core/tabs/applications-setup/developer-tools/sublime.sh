#!/bin/sh -e

. ../../common-script.sh

installSublime() {
    if ! brewprogram_exists sublime-text; then
        printf "%b\n" "${YELLOW}Installing Sublime...${RC}"
        brew install --cask sublime-text
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Sublime. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Sublime installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Sublime is already installed.${RC}"
    fi

}

checkEnv
installSublime