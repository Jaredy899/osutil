#!/bin/sh -e

# Complete Linux Setup Script
# Combines multiple setup scripts into one comprehensive installation script

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LINUX_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common scripts
. "$LINUX_DIR/common-script.sh"

# Initialize environment
checkEnv

printf "%b\n" "${CYAN}========================================${RC}"
printf "%b\n" "${CYAN}Complete Linux Setup Script${RC}"
printf "%b\n" "${CYAN}========================================${RC}"
printf "%b\n" ""

# 1. Git Setup
printf "%b\n" "${CYAN}=== Step 1: Git Setup ===${RC}"
. "$SCRIPT_DIR/git-setup.sh"
printf "%b\n" ""

# 2. SSH Key Setup
printf "%b\n" "${CYAN}=== Step 2: SSH Key Setup ===${RC}"
. "$LINUX_DIR/utils/add-ssh-key.sh"
printf "%b\n" ""

# 3. Helix Setup
printf "%b\n" "${CYAN}=== Step 3: Helix Editor Setup ===${RC}"
. "$LINUX_DIR/applications-setup/developer-tools/helix.sh"
printf "%b\n" ""

# 4. Neovim Setup
printf "%b\n" "${CYAN}=== Step 4: Neovim Setup ===${RC}"
. "$LINUX_DIR/applications-setup/developer-tools/neovim.sh"
printf "%b\n" ""

# 5. Zellij Setup
printf "%b\n" "${CYAN}=== Step 5: Zellij Setup ===${RC}"
. "$LINUX_DIR/applications-setup/developer-tools/zellij.sh"
printf "%b\n" ""

# 6. Eza Setup
printf "%b\n" "${CYAN}=== Step 6: Eza Setup ===${RC}"
. "$LINUX_DIR/applications-setup/eza.sh"
printf "%b\n" ""

# 7. Package Finder Setup
printf "%b\n" "${CYAN}=== Step 7: Package Finder Setup ===${RC}"
. "$LINUX_DIR/applications-setup/package-finder.sh"
printf "%b\n" ""

# 8. Shell Setup
printf "%b\n" "${CYAN}=== Step 8: Shell Setup ===${RC}"
. "$LINUX_DIR/applications-setup/shell-setup.sh"
printf "%b\n" ""

# 9. Yazi Setup
printf "%b\n" "${CYAN}=== Step 9: Yazi Setup ===${RC}"
. "$LINUX_DIR/applications-setup/yazi.sh"
printf "%b\n" ""

printf "%b\n" "${GREEN}========================================${RC}"
printf "%b\n" "${GREEN}Complete Linux Setup Finished!${RC}"
printf "%b\n" "${GREEN}========================================${RC}"
