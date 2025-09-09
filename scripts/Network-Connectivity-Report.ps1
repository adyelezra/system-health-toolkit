<# 
Network-Connectivity-Report.ps1
Quick network health snapshot for L1 support.

Collects:
- Adapter status, link speed, MAC
- IP config (IPv4/IPv6, DNS, Gateway)
- Ping tests: loopback, default gateway(s), 8.8.8.8, 1.1.1.1, and a DNS name
- DNS resolution test

Outputs:
- logs/network_YYYYMMDD_HHMMSS.txt
#>

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir    = "logs"
$logFile   = Join-Path $logDir "network_$timestamp.txt"

if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

function Write-Log($text){ $text | Tee-Object -FilePath $logFile -Append | Out-Null }

Write-Log "===== Network Connectivity Report ====="
Write-Log "Generated: $(Get-Date)"
Write-Log ""

# Adapter overview
Write-Log "== Adapters =="
try {
    Get-NetAdapter |
      Select-Object Name, Status, LinkSpeed, MacAddress |
      Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_ }
} catch {
    Write-Log "Get-NetAdapter not available, skipping adapter overview."
}
Write-Log ""

# IP configuration (brief)
Write-Log "== IP Configuration =="
try {
    Get-NetIPConfiguration |
      Select-Object InterfaceAlias, IPv4Address, IPv6Address, DNSServer, InterfaceDescription |
      Format-List | Out-String | ForEach-Object { Write-Log $_ }
} catch {
    # fallback
    Write-Log "Fallback: ipconfig /all"
    (ipconfig /all) | ForEach-Object { Write-Log $_ }
}
Write-Log ""

# helper: ping target
function Test-Target {
    param([Parameter(Mandatory=$true)][string]$Target, [int]$Count = 4)
    Write-Log "Pinging $Target ($Count x)..."
    try {
        $res = Test-Connection -ComputerName $Target -Count $Count -ErrorAction Stop
        $avg = [Math]::Round(($res | Measure-Object -Property ResponseTime -Average).Average,2)
        $min = [Math]::Round(($res | Measure-Object -Property ResponseTime -Minimum).Minimum,2)
        $max = [Math]::Round(($res | Measure-Object -Property ResponseTime -Maximum).Maximum,2)
        Write-Log ("  Success: {0}/{1} replies, RTT ms (min/avg/max): {2}/{3}/{4}" -f $res.Count,$Count,$min,$avg,$max)
    } catch {
        Write-Log "  FAILED: $_"
    }
    Write-Log ""
}

# targets: loopback, default gateways, public IPs, DNS name
Test-Target -Target "127.0.0.1"

$gateways = @()
try {
    $gateways = (Get-NetIPConfiguration | ForEach-Object { $_.IPv4DefaultGateway.NextHop }) |
                Where-Object { $_ } | Select-Object -Unique
} catch { }

if ($gateways.Count -gt 0) {
    foreach ($gw in $gateways) { Test-Target -Target $gw }
} else {
    Write-Log "No default gateway detected."
    Write-Log ""
}

Test-Target -Target "8.8.8.8"
Test-Target -Target "1.1.1.1"

Write-Log "== DNS Resolution Test =="
try {
    $dns = Resolve-DnsName -Name "microsoft.com" -ErrorAction Stop |
           Where-Object { $_.IPAddress } |
           Select-Object -First 5 Name, Type, IPAddress
    if ($dns) {
        ($dns | Format-Table -AutoSize | Out-String) | ForEach-Object { Write-Log $_ }
    } else {
        Write-Log "No A/AAAA records returned."
    }
} catch {
    Write-Log "DNS resolution failed: $_"
}
Write-Log ""

Write-Log "Report saved: $logFile"
Write-Output "Done. See $logFile"
