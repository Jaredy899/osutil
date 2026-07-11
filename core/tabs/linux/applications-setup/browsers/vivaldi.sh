#!/bin/sh -e

. ../../common-script.sh

installVivaldi() {
    if ! command_exists vivaldi; then
        printf "%b\n" "${YELLOW}Installing Vivaldi...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                installPkg curl
                "$ESCALATION_TOOL" curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg
                "$ESCALATION_TOOL" echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=$(dpkg --print-architecture)] https://repo.vivaldi.com/archive/deb/ stable main" | sudo dd of=/etc/apt/sources.list.d/vivaldi-archive.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                installPkg vivaldi-stable
                ;;
            dnf)
                installPkg dnf-plugins-core
                dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
                if [ "$dnf_version" -eq 4 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://repo.vivaldi.com/stable/vivaldi-fedora.repo
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
                fi
                installPkg vivaldi-stable
                ;;
            zypper)
                "$ESCALATION_TOOL" zypper ar https://repo.vivaldi.com/archive/vivaldi-suse.repo
                "$ESCALATION_TOOL" zypper --non-interactive --gpg-auto-import-keys in vivaldi-stable
                ;;
            pacman)
                installPkg vivaldi
                ;;
            eopkg)
                installPkg vivaldi-stable
                ;;
            moss|rpm-ostree|apk|xbps-install|pkg)
                # No official Flatpak; fall back to Chromium Flatpak
                printf "%b\n" "${YELLOW}Vivaldi has no package for ${PACKAGER}; installing Chromium Flatpak instead.${RC}"
                installFlatpak org.chromium.Chromium
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Vivaldi Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installVivaldi
