#!/bin/sh -e

. ../common-script.sh

installYazi() {
    if ! brewprogram_exists yazi; then
        printf "%b\n" "${YELLOW}Installing Yazi...${RC}"
        if ! brew install yazi ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick; then
            printf "%b\n" "${RED}Failed to install Yazi. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Yazi installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Yazi is already installed.${RC}"
    fi
}

checkEnv
installYazi
