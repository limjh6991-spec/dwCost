@echo off
REM ============================================================
REM  dwisCOST PROD - manual build/deploy (server-side, no CI)
REM  - run by hand (double-click). Asks for DEPLOY confirmation.
REM  - must run as the user whose .m2 has the deps (offline build)
REM ============================================================

REM --- auto-elevate: 운영 java 가 관리자 레벨로 떠 있어, 종료/재기동에 관리자 권한 필요 ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [info] 관리자 권한으로 다시 실행합니다...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

setlocal

set REPO=C:\DCIS\build\dwCost-prod
set DEPLOY=C:\DCIS\webapp\api_prod
set BRANCH=master
set PROFILE=prod2
set PORT=9090
set MVN=C:\apache-maven-3.9.9\bin\mvn.cmd

echo *** PRODUCTION deploy (port %PORT%, profile %PROFILE%) ***
set /p OK="Type DEPLOY to proceed: "
if /I not "%OK%"=="DEPLOY" (echo canceled & exit /b 1)

cd /d "%REPO%" || (echo [ERR] repo not found: %REPO% & exit /b 1)
git fetch origin %BRANCH% 1>nul 2>nul
git reset --hard origin/%BRANCH%

echo [build] mvn -o (offline, revision=prod) ...
call "%MVN%" -o -Drevision=prod clean package -Dmaven.test.skip=true -B
if errorlevel 1 (echo [ERR] build failed & exit /b 1)

echo [stop] port %PORT% ...
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ('  killing PID ' + $_.OwningProcess); Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"
timeout /t 3 >nul

echo [deploy] jar -> %DEPLOY% ...
if not exist "%DEPLOY%\backup" mkdir "%DEPLOY%\backup"
for %%f in (target\dwisCOST-*.jar) do echo %%f| findstr /v ".original" >nul && (copy /Y "%%f" "%DEPLOY%\dwisCOST-%PROFILE%.jar" >nul & copy /Y "%%f" "%DEPLOY%\backup\" >nul)

echo [start] service on port %PORT% ...
cd /d "%DEPLOY%"
start "dwisCOST-%PROFILE%" /min cmd /c "java -Xms1g -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=heapdump.hprof -jar dwisCOST-%PROFILE%.jar --spring.profiles.active=%PROFILE% >> app.log 2>&1"

echo [done] PROD deployed %date% %time%  (log: %DEPLOY%\app.log)
pause
endlocal
