$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Save-RemoteFile {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    # Try BITS first (preferred)
    try {
        Start-BitsTransfer -Source $Url -Destination $Destination -ErrorAction Stop
        return $true
    } catch {
        $err = $_.Exception.Message
        Write-Host "${Yellow}BITS failed: $err${Reset}"
        # Common Win10 error when BITS service is unavailable: 0x800704DD
        # Fallback 1: Invoke-WebRequest
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
            return $true
        } catch {
            Write-Host "${Yellow}Invoke-WebRequest failed: $($_.Exception.Message)${Reset}"
            # Fallback 2: .NET WebClient
            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($Url, $Destination)
                return $true
            } catch {
                Write-Host "${Yellow}.NET WebClient failed: $($_.Exception.Message)${Reset}"
                # Fallback 3: curl.exe (if available)
                try {
                    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
                    if ($null -ne $curl) {
                        & $curl.Path -L -o $Destination $Url
                        if ($LASTEXITCODE -eq 0 -and (Test-Path $Destination)) { return $true }
                    }
                    throw "curl.exe not available or failed"
                } catch {
                    Write-Host "${Red}All download methods failed for: $Url${Reset}"
                    return $false
                }
            }
        }
    }
}

# Define the GitHub base URL for your setup scripts
$githubBaseUrl = "https://raw.githubusercontent.com/Jaredy899/win/main/my_powershell"

# Corrected specific URLs for each setup script
$appsScriptUrl = "$githubBaseUrl/apps_install.ps1"
$configJsoncUrl = "$githubBaseUrl/config.jsonc"
$starshipTomlUrl = "$githubBaseUrl/starship.toml"
$githubProfileUrl = "$githubBaseUrl/Microsoft.PowerShell_profile.ps1"
$fontScriptUrl = "$githubBaseUrl/install_nerd_font.ps1"
$wingetScriptUrl = "$githubBaseUrl/install_winget.ps1"

# Add new URL for shortcuts.ahk
$shortcutsAhkUrl = "$githubBaseUrl/shortcuts.ahk"

# Local paths where the scripts will be temporarily downloaded
$appsScriptPath = "$env:TEMP\apps_install.ps1"
$fontScriptPath = "$env:TEMP\install_nerd_font.ps1"
$wingetScriptPath = "$env:TEMP\install_winget.ps1"

function Invoke-DownloadAndRunScript {
    param(
        [string]$url,
        [string]$localPath
    )
    Write-Host "${Yellow}Downloading: $url${Reset}"
    if (Save-RemoteFile -Url $url -Destination $localPath) {
        Write-Host "${Cyan}Running: $localPath${Reset}"
        try { & $localPath } catch { Write-Host "${Red}Script failed: $($_.Exception.Message)${Reset}" }
    } else {
        Write-Host "${Red}Failed to download or run: $url${Reset}"
    }
}

# Ensure Winget is installed or updated
Write-Host "${Cyan}Checking winget...${Reset}"
Invoke-DownloadAndRunScript -url $wingetScriptUrl -localPath $wingetScriptPath

# Applications installation
Write-Host "${Cyan}Installing apps...${Reset}"
Invoke-DownloadAndRunScript -url $appsScriptUrl -localPath $appsScriptPath

# Nerd Font installation
Write-Host "${Cyan}Installing Nerd Font...${Reset}"
Invoke-DownloadAndRunScript -url $fontScriptUrl -localPath $fontScriptPath

# Initialize PowerShell profiles (PS5 and PS7)
function Initialize-Profile {
    param(
        [string]$profilePath,
        [string]$profileUrl
    )
    $profileDir = Split-Path $profilePath
    if (-not (Test-Path -Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    if (-not [string]::IsNullOrEmpty($profileUrl)) {
        if (Save-RemoteFile -Url $profileUrl -Destination $profilePath) {
            Write-Host "${Green}Profile updated: $profilePath${Reset}"
        } else {
            Write-Host "${Red}Failed to update profile from: $profileUrl${Reset}"
        }
    } else {
        Write-Host "${Yellow}Profile URL is empty; skipped.${Reset}"
    }
}

$ps5ProfilePath = "$env:UserProfile\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps7ProfilePath = "$env:UserProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
Initialize-Profile -profilePath $ps5ProfilePath -profileUrl $githubProfileUrl
Initialize-Profile -profilePath $ps7ProfilePath -profileUrl $githubProfileUrl

# Config files (fastfetch, starship)
function Initialize-ConfigFiles {
    $userConfigDir = "$env:UserProfile\.config"
    $fastfetchConfigDir = "$userConfigDir\fastfetch"
    if (-not (Test-Path -Path $fastfetchConfigDir)) { New-Item -ItemType Directory -Path $fastfetchConfigDir -Force | Out-Null }
    if (Save-RemoteFile -Url $configJsoncUrl -Destination (Join-Path $fastfetchConfigDir 'config.jsonc')) {
        Write-Host "${Green}Fastfetch config updated.${Reset}"
    } else {
        Write-Host "${Red}Failed to update fastfetch config.${Reset}"
    }
    if (Save-RemoteFile -Url $starshipTomlUrl -Destination (Join-Path $userConfigDir 'starship.toml')) {
        Write-Host "${Green}Starship config updated.${Reset}"
    } else {
        Write-Host "${Red}Failed to update starship config.${Reset}"
    }
}
Initialize-ConfigFiles

# Terminal-Icons module
function Install-TerminalIcons {
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Write-Host "${Yellow}Installing Terminal-Icons...${Reset}"
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "${Green}Terminal-Icons installed.${Reset}"
    } else {
        Write-Host "${Cyan}Terminal-Icons already installed.${Reset}"
    }
}
Install-TerminalIcons

# Optional: AutoHotkey shortcuts
function Initialize-CustomShortcuts {
    Write-Host "${Cyan}Set up custom AutoHotkey shortcuts? (y/n) ${Reset}" -NoNewline
    $response = Read-Host
    if ($response.ToLower() -ne 'y') { Write-Host "${Yellow}Skipped.${Reset}"; return }
    Write-Host "${Yellow}Installing AutoHotkey and setting up shortcuts...${Reset}"
    winget install -e --id AutoHotkey.AutoHotkey
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutsPath = Join-Path $startupFolder 'shortcuts.ahk'
    try {
        Start-BitsTransfer -Source $shortcutsAhkUrl -Destination $shortcutsPath -ErrorAction Stop
        # Create desktop shortcut
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $shortcutPath = Join-Path $desktopPath 'Custom Shortcuts.lnk'
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $shortcutsPath
        $Shortcut.WorkingDirectory = $startupFolder
        $Shortcut.Description = 'Custom Keyboard Shortcuts'
        $Shortcut.Save()
        if (Test-Path $shortcutsPath) { Start-Process $shortcutsPath }
        Write-Host "${Green}AutoHotkey shortcuts set up.${Reset}"
    } catch {
        Write-Host "${Red}Failed to set up shortcuts.`n$_${Reset}"
    }
}
Initialize-CustomShortcuts

# Neovim config
function Initialize-NeovimConfig {
    Write-Host "${Cyan}Setting up Neovim with LazyVim...${Reset}"
    $nvimConfigDir = "$env:LOCALAPPDATA\nvim"
    
    # Backup existing config if it exists
    if (Test-Path -Path $nvimConfigDir) {
        $backupDir = "$nvimConfigDir.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $nvimConfigDir -Destination $backupDir -Recurse -Force
        Write-Host "${Yellow}Backed up existing Neovim config to: $backupDir${Reset}"
        Remove-Item -Path $nvimConfigDir -Recurse -Force
    }
    
    # Create nvim config directory
    New-Item -ItemType Directory -Path $nvimConfigDir -Force | Out-Null
    
    # Clone LazyVim starter template
    try {
        Write-Host "${Cyan}Cloning LazyVim starter template...${Reset}"
        git clone https://github.com/LazyVim/starter $nvimConfigDir
        
        # Remove the .git folder so it can be added to user's own repo later
        $gitDir = Join-Path $nvimConfigDir '.git'
        if (Test-Path $gitDir) {
            Remove-Item -Path $gitDir -Recurse -Force
        }
        
        Write-Host "${Green}LazyVim installed successfully. Run 'nvim' to start, then ':LazyHealth' to verify setup.${Reset}"
    } catch {
        Write-Host "${Red}Failed to clone LazyVim starter template. Please check your internet connection and try again.${Reset}"
        Write-Host "${Red}Error: $($_.Exception.Message)${Reset}"
    }
}
Initialize-NeovimConfig

# Final notes (concise)
Write-Host ''
Write-Host "${Cyan}Font setup:${Reset}"
Write-Host "Set 'Fira Code Nerd Font' in Windows Terminal > Settings > Windows PowerShell > Appearance." -ForegroundColor White
Write-Host ''
Write-Host "${Cyan}Profile notes:${Reset}"
Write-Host 'The profile will be updated when you re-run this script.' -ForegroundColor White
Write-Host 'For personal aliases/customizations, create a separate profile.ps1.' -ForegroundColor White

Write-Host "${Green}`nDevelopment setup complete!${Reset}"