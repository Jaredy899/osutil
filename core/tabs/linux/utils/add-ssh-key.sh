#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Function to setup and configure SSH
setup_ssh() {
    printf "%b\n" "${YELLOW}Setting up SSH...${RC}"

    case "$PACKAGER" in
        apt-get|nala)
            if ! command_exists "openssh-server"; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y openssh-server
            else
                printf "%b\n" "${GREEN}openssh-server is already installed.${RC}"
            fi
            startAndEnableService "ssh"
            ;;
        pacman)
            if ! command_exists "openssh"; then
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm openssh
            else
                printf "%b\n" "${GREEN}openssh is already installed.${RC}"
            fi
            startAndEnableService "sshd"
            ;;
        apk)
            if ! command_exists "openssh"; then
                "$ESCALATION_TOOL" "$PACKAGER" add openssh
            else
                printf "%b\n" "${GREEN}openssh is already installed.${RC}"
            fi
            startAndEnableService "sshd"
            ;;
        xbps-install)
            if ! command_exists "openssh"; then
                "$ESCALATION_TOOL" "$PACKAGER" -Sy openssh
            else
                printf "%b\n" "${GREEN}openssh is already installed.${RC}"
            fi
            startAndEnableService "sshd"
            ;;
        pkg)
            if ! command_exists "openssh"; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y openssh-portable
            else
                printf "%b\n" "${GREEN}openssh-portable is already installed.${RC}"
            fi
            startAndEnableService "sshd"
            ;;
        *)
            if ! command_exists "openssh-server"; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y openssh-server
            else
                printf "%b\n" "${GREEN}openssh-server is already installed.${RC}"
            fi
            startAndEnableService "sshd"
            ;;
    esac
}

ensure_ssh_setup() {
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

import_ssh_keys() {
    printf "%b" "${CYAN}Enter the GitHub username: ${RC}"
    read -r GITHUB_USER

    SSH_KEYS_URL="https://github.com/$GITHUB_USER.keys"
    KEYS=$(curl -s "$SSH_KEYS_URL")

    if [ -z "$KEYS" ]; then
        printf "%b\n" "${RED}No SSH keys found for GitHub user: $GITHUB_USER${RC}"
    else
        printf "%b\n" "${GREEN}SSH keys found for $GITHUB_USER:${RC}"
        printf "%s\n" "$KEYS"
        printf "%b" "${CYAN}Do you want to import these keys? [Y/n]: ${RC}"
        read -r CONFIRM

        case "$CONFIRM" in
            [Nn]*)
                printf "%b\n" "${YELLOW}SSH key import cancelled.${RC}"
                ;;
            *)
                printf "%s\n" "$KEYS" >> "$AUTHORIZED_KEYS"
                chmod 600 "$AUTHORIZED_KEYS"
                printf "%b\n" "${GREEN}SSH keys imported successfully!${RC}"
                ;;
        esac
    fi
}

add_manual_key() {
    printf "%b" "${CYAN}Enter the public key to add: ${RC}"
    read -r PUBLIC_KEY

    if grep -q "$PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
        printf "%b\n" "${YELLOW}Public key already exists in $AUTHORIZED_KEYS.${RC}"
    else
        printf "%s\n" "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
        printf "%b\n" "${GREEN}Public key added to $AUTHORIZED_KEYS.${RC}"
    fi
}

show_ssh_menu() {
    printf "%b\n" "${CYAN}SSH Key Management${RC}"
    printf "%b\n" "${CYAN}1) Import from GitHub${RC}"
    printf "%b\n" "${CYAN}2) Enter your own public key${RC}"
    printf "%b\n" "${CYAN}3) Exit${RC}"
}

ssh_key_menu() {
    while true; do
        show_ssh_menu
        printf "%b" "${CYAN}Select an option (1-3): ${RC}"
        read -r CHOICE

        case $CHOICE in
            1)
                import_ssh_keys
                break
                ;;
            2)
                add_manual_key
                break
                ;;
            3)
                printf "%b\n" "${GREEN}Exiting...${RC}"
                exit 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid option. Please try again.${RC}"
                ;;
        esac
        printf "%b\n" "${CYAN}Press Enter to continue...${RC}"
        read -r _
    done
}

checkEnv
setup_ssh
ensure_ssh_setup
ssh_key_menu