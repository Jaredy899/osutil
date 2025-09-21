# Java installer via mise

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Java via mise...${Reset}"

# Install mise if not available
if (-not (Test-CommandExists mise)) {
  Write-Host "${Yellow}Installing mise...${Reset}"
  try {
    Invoke-WebRequest -Uri "https://mise.run/install.ps1" -OutFile "$env:TEMP\mise-install.ps1"
    & "$env:TEMP\mise-install.ps1"
    Remove-Item "$env:TEMP\mise-install.ps1" -ErrorAction SilentlyContinue
  } catch { Write-Host "${Red}Failed to install mise: $($_.Exception.Message)${Reset}"; exit 1 }
}

# Install latest LTS Java (prefer 21, fallback to 17)
try {
  $javaVersions = mise ls-remote java
  if ($javaVersions -match "21\.") {
    mise use -g java@21
  } else {
    mise use -g java@17
  }
  Write-Host "${Green}Java installed via mise. Restart your shell to use Java.${Reset}"
} catch { Write-Host "${Red}Failed to install Java via mise: $($_.Exception.Message)${Reset}"; exit 1 }


