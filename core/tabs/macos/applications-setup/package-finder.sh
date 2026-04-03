#!/bin/sh -e

. ../common-script.sh

installDependencies() {
    printf "%b\n" "${YELLOW}Installing dependencies for pkg-tui (fzf, curl)...${RC}"
    ensureHomebrewAvailable
    brew install fzf curl
    printf "%b\n" "${GREEN}Dependencies installed.${RC}"
}

buildPkgTui() {
    printf "%b\n" "${YELLOW}Building pkg-tui script (Homebrew)...${RC}"
    tmpfile=$(mktemp)
    cat > "$tmpfile" <<"EOF"
#!/bin/sh
set -e

# Prefer Homebrew on Apple Silicon or Intel default paths
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export HOMEBREW_NO_AUTO_UPDATE=1

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

# $1 = fzf line; uses brew info / brew info --cask (no single INFO_CMD — casks use a prefix)
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
  case "$pkg_name" in
    cask/*)
      brew info --cask "${pkg_name#cask/}" > "$tmp_file" 2>&1 || true
      ;;
    *)
      brew info "$pkg_name" > "$tmp_file" 2>&1 || true
      ;;
  esac
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

PKG_MGR="brew"
# brew formulae / brew casks read local tap metadata (fast). cask/* distinguishes GUI casks from formula names.
LIST_CMD='{ brew formulae 2>/dev/null; brew casks 2>/dev/null | sed "s/^/cask\//"; }'
INSTALLED_CMD='{ brew list --formula -1 2>/dev/null; brew list --cask -1 2>/dev/null | sed "s/^/cask\//"; }'

CACHE_TTL_SECONDS="${PKG_TUI_CACHE_TTL_SECONDS:-3600}"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/Library/Caches}/pkg-tui"
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
      _reload_payload=$(printf 'reload-sync(sh %s)+change-header(🔎 %s | list updated | Enter/Alt-i: brew install | Alt-r: uninstall | Ctrl-r: Refresh)' "$PKG_TUI_MERGER" "$PKG_TUI_PKG_MGR")
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

ACTION_BASE="${TMPDIR:-/tmp}"
ACTION_DIR=$(mktemp -d "${ACTION_BASE}/pkg-tui-act.XXXXXX" 2>/dev/null || mktemp -d /tmp/pkg-tui-act.XXXXXX)
ACTION_FILE="$ACTION_DIR/selection"
MODE_FILE="$ACTION_DIR/mode"
trap 'rm -rf "$ACTION_DIR"' EXIT INT HUP

export CACHE_DIR CACHE_TTL_SECONDS LIST_CACHE_FILE INSTALLED_CACHE_FILE
export PKG_TUI_LIST_CACHE="$LIST_CACHE_FILE"
export PKG_TUI_INSTALLED_CACHE="$INSTALLED_CACHE_FILE"
export PKG_TUI_LIST_CMD="$LIST_CMD"
export PKG_TUI_INSTALLED_CMD="$INSTALLED_CMD"
export PKG_TUI_FZF_URL
export PKG_TUI_MERGER="$MERGER_SCRIPT"
export PKG_TUI_PKG_MGR="$PKG_MGR"

MYSELF=$(command -v "$0" 2>/dev/null || printf '%s\n' "$0")

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
  --bind "ctrl-r:reload-sync(sh ${MERGER_SCRIPT})+change-header(🔎 ${PKG_MGR} | refreshed | Enter/Alt-i: install | Alt-r: uninstall | Ctrl-r: Refresh)" \
  --bind "start:execute-silent((sleep 0.2; nice -n 19 \"${MYSELF}\" --refresh-worker) &)" \
  --header "🔎 ${PKG_MGR} formulae + casks (cask/*) | Enter/Alt-i: install | Alt-r: uninstall | Ctrl-r: Refresh | updating list…" \
  --color 'pointer:green,marker:green' || true

if [ -s "$ACTION_FILE" ] && [ -s "$MODE_FILE" ]; then
  pkg_names=$(sed 's/ ✅//; s/\x1b\[[0-9;]*m//g' "$ACTION_FILE" | awk '{print $1}' | tr '\n' ' ')
  action=$(cat "$MODE_FILE")

  for _pkg in $pkg_names; do
    case "$action" in
      install)
        case "$_pkg" in
          cask/*) echo "➡️ brew install --cask ${_pkg#cask/}"; brew install --cask "${_pkg#cask/}" ;;
          *) echo "➡️ brew install $_pkg"; brew install "$_pkg" ;;
        esac
        ;;
      remove)
        case "$_pkg" in
          cask/*) echo "🗑️ brew uninstall --cask ${_pkg#cask/}"; brew uninstall --cask "${_pkg#cask/}" ;;
          *) echo "🗑️ brew uninstall $_pkg"; brew uninstall "$_pkg" ;;
        esac
        ;;
    esac
  done
  invalidate_pkg_cache

  rm -f "$ACTION_FILE" "$MODE_FILE"

  echo "✅ Action '$action' complete for: $pkg_names"

  exit 0
fi

exit 0
EOF

    ensureHomebrewAvailable
    BREW_BIN="$(brew --prefix)/bin"
    mkdir -p "$BREW_BIN"
    mv "$tmpfile" "$BREW_BIN/pkg-tui"
    chmod +x "$BREW_BIN/pkg-tui"
    printf "%b\n" "${GREEN}pkg-tui installed to ${BREW_BIN}/pkg-tui${RC}"
}

addAlias() {
    if [ -f "$HOME/.zshrc" ] && ! grep -q "alias pfind=" "$HOME/.zshrc" 2>/dev/null; then
        echo "alias pfind='pkg-tui'" >> "$HOME/.zshrc"
        printf "%b\n" "${GREEN}Alias 'pfind' added to .zshrc${RC}"
    elif [ -f "$HOME/.bashrc" ] && ! grep -q "alias pfind=" "$HOME/.bashrc" 2>/dev/null; then
        echo "alias pfind='pkg-tui'" >> "$HOME/.bashrc"
        printf "%b\n" "${GREEN}Alias 'pfind' added to .bashrc${RC}"
    else
        printf "%b\n" "${CYAN}Alias 'pfind' already exists or no shell rc found${RC}"
    fi

    printf "%b\n" "${GREEN}pkg-tui installation complete.${RC}"
    printf "%b\n" "${CYAN}Run 'pfind' or 'pkg-tui' to start.${RC}"
}

# Main
checkEnv
installDependencies
buildPkgTui
# addAlias
