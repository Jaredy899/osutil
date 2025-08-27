#!/bin/sh -e

. ../common-script.sh

updateHomebrew() {
    printf "%b\n" "${YELLOW}Updating Homebrew packages...${RC}"
    
    # Update Homebrew itself
    printf "%b\n" "${CYAN}Updating Homebrew...${RC}"
    brew update
    
    # Upgrade all installed formulae
    printf "%b\n" "${CYAN}Upgrading installed formulae...${RC}"
    brew upgrade
    
    # Clean up old versions and cache
    printf "%b\n" "${CYAN}Cleaning up old versions and cache...${RC}"
    brew cleanup
    brew autoremove
}

updateMacAppStore() {
    if command_exists "mas"; then
        printf "%b\n" "${YELLOW}Updating Mac App Store applications...${RC}"
        mas upgrade
    else
        printf "%b\n" "${YELLOW}Installing mas-cli for Mac App Store updates...${RC}"
        if brew install mas; then
            printf "%b\n" "${CYAN}Updating Mac App Store applications...${RC}"
            mas upgrade
        else
            printf "%b\n" "${RED}Failed to install mas-cli. Skipping Mac App Store updates.${RC}"
        fi
    fi

    printf "%b\n" "${GREEN}Mac App Store applications updated!${RC}"
}

updateCasks() {
    printf "%b\n" "${YELLOW}Updating Homebrew Casks...${RC}"
    
    # Get list of outdated casks (including :latest and auto_updates)
    outdated_casks=$(brew outdated --cask --greedy 2>/dev/null)
    
    if [ -n "$outdated_casks" ]; then
        printf "%b\n" "${CYAN}Outdated casks found:${RC}\n$outdated_casks\n"
        
        # Try upgrading all casks
        if ! brew upgrade --cask --greedy; then
            printf "%b\n" "${RED}Some casks failed to upgrade. Attempting force reinstall...${RC}"
            
            # Extract cask names and force reinstall
            for cask in $(echo "$outdated_casks" | awk '{print $1}'); do
                printf "%b\n" "${CYAN}Reinstalling $cask...${RC}"
                brew uninstall --cask --force "$cask" || true
                brew install --cask "$cask" || true
            done
        fi
    else
        printf "%b\n" "${GREEN}No outdated casks found.${RC}"
    fi
    
    # Final cleanup
    printf "%b\n" "${CYAN}Cleaning up old cask versions...${RC}"
    brew cleanup --prune=all

}

checkEnv
updateHomebrew
updateCasks
updateMacAppStore