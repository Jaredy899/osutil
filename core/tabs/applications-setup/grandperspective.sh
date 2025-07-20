#!/bin/sh -e

. ../common-script.sh

installGrandPerspective() {
    if ! brewprogram_exists grandperspective; then
        printf "%b\n" "${YELLOW}Installing GrandPerspective...${RC}"
        if ! brew install --cask grandperspective; then
            printf "%b\n" "${RED}Failed to install GrandPerspective. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}GrandPerspective installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}GrandPerspective is already installed.${RC}"
    fi
}

checkEnv
installGrandPerspective