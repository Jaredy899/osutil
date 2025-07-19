#!/bin/sh -e

. ../common-script.sh

installKitty() {
    if ! brewprogram_exists kitty; then
        brew install --cask kitty
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Kitty. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Kitty installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
    fi
}

setupKittyConfig() {
    printf "%b\n" "${YELLOW}Copying Kitty configuration files...${RC}"
    if [ -d "${HOME}/.config/kitty" ] && [ ! -d "${HOME}/.config/kitty-bak" ]; then
        cp -r "${HOME}/.config/kitty" "${HOME}/.config/kitty-bak"
    fi
    mkdir -p "${HOME}/.config/kitty/"
    curl -sSLo "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    curl -sSLo "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
installKitty
setupKittyConfig