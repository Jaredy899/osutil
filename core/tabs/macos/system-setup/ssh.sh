#!/bin/sh -e

. ../common-script.sh

installSSHDepend() {
    printf "%b\n" "${YELLOW}Installing SSH dependencies...${RC}"

    if ! command_exists "brew"; then
        printf "%b\n" "${RED}Homebrew is required but not installed. Please install it first.${RC}"
        printf "%b\n" "${YELLOW}Visit: https://brew.sh${RC}"
        exit 1
    fi

    printf "%b\n" "${CYAN}Updating Homebrew...${RC}"
    brew update

    printf "%b\n" "${CYAN}Installing SSH tools...${RC}"
    brew install openssh curl

    printf "%b\n" "${GREEN}SSH dependencies installed!${RC}"
}

openFullDiskAccessPane() {
    printf "%b\n" "${YELLOW}Opening Full Disk Access settings...${RC}"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    printf "%b\n" "${YELLOW}Please add your terminal app to the list and restart it before continuing.${RC}"
}

enableSSH() {
    printf "%b\n" "${CYAN}Enabling SSH access...${RC}"
    if ! "$ESCALATION_TOOL" systemsetup -setremotelogin on 2>/dev/null; then
        printf "%b\n" "${RED}Failed to enable SSH. Full Disk Access is required.${RC}"
        openFullDiskAccessPane
        exit 1
    fi
    "$ESCALATION_TOOL" systemsetup -getremotelogin
    printf "%b\n" "${GREEN}SSH access enabled.${RC}"
}

configureSSHD() {
    printf "%b\n" "${CYAN}Configuring sshd...${RC}"
    # shellcheck disable=SC2016
    "$ESCALATION_TOOL" sh -c '
        SSHD_CONFIG="/etc/ssh/sshd_config"
        if [ -f "$SSHD_CONFIG" ]; then
            if grep -q "^PubkeyAuthentication" "$SSHD_CONFIG"; then
                sed -i "" "s/^PubkeyAuthentication.*/PubkeyAuthentication yes/" "$SSHD_CONFIG"
            else
                echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
            fi
            if grep -q "^AuthorizedKeysFile" "$SSHD_CONFIG"; then
                sed -i "" "s|^AuthorizedKeysFile.*|AuthorizedKeysFile .ssh/authorized_keys|" "$SSHD_CONFIG"
            else
                echo "AuthorizedKeysFile .ssh/authorized_keys" >> "$SSHD_CONFIG"
            fi
            echo "sshd_config updated for public key authentication."
            if command -v systemctl >/dev/null 2>&1; then
                systemctl restart sshd
            elif command -v service >/dev/null 2>&1; then
                service sshd restart
            else
                launchctl stop com.openssh.sshd
                launchctl start com.openssh.sshd
            fi
        else
            echo "SSH daemon config file not found at $SSHD_CONFIG"
            exit 1
        fi
    '
    printf "%b\n" "${GREEN}sshd configured.${RC}"
}

ensureSSHDir() {
    SSH_DIR="$HOME/.ssh"
    AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        printf "%b\n" "${GREEN}Created $SSH_DIR and set permissions to 700.${RC}"
    else
        printf "%b\n" "${YELLOW}$SSH_DIR already exists.${RC}"
    fi

    if [ ! -f "$AUTHORIZED_KEYS" ]; then
        touch "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
        printf "%b\n" "${GREEN}Created $AUTHORIZED_KEYS and set permissions to 600.${RC}"
    else
        printf "%b\n" "${YELLOW}$AUTHORIZED_KEYS already exists.${RC}"
    fi
}

importSSHKeys() {
    printf "%b" "${CYAN}Enter the GitHub username: ${RC}"
    read -r github_user

    ssh_keys_url="https://github.com/$github_user.keys"
    keys=$(curl -s "$ssh_keys_url")

    if [ -z "$keys" ]; then
        printf "%b\n" "${RED}No SSH keys found for GitHub user: $github_user${RC}"
    else
        printf "%b\n" "${GREEN}SSH keys found for $github_user:${RC}"
        printf "%s\n" "$keys"
        printf "%b" "${CYAN}Do you want to import these keys? [Y/n]: ${RC}"
        read -r confirm

        case "$confirm" in
            [Nn]*)
                printf "%b\n" "${YELLOW}SSH key import cancelled.${RC}"
                ;;
            *)
                printf "%s\n" "$keys" >> "$HOME/.ssh/authorized_keys"
                chmod 600 "$HOME/.ssh/authorized_keys"
                printf "%b\n" "${GREEN}SSH keys imported successfully!${RC}"
                ;;
        esac
    fi
}

addManualKey() {
    printf "%b" "${CYAN}Enter the public key to add: ${RC}"
    read -r PUBLIC_KEY

    if grep -q "$PUBLIC_KEY" "$HOME/.ssh/authorized_keys"; then
        printf "%b\n" "${YELLOW}Public key already exists in authorized_keys.${RC}"
    else
        printf "%s\n" "$PUBLIC_KEY" >> "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        printf "%b\n" "${GREEN}Public key added to authorized_keys.${RC}"
    fi
}

showSSHMenu() {
    printf "%b\n" "${CYAN}1) Import from GitHub"
    printf "%b\n" "2) Enter your own public key${RC}"
}

setupSSHKey() {
    printf "%b\n" "${CYAN}Select SSH key option:${RC}"
    showSSHMenu
    read -r choice

    case $choice in
        1)
            importSSHKeys
            ;;
        2)
            addManualKey
            ;;
        *)
            printf "%b\n" "${YELLOW}No valid option selected. Skipping key import.${RC}"
            ;;
    esac
}

checkEnv
installSSHDepend
enableSSH
configureSSHD
ensureSSHDir
setupSSHKey