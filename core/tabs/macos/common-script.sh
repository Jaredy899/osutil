#!/bin/sh -e

# shellcheck disable=SC2034

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

command_exists() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

brewprogram_exists() {
    for cmd in "$@"; do
        brew list "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

checkEscalationTool() {
    if [ "$(id -u)" = "0" ]; then
        ESCALATION_TOOL="eval"
        printf "%b\n" "${CYAN}Running as root, no escalation needed${RC}"
    elif command_exists "sudo"; then
        ESCALATION_TOOL="sudo"
        printf "%b\n" "${CYAN}Using sudo for privilege escalation${RC}"
    else
        printf "%b\n" "${RED}No escalation tool found${RC}"
        exit 1
    fi
}

checkPackageManager() {
    if command_exists "brew"; then
        printf "%b\n" "${GREEN}Homebrew is installed${RC}"
    else
        printf "%b\n" "${RED}Homebrew is not installed${RC}"
        printf "%b\n" "${YELLOW}Installing Homebrew...${RC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for current session
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            export PATH="/opt/homebrew/bin:$PATH"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
            export PATH="/usr/local/bin:$PATH"
        fi
        
        # Verify brew is now available
        if command_exists "brew"; then
            printf "%b\n" "${GREEN}Homebrew installed successfully!${RC}"
        else
            printf "%b\n" "${RED}Homebrew installed but not found in PATH${RC}"
            printf "%b\n" "${YELLOW}Please restart your terminal or run: eval \"\$(/opt/homebrew/bin/brew shellenv)\"${RC}"
            exit 1
        fi
    fi
}

ensureHomebrewAvailable() {
    # Ensure Homebrew is available in current session
    if ! command_exists "brew"; then
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            export PATH="/opt/homebrew/bin:$PATH"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
            export PATH="/usr/local/bin:$PATH"
        fi
    fi
}

checkEnv() {
    checkEscalationTool
    checkPackageManager
    ensureHomebrewAvailable
}