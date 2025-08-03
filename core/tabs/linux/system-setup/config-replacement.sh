#!/bin/sh -e

. ../common-script.sh

# Configuration
BASE_URL="https://raw.githubusercontent.com/Jaredy899/linux/main/config_changes"
MYBASH_DIR="$HOME/.local/share/mybash"

download_file() {
    url="$1"
    dest="$2"
    desc="$3"
    
    printf "%b\n" "${YELLOW}Downloading $desc...${RC}"
    
    if curl -sSfL -o "$dest" "$url"; then
        printf "%b\n" "${GREEN}✓ $desc downloaded successfully${RC}"
    else
        printf "%b\n" "${RED}✗ Failed to download $desc${RC}"
        return 1
    fi
}

create_dir() {
    dir="$1"
    desc="$2"
    
    if mkdir -p "$dir"; then
        printf "%b\n" "${GREEN}✓ $desc directory created${RC}"
    else
        printf "%b\n" "${RED}✗ Failed to create $desc directory${RC}"
        return 1
    fi
}

replace_configs() {
    printf "%b\n" "${YELLOW}Starting configuration replacement process...${RC}"
    
    # Create necessary directories
    create_dir "$MYBASH_DIR" "MyBash"
    create_dir "$HOME/.config/fastfetch" "Fastfetch config"
    create_dir "$HOME/.config" "Config"
    
    # Handle Alpine Linux
    if [ -f /etc/alpine-release ]; then
        printf "%b\n" "${YELLOW}Processing Alpine Linux configuration...${RC}"
        download_file "$BASE_URL/profile" "/etc/profile" "Alpine profile"
        
        if command_exists apk; then
            printf "%b\n" "${YELLOW}Installing zoxide...${RC}"
            "$ESCALATION_TOOL" apk add --no-cache zoxide
        fi
    
    # Handle Solus
    elif [ "$DTYPE" = "solus" ]; then
        printf "%b\n" "${YELLOW}Processing Solus configuration...${RC}"
        download_file "$BASE_URL/.profile" "$HOME/.profile" "Solus profile"
        download_file "$BASE_URL/.bashrc" "$MYBASH_DIR/.bashrc" "Solus bashrc"
    
    # Handle other distributions
    else
        printf "%b\n" "${YELLOW}Processing standard Linux configuration...${RC}"
        download_file "$BASE_URL/.bashrc" "$MYBASH_DIR/.bashrc" "Standard bashrc"
    fi
    
    # Download common configuration files
    download_file "$BASE_URL/config.jsonc" "$HOME/.config/fastfetch/config.jsonc" "Fastfetch config"
    download_file "$BASE_URL/starship.toml" "$HOME/.config/starship.toml" "Starship config"
    
    printf "%b\n" "${GREEN}Configuration replacement process completed!${RC}"
}

checkEnv
checkEscalationTool
replace_configs 