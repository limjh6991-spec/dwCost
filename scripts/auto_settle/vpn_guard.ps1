<#
  사내 DB VPN 연결 유지·감시 (상주형) — 로그온 시 예약작업으로 숨김 실행.

  하는 일
  1) 30초마다 DB 포트(10.100.40.17:14233)에 TCP 접속 → VPN 터널에 트래픽을 계속 만든다(유휴 시간 초과 방지).
  2) 프로그램이 도는 동안 Windows 유휴 절전을 막는다(SetThreadExecutionState). 덮개 닫기·수동 절전은 막지 않는다.
  3) 상태가 바뀌면(연결↔끊김) 로그에 한 줄 + 끊김 원인 추적용 정보(전원·배터리·네트워크·VPN 어댑터·최근 절전/깨어남)를 남긴다.
  4) 끊기면 알림 풍선을 띄우고 FortiClient 창을 연다 → 돌아와서 비밀번호만 넣으면 된다.

  하지 않는 일
  - 비밀번호 자동 입력/자동 재연결(회사 설정으로 비밀번호 저장이 막혀 있음 — 우회하지 않는다).

  로그: %USERPROFILE%\OneDrive\文档\개발\도우인시스\결산자동\vpn_연결로그.txt (기존 vpn_keepalive.ps1 과 같은 파일·형식)
  상세: 같은 폴더 vpn_guard_진단.txt
#>
param(
    [string]$Target = '10.100.40.17',
    [int]$Port = 14233,
    [int]$IntervalSec = 30,
    [switch]$Once          # 시험용: 한 번 점검하고 종료
)
$ErrorActionPreference = 'SilentlyContinue'

# ---- 한 번만 실행 (중복 실행 방지) ----
$mutex = New-Object System.Threading.Mutex($false, 'Global\DowooVpnGuard')
if (-not $Once -and -not $mutex.WaitOne(0)) { exit 0 }

$dir = Join-Path $env:USERPROFILE 'OneDrive\文档\개발\도우인시스\결산자동'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$log = Join-Path $dir 'vpn_연결로그.txt'
$diag = Join-Path $dir 'vpn_guard_진단.txt'
$state = Join-Path $env:LOCALAPPDATA 'dowoo_vpn_state.txt'

# ---- 유휴 절전 방지 ----
Add-Type -Namespace Dowoo -Name Power -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint esFlags);
'@
$ES_CONTINUOUS = [uint32]'0x80000000'; $ES_SYSTEM_REQUIRED = [uint32]'0x00000001'
function Set-Awake([bool]$on) {
    if ($on) { [void][Dowoo.Power]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED) }
    else { [void][Dowoo.Power]::SetThreadExecutionState($ES_CONTINUOUS) }
}

# ---- 알림 풍선 ----
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Warning
$tray.Text = 'Dowoo VPN 감시'
function Notify([string]$title, [string]$text) {
    $tray.Visible = $true
    $tray.ShowBalloonTip(15000, $title, $text, [System.Windows.Forms.ToolTipIcon]::Warning)
}

function Test-Db {
    $c = New-Object System.Net.Sockets.TcpClient
    try { $t = $c.ConnectAsync($Target, $Port); return ($t.Wait(5000) -and $c.Connected) } catch { return $false } finally { $c.Close() }
}

function Get-Diag {
    $b = Get-CimInstance Win32_Battery | Select-Object -First 1
    $power = if ($b) { "배터리 {0}% / 전원:{1}" -f $b.EstimatedChargeRemaining, $(if ($b.BatteryStatus -eq 2) { '어댑터' } else { '배터리' }) } else { '배터리 없음' }
    $vpn = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'Forti' } | ForEach-Object { "$($_.Name)=$($_.Status)" }
    $net = Get-NetConnectionProfile | ForEach-Object { "$($_.InterfaceAlias):$($_.Name)/$($_.IPv4Connectivity)" }
    $fc = (Get-Process | Where-Object { $_.ProcessName -match 'Forti' } | Select-Object -ExpandProperty ProcessName -Unique) -join ','
    $pw = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 1, 42, 107, 506, 507; StartTime = (Get-Date).AddHours(-2) } -MaxEvents 3 |
          ForEach-Object { "{0:HH:mm} id{1}" -f $_.TimeCreated, $_.Id }
    "전원[$power] VPN어댑터[$($vpn -join ' ')] 네트워크[$($net -join ' ')] Forti프로세스[$fc] 최근절전/깨어남[$($pw -join ' ')]"
}

function Open-FortiClient {
    $exe = @("$env:ProgramFiles\Fortinet\FortiClient\FortiClient.exe", "${env:ProgramFiles(x86)}\Fortinet\FortiClient\FortiClient.exe") |
           Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) { Start-Process $exe }
}

$prev = if (Test-Path $state) { (Get-Content $state -Raw).Trim() } else { '' }
$downSince = $null
do {
    $ok = Test-Db
    $now = if ($ok) { 'UP' } else { 'DOWN' }
    Set-Awake $ok                                    # 연결돼 있을 때만 유휴 절전 방지
    Set-Content -Path "$state.beat" -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $now) -Encoding ASCII   # 살아 있음 표시
    if ($now -ne $prev) {
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $msg = if ($ok) { '연결됨' } else { '끊김 (VPN 재연결 필요)' }
        Add-Content -Path $log -Value ("{0}`t{1}`t{2}" -f $ts, $now, $msg) -Encoding UTF8
        Add-Content -Path $diag -Value ("{0}`t{1}`t{2}" -f $ts, $now, (Get-Diag)) -Encoding UTF8
        Set-Content -Path $state -Value $now -Encoding ASCII
        if (-not $ok -and -not $Once) {
            $downSince = Get-Date
            Notify 'VPN 끊김' 'DB(10.100.40.17) 연결이 끊겼습니다. FortiClient에서 다시 연결해 주세요.'
            Open-FortiClient
        }
        if ($ok) { $downSince = $null; $tray.Visible = $false }
        $prev = $now
    } elseif (-not $ok -and $downSince -and ((Get-Date) - $downSince).TotalMinutes -ge 30) {
        Notify 'VPN 계속 끊김' ('{0:HH:mm}부터 끊겨 있습니다.' -f $downSince)   # 30분마다 다시 알림
        $downSince = Get-Date
    }
    if ($Once) { "상태: $now"; Get-Diag; break }
    Start-Sleep -Seconds $IntervalSec
} while ($true)

Set-Awake $false
$tray.Dispose()
