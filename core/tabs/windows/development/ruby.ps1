# Ruby installer via winget

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Ruby...${Reset}"

if (Test-CommandExists ruby) { Write-Host "${Green}Ruby already installed. Skipping.${Reset}"; exit 0 }

try {
  winget install -e --id RubyInstallerTeam.RubyWithDevKit -h --scope user
  Write-Host "${Green}Ruby installed.${Reset}"
} catch { Write-Host "${Red}Failed to install Ruby: $($_.Exception.Message)${Reset}"; exit 1 }


