# DEPLOY_SETUP — dwisCOST 빌드/배포 (서버 배치 방식)

GitHub Actions(셀프호스티드 러너)는 **서비스가 뜬 채로 잡이 안 끝나고 무한 hang** 되는 문제가 있어 제거했다.
대신 **서버에서 배치 스크립트로 직접 빌드/배포**한다 — 단순하고, hang이 원천적으로 없다.

---

## 1. 배포 대상 (dev·운영 모두 같은 장비)

| 환경 | 경로 | 프로파일 | 포트 | 실행 jar | 트리거 |
|---|---|---|---|---|---|
| **dev** | `C:\DCIS\webapp\api_dev` | `dev` | 9091 | `dwisCOST-dev.jar` | **자동**(5분 폴링) |
| **운영** | `C:\DCIS\webapp\api_prod` | `prod1` | 9090 | `dwisCOST-prod.jar` | **수동**(DEPLOY 확인) |

- 빌드 도구: 설치 Maven `C:\apache-maven-3.9.9`, JDK 17
- 스크립트: [`deploy/deploy-dev.bat`](deploy/deploy-dev.bat), [`deploy/deploy-prod.bat`](deploy/deploy-prod.bat)

---

## 2. ⚠️ 오프라인 빌드 (러너/서버가 인터넷 차단)

Maven Central 접속이 안 되므로 **`mvn -o`(오프라인)** 로 빌드한다.
- 의존성은 배치를 실행하는 **사용자 계정의 `%USERPROFILE%\.m2\repository`** 에 미리 있어야 한다(현재 `dowoobinary25` 계정에 시딩 완료).
- **`pom.xml`에 새 의존성 추가 시**: 인터넷 되는 PC에서 `mvn clean package` 한 번 → 그 PC의 `.m2\repository`를 tar로 압축 → 서버 `.m2`에 풀어 병합.

---

## 3. 최초 설정 (한 번만)

```cmd
REM (1) 빌드용 클론 — 공개 저장소라 인증 불필요
git clone https://github.com/limjh6991-spec/dwCost.git C:\DCIS\build\dwCost

REM (2) 배치 파일을 저장소 밖(안정적 위치)으로 복사
copy C:\DCIS\build\dwCost\deploy\deploy-dev.bat  C:\DCIS\build\
copy C:\DCIS\build\dwCost\deploy\deploy-prod.bat C:\DCIS\build\

REM (3) dev 자동배포 스케줄 — 5분마다 새 커밋 확인 후 있으면 배포
REM     (배치를 실행하는 계정 = .m2가 있는 dowoobinary25 로 로그온 상태에서 동작)
schtasks /create /tn "dwisCOST-dev-autodeploy" /tr "C:\DCIS\build\deploy-dev.bat" /sc MINUTE /mo 5 /f
```

> 경로가 다르면 각 `.bat` 상단의 `set REPO=` / `set DEPLOY=` 만 수정.

---

## 4. 사용법

- **dev**: master에 push하면 최대 5분 내 자동으로 빌드·배포·재기동. 수동으로 즉시 돌리려면 `C:\DCIS\build\deploy-dev.bat` 실행.
- **운영**: `C:\DCIS\build\deploy-prod.bat` 더블클릭 → `DEPLOY` 입력해야 진행.
- 서비스 로그: `C:\DCIS\webapp\api_dev\app.log` (운영은 `api_prod\app.log`).
- 상태 확인: `netstat -ano | findstr :9091` (운영은 `:9090`).

---

## 5. 동작 요약 (각 배치)

1. `git fetch` → 원격에 새 커밋 있으면(dev는 없으면 즉시 종료) `git reset --hard origin/master`
2. `mvn -o clean package -DskipTests` (오프라인 빌드)
3. 해당 포트의 java 프로세스 종료(다른 환경은 건드리지 않음)
4. `dwisCOST-<profile>.jar` 고정명으로 배포 + `backup\`에 타임스탬프본 보관
5. `start`로 서비스 기동(백그라운드 유지) — JVM 옵션은 `-jar` 앞에 정렬

---

## 6. 참고 — 이전 GitHub Actions 러너 정리

배치 방식으로 전환했으므로 셀프호스티드 러너는 더 이상 필요 없다.
- 러너 콘솔(`C:\actions-runner\run.cmd`)을 종료.
- 서비스로 등록돼 있으면 중지: `sc query state= all | findstr /i actions.runner` 로 이름 확인 후 `net stop <이름>`.
