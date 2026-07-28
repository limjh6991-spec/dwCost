@echo off
REM ============================================================
REM  dwisCOST PROD - Start Service
REM ============================================================
setlocal

set JAR_DIR=C:\DCIS\webapp\api_prod
set JAR_FILE=dwisCOST-prod.jar
set PROFILE=prod2

if not exist "%JAR_DIR%\%JAR_FILE%" (
    echo [ERROR] JAR file not found: %JAR_DIR%\%JAR_FILE%
    pause
    exit /b 1
)

echo [INFO] Starting %JAR_FILE% (profile: %PROFILE%)

cd /d "%JAR_DIR%"
java -Xms1g -Xmx1g ^
     -XX:+UseG1GC -XX:MaxGCPauseMillis=200 ^
     -Djava.net.preferIPv4Stack=true ^
     -Dfile.encoding=UTF-8 ^
     -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=%JAR_DIR%\heapdump.hprof ^
     -jar "%JAR_FILE%" ^
     --spring.profiles.active=%PROFILE%

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Service stopped with error.
    pause
    exit /b 1
)

echo [INFO] Service stopped.
pause
endlocal
