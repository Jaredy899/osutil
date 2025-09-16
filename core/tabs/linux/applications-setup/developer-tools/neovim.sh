#!/bin/sh -e

. ../../common-script.sh

installNeovim() {
    if ! command_exists neovim ripgrep git fzf; then
    printf "%b\n" "${YELLOW}Installing Neovim with LazyVim...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm neovim ripgrep fzf python-virtualenv luarocks go shellcheck git
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y ripgrep fd-find fzf python3-venv luarocks golang-go shellcheck git curl
            # Download and install latest Neovim release
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
            "$ESCALATION_TOOL" rm -rf /opt/nvim
            "$ESCALATION_TOOL" tar -C /opt -xzf nvim-linux-x86_64.tar.gz
            "$ESCALATION_TOOL" ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
            rm -f nvim-linux-x86_64.tar.gz
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim ripgrep fzf python3-virtualenv luarocks golang ShellCheck git
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim ripgrep fzf python3-virtualenv lua53-luarocks golang ShellCheck git
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add neovim ripgrep fzf py3-virtualenv luarocks go shellcheck git
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy neovim ripgrep fzf python3-virtualenv luarocks go shellcheck git
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y neovim ripgrep fzf virtualenv luarocks golang shellcheck git
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
    fi
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
