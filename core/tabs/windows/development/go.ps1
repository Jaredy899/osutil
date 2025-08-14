# Go installer via winget

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Go...${Reset}"

if (Test-CommandExists go) { Write-Host "${Green}Go already installed. Skipping.${Reset}"; exit 0 }

try {
  winget install -e --id GoLang.Go --scope machine -h
  Write-Host "${Green}Go installed.${Reset}"
} catch { Write-Host "${Red}Failed to install Go: $($_.Exception.Message)${Reset}"; exit 1 }


