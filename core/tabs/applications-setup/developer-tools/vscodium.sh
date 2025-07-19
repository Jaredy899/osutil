#!/bin/sh -e

. ../../common-script.sh

installVsCodium() {
    if ! brewprogram_exists vscodium; then
        printf "%b\n" "${YELLOW}Installing VS Codium...${RC}"
        brew install --cask vscodium
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install VS Codium. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}VS Codium installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}VS Codium is already installed.${RC}"
    fi

}

checkEnv
installVsCodium