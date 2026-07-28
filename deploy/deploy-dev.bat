@echo off
REM ============================================================
REM  dwisCOST DEV - Build/Deploy (Manual)
REM  git pull -> build -> JAR copy
REM ============================================================
setlocal

set REPO=C:\DCIS\build\dwCost-dev
set DEPLOY=C:\DCIS\webapp\api_dev
set BRANCH=master
set PROFILE=dev
set MVN=C:\apache-maven-3.9.9\bin\mvn.cmd

echo ============================================================
echo  dwisCOST DEV Build/Deploy
echo ============================================================
echo.

cd /d "%REPO%" || (echo [ERR] repo not found: %REPO% & pause & exit /b 1)

echo [1/3] git pull ...
git fetch origin %BRANCH%
git reset --hard origin/%BRANCH%
echo.

echo [2/3] mvn build (offline) ...
call "%MVN%" -o package -Dmaven.test.skip=true -B
if errorlevel 1 (echo [ERR] Build failed! & pause & exit /b 1)
echo.

echo [3/3] JAR copy -^> %DEPLOY% ...
if not exist "%DEPLOY%\backup" mkdir "%DEPLOY%\backup"
for %%f in (target\dwisCOST-*.jar) do echo %%f| findstr /v ".original" >nul && (
    copy /Y "%%f" "%DEPLOY%\dwisCOST-%PROFILE%.jar" >nul
    copy /Y "%%f" "%DEPLOY%\backup\" >nul
    echo   copied: %%f
)
echo.

echo ============================================================
echo  Build/Deploy Done!
echo ============================================================
echo.
echo  [Next]
echo   1. Close existing service CMD window
echo   2. Start service:
echo.
echo      cd %DEPLOY%
echo      java -Xms1g -Xmx1g -jar dwisCOST-%PROFILE%.jar --spring.profiles.active=%PROFILE%
echo.
echo ============================================================
pause
endlocal
