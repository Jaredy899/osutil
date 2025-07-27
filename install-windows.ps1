#Requires -Version 5.1

# Prevent execution if this script was only partially downloaded
$ErrorActionPreference = "Stop"

# Check PowerShell execution policy
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "PowerShell execution policy is set to 'Restricted'."
    Write-Host "Please run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Host "Then try running this script again."
    exit 1
}

# Enable TLS 1.2 for PowerShell 5 (older versions default to TLS 1.0)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Test-Error {
    param($ExitCode, $Message)
    
    if ($ExitCode -ne 0) {
        Write-Host "ERROR: ${Message}"
        exit 1
    }
}

# Check if running on Windows
if ($env:OS -ne "Windows_NT") {
    Test-Error 1 "This installer is designed for Windows only"
}

function Get-Url {
    return "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
}

Write-Host "Installing osutil for Windows..."

# Download the binary
$tempFile = [System.IO.Path]::GetTempFileName()
try {
    Write-Host "Downloading osutil..."
    $url = Get-Url
    Write-Host "Download URL: $url"
    
    # Add error handling for network issues
    try {
        $response = Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5
        Write-Host "✓ Download completed successfully"
        Write-Host "File size: $((Get-Item $tempFile).Length) bytes"
    } catch {
        Write-Host "Network error: $($_.Exception.Message)"
        Write-Host "Please check your internet connection and try again."
        Test-Error 1 "Downloading osutil"
    }
    
    # Unblock the file to allow execution
    Write-Host "Unblocking downloaded file..."
    Unblock-File -Path $tempFile
    
    Write-Host "✓ osutil downloaded successfully"
    Write-Host "`nLaunching osutil..."
    
    # Launch the application and capture exit code
    try {
        & $tempFile @args
        $exitCode = $LASTEXITCODE
    } catch {
        Test-Error 1 "Failed to launch osutil: $($_.Exception.Message)"
    }
    
} catch {
    Test-Error 1 $_.Exception.Message
} finally {
    # Clean up temporary file silently
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
}

# Exit with the same code as the binary
exit $exitCode 