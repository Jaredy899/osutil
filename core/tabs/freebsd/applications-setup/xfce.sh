#!/bin/sh -e

. ../common-script.sh

installXFCE() {
    printf "%b\n" "${YELLOW}Installing XFCE desktop environment...${RC}"

    # Install XFCE and related packages
    printf "%b\n" "${CYAN}Installing XFCE desktop environment...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" install -y \
        xfce \
        xfce4-goodies \
        slim \
        dbus \
        hald \
        polkit

    # Enable services
    printf "%b\n" "${CYAN}Enabling required services...${RC}"
    "$ESCALATION_TOOL" sysrc dbus_enable=YES
    "$ESCALATION_TOOL" sysrc hald_enable=YES
    "$ESCALATION_TOOL" sysrc slim_enable=YES

    # Start services
    "$ESCALATION_TOOL" service dbus start
    "$ESCALATION_TOOL" service hald start

    printf "%b\n" "${GREEN}XFCE installed successfully!${RC}"
    printf "%b\n" "${CYAN}Reboot your system to start using XFCE desktop environment.${RC}"
    printf "%b\n" "${CYAN}You can select XFCE from the login manager (SLiM).${RC}"
}

checkEnv
installXFCE
