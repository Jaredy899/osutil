#!/bin/sh -e

. ../../common-script.sh

installDockerDesktop() {
    if ! brewprogram_exists docker-desktop; then
        printf "%b\n" "${YELLOW}Installing Docker Desktop...${RC}"
        if ! brew install --cask docker; then
            printf "%b\n" "${RED}Failed to install Docker Desktop. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Docker Desktop installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Docker Desktop is already installed.${RC}"
    fi
}

checkEnv
installDockerDesktop