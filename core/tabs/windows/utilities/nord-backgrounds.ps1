# Function to download and extract Nord backgrounds
function Get-NordBackgrounds {
    $documentsPath = [Environment]::GetFolderPath("MyDocuments")
    $backgroundsPath = Join-Path $documentsPath "nord_backgrounds"
    $zipPath = Join-Path $documentsPath "nord_backgrounds.zip"
    $url = "https://github.com/ChrisTitusTech/nord-background/archive/refs/heads/main.zip"

    if (Test-Path $backgroundsPath) {
        if ((Read-Host "Nord backgrounds folder exists. Overwrite? (y/n)") -ne 'y') {
            Write-Host "Skipping Nord backgrounds download."; return
        }
        Remove-Item $backgroundsPath -Recurse -Force
    }

    try {
        Write-Host "Downloading and extracting Nord backgrounds..."
        Invoke-WebRequest -Uri $url -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $documentsPath -Force
        Rename-Item -Path (Join-Path $documentsPath "nord-background-main") -NewName "nord_backgrounds"
        Remove-Item -Path $zipPath -Force
        Write-Host "Nord backgrounds set up in: $backgroundsPath"
    }
    catch {
        Write-Host "Error setting up Nord backgrounds: $_"
    }
}

# Execute the function
Get-NordBackgrounds 