#!/bin/sh -e
# shellcheck disable=SC2086

. ../common-script.sh

config_dir="$HOME/.config"

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"

# Shell detection function
detectShell() {
    # Primary method: check $SHELL environment variable (most reliable)
    if [ -n "$SHELL" ]; then
        CURRENT_SHELL=$(basename "$SHELL")
        case "$CURRENT_SHELL" in
            zsh|bash|ksh|fish|ash|dash|busybox)
                echo "$CURRENT_SHELL"
                return
                ;;
        esac
    fi
    
    # Check for shell-specific environment variables
    for shell_var in ZSH_VERSION BASH_VERSION KSH_VERSION FISH_VERSION ASH_VERSION BB_ASH_VERSION; do
        if [ -n "$(eval echo \$$shell_var)" ]; then
            case "$shell_var" in
                ZSH_VERSION) echo "zsh" ;;
                BASH_VERSION) echo "bash" ;;
                KSH_VERSION) echo "ksh" ;;
                FISH_VERSION) echo "fish" ;;
                ASH_VERSION) echo "ash" ;;
                BB_ASH_VERSION) echo "busybox" ;;
            esac
            return
        fi
    done
    
    # Check /proc/$$/comm (Linux-specific but very reliable)
    if [ -f "/proc/$$/comm" ]; then
        CURRENT_SHELL=$(cat /proc/$$/comm 2>/dev/null)
        case "$CURRENT_SHELL" in
            zsh|bash|ksh|fish|ash|dash|busybox)
                echo "$CURRENT_SHELL"
                return
                ;;
        esac
    fi
    
    # Check the actual running shell process
    if command_exists ps; then
        CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null | sed 's/^-//' | head -1)
        case "$CURRENT_SHELL" in
            zsh|bash|ksh|fish|ash|dash|busybox)
                echo "$CURRENT_SHELL"
                return
                ;;
        esac
    fi
    
    # Final fallback: check what shells are available
    for shell in zsh bash fish; do
        if command_exists "$shell"; then
            echo "$shell"
            return
        fi
    done
    echo "sh"
}

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    
    # Base packages needed for all configurations
    BASE_PACKAGES="tar bat tree unzip fontconfig git fastfetch fzf"
    
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
    printf "%b\n" "${GREEN}1) Use detected shell ($CURRENT_SHELL) ${YELLOW}(recommended)${RC}"
    printf "%b\n" "${CYAN}2) bash (recommended for most systems)${RC}"
    printf "%b\n" "${CYAN}3) zsh (recommended for macOS/advanced users)${RC}"
    printf "%b\n" "${CYAN}4) Skip shell configuration${RC}"
    
    printf "Enter your choice (1-4) [1]: "
    read -r USER_CHOICE
    USER_CHOICE=${USER_CHOICE:-1}
    
    case "$USER_CHOICE" in
        1) SHELL_CHOICE="auto" ;;
        2) SHELL_CHOICE="bash" ;;
        3) SHELL_CHOICE="zsh" ;;
        4) SHELL_CHOICE="skip" ;;
        *) SHELL_CHOICE="skip" ;;
    esac
}


symlinkConfigs() {
    printf "%b\n" "${YELLOW}Symlinking configuration files...${RC}"
    
    # Create necessary directories
    mkdir -p "$config_dir" "$config_dir/fastfetch" "$config_dir/mise"
    
    # Symlink starship config
    if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
        if [ -L "$config_dir/starship.toml" ] || [ -f "$config_dir/starship.toml" ]; then
            rm -f "$config_dir/starship.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/starship.toml" "$config_dir/starship.toml"
        printf "%b\n" "${GREEN}Symlinked starship.toml from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}starship.toml not found in dotfiles repo, skipping...${RC}"
    fi
    
    # Symlink fastfetch config based on platform
    case "$DTYPE" in
        linux)
            FASTFETCH_CONFIG="$DOTFILES_DIR/config/fastfetch/linux.jsonc"
            ;;
        darwin)
            FASTFETCH_CONFIG="$DOTFILES_DIR/config/fastfetch/macos.jsonc"
            ;;
        freebsd)
            FASTFETCH_CONFIG="$DOTFILES_DIR/config/fastfetch/linux.jsonc"
            ;;
        *)
            FASTFETCH_CONFIG="$DOTFILES_DIR/config/fastfetch/linux.jsonc"
            ;;
    esac
    
    if [ -f "$FASTFETCH_CONFIG" ]; then
        if [ -L "$config_dir/fastfetch/config.jsonc" ] || [ -f "$config_dir/fastfetch/config.jsonc" ]; then
            rm -f "$config_dir/fastfetch/config.jsonc"
        fi
        ln -sf "$FASTFETCH_CONFIG" "$config_dir/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Symlinked fastfetch config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}fastfetch config not found in dotfiles repo, skipping...${RC}"
    fi
    
    # Symlink mise config
    if [ -f "$DOTFILES_DIR/config/mise/config.toml" ]; then
        if [ -L "$config_dir/mise/config.toml" ] || [ -f "$config_dir/mise/config.toml" ]; then
            rm -f "$config_dir/mise/config.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/mise/config.toml" "$config_dir/mise/config.toml"
        printf "%b\n" "${GREEN}Symlinked mise config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}mise config not found in dotfiles repo, skipping...${RC}"
    fi
    
    # Handle shell-specific configs based on user choice
    case "$SHELL_CHOICE" in
        bash)
            printf "%b\n" "${YELLOW}Setting up bash configuration...${RC}"
            if [ -f "$DOTFILES_DIR/bash/.bashrc" ]; then
                if [ -L "$HOME/.bashrc" ] || [ -f "$HOME/.bashrc" ]; then
                    rm -f "$HOME/.bashrc"
                fi
                ln -sf "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
                printf "%b\n" "${GREEN}Symlinked .bashrc from dotfiles${RC}"
            else
                printf "%b\n" "${YELLOW}.bashrc not found in dotfiles repo, skipping...${RC}"
            fi
            ;;
        zsh)
            printf "%b\n" "${YELLOW}Setting up zsh configuration...${RC}"
            
            if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
                if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
                    rm -f "$HOME/.zshrc"
                fi
                ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
                printf "%b\n" "${GREEN}Symlinked .zshrc from dotfiles${RC}"
            else
                printf "%b\n" "${YELLOW}.zshrc not found in dotfiles repo, skipping...${RC}"
            fi
            ;;
        auto)
            case "$(detectShell)" in
                zsh)
                    printf "%b\n" "${YELLOW}Setting up zsh configuration (detected)...${RC}"
                    
                    if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
                        if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
                            rm -f "$HOME/.zshrc"
                        fi
                        ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
                        printf "%b\n" "${GREEN}Symlinked .zshrc from dotfiles${RC}"
                    else
                        printf "%b\n" "${YELLOW}.zshrc not found in dotfiles repo, skipping...${RC}"
                    fi
                    ;;
                bash)
                    printf "%b\n" "${YELLOW}Setting up bash configuration (detected)...${RC}"
                    if [ -f "$DOTFILES_DIR/bash/.bashrc" ]; then
                        if [ -L "$HOME/.bashrc" ] || [ -f "$HOME/.bashrc" ]; then
                            rm -f "$HOME/.bashrc"
                        fi
                        ln -sf "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
                        printf "%b\n" "${GREEN}Symlinked .bashrc from dotfiles${RC}"
                    else
                        printf "%b\n" "${YELLOW}.bashrc not found in dotfiles repo, skipping...${RC}"
                    fi
                    ;;
                *)
                    printf "%b\n" "${YELLOW}Setting up bash configuration (fallback for $(detectShell))...${RC}"
                    if [ -f "$DOTFILES_DIR/bash/.bashrc" ]; then
                        if [ -L "$HOME/.bashrc" ] || [ -f "$HOME/.bashrc" ]; then
                            rm -f "$HOME/.bashrc"
                        fi
                        ln -sf "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
                        printf "%b\n" "${GREEN}Symlinked .bashrc from dotfiles${RC}"
                    else
                        printf "%b\n" "${YELLOW}.bashrc not found in dotfiles repo, skipping...${RC}"
                    fi
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
    
    # Handle sh profile for Alpine/BusyBox systems
    if grep -qi alpine /etc/os-release 2>/dev/null || [ "$(detectShell)" = "busybox" ] || [ "$(detectShell)" = "ash" ]; then
        if [ -f "$DOTFILES_DIR/sh/.profile" ]; then
            if [ -L "$HOME/.profile" ] || [ -f "$HOME/.profile" ]; then
                rm -f "$HOME/.profile"
            fi
            ln -sf "$DOTFILES_DIR/sh/.profile" "$HOME/.profile"
            printf "%b\n" "${GREEN}Symlinked .profile for Alpine/BusyBox${RC}"
        else
            printf "%b\n" "${YELLOW}.profile not found in dotfiles repo, skipping...${RC}"
        fi
    fi
    
    # Handle Solus-specific case: .profile should source .bashrc
    if grep -qi solus /etc/os-release 2>/dev/null; then
        if [ -f "$HOME/.bashrc" ]; then
            # Create a .profile that sources .bashrc
            cat > "$HOME/.profile" << 'EOF'
# Solus-specific: Source .bashrc to avoid configuration duplication
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
EOF
            printf "%b\n" "${GREEN}Created .profile to source .bashrc for Solus${RC}"
        fi
    fi
    
    printf "%b\n" "${GREEN}All configuration files symlinked successfully!${RC}"
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

    # Handle apt systems separately since their fzf package is often outdated
    if [ "$PACKAGER" = "apt-get" ] || [ "$PACKAGER" = "nala" ]; then
        # Check if fzf is installed via apt and remove it
        if command_exists fzf && dpkg -l | grep -q "^ii.*fzf "; then
            printf "%b\n" "${YELLOW}Removing apt-installed fzf...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" remove -y fzf
        fi
        
        if ! command_exists fzf; then
            printf "%b\n" "${YELLOW}Installing fzf from GitHub (apt package is outdated)...${RC}"
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            cd ~/.fzf && ./install --all
            printf "%b\n" "${GREEN}Fzf installed successfully!${RC}"
        else
            printf "%b\n" "${GREEN}Fzf already installed${RC}"
        fi
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
    
    # Backup .profile for Solus if we're setting up bash
    if grep -qi solus /etc/os-release 2>/dev/null && [ "$SHELL_CHOICE" = "bash" ] || [ "$SHELL_CHOICE" = "auto" ] && [ "$(detectShell)" = "bash" ]; then
        if [ -e "$HOME/.profile" ] && [ ! -e "$HOME/.profile.bak" ]; then
            printf "%b\n" "${YELLOW}Backing up existing .profile to .profile.bak for Solus${RC}"
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
symlinkConfigs
installStarshipAndFzf
installZoxide
installMise