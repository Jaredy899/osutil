# Windows Activation launcher

param(
    [switch]$ForceNewWindow
)

$inTui = $env:OSUTIL_TUI_MODE -eq '1'

function Invoke-WindowsActivationInline {
    Write-Host "Activating Windows..."
    $confirmation = Read-Host "Are you sure you want to activate Windows? (y/n)"
    if ($confirmation -eq 'y') {
        Invoke-RestMethod https://get.activated.win | Invoke-Expression
    } else {
        Write-Host "Windows activation cancelled."
    }
}

if ($ForceNewWindow -or $inTui) {
    $ps = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
    if (-not $ps) { $ps = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
    $cmd = "`$confirmation = Read-Host 'Are you sure you want to activate Windows? (y/n)'; if (`$confirmation -eq 'y') { Invoke-RestMethod https://get.activated.win | Invoke-Expression } else { Write-Host 'Windows activation cancelled.' }"
    Start-Process $ps -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoLogo','-Command', $cmd
    exit 0
}

Invoke-WindowsActivationInline 