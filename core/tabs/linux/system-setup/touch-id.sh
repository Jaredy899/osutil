#!/bin/sh -e

. ../common-script.sh


# Function to enable TouchID for sudo
enableTouchIDForSudo() {
    printf "%b\n" "${YELLOW}Enabling TouchID authentication for sudo...${RC}"
    
    # Check if /etc/pam.d/sudo exists
    if [ -f "/etc/pam.d/sudo" ]; then
        # Check if TouchID is already enabled
        if ! grep -q "pam_tid.so" "/etc/pam.d/sudo"; then
            # Add TouchID authentication to sudo
            $ESCALATION_TOOL sed -i '.bak' '1i\
auth       sufficient     pam_tid.so\
' /etc/pam.d/sudo
            printf "%b\n" "${GREEN}TouchID authentication for sudo enabled${RC}"
        else
            printf "%b\n" "${YELLOW}TouchID authentication for sudo is already enabled${RC}"
        fi
    else
        printf "%b\n" "${RED}sudo PAM configuration file not found${RC}"
    fi
}

checkEnv
enableTouchIDForSudo