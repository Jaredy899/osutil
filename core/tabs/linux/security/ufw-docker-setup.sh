#!/bin/sh -e

. ../common-script.sh

installUfwDocker() {
    if ! command_exists ufw-docker; then
        printf "%b\n" "${YELLOW}Installing ufw-docker...${RC}"
        
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ufw-docker
                ;;
            *)
                # Download ufw-docker script for other distributions
                "$ESCALATION_TOOL" wget -O /usr/local/bin/ufw-docker \
                    https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
                
                # Make it executable
                "$ESCALATION_TOOL" chmod +x /usr/local/bin/ufw-docker
                ;;
        esac
        
        printf "%b\n" "${GREEN}ufw-docker installed successfully${RC}"
    else
        printf "%b\n" "${GREEN}ufw-docker is already installed${RC}"
    fi
}

checkDocker() {
    if ! command_exists docker; then
        printf "%b\n" "${RED}Docker is not installed. ufw-docker requires Docker to be installed first.${RC}"
        printf "%b\n" "${YELLOW}Please install Docker before running this script.${RC}"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        printf "%b\n" "${RED}Docker daemon is not running. Please start Docker service first.${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Docker is installed and running${RC}"
}

checkUfw() {
    if ! command_exists ufw; then
        printf "%b\n" "${RED}UFW is not installed. Please install UFW first using the ufw-baselines.sh script.${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}UFW is installed${RC}"
}

configureUfwDocker() {
    printf "%b\n" "${YELLOW}Configuring ufw-docker integration...${RC}"
    
    # Install ufw-docker rules
    printf "%b\n" "${YELLOW}Installing ufw-docker firewall rules...${RC}"
    "$ESCALATION_TOOL" ufw-docker install
    
    printf "%b\n" "${GREEN}ufw-docker configuration completed!${RC}"
    printf "%b\n" "${CYAN}You can now use ufw-docker commands to manage container firewall rules.${RC}"
    printf "%b\n" "${CYAN}Examples:${RC}"
    printf "%b\n" "${CYAN}  ufw-docker allow <container> <port>${RC}"
    printf "%b\n" "${CYAN}  ufw-docker list <container>${RC}"
    printf "%b\n" "${CYAN}  ufw-docker status${RC}"
}

showUsage() {
    printf "%b\n" "${CYAN}ufw-docker Usage Examples:${RC}"
    printf "%b\n" "${CYAN}========================${RC}"
    printf "%b\n" "${CYAN}Check status:${RC}"
    printf "%b\n" "${CYAN}  ufw-docker status${RC}"
    printf "%b\n" "${CYAN}${RC}"
    printf "%b\n" "${CYAN}Allow container port:${RC}"
    printf "%b\n" "${CYAN}  ufw-docker allow httpd 80${RC}"
    printf "%b\n" "${CYAN}  ufw-docker allow nginx 443/tcp${RC}"
    printf "%b\n" "${CYAN}${RC}"
    printf "%b\n" "${CYAN}List container rules:${RC}"
    printf "%b\n" "${CYAN}  ufw-docker list httpd${RC}"
    printf "%b\n" "${CYAN}${RC}"
    printf "%b\n" "${CYAN}Delete container rules:${RC}"
    printf "%b\n" "${CYAN}  ufw-docker delete allow httpd${RC}"
    printf "%b\n" "${CYAN}  ufw-docker delete allow httpd 80/tcp${RC}"
    printf "%b\n" "${CYAN}${RC}"
    printf "%b\n" "${CYAN}For Docker Swarm services:${RC}"
    printf "%b\n" "${CYAN}  ufw-docker service allow web 80${RC}"
    printf "%b\n" "${CYAN}  ufw-docker service delete allow web${RC}"
}

checkEnv
checkEscalationTool
checkDocker
checkUfw
installUfwDocker
configureUfwDocker
showUsage
