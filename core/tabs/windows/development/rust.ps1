# Rust (rustup) installer for Windows (winget + rustup)

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

Write-Host "${Yellow}Installing Rust (rustup)...${Reset}"

if (Test-CommandExists rustup) {
  Write-Host "${Green}rustup already installed. Updating toolchain...${Reset}"
  try {
    rustup default stable
    rustup update stable
    rustup component add rustfmt clippy
  } catch { Write-Host "${Red}Failed to update rustup toolchain: $($_.Exception.Message)${Reset}" }
  exit 0
}

try {
  winget install -e --id Rustlang.Rustup -h --scope user
} catch {
  Write-Host "${Red}Failed to install rustup via winget: $($_.Exception.Message)${Reset}"; exit 1
}

try {
  $env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')
  if (Test-CommandExists rustup) {
    rustup default stable
    rustup component add rustfmt clippy
  }
  Write-Host "${Green}Rust installed/updated successfully.${Reset}"
} catch { Write-Host "${Red}Rust post-install steps failed: $($_.Exception.Message)${Reset}" }


