<#
Windows-Update-Status.ps1
Purpose: Summarize Windows Update & reboot status for troubleshooting
Run as: Standard user OK; Admin recommended
Output: logs\winupdate_YYYY-MM-DD_HHMM.txt
#>

# Ensure logs folder
$logDir = Join-Path $PSScriptRoot "..\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = (Get-Date).ToString("yyyy-MM-dd_HHmm")
$log = Join-Path $logDir "winupdate_$stamp.txt"

function Write-Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    $line | Tee-Object -FilePath $log -Append
}

Write-Log "=== WINDOWS UPDATE STATUS ==="
Write-Log "User: $env:USERNAME  Host: $env:COMPUTERNAME"

# ---- Pending reboot checks ----
function Test-PendingReboot {
    $pending = $false
    $details = @()

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) { $pending = $true; $details += $p }
    }

    # Pending file rename operations
    try {
        $pfro = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
        if ($pfro -and $pfro.PendingFileRenameOperations) { $pending = $true; $details += "PendingFileRenameOperations" }
    } catch {}

    [PSCustomObject]@{
        IsPending = $pending
        Reasons   = if ($details) { $details -join "; " } else { "None" }
    }
}

$reboot = Test-PendingReboot
Write-Log ("Pending Reboot: {0}" -f ($(if($reboot.IsPending){"YES ❌"}else{"No ✅"})))
Write-Log ("Reasons: {0}" -f $reboot.Reasons)

# ---- Last installed updates (recent) ----
Write-Log "--- Recently Installed Updates (via Get-HotFix) ---"
try {
    Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 |
        ForEach-Object {
            $date = ($_.InstalledOn) -as [datetime]
            Write-Log ("{0}  KB{1}  {2}" -f ($date.ToString("yyyy-MM-dd")), ($_.HotFixID -replace 'KB',''), $_.Description)
        }
} catch {
    Write-Log "Get-HotFix unavailable or failed."
}

# ---- Windows Update client errors (last 30 days) ----
Write-Log "--- Windows Update Errors (last 30 days) ---"
try {
    $start = (Get-Date).AddDays(-30)
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-WindowsUpdateClient/Operational'
        Level   = 2   # Error
        StartTime = $start
    } -ErrorAction SilentlyContinue

    if ($events) {
        $events | Select-Object -First 20 | ForEach-Object {
            Write-Log ("{0}  ID:{1}  {2}" -f $_.TimeCreated.ToString("yyyy-MM-dd HH:mm"), $_.Id, $_.Message.Replace("`r`n"," "))
        }
    } else {
        Write-Log "No Windows Update error events in last 30 days. ✅"
    }
} catch {
    Write-Log "Could not read WindowsUpdateClient log."
}

# ---- Search for pending/available updates (best-effort) ----
# Uses Windows Update COM API (works on most client SKUs without extra modules)
Write-Log "--- Update Scan (Available / Pending) ---"
try {
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    # IsInstalled=0 -> not installed; IsHidden=0 -> visible
    $result   = $searcher.Search("IsInstalled=0 and IsHidden=0")
    $count    = $result.Updates.Count
    Write-Log ("Available updates: {0}" -f $count)
    if ($count -gt 0) {
        0..($count-1) | ForEach-Object {
            $u = $result.Updates.Item($_)
            Write-Log ("- {0} | KBs: {1}" -f $u.Title, (($u.KBArticleIDs) -join ',' ))
        }
    }
} catch {
    Write-Log "Update scan not available on this system (COM API blocked or service disabled)."
}

Write-Log "=== END WINDOWS UPDATE STATUS ==="
Write-Log "Saved to $log"
