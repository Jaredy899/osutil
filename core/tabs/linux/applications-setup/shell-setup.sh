#!/bin/sh -e
# shellcheck disable=SC2086

. ../common-script.sh

config_dir="$HOME/.config"

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"

# Shell detection function
detectShell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$KSH_VERSION" ]; then
        echo "ksh"
    elif [ -n "$FISH_VERSION" ]; then
        echo "fish"
    elif [ -n "$ASH_VERSION" ]; then
        echo "ash"
    elif [ -n "$BB_ASH_VERSION" ]; then
        echo "busybox"
    else
        # Fallback: check what shell is available
        if command_exists zsh; then
            echo "zsh"
        elif command_exists bash; then
            echo "bash"
        elif command_exists fish; then
            echo "fish"
        else
            echo "sh"
        fi
    fi
}

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    
    # Base packages needed for all configurations
    BASE_PACKAGES="tar bat tree unzip fontconfig git fastfetch stow"
    
    # Add shell-specific packages based on choice
    case "$SHELL_CHOICE" in
        bash)
            PACKAGES="$BASE_PACKAGES bash bash-completion"
            ;;
        zsh)
            PACKAGES="$BASE_PACKAGES zsh zsh-completions"
            ;;
        *)
            # For sh/skip/auto, just install base packages
            PACKAGES="$BASE_PACKAGES"
            ;;
    esac
    
    # Install packages based on package manager
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm $PACKAGES
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y $PACKAGES
            # Install fastfetch from GitHub for latest version if not available
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
            "$ESCALATION_TOOL" "$PACKAGER" add $PACKAGES
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy $PACKAGES
            ;;
        pkg)
            # Replace some package names for FreeBSD
            FREEBSD_PACKAGES=$(echo "$PACKAGES" | sed 's/tar/xtar/g')
            "$ESCALATION_TOOL" "$PACKAGER" install -y $FREEBSD_PACKAGES
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y $PACKAGES
            ;;
    esac
    
    # Show helpful message if zsh was installed
    if [ "$SHELL_CHOICE" = "zsh" ] && command_exists zsh; then
        printf "%b\n" "${GREEN}Zsh installed successfully!${RC}"
        printf "%b\n" "${YELLOW}To make zsh your default shell, run: chsh -s $(which zsh)${RC}"
    fi
}

cloneDotfiles() {
    printf "%b\n" "${YELLOW}Setting up dotfiles repository...${RC}"

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

getShellChoice() {
    # Detect current shell
    CURRENT_SHELL=$(detectShell)
    printf "%b\n" "${CYAN}Detected shell: $CURRENT_SHELL${RC}"
    
    # Ask user which shell config they want to use
    printf "%b\n" "${YELLOW}Which shell configuration would you like to install?${RC}"
    printf "%b\n" "${CYAN}1) bash (recommended for most systems)${RC}"
    printf "%b\n" "${CYAN}2) zsh (recommended for macOS/advanced users)${RC}"
    printf "%b\n" "${CYAN}3) Use detected shell ($CURRENT_SHELL)${RC}"
    printf "%b\n" "${CYAN}4) Skip shell configuration${RC}"
    
    printf "Enter your choice (1-4) [3]: "
    read -r USER_CHOICE
    USER_CHOICE=${USER_CHOICE:-3}
    
    case "$USER_CHOICE" in
        1) SHELL_CHOICE="bash" ;;
        2) SHELL_CHOICE="zsh" ;;
        3) SHELL_CHOICE="auto" ;;
        4) SHELL_CHOICE="skip" ;;
        *) SHELL_CHOICE="skip" ;;
    esac
}

stowConfigs() {
    printf "%b\n" "${YELLOW}Stowing configs with GNU Stow...${RC}"
    
    # Change to dotfiles directory
    cd "$DOTFILES_DIR"
    
    # Always stow config package
    stow config
    
    # Stow sh profile only on Alpine/BusyBox systems
    if grep -qi alpine /etc/os-release 2>/dev/null || [ "$(detectShell)" = "busybox" ] || [ "$(detectShell)" = "ash" ]; then
        printf "%b\n" "${YELLOW}Stowing sh profile (Alpine/BusyBox detected)...${RC}"
        stow sh
    fi
    
    # Stow shell-specific configs based on user choice
    case "$SHELL_CHOICE" in
        bash)
            printf "%b\n" "${YELLOW}Stowing bash configuration...${RC}"
            stow bash
            ;;
        zsh)
            printf "%b\n" "${YELLOW}Stowing zsh configuration...${RC}"
            stow zsh
            # Handle zsh-specific setup
            setupZshEnv
            ;;
        auto)
            case "$(detectShell)" in
                zsh)
                    printf "%b\n" "${YELLOW}Stowing zsh configuration (detected)...${RC}"
                    stow zsh
                    setupZshEnv
                    ;;
                bash)
                    printf "%b\n" "${YELLOW}Stowing bash configuration (detected)...${RC}"
                    stow bash
                    ;;
                *)
                    printf "%b\n" "${YELLOW}Stowing bash configuration (fallback for $(detectShell))...${RC}"
                    stow bash
                    ;;
            esac
            ;;
        skip)
            printf "%b\n" "${YELLOW}Skipping shell configuration...${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Invalid shell choice: $SHELL_CHOICE. Skipping shell configuration...${RC}"
            ;;
    esac
    
    # Handle platform-specific fastfetch config
    printf "%b\n" "${YELLOW}Setting up platform-specific configs...${RC}"
    
    # Create fastfetch config directory if it doesn't exist
    mkdir -p "$config_dir/fastfetch"
    
    case "$DTYPE" in
        linux)
            ln -sf "$DOTFILES_DIR/config/.config/fastfetch/linux.jsonc" "$config_dir/fastfetch/config.jsonc"
            printf "%b\n" "${GREEN}Symlinked Linux fastfetch config${RC}"
            ;;
        darwin)
            ln -sf "$DOTFILES_DIR/config/.config/fastfetch/macos.jsonc" "$config_dir/fastfetch/config.jsonc"
            printf "%b\n" "${GREEN}Symlinked macOS fastfetch config${RC}"
            ;;
        freebsd)
            ln -sf "$DOTFILES_DIR/config/.config/fastfetch/linux.jsonc" "$config_dir/fastfetch/config.jsonc"
            printf "%b\n" "${GREEN}Symlinked Linux fastfetch config (FreeBSD fallback)${RC}"
            ;;
        *)
            ln -sf "$DOTFILES_DIR/config/.config/fastfetch/linux.jsonc" "$config_dir/fastfetch/config.jsonc"
            printf "%b\n" "${GREEN}Symlinked Linux fastfetch config (default)${RC}"
            ;;
    esac
    
    printf "%b\n" "${GREEN}All configs stowed successfully!${RC}"
}

setupZshEnv() {
    # Ensure /etc/zsh/zshenv sets ZDOTDIR to the user's config directory
    [ ! -f /etc/zsh/zshenv ] && "$ESCALATION_TOOL" mkdir -p /etc/zsh && "$ESCALATION_TOOL" touch /etc/zsh/zshenv
    grep -q "ZDOTDIR" /etc/zsh/zshenv 2>/dev/null || \
        echo "export ZDOTDIR=\"$HOME/.config/zsh\"" | "$ESCALATION_TOOL" tee -a /etc/zsh/zshenv

    # Handle Alpine and Solus special cases for /etc/profile and .profile
    if [ -f /etc/alpine-release ] && [ -f "$DOTFILES_DIR/config/profile" ]; then
        "$ESCALATION_TOOL" ln -sf "$DOTFILES_DIR/config/profile" "/etc/profile"
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

    # Check if fzf is installed via apt and remove it
    if command_exists fzf && dpkg -l | grep -q "^ii.*fzf "; then
        printf "%b\n" "${YELLOW}Removing apt-installed fzf...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" remove -y fzf
    fi
    
    if ! command_exists fzf; then
        printf "%b\n" "${YELLOW}Installing fzf...${RC}"
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        printf "%b\n" "${GREEN}Fzf installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Fzf already installed${RC}"
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

installMise() {
    # Skip mise installation on FreeBSD
    if [ "$DTYPE" = "freebsd" ]; then
        printf "%b\n" "${YELLOW}Skipping mise installation on FreeBSD (use pkg instead)${RC}"
        return
    fi

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
    printf "%b\n" "${YELLOW}Backing up existing configurations...${RC}"
    
    # Backup shell configs based on what we're about to install
    case "$SHELL_CHOICE" in
        bash)
            if [ -e "$HOME/.bashrc" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
                printf "%b\n" "${YELLOW}Backing up existing .bashrc to .bashrc.bak${RC}"
                mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
            fi
            ;;
        zsh)
            if [ -e "$HOME/.zshrc" ] && [ ! -e "$HOME/.zshrc.bak" ]; then
                printf "%b\n" "${YELLOW}Backing up existing .zshrc to .zshrc.bak${RC}"
                mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
            fi
            ;;
        auto)
            # Backup based on detected shell
            CURRENT_SHELL=$(detectShell)
            case "$CURRENT_SHELL" in
                bash)
                    if [ -e "$HOME/.bashrc" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
                        printf "%b\n" "${YELLOW}Backing up existing .bashrc to .bashrc.bak${RC}"
                        mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
                    fi
                    ;;
                zsh)
                    if [ -e "$HOME/.zshrc" ] && [ ! -e "$HOME/.zshrc.bak" ]; then
                        printf "%b\n" "${YELLOW}Backing up existing .zshrc to .zshrc.bak${RC}"
                        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
                    fi
                    ;;
            esac
            ;;
    esac
    
    # Backup sh profile if we're on Alpine/BusyBox
    if grep -qi alpine /etc/os-release 2>/dev/null || [ "$(detectShell)" = "busybox" ] || [ "$(detectShell)" = "ash" ]; then
        if [ -e "$HOME/.profile" ] && [ ! -e "$HOME/.profile.bak" ]; then
            printf "%b\n" "${YELLOW}Backing up existing .profile to .profile.bak${RC}"
            mv "$HOME/.profile" "$HOME/.profile.bak"
        fi
    fi
    
    # Backup config files
    if [ -e "$config_dir/starship.toml" ] && [ ! -e "$config_dir/starship.toml.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing starship.toml to starship.toml.bak${RC}"
        mv "$config_dir/starship.toml" "$config_dir/starship.toml.bak"
    fi
    
    if [ -e "$config_dir/mise/config.toml" ] && [ ! -e "$config_dir/mise/config.toml.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing mise config to config.toml.bak${RC}"
        mv "$config_dir/mise/config.toml" "$config_dir/mise/config.toml.bak"
    fi
    
    if [ -e "$config_dir/fastfetch/config.jsonc" ] && [ ! -e "$config_dir/fastfetch/config.jsonc.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing fastfetch config to config.jsonc.bak${RC}"
        mv "$config_dir/fastfetch/config.jsonc" "$config_dir/fastfetch/config.jsonc.bak"
    fi
    
    printf "%b\n" "${GREEN}Backup completed!${RC}"
}

# Main execution
checkEnv
checkEscalationTool
getShellChoice
cloneDotfiles
backupExistingConfigs
installDependencies
stowConfigs
installStarshipAndFzf
installZoxide
installMise

printf "%b\n" "${GREEN}✅ Shell configuration installed with Stow! Restart your shell to see changes.${RC}"
