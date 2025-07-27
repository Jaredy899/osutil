#Requires -Version 5.1

# Prevent execution if this script was only partially downloaded
$ErrorActionPreference = "Stop"

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
    Invoke-WebRequest -Uri (Get-Url) -OutFile $tempFile -UseBasicParsing
    Test-Error $LASTEXITCODE "Downloading osutil"
    
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