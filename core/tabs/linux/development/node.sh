#!/bin/sh -e

. ../common-script.sh

installNode() {
    printf "%b\n" "${YELLOW}Installing Node.js via NVM (latest LTS)...${RC}"

    # Ensure curl and bash available
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm curl bash
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add curl bash
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy curl bash
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y curl bash
            ;;
    esac

    # Install NVM
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi

    # Load NVM into this shell
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    # Install latest LTS and set default
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    # Enable Corepack (yarn/pnpm)
    if command_exists corepack; then
        corepack enable || true
        corepack prepare yarn@stable --activate || true
        corepack prepare pnpm@latest --activate || true
    fi

    # Ensure NVM loads in future shells
    SHELL_RC="${HOME}/.bashrc"
    [ "$(basename "$SHELL")" = "zsh" ] && SHELL_RC="${HOME}/.zshrc"
    if ! grep -q "NVM_DIR=\"\$HOME/.nvm\"" "$SHELL_RC" 2>/dev/null; then
        {
            printf "%s\n" ''
            cat <<'RCAPPEND'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
RCAPPEND
        } >> "$SHELL_RC"
    fi

    printf "%b\n" "${GREEN}Node.js (LTS) installed via NVM. Restart your shell to use 'node' and 'npm'.${RC}"
}

checkEnv
installNode


