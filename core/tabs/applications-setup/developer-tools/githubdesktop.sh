#!/bin/sh -e

. ../../common-script.sh

installGithubDesktop() {
    if ! brewprogram_exists github; then
        printf "%b\n" "${YELLOW}Installing Github Desktop...${RC}"
        brew install --cask github
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Github Desktop. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Github Desktop installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Github Desktop is already installed.${RC}"
    fi
}

checkEnv
installGithubDesktop