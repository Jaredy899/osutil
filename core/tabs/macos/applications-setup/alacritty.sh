#!/bin/sh -e

. ../common-script.sh

installAlacritty() {
    if ! brewprogram_exists alacritty; then
    printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
        if ! brew install --cask alacritty; then
            printf "%b\n" "${RED}Failed to install Alacritty. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
    else
        printf "%b\n" "${GREEN}Alacritty is already installed.${RC}"
    fi
}

setupAlacrittyConfig() {
    printf "%b\n" "${YELLOW}Copying alacritty config files...${RC}"
    if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -fsSLo "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    curl -fsSLo "${HOME}/.config/alacritty/keybinds.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/keybinds.toml"
    curl -fsSLo "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
    printf "%b\n" "${GREEN}Alacritty configuration files copied.${RC}"
}

checkEnv
installAlacritty
setupAlacrittyConfig