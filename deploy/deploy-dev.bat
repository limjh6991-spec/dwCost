@echo off
REM ============================================================
REM  dwisCOST DEV - auto build/deploy (server-side, no CI)
REM  - checks GitHub for new commit; if changed: pull->build->restart
REM  - run periodically via Task Scheduler (every 5 min)
REM  - must run as the user whose .m2 has the deps (offline build)
REM ============================================================
setlocal enabledelayedexpansion

set REPO=C:\DCIS\build\dwCost-dev
set DEPLOY=C:\DCIS\webapp\api_dev
set BRANCH=master
set PROFILE=dev
set PORT=9091
set MVN=C:\apache-maven-3.9.9\bin\mvn.cmd

cd /d "%REPO%" || (echo [ERR] repo not found: %REPO% & exit /b 1)

REM --- new commit on remote? ---
git fetch origin %BRANCH% 1>nul 2>nul
for /f %%h in ('git rev-parse HEAD') do set LOCAL=%%h
for /f %%h in ('git rev-parse origin/%BRANCH%') do set REMOTE=%%h
if "!LOCAL!"=="!REMOTE!" (echo [%date% %time%] no change & exit /b 0)

echo [%date% %time%] deploying new commit: !REMOTE!
git reset --hard origin/%BRANCH%

echo [build] mvn -o (offline) ...
call "%MVN%" -o clean package -Dmaven.test.skip=true -B
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

echo [done] %date% %time%  (log: %DEPLOY%\app.log)
endlocal
