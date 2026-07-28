@echo off
REM ============================================================
REM  dwisCOST DEV - 수동 빌드/배포
REM  git pull -> 빌드 -> JAR 복사 (서비스 종료/기동은 수동)
REM ============================================================
setlocal

set REPO=C:\DCIS\build\dwCost-dev
set DEPLOY=C:\DCIS\webapp\api_dev
set BRANCH=master
set PROFILE=dev
set MVN=C:\apache-maven-3.9.9\bin\mvn.cmd

echo ============================================================
echo  dwisCOST DEV 빌드/배포
echo ============================================================
echo.

cd /d "%REPO%" || (echo [ERR] repo not found: %REPO% & pause & exit /b 1)

echo [1/3] git pull ...
git fetch origin %BRANCH%
git reset --hard origin/%BRANCH%
echo.

echo [2/3] mvn build (offline) ...
if exist "%REPO%\target" rmdir /s /q "%REPO%\target" 2>nul
call "%MVN%" -o clean package -Dmaven.test.skip=true -B
if errorlevel 1 (echo [ERR] 빌드 실패! & pause & exit /b 1)
echo.

echo [3/3] JAR 복사 -^> %DEPLOY% ...
if not exist "%DEPLOY%\backup" mkdir "%DEPLOY%\backup"
for %%f in (target\dwisCOST-*.jar) do echo %%f| findstr /v ".original" >nul && (
    copy /Y "%%f" "%DEPLOY%\dwisCOST-%PROFILE%.jar" >nul
    copy /Y "%%f" "%DEPLOY%\backup\" >nul
    echo   복사 완료: %%f
)
echo.

echo ============================================================
echo  빌드/배포 완료!
echo ============================================================
echo.
echo  [다음 단계]
echo   1. 기존 서비스 CMD 창을 수동으로 종료하세요
echo   2. 아래 명령어로 서비스를 기동하세요:
echo.
echo      cd %DEPLOY%
echo      java -Xms1g -Xmx1g -jar dwisCOST-%PROFILE%.jar --spring.profiles.active=%PROFILE%
echo.
echo ============================================================
pause
endlocal
