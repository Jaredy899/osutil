#!/bin/sh -e

# Complete macOS Setup Script
# Combines multiple setup scripts into one comprehensive installation script
# Skips eza and package-finder (not present in macos; shell setup handles core deps via zsh.sh)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MACOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common scripts
. "$MACOS_DIR/common-script.sh"

# Helper function to source scripts from their own directory
# This ensures relative paths in sourced scripts work correctly
# Returns 0 on success, 1 on failure, but doesn't exit the script
source_script() {
    local script_path="$1"
    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    local script_name="$(basename "$script_path")"
    local old_pwd="$PWD"

    # Temporarily disable exit on error for sourced scripts
    set +e

    cd "$script_dir" || {
        set -e
        return 1
    }

    # Source the script (errors won't exit due to set +e)
    . "./$script_name"
    local result=$?

    cd "$old_pwd" || {
        set -e
        return 1
    }

    # Re-enable exit on error
    set -e

    return $result
}

# Initialize environment
checkEnv

printf "%b\n" "${CYAN}========================================${RC}"
printf "%b\n" "${CYAN}Complete macOS Setup Script${RC}"
printf "%b\n" "${CYAN}========================================${RC}"
printf "%b\n" ""

# 1. Git Setup
printf "%b\n" "${CYAN}=== Step 1: Git Setup ===${RC}"
if ! source_script "$SCRIPT_DIR/git-setup.sh"; then
    printf "%b\n" "${YELLOW}Git setup failed or skipped, continuing...${RC}"
fi
printf "%b\n" ""

# 2. SSH Setup
printf "%b\n" "${CYAN}=== Step 2: SSH Setup ===${RC}"
if ! source_script "$SCRIPT_DIR/ssh.sh"; then
    printf "%b\n" "${YELLOW}SSH setup failed or skipped, continuing...${RC}"
fi
printf "%b\n" ""

# 3. Helix Setup
printf "%b\n" "${CYAN}=== Step 3: Helix Editor Setup ===${RC}"
if ! source_script "$MACOS_DIR/applications-setup/developer-tools/helix.sh"; then
    printf "%b\n" "${YELLOW}Helix setup failed or skipped, continuing...${RC}"
fi
printf "%b\n" ""

# 4. Zellij Setup
printf "%b\n" "${CYAN}=== Step 4: Zellij Setup ===${RC}"
if ! source_script "$MACOS_DIR/applications-setup/developer-tools/zellij.sh"; then
    printf "%b\n" "${YELLOW}Zellij setup failed or skipped, continuing...${RC}"
fi
printf "%b\n" ""

# 5. Shell Setup (zsh, dotfiles, starship, etc. — eza/package-finder not in macos zsh.sh)
printf "%b\n" "${CYAN}=== Step 5: Shell Setup ===${RC}"
if ! source_script "$MACOS_DIR/applications-setup/zsh.sh"; then
    printf "%b\n" "${YELLOW}Shell setup failed or skipped, continuing...${RC}"
fi
printf "%b\n" ""

# 6. Yazi Setup
printf "%b\n" "${CYAN}=== Step 6: Yazi Setup ===${RC}"
if ! source_script "$MACOS_DIR/applications-setup/yazi.sh"; then
    printf "%b\n" "${YELLOW}Yazi setup failed or skipped, continuing...${RC}"
fi
printf "%b\n" ""
