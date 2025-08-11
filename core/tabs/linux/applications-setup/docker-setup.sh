#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

choose_installation() {
    printf "%b\n" "${YELLOW}Choose what to install:${RC}"
    printf "%b\n" "1. ${YELLOW}Only Docker${RC}"
    printf "%b\n" "2. ${YELLOW}Docker + Dockge${RC}"
    printf "%b\n" "3. ${YELLOW}Docker + Portainer${RC}"
    printf "%b\n" "4. ${YELLOW}Docker + Dockge + Portainer${RC}"
    printf "%b" "Enter your choice [1-4]: "
    read -r CHOICE

    case "$CHOICE" in
        1) INSTALL_DOCKER=1; INSTALL_DOCKGE=0; INSTALL_PORTAINER=0 ;;
        2) INSTALL_DOCKER=1; INSTALL_DOCKGE=1; INSTALL_PORTAINER=0 ;;
        3) INSTALL_DOCKER=1; INSTALL_DOCKGE=0; INSTALL_PORTAINER=1 ;;
        4) INSTALL_DOCKER=1; INSTALL_DOCKGE=1; INSTALL_PORTAINER=1 ;;
        *) printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"; exit 1 ;;
    esac
}

install_docker() {
    if ! command_exists docker; then
        printf "%b\n" "${YELLOW}Installing Docker...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed docker docker-compose
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy docker docker-compose
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y docker docker-compose docker-compose-switch
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y docker docker-compose
                ;;
            apk)
                "$ESCALATION_TOOL" apk add --no-cache --update-cache \
                    --repository http://dl-cdn.alpinelinux.org/alpine/latest-stable/community \
                    docker docker-compose
                ;;
            dnf)
                if [ "$DTYPE" = "rocky" ] || [ "$DTYPE" = "almalinux" ]; then
                    "$ESCALATION_TOOL" dnf remove -y docker docker-client docker-client-latest \
                        docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
                    "$ESCALATION_TOOL" dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    "$ESCALATION_TOOL" "$PACKAGER" install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                else
                    curl -fsSL https://get.docker.com | "$ESCALATION_TOOL" sh
                fi
                ;;
            *)
                curl -fsSL https://get.docker.com | "$ESCALATION_TOOL" sh
                ;;
        esac

        startAndEnableService docker

        if ! isServiceActive docker; then
            printf "%b\n" "${RED}Docker service failed to start.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Docker service enabled and started.${RC}"

        if [ "$DTYPE" = "fedora" ] && sestatus 2>/dev/null | grep -q 'SELinux status:\s*enabled'; then
            printf "%b\n" "${YELLOW}Adjusting SELinux for Docker on Fedora...${RC}"
            "$ESCALATION_TOOL" setenforce 0
            "$ESCALATION_TOOL" sed -i --follow-symlinks 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
        fi

        printf "%b\n" "${GREEN}Docker installation and setup completed.${RC}"
    else
        printf "%b\n" "${GREEN}Docker is already installed.${RC}"
    fi
}

create_compose_stack() {
    stack_name="$1"
    stack_dir="$2"
    compose_content="$3"

    if ! "$ESCALATION_TOOL" docker ps -a --format '{{.Names}}' | grep -q "^${stack_name}$"; then
        printf "%b\n" "${YELLOW}Installing and starting ${stack_name}...${RC}"

        "$ESCALATION_TOOL" mkdir -p "$stack_dir"
        printf "%s" "$compose_content" | "$ESCALATION_TOOL" tee "${stack_dir}/compose.yaml" > /dev/null

        if ! "$ESCALATION_TOOL" docker ps -a --format '{{.Names}}' | grep -q "^dockge$"; then
            (
                cd "$stack_dir" && "$ESCALATION_TOOL" docker compose up -d
            )

            printf "%b\n" "${YELLOW}Waiting for ${stack_name} to start...${RC}"
            i=0
            while [ "$i" -lt 30 ]; do
                if "$ESCALATION_TOOL" docker inspect -f '{{.State.Status}}' "$stack_name" 2>/dev/null | grep -q "running"; then
                    printf "%b\n" "${GREEN}${stack_name} started successfully.${RC}"
                    return 0
                fi
                i=$((i+1))
                sleep 1
            done

            printf "%b\n" "${RED}${stack_name} did not start successfully. Checking logs...${RC}"
            "$ESCALATION_TOOL" docker logs "$stack_name" || printf "%b\n" "${RED}No logs available. ${stack_name} may not have started correctly.${RC}"
        else
            printf "%b\n" "${GREEN}${stack_name} stack has been created in ${stack_dir}/compose.yaml${RC}"
            printf "%b\n" "${YELLOW}Please deploy it manually through the Dockge interface at http://$(ip route get 1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'):5001${RC}"
        fi
    else
        printf "%b\n" "${GREEN}${stack_name} is already installed.${RC}"
    fi
}

install_dockge() {
    dockge_compose="---
services:
  dockge:
    image: louislam/dockge:latest
    container_name: dockge
    restart: unless-stopped
    ports:
      - 5001:5001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      - /opt/stacks:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks"
    create_compose_stack "dockge" "/opt/dockge" "$dockge_compose"
}

install_portainer() {
    portainer_compose="---
services:
  portainer-ce:
    ports:
      - 8000:8000
      - 9443:9443
    container_name: portainer
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    image: portainer/portainer-ce:latest
volumes:
  portainer_data: {}
networks: {}"
    create_compose_stack "portainer" "/opt/stacks/portainer" "$portainer_compose"
}

docker_permission() {
    printf "%b\n" "${YELLOW}Adding current user to the docker group...${RC}"
    "$ESCALATION_TOOL" usermod -aG docker "$USER"

    printf "%b\n" "${CYAN}Your user has been added to the Docker group.${RC}"
    printf "%b\n" "${CYAN}To apply the changes, you have two options:${RC}"
    printf "%b\n" "${CYAN}1. Run the following command to apply changes immediately:${RC}"
    printf "%b\n" "${CYAN}   newgrp docker${RC}"
    printf "%b\n" "${CYAN}2. Log out and log back in to apply the changes.${RC}"
    printf "%b\n" "${CYAN}After applying the changes, you can use Docker without sudo.${RC}"
    printf "%b\n" "${CYAN}To apply changes immediately, copy and run this command:${RC}"
    printf "%b\n" "${CYAN}newgrp docker${RC}"
}

install_components() {
    choose_installation

    if [ "$INSTALL_DOCKER" -eq 1 ]; then
        install_docker
    fi

    if [ "$INSTALL_DOCKGE" -eq 1 ]; then
        install_dockge
    fi

    if [ "$INSTALL_PORTAINER" -eq 1 ]; then
        install_portainer
    fi
}

# Main logic
checkEnv
checkDistro
install_components
docker_permission