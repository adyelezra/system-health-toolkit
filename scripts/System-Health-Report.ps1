<#
System-Health-Report.ps1
Purpose: Collect key Windows system info for troubleshooting
Run as: Standard user OK; Admin gives more details
Output: logs\sysreport_YYYY-MM-DD_HHMM.txt
#>

# Ensure logs folder
$logDir = Join-Path $PSScriptRoot "..\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = (Get-Date).ToString("yyyy-MM-dd_HHmm")
$log = Join-Path $logDir "sysreport_$stamp.txt"

function Write-Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    $line | Tee-Object -FilePath $log -Append
}

Write-Log "=== SYSTEM HEALTH REPORT ==="
Write-Log "User: $env:USERNAME  Host: $env:COMPUTERNAME"

# OS Info
$os = Get-CimInstance Win32_OperatingSystem
Write-Log "OS: $($os.Caption) ($($os.Version))"
Write-Log "Installed: $([DateTime]$os.InstallDate)"
Write-Log "Uptime: $([Math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours,1)) hours"

# CPU & RAM
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Log "CPU: $($cpu.Name)  Cores: $($cpu.NumberOfCores)  Logical: $($cpu.NumberOfLogicalProcessors)"
Write-Log "RAM Total: $([Math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB"
Write-Log "RAM Free : $([Math]::Round($os.FreePhysicalMemory/1MB,2)) GB"

# Disk Usage
Write-Log "--- Disk Usage ---"
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $size = [math]::Round(($_.Used + $_.Free)/1GB,2)
    $used = [math]::Round(($_.Used/1GB),2)
    $free = [math]::Round(($_.Free/1GB),2)
    Write-Log ("Drive {0}: Used {1} GB / {2} GB (Free {3} GB)" -f $_.Name, $used, $size, $free)
}

# Network Adapters
Write-Log "--- Network ---"
Get-NetAdapter | Sort-Object Name | ForEach-Object {
    Write-Log ("{0} - Status: {1}, MAC: {2}, Speed: {3}" -f $_.Name, $_.Status, $_.MacAddress, $_.LinkSpeed)
}

# IP Config summary
Write-Log "--- IP Configuration ---"
Get-NetIPConfiguration | ForEach-Object {
    $ifName = $_.InterfaceAlias
    $ipv4 = ($_.IPv4Address | Select-Object -ExpandProperty IPv4Address -ErrorAction SilentlyContinue) -join ", "
    $gw   = ($_.IPv4DefaultGateway | Select-Object -ExpandProperty NextHop -ErrorAction SilentlyContinue)
    $dns  = ($_.DNSServer.ServerAddresses) -join ", "
    Write-Log ("IF: {0} | IPv4: {1} | GW: {2} | DNS: {3}" -f $ifName, $ipv4, $gw, $dns)
}

# Services not running (potential issues)
Write-Log "--- Services (Stopped/Failed) ---"
Get-Service | Where-Object { $_.Status -ne 'Running' } |
    Select-Object Name, Status | ForEach-Object {
        Write-Log ("{0} - {1}" -f $_.Name, $_.Status)
    }

Write-Log "=== END OF REPORT ==="
Write-Log "Saved to $log"
