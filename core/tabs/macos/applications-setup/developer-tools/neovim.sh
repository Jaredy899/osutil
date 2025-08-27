#!/bin/sh -e

. ../../common-script.sh

installNeovim() {
    printf "%b\n" "${YELLOW}Setting up Neovim with LazyVim...${RC}"
    
    # Install Neovim and dependencies with brew
    printf "%b\n" "${CYAN}Installing Neovim and dependencies...${RC}"
    if ! brew install neovim ripgrep fzf; then
        printf "%b\n" "${RED}Failed to install Neovim and dependencies. Please check your Homebrew installation or try again later.${RC}"
        exit 1
    fi
    
    # Backup existing config if it exists
    if [ -d "$HOME/.config/nvim" ] && [ ! -d "$HOME/.config/nvim-backup" ]; then
        printf "%b\n" "${YELLOW}Backing up existing Neovim config...${RC}"
        cp -r "$HOME/.config/nvim" "$HOME/.config/nvim-backup"
    fi
    
    # Clear existing config
    rm -rf "$HOME/.config/nvim"
    
    # Clone LazyVim starter template
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
installNeovim