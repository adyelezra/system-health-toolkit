# System Health Toolkit (Windows)

Windows PowerShell scripts for quick diagnostics and health checks.

## 🖥️ System Health Report
- Script: `scripts/System-Health-Report.ps1`
- Collects OS version, uptime, CPU/RAM, disk usage, network adapters, IP configuration, and non-running services.
- Output saved to `logs/sysreport_TIMESTAMP.txt`.
- Use when investigating performance issues, post-update problems, or for baseline system inventory.

## 💾 Disk Health Check
- Script: `scripts/Disk-Health-Check.ps1`
- Uses `Get-PhysicalDisk` + `Get-StorageReliabilityCounter` when available, and falls back to WMI SMART status for older systems.
- Reports: health status, size, media type (HDD/SSD), temperature, power-on hours, read/write errors, retries, and SMART predictive failure (if available).
- Output saved to `logs/diskhealth_TIMESTAMP.txt`.

**When to use**
- System feels unstable or crashes during file operations
- Clicking/whirring HDD sounds
- Frequent disk-related errors in Event Viewer
- Before cloning/migrating OS to another drive

## 🔄 Windows Update Status
- Script: `scripts/Windows-Update-Status.ps1`
- Shows **pending reboot** state, lists **recently installed updates**, surfaces **Windows Update errors** from the last 30 days, and performs a quick **available updates scan**.
- Output saved to `logs/winupdate_TIMESTAMP.txt`.

**When to use**
- User says “Windows keeps asking to restart”
- Updates failed or are stuck
- Verifying that critical updates were installed

## ⚡ Startup Apps Report
- Script: `scripts/Startup-Apps-Report.ps1`
- Lists programs that launch at boot/login from **Registry Run keys**, **Startup folders**, **Scheduled Tasks (Logon/Startup)**, and **Automatic services**. Attempts modern Startup Apps provider when available.
- Output saved to `logs/startup_TIMESTAMP.txt`.

**When to use**
- Slow boot or login
- Too many apps launching automatically
- Investigating what re-enables itself after cleanup
