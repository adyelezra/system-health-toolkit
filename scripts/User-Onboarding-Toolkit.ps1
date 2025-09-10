<#
.SYNOPSIS
Simulates user onboarding, asset assignment, and offboarding for IT administration.

.DESCRIPTION
This script:
1. Creates a new user account (simulation)
2. Assigns a device/laptop to the user
3. Logs all actions to a timestamped log file
4. Simulates offboarding (optional)
#>

# === Variables ===
$logFolder = "..\logs"
if (!(Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$logFolder\onboarding_$timestamp.txt"

# === Sample User Data ===
$user = @{
    Username = "jdoe"
    FullName = "John Doe"
    Role     = "IT Staff"
}

# === Sample Asset Data ===
$asset = @{
    DeviceName = "Laptop-001"
    CPU        = "Intel i7"
    RAM        = "16GB"
    Disk       = "512GB SSD"
    Serial     = "SN12345678"
}

# === Functions ===

function Log-Action {
    param([string]$Message)
    $entry = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $Message"
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

function Onboard-User {
    Log-Action "Starting onboarding for $($user.Username) ($($user.FullName))"
    Log-Action "Assigned Role: $($user.Role)"
    Log-Action "Assigning device: $($asset.DeviceName) (CPU: $($asset.CPU), RAM: $($asset.RAM), Disk: $($asset.Disk), Serial: $($asset.Serial))"
    Log-Action "Onboarding completed successfully!"
}

function Offboard-User {
    Log-Action "Starting offboarding for $($user.Username) ($($user.FullName))"
    Log-Action "Device $($asset.DeviceName) returned and archived"
    Log-Action "User account disabled"
    Log-Action "Offboarding completed successfully!"
}

# === Script Execution ===
Onboard-User

# Uncomment the next line to simulate offboarding
# Offboard-User

Write-Output "Done. See $logFile"
