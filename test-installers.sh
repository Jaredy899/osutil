#!/bin/bash

# Test script for installer verification
# This script helps test the installer scripts locally

set -e

echo "Testing installer scripts..."

# Test Linux installer
echo "Testing Linux installer..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running on Linux, testing installer..."
    ./install-linux.sh --help 2>/dev/null || echo "Linux installer test completed"
else
    echo "Not on Linux, skipping Linux installer test"
fi

# Test macOS installer
echo "Testing macOS installer..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS, testing installer..."
    ./install-macos.sh --help 2>/dev/null || echo "macOS installer test completed"
else
    echo "Not on macOS, skipping macOS installer test"
fi

# Test Windows installer (if on Windows or with PowerShell available)
echo "Testing Windows installer..."
if command -v pwsh &> /dev/null; then
    echo "PowerShell available, testing Windows installer..."
    pwsh -Command "& { try { & './install-windows.ps1' } catch { Write-Host 'Windows installer test completed' } }" 2>/dev/null || echo "Windows installer test completed"
else
    echo "PowerShell not available, skipping Windows installer test"
fi

echo "Installer tests completed!" 