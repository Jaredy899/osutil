#!/bin/sh -e

. ../../common-script.sh

installSublime() {
    if ! command_exists sublime && ! command_exists subl && ! command_exists com.sublimetext.three; then
        printf "%b\n" "${YELLOW}Installing Sublime...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | "$ESCALATION_TOOL" apt-key add -
                echo "deb https://download.sublimetext.com/ apt/stable/" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/sublime-text.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                installPkg sublime-text
                ;;
            zypper)
                "$ESCALATION_TOOL" rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                "$ESCALATION_TOOL" "$PACKAGER" addrepo -g -f https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                installPkg sublime-text
                ;;
            pacman)
                installAurPkg sublime-text-4
                ;;
            dnf)
                "$ESCALATION_TOOL" rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
                if [ "$dnf_version" -eq 4 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                fi
                installPkg sublime-text
                ;;
            moss|rpm-ostree|apk|xbps-install|eopkg|pkg)
                installFlatpak com.sublimetext.three
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Sublime is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installSublime
