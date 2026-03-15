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
        moss)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf bash uutils-coreutils
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy fzf bash coreutils
            ;;
        rpm-ostree)
            "$ESCALATION_TOOL" "$PACKAGER" install --allow-inactive fzf bash coreutils
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
  if [ -f /run/ostree-booted ] && command -v rpm-ostree >/dev/null 2>&1; then
    echo "rpm-ostree"
    return
  fi
  for mgr in nala apt yay pacman dnf zypper apk eopkg xbps-install pkg moss; do
    if command -v "$mgr" >/dev/null 2>&1; then
      echo "$mgr"
      return
    fi
  done
  echo "none"
}

detect_escalation_tool() {
  if [ "$(id -u)" = "0" ]; then
    echo "eval"
    return
  fi

  for tool in sudo-rs sudo doas; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "$tool"
      return
    fi
  done

  echo "sudo"
}

PKG_MGR=$(detect_pkg_mgr)
ESCALATION_TOOL=$(detect_escalation_tool)

case "$PKG_MGR" in
  nala)
    LIST_CMD="apt-cache pkgnames"
    INFO_CMD="nala show {1} 2>/dev/null"
    INSTALL_CMD="$ESCALATION_TOOL nala install -y"
    REMOVE_CMD="$ESCALATION_TOOL nala remove -y"
    INSTALLED_CMD="dpkg-query -W -f='\${Package}\n'"
    ;;
  apt)
    LIST_CMD="apt-cache pkgnames"
    INFO_CMD="apt show {1} 2>/dev/null"
    INSTALL_CMD="$ESCALATION_TOOL apt install -y"
    REMOVE_CMD="$ESCALATION_TOOL apt autoremove -y"
    INSTALLED_CMD="dpkg-query -W -f='\${Package}\n'"
    ;;
  yay)
    LIST_CMD="yay -Slq"
    INFO_CMD="yay -Si {1}"
    INSTALL_CMD="yay -S --noconfirm"
    REMOVE_CMD="yay -R --noconfirm"
    INSTALLED_CMD="yay -Qq"
    ;;
  pacman)
    LIST_CMD="pacman -Slq"
    INFO_CMD="pacman -Si {1}"
    INSTALL_CMD="$ESCALATION_TOOL pacman -S --noconfirm"
    REMOVE_CMD="$ESCALATION_TOOL pacman -R --noconfirm"
    INSTALLED_CMD="pacman -Qq"
    ;;
  dnf)
    LIST_CMD="dnf repoquery --qf '%{name}\n' --quiet"
    INFO_CMD="dnf info {1}"
    INSTALL_CMD="$ESCALATION_TOOL dnf install -y"
    REMOVE_CMD="$ESCALATION_TOOL dnf remove -y"
    INSTALLED_CMD="rpm -qa --qf '%{NAME}\n'"
    ;;
  rpm-ostree)
    LIST_CMD="rpm -qa --qf '%{NAME}\n'"
    INFO_CMD="rpm-ostree search {1}"
    INSTALL_CMD="$ESCALATION_TOOL rpm-ostree install"
    REMOVE_CMD="$ESCALATION_TOOL rpm-ostree uninstall"
    INSTALLED_CMD="rpm -qa --qf '%{NAME}\n'"
    ;;
  zypper)
    LIST_CMD="zypper se -s | awk 'NR>2 {print \$2; print \$3}' | grep -v '^[|]' | sort -u"
    INFO_CMD="zypper info {1}"
    INSTALL_CMD="$ESCALATION_TOOL zypper install -y"
    REMOVE_CMD="$ESCALATION_TOOL zypper remove -y"
    INSTALLED_CMD="rpm -qa --qf '%{NAME}\n'"
    ;;
  apk)
    LIST_CMD="apk search -v | awk -F'-[0-9]' '{print \$1}'"
    INFO_CMD="apk info -d {1}"
    INSTALL_CMD="$ESCALATION_TOOL apk add"
    REMOVE_CMD="$ESCALATION_TOOL apk del"
    INSTALLED_CMD="apk info | awk -F'-[0-9]' '{print \$1}'"
    ;;
  eopkg)
    LIST_CMD="eopkg list-available \
  | sed -r 's/\x1B\[[0-9;]*m//g' \
  | awk 'NF>0 && !/Repository/ && !/^Installed packages/ { sub(/^[ \t]+/, \"\"); print \$1 }'"
    INFO_CMD="eopkg info {1}"
    INSTALL_CMD="$ESCALATION_TOOL eopkg install -y"
    REMOVE_CMD="$ESCALATION_TOOL eopkg remove -y"
    INSTALLED_CMD="eopkg list-installed | awk '{print \$1}'"
    ;;
  moss)
    LIST_CMD="moss list available"
    INFO_CMD="moss info {1}"
    INSTALL_CMD="$ESCALATION_TOOL moss install -y"
    REMOVE_CMD="$ESCALATION_TOOL moss remove -y"
    INSTALLED_CMD="moss list installed | awk '{print \$1}'"
    ;;
  xbps-install)
    LIST_CMD="xbps-query -Rs '' | awk '{print \$2}'"
    INFO_CMD="xbps-query -RS {1}"
    INSTALL_CMD="$ESCALATION_TOOL xbps-install -y"
    REMOVE_CMD="$ESCALATION_TOOL xbps-remove -y"
    INSTALLED_CMD="xbps-query -l | awk '{print \$2}'"
    ;;
  pkg)
    LIST_CMD="pkg search . | awk '{print \$1}'"
    INFO_CMD="pkg info {1}"
    INSTALL_CMD="$ESCALATION_TOOL pkg install -y"
    REMOVE_CMD="$ESCALATION_TOOL pkg remove -y"
    INSTALLED_CMD="pkg query -a '%n'"
    ;;
  none)
    echo "❌ No supported package manager found (apt, pacman, dnf, rpm-ostree, zypper, apk, eopkg, xbps, pkg)."
    exit 1
    ;;
esac

CACHE_TTL_SECONDS="${PKG_TUI_CACHE_TTL_SECONDS:-3600}"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/pkg-tui"
CACHE_DIR="$CACHE_ROOT/$PKG_MGR"
LIST_CACHE_FILE="$CACHE_DIR/package-list.cache"
INSTALLED_CACHE_FILE="$CACHE_DIR/installed-list.cache"
mkdir -p "$CACHE_DIR"

cache_file_is_fresh() {
  local file="$1"
  [[ -s "$file" ]] || return 1
  [[ "$CACHE_TTL_SECONDS" -gt 0 ]] || return 1

  local now mtime age
  now=$(date +%s)
  mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
  age=$((now - mtime))

  (( age < CACHE_TTL_SECONDS ))
}

populate_pkg_cache() {
  local cache_file="$1"
  local cache_cmd="$2"
  local tmp_file="${cache_file}.tmp"

  if cache_file_is_fresh "$cache_file"; then
    return 0
  fi

  eval "$cache_cmd" 2>/dev/null \
    | sed -r 's/\x1B\[[0-9;]*m//g' \
    | awk 'NF>0 { sub(/^[ \t]+/, ""); sub(/[ \t]+$/, ""); print $1 }' \
    | sort -u > "$tmp_file"

  if [[ -s "$tmp_file" ]]; then
    mv "$tmp_file" "$cache_file"
  else
    rm -f "$tmp_file"
    [[ -f "$cache_file" ]] || : > "$cache_file"
  fi
}

invalidate_pkg_cache() {
  rm -f "$LIST_CACHE_FILE" "$INSTALLED_CACHE_FILE" "$CACHE_DIR"/info-*.cache 2>/dev/null || true
}

preview_pkg_info() {
  local raw_name="$1"
  local pkg_name cache_key info_cache_file tmp_file info_cmd

  pkg_name=$(
    printf '%s\n' "$raw_name" \
      | sed 's/\x1B\[[0-9;]*m//g; s/✅//g' \
      | awk 'NF>0 {print $1}'
  )
  [[ -n "$pkg_name" ]] || exit 0

  cache_key=$(printf '%s' "$pkg_name" | tr -c '[:alnum:]._-' '_')
  info_cache_file="$CACHE_DIR/info-${cache_key}.cache"
  tmp_file="${info_cache_file}.tmp"

  if ! cache_file_is_fresh "$info_cache_file"; then
    info_cmd="${INFO_CMD//\{1\}/$pkg_name}"
    eval "$info_cmd" > "$tmp_file" 2>&1 || true
    if [[ -s "$tmp_file" ]]; then
      mv "$tmp_file" "$info_cache_file"
    else
      printf "No package information available for %s\n" "$pkg_name" > "$info_cache_file"
      rm -f "$tmp_file"
    fi
  fi

  cat "$info_cache_file"
}

populate_pkg_cache "$LIST_CACHE_FILE" "$LIST_CMD"
populate_pkg_cache "$INSTALLED_CACHE_FILE" "$INSTALLED_CMD"

declare -A installed
while read -r pkg; do
  [[ -n "$pkg" ]] && installed["$pkg"]=1
done < "$INSTALLED_CACHE_FILE"

# Package list function
list_names() {
  while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if [[ -n ${installed[$pkg]} ]]; then
      printf "\033[32m%s ✅\033[0m\n" "$pkg"
    else
      echo "$pkg"
    fi
  done < "$LIST_CACHE_FILE"
}

export INFO_CMD CACHE_DIR CACHE_TTL_SECONDS
export -f cache_file_is_fresh preview_pkg_info

# fzf args
fzf_args=(
  --multi
  --ansi
  --exact
  --tiebreak=begin,length
  --preview 'bash -c '\''preview_pkg_info "$1"'\'' _ {1}'
  --preview-window 'down:30%:wrap'
  --bind 'enter:execute-silent(sh -c '\''cat > /tmp/pkg-tui-action'\'' <<<"{+1}" && echo install > /tmp/pkg-tui-mode)+accept'
  --bind 'alt-i:execute-silent(sh -c '\''cat > /tmp/pkg-tui-action'\'' <<<"{+1}" && echo install > /tmp/pkg-tui-mode)+accept'
  --bind 'alt-r:execute-silent(sh -c '\''cat > /tmp/pkg-tui-action'\'' <<<"{+1}" && echo remove > /tmp/pkg-tui-mode)+accept'
  --header "🔎 $PKG_MGR | Enter/Alt-i: Install | Alt-r: Remove"
  --color 'pointer:green,marker:green'
)

# Run fzf
pkg=$(list_names | fzf "${fzf_args[@]}")

if [[ -s /tmp/pkg-tui-action && -s /tmp/pkg-tui-mode ]]; then
  pkg_names=$(sed 's/ ✅//; s/\x1b\[[0-9;]*m//g' /tmp/pkg-tui-action | awk '{print $1}' | tr -d '"'"'" | tr '\n' ' ')
  action=$(cat /tmp/pkg-tui-mode)

  case "$action" in
    install)
      echo "➡️ Installing: $pkg_names"
      $INSTALL_CMD $pkg_names
      invalidate_pkg_cache
      ;;
    remove)
      echo "🗑️ Removing: $pkg_names"
      $REMOVE_CMD $pkg_names
      invalidate_pkg_cache
      ;;
  esac

  rm -f /tmp/pkg-tui-action /tmp/pkg-tui-mode

  echo "✅ Action '$action' complete for: $pkg_names"
  
  exit 0
fi

# Exit if no packages were selected
exit 0
EOF

    if [ "$PACKAGER" = "eopkg" ] || [ "$PACKAGER" = "moss" ] || [ "$PACKAGER" = "rpm-ostree" ]; then
        "$ESCALATION_TOOL" mv "$tmpfile" /usr/bin/pkg-tui
        "$ESCALATION_TOOL" chmod +x /usr/bin/pkg-tui
        printf "%b\n" "${GREEN}pkg-tui script installed to /usr/bin/pkg-tui${RC}"
    else
        "$ESCALATION_TOOL" mv "$tmpfile" /usr/local/bin/pkg-tui
        "$ESCALATION_TOOL" chmod +x /usr/local/bin/pkg-tui
        printf "%b\n" "${GREEN}pkg-tui script installed to /usr/local/bin/pkg-tui${RC}"
    fi
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
# addAlias