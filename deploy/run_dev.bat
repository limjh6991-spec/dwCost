@echo off
setlocal

set JAR_DIR=C:\DCIS\webapp\api_dev
set JAR_FILE=dwisCOST-dev.jar
set ERR_FILE=%JAR_DIR%\startup_error.log

if not exist "%JAR_DIR%\%JAR_FILE%" (
    echo [ERROR] No JAR file found: %JAR_DIR%\%JAR_FILE%
    pause
    exit /b 1
)

echo [STEP 1] Java version:
java -version 2>&1
echo.

echo [STEP 2] JAR file size:
dir "%JAR_DIR%\%JAR_FILE%"
echo.

echo [STEP 3] Starting Spring Boot...
echo stderr will be captured to: %ERR_FILE%
echo ============================================

java -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -Xms1g -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -jar "%JAR_DIR%\%JAR_FILE%" --spring.profiles.active=dev 2>"%ERR_FILE%"

echo ============================================
echo [INFO] Exit code: %ERRORLEVEL%
echo.

if exist "%ERR_FILE%" (
    echo [INFO] === stderr output ===
    type "%ERR_FILE%"
    echo.
    echo [INFO] === end stderr ===
)

echo [INFO] Finished at %date% %time%
pause
