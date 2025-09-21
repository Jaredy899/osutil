#!/bin/sh -e

. ../common-script.sh

config_dir="$HOME/.config"

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/.local/share/dotfiles"

installDepend() {
    if [ ! -f "/usr/share/bash-completion/bash_completion" ] || ! command_exists bash tar bat tree unzip fc-list git fastfetch; then
        printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm bash bash-completion tar bat tree unzip fontconfig git fastfetch
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig git
                # Install fastfetch from GitHub for latest version
                if ! command_exists fastfetch; then
                    printf "%b\n" "${YELLOW}Installing Fastfetch from GitHub...${RC}"
                    case "$ARCH" in
                        x86_64)
                            DEB_FILE="fastfetch-linux-amd64.deb"
                            ;;
                        aarch64)
                            DEB_FILE="fastfetch-linux-aarch64.deb"
                            ;;
                        *)
                            printf "%b\n" "${RED}Unsupported architecture for deb install: $ARCH${RC}"
                            exit 1
                            ;;
                    esac
                    curl -sSLo "/tmp/fastfetch.deb" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/$DEB_FILE"
                    "$ESCALATION_TOOL" "$PACKAGER" install -y /tmp/fastfetch.deb
                    rm /tmp/fastfetch.deb
                fi
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add bash bash-completion tar bat tree unzip fontconfig git fastfetch
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy bash bash-completion tar bat tree unzip fontconfig git fastfetch
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig git fastfetch
                ;;
        esac
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

downloadConfigs() {
    printf "%b\n" "${YELLOW}Symlinking your custom config files from dotfiles...${RC}"

    # Create config directory if it doesn't exist
    mkdir -p "$config_dir" "$config_dir/fastfetch" "$config_dir/mise"

    # Symlink .bashrc from dotfiles repo
    if [ -f "$DOTFILES_DIR/bash/.bashrc" ]; then
        if [ -L "$HOME/.bashrc" ] || [ -f "$HOME/.bashrc" ]; then
            rm -f "$HOME/.bashrc"
        fi
        ln -sf "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
        printf "%b\n" "${GREEN}Symlinked .bashrc from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}.bashrc not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink starship.toml from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
        if [ -L "$config_dir/starship.toml" ] || [ -f "$config_dir/starship.toml" ]; then
            rm -f "$config_dir/starship.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/starship.toml" "$config_dir/starship.toml"
        printf "%b\n" "${GREEN}Symlinked starship.toml from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}starship.toml not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink config.jsonc from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/fastfetch/linux.jsonc" ]; then
        if [ -L "$config_dir/fastfetch/config.jsonc" ] || [ -f "$config_dir/fastfetch/config.jsonc" ]; then
            rm -f "$config_dir/fastfetch/config.jsonc"
        fi
        ln -sf "$DOTFILES_DIR/config/fastfetch/linux.jsonc" "$config_dir/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Symlinked config.jsonc from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}config.jsonc not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink mise config from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/mise/config.toml" ]; then
        if [ -L "$config_dir/mise/config.toml" ] || [ -f "$config_dir/mise/config.toml" ]; then
            rm -f "$config_dir/mise/config.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/mise/config.toml" "$config_dir/mise/config.toml"
        printf "%b\n" "${GREEN}Symlinked mise config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}mise config not found in dotfiles repo, skipping...${RC}"
    fi

    printf "%b\n" "${GREEN}All available config files symlinked successfully!${RC}"
}

installFont() {
    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "%b\n" "${GREEN}Font '$FONT_NAME' is installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing font '$FONT_NAME'${RC}"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
        unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR"/"$FONT_NAME"
        mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
        fc-cache -fv
        rm -rf "${TEMP_DIR}"
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
        # Check if installed fzf version is before 0.48.0
        FZF_VERSION=$(fzf --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$FZF_VERSION" ]; then
            # Compare version with 0.48.0
            if [ "$(printf '%s\n' "0.48.0" "$FZF_VERSION" | sort -V | head -1)" = "0.48.0" ]; then
                printf "%b\n" "${GREEN}Fzf already installed (version $FZF_VERSION)${RC}"
            else
                printf "%b\n" "${YELLOW}Fzf version $FZF_VERSION is older than 0.48.0, updating...${RC}"
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                ~/.fzf/install --all
            fi
        else
            printf "%b\n" "${GREEN}Fzf already installed${RC}"
        fi
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "%b\n" "${GREEN}Zoxide already installed${RC}"
        return
    fi

    if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}Zoxide installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please restart your shell to see the changes.${RC}"
    fi
}

installMise() {
    if command_exists mise; then
        printf "%b\n" "${GREEN}Mise already installed${RC}"
        return
    fi

    if ! curl -sSL https://mise.run | sh; then
        printf "%b\n" "${RED}Something went wrong during mise install!${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}Mise installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please restart your shell to see the changes.${RC}"
    fi
}

backupExistingConfigs() {
    OLD_BASHRC="$HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
        printf "%b\n" "${YELLOW}Moving old bash config file to $HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$HOME/.bashrc.bak"; then
            printf "%b\n" "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi
    
    # Backup existing starship config if it exists
    if [ -e "$config_dir/starship.toml" ] && [ ! -e "$config_dir/starship.toml.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing starship.toml to $config_dir/starship.toml.bak${RC}"
        mv "$config_dir/starship.toml" "$config_dir/starship.toml.bak"
    fi
    
    # Backup existing config.jsonc if it exists
    if [ -e "$config_dir/fastfetch/config.jsonc" ] && [ ! -e "$config_dir/fastfetch/config.jsonc.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing config.jsonc to $config_dir/fastfetch/config.jsonc.bak${RC}"
        mv "$config_dir/fastfetch/config.jsonc" "$config_dir/fastfetch/config.jsonc.bak"
    fi
}

checkEnv
checkEscalationTool
installDepend
cloneDotfiles
backupExistingConfigs
downloadConfigs
installFont
installStarshipAndFzf
installZoxide
installMise