#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Adb {
    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
        Write-Host "Installing ADB..."
        try {
            winget install -e --id Google.PlatformTools
        }
        catch {
            Write-Error "Failed to install ADB. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "ADB is already installed."
    }
}

function Install-UniversalAndroidDebloater {
    if (-not (Get-Command uad -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Universal Android Debloater..."
        try {
            Invoke-WebRequest -Uri "https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest/download/uad_gui-windows-portable.exe" -OutFile "$HOME/uad.exe"
            Move-Item -Path "$HOME/uad.exe" -Destination "$env:SystemRoot/System32"
        }
        catch {
            Write-Error "Failed to install Universal Android Debloater. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Universal Android Debloater is already installed."
    }
}


Install-Adb
Install-UniversalAndroidDebloater
