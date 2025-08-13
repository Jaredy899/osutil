#!/bin/sh -e

. ../common-script.sh

installFastfetch() {
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${RC}"
        if ! brew install fastfetch; then
            printf "%b\n" "${RED}Failed to install Fastfetch. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Fastfetch installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Fastfetch is already installed.${RC}"
    fi
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Copying Fastfetch config files...${RC}"
    if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
        cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -fsSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/config.jsonc
}

setupFastfetchShell() {
    printf "%b\n" "${YELLOW}Configuring shell integration...${RC}"

    current_shell=$(basename "$SHELL")
    rc_file=""

    case "$current_shell" in
    "bash")
        rc_file="$HOME/.bashrc"
        ;;
    "zsh")
        rc_file="$HOME/.zshrc"
        ;;
    "fish")
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    "nu")
        rc_file="$HOME/.config/nushell/config.nu"
        ;;
    *)
        printf "%b\n" "${RED}$current_shell is not supported. Update your shell configuration manually.${RC}"
        ;;
    esac

    if [ ! -f "$rc_file" ]; then
        printf "%b\n" "${RED}Shell config file $rc_file not found${RC}"
    else
        if grep -q "fastfetch" "$rc_file"; then
            printf "%b\n" "${YELLOW}Fastfetch is already configured in $rc_file${RC}"
            return 0
        else
            if [ "${ADD_FASTFETCH_TO_SHELL:-0}" = "1" ]; then
                printf "\n# Run fastfetch on shell initialization\nfastfetch\n" >>"$rc_file"
                printf "%b\n" "${GREEN}Added fastfetch to $rc_file${RC}"
            else
                printf "%b\n" "${YELLOW}Skipped adding fastfetch to shell config (set ADD_FASTFETCH_TO_SHELL=1 to enable)${RC}"
            fi
        fi
    fi

}

checkEnv
installFastfetch
setupFastfetchConfig
setupFastfetchShell
