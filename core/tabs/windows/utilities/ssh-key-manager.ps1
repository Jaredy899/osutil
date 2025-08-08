# Script to add SSH keys to Windows administrators authorized_keys
# Must be run as administrator

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

# Variables
$programData = $env:ProgramData
$sshPath = Join-Path $programData "ssh"
$adminKeys = Join-Path $sshPath "administrators_authorized_keys"

function Initialize-SshEnvironment {
    if (-not (Test-Path -Path $sshPath)) {
        New-Item -ItemType Directory -Path $sshPath -Force | Out-Null
        Write-Host "✓ Created $sshPath" -ForegroundColor Green
    }
    if (-not (Test-Path -Path $adminKeys)) {
        New-Item -ItemType File -Path $adminKeys -Force | Out-Null
        Write-Host "✓ Created $adminKeys" -ForegroundColor Green
    }
}

function Get-GitHubKeys { param([string]$username)
    try { Invoke-RestMethod -Uri "https://api.github.com/users/$username/keys" -ErrorAction Stop }
    catch { Write-Host "✗ Failed to fetch keys from GitHub: $_" -ForegroundColor Red; $null }
}

function Add-UniqueKey { param([string]$key)
    $existingKeys = if (Test-Path $adminKeys) { Get-Content -Path $adminKeys } else { @() }
    if ($existingKeys -contains $key) { Write-Host "! Key already exists in $adminKeys" -ForegroundColor Yellow; return }
    Add-Content -Path $adminKeys -Value $key
    Write-Host "✓ Added new key to $adminKeys" -ForegroundColor Green
}

function Import-GitHubKeys {
    Write-Host "`nEnter GitHub username: " -ForegroundColor Cyan -NoNewline
    $githubUsername = Read-Host
    if (-not $githubUsername) { return }
    Write-Host "`nFetching keys from GitHub..." -ForegroundColor Yellow
    $keys = Get-GitHubKeys -username $githubUsername
    if (-not $keys) { return }

    Write-Host "`nFound $($keys.Count) keys for user $githubUsername" -ForegroundColor Cyan

    $index = 0
    foreach ($entry in $keys) {
        $index++
        Write-Host "`n[$index]" -ForegroundColor Cyan -NoNewline
        $keyType = ($entry.key -split ' ')[0]
        Write-Host " Type: $keyType" -ForegroundColor Yellow
        $tmp = [IO.Path]::GetTempFileName()
        try {
            Set-Content -Path $tmp -Value $entry.key
            $fp = (& ssh-keygen -lf $tmp) -split '\s+' | Select-Object -Index 1
            Write-Host "    Fingerprint: $fp" -ForegroundColor Green
        } catch { Write-Host "    Fingerprint: (could not compute)" -ForegroundColor Red }
        finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
    }

    Write-Host "`nEnter a number to add a key, 'a' to add all, or press Enter to cancel: " -ForegroundColor Cyan -NoNewline
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
    Write-Host "`nPaste your public key: " -ForegroundColor Cyan
    $manualKey = Read-Host
    if ($manualKey) { Add-UniqueKey -key $manualKey }
}

function Restart-SshService {
    Write-Host "`nRestarting SSH service..." -ForegroundColor Yellow
    try { Stop-Service sshd -Force -ErrorAction Stop; Start-Sleep -Seconds 2; Start-Service sshd -ErrorAction Stop; Write-Host "✓ SSH service restarted successfully" -ForegroundColor Green }
    catch { Write-Host "✗ Failed to restart SSH service: $_" -ForegroundColor Red }
}

function Repair-SshKeyPermissions { param([string]$keyPath = "$env:USERPROFILE\.ssh\id_rsa")
    Write-Host "`nChecking private key permissions..." -ForegroundColor Yellow
    if (-not (Test-Path -Path $keyPath)) { Write-Host "! No private key found at $keyPath - skipping permissions fix" -ForegroundColor Yellow; return }
    try { icacls $keyPath /inheritance:r | Out-Null; icacls $keyPath /grant ${env:USERNAME}:"(R)" | Out-Null; Write-Host "✓ Fixed permissions for $keyPath" -ForegroundColor Green }
    catch { Write-Host "✗ Failed to set key permissions: $_" -ForegroundColor Red }
}

# Main
Initialize-SshEnvironment

# Simple numeric menu (works with stdin)
Write-Host "`nWindows SSH Key Manager" -ForegroundColor Cyan
Write-Host "1) Import keys from GitHub" -ForegroundColor Gray
Write-Host "2) Enter key manually" -ForegroundColor Gray
Write-Host "Select an option (1-2), or press Enter to cancel: " -ForegroundColor Cyan -NoNewline
$choice = Read-Host
switch ($choice) {
    '1' { Import-GitHubKeys }
    '2' { Add-ManualKey }
    default { Write-Host "Cancelled." -ForegroundColor Yellow; return }
}

Write-Host "`nSetting permissions..." -ForegroundColor Yellow
icacls $adminKeys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null
Write-Host "✓ Set permissions for $adminKeys" -ForegroundColor Green

Restart-SshService
Repair-SshKeyPermissions

Write-Host "`nDone." -ForegroundColor Green 