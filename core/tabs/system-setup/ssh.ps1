#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Ssh {
    Write-Host "Installing SSH dependencies..."
    try {
        winget install -e --id Microsoft.OpenSSH.Beta
    }
    catch {
        Write-Error "Failed to install OpenSSH. Please check your winget installation or try again later."
        exit 1
    }
    Write-Host "SSH dependencies installed!"
}

function Enable-Ssh {
    Write-Host "Enabling SSH access..."
    try {
        Start-Service -Name "sshd"
        Set-Service -Name "sshd" -StartupType "Automatic"
    }
    catch {
        Write-Error "Failed to enable SSH. Please check your system or try again later."
        exit 1
    }
    Write-Host "SSH access enabled."
}

function Configure-Sshd {
    Write-Host "Configuring sshd..."
    $sshdConfig = "$env:ProgramData\ssh\sshd_config"
    if (Test-Path $sshdConfig) {
        (Get-Content $sshdConfig) | ForEach-Object { $_ -replace "#PubkeyAuthentication yes", "PubkeyAuthentication yes" } | Set-Content $sshdConfig
        (Get-Content $sshdConfig) | ForEach-Object { $_ -replace "#PasswordAuthentication yes", "PasswordAuthentication no" } | Set-Content $sshdConfig
        Restart-Service -Name "sshd"
    }
    else {
        Write-Error "SSH daemon config file not found at $sshdConfig"
        exit 1
    }
    Write-Host "sshd configured."
}

function Ensure-SshDir {
    $sshDir = "$HOME/.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -Path $sshDir -ItemType Directory
    }
}

function Import-SshKeys {
    $githubUser = Read-Host "Enter the GitHub username"
    $sshKeysUrl = "https://github.com/$githubUser.keys"
    $keys = Invoke-RestMethod -Uri $sshKeysUrl
    if ($keys) {
        Write-Host "SSH keys found for $githubUser:"
        $keys
        $confirm = Read-Host "Do you want to import these keys? [Y/n]"
        if ($confirm -ne "n") {
            Add-Content -Path "$HOME/.ssh/authorized_keys" -Value $keys
            Write-Host "SSH keys imported successfully!"
        }
        else {
            Write-Host "SSH key import cancelled."
        }
    }
    else {
        Write-Error "No SSH keys found for GitHub user: $githubUser"
    }
}

function Add-ManualKey {
    $publicKey = Read-Host "Enter the public key to add"
    Add-Content -Path "$HOME/.ssh/authorized_keys" -Value $publicKey
    Write-Host "Public key added to authorized_keys."
}

function Show-SshMenu {
    Write-Host "1) Import from GitHub"
    Write-Host "2) Enter your own public key"
}

function Setup-SshKey {
    Write-Host "Select SSH key option:"
    Show-SshMenu
    $choice = Read-Host
    switch ($choice) {
        "1" { Import-SshKeys }
        "2" { Add-ManualKey }
        default { Write-Host "No valid option selected. Skipping key import." }
    }
}

Check-Env
Install-Ssh
Enable-Ssh
Configure-Sshd
Ensure-SshDir
Setup-SshKey