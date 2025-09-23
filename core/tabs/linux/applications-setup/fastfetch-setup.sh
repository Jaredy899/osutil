#!/bin/sh -e

. ../common-script.sh

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/.local/share/dotfiles"

installFastfetch() {
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fastfetch
                ;;
            apt-get|nala)
                case "$ARCH" in
                    x86_64)
                        DEB_FILE="fastfetch-linux-amd64.deb"
                        ;;
                    aarch64)
                        DEB_FILE="fastfetch-linux-aarch64.deb"
                        ;;
                    *)
                        printf "%b\n" "${RED}Unsupported architecture for deb install: $ARCH${RC}"
                        exit 1
                        ;;
                esac
                curl -sSLo "/tmp/fastfetch.deb" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/$DEB_FILE"
                "$ESCALATION_TOOL" "$PACKAGER" install -y /tmp/fastfetch.deb
                rm /tmp/fastfetch.deb
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add fastfetch zoxide
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy fastfetch
                ;;
            pkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Fastfetch is already installed.${RC}"
    fi
}

cloneDotfiles() {
    printf "%b\n" "${YELLOW}Cloning dotfiles repository...${RC}"

    # Ensure the parent directory exists
    mkdir -p "$HOME/.local/share"

    if [ -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${CYAN}Dotfiles directory already exists. Pulling latest changes...${RC}"
        if ! (cd "$DOTFILES_DIR" && git pull); then
            printf "%b\n" "${RED}Failed to update dotfiles repository${RC}"
            exit 1
        fi
    else
        if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            printf "%b\n" "${RED}Failed to clone dotfiles repository${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${GREEN}Dotfiles repository ready!${RC}"
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Setting up Fastfetch configuration...${RC}"

    # Symlink fastfetch config from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/fastfetch/linux.jsonc" ]; then
        mkdir -p "$HOME/.config/fastfetch"
        if [ -L "$HOME/.config/fastfetch/config.jsonc" ] || [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$HOME/.config/fastfetch/config.jsonc"
        fi
        ln -sf "$DOTFILES_DIR/config/fastfetch/linux.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Fastfetch configuration symlinked successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}Fastfetch config not found in dotfiles repo, skipping...${RC}"
    fi
}

setupFastfetchShell() {
	printf "%b\n" "${YELLOW}Configuring shell integration...${RC}"

	current_shell=$(basename "$SHELL")
	rc_file=""

	case "$current_shell" in
	"bash")
		rc_file="$HOME/.bashrc"
		;;
	"zsh")
		rc_file="$HOME/.zshrc"
		;;
	"fish")
		rc_file="$HOME/.config/fish/config.fish"
		;;
	"nu")
		rc_file="$HOME/.config/nushell/config.nu"
		;;
	*)
		printf "%b\n" "${RED}$current_shell is not supported. Update your shell configuration manually.${RC}"
		;;
	esac

	if [ ! -f "$rc_file" ]; then
		printf "%b\n" "${RED}Shell config file $rc_file not found${RC}"
	else
		if grep -q "fastfetch" "$rc_file"; then
			printf "%b\n" "${YELLOW}Fastfetch is already configured in $rc_file${RC}"
			return 0
		else
			printf "%b" "${GREEN}Would you like to add fastfetch to $rc_file? [y/N] ${RC}"
			read -r response
			if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
				printf "\n# Run fastfetch on shell initialization\nfastfetch\n" >>"$rc_file"
				printf "%b\n" "${GREEN}Added fastfetch to $rc_file${RC}"
			else
				printf "%b\n" "${YELLOW}Skipped adding fastfetch to shell config${RC}"
			fi
		fi
	fi
}

checkEnv
checkEscalationTool
cloneDotfiles
installFastfetch
setupFastfetchConfig
# setupFastfetchShell
