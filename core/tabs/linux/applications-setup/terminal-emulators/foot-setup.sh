#!/bin/sh -e

. ../../common-script.sh


installFoot() {
    if ! command_exists foot; then
        printf "%b\n" "${YELLOW}Installing foot...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm foot
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add foot
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy foot
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y foot
                ;;
        esac
    else
        printf "%b\n" "${GREEN}foot is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installFoot
