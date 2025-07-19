#!/bin/sh -e

. ../../common-script.sh

installVsCode() {
    if ! brewprogram_exists visual-studio-code; then
        printf "%b\n" "${YELLOW}Installing VS Code..${RC}."
        brew install --cask visual-studio-code
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install VS Code. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}VS Code installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}VS Code is already installed.${RC}"
    fi
}

checkEnv
installVsCode 