#!/bin/sh -e

. ../../common-script.sh

setupPorts() {
  # Check if git is available
  if ! command_exists git; then
    "$ESCALATION_TOOL" "$PACKAGER" install -y git
    if ! command_exists git; then
      printf "%b\n" "${RED}Failed to install git. Cannot proceed.${RC}"
      exit 1
    fi
  fi

  # Check if ports tree already exists
  if [ "$PORTS_AVAILABLE" = "true" ]; then
    # Check if it's a git repository
    if [ -d /usr/ports/.git ]; then
      cd /usr/ports || exit 1
      "$ESCALATION_TOOL" git pull --rebase
    else
      # Remove existing ports tree and clone fresh
      if ! "$ESCALATION_TOOL" rm -rf /usr/ports; then
        # Try alternative removal methods
        printf "%b\n" "${YELLOW}Standard removal failed, trying alternatives...${RC}"

        # Method 1: Try to unmount if it's a mount point
        if "$ESCALATION_TOOL" umount /usr/ports 2>/dev/null; then
          printf "%b\n" "${YELLOW}Unmounted /usr/ports, removing empty directory...${RC}"
          # After unmounting, remove the now-empty directory
          "$ESCALATION_TOOL" rmdir /usr/ports 2>/dev/null || "$ESCALATION_TOOL" rm -rf /usr/ports
        fi

        # Method 2: Kill processes that might be using the directory
        "$ESCALATION_TOOL" fuser -k /usr/ports 2>/dev/null || true
        sleep 2

        # Method 3: Try removal again
        if "$ESCALATION_TOOL" rm -rf /usr/ports; then
          printf "%b\n" "${GREEN}Successfully removed ports tree${RC}"
        else
          printf "%b\n" "${RED}Cannot remove /usr/ports. Please resolve manually and run again.${RC}"
          exit 1
        fi
      fi
      clonePortsTree
    fi
  else
    clonePortsTree
  fi

  # Set proper permissions
  "$ESCALATION_TOOL" chown -R root:wheel /usr/ports
  "$ESCALATION_TOOL" find /usr/ports -type d -exec chmod 755 {} \;
  "$ESCALATION_TOOL" find /usr/ports -type f -exec chmod 644 {} \;

  printf "%b\n" "${GREEN}FreeBSD Ports setup completed!${RC}"
}

clonePortsTree() {
  # Create ports directory if it doesn't exist
  "$ESCALATION_TOOL" mkdir -p /usr/ports

  # Clone the ports tree
  if ! "$ESCALATION_TOOL" git clone --depth 1 https://git.freebsd.org/ports.git /usr/ports; then
    printf "%b\n" "${RED}Failed to clone ports tree${RC}"
    exit 1
  fi
}

checkEnv
setupPorts
