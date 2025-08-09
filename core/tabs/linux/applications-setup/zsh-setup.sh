#!/bin/sh

. ../common-script.sh

# Centralized base URL for configuration files
CONFIG_BASE_URL="${CONFIG_BASE_URL:-https://raw.githubusercontent.com/Jaredy899/linux/refs/heads/main/config_changes}"

# Function to install zsh
installZsh() {
    if ! command_exists zsh; then
        printf "%b\n" "${YELLOW}Installing Zsh...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm zsh
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add zsh
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy zsh
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y zsh
                ;;
        esac
    else
        printf "%b\n" "${GREEN}ZSH is already installed.${RC}"
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
        return
    fi

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

 

setupAndReplaceConfigs() {
    printf "%b\n" "${YELLOW}Setting up Zsh and downloading configurations...${RC}"

    # Create necessary directories
    mkdir -p "$HOME/.config/zsh"
    mkdir -p "$HOME/.config/fastfetch"
    mkdir -p "$HOME/.config"

    # Download .zshrc from config_changes
    curl -fsSL "$CONFIG_BASE_URL/.zshrc" -o "$HOME/.config/zsh/.zshrc"

    # Ensure /etc/zsh/zshenv sets ZDOTDIR to the user's config directory
    [ ! -f /etc/zsh/zshenv ] && "$ESCALATION_TOOL" mkdir -p /etc/zsh && "$ESCALATION_TOOL" touch /etc/zsh/zshenv
    grep -q "ZDOTDIR" /etc/zsh/zshenv 2>/dev/null || \
        echo "export ZDOTDIR=\"$HOME/.config/zsh\"" | "$ESCALATION_TOOL" tee -a /etc/zsh/zshenv

    # Handle Alpine and Solus special cases for /etc/profile and .profile
    if [ -f /etc/alpine-release ]; then
        "$ESCALATION_TOOL" curl -sSfL -o "/etc/profile" "$CONFIG_BASE_URL/profile"
    fi

    # Download fastfetch and starship configs
    curl -sSfL -o "$HOME/.config/fastfetch/config.jsonc" "$CONFIG_BASE_URL/config.jsonc"
    curl -sSfL -o "$HOME/.config/starship.toml" "$CONFIG_BASE_URL/starship.toml"

    printf "%b\n" "${GREEN}Zsh and other configurations set up successfully.${RC}"
}

checkEnv
checkEscalationTool
installZsh
installFont
installStarshipAndFzf
installZoxide
setupAndReplaceConfigs