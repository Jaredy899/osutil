#!/bin/sh -e

. ../common-script.sh

installPodmanCompose() {
    if command_exists podman-compose; then
        printf "%b\n" "${GREEN}Podman Compose is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Podman Compose...${RC}"
    case "$PACKAGER" in
        pacman|apt-get|nala|dnf|zypper|rpm-ostree|apk|xbps-install|eopkg|pkg)
            installPkg podman-compose
            ;;
        moss)
            # No native package; install via pip when available
            if ! command_exists pip3; then
                installPkg python-pip || installPkg pip || true
            fi
            if command_exists pip3; then
                "$ESCALATION_TOOL" pip3 install podman-compose
            elif command_exists pip; then
                "$ESCALATION_TOOL" pip install podman-compose
            else
                printf "%b\n" "${YELLOW}No podman-compose package on moss and pip is unavailable.${RC}"
                printf "%b\n" "${CYAN}Install Podman and use its compose support, or install pip and re-run this script.${RC}"
                return 1
            fi
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

checkEnv
checkEscalationTool
installPodmanCompose
