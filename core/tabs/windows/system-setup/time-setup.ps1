# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevate the script if required
if (-not (Test-Administrator)) {
    Write-Output "Requesting administrative privileges..."
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    Exit
}

Write-Output "Script running with administrative privileges..."

function Set-TimeSettings {
    Try {
        # Attempt to automatically detect timezone
        Try {
            # Try multiple geolocation services
            $timezone = $null
            
            # Try ipapi.co first
            Try {
                $timezone = (Invoke-RestMethod -Uri "https://ipapi.co/timezone" -Method Get -TimeoutSec 5).Trim()
            } Catch {
                Write-Output "ipapi.co detection failed, trying alternative service..."
            }
            
            if ($timezone) {
                Write-Host "Detected timezone: $timezone" -ForegroundColor Yellow
                
                # Simplified mapping for common US timezones
                $tzMapping = @{
                    'America/New_York' = 'Eastern Standard Time'
                    'America/Chicago' = 'Central Standard Time'
                    'America/Denver' = 'Mountain Standard Time'
                    'America/Los_Angeles' = 'Pacific Standard Time'
                    'America/Anchorage' = 'Alaskan Standard Time'
                    'Pacific/Honolulu' = 'Hawaiian Standard Time'
                }

                if ($tzMapping.ContainsKey($timezone)) {
                    $windowsTimezone = $tzMapping[$timezone]
                    tzutil /s $windowsTimezone *>$null
                    Write-Host "Time zone automatically set to $windowsTimezone" -ForegroundColor Green
                } else {
                    throw "Could not map timezone"
                }
            } else {
                throw "Could not detect timezone"
            }
        } Catch {
            Write-Host "Automatic timezone detection failed. Falling back to manual selection..." -ForegroundColor Yellow
            # Display options for time zones
            Write-Host "Select a time zone from the options below:" -ForegroundColor Cyan
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
                Write-Output "$($i + 1). $($timeZones[$i])"
            }

            # Prompt the user to select a time zone
            $selection = Read-Host "Enter the number corresponding to your time zone"

            # Validate input and set the time zone
            if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $timeZones.Count) {
                $selectedTimeZone = $timeZones[$selection - 1]
                tzutil /s "$selectedTimeZone" *>$null
                Write-Output "Time zone set to $selectedTimeZone."
            } else {
                Write-Output "Invalid selection. Please run the script again and choose a valid number."
                return
            }
        }

        # Configure the time synchronization settings using time.nist.gov
        w32tm /config /manualpeerlist:"time.nist.gov,0x1" /syncfromflags:manual /reliable:YES /update *>$null
        Set-Service -Name w32time -StartupType Automatic *>$null
        Start-Service -Name w32time *>$null
        w32tm /resync *>$null

        Write-Output "Time settings configured and synchronized using time.nist.gov."
    } Catch {
        Write-Output "Failed to configure time settings or synchronization: $($_)"
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
        Write-Host "Scheduled task for time synchronization at startup has been created." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to create scheduled task for time synchronization: $($_)" -ForegroundColor Red
    }
}

# Execute time setup tasks
Set-TimeSettings
Set-TimeSyncAtStartup

Write-Host "`nTime setup complete!" -ForegroundColor Green 