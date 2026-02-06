#!/bin/sh -e

. ../../common-script.sh

multimedia() {
    case "$PACKAGER" in
        dnf)
            if [ -e /etc/yum.repos.d/rpmfusion-free.repo ] && [ -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing Multimedia Codecs...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" swap ffmpeg-free ffmpeg --allowerasing -y
                printf "%b\n" "${GREEN}Multimedia Codecs Installed...${RC}"
            else
                printf "%b\n" "${RED}RPM Fusion repositories not found. Please set up RPM Fusion first!${RC}"
            fi
            ;;
        rpm-ostree)
            if [ -e /etc/yum.repos.d/rpmfusion-free.repo ] && [ -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Layering Multimedia Codecs (reboot to apply)...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" override remove ffmpeg-free 2>/dev/null || true
                "$ESCALATION_TOOL" "$PACKAGER" install --allow-inactive ffmpeg
                printf "%b\n" "${GREEN}Multimedia codecs layered. Reboot to apply.${RC}"
            else
                printf "%b\n" "${RED}RPM Fusion not found. Run RPM Fusion setup first.${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
multimedia