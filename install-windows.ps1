#Requires -Version 5.1

# Prevent execution if this script was only partially downloaded
{
    $ErrorActionPreference = "Stop"
    
    # Colors for output
    $Red = "`e[31m"
    $Green = "`e[32m"
    $Blue = "`e[34m"
    $Reset = "`e[0m"
    
    # Check if running on Windows
    if ($env:OS -ne "Windows_NT") {
        Write-Host "${Red}ERROR: This installer is designed for Windows only${Reset}"
        exit 1
    }
    
    function Get-Url {
        return "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
    }
    
    function Get-InstallPath {
        # Try to install to a directory in PATH, fallback to user's home
        $paths = @(
            "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
            "$env:USERPROFILE\.local\bin",
            "$env:USERPROFILE\AppData\Local\Programs\osutil"
        )
        
        foreach ($path in $paths) {
            if (Test-Path $path -PathType Container) {
                return "$path\osutil.exe"
            }
        }
        
        # Create the first directory if none exist
        $installDir = "$env:USERPROFILE\AppData\Local\Programs\osutil"
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        return "$installDir\osutil.exe"
    }
    
    $installPath = Get-InstallPath
    $installDir = Split-Path $installPath -Parent
    
    Write-Host "${Blue}Installing osutil for Windows...${Reset}"
    
    # Create installation directory if it doesn't exist
    if (!(Test-Path $installDir -PathType Container)) {
        Write-Host "Creating directory: $installDir"
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    
    # Download the binary
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Write-Host "Downloading osutil..."
        Invoke-WebRequest -Uri (Get-Url) -OutFile $tempFile -UseBasicParsing
        
        # Move to installation location
        Move-Item -Path $tempFile -Destination $installPath -Force
        
        Write-Host "${Green}✓ osutil installed successfully to $installPath${Reset}"
        
        # Check if the installation directory is in PATH
        $pathDirs = $env:PATH -split ';'
        if ($pathDirs -contains $installDir) {
            Write-Host "${Green}✓ osutil is ready to use!${Reset}"
        } else {
            Write-Host "${Blue}⚠  Please add $installDir to your PATH or restart your terminal${Reset}"
            Write-Host "   You can run: `$env:PATH += `";$installDir`""
        }
        
        Write-Host "`n${Blue}Launching osutil...${Reset}"
        
        # Launch the application
        try {
            & $installPath
        } catch {
            Write-Host "${Red}Failed to launch osutil: $($_.Exception.Message)${Reset}"
            Write-Host "${Blue}You can manually run: $installPath${Reset}"
        }
        
    } catch {
        Write-Host "${Red}ERROR: $($_.Exception.Message)${Reset}"
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
        exit 1
    }
} # End of wrapping 