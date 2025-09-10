# 🛠️ IT Support Toolkit (Windows)

PowerShell scripts for quick diagnostics and health checks on Windows systems.

---

## 🖥️ System Health Report
- **Script:** `scripts/System-Health-Report.ps1`  
- Collects OS info, CPU/RAM, disk usage, network adapters, IP configuration, and non-running services.  
- **Output:** `logs/sysreport_TIMESTAMP.txt`

---

## 💾 Disk Health Check
- **Script:** `scripts/Disk-Health-Check.ps1`  
- Checks disk type, size, health, temperature, and SMART status.  
- **Output:** `logs/diskhealth_TIMESTAMP.txt`

---

## 🔄 Windows Update Status
- **Script:** `scripts/Windows-Update-Status.ps1`  
- Checks pending updates, recently installed updates, errors, and available updates.  
- **Output:** `logs/winupdate_TIMESTAMP.txt`

---

## ⚡ Startup Apps Report
- **Script:** `scripts/Startup-Apps-Report.ps1`  
- Lists programs and services that launch at boot/login.  
- **Output:** `logs/startup_TIMESTAMP.txt`

---

## 🌐 Network Connectivity Report
- **Script:** `scripts/Network-Connectivity-Report.ps1`  
- Checks network adapters, IP configuration, connectivity, and DNS resolution.  
- **Output:** `logs/network_TIMESTAMP.txt`

---

## ⚡ How to Run
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\scripts\<Script-Name>.ps1
