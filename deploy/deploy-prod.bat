@echo off
REM ============================================================
REM  dwisCOST PROD - manual build/deploy (server-side, no CI)
REM  - run by hand (double-click). Asks for DEPLOY confirmation.
REM  - must run as the user whose .m2 has the deps (offline build)
REM ============================================================
setlocal

set REPO=C:\DCIS\build\dwCost
set DEPLOY=C:\DCIS\webapp\api_prod
set BRANCH=master
set PROFILE=prod1
set PORT=9090
set MVN=C:\apache-maven-3.9.9\bin\mvn.cmd

echo *** PRODUCTION deploy (port %PORT%, profile %PROFILE%) ***
set /p OK="Type DEPLOY to proceed: "
if /I not "%OK%"=="DEPLOY" (echo canceled & exit /b 1)

cd /d "%REPO%" || (echo [ERR] repo not found: %REPO% & exit /b 1)
git fetch origin %BRANCH% 1>nul 2>nul
git reset --hard origin/%BRANCH%

echo [build] mvn -o (offline) ...
call "%MVN%" -o clean package -DskipTests -B
if errorlevel 1 (echo [ERR] build failed & exit /b 1)

echo [stop] port %PORT% ...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr :%PORT% ^| findstr LISTENING') do taskkill /F /PID %%p 1>nul 2>nul
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
