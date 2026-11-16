<#
  사내 DB(10.100.40.17:14233) VPN 연결 유지 — Windows 작업 스케줄러가 5분마다 실행한다.

  - DB 포트에 TCP 접속을 한 번 열었다 닫는다. VPN 터널에 트래픽이 생겨 유휴 시간 초과로 끊기는 것을 막는다.
  - 연결 상태가 바뀔 때만(정상→끊김, 끊김→정상) 로그에 한 줄 남긴다. 결산 자동 점검 예약작업이 이 로그를 읽어 알린다.
  - VPN 재연결은 하지 않는다(FortiClient 무료판은 명령줄 연결이 없고, 비밀번호 저장도 회사 설정으로 꺼져 있음).
#>
$ErrorActionPreference = 'SilentlyContinue'
$target = '10.100.40.17'; $port = 14233
$dir = Join-Path $env:USERPROFILE 'OneDrive\文档\개발\도우인시스\결산자동'
$log = Join-Path $dir 'vpn_연결로그.txt'
$state = Join-Path $env:LOCALAPPDATA 'dowoo_vpn_state.txt'

$ok = $false
$client = New-Object System.Net.Sockets.TcpClient
try {
    $task = $client.ConnectAsync($target, $port)
    $ok = $task.Wait(5000) -and $client.Connected
} finally { $client.Close() }

$now = if ($ok) { 'UP' } else { 'DOWN' }
$prev = if (Test-Path $state) { (Get-Content $state -Raw).Trim() } else { '' }
if ($now -ne $prev) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $msg = if ($ok) { '연결됨' } else { '끊김 (VPN 재연결 필요)' }
    Add-Content -Path $log -Value ("{0}`t{1}`t{2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $now, $msg) -Encoding UTF8
    Set-Content -Path $state -Value $now -Encoding ASCII
}
