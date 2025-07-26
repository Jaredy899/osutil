#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Enable-WindowsHelloForSudo {
    Write-Host "Enabling Windows Hello for sudo..."
    # This is not a direct equivalent of the macOS functionality, but it is the closest thing.
    # This will enable Windows Hello for UAC prompts.
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force
    }
    Set-ItemProperty -Path $regPath -Name "EnableLUA" -Value 1
    Write-Host "Windows Hello for sudo enabled."
}


Enable-WindowsHelloForSudo
