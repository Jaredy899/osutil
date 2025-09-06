# Winget Backup/Restore/Update Utility (TUI-friendly)

$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Blue  = "${esc}[34m"
$Reset = "${esc}[0m"

$ErrorActionPreference = 'Stop'

# Fix for backspace issue in Windows Terminal
# Set PSReadLine options for better input handling
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -Force
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -PredictionSource None
}

# Alternative input function that works better in Windows Terminal
function Read-InputWithBackspace {
    param(
        [string]$Prompt = ""
    )
    
    if ($Prompt) {
        Write-Host $Prompt -NoNewline
    }
    
    # Use Read-Host with error handling to prevent backspace overflow issues
    $originalErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'SilentlyContinue'
        $result = Read-Host
        $ErrorActionPreference = $originalErrorAction
        return $result
    } catch {
        $ErrorActionPreference = $originalErrorAction
        # If Read-Host fails due to backspace overflow, return empty string
        Write-Host ""
        return ""
    }
}

function Test-WingetAvailable {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command winget -ErrorAction SilentlyContinue }
    return [bool]$cmd
}

function Get-BackupPaths {
    $documentsPath = [Environment]::GetFolderPath('MyDocuments')
    $backupDir = Join-Path $documentsPath 'winget-backup'
    $stablePath = Join-Path $backupDir 'packages.json'
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $snapshotPath = Join-Path $backupDir ("packages.$timestamp.json")
    [PSCustomObject]@{ Documents = $documentsPath; Dir = $backupDir; Stable = $stablePath; Snapshot = $snapshotPath }
}

function New-DirectoryIfMissing([string]$path) {
    if (-not (Test-Path -Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

function Invoke-WingetBackup {
    $paths = Get-BackupPaths
    New-DirectoryIfMissing -path $paths.Dir
    Write-Host "${Cyan}Exporting installed packages with winget...${Reset}"
    try {
        winget export -o "$($paths.Stable)" --accept-source-agreements | Out-Null
        if (Test-Path $paths.Stable) {
            Copy-Item -Path $paths.Stable -Destination $paths.Snapshot -Force
            Write-Host "${Green}Backup created:${Reset} $($paths.Stable)"
            Write-Host "${Blue}Snapshot:${Reset} $($paths.Snapshot)"
        } else {
            Write-Host "${Red}Export reported success but backup file not found.${Reset}"
        }
    } catch {
        Write-Host "${Red}Backup failed: $($_.Exception.Message)${Reset}"
    }
}

function Invoke-WingetRestore {
    $paths = Get-BackupPaths
    if (-not (Test-Path -Path $paths.Stable)) {
        Write-Host "${Red}Backup file not found at:${Reset} $($paths.Stable)"
        Write-Host "${Yellow}Run a backup first, or place a packages.json at that location.${Reset}"
        return
    }
    Write-Host "${Cyan}Importing packages from backup...${Reset}"
    try {
        winget import -i "$($paths.Stable)" --silent --accept-source-agreements --accept-package-agreements | Out-Null
        Write-Host "${Green}Restore initiated. Some packages may continue installing in the background.${Reset}"
    } catch {
        Write-Host "${Red}Restore failed: $($_.Exception.Message)${Reset}"
    }
}

function Invoke-WingetUpgradeAll {
    Write-Host "${Cyan}Upgrading all upgradable packages via winget...${Reset}"
    try {
        winget upgrade --all --include-unknown --accept-source-agreements --accept-package-agreements
        Write-Host "${Green}Upgrade run complete.${Reset}"
    } catch {
        Write-Host "${Red}Upgrade failed: $($_.Exception.Message)${Reset}"
    }
}

if (-not (Test-WingetAvailable)) {
    Write-Host "${Red}winget is not available on this system.${Reset}"
    Write-Host "${Yellow}Tip:${Reset} Run the PowerShell setup utility in this tab set to install or update winget."
    exit 1
}

# Simple numeric menu (works in TUI)
Write-Host "${Cyan}`nWinget Backup/Restore/Update${Reset}"
Write-Host "1) Backup installed packages"
Write-Host "2) Restore packages from backup"
Write-Host "3) Update all packages"
$choice = Read-InputWithBackspace -Prompt "${Cyan}Select an option (1-3), or press Enter to cancel: ${Reset}"

switch ($choice) {
    '1' { Invoke-WingetBackup }
    '2' { Invoke-WingetRestore }
    '3' { Invoke-WingetUpgradeAll }
    default { Write-Host "${Yellow}Cancelled.${Reset}" }
}


