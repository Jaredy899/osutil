$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

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
    try {
        Start-BitsTransfer -Source $url -Destination $localPath -ErrorAction Stop
        Write-Host "${Cyan}Running: $localPath${Reset}"
        & $localPath
    } catch {
        Write-Host "${Red}Failed to download or run: $url`n$_${Reset}"
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
        Start-BitsTransfer -Source $profileUrl -Destination $profilePath -ErrorAction Stop
        Write-Host "${Green}Profile updated: $profilePath${Reset}"
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
    Start-BitsTransfer -Source $configJsoncUrl -Destination (Join-Path $fastfetchConfigDir 'config.jsonc') -ErrorAction Stop
    Start-BitsTransfer -Source $starshipTomlUrl -Destination (Join-Path $userConfigDir 'starship.toml') -ErrorAction Stop
    Write-Host "${Green}Config files updated (fastfetch, starship).${Reset}"
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
    Write-Host "${Cyan}Setting up Neovim configuration...${Reset}"
    $nvimConfigDir = "$env:LOCALAPPDATA\nvim"
    if (-not (Test-Path -Path $nvimConfigDir)) { New-Item -ItemType Directory -Path $nvimConfigDir -Force | Out-Null } else {
        $backupDir = "$nvimConfigDir.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $nvimConfigDir -Destination $backupDir -Recurse -Force
        Remove-Item -Path "$nvimConfigDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    $tempDir = Join-Path $env:TEMP 'nvim_download'
    if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $zipUrl = 'https://github.com/Jaredy899/win/archive/refs/heads/main.zip'
    $zipPath = Join-Path $tempDir 'repo.zip'
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        $extractedNvimPath = Join-Path $tempDir 'win-main\my_powershell\nvim'
        if (Test-Path $extractedNvimPath) {
            Copy-Item -Path (Join-Path $extractedNvimPath '*') -Destination $nvimConfigDir -Recurse -Force
            Write-Host "${Green}Neovim configuration installed.${Reset}"
        } else { Write-Host "${Red}nvim folder not found in repository.${Reset}" }
    } catch { Write-Host "${Red}Error setting up Neovim config.`n$_${Reset}" }
    finally { if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force } }
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