#!/bin/sh -e

. ../common-script.sh

MYBASH_DIR="$HOME/.local/share/mybash"

installDepend() {
    if [ ! -f "/usr/share/bash-completion/bash_completion" ] || \
       ! command_exists bash tar bat tree unzip fc-list git; then
        printf "%b\n" "${YELLOW}Installing Bash...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm \
                    bash bash-completion tar bat tree unzip fontconfig git
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add \
                    bash bash-completion tar bat tree unzip fontconfig git
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy \
                    bash bash-completion tar bat tree unzip fontconfig git
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y \
                    bash bash-completion tar bat tree unzip fontconfig git
                ;;
        esac
    fi
}

installFont() {
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "%b\n" "${GREEN}Font '$FONT_NAME' is installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing font '$FONT_NAME'${RC}"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_URL"
        unzip "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR/$FONT_NAME"
        mv "$TEMP_DIR"/*.ttf "$FONT_DIR/$FONT_NAME"
        fc-cache -fv
        rm -rf "$TEMP_DIR"
        printf "%b\n" "${GREEN}'$FONT_NAME' installed successfully.${RC}"
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        printf "%b\n" "${GREEN}Starship already installed${RC}"
    else
        if [ "$PACKAGER" = "eopkg" ]; then
            "$ESCALATION_TOOL" "$PACKAGER" install -y starship || {
                printf "%b\n" "${RED}Failed to install starship with Solus!${RC}"
                exit 1
            }
        else
            curl -sSL https://starship.rs/install.sh | "$ESCALATION_TOOL" sh || {
                printf "%b\n" "${RED}Failed to install starship!${RC}"
                exit 1
            }
        fi
    fi

    if command_exists fzf; then
        printf "%b\n" "${GREEN}Fzf already installed${RC}"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        "$ESCALATION_TOOL" ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "%b\n" "${GREEN}Zoxide already installed${RC}"
        return
    fi

    if [ "$PACKAGER" = "apk" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" add zoxide
    else
        if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
            printf "%b\n" "${RED}Something went wrong during zoxide install!${RC}"
            exit 1
        fi
    fi
}

linkConfig() {
    OLD_BASHRC="$HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
        printf "%b\n" "${YELLOW}Moving old bash config file to $HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$HOME/.bashrc.bak"; then
            printf "%b\n" "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${YELLOW}Linking new bash config file...${RC}"
    ln -svf "$MYBASH_DIR/.bashrc" "$HOME/.bashrc" || {
        printf "%b\n" "${RED}Failed to create symbolic link for .bashrc${RC}"
        exit 1
    }
    mkdir -p "$HOME/.config"
    ln -svf "$HOME/.config/starship.toml" "$HOME/.config/starship.toml" || {
        printf "%b\n" "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
    printf "%b\n" "${GREEN}Done! restart your shell to see the changes.${RC}"
}

# --- Download and replace configs ---
BASE_URL="https://raw.githubusercontent.com/Jaredy899/linux/main/config_changes"

replaceConfigs() {
    printf "%b\n" "${YELLOW}Downloading and replacing configurations...${RC}"

    mkdir -p "$MYBASH_DIR"
    mkdir -p "$HOME/.config/fastfetch"
    mkdir -p "$HOME/.config"

    if [ -f /etc/alpine-release ]; then
        "$ESCALATION_TOOL" curl -sSfL -o "/etc/profile" "$BASE_URL/profile"
    elif [ "$DTYPE" = "solus" ]; then
        curl -sSfL -o "$HOME/.profile" "$BASE_URL/.profile"
        curl -sSfL -o "$MYBASH_DIR/.bashrc" "$BASE_URL/.bashrc"
    else
        curl -sSfL -o "$MYBASH_DIR/.bashrc" "$BASE_URL/.bashrc"
    fi

    curl -sSfL -o "$HOME/.config/fastfetch/config.jsonc" "$BASE_URL/config.jsonc"
    curl -sSfL -o "$HOME/.config/starship.toml" "$BASE_URL/starship.toml"

    printf "%b\n" "${GREEN}Configurations downloaded and replaced successfully.${RC}"
}

# --- Main execution ---
checkEnv
checkEscalationTool
installDepend
installFont
installStarshipAndFzf
installZoxide
replaceConfigs
linkConfig