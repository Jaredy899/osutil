#!/bin/sh -e

. ../common-script.sh

installRuby() {
    printf "%b\n" "${YELLOW}Installing Ruby (via Homebrew)...${RC}"
    if brewprogram_exists ruby; then
        printf "%b\n" "${GREEN}Ruby already installed. Skipping.${RC}"
        return 0
    fi
    if ! brew install ruby; then
        printf "%b\n" "${RED}Failed to install Ruby with Homebrew.${RC}"
        exit 1
    fi

    SHELL_RC="${HOME}/.zshrc"
    if ! grep -q 'opt/homebrew/opt/ruby/bin' "$SHELL_RC" 2>/dev/null && \
       ! grep -q 'usr/local/opt/ruby/bin' "$SHELL_RC" 2>/dev/null; then
        {
            printf "%s\n" ''
            cat <<'RCAPPEND'
# Ensure Homebrew Ruby is preferred
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
elif [ -d "/usr/local/opt/ruby/bin" ]; then
  export PATH="/usr/local/opt/ruby/bin:$PATH"
fi
RCAPPEND
        } >> "$SHELL_RC"
    fi

    printf "%b\n" "${GREEN}Ruby installed. Verify with: ruby --version${RC}"
}

checkEnv
installRuby


