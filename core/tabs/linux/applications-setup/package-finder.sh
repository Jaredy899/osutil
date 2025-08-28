#!/bin/sh -e

. ../common-script.sh

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies for pkg-tui...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm fzf bash coreutils
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf bash coreutils
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf bash coreutils
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf bash coreutils
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add fzf bash coreutils
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf bash coreutils
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy fzf bash coreutils
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    printf "%b\n" "${GREEN}Dependencies installed.${RC}"
}

buildPkgTui() {
    printf "%b\n" "${YELLOW}Building pkg-tui script...${RC}"
    tmpfile=$(mktemp)
    cat > "$tmpfile" <<"EOF"
#!/usr/bin/env bash
set -e

# Detect first available package manager
detect_pkg_mgr() {
  for mgr in apt pacman dnf zypper apk eopkg xbps-install; do
    if command -v "$mgr" >/dev/null 2>&1; then
      echo "$mgr"
      return
    fi
  done
  echo "none"
}

PKG_MGR=$(detect_pkg_mgr)

case "$PKG_MGR" in
  apt)
    LIST_CMD="apt-cache pkgnames"
    INFO_CMD="apt show {1} 2>/dev/null"
    INSTALL_CMD="sudo apt install"
    REMOVE_CMD="sudo apt remove"
    INSTALLED_LIST=$(dpkg-query -W -f='${Package}\n')
    ;;
  pacman)
    LIST_CMD="pacman -Slq"
    INFO_CMD="pacman -Si {1}"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    REMOVE_CMD="sudo pacman -R --noconfirm"
    INSTALLED_LIST=$(pacman -Qq)
    ;;
  dnf)
    LIST_CMD="dnf list available | awk '{print \$1}'"
    INFO_CMD="dnf info {1}"
    INSTALL_CMD="sudo dnf install -y"
    REMOVE_CMD="sudo dnf remove -y"
    INSTALLED_LIST=$(dnf list installed | awk '{print $1}')
    ;;
  zypper)
    LIST_CMD="zypper se -s | awk 'NR>2 {print \$2; print \$3}' | grep -v '^[|]' | sort -u"
    INFO_CMD="zypper info {1}"
    INSTALL_CMD="sudo zypper install -y"
    REMOVE_CMD="sudo zypper remove -y"
    INSTALLED_LIST=$(rpm -qa --qf '%{NAME}\n')
    ;;
  apk)
    LIST_CMD="apk search -v | awk '{print \$1}'"
    INFO_CMD="apk info -d {1}"
    INSTALL_CMD="sudo apk add"
    REMOVE_CMD="sudo apk del"
    INSTALLED_LIST=$(apk info)
    ;;
  eopkg)
    LIST_CMD="eopkg list-available | awk '{print \$1}'"
    INFO_CMD="eopkg info {1}"
    INSTALL_CMD="sudo eopkg install -y"
    REMOVE_CMD="sudo eopkg remove -y"
    INSTALLED_LIST=$(eopkg list-installed | awk '{print $1}')
    ;;
  xbps-install)
    LIST_CMD="xbps-query -Rs '' | awk '{print \$2}'"
    INFO_CMD="xbps-query -RS {1}"
    INSTALL_CMD="sudo xbps-install -y"
    REMOVE_CMD="sudo xbps-remove -y"
    INSTALLED_LIST=$(xbps-query -l | awk '{print $2}')
    ;;
  none)
    echo "❌ No supported package manager found (apt, pacman, dnf, zypper, apk, eopkg, xbps)."
    exit 1
    ;;
esac

# Build installed hash set (skip empty lines)
declare -A installed
while read -r pkg; do
  [[ -n "$pkg" ]] && installed["$pkg"]=1
done <<< "$INSTALLED_LIST"

# Package list function
list_names() {
  eval "$LIST_CMD" | sort | while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if [[ -n ${installed[$pkg]} ]]; then
      printf "\033[32m%s ✅\033[0m\n" "$pkg"
    else
      echo "$pkg"
    fi
  done
}

# fzf args
fzf_args=(
  --multi
  --ansi
  --exact
  --tiebreak=begin,length
  --preview "$INFO_CMD"
  --preview-window 'down:30%:wrap'
  --bind 'enter:execute-silent(echo {+1} > /tmp/pkg-tui-action && echo install > /tmp/pkg-tui-mode)+accept,alt-i:execute-silent(echo {+1} > /tmp/pkg-tui-action && echo install > /tmp/pkg-tui-mode)+accept,alt-r:execute-silent(echo {+1} > /tmp/pkg-tui-action && echo remove > /tmp/pkg-tui-mode)+accept'
  --header "🔎 $PKG_MGR Package Manager | Enter/Alt-i: Install | Alt-r: Remove"
  --color 'pointer:green,marker:green'
)

# Run fzf
pkg=$(list_names | fzf "${fzf_args[@]}")

if [[ -s /tmp/pkg-tui-action && -s /tmp/pkg-tui-mode ]]; then
  pkg_names=$(sed 's/ ✅//; s/\x1b\[[0-9;]*m//g' /tmp/pkg-tui-action | awk '{print $1}' | tr '\n' ' ')
  action=$(cat /tmp/pkg-tui-mode)

  case "$action" in
    install)
      echo "➡️ Installing: $pkg_names"
      $INSTALL_CMD $pkg_names
      ;;
    remove)
      echo "🗑️ Removing: $pkg_names"
      $REMOVE_CMD $pkg_names
      ;;
  esac

  rm -f /tmp/pkg-tui-action /tmp/pkg-tui-mode

  if command -v notify-send >/dev/null; then
    notify-send "pkg-tui" "Action '$action' complete for: $pkg_names"
  else
    echo "✅ Action '$action' complete for: $pkg_names"
  fi
fi
EOF

    "$ESCALATION_TOOL" mv "$tmpfile" /usr/local/bin/pkg-tui
    "$ESCALATION_TOOL" chmod +x /usr/local/bin/pkg-tui
    printf "%b\n" "${GREEN}pkg-tui script installed to /usr/local/bin/pkg-tui${RC}"
}

addAlias() {
    if ! grep -q "alias pfind=" "$HOME/.bashrc"; then
        echo "alias pfind='pkg-tui'" >> "$HOME/.bashrc"
        printf "%b\n" "${GREEN}Alias 'pfind' added to .bashrc${RC}"
    else
        printf "%b\n" "${CYAN}Alias 'pfind' already exists in .bashrc${RC}"
    fi

    printf "%b\n" "${GREEN}pkg-tui installation complete.${RC}"
    printf "%b\n" "${CYAN}Run 'pfind' or 'pkg-tui' to start.${RC}"
}

# Main
checkEnv
checkEscalationTool
installDependencies
buildPkgTui
addAlias