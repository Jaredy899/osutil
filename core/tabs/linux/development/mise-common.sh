#!/bin/sh -e
# Shared mise helpers for Development scripts.
# Sourced by mise.sh and language installers (go/node/rust/…).

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

## Ensure mise is on PATH for the current shell session.
ensureMiseInPath() {
    if command_exists mise; then
        return 0
    fi

    for candidate in \
        "$HOME/.local/bin/mise" \
        "$HOME/.cargo/bin/mise" \
        /usr/local/bin/mise; do
        if [ -x "$candidate" ]; then
            case ":$PATH:" in
                *":$(dirname "$candidate"):"*) ;;
                *) export PATH="$(dirname "$candidate"):$PATH" ;;
            esac
            break
        fi
    done

    # Activate shims if available (session-only)
    if command_exists mise; then
        # POSIX-friendly: prefer bash activate when bash is present
        if command_exists bash; then
            eval "$(mise activate bash)" 2>/dev/null || true
        fi
    fi
}

## Install mise if missing, then put it on PATH.
ensureMise() {
    ensureMiseInPath
    if command_exists mise; then
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing mise...${RC}"
    if ! curl -fsSL https://mise.run | sh; then
        printf "%b\n" "${RED}Failed to install mise${RC}"
        return 1
    fi

    ensureMiseInPath
    if ! command_exists mise; then
        printf "%b\n" "${RED}mise installed but not found on PATH. Add ~/.local/bin to PATH and retry.${RC}"
        return 1
    fi

    printf "%b\n" "${GREEN}mise installed successfully${RC}"
}

## Clone/update dotfiles used for mise config.
ensureDotfiles() {
    if [ -d "$DOTFILES_DIR/.git" ]; then
        (cd "$DOTFILES_DIR" && git pull --ff-only) >/dev/null 2>&1 || true
        return 0
    fi

    if [ -d "$DOTFILES_DIR" ]; then
        return 0
    fi

    if ! command_exists git; then
        printf "%b\n" "${YELLOW}git not available; skipping mise config from dotfiles${RC}"
        return 0
    fi

    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || {
        printf "%b\n" "${YELLOW}Could not clone dotfiles; skipping mise config symlink${RC}"
        return 0
    }
}

## Symlink mise config from dotfiles if present.
symlinkMiseConfig() {
    ensureDotfiles
    mkdir -p "$HOME/.config/mise"

    if [ ! -f "$DOTFILES_DIR/config/mise/config.toml" ]; then
        printf "%b\n" "${YELLOW}mise config not found in dotfiles, skipping symlink${RC}"
        return 0
    fi

    if [ -e "$HOME/.config/mise/config.toml" ] && [ ! -L "$HOME/.config/mise/config.toml" ] &&
        [ ! -e "$HOME/.config/mise/config.toml.bak" ]; then
        mv "$HOME/.config/mise/config.toml" "$HOME/.config/mise/config.toml.bak"
        printf "%b\n" "${YELLOW}Backed up existing mise config to config.toml.bak${RC}"
    fi

    rm -f "$HOME/.config/mise/config.toml"
    ln -sf "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"
    printf "%b\n" "${GREEN}Symlinked mise config from dotfiles${RC}"
}
