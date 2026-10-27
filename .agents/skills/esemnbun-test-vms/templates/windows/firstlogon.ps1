param([string]$Drive)
$ErrorActionPreference = 'Continue'
$root = "$($Drive):\"
Start-Transcript -Path C:\esemnbun-setup.log -Append
# virtio drivers (network, rng, serial, balloon) for QEMU on ARM64
Get-ChildItem "$root\drivers" -Recurse -Filter *.inf | ForEach-Object { pnputil /add-driver $_.FullName /install }
# never sleep / lock while testing
powercfg /change standby-timeout-ac 0; powercfg /change monitor-timeout-ac 0
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f
# Remote Desktop
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
# OpenSSH server with key auth for the Macs
for ($i = 0; $i -lt 30 -and -not (Test-Connection 1.1.1.1 -Count 1 -Quiet); $i++) { Start-Sleep 5 }
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service sshd -StartupType Automatic; Start-Service sshd
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force
Copy-Item "$root\setup\authorized_keys" C:\ProgramData\ssh\administrators_authorized_keys -Force
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F'
if (-not (Get-NetFirewallRule -Name sshd -ErrorAction SilentlyContinue)) { New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 }
Set-Content C:\esemnbun-setup.done (Get-Date)
Stop-Transcript
