<#
  vpn_guard.ps1 을 로그온 시 자동 실행하도록 예약작업 등록 (현재 사용자, 관리자 권한 불필요).
    설치:  powershell -ExecutionPolicy Bypass -File scripts\auto_settle\install_vpn_guard.ps1
    제거:  powershell -ExecutionPolicy Bypass -File scripts\auto_settle\install_vpn_guard.ps1 -Remove
  - 작업 이름: DowooVpnGuard. 배터리에서도 실행, 멈추면 1분 뒤 재시작, 실행 시간 제한 없음.
  - 기존 5분 주기 작업(vpn_keepalive.ps1)은 그대로 둔다(같은 로그 파일을 쓰며 상태 파일로 중복 기록을 막음).
#>
param([switch]$Remove)
$name = 'DowooVpnGuard'
if ($Remove) {
    Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'vpn_guard\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    "제거 완료"; return
}
$script = Join-Path $PSScriptRoot 'vpn_guard.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
            -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Description 'Dowoo 사내 DB VPN 연결 유지·감시' -Force | Out-Null
Start-ScheduledTask -TaskName $name
"설치 완료 — 지금 시작했고, 다음부터 로그온 시 자동 실행됩니다."
