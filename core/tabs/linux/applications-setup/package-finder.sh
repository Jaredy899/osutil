#!/bin/sh -e

. ../common-script.sh

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies for pkg-tui...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm fzf curl
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf curl
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf curl
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf curl
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add fzf curl
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf curl
            ;;
        moss)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fzf curl
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy fzf curl
            ;;
        rpm-ostree)
            "$ESCALATION_TOOL" "$PACKAGER" install --allow-inactive fzf curl
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
#!/bin/sh
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

write_lib_script() {
  _lib="$1"
  cat > "$_lib" <<'LIBEOF'
# Sourced by pkg-tui and preview subprocess (POSIX sh)
_cache_mtime() {
  _f="$1"
  if _m=$(stat -c %Y "$_f" 2>/dev/null); then
    printf %s "$_m"
  elif _m=$(stat -f %m "$_f" 2>/dev/null); then
    printf %s "$_m"
  else
    echo 0
  fi
}

cache_file_is_fresh() {
  _file="$1"
  [ -s "$_file" ] || return 1
  [ "$CACHE_TTL_SECONDS" -gt 0 ] || return 1
  _now=$(date +%s)
  _mtime=$(_cache_mtime "$_file")
  _age=$((_now - _mtime))
  [ "$_age" -lt "$CACHE_TTL_SECONDS" ]
}
LIBEOF
}

populate_pkg_cache() {
  _cache_file="$1"
  _cache_cmd="$2"
  _tmp_file="${_cache_file}.tmp"

  if cache_file_is_fresh "$_cache_file"; then
    return 0
  fi

  eval "$_cache_cmd" 2>/dev/null \
    | sed -E 's/\x1B\[[0-9;]*m//g' \
    | awk 'NF>0 { sub(/^[ \t]+/, ""); sub(/[ \t]+$/, ""); print $1 }' \
    | sort -u > "$_tmp_file"

  if [ -s "$_tmp_file" ]; then
    mv "$_tmp_file" "$_cache_file"
  else
    rm -f "$_tmp_file"
    [ -f "$_cache_file" ] || : > "$_cache_file"
  fi
}

populate_pkg_cache_force() {
  _cache_file="$1"
  _cache_cmd="$2"
  _tmp_file="${_cache_file}.tmp"

  eval "$_cache_cmd" 2>/dev/null \
    | sed -E 's/\x1B\[[0-9;]*m//g' \
    | awk 'NF>0 { sub(/^[ \t]+/, ""); sub(/[ \t]+$/, ""); print $1 }' \
    | sort -u > "$_tmp_file"

  if [ -s "$_tmp_file" ]; then
    mv "$_tmp_file" "$_cache_file"
  else
    rm -f "$_tmp_file"
    [ -f "$_cache_file" ] || : > "$_cache_file"
  fi
}

invalidate_pkg_cache() {
  rm -f "$LIST_CACHE_FILE" "$INSTALLED_CACHE_FILE" "$CACHE_DIR"/info-*.cache 2>/dev/null || true
}

write_merge_script() {
  _merger="$1"
  cat > "$_merger" <<MHEREDOC
#!/bin/sh
# Stream LIST line-by-line (no FNR==NR stall on installed file); fflush = line-buffered to fzf
exec awk -v instf="$INSTALLED_CACHE_FILE" 'BEGIN {
  while ((getline line < instf) > 0) {
    gsub(/^[ \t]+|[ \t]+$/, "", line)
    if (line != "") inst[line] = 1
  }
  close(instf)
}
NF > 0 {
  p = \$1
  gsub(/^[ \t]+|[ \t]+$/, "", p)
  if (p == "") next
  if (p in inst) printf "\\033[32m%s ✅\\033[0m\\n", p
  else print p
  fflush()
}' "$LIST_CACHE_FILE"
MHEREDOC
  chmod +x "$_merger"
}

# Written at runtime: dot-sources lib, $1 = fzf line (avoids broken sh -c quoting in --preview)
write_preview_script() {
  _out="$1"
  {
    printf '#!/bin/sh\n. "%s"\n' "$LIB_SCRIPT"
    cat <<'PREBODY'
raw="$1"
pkg_name=$(printf '%s\n' "$raw" | sed -E 's/\x1B\[[0-9;]*m//g; s/✅//g' | awk 'NF>0 {print $1}')
[ -n "$pkg_name" ] || exit 0
cache_key=$(printf '%s' "$pkg_name" | tr -c '[:alnum:]._-' '_')
info_cache_file="$CACHE_DIR/info-${cache_key}.cache"
tmp_file="${info_cache_file}.tmp"
if ! cache_file_is_fresh "$info_cache_file"; then
  info_cmd=$(printf '%s\n' "$INFO_CMD" | awk -v n="$pkg_name" '{ gsub(/\{1\}/, n); print }')
  eval "$info_cmd" > "$tmp_file" 2>&1 || true
  if [ -s "$tmp_file" ]; then
    mv "$tmp_file" "$info_cache_file"
  else
    printf "No package information available for %s\n" "$pkg_name" > "$info_cache_file"
    rm -f "$tmp_file"
  fi
fi
cat "$info_cache_file"
PREBODY
  } > "$_out"
  chmod +x "$_out"
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
  | sed -E 's/\x1B\[[0-9;]*m//g' \
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

LIB_SCRIPT="$CACHE_DIR/pkg-tui-lib.sh"
write_lib_script "$LIB_SCRIPT"
. "$LIB_SCRIPT"

case "$1" in
  --refresh-worker)
    sleep 0.05
    populate_pkg_cache_force "$PKG_TUI_LIST_CACHE" "$PKG_TUI_LIST_CMD"
    populate_pkg_cache_force "$PKG_TUI_INSTALLED_CACHE" "$PKG_TUI_INSTALLED_CMD"
    if [ -n "$PKG_TUI_FZF_URL" ] && command -v curl >/dev/null 2>&1; then
      _reload_payload=$(printf 'reload-sync(sh %s)+change-header(🔎 %s | list updated | Enter/Alt-i: Install | Alt-r: Remove | Ctrl-r: Refresh)' "$PKG_TUI_MERGER" "$PKG_TUI_PKG_MGR")
      curl -sS -g -X POST "$PKG_TUI_FZF_URL" --data-binary "$_reload_payload" >/dev/null 2>&1 || true
    fi
    exit 0
    ;;
esac

[ -f "$LIST_CACHE_FILE" ] || : > "$LIST_CACHE_FILE"
[ -f "$INSTALLED_CACHE_FILE" ] || : > "$INSTALLED_CACHE_FILE"

MERGER_SCRIPT="$CACHE_DIR/pkg-tui-merge-list.sh"
write_merge_script "$MERGER_SCRIPT"

PREVIEW_SCRIPT="$CACHE_DIR/pkg-tui-preview.sh"
write_preview_script "$PREVIEW_SCRIPT"

if command -v python3 >/dev/null 2>&1; then
  FZF_LISTEN_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()' 2>/dev/null) || FZF_LISTEN_PORT=
fi
if [ -z "$FZF_LISTEN_PORT" ]; then
  FZF_LISTEN_PORT=$((42000 + ($$ % 25000)))
fi
FZF_LISTEN_ADDR="127.0.0.1:${FZF_LISTEN_PORT}"
PKG_TUI_FZF_URL="http://${FZF_LISTEN_ADDR}/"

ACTION_BASE="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
ACTION_DIR=$(mktemp -d "${ACTION_BASE}/pkg-tui-act.XXXXXX" 2>/dev/null || mktemp -d /tmp/pkg-tui-act.XXXXXX)
ACTION_FILE="$ACTION_DIR/selection"
MODE_FILE="$ACTION_DIR/mode"
trap 'rm -rf "$ACTION_DIR"' EXIT INT HUP

export INFO_CMD CACHE_DIR CACHE_TTL_SECONDS LIST_CACHE_FILE INSTALLED_CACHE_FILE
export PKG_TUI_LIST_CACHE="$LIST_CACHE_FILE"
export PKG_TUI_INSTALLED_CACHE="$INSTALLED_CACHE_FILE"
export PKG_TUI_LIST_CMD="$LIST_CMD"
export PKG_TUI_INSTALLED_CMD="$INSTALLED_CMD"
export PKG_TUI_FZF_URL
export PKG_TUI_MERGER="$MERGER_SCRIPT"
export PKG_TUI_PKG_MGR="$PKG_MGR"

MYSELF=$(command -v "$0" 2>/dev/null || printf '%s\n' "$0")

# Feed fzf as soon as each line is ready (installed loaded in BEGIN; fflush avoids pipe block-buffering)
_pkg_tui_stream_list() {
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL awk -v instf="$INSTALLED_CACHE_FILE" 'BEGIN {
      while ((getline line < instf) > 0) {
        gsub(/^[ \t]+|[ \t]+$/, "", line)
        if (line != "") inst[line] = 1
      }
      close(instf)
    }
    NF > 0 {
      p = $1
      gsub(/^[ \t]+|[ \t]+$/, "", p)
      if (p == "") next
      if (p in inst) printf "\033[32m%s ✅\033[0m\n", p
      else print p
      fflush()
    }' "$LIST_CACHE_FILE"
  else
    awk -v instf="$INSTALLED_CACHE_FILE" 'BEGIN {
      while ((getline line < instf) > 0) {
        gsub(/^[ \t]+|[ \t]+$/, "", line)
        if (line != "") inst[line] = 1
      }
      close(instf)
    }
    NF > 0 {
      p = $1
      gsub(/^[ \t]+|[ \t]+$/, "", p)
      if (p == "") next
      if (p in inst) printf "\033[32m%s ✅\033[0m\n", p
      else print p
      fflush()
    }' "$LIST_CACHE_FILE"
  fi
}

_pkg_tui_stream_list | fzf --multi --ansi --exact \
  --tiebreak=begin,length \
  --listen="$FZF_LISTEN_ADDR" \
  --preview "\"${PREVIEW_SCRIPT}\" {}" \
  --preview-window 'down:30%:wrap' \
  --bind "enter:execute-silent(sh -c 'printf \"%s\\n\" \"{+1}\" > \"${ACTION_FILE}\" && echo install > \"${MODE_FILE}\"')+accept" \
  --bind "alt-i:execute-silent(sh -c 'printf \"%s\\n\" \"{+1}\" > \"${ACTION_FILE}\" && echo install > \"${MODE_FILE}\"')+accept" \
  --bind "alt-r:execute-silent(sh -c 'printf \"%s\\n\" \"{+1}\" > \"${ACTION_FILE}\" && echo remove > \"${MODE_FILE}\"')+accept" \
  --bind "ctrl-r:reload-sync(sh ${MERGER_SCRIPT})+change-header(🔎 ${PKG_MGR} | refreshed | Enter/Alt-i: Install | Alt-r: Remove | Ctrl-r: Refresh)" \
  --bind "start:execute-silent((sleep 0.2; nice -n 19 \"${MYSELF}\" --refresh-worker) &)" \
  --header "🔎 ${PKG_MGR} | Enter/Alt-i: Install | Alt-r: Remove | Ctrl-r: Refresh | updating list…" \
  --color 'pointer:green,marker:green' || true

if [ -s "$ACTION_FILE" ] && [ -s "$MODE_FILE" ]; then
  pkg_names=$(sed 's/ ✅//; s/\x1b\[[0-9;]*m//g' "$ACTION_FILE" | awk '{print $1}' | tr '\n' ' ')
  action=$(cat "$MODE_FILE")

  case "$action" in
    install)
      echo "➡️ Installing: $pkg_names"
      eval "$INSTALL_CMD $pkg_names"
      invalidate_pkg_cache
      ;;
    remove)
      echo "🗑️ Removing: $pkg_names"
      eval "$REMOVE_CMD $pkg_names"
      invalidate_pkg_cache
      ;;
  esac

  rm -f "$ACTION_FILE" "$MODE_FILE"

  echo "✅ Action '$action' complete for: $pkg_names"

  exit 0
fi

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
