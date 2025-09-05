<#
Startup-Apps-Report.ps1
Purpose: List programs/services that run at startup/login and their impact
Run as: Standard user OK; Admin recommended for services
Output: logs\startup_YYYY-MM-DD_HHMM.txt
#>

# Ensure logs folder
$logDir = Join-Path $PSScriptRoot "..\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = (Get-Date).ToString("yyyy-MM-dd_HHmm")
$log = Join-Path $logDir "startup_$stamp.txt"

function Write-Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    $line | Tee-Object -FilePath $log -Append
}

Write-Log "=== STARTUP APPS REPORT ==="
Write-Log "User: $env:USERNAME  Host: $env:COMPUTERNAME"

# --- Startup apps via Windows 10/11 "Startup Apps" provider (if available) ---
Write-Log "--- Startup Apps (Modern Provider) ---"
try {
    $apps = Get-CimInstance -Namespace root\cimv2\mdm\dmmap -ClassName MDM_Startup_StartupApp -ErrorAction Stop
    if ($apps) {
        $apps | Sort-Object InstanceID | ForEach-Object {
            Write-Log ("Name: {0} | Enabled: {1} | Command: {2}" -f $_.InstanceID, $_.Enabled, $_.CmdLine)
        }
    } else { Write-Log "No entries found in modern provider." }
} catch { Write-Log "Modern Startup Apps provider not available (OK to ignore)." }

# --- Classic Run keys (per-machine & per-user) ---
Write-Log "--- Registry Run Keys ---"
$runKeys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
)
foreach ($rk in $runKeys) {
    try {
        if (Test-Path $rk) {
            Write-Log ("[{0}]" -f $rk)
            $vals = Get-ItemProperty -Path $rk
            ($vals.PSObject.Properties | Where-Object { $_.Name -notin 'PSPath','PSParentPath','PSChildName','PSDrive','PSProvider' }) |
                ForEach-Object { Write-Log ("  {0} = {1}" -f $_.Name, $_.Value) }
        }
    } catch { Write-Log ("  (Could not read {0})" -f $rk) }
}

# --- Startup folder shortcuts (per-machine & per-user) ---
Write-Log "--- Startup Folders ---"
$folders = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp",
    "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($f in $folders) {
    Write-Log ("[{0}]" -f $f)
    if (Test-Path $f) {
        Get-ChildItem $f -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Log ("  {0}" -f $_.FullName)
        }
    } else { Write-Log "  (folder not found)" }
}

# --- Services set to Auto/AutoDelayed ---
Write-Log "--- Services (Automatic/Delayed) ---"
try {
    Get-Service | Where-Object { $_.StartType -in ('Automatic','AutomaticDelayedStart') } |
        Sort-Object DisplayName |
        ForEach-Object { Write-Log ("{0} | Status: {1} | StartType: {2}" -f $_.DisplayName, $_.Status, $_.StartType) }
} catch { Write-Log "Could not enumerate services." }

# --- Scheduled tasks that run at logon ---
Write-Log "--- Scheduled Tasks (At Logon) ---"
try {
    $tasks = Get-ScheduledTask | Where-Object {
        $_.Triggers | Where-Object { $_.TriggerType -eq 'Logon' -or $_.TriggerType -eq 'Startup' }
    }
    if ($tasks) {
        $tasks | ForEach-Object {
            $trigs = ($_.Triggers | ForEach-Object { $_.TriggerType }) -join ','
            Write-Log ("{0} | Triggers: {1} | State: {2}" -f $_.TaskName, $trigs, $_.State)
        }
    } else { Write-Log "No logon/startup scheduled tasks found." }
} catch { Write-Log "Scheduled Tasks not available (need admin on some systems)." }

# --- Optional: Startup impact (best-effort) ---
# Windows doesn't expose the "Startup impact" rating via a stable API.
# We approximate by listing everything and letting the tech decide what to disable.
Write-Log "Tip: Disable non-essential entries via Task Manager > Startup, or Settings > Apps > Startup."

Write-Log "=== END STARTUP APPS REPORT ==="
Write-Log "Saved to $log"
