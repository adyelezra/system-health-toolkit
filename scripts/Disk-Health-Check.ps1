<#
Disk-Health-Check.ps1
Purpose: Check physical disk health on Windows (SMART / reliability counters)
Run as: Administrator recommended
Output: logs\diskhealth_YYYY-MM-DD_HHMM.txt
#>

# Ensure logs folder
$logDir = Join-Path $PSScriptRoot "..\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = (Get-Date).ToString("yyyy-MM-dd_HHmm")
$log = Join-Path $logDir "diskhealth_$stamp.txt"

function Write-Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    $line | Tee-Object -FilePath $log -Append
}

Write-Log "=== DISK HEALTH CHECK ==="
Write-Log "User: $env:USERNAME  Host: $env:COMPUTERNAME"

# Helper: Try to get reliability counters (best quality on Win8/2012+)
function Get-ReliabilitySafe {
    try {
        $counters = Get-PhysicalDisk -ErrorAction Stop |
            ForEach-Object {
                $pd = $_
                try {
                    $rc = Get-StorageReliabilityCounter -PhysicalDisk $pd -ErrorAction Stop
                    [PSCustomObject]@{
                        FriendlyName = $pd.FriendlyName
                        SerialNumber  = $pd.SerialNumber
                        MediaType     = $pd.MediaType
                        HealthStatus  = $pd.HealthStatus
                        SizeGB        = [math]::Round($pd.Size/1GB,2)
                        TemperatureC  = $rc.Temperature
                        PowerOnHours  = $rc.PowerOnHours
                        Wear          = $rc.Wear
                        ReadErrors    = $rc.ReadErrorsTotal
                        WriteErrors   = $rc.WriteErrorsTotal
                        Retries       = $rc.RetriesOnError
                        PredictiveFailure = $false
                        Source        = "StorageReliabilityCounter"
                    }
                } catch {
                    [PSCustomObject]@{
                        FriendlyName = $pd.FriendlyName
                        SerialNumber  = $pd.SerialNumber
                        MediaType     = $pd.MediaType
                        HealthStatus  = $pd.HealthStatus
                        SizeGB        = [math]::Round($pd.Size/1GB,2)
                        TemperatureC  = $null
                        PowerOnHours  = $null
                        Wear          = $null
                        ReadErrors    = $null
                        WriteErrors   = $null
                        Retries       = $null
                        PredictiveFailure = $null
                        Source        = "PhysicalDiskOnly"
                    }
                }
            }
        return $counters
    } catch {
        return $null
    }
}

# Helper: Basic SMART status via WMI
function Get-WmiSmartStatus {
    try {
        $status = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction Stop
        $result = foreach ($s in $status) {
            [PSCustomObject]@{
                InstanceName      = $s.InstanceName
                PredictiveFailure = [bool]$s.PredictFailure
                Reason            = if ($s.PredictFailure) { "Drive reports SMART predictive failure" } else { "SMART OK" }
            }
        }
        return $result
    } catch {
        return $null
    }
}

# Collect using modern API first
$records = Get-ReliabilitySafe
$wmi = Get-WmiSmartStatus

# Merge info
if ($records) {
    foreach ($r in $records) {
        if ($wmi) {
            $match = $wmi | Where-Object { $_.InstanceName -match ($r.SerialNumber -replace '\s','') } | Select-Object -First 1
            if ($match) { $r.PredictiveFailure = $match.PredictiveFailure }
        }
    }
}

# Output summary
if ($records) {
    Write-Log "--- Disk Summary ---"
    foreach ($r in $records) {
        Write-Log ("Disk: {0} | SN: {1} | Type: {2} | Size: {3} GB | Health: {4}" -f $r.FriendlyName, $r.SerialNumber, $r.MediaType, $r.SizeGB, $r.HealthStatus)
        if ($r.TemperatureC) { Write-Log ("   Temp: {0} °C" -f $r.TemperatureC) }
        if ($r.PowerOnHours) { Write-Log ("   PowerOnHours: {0}" -f $r.PowerOnHours) }
        if ($r.Wear)         { Write-Log ("   Wear (SSD/NVMe): {0}" -f $r.Wear) }
        if ($r.ReadErrors)   { Write-Log ("   ReadErrors: {0}  WriteErrors: {1}  Retries: {2}" -f $r.ReadErrors, $r.WriteErrors, $r.Retries) }
        if ($null -ne $r.PredictiveFailure) {
            Write-Log ("   SMART Predictive Failure: {0}" -f $(if($r.PredictiveFailure){"YES ❌"}else{"No ✅"}))
        }
    }
} elseif ($wmi) {
    Write-Log "--- SMART Predictive Status (WMI) ---"
    foreach ($d in $wmi) {
        Write-Log ("{0} | PredictiveFailure: {1} | {2}" -f $d.InstanceName, $d.PredictiveFailure, $d.Reason)
    }
} else {
    Write-Log "No disk health APIs available (need admin or newer OS/drivers)."
}

# Recommendations
Write-Log "--- Recommendations ---"
Write-Log "If any disk shows Predictive Failure = YES or abnormal errors/temps:"
Write-Log " - Backup important data immediately."
Write-Log " - Check SATA/NVMe cables / ports if applicable."
Write-Log " - Run vendor diagnostics (SeaTools, WD Dashboard, Samsung Magician, etc)."
Write-Log " - Consider replacing the drive if failures persist."

Write-Log "=== END OF DISK HEALTH CHECK ==="
Write-Log "Saved to $log"
