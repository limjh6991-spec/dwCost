@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  dwisCOST 서버 빌드 스크립트
REM   - git 최신 소스 내려받아 jar 빌드 (오프라인/에어갭)
REM   - 배포/기동은 이 스크립트가 안 함 → startCost.bat 이 담당
REM   - 실행: 이 파일 더블클릭 (또는 cmd 에서 실행)
REM ============================================================

REM ===== 설정 (필요하면 여기만 수정) =====
set REPO_URL=https://github.com/limjh6991-spec/dwCost.git
set BRANCH=master
set SRC_DIR=C:\DCIS\build\dwCost-prod
set MVN=C:\apache-maven-3.9.9\bin\mvn.cmd
set DEPLOY_DIR=C:\DCIS\webapp\api
set COPY_TO_DEPLOY=Y
REM  COPY_TO_DEPLOY=Y 면 빌드된 jar를 운영 폴더(api)로 복사 (startCost.bat이 최신 jar 자동 선택)
REM  N 이면 빌드만 하고 target 폴더에 둠

echo ============================================================
echo  [1/3] 소스 내려받기  (%REPO_URL%  %BRANCH%)
echo ============================================================
if not exist "%SRC_DIR%\.git" (
  echo   최초 clone ...
  git clone "%REPO_URL%" "%SRC_DIR%" || (echo [ERR] git clone 실패 & pause & exit /b 1)
)
cd /d "%SRC_DIR%" || (echo [ERR] 소스 폴더 없음: %SRC_DIR% & pause & exit /b 1)
git fetch origin %BRANCH% || (echo [ERR] git fetch 실패 & pause & exit /b 1)
git reset --hard origin/%BRANCH% || (echo [ERR] git reset 실패 & pause & exit /b 1)
for /f %%h in ('git rev-parse --short HEAD') do echo   현재 커밋: %%h

echo.
echo ============================================================
echo  [2/3] 빌드  (mvn -o -Drevision=prod, 오프라인)
echo ============================================================
call "%MVN%" -o -Drevision=prod clean package -Dmaven.test.skip=true -B
if errorlevel 1 (echo [ERR] 빌드 실패 - 새 의존성이면 .m2 시딩 필요 & pause & exit /b 1)

echo.
echo ============================================================
echo  [3/3] 결과 jar 확인
echo ============================================================
set JAR=
for /f "delims=" %%F in ('dir "%SRC_DIR%\target\dwisCOST-prod-*.jar" /b /o-d 2^>nul ^| findstr /v /i ".original"') do (
  if not defined JAR set JAR=%%F
)
if "!JAR!"=="" (echo [ERR] 빌드된 jar 를 못 찾음 & pause & exit /b 1)
echo   빌드된 jar : %SRC_DIR%\target\!JAR!

if /I "%COPY_TO_DEPLOY%"=="Y" (
  if not exist "%DEPLOY_DIR%" mkdir "%DEPLOY_DIR%"
  copy /Y "%SRC_DIR%\target\!JAR!" "%DEPLOY_DIR%\" >nul && echo   복사 완료 : %DEPLOY_DIR%\!JAR!
)

echo.
echo ============================================================
echo  [완료] 빌드 끝.
if /I "%COPY_TO_DEPLOY%"=="Y" (
  echo   다음: %DEPLOY_DIR% 에서 startCost.bat 실행하면 방금 jar로 뜹니다.
) else (
  echo   jar 위치: %SRC_DIR%\target\!JAR!
)
echo ============================================================
pause
endlocal
