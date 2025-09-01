# Color function for better output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Starting OSutil" "Cyan"

$url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows-x86_64-gnu.exe"

$temp = [System.IO.Path]::GetTempFileName()
$exe = [System.IO.Path]::ChangeExtension($temp, ".exe")

try {
    Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
    Move-Item $temp $exe -Force
    Unblock-File $exe
    & $exe
} catch {
    Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
    exit 1
} finally {
    if (Test-Path $exe) {
        Remove-Item $exe -Force
    }
}