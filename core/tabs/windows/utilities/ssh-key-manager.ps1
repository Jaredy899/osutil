# Script to add SSH keys to Windows administrators authorized_keys
# Must be run as administrator

# Minimal ANSI colors (PS7/Windows Terminal/TUI)
$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevate the script if required
if (-not (Test-Administrator)) {
    Write-Host "${Cyan}Requesting administrative privileges...${Reset}"
    # Resolve a shell executable path in a way that's compatible with Windows PowerShell 5.x
    $ps = $null
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) {
        $ps = $cmd.Source
    } else {
        $cmd = Get-Command powershell -ErrorAction SilentlyContinue
        if ($cmd) {
            $ps = $cmd.Source
        } else {
            $ps = 'powershell.exe'
        }
    }
    Start-Process $ps -Verb RunAs -ArgumentList ('-NoProfile','-ExecutionPolicy','Bypass','-File', $PSCommandPath)
    Exit
}

Write-Host "${Cyan}Script running with administrative privileges...${Reset}"

# Variables
$programData = $env:ProgramData
$sshPath = Join-Path $programData "ssh"
$adminKeys = Join-Path $sshPath "administrators_authorized_keys"

function Initialize-SshEnvironment {
    if (-not (Test-Path -Path $sshPath)) {
        New-Item -ItemType Directory -Path $sshPath -Force | Out-Null
        Write-Host "${Green}✓ Created $sshPath${Reset}"
    }
    if (-not (Test-Path -Path $adminKeys)) {
        New-Item -ItemType File -Path $adminKeys -Force | Out-Null
        Write-Host "${Green}✓ Created $adminKeys${Reset}"
    }
}

function Get-GitHubKeys {
    param(
        [string]$username
    )
    try {
        Invoke-RestMethod -Uri "https://api.github.com/users/$username/keys" -ErrorAction Stop
    }
    catch {
        Write-Host "${Red}✗ Failed to fetch keys from GitHub: $_${Reset}"
        return $null
    }
}

function Add-UniqueKey {
    param(
        [string]$key
    )
    $existingKeys = if (Test-Path $adminKeys) { Get-Content -Path $adminKeys } else { @() }
    if ($existingKeys -contains $key) {
        Write-Host "${Yellow}! Key already exists in $adminKeys${Reset}"
        return
    }
    Add-Content -Path $adminKeys -Value $key
    Write-Host "${Green}✓ Added new key to $adminKeys${Reset}"
}

function Import-GitHubKeys {
    Write-Host "${Cyan}`nEnter GitHub username: ${Reset}" -NoNewline
    $githubUsername = Read-Host
    if (-not $githubUsername) { return }
    Write-Host "${Yellow}`nFetching keys from GitHub...${Reset}"
    $keys = Get-GitHubKeys -username $githubUsername
    if (-not $keys) { return }

    Write-Host "${Cyan}`nFound $($keys.Count) keys for user $githubUsername${Reset}"

    $index = 0
    foreach ($entry in $keys) {
        $index++
        Write-Host "${Cyan}`n[$index]${Reset}" -NoNewline
        $keyType = ($entry.key -split ' ')[0]
        Write-Host "${Yellow} Type: $keyType${Reset}"
        $tmp = [IO.Path]::GetTempFileName()
        try {
            Set-Content -Path $tmp -Value $entry.key
            $fp = (& ssh-keygen -lf $tmp) -split '\s+' | Select-Object -Index 1
            Write-Host "${Green}    Fingerprint: $fp${Reset}"
        }
        catch {
            Write-Host "${Red}    Fingerprint: (could not compute)${Reset}"
        }
        finally {
            Remove-Item $tmp -ErrorAction SilentlyContinue
        }
    }

    Write-Host "${Cyan}`nEnter a number to add a key, 'a' to add all, or press Enter to cancel: ${Reset}" -NoNewline
    $selection = Read-Host
    if (-not $selection) { return }
    if ($selection -eq 'a') {
        foreach ($entry in $keys) { Add-UniqueKey -key $entry.key }
        return
    }
    if ($selection -as [int]) {
        $n = [int]$selection
        if ($n -ge 1 -and $n -le $keys.Count) {
            Add-UniqueKey -key $keys[$n-1].key
        }
    }
}

function Add-ManualKey {
    Write-Host "${Cyan}`nPaste your public key: ${Reset}"
    $manualKey = Read-Host
    if ($manualKey) { Add-UniqueKey -key $manualKey }
}

function Restart-SshService {
    Write-Host "${Yellow}`nRestarting SSH service...${Reset}"
    try {
        Stop-Service sshd -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        Start-Service sshd -ErrorAction Stop
        Write-Host "${Green}✓ SSH service restarted successfully${Reset}"
    }
    catch {
        Write-Host "${Red}✗ Failed to restart SSH service: $_${Reset}"
    }
}

function Repair-SshKeyPermissions {
    param(
        [string]$keyPath = "$env:USERPROFILE\.ssh\id_rsa"
    )
    Write-Host "${Yellow}`nChecking private key permissions...${Reset}"
    if (-not (Test-Path -Path $keyPath)) {
        Write-Host "${Yellow}! No private key found at $keyPath - skipping permissions fix${Reset}"
        return
    }
    try {
        icacls $keyPath /inheritance:r | Out-Null
        icacls $keyPath /grant "${env:USERNAME}:(R)" | Out-Null
        Write-Host "${Green}✓ Fixed permissions for $keyPath${Reset}"
    }
    catch {
        Write-Host "${Red}✗ Failed to set key permissions: $_${Reset}"
    }
}

# Main
Initialize-SshEnvironment

# Simple numeric menu (works with stdin)
Write-Host "${Cyan}`nWindows SSH Key Manager${Reset}"
Write-Host "1) Import keys from GitHub"
Write-Host "2) Enter key manually"
Write-Host "${Cyan}Select an option (1-2), or press Enter to cancel: ${Reset}" -NoNewline
$choice = Read-Host
switch ($choice) {
    '1' { Import-GitHubKeys }
    '2' { Add-ManualKey }
    default { Write-Host "${Yellow}Cancelled.${Reset}"; return }
}

Write-Host "${Yellow}`nSetting permissions...${Reset}"
icacls $adminKeys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null
Write-Host "${Green}✓ Set permissions for $adminKeys${Reset}"

Restart-SshService
Repair-SshKeyPermissions

Write-Host "${Green}`nDone.${Reset}"