#!/bin/sh

. ../common-script.sh

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/.local/share/dotfiles"

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

 

cloneDotfiles() {
    printf "%b\n" "${YELLOW}Cloning dotfiles repository...${RC}"

    # Ensure the parent directory exists
    mkdir -p "$HOME/.local/share"

    if [ -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${CYAN}Dotfiles directory already exists. Pulling latest changes...${RC}"
        if ! (cd "$DOTFILES_DIR" && git pull); then
            printf "%b\n" "${RED}Failed to update dotfiles repository${RC}"
            exit 1
        fi
    else
        if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            printf "%b\n" "${RED}Failed to clone dotfiles repository${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${GREEN}Dotfiles repository ready!${RC}"
}

setupAndReplaceConfigs() {
    printf "%b\n" "${YELLOW}Setting up Zsh and symlinking configurations...${RC}"

    # Create necessary directories
    mkdir -p "$HOME/.config/zsh"
    mkdir -p "$HOME/.config/fastfetch"
    mkdir -p "$HOME/.config"

    # Symlink .zshrc from dotfiles repo
    if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
        if [ -L "$HOME/.config/zsh/.zshrc" ] || [ -f "$HOME/.config/zsh/.zshrc" ]; then
            rm -f "$HOME/.config/zsh/.zshrc"
        fi
        ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
        printf "%b\n" "${GREEN}Symlinked .zshrc from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}.zshrc not found in dotfiles repo, skipping...${RC}"
    fi

    # Ensure /etc/zsh/zshenv sets ZDOTDIR to the user's config directory
    [ ! -f /etc/zsh/zshenv ] && "$ESCALATION_TOOL" mkdir -p /etc/zsh && "$ESCALATION_TOOL" touch /etc/zsh/zshenv
    grep -q "ZDOTDIR" /etc/zsh/zshenv 2>/dev/null || \
        echo "export ZDOTDIR=\"$HOME/.config/zsh\"" | "$ESCALATION_TOOL" tee -a /etc/zsh/zshenv

    # Handle Alpine and Solus special cases for /etc/profile and .profile
    if [ -f /etc/alpine-release ] && [ -f "$DOTFILES_DIR/config/profile" ]; then
        "$ESCALATION_TOOL" ln -sf "$DOTFILES_DIR/config/profile" "/etc/profile"
    fi

    # Symlink fastfetch and starship configs from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/fastfetch/config.jsonc" ]; then
        if [ -L "$HOME/.config/fastfetch/config.jsonc" ] || [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$HOME/.config/fastfetch/config.jsonc"
        fi
        ln -sf "$DOTFILES_DIR/config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Symlinked fastfetch config from dotfiles${RC}"
    fi

    if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
        if [ -L "$HOME/.config/starship.toml" ] || [ -f "$HOME/.config/starship.toml" ]; then
            rm -f "$HOME/.config/starship.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
        printf "%b\n" "${GREEN}Symlinked starship config from dotfiles${RC}"
    fi

    printf "%b\n" "${GREEN}Zsh and other configurations set up successfully.${RC}"
}

checkEnv
checkEscalationTool
installZsh
installFont
installStarshipAndFzf
installZoxide
cloneDotfiles
setupAndReplaceConfigs