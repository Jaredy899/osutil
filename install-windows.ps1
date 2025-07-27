#Requires -Version 5.1

# Prevent execution if this script was only partially downloaded
{
    $ErrorActionPreference = "Stop"
    
    # Colors for output
    $Red = "`e[31m"
    $Green = "`e[32m"
    $Blue = "`e[34m"
    $Reset = "`e[0m"
    
    function Check-Error {
        param($ExitCode, $Message)
        
        if ($ExitCode -ne 0) {
            Write-Host "${Red}ERROR: ${Message}${Reset}"
            exit 1
        }
    }
    
    # Check if running on Windows
    if ($env:OS -ne "Windows_NT") {
        Check-Error 1 "This installer is designed for Windows only"
    }
    
    function Get-Url {
        return "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
    }
    
    Write-Host "${Blue}Installing osutil for Windows...${Reset}"
    
    # Download the binary
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Write-Host "Downloading osutil..."
        Invoke-WebRequest -Uri (Get-Url) -OutFile $tempFile -UseBasicParsing
        Check-Error $LASTEXITCODE "Downloading osutil"
        
        Write-Host "${Green}✓ osutil downloaded successfully${Reset}"
        Write-Host "`n${Blue}Launching osutil...${Reset}"
        
        # Launch the application
        try {
            & $tempFile @args
            Check-Error $LASTEXITCODE "Executing osutil"
        } catch {
            Check-Error 1 "Failed to launch osutil: $($_.Exception.Message)"
        }
        
    } catch {
        Check-Error 1 $_.Exception.Message
    } finally {
        # Clean up temporary file
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
} # End of wrapping 