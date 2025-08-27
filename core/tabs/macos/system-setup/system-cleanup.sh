#!/bin/sh

. ../common-script.sh

cleanup_system() {
    printf "%b\n" "${YELLOW}Performing macOS system cleanup...${RC}"
    
    # Fix Mission Control to NEVER rearrange spaces
    printf "%b\n" "${CYAN}Fixing Mission Control to never rearrange spaces...${RC}"
    "$ESCALATION_TOOL" defaults write com.apple.dock mru-spaces -bool false

    # Disable Apple Intelligence features (if present)
    printf "%b\n" "${CYAN}Disabling Apple Intelligence features...${RC}"
    "$ESCALATION_TOOL" defaults write com.apple.CloudSubscriptionFeatures.optIn "545129924" -bool "false" || true
    
    # Homebrew cleanup
    if command_exists "brew"; then
        printf "%b\n" "${CYAN}Cleaning Homebrew cache and removing old versions...${RC}"
        brew cleanup --prune=all || true
        brew autoremove || true
        brew doctor || true
    fi
    
    # Clean system + user caches
    printf "%b\n" "${CYAN}Cleaning caches...${RC}"
    "$ESCALATION_TOOL" rm -rf /Library/Caches/* 2>/dev/null || true
    rm -rf ~/Library/Caches/* 2>/dev/null || true
    
    # Clean Xcode derived data
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        printf "%b\n" "${CYAN}Cleaning Xcode derived data...${RC}"
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
    fi
    
# Clean iOS Simulator caches
if [ -d ~/Library/Developer/CoreSimulator ]; then
    printf "%b\n" "${CYAN}Cleaning iOS Simulator caches...${RC}"
    rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/var/mobile/Media/DCIM/* 2>/dev/null || true
    rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/var/mobile/Media/PhotoData/* 2>/dev/null || true
fi
    
    # Remove old logs
    printf "%b\n" "${CYAN}Removing old log files...${RC}"
    "$ESCALATION_TOOL" find /var/log -type f -mtime +30 -delete 2>/dev/null || true
}

common_cleanup() {
    printf "%b\n" "${CYAN}Performing common cleanup tasks...${RC}"
    
    # Clean /tmp and /var/tmp
    "$ESCALATION_TOOL" find /tmp -type f -atime +5 -delete 2>/dev/null || true
    "$ESCALATION_TOOL" find /var/tmp -type f -atime +5 -delete 2>/dev/null || true
    
    # Clean system logs (keep last 7 days)
    "$ESCALATION_TOOL" find /var/log -name "*.log.*" -mtime +7 -delete 2>/dev/null || true
    "$ESCALATION_TOOL" find /var/log -name "*.gz" -mtime +30 -delete 2>/dev/null || true
    
    # Flush DNS cache
    printf "%b\n" "${CYAN}Flushing DNS cache...${RC}"
    "$ESCALATION_TOOL" dscacheutil -flushcache
    "$ESCALATION_TOOL" killall -HUP mDNSResponder 2>/dev/null || true
}

clean_data() {
    printf "%b" "${YELLOW}Clean up user caches, trash? (y/N): ${RC}"
    read -r clean_response
    case $clean_response in
        y|Y)
            printf "%b\n" "${CYAN}Cleaning user caches and trash...${RC}"
            rm -rf ~/.Trash/* /Volumes/*/.Trashes/* 2>/dev/null || true
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping user data cleanup.${RC}"
            ;;
    esac
}

clean_docker() {
    if command_exists "docker"; then
        printf "%b" "${YELLOW}Clean up Docker system (containers, images, volumes)? (y/N): ${RC}"
        read -r docker_response
        case $docker_response in
            y|Y)
                docker system prune -a -f --volumes
                ;;
        esac
    fi
}

clean_node_modules() {
    printf "%b" "${YELLOW}Clean up node_modules directories (older than 30 days)? (y/N): ${RC}"
    read -r node_response
    case $node_response in
        y|Y)
            # Restrict search to ~/Projects for safety
            if [ -d "$HOME/Projects" ]; then
                find "$HOME/Projects" -name "node_modules" -type d -atime +30 -exec rm -rf {} + 2>/dev/null || true
            fi
            ;;
    esac
}

system_cleanup() {
    printf "%b\n" "${YELLOW}Performing comprehensive macOS system cleanup...${RC}"
    
    cleanup_system
    common_cleanup
    clean_data
    clean_docker
    clean_node_modules
    
    printf "%b\n" "${GREEN}macOS system cleanup completed!${RC}"
}

checkEnv
system_cleanup