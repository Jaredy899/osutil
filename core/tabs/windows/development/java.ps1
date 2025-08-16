# Java (Temurin) installer via winget

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Java (Temurin)...${Reset}"

if (Test-CommandExists java) { Write-Host "${Green}Java already installed. Skipping.${Reset}"; exit 0 }

try {
  # Prefer Temurin 21, fallback to 17
  winget install -e --id EclipseAdoptium.Temurin.21.JDK -h --scope machine
} catch {
  try {
    Write-Host "${Yellow}Temurin 21 failed, trying Temurin 17...${Reset}"
    winget install -e --id EclipseAdoptium.Temurin.17.JDK -h --scope machine
  } catch { Write-Host "${Red}Failed to install Temurin JDK: $($_.Exception.Message)${Reset}"; exit 1 }
}

Write-Host "${Green}Java installed.${Reset}"


