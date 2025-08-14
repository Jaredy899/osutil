# Zig installer via winget

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Zig...${Reset}"

if (Test-CommandExists zig) { Write-Host "${Green}Zig already installed. Skipping.${Reset}"; exit 0 }

try {
  winget install -e --id zig.zig -h --scope user --accept-package-agreements --accept-source-agreements
  Write-Host "${Green}Zig installed.${Reset}"
} catch { Write-Host "${Red}Failed to install Zig: $($_.Exception.Message)${Reset}"; exit 1 }


