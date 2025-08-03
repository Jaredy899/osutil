#!/bin/bash

install_omakub() {
    echo "Installing Omakub..."
    wget -qO- https://omakub.org/install | bash
    echo "Omakub installed successfully!"
}

checkEnv
checkEscalationTool
install_omakub