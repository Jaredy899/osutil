#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

choose_mount_type() {
    printf "%b\n" "${YELLOW}Choose the network mount type:${RC}"
    printf "%b\n" "1. ${YELLOW}CIFS (Samba)${RC}"
    printf "%b\n" "2. ${YELLOW}NFS${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE

    case "$CHOICE" in
        1) MOUNT_TYPE="cifs" ;;
        2) MOUNT_TYPE="nfs" ;;
        *) printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"; exit 1 ;;
    esac
}

install_package() {
    package_name="$1"
    mount_type="$2"

    # Determine the correct package name based on mount type and package manager
    if [ "$mount_type" = "nfs" ]; then
        if [ "$PACKAGER" = "apt-get" ] || [ "$PACKAGER" = "nala" ]; then
            package_name="nfs-common"
        else
            package_name="nfs-utils"
        fi
    elif [ "$mount_type" = "cifs" ]; then
        package_name="cifs-utils"
    fi

    # Check if already installed
    if command_exists "$package_name"; then
        printf "%b\n" "${GREEN}$package_name is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing $package_name...${RC}"

    case "$PACKAGER" in
        pacman)
            if "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed "$package_name"; then
                printf "%b\n" "${GREEN}$package_name installed successfully.${RC}"
            else
                printf "%b\n" "${RED}Failed to install $package_name. Please install it manually.${RC}"
                exit 1
            fi
            ;;
        apt-get|nala|dnf|zypper|eopkg)
            if "$ESCALATION_TOOL" "$PACKAGER" install -y "$package_name"; then
                printf "%b\n" "${GREEN}$package_name installed successfully.${RC}"
            else
                printf "%b\n" "${RED}Failed to install $package_name. Please install it manually.${RC}"
                exit 1
            fi
            ;;
        apk)
            if "$ESCALATION_TOOL" "$PACKAGER" add --no-cache "$package_name"; then
                printf "%b\n" "${GREEN}$package_name installed successfully.${RC}"
            else
                printf "%b\n" "${RED}Failed to install $package_name. Please install it manually.${RC}"
                exit 1
            fi
            ;;
        xbps-install)
            if "$ESCALATION_TOOL" "$PACKAGER" -Sy "$package_name"; then
                printf "%b\n" "${GREEN}$package_name installed successfully.${RC}"
            else
                printf "%b\n" "${RED}Failed to install $package_name. Please install it manually.${RC}"
                exit 1
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unknown package manager. Cannot install package.${RC}"
            exit 1
            ;;
    esac
}

prompt_mount_info() {
    if [ "$MOUNT_TYPE" = "cifs" ]; then
        install_package "cifs-utils" "cifs"

        printf "%b" "${CYAN}Enter the remote CIFS (Samba) mount location (e.g., //192.168.1.1/Files): ${RC}"
        read -r REMOTE_MOUNT

        printf "%b" "${CYAN}Enter the username for the remote CIFS (Samba) mount: ${RC}"
        read -r USERNAME

        printf "%b" "${CYAN}Enter the password for the remote CIFS (Samba) mount: ${RC}"
        stty -echo
        read -r PASSWORD
        stty echo
        printf "\n"

        CREDENTIALS_FILE="/etc/cifs-credentials-$USERNAME"
        printf "username=%s\n" "$USERNAME" | "$ESCALATION_TOOL" tee "$CREDENTIALS_FILE" > /dev/null
        printf "password=%s\n" "$PASSWORD" | "$ESCALATION_TOOL" tee -a "$CREDENTIALS_FILE" > /dev/null
        "$ESCALATION_TOOL" chmod 600 "$CREDENTIALS_FILE"

        MOUNT_OPTIONS="credentials=$CREDENTIALS_FILE"
        FS_TYPE="cifs"
    else
        install_package "nfs-utils" "nfs"

        printf "%b" "${CYAN}Enter the remote NFS mount location (e.g., 192.168.1.1:/path/to/share): ${RC}"
        read -r REMOTE_MOUNT

        MOUNT_OPTIONS="defaults"
        FS_TYPE="nfs"
    fi
}

prompt_local_mount() {
    printf "%b" "${CYAN}Do you want to use the default local mount directory (/srv/remotemount)? (y/n): ${RC}"
    read -r USE_DEFAULT

    if [ "$USE_DEFAULT" = "y" ] || [ "$USE_DEFAULT" = "Y" ]; then
        printf "%b" "${CYAN}Enter the name for the mount directory (e.g., nas): ${RC}"
        read -r MOUNT_NAME
        LOCAL_MOUNT="/srv/remotemount/$MOUNT_NAME"
    else
        printf "%b" "${CYAN}Enter the full path for the local mount directory: ${RC}"
        read -r LOCAL_MOUNT
    fi

    if [ ! -d "$LOCAL_MOUNT" ]; then
        "$ESCALATION_TOOL" mkdir -p "$LOCAL_MOUNT"
        printf "%b\n" "${GREEN}Created mount directory $LOCAL_MOUNT${RC}"
    fi
}

add_fstab_entry() {
    NEW_ENTRY="$REMOTE_MOUNT $LOCAL_MOUNT $FS_TYPE $MOUNT_OPTIONS 0 0"

    if grep -Fxq "$NEW_ENTRY" /etc/fstab; then
        printf "%b\n" "${YELLOW}The entry already exists in /etc/fstab${RC}"
    else
        printf "%s\n" "$NEW_ENTRY" | "$ESCALATION_TOOL" tee -a /etc/fstab > /dev/null
        printf "%b\n" "${GREEN}The entry has been added to /etc/fstab${RC}"
    fi
}

reload_init() {
    if [ "$INIT_MANAGER" = "systemctl" ]; then
        "$ESCALATION_TOOL" systemctl daemon-reload
        printf "%b\n" "${GREEN}Systemd daemon reloaded${RC}"
    elif [ "$INIT_MANAGER" = "rc-service" ]; then
        "$ESCALATION_TOOL" rc-service --ifexists --quiet remount-ro restart
        printf "%b\n" "${GREEN}OpenRC mounts reloaded${RC}"
    else
        printf "%b\n" "${YELLOW}No supported init system found, continuing without reload${RC}"
    fi
}

mount_and_verify() {
    if "$ESCALATION_TOOL" mount "$LOCAL_MOUNT"; then
        printf "%b\n" "${GREEN}Mount command executed successfully${RC}"
    else
        printf "%b\n" "${RED}Mount command failed. Check dmesg for more information.${RC}"
    fi

    if mountpoint -q "$LOCAL_MOUNT"; then
        printf "%b\n" "${GREEN}The network drive has been successfully mounted at $LOCAL_MOUNT${RC}"
    else
        printf "%b\n" "${RED}Failed to mount the network drive. Please check your settings and try again.${RC}"
    fi
}

# Main logic
checkEnv
choose_mount_type
prompt_mount_info
prompt_local_mount
add_fstab_entry
reload_init
mount_and_verify