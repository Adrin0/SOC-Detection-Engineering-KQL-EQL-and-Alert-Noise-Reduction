# First-logon bootstrap for the Windows 11 endpoint VM 104 (soc-win-ep).
# Runs once from the answer ISO via autounattend.xml FirstLogonCommands, as the local admin.
# Contains no secrets. Log: C:\Windows\Temp\soc-bootstrap.log
$ErrorActionPreference = 'Continue'
Start-Transcript -Path C:\Windows\Temp\soc-bootstrap.log -Append
$src = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Network: static address on vmbr0 ---
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
Remove-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Set-NetIPInterface -InterfaceIndex $nic.ifIndex -Dhcp Disabled
New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress 192.168.1.62 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses 192.168.1.1
Set-NetConnectionProfile -InterfaceIndex $nic.ifIndex -NetworkCategory Private
Start-Sleep 10

# --- Power: never sleep (it is a server-like lab guest) ---
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /hibernate off

# --- Management: OpenSSH, key-only, from hadron and the mgmt VM only ---
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*'
if ($cap.State -ne 'Installed') { Add-WindowsCapability -Online -Name $cap.Name }
Start-Service sshd   # first start creates %ProgramData%\ssh and sshd_config
Copy-Item "$src\administrators_authorized_keys" "$env:ProgramData\ssh\administrators_authorized_keys" -Force
icacls "$env:ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant 'SYSTEM:F' /grant '*S-1-5-32-544:F'
$cfg = "$env:ProgramData\ssh\sshd_config"
(Get-Content $cfg) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication no' | Set-Content $cfg
Set-Service sshd -StartupType Automatic
Restart-Service sshd
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name 'SOC-SSH-In' -DisplayName 'SOC: SSH from hadron and mgmt' -Direction Inbound -Protocol TCP -LocalPort 22 -RemoteAddress 192.168.1.56,192.168.1.45 -Action Allow
New-NetFirewallRule -Name 'SOC-ICMP-In' -DisplayName 'SOC: ping from hadron and mgmt' -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress 192.168.1.56,192.168.1.45 -Action Allow

# --- Audit policy and PowerShell logging (DET-001 4625, DET-002 4104) ---
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable
auditpol /set /subcategory:"Process Creation" /success:enable
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Force |
  New-ItemProperty -Name EnableScriptBlockLogging -Value 1 -PropertyType DWord -Force

# --- Sysmon (SwiftOnSecurity config), only if Microsoft-signed ---
$sm = 'C:\Program Files\Sysmon'
Expand-Archive "$src\Sysmon.zip" $sm -Force
$sig = Get-AuthenticodeSignature "$sm\Sysmon64.exe"
if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -like '*O=Microsoft Corporation*') {
  Copy-Item "$src\sysmonconfig-export.xml" $sm
  & "$sm\Sysmon64.exe" -accepteula -i "$sm\sysmonconfig-export.xml"
} else { Write-Warning "Sysmon64.exe signature check failed: $($sig.Status)" }

# --- Winlogbeat 9.5.6 (installed, not started: setup runs first over SSH) ---
$wb = 'C:\Program Files\Winlogbeat'
Expand-Archive "$src\winlogbeat-9.5.6-windows-x86_64.zip" C:\Windows\Temp\wb -Force
Move-Item C:\Windows\Temp\wb\winlogbeat-9.5.6-windows-x86_64 $wb -Force
Copy-Item "$src\winlogbeat.yml", "$src\ca.crt" $wb -Force
& "$wb\install-service-winlogbeat.ps1"
Set-Service winlogbeat -StartupType Automatic

New-Item -ItemType File C:\Windows\Temp\soc-bootstrap.done -Force | Out-Null
Stop-Transcript
