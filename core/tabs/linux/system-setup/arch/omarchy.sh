#!/bin/bash

install_omarchy() {
    echo "Installing Omarchy..."
    wget -qO- https://omarchy.org/install | bash
    echo "Omarchy installed successfully!"
}

checkEnv
checkEscalationTool
install_omarchy