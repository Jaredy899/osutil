# Node.js (Current) via nvm-windows or winget

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Node.js (Current)...${Reset}"

if (Test-CommandExists node) { Write-Host "${Green}Node.js already installed. Skipping.${Reset}"; exit 0 }

try {
  # Prefer nvm-windows for flexible version management
  if (-not (Test-CommandExists nvm)) {
    winget install -e --id CoreyButler.NVMforWindows -h --scope user
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')
  }
  if (Test-CommandExists nvm) {
    nvm install latest
    nvm use latest
    Write-Host "${Green}Node.js installed via nvm-windows.${Reset}"
  } else {
    # Fallback to direct Node.js install
    winget install -e --id OpenJS.NodeJS --scope machine -h
    Write-Host "${Green}Node.js installed via winget.${Reset}"
  }
} catch { Write-Host "${Red}Failed to install Node.js: $($_.Exception.Message)${Reset}"; exit 1 }


