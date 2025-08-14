#!/bin/sh -e

. ../common-script.sh

installJava() {
    printf "%b\n" "${YELLOW}Installing Java (OpenJDK via Homebrew)...${RC}"
    if brewprogram_exists java; then
        printf "%b\n" "${GREEN}Java already installed. Skipping.${RC}"
        return 0
    fi
    if ! brew install openjdk@21; then
        printf "%b\n" "${YELLOW}openjdk@21 failed, trying openjdk@17...${RC}"
        if ! brew install openjdk@17; then
            printf "%b\n" "${RED}Failed to install OpenJDK via Homebrew.${RC}"
            exit 1
        fi
    fi

    # Suggest path export for Apple JDK linking nuances
    if ! grep -q '/opt/homebrew/opt/openjdk@' "$HOME/.zshrc" 2>/dev/null && \
       ! grep -q '/usr/local/opt/openjdk@' "$HOME/.zshrc" 2>/dev/null; then
        {
            printf "%s\n" ''
            cat <<'RCAPPEND'
# Ensure Homebrew OpenJDK is on PATH for java/javac
if [ -d "/opt/homebrew/opt/openjdk@21" ]; then
  export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
  export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include:$CPPFLAGS"
elif [ -d "/opt/homebrew/opt/openjdk@17" ]; then
  export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
  export CPPFLAGS="-I/opt/homebrew/opt/openjdk@17/include:$CPPFLAGS"
fi
RCAPPEND
        } >> "$HOME/.zshrc"
    fi

    printf "%b\n" "${GREEN}Java (OpenJDK) installed.${RC}"
}

checkEnv
installJava


