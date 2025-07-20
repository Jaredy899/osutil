#!/bin/sh -e

. ../../common-script.sh

installOnyx() {
    if ! brewprogram_exists onyx; then
        printf "%b\n" "${YELLOW}Installing Onyx...${RC}"
        brew install --cask onyx
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Onyx. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Onyx installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Onyx is already installed.${RC}"
    fi
}

checkEnv
installOnyx