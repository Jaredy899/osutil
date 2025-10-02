#!/bin/sh -e

. ../../common-script.sh

installNeovim() {
    printf "%b\n" "${YELLOW}Installing Neovim with essential dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm neovim git fzf ripgrep fd tree-sitter gcc || true    
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y git ripgrep fd-find tree-sitter-cli gcc || true # fzf will be installed from git
            
            ARCH=$(uname -m)
            case "$ARCH" in
                x86_64)
                    NVIM_ARCH="x86_64"
                    ;;
                aarch64|arm64)
                    NVIM_ARCH="aarch64"
                    ;;
                armv7l)
                    printf "%b\n" "${RED}ARM32 (armv7l) is not supported by official Neovim releases.${RC}"
                    printf "%b\n" "${YELLOW}Please install Neovim from your package manager or build from source.${RC}"
                    printf "%b\n" "${CYAN}Installing from package manager as fallback...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" install -y neovim || true
                    return 0
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"
                    printf "%b\n" "${YELLOW}Please install Neovim from your package manager or build from source.${RC}"
                    printf "%b\n" "${CYAN}Installing from package manager as fallback...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" install -y neovim || true
                    return 0
                    ;;
            esac
            
            # Download and install latest Neovim release (>= 0.11.2)
            printf "%b\n" "${YELLOW}Downloading Neovim for $ARCH architecture...${RC}"
            curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
            "$ESCALATION_TOOL" rm -rf /opt/nvim
            "$ESCALATION_TOOL" tar -C /opt -xzf "nvim-linux-${NVIM_ARCH}.tar.gz"
            "$ESCALATION_TOOL" ln -sf "/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim
            rm -f "nvim-linux-${NVIM_ARCH}.tar.gz"
            
            # Install fzf from git (better version)
            if command_exists fzf && dpkg -l | grep -q "^ii.*fzf "; then
                printf "%b\n" "${YELLOW}Removing apt-installed fzf...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" remove -y fzf
            fi
            
            if ! command_exists fzf; then
                printf "%b\n" "${YELLOW}Installing fzf from git...${RC}"
                # Remove existing .fzf directory if it exists
                if [ -d "$HOME/.fzf" ]; then
                    rm -rf "$HOME/.fzf"
                fi
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                ~/.fzf/install --all
                printf "%b\n" "${GREEN}Fzf installed successfully!${RC}"
            else
                printf "%b\n" "${GREEN}Fzf already installed${RC}"
            fi
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim git fzf ripgrep fd-find tree-sitter-cli gcc || true
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim git fzf ripgrep fd tree-sitter gcc || true
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add neovim git fzf ripgrep fd tree-sitter gcc || true
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy neovim git fzf ripgrep fd tree-sitter gcc || true
            ;;
        pkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim git fzf ripgrep fd-find tree-sitter gcc || true
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim git fzf ripgrep fd tree-sitter gcc || true
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}


backupNeovimConfig() {
    printf "%b\n" "${YELLOW}Backing up existing configuration files...${RC}"
    if [ -d "$HOME/.config/nvim" ] && [ ! -d "$HOME/.config/nvim-backup" ]; then
        cp -r "$HOME/.config/nvim" "$HOME/.config/nvim-backup"
    fi
    rm -rf "$HOME/.config/nvim"
}

installLazyVim() {
    printf "%b\n" "${CYAN}Installing LazyVim starter template...${RC}"
    if ! git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"; then
        printf "%b\n" "${RED}Failed to clone LazyVim starter template. Please check your internet connection and try again.${RC}"
        exit 1
    fi
    
    # Remove the .git folder so it can be added to user's own repo later
    rm -rf "$HOME/.config/nvim/.git"
    
    printf "%b\n" "${GREEN}LazyVim setup completed successfully!${RC}"
    printf "%b\n" "${CYAN}You can now start Neovim with 'nvim' to begin using LazyVim.${RC}"
    printf "%b\n" "${YELLOW}Tip: Run ':LazyHealth' after starting Neovim to check if everything is working correctly.${RC}"
}


checkEnv
checkEscalationTool
installNeovim
backupNeovimConfig
installLazyVim
