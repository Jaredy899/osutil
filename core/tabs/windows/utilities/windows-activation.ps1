# Function to activate Windows
function Invoke-WindowsActivation {
    Write-Host "Activating Windows..."
    $confirmation = Read-Host "Are you sure you want to activate Windows? (y/n)"
    if ($confirmation -eq 'y') {
        Invoke-RestMethod https://get.activated.win | Invoke-Expression
    } else {
        Write-Host "Windows activation cancelled."
    }
}

# Execute the function
Invoke-WindowsActivation 