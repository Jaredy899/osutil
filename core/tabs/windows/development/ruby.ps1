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
  # Resolve latest major.minor Ruby (non-DevKit) dynamically from winget
  $searchJson = winget search RubyInstallerTeam.Ruby --source winget --output json 2>$null
  $parsed = $null
  if ($searchJson) { $parsed = $searchJson | ConvertFrom-Json }
  $items = @()
  if ($parsed) {
    if ($parsed.Data) { $items = $parsed.Data } else { $items = $parsed }
  }

  # Pick highest Id of the form RubyInstallerTeam.Ruby.X.Y (avoid WithDevKit here)
  $candidates = $items | Where-Object { $_.Id -match '^RubyInstallerTeam\.Ruby\.[0-9]+\.[0-9]+$' }
  if (-not $candidates -or $candidates.Count -eq 0) { throw 'No Ruby candidates found via winget search.' }

  $latest = $candidates | Sort-Object @{ Expression = { [version]($_.Id -replace '^[^.]+\.[^.]+\.', '') } } -Descending | Select-Object -First 1
  $pkg = $latest.Id

  winget install -e --id $pkg -h --scope user --accept-package-agreements --accept-source-agreements
  Write-Host "${Green}Ruby installed.${Reset}"
} catch { Write-Host "${Red}Failed to install Ruby: $($_.Exception.Message)${Reset}"; exit 1 }


