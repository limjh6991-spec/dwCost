@echo off
REM ============================================================
REM  dwisCOST 서버 배포 최초 설정 (한 번만 실행)
REM  - 개발/운영 빌드 클론을 분리 생성 (동시 빌드 충돌 방지)
REM  - 최신 배치 복사 + 개발 자동배포 스케줄 등록
REM  - 관리자 권한 불필요 (운영 배포만 관리자로)
REM ============================================================
echo [1] 옛 스케줄/공유설정 정리
schtasks /delete /tn dwisCOST-dev-autodeploy /f 2>nul
schtasks /delete /tn dwisCOST-dev /f 2>nul

echo [2] 개발/운영 빌드 클론 분리 생성
if not exist C:\DCIS\build\dwCost-dev  git clone https://github.com/limjh6991-spec/dwCost.git C:\DCIS\build\dwCost-dev
if not exist C:\DCIS\build\dwCost-prod git clone https://github.com/limjh6991-spec/dwCost.git C:\DCIS\build\dwCost-prod

echo [3] 최신 배치 복사
copy /Y C:\DCIS\build\dwCost-prod\deploy\deploy-dev.bat   C:\DCIS\build\
copy /Y C:\DCIS\build\dwCost-prod\deploy\deploy-prod.bat  C:\DCIS\build\

echo [4] 개발 자동배포 스케줄(5분) 등록
schtasks /create /tn dwisCOST-dev-autodeploy /tr "C:\DCIS\build\deploy-dev.bat" /sc MINUTE /mo 5 /f

echo.
echo ============================================================
echo  완료.
echo   - 개발: master push 시 5분내 자동 배포 (9091)
echo   - 운영: C:\DCIS\build\deploy-prod.bat 를 "관리자 권한으로 실행" (9090)
echo ============================================================
pause
