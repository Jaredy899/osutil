#!/bin/sh -e

. ../../common-script.sh

installChromium() {
if ! brewprogram_exists chromium; then
    printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
    brew install --cask chromium
    if [ $? -ne 0 ]; then
        printf "%b\n" "${RED}Failed to install Chromium Browser. Please check your Homebrew installation or try again later.${RC}"
        exit 1
    fi
    printf "%b\n" "${GREEN}Chromium Browser installed successfully!${RC}"
else
    printf "%b\n" "${GREEN}Chromium Browser is already installed.${RC}"
fi
}

checkEnv
installChromium