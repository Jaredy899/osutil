#!/bin/sh -e

. ../common-script.sh

# Function to configure trackpad settings
configureTrackpad() {
    printf "%b\n" "${YELLOW}Configuring trackpad settings...${RC}"
    
    if ! $ESCALATION_TOOL defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true; then
        printf "%b\n" "${RED}Failed to configure trackpad settings. Please check your system or try again later.${RC}"
        exit 1
    fi
    if ! $ESCALATION_TOOL defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true; then
        printf "%b\n" "${RED}Failed to configure trackpad settings. Please check your system or try again later.${RC}"
        exit 1
    fi
    if ! $ESCALATION_TOOL defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false; then
        printf "%b\n" "${RED}Failed to configure trackpad settings. Please check your system or try again later.${RC}"
        exit 1
    fi
    if ! $ESCALATION_TOOL defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true; then
        printf "%b\n" "${RED}Failed to configure trackpad settings. Please check your system or try again later.${RC}"
        exit 1
    fi
    if ! $ESCALATION_TOOL defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1; then
        printf "%b\n" "${RED}Failed to configure trackpad settings. Please check your system or try again later.${RC}"
        exit 1
    fi
    if ! $ESCALATION_TOOL defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 1; then
        printf "%b\n" "${RED}Failed to configure trackpad settings. Please check your system or try again later.${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Trackpad settings updated successfully${RC}"
}

checkEnv
configureTrackpad