# Chris Titus Tech Windows Utility launcher

param(
    [switch]$ForceNewWindow
)

$inTui = $env:OSUTIL_TUI_MODE -eq '1'

if ($ForceNewWindow -or $inTui) {
    # In TUI or when forced: open a separate PowerShell window to ensure full interactivity
    $ps = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
    if (-not $ps) { $ps = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
    Start-Process $ps -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoLogo','-Command', "Invoke-RestMethod https://christitus.com/win | Invoke-Expression"
    exit 0
}

# Inline (non-TUI) path
Write-Host "Invoking Chris Titus Tech's Windows Utility..."
Invoke-RestMethod -Uri "https://christitus.com/win" | Invoke-Expression 