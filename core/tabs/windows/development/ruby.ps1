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
  $parsed = $null
  $raw = winget search RubyInstallerTeam.Ruby --source winget --accept-source-agreements --output json 2>$null
  if ($raw) {
    $text = ($raw | Out-String).Trim()
    $start = $text.IndexOf('[')
    if ($start -lt 0) { $start = $text.IndexOf('{') }
    if ($start -ge 0) {
      $jsonText = $text.Substring($start)
      try { $parsed = $jsonText | ConvertFrom-Json } catch { $parsed = $null }
    }
  }

  $items = @()
  if ($parsed) { if ($parsed.Data) { $items = $parsed.Data } else { $items = $parsed } }

  # If JSON parse failed, fallback to parsing text output
  if (-not $items -or $items.Count -eq 0) {
    $rawText = winget search RubyInstallerTeam.Ruby --source winget 2>$null | Out-String
    $matches = [regex]::Matches($rawText, 'RubyInstallerTeam\.Ruby\.(\d+\.\d+)')
    if ($matches.Count -gt 0) {
      $versions = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique | ForEach-Object { [version]$_ } | Sort-Object -Descending
      if ($versions.Count -gt 0) { $pkg = 'RubyInstallerTeam.Ruby.' + ($versions[0].ToString()) }
    }
  } else {
    $candidates = $items | Where-Object { $_.Id -match '^RubyInstallerTeam\.Ruby\.[0-9]+\.[0-9]+$' }
    if ($candidates -and $candidates.Count -gt 0) {
      $latest = $candidates | Sort-Object @{ Expression = { [version]($_.Id -replace '^[^.]+\.[^.]+\.', '') } } -Descending | Select-Object -First 1
      $pkg = $latest.Id
    }
  }

  if (-not $pkg) { throw 'No Ruby candidates found via winget.' }

  winget install -e --id $pkg -h --scope user --accept-package-agreements --accept-source-agreements
  Write-Host "${Green}Ruby installed.${Reset}"
} catch { Write-Host "${Red}Failed to install Ruby: $($_.Exception.Message)${Reset}"; exit 1 }


