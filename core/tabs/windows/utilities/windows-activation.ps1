# Windows Activation launcher

param(
    [switch]$ForceNewWindow
)

$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Reset = "${esc}[0m"

$inTui = $env:OSUTIL_TUI_MODE -eq '1'

function Invoke-WindowsActivationInline {
    Write-Host "${Cyan}Activating Windows...${Reset}"
    $confirmation = Read-Host "Are you sure you want to activate Windows? (y/n)"
    if ($confirmation -eq 'y') {
        Invoke-RestMethod https://get.activated.win | Invoke-Expression
    } else {
        Write-Host "${Yellow}Windows activation cancelled.${Reset}"
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