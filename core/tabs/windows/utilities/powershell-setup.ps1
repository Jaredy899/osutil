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
    Write-Host "Downloading: $url" -ForegroundColor Yellow
    try {
        Start-BitsTransfer -Source $url -Destination $localPath -ErrorAction Stop
        Write-Host "Running: $localPath" -ForegroundColor Cyan
        & $localPath
    } catch {
        Write-Host "Failed to download or run: $url`n$_" -ForegroundColor Red
    }
}

# Ensure Winget is installed or updated
Write-Host "Checking winget..." -ForegroundColor Cyan
Invoke-DownloadAndRunScript -url $wingetScriptUrl -localPath $wingetScriptPath

# Applications installation
Write-Host "Installing apps..." -ForegroundColor Cyan
Invoke-DownloadAndRunScript -url $appsScriptUrl -localPath $appsScriptPath

# Nerd Font installation
Write-Host "Installing Nerd Font..." -ForegroundColor Cyan
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
        Write-Host "Profile updated: $profilePath" -ForegroundColor Green
    } else {
        Write-Host "Profile URL is empty; skipped." -ForegroundColor Yellow
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
    Write-Host "Config files updated (fastfetch, starship)." -ForegroundColor Green
}
Initialize-ConfigFiles

# Terminal-Icons module
function Install-TerminalIcons {
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Write-Host "Installing Terminal-Icons..." -ForegroundColor Yellow
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "Terminal-Icons installed." -ForegroundColor Green
    } else {
        Write-Host "Terminal-Icons already installed." -ForegroundColor Blue
    }
}
Install-TerminalIcons

# Optional: AutoHotkey shortcuts
function Initialize-CustomShortcuts {
    Write-Host "Set up custom AutoHotkey shortcuts? (y/n) " -ForegroundColor Cyan -NoNewline
    $response = Read-Host
    if ($response.ToLower() -ne 'y') { Write-Host 'Skipped.' -ForegroundColor Yellow; return }
    Write-Host "Installing AutoHotkey and setting up shortcuts..." -ForegroundColor Yellow
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
        Write-Host 'AutoHotkey shortcuts set up.' -ForegroundColor Green
    } catch {
        Write-Host "Failed to set up shortcuts.`n$_" -ForegroundColor Red
    }
}
Initialize-CustomShortcuts

# Neovim config
function Initialize-NeovimConfig {
    Write-Host 'Setting up Neovim configuration...' -ForegroundColor Cyan
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
            Write-Host 'Neovim configuration installed.' -ForegroundColor Green
        } else { Write-Host 'nvim folder not found in repository.' -ForegroundColor Red }
    } catch { Write-Host "Error setting up Neovim config.`n$_" -ForegroundColor Red }
    finally { if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force } }
}
Initialize-NeovimConfig

# Final notes (concise)
Write-Host ''
Write-Host 'Font setup:' -ForegroundColor Cyan
Write-Host "Set 'Fira Code Nerd Font' in Windows Terminal > Settings > Windows PowerShell > Appearance." -ForegroundColor White
Write-Host ''
Write-Host 'Profile notes:' -ForegroundColor Cyan
Write-Host 'The profile will be updated when you re-run this script.' -ForegroundColor White
Write-Host 'For personal aliases/customizations, create a separate profile.ps1.' -ForegroundColor White

Write-Host "`nDevelopment setup complete!" -ForegroundColor Green 