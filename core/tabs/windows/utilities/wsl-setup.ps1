#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

# Minimal ANSI colors (PS7/Windows Terminal/TUI)
$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevate if needed
if (-not (Test-Administrator)) {
    Write-Host "${Cyan}Requesting administrative privileges...${Reset}"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    exit
}

function Enable-WSLFeatures {
    param([ref]$rebootRequired)

    Write-Host "${Cyan}Ensuring Windows features for WSL are enabled...${Reset}"
    $features = @(
        'Microsoft-Windows-Subsystem-Linux',
        'VirtualMachinePlatform'
    )

    $reboot = $false
    foreach ($feature in $features) {
        try {
            $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
            if ($state -ne 'Enabled') {
                Write-Host "${Yellow}Enabling feature: $feature${Reset}"
                $result = Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName $feature -All
                if ($result.RestartNeeded) { $reboot = $true }
            }
        } catch {
            Write-Host "${Red}Failed to check/enable ${feature}: $($_.Exception.Message)${Reset}"
        }
    }

    try {
        & wsl.exe --set-default-version 2 *>$null
    } catch {
        # Ignore if not supported; WSL might not be installed yet
    }

    $rebootRequired.Value = $reboot
}

function Get-InstalledDistros {
    try {
        $out = & wsl.exe -l -q 2>$null
        if ($LASTEXITCODE -ne 0) { return @() }
        return @($out | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() })
    } catch { return @() }
}

function Select-Or-InstallDistro {
    # If no distributions are installed, offer to install one (default Ubuntu)
    $installed = @(Get-InstalledDistros)
    if ($installed.Count -eq 0) {
        Write-Host "${Yellow}No WSL distributions found. Installing Ubuntu (default).${Reset}"
        try {
            & wsl.exe --install -d Ubuntu
            Write-Host "${Green}WSL installation initiated. A reboot may be required. After reboot, complete the Ubuntu first-run setup.${Reset}"
        } catch {
            Write-Host "${Red}Automatic install failed: $($_.Exception.Message)${Reset}"
            Write-Host "${Yellow}You can manually install with: wsl --list --online, then wsl --install -d <DistroName>${Reset}"
        }
        return $null
    }

    if ($installed.Count -eq 1) {
        Write-Host "${Cyan}Detected single distro. Using: $($installed[0])${Reset}"
        return $installed[0]
    }

    Write-Host "${Cyan}Select a WSL distribution to auto-start at boot:${Reset}"
    for ($i = 0; $i -lt $installed.Count; $i++) {
        $idx = $i + 1
        Write-Host "$idx. $($installed[$i])"
    }
    $selection = Read-Host "Enter number or name (default 1)"
    if ([string]::IsNullOrWhiteSpace($selection)) { return $installed[0] }
    if ($selection -match '^[0-9]+$' -and [int]$selection -ge 1 -and [int]$selection -le $installed.Count) {
        return $installed[[int]$selection - 1]
    }
    $match = $installed | Where-Object { $_.ToLower() -eq $selection.ToLower() }
    if ($match) { return $match[0] }
    $prefixMatches = $installed | Where-Object { $_.ToLower().StartsWith($selection.ToLower()) }
    if ($prefixMatches.Count -eq 1) { return $prefixMatches[0] }

    Write-Host "${Red}Invalid selection.${Reset}"
    return $null
}

function Set-WSLSystemdEnabled {
    Write-Host "${Cyan}Ensuring systemd is enabled for WSL2...${Reset}"
    $content = "[wsl2]`nsystemd=true`n"
    $paths = @()

    # Current user profile
    if ($env:UserProfile) { $paths += (Join-Path $env:UserProfile '.wslconfig') }

    # SYSTEM profile (used if the task runs as SYSTEM)
    $systemProfile = 'C:\Windows\System32\config\systemprofile'
    if (Test-Path $systemProfile) { $paths += (Join-Path $systemProfile '.wslconfig') }

    foreach ($path in $paths) {
        try {
            $dir = Split-Path $path
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $path) {
                $existing = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue
                if ($existing -notmatch '(?im)^\[wsl2\]') {
                    Set-Content -Path $path -Value $content -Encoding ASCII
                } elseif ($existing -match '(?im)^systemd\s*=\s*true\b') {
                    # already enabled
                } else {
                    # Merge by forcing systemd=true under [wsl2]
                    $updated = ($existing -replace '(?im)^(\[wsl2\][\s\S]*?)(?:$|\z)', {
                        param($m)
                        $section = $m.Groups[1].Value
                        if ($section -match '(?im)^systemd\s*=') {
                            $section = $section -replace '(?im)^systemd\s*=.*$', 'systemd=true'
                        } else {
                            $section = $section.TrimEnd() + "`nsystemd=true`n"
                        }
                        return $section
                    })
                    Set-Content -Path $path -Value $updated -Encoding ASCII
                }
            } else {
                Set-Content -Path $path -Value $content -Encoding ASCII
            }
            Write-Host "${Green}Configured: $path${Reset}"
        } catch {
            Write-Host "${Yellow}Could not update ${path}: $($_.Exception.Message)${Reset}"
        }
    }
}

function Register-WSLAutoStartTask {
    param(
        [Parameter(Mandatory=$true)][string]$DistroName
    )

    $taskName = "Start WSL at Boot - $DistroName"
    Write-Host "${Cyan}Creating scheduled task: $taskName${Reset}"

    $wslPath = Join-Path $env:SystemRoot 'System32\wsl.exe'
    $action    = New-ScheduledTaskAction -Execute $wslPath -Argument ('-d "{0}"' -f $DistroName)
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    # Remove any existing copies with the same name in root and known folders
    try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    try { Unregister-ScheduledTask -TaskName $taskName -TaskPath '\\osutil\\wsl\\' -Confirm:$false -ErrorAction SilentlyContinue } catch {}

    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -ErrorAction Stop *> $null
        Write-Host "${Green}Scheduled task created.${Reset}"
    } catch {
        # If it exists, update it
        try {
            Set-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Principal $principal -Settings $settings -ErrorAction Stop *> $null
            Write-Host "${Green}Scheduled task updated.${Reset}"
        } catch {
            # Suppress noisy error output and continue silently when the task already exists
            return
        }
    }

    # Try to start the task now (it may finish quickly and not appear as Running)
    try { Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue *> $null } catch {}
}

# Orchestration
$rebootRef = [ref]$false
Enable-WSLFeatures -rebootRequired $rebootRef

Set-WSLSystemdEnabled

$selected = Select-Or-InstallDistro
if (-not $selected) {
    if ($rebootRef.Value) {
        Write-Host "${Yellow}`nA reboot is required to finish enabling WSL features. Please reboot, complete distro initialization, and rerun this script to create the auto-start task.${Reset}"
    } else {
        Write-Host "${Yellow}`nPlease install a WSL distribution (e.g., 'wsl --install -d Ubuntu'), then rerun this script.${Reset}"
    }
    exit 0
}

Register-WSLAutoStartTask -DistroName $selected

Write-Host "${Green}Selected distro: $selected${Reset}"

if ($rebootRef.Value) {
    Write-Host "${Yellow}`nA reboot may still be required for changes to take effect.${Reset}"
}

Write-Host "${Green}`nWSL setup and auto-start configuration complete.${Reset}"


