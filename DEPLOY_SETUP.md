# DEPLOY_SETUP — dwisCOST 자동 배포(CI/CD) 환경

GitHub Actions + **self-hosted 러너**로 dev/운영 서버에 배포한다. 이 문서는 실제로 확인한 사실을 기준으로 작성했다.

---

## 1. 구성 요약

| 구분 | 값 |
|---|---|
| 저장소 | `limjh6991-spec/dwCost` (Actions 실행), 로컬 클론 `C:\dev\dwisCOST` |
| 러너 | **self-hosted `SPS008`** (Windows Server 2022, 계정 `dowoobinary25`) |
| JDK | Temurin 17 (`C:\Program Files\Eclipse Adoptium\jdk-17...`) |
| Maven | **설치본 `C:\apache-maven-3.9.9`** (래퍼 `mvnw.cmd` 사용 안 함) |
| 워크플로 | `.github/workflows/deploy-dev.yml`, `.github/workflows/deploy-prod.yml` |

### 배포 대상 (dev·운영 모두 같은 장비 SPS008)

| 환경 | 경로 | 프로파일 | 포트 | 실행 jar |
|---|---|---|---|---|
| **dev** | `C:\DCIS\webapp\api_dev` | `dev` | **9091** | `dwisCOST-dev.jar` |
| **운영(prod)** | `C:\DCIS\webapp\api_prod` | `prod1` | **9090** | `dwisCOST-prod.jar` |

각 경로의 `backup\` 폴더에 타임스탬프 jar가 보관된다(롤백용).

---

## 2. ⚠️ 가장 중요한 제약 — 러너는 인터넷 차단(에어갭)

러너 SPS008은 **Maven Central(`repo.maven.apache.org`)에 접속할 수 없다.**

- 그래서 **Maven 래퍼 `mvnw.cmd`(distributionType=only-script)는 쓰면 안 된다.** 래퍼는 매 빌드마다 Maven 배포판을 인터넷에서 받으려다 실패한다.
- 반드시 **설치된 Maven으로 오프라인 빌드**한다:
  ```bat
  C:\apache-maven-3.9.9\bin\mvn.cmd -o clean package -DskipTests -B
  ```
- 의존성은 러너의 로컬 저장소 `%USERPROFILE%\.m2\repository`(= `C:\Users\dowoobinary25\.m2`)에 **미리 캐시**돼 있어야 한다.

### 새 의존성을 추가했다면 (.m2 시딩 절차)
`pom.xml`에 의존성/플러그인을 추가하면 러너에 그 아티팩트가 없어 **오프라인 빌드가 실패**한다. 이때:

1. **인터넷 되는 PC**에서 프로젝트를 한 번 빌드해 `.m2`를 채운다(온라인).
   ```bat
   mvn clean package -DskipTests
   ```
2. 그 PC의 `%USERPROFILE%\.m2\repository`를 압축한다.
   ```bat
   cd /d "%USERPROFILE%\.m2\repository"
   tar -czf m2repo.tar.gz .
   ```
3. 압축본을 러너로 옮겨 러너 `.m2`에 **병합 해제**한다.
   ```bat
   cd /d "%USERPROFILE%\.m2\repository"
   tar -xzf <옮긴경로>\m2repo.tar.gz
   ```
4. 러너에서 오프라인 빌드로 확인: `mvn -o clean package -DskipTests -B` → `BUILD SUCCESS`.

> 장기적으로는 **사내 Nexus/Artifactory 미러** 또는 러너의 Maven Central 접근 허용이 근본 해결책이다(IT 협의 필요).

---

## 3. 워크플로 동작

두 워크플로 모두: `mvn -o` 오프라인 빌드 → 고정명 jar로 배포(+backup) → **해당 경로 프로세스만** 종료(다른 환경 보존) → `Win32_Process.Create`로 기동(러너 잡 종료와 무관하게 서비스 유지) → **포트 리슨 확인**으로 헬스체크.

### deploy-dev.yml
- **트리거:** `master`에 `src/**` 또는 `pom.xml` push 시 자동 + 수동(`workflow_dispatch`)
- dev 서비스(9091) 재배포

### deploy-prod.yml
- **트리거:** 수동(`workflow_dispatch`) **only** — 실수 배포 방지
- 실행 시 입력: `profile`(prod1/prod2, 기본 prod1), `confirm`(= **`DEPLOY`** 입력해야 진행)
- 운영 서비스(9090) 재배포

### 실행 방법 (GitHub → Actions 탭)
- **dev:** *Deploy to Dev Server* → *Run workflow* → Branch `master` → Run
- **운영:** *Deploy to Prod Server* → *Run workflow* → `profile=prod1`, `confirm=DEPLOY` → Run

---

## 4. 트러블슈팅 (과거 실제 증상)

| 증상 | 원인 | 조치 |
|---|---|---|
| Build JAR가 **43초 후 실패** | 래퍼가 Maven 배포판 다운로드 시도 → 연결 타임아웃 | 래퍼 대신 `mvn -o` 사용 |
| `mvnw.cmd`가 **0바이트** | 실패한 다운로드 잔재/래퍼 손상 | 래퍼 미사용(위와 동일) |
| `Could not resolve ... (absent)` | 러너 `.m2`에 의존성 없음 + 인터넷 차단 | 2절 **.m2 시딩 절차** |
| 포트 9091/9090 **이미 점유** | 이전 서비스가 안 죽음(구 워크플로 창제목 taskkill 실패) | 현재는 경로 기준으로 정확히 종료함 |

> 참고: 기존 수동 기동 스크립트는 JVM 옵션(`-Xms1g` 등)이 `-jar` **뒤**에 있어 실제로 적용되지 않았다. 워크플로에서는 `-jar` **앞**으로 정렬해 정상 적용되게 했다.

---

*작성: 2026-07-23 · 관련: [`.github/workflows/deploy-dev.yml`](.github/workflows/deploy-dev.yml), [`.github/workflows/deploy-prod.yml`](.github/workflows/deploy-prod.yml)*
