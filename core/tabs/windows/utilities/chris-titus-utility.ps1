# Special function to invoke Chris Titus Tech's Windows Utility directly from URL
function Invoke-ChrisTitusTechUtility {
    Write-Host "Invoking Chris Titus Tech's Windows Utility..."
    Invoke-RestMethod -Uri "https://christitus.com/win" | Invoke-Expression
}

# Execute the function
Invoke-ChrisTitusTechUtility 