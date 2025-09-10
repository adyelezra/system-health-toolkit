# 🛠️ System Health Toolkit (Windows)

PowerShell scripts to quickly check and maintain Windows system health.

---

## 🖥️ System Health Report
- Collects OS info, CPU/RAM, disk usage, network adapters, IP config, and non-running services.
- Output: `logs/sysreport_TIMESTAMP.txt`

## 💾 Disk Health Check
- Checks disk type, size, health, temperature, and SMART status.
- Output: `logs/diskhealth_TIMESTAMP.txt`

## 🔄 Windows Update Status
- Reports pending updates, recent installs, errors, and available updates.
- Output: `logs/winupdate_TIMESTAMP.txt`

## ⚡ Startup Apps Report
- Lists startup programs and automatic services.
- Output: `logs/startup_TIMESTAMP.txt`

## 🌐 Network Connectivity Report
- Checks network adapters, IP configuration, connectivity, and DNS resolution.
- Output: `logs/network_TIMESTAMP.txt`

---

### ⚡ How to Run
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\scripts\<Script-Name>.ps1
