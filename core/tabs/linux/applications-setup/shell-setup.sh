#!/bin/sh -e
# shellcheck disable=SC2086

. ../common-script.sh

config_dir="$HOME/.config"

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"

# Shell detection function
detectShell() {
  # Primary method: check $SHELL environment variable (most reliable)
  if [ -n "$SHELL" ]; then
    CURRENT_SHELL=$(basename "$SHELL")
    case "$CURRENT_SHELL" in
    zsh | bash | ksh | fish | ash | dash | busybox)
      echo "$CURRENT_SHELL"
      return
      ;;
    esac
  fi

  # Check for shell-specific environment variables
  for shell_var in ZSH_VERSION BASH_VERSION KSH_VERSION FISH_VERSION ASH_VERSION BB_ASH_VERSION; do
    if [ -n "$(eval echo \$$shell_var)" ]; then
      case "$shell_var" in
      ZSH_VERSION) echo "zsh" ;;
      BASH_VERSION) echo "bash" ;;
      KSH_VERSION) echo "ksh" ;;
      FISH_VERSION) echo "fish" ;;
      ASH_VERSION) echo "ash" ;;
      BB_ASH_VERSION) echo "busybox" ;;
      esac
      return
    fi
  done

  # Check /proc/$$/comm (Linux-specific but very reliable)
  if [ -f "/proc/$$/comm" ]; then
    CURRENT_SHELL=$(cat /proc/$$/comm 2>/dev/null)
    case "$CURRENT_SHELL" in
    zsh | bash | ksh | fish | ash | dash | busybox)
      echo "$CURRENT_SHELL"
      return
      ;;
    esac
  fi

  # Check the actual running shell process
  if command_exists ps; then
    CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null | sed 's/^-//' | head -1)
    case "$CURRENT_SHELL" in
    zsh | bash | ksh | fish | ash | dash | busybox)
      echo "$CURRENT_SHELL"
      return
      ;;
    esac
  fi

  # Final fallback: check what shells are available
  for shell in zsh bash fish; do
    if command_exists "$shell"; then
      echo "$shell"
      return
    fi
  done
  echo "sh"
}

installEza() {
  if command_exists eza; then
    printf "%b\n" "${GREEN}eza already installed${RC}"
    return 0
  fi

  printf "%b\n" "${YELLOW}Installing eza...${RC}"
  case "$PACKAGER" in
  pacman | apk | xbps-install | zypper | eopkg | moss | dnf | rpm-ostree | pkg)
    installPkg eza || true
    ;;
  apt-get | nala)
    if ! installPkg eza 2>/dev/null; then
      "$ESCALATION_TOOL" mkdir -p /etc/apt/keyrings
      wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
        "$ESCALATION_TOOL" gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
        "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/gierens.list
      "$ESCALATION_TOOL" chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
      "$ESCALATION_TOOL" "$PACKAGER" update
      installPkg eza || true
    fi
    ;;
  *)
    ARCH=$(uname -m)
    case "$ARCH" in
    x86_64) EZA_FILE="eza_x86_64-unknown-linux-gnu.tar.gz" ;;
    aarch64) EZA_FILE="eza_aarch64-unknown-linux-gnu.tar.gz" ;;
    *)
      printf "%b\n" "${YELLOW}Unsupported architecture for eza binary install: $ARCH${RC}"
      return 0
      ;;
    esac
    curl -sSL "https://github.com/eza-community/eza/releases/latest/download/$EZA_FILE" | tar xz
    "$ESCALATION_TOOL" chmod +x eza
    "$ESCALATION_TOOL" mv eza /usr/local/bin/eza
    ;;
  esac

  if command_exists eza; then
    printf "%b\n" "${GREEN}eza installed successfully${RC}"
  else
    printf "%b\n" "${YELLOW}eza install failed, continuing...${RC}"
  fi
}

installFastfetch() {
  if command_exists fastfetch; then
    printf "%b\n" "${GREEN}fastfetch already installed${RC}"
    return 0
  fi

  printf "%b\n" "${YELLOW}Installing fastfetch...${RC}"
  case "$PACKAGER" in
  pacman | apk | xbps-install | dnf | zypper | eopkg | moss | rpm-ostree | pkg)
    installPkg fastfetch || true
    ;;
  apt-get | nala)
    if ! installPkg fastfetch 2>/dev/null; then
      case "$ARCH" in
      x86_64) DEB_FILE="fastfetch-linux-amd64.deb" ;;
      aarch64) DEB_FILE="fastfetch-linux-aarch64.deb" ;;
      *)
        printf "%b\n" "${YELLOW}Unsupported architecture for fastfetch deb: $ARCH${RC}"
        return 0
        ;;
      esac
      curl -sSLo "/tmp/fastfetch.deb" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/$DEB_FILE" &&
        installPkg /tmp/fastfetch.deb &&
        rm -f /tmp/fastfetch.deb ||
        printf "%b\n" "${YELLOW}Failed to install fastfetch from GitHub, continuing...${RC}"
    fi
    ;;
  *)
    printf "%b\n" "${YELLOW}No fastfetch package for $PACKAGER, continuing...${RC}"
    ;;
  esac

  if command_exists fastfetch; then
    printf "%b\n" "${GREEN}fastfetch installed successfully${RC}"
  fi
}

installDependencies() {
  printf "%b\n" "${YELLOW}Installing shell dependencies...${RC}"

  # Always include eza + fastfetch (installed via dedicated helpers below)
  BASE_PACKAGES="tar bat tree unzip fontconfig git starship fzf zoxide"

  case "$SHELL_CHOICE" in
  bash)
    PACKAGES="$BASE_PACKAGES bash bash-completion"
    ;;
  zsh)
    PACKAGES="$BASE_PACKAGES zsh zsh-completions"
    ;;
  fish)
    PACKAGES="$BASE_PACKAGES fish"
    ;;
  *)
    PACKAGES="$BASE_PACKAGES"
    ;;
  esac

  case "$PACKAGER" in
  apt-get | nala)
    "$ESCALATION_TOOL" "$PACKAGER" update
    installPkg $PACKAGES || printf "%b\n" "${YELLOW}Some packages may not be available, continuing...${RC}"
    ;;
  rpm-ostree)
    installPkg $PACKAGES || printf "%b\n" "${YELLOW}Some packages may not be available, continuing...${RC}"
    printf "%b\n" "${YELLOW}Reboot to apply layered packages.${RC}"
    ;;
  *)
    installPkg $PACKAGES || printf "%b\n" "${YELLOW}Some packages may not be available, continuing...${RC}"
    ;;
  esac

  installEza
  installFastfetch

  if [ "$SHELL_CHOICE" = "zsh" ] && command_exists zsh; then
    printf "%b\n" "${GREEN}Zsh installed successfully!${RC}"
    printf "%b\n" "${YELLOW}To make zsh your default shell, run: chsh -s $(which zsh)${RC}"
  fi

  if [ "$SHELL_CHOICE" = "fish" ] && command_exists fish; then
    printf "%b\n" "${GREEN}Fish installed successfully!${RC}"
    printf "%b\n" "${YELLOW}To make fish your default shell, run: chsh -s $(which fish)${RC}"
  fi
}

cloneDotfiles() {
  printf "%b\n" "${YELLOW}Setting up dotfiles repository...${RC}"

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

getShellChoice() {
  CURRENT_SHELL=$(detectShell)
  printf "%b\n" "${CYAN}Detected shell: $CURRENT_SHELL${RC}"

  printf "%b\n" "${YELLOW}Which shell configuration would you like to install?${RC}"
  printf "%b\n" "${GREEN}1) Use detected shell ($CURRENT_SHELL) ${YELLOW}(recommended)${RC}"
  printf "%b\n" "${CYAN}2) bash${RC}"
  printf "%b\n" "${CYAN}3) zsh${RC}"
  printf "%b\n" "${CYAN}4) fish${RC}"
  printf "%b\n" "${CYAN}5) Skip shell configuration${RC}"

  printf "Enter your choice (1-5) [1]: "
  read -r USER_CHOICE
  USER_CHOICE=${USER_CHOICE:-1}

  case "$USER_CHOICE" in
  1) SHELL_CHOICE="auto" ;;
  2) SHELL_CHOICE="bash" ;;
  3) SHELL_CHOICE="zsh" ;;
  4) SHELL_CHOICE="fish" ;;
  5) SHELL_CHOICE="skip" ;;
  *) SHELL_CHOICE="skip" ;;
  esac
}

symlinkShellConfig() {
  shell_name="$1"
  case "$shell_name" in
  bash)
    printf "%b\n" "${YELLOW}Setting up bash configuration...${RC}"
    if [ -f "$DOTFILES_DIR/bash/.bashrc" ]; then
      rm -f "$HOME/.bashrc"
      ln -sf "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
      printf "%b\n" "${GREEN}Symlinked .bashrc from dotfiles${RC}"
    else
      printf "%b\n" "${YELLOW}.bashrc not found in dotfiles repo, skipping...${RC}"
    fi
    ;;
  zsh)
    printf "%b\n" "${YELLOW}Setting up zsh configuration...${RC}"
    if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
      rm -f "$HOME/.zshrc"
      ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
      printf "%b\n" "${GREEN}Symlinked .zshrc from dotfiles${RC}"
    else
      printf "%b\n" "${YELLOW}.zshrc not found in dotfiles repo, skipping...${RC}"
    fi
    ;;
  fish)
    printf "%b\n" "${YELLOW}Setting up fish configuration...${RC}"
    mkdir -p "$HOME/.config/fish"
    if [ -f "$DOTFILES_DIR/fish/config.fish" ]; then
      rm -f "$HOME/.config/fish/config.fish"
      ln -sf "$DOTFILES_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
      printf "%b\n" "${GREEN}Symlinked config.fish from dotfiles${RC}"
    else
      printf "%b\n" "${YELLOW}config.fish not found in dotfiles repo, skipping...${RC}"
    fi
    ;;
  *)
    symlinkShellConfig bash
    ;;
  esac
}

symlinkConfigs() {
  printf "%b\n" "${YELLOW}Symlinking configuration files...${RC}"

  mkdir -p "$config_dir" "$config_dir/fastfetch"

  # Starship
  if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
    rm -f "$config_dir/starship.toml"
    ln -sf "$DOTFILES_DIR/config/starship.toml" "$config_dir/starship.toml"
    printf "%b\n" "${GREEN}Symlinked starship.toml from dotfiles${RC}"
  else
    printf "%b\n" "${YELLOW}starship.toml not found in dotfiles repo, skipping...${RC}"
  fi

  # Fastfetch (always)
  case "$DTYPE" in
  darwin) FASTFETCH_CONFIG="$DOTFILES_DIR/config/fastfetch/macos.jsonc" ;;
  *) FASTFETCH_CONFIG="$DOTFILES_DIR/config/fastfetch/linux.jsonc" ;;
  esac

  if [ -f "$FASTFETCH_CONFIG" ]; then
    rm -f "$config_dir/fastfetch/config.jsonc"
    ln -sf "$FASTFETCH_CONFIG" "$config_dir/fastfetch/config.jsonc"
    printf "%b\n" "${GREEN}Symlinked fastfetch config from dotfiles${RC}"
  else
    printf "%b\n" "${YELLOW}fastfetch config not found in dotfiles repo, skipping...${RC}"
  fi

  # Shell rc files
  case "$SHELL_CHOICE" in
  bash | zsh | fish)
    symlinkShellConfig "$SHELL_CHOICE"
    ;;
  auto)
    symlinkShellConfig "$(detectShell)"
    ;;
  skip)
    printf "%b\n" "${YELLOW}Skipping shell configuration...${RC}"
    ;;
  *)
    printf "%b\n" "${RED}Invalid shell choice: $SHELL_CHOICE. Skipping shell configuration...${RC}"
    ;;
  esac

  # Distro-specific .profile handling
  if grep -qi alpine /etc/os-release 2>/dev/null; then
    if [ -f "$DOTFILES_DIR/sh/.profile" ]; then
      rm -f "$HOME/.profile"
      ln -sf "$DOTFILES_DIR/sh/.profile" "$HOME/.profile"
      printf "%b\n" "${GREEN}Symlinked .profile for Alpine${RC}"
    fi
  elif grep -qi solus /etc/os-release 2>/dev/null; then
    if [ "$SHELL_CHOICE" = "bash" ] || ([ "$SHELL_CHOICE" = "auto" ] && [ "$(detectShell)" = "bash" ]); then
      if [ -f "$HOME/.bashrc" ]; then
        cat >"$HOME/.profile" <<'EOF'
# Solus-specific: Source .bashrc to avoid configuration duplication
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
EOF
        printf "%b\n" "${GREEN}Created .profile to source .bashrc for Solus${RC}"
      fi
    fi
  fi

  printf "%b\n" "${GREEN}Configuration files symlinked successfully!${RC}"
}

installStarshipAndFzf() {
  if command_exists starship; then
    printf "%b\n" "${GREEN}Starship already installed${RC}"
  else
    if [ "$PACKAGER" = "eopkg" ] || [ "$PACKAGER" = "moss" ]; then
      installPkg starship || true
    fi
    if ! command_exists starship; then
      printf "%b\n" "${YELLOW}Installing starship via official install script...${RC}"
      curl -sS https://starship.rs/install.sh | sh || printf "%b\n" "${YELLOW}Starship install failed, continuing...${RC}"
    fi
  fi

  # apt/nala fzf is often outdated — prefer GitHub build
  if [ "$PACKAGER" = "apt-get" ] || [ "$PACKAGER" = "nala" ]; then
    if command_exists fzf && dpkg -l | grep -q "^ii.*fzf "; then
      printf "%b\n" "${YELLOW}Removing apt-installed fzf...${RC}"
      "$ESCALATION_TOOL" "$PACKAGER" remove -y fzf
    fi

    if ! command_exists fzf; then
      printf "%b\n" "${YELLOW}Installing fzf from GitHub...${RC}"
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
      cd ~/.fzf && ./install --all
      printf "%b\n" "${GREEN}Fzf installed successfully!${RC}"
    else
      printf "%b\n" "${GREEN}Fzf already installed${RC}"
    fi
  fi
}

installZoxide() {
  if command_exists zoxide; then
    printf "%b\n" "${GREEN}Zoxide already installed${RC}"
    return
  fi

  if [ "$PACKAGER" = "apk" ]; then
    installPkg zoxide || printf "%b\n" "${YELLOW}Failed to install zoxide, continuing...${RC}"
  else
    curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || {
      printf "%b\n" "${YELLOW}Something went wrong during zoxide install, continuing...${RC}"
    }
  fi
}

backupExistingConfigs() {
  printf "%b\n" "${YELLOW}Backing up existing configurations...${RC}"

  case "$SHELL_CHOICE" in
  bash)
    [ -e "$HOME/.bashrc" ] && [ ! -e "$HOME/.bashrc.bak" ] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    ;;
  zsh)
    [ -e "$HOME/.zshrc" ] && [ ! -e "$HOME/.zshrc.bak" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    ;;
  fish)
    [ -e "$HOME/.config/fish/config.fish" ] && [ ! -e "$HOME/.config/fish/config.fish.bak" ] &&
      mv "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak"
    ;;
  auto)
    case "$(detectShell)" in
    bash) [ -e "$HOME/.bashrc" ] && [ ! -e "$HOME/.bashrc.bak" ] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak" ;;
    zsh) [ -e "$HOME/.zshrc" ] && [ ! -e "$HOME/.zshrc.bak" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak" ;;
    fish)
      [ -e "$HOME/.config/fish/config.fish" ] && [ ! -e "$HOME/.config/fish/config.fish.bak" ] &&
        mv "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak"
      ;;
    esac
    ;;
  esac

  if grep -qi alpine /etc/os-release 2>/dev/null; then
    [ -e "$HOME/.profile" ] && [ ! -e "$HOME/.profile.bak" ] && mv "$HOME/.profile" "$HOME/.profile.bak"
  elif grep -qi solus /etc/os-release 2>/dev/null; then
    if [ "$SHELL_CHOICE" = "bash" ] || ([ "$SHELL_CHOICE" = "auto" ] && [ "$(detectShell)" = "bash" ]); then
      [ -e "$HOME/.profile" ] && [ ! -e "$HOME/.profile.bak" ] && mv "$HOME/.profile" "$HOME/.profile.bak"
    fi
  fi

  [ -e "$config_dir/starship.toml" ] && [ ! -e "$config_dir/starship.toml.bak" ] &&
    mv "$config_dir/starship.toml" "$config_dir/starship.toml.bak"

  [ -e "$config_dir/fastfetch/config.jsonc" ] && [ ! -e "$config_dir/fastfetch/config.jsonc.bak" ] &&
    mv "$config_dir/fastfetch/config.jsonc" "$config_dir/fastfetch/config.jsonc.bak"

  printf "%b\n" "${GREEN}Backup completed!${RC}"
}

# Main execution
checkEnv
checkEscalationTool
getShellChoice
installDependencies
cloneDotfiles
backupExistingConfigs
symlinkConfigs
installStarshipAndFzf
installZoxide

printf "%b\n" "${CYAN}Shell setup complete (includes eza + fastfetch).${RC}"
printf "%b\n" "${CYAN}For language toolchains, install Mise from the Development tab first.${RC}"
