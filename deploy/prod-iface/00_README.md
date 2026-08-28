# 운영(도우제조원가시스템) 인터페이스 배포 패키지

> 생성: 2026-08-28 · 소스: dev(DWCMSTEST) **라이브 정의** 추출 · 문법검증(PARSEONLY) 통과
> ⚠️ **검토 후 운영에서 직접 실행하세요.** 이 패키지는 SQL만 제공하며, 운영 DB에는 자동 적용되지 않았습니다.

현재 운영 DB에는 인터페이스 인프라가 **하나도 없습니다**(스테이징 0/프로시저 0). 이 패키지로 프로비저닝해야 운영에서 [API 호출]이 동작합니다.

## 배포 순서 (SQL, 위→아래)

| # | 파일 | 내용 | 멱등 |
|---|---|---|---|
| 1 | `01_staging_tables.sql` | 인터페이스 스테이징 **26종** (DOI_VN_IF_* 18 + DOI_HQ_IF_* 8) | `OBJECT_ID IS NULL`시 생성 |
| 2 | `02_target_tables.sql` | xform 기록대상 중 운영 부재 **5종** (DOI_HQ_STOCK_DETAIL, DOI_VN_STCO, doi_vn_stock_resc, doi_vn_prod_resc, DOI_VN_EXP_CLAIM) | 동일 |
| 3 | `03_load_procs.sql` | 적재 프로시저 **26종** (UP_*_IF_LOAD_*) | `CREATE OR ALTER` |
| 4 | `04_xform_procs.sql` | 변환 프로시저 **19종** (UP_*_IF_XFORM_*) | `CREATE OR ALTER` |
| 5 | `05_doi_acct_vn_seed.sql` | DOI_ACCT_VN(계정 다국어 마스터) 시드 — 운영=0행이면 dev에서 복사 | 비어있을 때만 |

각 파일은 `GO` 배치 구분자 포함. SSMS/sqlcmd로 **도우제조원가시스템**에 순서대로 실행.

> ⚠️ **02_target_tables**의 `DOI_VN_STCO`/`doi_vn_stock_resc`/`doi_vn_prod_resc`는 원래 **VN _NEW 결산 파이프라인** 산출물입니다. 여기선 인터페이스 xform 오류 방지용 **구조(컬럼)만** 생성하며, PK/인덱스/결산 프로시저 등 전체 파이프라인 배포는 **별도 확인**이 필요합니다.

## ★ 배포 전 반드시 선결 (외부 — SQL로 해결 불가)

1. **영림원 ERP cert 권한** — 현재 미부여(50000 Không có quyền)로 **ERP 계열 실호출 전부 불가**. 영림원(K-System) 관리자에 VN·HQ cert의 serviceSeq/pgmSeq/methodSeq/userSeq 인가 요청·확인 필요. **미해소 시 ERP 버튼은 배포해도 실패**(MES 계열 FG_SUBUL/WIP_SUBUL은 인증 불요라 동작).
2. **네트워크 도달성** — 운영 앱 서버가 ERP-VN(172.16.21.x)·ERP-HQ(10.100.40.16)·MES(172.16.23.x) 각 망에 도달 가능한지 확인. (기존 실호출은 공장망 10.100.40.242에서만 성공.)

## 앱/설정 (jar · env)

3. **PROD jar 재빌드** — 최신 소스(HQ-if/C0007002/자재코드 누적/마감월 가드) 미반영 상태(현 prod jar는 구버전). 운영 승격 시:
   ```bash
   git pull            # 최신(마감월가드 커밋 포함)
   npm run buildprod2  # (src/main/vue) 프론트 운영빌드
   ./mvnw -Drevision=prod clean package -Dmaven.test.skip=true
   # → target/dwisCOST-prod-*.jar 배포
   ```
4. **cert/base-url env 주입** (기동 스크립트에 미배선 — 실값은 커밋 금지):
   - VN: `IFACE_ERP_CERT_ID` `IFACE_ERP_CERT_KEY` `IFACE_ERP_DSN_OPER` `IFACE_ERP_DSN_BIS`
   - HQ: `IFACE_ERP_HQ_CERT_ID` `IFACE_ERP_HQ_CERT_KEY` `IFACE_ERP_HQ_DSN_OPER` `IFACE_ERP_HQ_DSN_BIS` (+ 선택 `IFACE_ERP_HQ_BASE_URL`)
   - base-url: ERP-VN TEST 8801 → **운영 8800**, ERP-HQ TEST 8300 → **운영주소**로 교체(env override 권장).
5. **운영 프로파일 DB 확인** — prod2 → 도우제조원가시스템. `--spring.profiles.active=prod`(application-prod.yml 부재)로 뜨면 base(DWCMSTEST)로 붙는 함정 주의 → **prod2** 사용.

## 배포 후 검증

6. `GET /api/iface/status` — endpoints 26종 노출, ready.mes/ready.erp 확인(비밀값 미노출).
7. **소량 스모크** — 마감 안 된 월로, 인증 불요 **MES(WIP_SUBUL/FG_SUBUL)부터** → 영림원 인가 확보 후 ERP. 각 loadProc→스테이징 적재→xformProc 변환 무결성 대사.
8. `DOI_ACCT_VN` 확인: `SELECT COUNT(*), SUM(CASE WHEN ISNULL(ACCT_KO,'')<>'' THEN 1 ELSE 0 END) FROM DOI_ACCT_VN;` (689 근처, ACCT_KO 채움).

## 안전장치 (이미 코드 반영됨)

- **마감월 가드**(커밋 b6a8a46): 적재 인터페이스가 마감월(DOI_CLOSING_MONTH, yyyymm+site)에 대해 API 적재를 차단 → 마감된 결산 데이터 훼손 방지. (운영 배포 jar에 포함되도록 위 3의 prod 재빌드 필수.)

## 잔여 항목 (배포와 별개)

- load-only 7종(ITEM/PROCESS/ACCLANG/ITEM_PROC_MAT/WH_STOCK_SUM(VN)/BIZ_STOCK_SUM/EXP_PERMIT)은 프론트 버튼 미배선(의도적, 필요 시 화면 추가).
- PROCESS/EXP_CLAIM/EXP_SALES userSeq는 정의서 JSON샘플 부재로 실호출 대사 잔여.
- HQ 생산수불(DOI_PROD_SUBUL): MES 운영DB 전용 개체 의존(현행 유지, 별건).
