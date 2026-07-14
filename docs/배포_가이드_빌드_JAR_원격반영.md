# dwisCOST 빌드 · JAR 패키징 · 원격 반영 가이드 (운영 10.100.40.19)

프론트(Vue) 빌드 → 백엔드 JAR 패키징 → 운영 서버 반영까지의 표준 절차입니다.
**순서 중요**: 반드시 ① Vue 빌드 → ② JAR 패키징 순으로 진행합니다. (JAR이 Vue 빌드 산출물 `src/main/resources/public`를 포함하기 때문)

---

## 0. 사전 확인 (개발 dev / 운영 prod 비교)

| 항목 | **개발 (dev)** | **운영 (prod)** |
|---|---|---|
| 프론트 빌드 환경 | `dev` (`.env.dev`) | `prod2` (`.env.prod2`) |
| 프론트 빌드 명령 | `npm run builddev` | `npm run buildprod2` |
| API URL / 포트 | `http://10.100.40.19:**9091**` | `http://10.100.40.19:**9090**` |
| Maven 명령 | `./mvnw clean install` (프로파일 없음) | `./mvnw clean install **-Pprod**` |
| JAR 산출물 | `target/dwisCOST-**dev**-<YYMMDD-HHMM>.jar` | `target/dwisCOST-**prod**-<YYMMDD-HHMM>.jar` |
| 배포 폴더 (10.100.40.19) | `C:\DCIS\webapp\**api_dev**` | `C:\DCIS\webapp\**api**` |
| RealGrid 라이선스 | 운영용(도메인 바인딩) `.env.dev` | 운영용(도메인 바인딩) `.env.prod2` |
| Vue 산출 경로(공통) | `src/main/resources/public` (`VUE_APP_OUTPUT_DIR=../resources/public`) | 〃 |
| 실행 배치(공통) | `startCost.bat` (각 폴더 내) | 〃 |
| 서버(공통) | `10.100.40.19` (원격 데스크톱) | 〃 |

> ⚠️ **버전/폴더 교차 주의**
> - `-Pprod`를 **빼면** `dwisCOST-dev-…jar` (개발), **붙이면** `dwisCOST-prod-…jar` (운영).
> - 개발 JAR → **`api_dev`**, 운영 JAR → **`api`**. 폴더를 바꿔 넣지 않도록 파일명(`-dev-`/`-prod-`)을 반드시 확인.
> - 프론트 빌드 모드(`builddev`↔`buildprod2`)와 JAR 프로파일을 **짝 맞춰** 진행(개발끼리 / 운영끼리).

---

## 1. 프론트(Vue) 빌드

```bash
cd src/main/vue
npm install           # 최초 1회 또는 의존성 변경 시

# 개발(dev)
npm run builddev      # = vue-cli-service build --mode dev  (.env.dev, API 9091)

# 운영(prod)
npm run buildprod2    # = vue-cli-service build --mode prod2 (.env.prod2, API 9090)
```

- 결과물이 `src/main/resources/public`에 생성됩니다(기존 파일 덮어씀).
- 확인: 빌드 후 `src/main/resources/public/js/app.*.js` 갱신 시각이 방금인지 체크.
- 개발·운영 중 **반영하려는 환경 하나만** 빌드하고, 곧바로 그 짝의 JAR을 패키징합니다(뒤섞임 방지).

---

## 2. JAR 패키징

프로젝트 루트에서:

```bash
# 개발(dev) — 프로파일 없음(기본 revision=dev)
./mvnw clean install
#   → target/dwisCOST-dev-<YYMMDD-HHMM>.jar

# 운영(prod)
./mvnw clean install -Pprod
#   → target/dwisCOST-prod-<YYMMDD-HHMM>.jar
```

- `finalName = dwisCOST-${revision}-${build.date}` (예: `dwisCOST-prod-260713-1530.jar`)
- 방금 만들어진 JAR **파일명(`-dev-`/`-prod-`)·시각**을 확인합니다.

---

## 3. 운영 서버(10.100.40.19) 반영

1. **원격 데스크톱**으로 `10.100.40.19` 접속
2. 로컬 `target\dwisCOST-<...>.jar`를 서버의 **해당 폴더**로 복사·붙여넣기 (경로: `C 드라이브 → DCIS → webapp → …`)
   - **개발(dev)** JAR(`dwisCOST-dev-…`) → **`C:\DCIS\webapp\api_dev`**
   - **운영(prod)** JAR(`dwisCOST-prod-…`) → **`C:\DCIS\webapp\api`**
3. (권장) 기존 JAR은 파일명 뒤에 날짜를 붙여 백업 보관 후 교체
4. ⚠️ **개발↔운영 폴더를 바꿔 넣지 말 것** (파일명 `-dev-`/`-prod-`로 재확인)

---

## 4. 재기동

1. **기존 실행 중인 JAR(콘솔 창) 종료** — 해당 환경의 실행 창을 닫습니다.
2. 배포한 폴더(**`api_dev`**(개발) 또는 **`api`**(운영))의 **`startCost.bat` 실행** → 새 JAR로 기동
3. 기동 로그 확인(정상 부팅 / 포트 리슨 [개발 9091 · 운영 9090] / DB 연결).

---

## 5. 반영 후 검증 (체크리스트)

- [ ] 로그인 화면 → 로그인 정상 진행(다음 화면 전환)
- [ ] RealGrid가 뜨는 화면에서 **라이선스 오류(invalid domain) 없음**
- [ ] 주요 화면(원가/손익/수불) 데이터 정상 표시
- [ ] **브라우저 캐시 삭제 후 재접속**(Ctrl+Shift+R 또는 캐시 비우기) — 이전 JS가 남아 있으면 오작동

---

## 트러블슈팅 (과거 사례)

| 증상 | 원인 / 조치 |
|---|---|
| RealGrid "invalid domain" | `.env.prod2`의 운영 라이선스 키(도메인 바인딩)로 빌드했는지 확인. 로컬/dev 키(짧은 키)로 빌드하면 운영 도메인에서 실패 |
| 로그인 후 다음 화면 안 넘어감 / 401 | API URL(`.env.prod2` = `10.100.40.19:9090`)·CORS·백엔드 DB 프로파일 확인. 프론트가 잘못된 API를 보고 있는지 점검 |
| 화면에 옛 데이터/구버전 동작 | 브라우저 캐시. 캐시 삭제 후 재접속 |
| JAR 이름이 `dev`로 나옴 | `-Pprod` 누락 |
| 변경한 프론트가 반영 안 됨 | ① Vue 빌드를 JAR 패키징 **이전에** 했는지, ② `src/main/resources/public` 갱신 확인 |

---

## 요약 (한눈에)

**개발(dev)**
```bash
cd src/main/vue && npm run builddev          # 1) 프론트(dev)
cd ../../.. && ./mvnw clean install          # 2) JAR → target/dwisCOST-dev-<...>.jar
# 3) 원격 10.100.40.19  →  C:\DCIS\webapp\api_dev  로 JAR 복사
# 4) 기존 JAR 종료 → api_dev\startCost.bat 실행 → 캐시 삭제 후 검증(포트 9091)
```

**운영(prod)**
```bash
cd src/main/vue && npm run buildprod2         # 1) 프론트(prod)
cd ../../.. && ./mvnw clean install -Pprod    # 2) JAR → target/dwisCOST-prod-<...>.jar
# 3) 원격 10.100.40.19  →  C:\DCIS\webapp\api      로 JAR 복사
# 4) 기존 JAR 종료 → api\startCost.bat 실행 → 캐시 삭제 후 검증(포트 9090)
```
