#!/bin/sh -e

. ../common-script.sh

upgradeFreeBSD() {
    printf "%b\n" "${YELLOW}FreeBSD System Upgrade Utility${RC}"
    printf "%b\n" "${CYAN}This script helps you manage FreeBSD version upgrades and repository changes.${RC}"

    # Show current FreeBSD version
    if [ -n "$FREEBSD_VERSION" ]; then
        printf "%b\n" "${GREEN}Current FreeBSD version: ${FREEBSD_VERSION}${RC}"
    else
        printf "%b\n" "${YELLOW}Could not determine current FreeBSD version${RC}"
    fi

    printf "%b\n" "${YELLOW}Choose upgrade option:${RC}"
    printf "%b\n" "${CYAN}1) Update package repositories and upgrade all packages${RC}"
    printf "%b\n" "${CYAN}2) Major version upgrade (requires careful planning)${RC}"
    printf "%b\n" "${CYAN}3) Switch to quarterly package branch${RC}"
    printf "%b\n" "${CYAN}4) Switch to latest package branch${RC}"
    printf "%b" "Enter your choice (1-4): "
    read -r choice

    case $choice in
        1)
            printf "%b\n" "${YELLOW}Updating repositories and upgrading packages...${RC}"

            # Update package database
            printf "%b\n" "${CYAN}Updating package database...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" update

            # Upgrade all packages
            printf "%b\n" "${CYAN}Upgrading all packages...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y

            # Clean up old packages
            printf "%b\n" "${CYAN}Cleaning up old packages...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" autoremove -y

            printf "%b\n" "${GREEN}Package upgrade completed!${RC}"
            ;;
        2)
            printf "%b\n" "${RED}Major version upgrades require careful planning and may break your system!${RC}"
            printf "%b\n" "${YELLOW}Please read the FreeBSD Handbook section on upgrading:${RC}"
            printf "%b\n" "${CYAN}https://docs.freebsd.org/en/books/handbook/cutting-edge/#makeworld${RC}"
            printf "%b\n" "${YELLOW}For major upgrades, it's recommended to:${RC}"
            printf "%b\n" "${CYAN}1. Backup your data${RC}"
            printf "%b\n" "${CYAN}2. Read the release notes${RC}"
            printf "%b\n" "${CYAN}3. Use freebsd-update or build from source${RC}"
            printf "%b\n" "${CYAN}4. Test in a VM first${RC}"
            ;;
        3)
            printf "%b\n" "${YELLOW}Switching to quarterly package branch...${RC}"
            printf "%b\n" "${YELLOW}This uses well-tested packages from the quarterly branch.${RC}"

            # Backup current pkg configuration
            if [ -f /usr/local/etc/pkg/repos/FreeBSD.conf ]; then
                "$ESCALATION_TOOL" cp /usr/local/etc/pkg/repos/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf.backup
            fi

            # Set quarterly branch
            "$ESCALATION_TOOL" mkdir -p /usr/local/etc/pkg/repos
            "$ESCALATION_TOOL" sh -c "cat > /usr/local/etc/pkg/repos/FreeBSD.conf << EOF
FreeBSD: {
  url: \"pkg+http://pkg.FreeBSD.org/\${ABI}/quarterly\",
  mirror_type: \"srv\",
  signature_type: \"fingerprints\",
  fingerprints: \"/usr/share/keys/pkg\",
  enabled: yes
}
EOF"

            # Update repositories
            "$ESCALATION_TOOL" "$PACKAGER" update
            printf "%b\n" "${GREEN}Switched to quarterly package branch!${RC}"
            ;;
        4)
            printf "%b\n" "${YELLOW}Switching to latest package branch...${RC}"
            printf "%b\n" "${YELLOW}This uses the latest packages but may be less stable.${RC}"

            # Backup current pkg configuration
            if [ -f /usr/local/etc/pkg/repos/FreeBSD.conf ]; then
                "$ESCALATION_TOOL" cp /usr/local/etc/pkg/repos/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf.backup
            fi

            # Set latest branch
            "$ESCALATION_TOOL" mkdir -p /usr/local/etc/pkg/repos
            "$ESCALATION_TOOL" sh -c "cat > /usr/local/etc/pkg/repos/FreeBSD.conf << EOF
FreeBSD: {
  url: \"pkg+http://pkg.FreeBSD.org/\${ABI}/latest\",
  mirror_type: \"srv\",
  signature_type: \"fingerprints\",
  fingerprints: \"/usr/share/keys/pkg\",
  enabled: yes
}
EOF"

            # Update repositories
            "$ESCALATION_TOOL" "$PACKAGER" update
            printf "%b\n" "${GREEN}Switched to latest package branch!${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Exiting...${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}FreeBSD upgrade operations completed!${RC}"
    printf "%b\n" "${YELLOW}Note: If you encounter issues, you can restore configurations from backup files.${RC}"
}

checkEnv
upgradeFreeBSD
