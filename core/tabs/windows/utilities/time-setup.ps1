# Minimal ANSI colors (PS7/Windows Terminal/TUI)
$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevate the script if required
if (-not (Test-Administrator)) {
    Write-Host "${Cyan}Requesting administrative privileges...${Reset}"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    Exit
}

Write-Host "${Cyan}Script running with administrative privileges...${Reset}"
 
function Enable-AutoTimeZone {
    Try {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime" -Force *>$null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime" -Name "AutoTimeZoneEnabled" -PropertyType DWord -Value 1 -Force *>$null

        Try {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Force *>$null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -PropertyType DWord -Value 0 -Force *>$null
        } Catch {}

        Try { Set-Service -Name lfsvc -StartupType Automatic *>$null } Catch {}
        Try { Start-Service -Name lfsvc *>$null } Catch {}
        Try { Set-Service -Name tzautoupdate -StartupType Automatic *>$null } Catch {}

        $taskPath = "\\Microsoft\\Windows\\Time Zone\\"
        $taskName = "SynchronizeTimeZone"
        $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Start-ScheduledTask -TaskPath $taskPath -TaskName $taskName
            Start-Sleep -Seconds 3
        } else {
            Try { Start-Service -Name tzautoupdate *>$null } Catch {}
        }

        $currentTz = Get-TimeZone -ErrorAction SilentlyContinue
        if ($currentTz) {
            Write-Host "${Green}Automatic time zone enabled (${currentTz.Id}).${Reset}"
        } else {
            Write-Host "${Yellow}Automatic time zone enabled, but current time zone could not be read.${Reset}"
        }
        return $true
    } Catch {
        Write-Host "${Yellow}Failed to enable automatic time zone: $($_)${Reset}"
        return $false
    }
}

function Set-TimeSettings {
    Try {
        if (-not (Enable-AutoTimeZone)) {
            Write-Host "${Yellow}Automatic timezone unavailable. Falling back to manual selection...${Reset}"
            # Display options for time zones
            Write-Host "${Cyan}Select a time zone from the options below:${Reset}"
            $timeZones = @(
                "Eastern Standard Time",
                "Central Standard Time",
                "Mountain Standard Time",
                "Pacific Standard Time",
                "Greenwich Standard Time",
                "UTC",
                "Hawaiian Standard Time",
                "Alaskan Standard Time"
            )
            
            # Display the list of options
            for ($i = 0; $i -lt $timeZones.Count; $i++) {
                Write-Output "$(($i + 1)). $($timeZones[$i])"
            }

            # Prompt the user to select a time zone
            $selection = Read-Host "Enter the number corresponding to your time zone"

            # Validate input and set the time zone
            if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $timeZones.Count) {
                $selectedTimeZone = $timeZones[$selection - 1]
                Set-TimeZone -Id "$selectedTimeZone"
                Write-Host "${Green}Time zone set to $selectedTimeZone.${Reset}"
            } else {
                Write-Host "${Yellow}Invalid selection. Please run the script again and choose a valid number.${Reset}"
                return
            }
        }

        # Configure the time synchronization settings using time.nist.gov
        w32tm /config /manualpeerlist:"time.nist.gov,0x1" /syncfromflags:manual /reliable:YES /update *>$null
        Set-Service -Name w32time -StartupType Automatic *>$null
        Start-Service -Name w32time *>$null
        w32tm /resync *>$null

        Write-Host "${Green}Time settings configured and synchronized using time.nist.gov.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to configure time settings or synchronization: $($_)${Reset}"
    }
}

# Function to create a scheduled task for time synchronization at startup
function Set-TimeSyncAtStartup {
    Try {
        $taskName = "TimeSyncAtStartup"
        $action = New-ScheduledTaskAction -Execute "w32tm.exe" -Argument "/resync"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Check if the task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Write-Host "${Green}Scheduled task for time synchronization at startup has been created.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to create scheduled task for time synchronization: $($_)${Reset}"
    }
}

# Execute time setup tasks
Set-TimeSettings
Set-TimeSyncAtStartup

Write-Host "${Green}`nTime setup complete!${Reset}"