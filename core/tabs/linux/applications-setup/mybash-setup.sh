#!/bin/sh -e

. ../common-script.sh

config_dir="$HOME/.config"

installDepend() {
    if [ ! -f "/usr/share/bash-completion/bash_completion" ] || ! command_exists bash tar bat tree unzip fc-list git; then
        printf "%b\n" "${YELLOW}Installing Bash...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm bash bash-completion tar bat tree unzip fontconfig git
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add bash bash-completion tar bat tree unzip fontconfig git
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy bash bash-completion tar bat tree unzip fontconfig git
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig git
                ;;
        esac
    fi
}

downloadConfigs() {
    printf "%b\n" "${YELLOW}Downloading your custom config files...${RC}"
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir" "$config_dir/fastfetch"
    
    # Download .bashrc
    printf "%b\n" "${YELLOW}Downloading .bashrc...${RC}"
    # Ensure target is not a directory and is writable (fix ownership if needed)
    if [ -d "$HOME/.bashrc" ]; then
        printf "%b\n" "${RED}$HOME/.bashrc exists and is a directory${RC}"
        exit 1
    fi
    if [ -e "$HOME/.bashrc" ] && [ ! -w "$HOME/.bashrc" ]; then
        printf "%b\n" "${YELLOW}Fixing ownership/permissions for $HOME/.bashrc${RC}"
        if ! "$ESCALATION_TOOL" chown "$USER":"$USER" "$HOME/.bashrc"; then
            printf "%b\n" "${RED}Unable to fix permissions for $HOME/.bashrc${RC}"
            exit 1
        fi
    fi
    tmp_bashrc="$(mktemp)"
    if ! curl -fsSLo "$tmp_bashrc" "https://raw.githubusercontent.com/Jaredy899/linux/main/config_changes/.bashrc"; then
        rm -f "$tmp_bashrc"
        printf "%b\n" "${RED}Failed to download .bashrc${RC}"
        exit 1
    fi
    if ! mv "$tmp_bashrc" "$HOME/.bashrc"; then
        rm -f "$tmp_bashrc"
        printf "%b\n" "${RED}Failed to write $HOME/.bashrc${RC}"
        exit 1
    fi
    
    # Download starship.toml
    printf "%b\n" "${YELLOW}Downloading starship.toml...${RC}"
    tmp_starship="$(mktemp)"
    if ! curl -fsSLo "$tmp_starship" "https://raw.githubusercontent.com/Jaredy899/linux/main/config_changes/starship.toml"; then
        rm -f "$tmp_starship"
        printf "%b\n" "${RED}Failed to download starship.toml${RC}"
        exit 1
    fi
    if ! mv "$tmp_starship" "$config_dir/starship.toml"; then
        rm -f "$tmp_starship"
        printf "%b\n" "${RED}Failed to write $config_dir/starship.toml${RC}"
        exit 1
    fi
    
    # Download config.jsonc
    printf "%b\n" "${YELLOW}Downloading config.jsonc...${RC}"
    tmp_jsonc="$(mktemp)"
    if ! curl -fsSLo "$tmp_jsonc" "https://raw.githubusercontent.com/Jaredy899/linux/main/config_changes/config.jsonc"; then
        rm -f "$tmp_jsonc"
        printf "%b\n" "${RED}Failed to download config.jsonc${RC}"
        exit 1
    fi
    if ! mv "$tmp_jsonc" "$config_dir/fastfetch/config.jsonc"; then
        rm -f "$tmp_jsonc"
        printf "%b\n" "${RED}Failed to write $config_dir/fastfetch/config.jsonc${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}All config files downloaded successfully!${RC}"
}

installFont() {
    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "%b\n" "${GREEN}Font '$FONT_NAME' is installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing font '$FONT_NAME'${RC}"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
        unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR"/"$FONT_NAME"
        mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
        fc-cache -fv
        rm -rf "${TEMP_DIR}"
        printf "%b\n" "${GREEN}'$FONT_NAME' installed successfully.${RC}"
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        printf "%b\n" "${GREEN}Starship already installed${RC}"
        return
    fi

    if [ "$PACKAGER" = "eopkg" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" install -y starship || {
            printf "%b\n" "${RED}Failed to install starship with Solus!${RC}"
            exit 1
        }
    else
        curl -sSL https://starship.rs/install.sh | "$ESCALATION_TOOL" sh || {
            printf "%b\n" "${RED}Failed to install starship!${RC}"
            exit 1
        }
    fi

    if command_exists fzf; then
        printf "%b\n" "${GREEN}Fzf already installed${RC}"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        "$ESCALATION_TOOL" ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "%b\n" "${GREEN}Zoxide already installed${RC}"
        return
    fi

    if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}Zoxide installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please restart your shell to see the changes.${RC}"
    fi
}

backupExistingConfigs() {
    OLD_BASHRC="$HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
        printf "%b\n" "${YELLOW}Moving old bash config file to $HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$HOME/.bashrc.bak"; then
            printf "%b\n" "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi
    
    # Backup existing starship config if it exists
    if [ -e "$config_dir/starship.toml" ] && [ ! -e "$config_dir/starship.toml.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing starship.toml to $config_dir/starship.toml.bak${RC}"
        mv "$config_dir/starship.toml" "$config_dir/starship.toml.bak"
    fi
    
    # Backup existing config.jsonc if it exists
    if [ -e "$config_dir/fastfetch/config.jsonc" ] && [ ! -e "$config_dir/fastfetch/config.jsonc.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing config.jsonc to $config_dir/fastfetch/config.jsonc.bak${RC}"
        mv "$config_dir/fastfetch/config.jsonc" "$config_dir/fastfetch/config.jsonc.bak"
    fi
}

checkEnv
checkEscalationTool
installDepend
backupExistingConfigs
downloadConfigs
installFont
installStarshipAndFzf
installZoxide