#Requires -Version 5.1

# Prevent execution if this script was only partially downloaded
$ErrorActionPreference = "Stop"

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Test-Error {
    param($ExitCode, $Message)

    if ($ExitCode -ne 0) {
        Write-Host "${Red}ERROR: ${Message}${Reset}"
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

Write-Host "${Blue}Installing osutil for Windows...${Reset}"

# Download the binary
$tempFile = [System.IO.Path]::GetTempFileName()
$exeFile = [System.IO.Path]::ChangeExtension($tempFile, ".exe")

Write-Host "Temp file: $tempFile"
Write-Host "Exe file: $exeFile"

try {
    Write-Host "Downloading osutil..."
    $response = Invoke-WebRequest -Uri (Get-Url) -OutFile $tempFile -UseBasicParsing
    Write-Host "${Green}✓ Download completed successfully${Reset}"
    Write-Host "File size: $((Get-Item $tempFile).Length) bytes"

    # Rename to .exe extension
    Write-Host "Preparing executable..."
    Move-Item -Path $tempFile -Destination $exeFile -Force
    Write-Host "${Green}✓ File renamed${Reset}"

    # Unblock the file to allow execution
    Write-Host "Unblocking downloaded file..."
    Unblock-File -Path $exeFile
    Write-Host "${Green}✓ File unblocked${Reset}"

    Write-Host "${Green}✓ osutil downloaded successfully${Reset}"
    Write-Host "`n${Blue}Launching osutil...${Reset}"

    # Launch the application
    try {
        Write-Host "Executing: $exeFile"
        & $exeFile --help
        $exitCode = $LASTEXITCODE
        Write-Host "${Green}✓ Execution completed with exit code: $exitCode${Reset}"
    } catch {
        Write-Host "${Red}✗ Execution failed: $($_.Exception.Message)${Reset}"
        Test-Error 1 "Failed to launch osutil: $($_.Exception.Message)"
    }

} catch {
    Write-Host "${Red}✗ Exception caught: $($_.Exception.Message)${Reset}"
    Test-Error 1 $_.Exception.Message
} finally {
    # Clean up temporary files
    Write-Host "Cleaning up..."
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
        Write-Host "Removed temp file"
    }
    if (Test-Path $exeFile) {
        Remove-Item $exeFile -Force
        Write-Host "Removed exe file"
    }
} 