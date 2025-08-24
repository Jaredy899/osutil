#!/bin/sh -e

. ../common-script.sh

installJava() {
    printf "%b\n" "${YELLOW}Installing OpenJDK...${RC}"

    # Install OpenJDK (prefer version 21, fallback to 17)
    if "$ESCALATION_TOOL" "$PACKAGER" search openjdk21 2>/dev/null | grep -q openjdk21; then
        printf "%b\n" "${CYAN}Installing OpenJDK 21...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" install -y openjdk21
        JAVA_HOME="/usr/local/openjdk21"
    elif "$ESCALATION_TOOL" "$PACKAGER" search openjdk17 2>/dev/null | grep -q openjdk17; then
        printf "%b\n" "${CYAN}Installing OpenJDK 17...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" install -y openjdk17
        JAVA_HOME="/usr/local/openjdk17"
    else
        printf "%b\n" "${CYAN}Installing latest available OpenJDK...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" install -y openjdk
        JAVA_HOME="/usr/local/openjdk"
    fi

    # Set JAVA_HOME in shell profile
    if ! grep -q "JAVA_HOME" "$HOME/.bashrc" 2>/dev/null; then
        {
            printf "%s\n" ''
            printf "%s\n" "export JAVA_HOME=\"$JAVA_HOME\""
            printf "%s\n" 'export PATH="$JAVA_HOME/bin:$PATH"'
        } >> "$HOME/.bashrc"
    fi

    # Add to current session
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"

    printf "%b\n" "${GREEN}Java installed successfully!${RC}"
    printf "%b\n" "${CYAN}Java version: $(java -version 2>&1 | head -n1)${RC}"
    printf "%b\n" "${CYAN}JAVA_HOME: $JAVA_HOME${RC}"
}

checkEnv
installJava
