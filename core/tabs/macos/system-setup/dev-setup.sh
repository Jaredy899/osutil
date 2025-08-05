#!/bin/sh -e
# shellcheck disable=SC2086

. ../common-script.sh

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tree multitail tealdeer unzip cmake make jq fd ripgrep automake autoconf rustup python pipx'
    printf "%b\n" "${YELLOW}Installing development dependencies...${RC}"
    
    # Check if Homebrew is installed
    if ! command_exists "brew"; then
        printf "%b\n" "${RED}Homebrew is required but not installed. Please install it first.${RC}"
        printf "%b\n" "${YELLOW}Visit: https://brew.sh${RC}"
        exit 1
    fi
    
    # Update Homebrew
    printf "%b\n" "${CYAN}Updating Homebrew...${RC}"
    brew update
    
    # Install core development tools
    printf "%b\n" "${CYAN}Installing development tools...${RC}"
    brew install $DEPENDENCIES
    
    # Install mas (Mac App Store command line interface) if not already installed
    if ! command_exists "mas"; then
        printf "%b\n" "${CYAN}Installing mas (Mac App Store CLI)...${RC}"
        brew install mas
    else
        printf "%b\n" "${GREEN}mas is already installed.${RC}"
    fi
    
    # Check for Xcode installation and configure it
    if [ -d "/Applications/Xcode.app" ]; then
        printf "%b\n" "${GREEN}Xcode is installed.${RC}"
        
        # Switch to full Xcode installation
        printf "%b\n" "${CYAN}Configuring Xcode...${RC}"
        "$ESCALATION_TOOL" xcode-select --switch /Applications/Xcode.app/Contents/Developer
        
        # Verify the path
        XCODE_PATH=$(xcode-select --print-path)
        printf "%b\n" "${GREEN}Xcode path: ${XCODE_PATH}${RC}"
        
        # Accept Xcode license if needed
        printf "%b\n" "${CYAN}Accepting Xcode license...${RC}"
        "$ESCALATION_TOOL" xcodebuild -license accept
        
    else
        printf "%b\n" "${YELLOW}Xcode is not installed. Installing via Mac App Store...${RC}"
        printf "%b\n" "${CYAN}Installing Xcode (this may take a while)...${RC}"
        mas install 497799835
        
        # Wait for installation to complete and then configure
        printf "%b\n" "${CYAN}Waiting for Xcode installation to complete...${RC}"
        while [ ! -d "/Applications/Xcode.app" ]; do
            sleep 10
            printf "%b\n" "${YELLOW}Still waiting for Xcode installation...${RC}"
        done
        
        printf "%b\n" "${GREEN}Xcode installation completed!${RC}"
        
        # Switch to full Xcode installation
        printf "%b\n" "${CYAN}Configuring Xcode...${RC}"
        "$ESCALATION_TOOL" xcode-select --switch /Applications/Xcode.app/Contents/Developer
        
        # Verify the path
        XCODE_PATH=$(xcode-select --print-path)
        printf "%b\n" "${GREEN}Xcode path: ${XCODE_PATH}${RC}"
        
        # Accept Xcode license if needed
        printf "%b\n" "${CYAN}Accepting Xcode license...${RC}"
        "$ESCALATION_TOOL" xcodebuild -license accept
    fi
    
    printf "%b\n" "${GREEN}Development setup complete!${RC}"
}

checkEnv
installDepend
