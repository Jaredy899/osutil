#!/bin/sh -e

. ../../common-script.sh

installITerm2() {
    if ! brewprogram_exists iterm2; then
        printf "%b\n" "${YELLOW}Installing iTerm2...${RC}"
        if ! brew install --cask iterm2; then
            printf "%b\n" "${RED}Failed to install iTerm2. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}iTerm2 installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}iTerm2 is already installed.${RC}"
    fi
}

checkEnv
installITerm2
