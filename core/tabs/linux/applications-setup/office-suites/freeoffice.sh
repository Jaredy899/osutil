#!/bin/sh -e

. ../../common-script.sh

installFreeOffice() {
    if ! command_exists softmaker-freeoffice-2024 && ! command_exists freeoffice && ! command_exists softmaker; then
        printf "%b\n" "${YELLOW}Installing Free Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://www.softmaker.net/down/softmaker-freeoffice-2024_1218-01_amd64.deb
                installPkg ./softmaker-freeoffice-2024_1218-01_amd64.deb
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo -f https://shop.softmaker.com/repo/rpm SoftMaker
                "$ESCALATION_TOOL" "$PACKAGER" --gpg-auto-import-keys refresh
                installPkg softmaker-freeoffice-2024
                ;;
            pacman)
                installAurPkg freeoffice
                ;;
            dnf)
                "$ESCALATION_TOOL" curl -O -qO /etc/yum.repos.d/softmaker.repo https://shop.softmaker.com/repo/softmaker.repo
                installPkg softmaker-freeoffice-2024
                ;;
            moss|rpm-ostree|apk|xbps-install|eopkg|pkg)
                # SoftMaker FreeOffice is not packaged for these; use LibreOffice Flatpak instead
                printf "%b\n" "${YELLOW}FreeOffice has no native package for ${PACKAGER}; installing LibreOffice Flatpak instead.${RC}"
                installFlatpak org.libreoffice.LibreOffice
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Free Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installFreeOffice
