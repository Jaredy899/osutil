#!/bin/sh -e

. ../common-script.sh

installYazi() {
    if ! command_exists yazi; then
        printf "%b\n" "${YELLOW}Installing Yazi...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y ffmpeg 7zip jq poppler-utils fd-find ripgrep imagemagick # fzf and zoxide will be installed from git
                
                case "$ARCH" in
                    x86_64)
                        YAZI_FILE="yazi-x86_64-unknown-linux-musl.zip"
                        ;;
                    aarch64)
                        YAZI_FILE="yazi-aarch64-unknown-linux-musl.zip"
                        ;;
                    *)
                        printf "%b\n" "${RED}Unsupported architecture for Yazi install: $ARCH${RC}"
                        exit 1
                        ;;
                esac
                
                printf "%b\n" "${YELLOW}Downloading Yazi from GitHub releases...${RC}"
                curl -sSLo "/tmp/yazi.zip" "https://github.com/sxyazi/yazi/releases/latest/download/$YAZI_FILE"
                unzip -q "/tmp/yazi.zip" -d "/tmp/"
                "$ESCALATION_TOOL" mv "/tmp/yazi" "/usr/local/bin/"
                "$ESCALATION_TOOL" mv "/tmp/ya" "/usr/local/bin/"
                rm "/tmp/yazi.zip"
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add yazi ffmpeg p7zip jq poppler-utils fd ripgrep fzf zoxide imagemagick
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy yazi ffmpeg p7zip jq poppler-utils fd ripgrep fzf zoxide imagemagick
                ;;
            dnf)
                # Try COPR repository first
                if ! "$ESCALATION_TOOL" dnf copr enable lihaohong/yazi -y; then
                    printf "%b\n" "${YELLOW}COPR repository not available, installing dependencies only...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" install -y ffmpeg p7zip jq poppler-utils fd-find ripgrep fzf zoxide ImageMagick
                    printf "%b\n" "${YELLOW}Please install Yazi manually from GitHub releases${RC}"
                    return 0
                fi
                "$ESCALATION_TOOL" "$PACKAGER" install -y yazi ffmpeg p7zip jq poppler-utils fd-find ripgrep fzf zoxide ImageMagick
                ;;
            pkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y yazi ffmpeg p7zip jq poppler-utils fd-find ripgrep fzf zoxide ImageMagick
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y yazi ffmpeg p7zip jq poppler-utils fd ripgrep fzf zoxide ImageMagick
                ;;
        esac
        printf "%b\n" "${GREEN}Yazi installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Yazi is already installed.${RC}"
    fi
}

checkEnv
checkDistro
installYazi
