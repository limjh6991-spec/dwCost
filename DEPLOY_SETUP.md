# DEPLOY_SETUP — dwisCOST 빌드/배포 (수동 방식)

개발/운영 모두 **수동 배치 스크립트**로 빌드·배포한다.
서비스 종료와 기동은 수동으로 처리한다.

---

## 1. 배포 대상

| 환경 | 빌드 경로 | 배포 경로 | 프로파일 | 포트 | JAR 파일명 |
|---|---|---|---|---|---|
| **dev** | `C:\DCIS\build\dwCost-dev` | `C:\DCIS\webapp\api_dev` | `dev` | 9091 | `dwisCOST-dev.jar` |
| **운영** | `C:\DCIS\build\dwCost-prod` | `C:\DCIS\webapp\api_prod` | `prod2` | 9090 | `dwisCOST-prod.jar` |

- 빌드 도구: Maven `C:\apache-maven-3.9.9`, JDK 17
- 스크립트: [`deploy/deploy-dev.bat`](deploy/deploy-dev.bat), [`deploy/deploy-prod.bat`](deploy/deploy-prod.bat)

---

## 2. ⚠️ 오프라인 빌드 (서버가 인터넷 차단)

Maven Central 접속이 안 되므로 **`mvn -o`(오프라인)** 로 빌드한다.
- 의존성은 배치를 실행하는 **사용자 계정의 `%USERPROFILE%\.m2\repository`** 에 미리 있어야 한다.
- **`pom.xml`에 새 의존성 추가 시**: 인터넷 되는 PC에서 `mvn clean package` 한 번 → 그 PC의 `.m2\repository`를 tar로 압축 → 서버 `.m2`에 풀어 병합.

---

## 3. 최초 설정 (한 번만)

```cmd
REM (1) 빌드용 클론 — 공개 저장소라 인증 불필요
git clone https://github.com/limjh6991-spec/dwCost.git C:\DCIS\build\dwCost-dev
git clone https://github.com/limjh6991-spec/dwCost.git C:\DCIS\build\dwCost-prod

REM (2) 배치 파일을 저장소 밖(안정적 위치)으로 복사
copy C:\DCIS\build\dwCost-dev\deploy\deploy-dev.bat  C:\DCIS\build\
copy C:\DCIS\build\dwCost-dev\deploy\deploy-prod.bat C:\DCIS\build\
```

---

## 4. 배포 절차

### 개발 (dev)

```
1. C:\DCIS\build\deploy-dev.bat 실행
   → git pull + 빌드 + JAR 복사 자동 수행
2. 기존 서비스 CMD 창 수동 종료 (또는 작업관리자에서 java.exe 종료)
3. 서비스 기동:
   cd C:\DCIS\webapp\api_dev
   java -Xms1g -Xmx1g -jar dwisCOST-dev.jar --spring.profiles.active=dev
```

### 운영 (prod)

```
1. C:\DCIS\build\deploy-prod.bat 실행
   → DEPLOY 입력 확인 → git pull + 빌드 + JAR 복사 자동 수행
2. 기존 서비스 CMD 창 수동 종료 (또는 작업관리자에서 java.exe 종료)
3. 서비스 기동:
   cd C:\DCIS\webapp\api_prod
   java -Xms1g -Xmx1g -jar dwisCOST-prod.jar --spring.profiles.active=prod2
```

---

## 5. 동작 요약 (각 배치)

1. `git fetch` → `git reset --hard origin/master` (최신 코드 동기화)
2. `mvn -o clean package -DskipTests` (오프라인 빌드)
3. `dwisCOST-<profile>.jar` 고정명으로 배포 경로에 복사 + `backup\`에 타임스탬프본 보관
4. 완료 메시지 출력 → **서비스 종료/기동은 수동**

---

## 6. 상태 확인

```cmd
REM 포트 확인
netstat -ano | findstr :9091    (개발)
netstat -ano | findstr :9090    (운영)

REM 로그 확인
type C:\DCIS\webapp\api_dev\app.log     (개발)
type C:\DCIS\webapp\api_prod\app.log    (운영)
```
