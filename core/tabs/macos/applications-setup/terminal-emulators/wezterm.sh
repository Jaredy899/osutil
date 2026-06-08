#!/bin/sh -e

. ../../common-script.sh

installWezTerm() {
    if ! brewprogram_exists wezterm; then
        printf "%b\n" "${YELLOW}Installing WezTerm...${RC}"
        if ! brew install --cask wezterm; then
            printf "%b\n" "${RED}Failed to install WezTerm. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}WezTerm installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}WezTerm is already installed.${RC}"
    fi
}

checkEnv
installWezTerm
