# HQ 월결산 런북 — 엑셀 기초자료 적재 + 결산체인

> 작성 2026-11-10 (202610 결산 기준) · 운영 **도우제조원가시스템**(10.100.40.17,14233) 직접 실행
> 인수인계용. `hq_settlement.py` 와 함께 읽을 것.

## 0. 개요

HQ 월결산 = **(A) 기초자료 적재**(엑셀 → doi_* 12종) + **(B) 결산 체인**(배부/원가 프로시저 순차 EXEC) + **(C) 검증**.
신규 월은 맨 앞에 **CarryOver**(전월 복사 생성)가 1회 필요하다. 결산 이후 별도 단계로 **재고자산충당금 적재**와 **마감**이 있다(§5, 이 패키지 미포함).

- 엑셀 원천: `C:\Users\USER\Downloads\26.10월 정보\` (월별 폴더). 파일명 날짜접미사는 매월 바뀜 → 스크립트는 glob 패턴으로 찾음(다중매칭·`~$`잠금 가드 있음).
- 모든 적재는 **트랜잭션 → DELETE(월·사업장 한정) → INSERT → 엑셀 TOTAL/항등식 검증 → 통과 시 commit, 실패 시 rollback**. base 7종은 테이블별 트랜잭션(전체 원자 아님) — 실패 시 그 지점부터 재실행 가능(각 테이블 DELETE 후 재적재).
- 타입 주의: 수량·단가 = `float`(real), 금액·원가 = `Decimal`(numeric), bigint = `int`, 날짜 = `'YYYY-MM-DD'` 문자열, **`fast_executemany=False`**(혼합정밀도 손실 회피).
- 다운로드 엑셀은 외부 데이터 → `python -I` 로 실행.
- **DB 비밀번호는 파일에 없음**(팀 공유). 실행 전 환경변수로 주입: `PowerShell: $env:DWCOST_PWD='...'` / `cmd: set DWCOST_PWD=...`.

### ★ 신규 월 실행 순서 (이 순서를 지킬 것)

```bash
# 0) 설정: hq_settlement.py 상단 YYYYMM / PREV_YYYYMM / XLSX_DIR 를 대상 월로 수정, $env:DWCOST_PWD 설정
python -I hq_settlement.py --step carryover   # 1) 신규월 1회: UP_DOI_CarryOver(ACCT/BOM/DEPT/MODEL_MAST 전월복사 생성)
python -I hq_settlement.py --step base        # 2) 기초 적재 12종 (BOM 엑셀 전체교체 = CarryOver 생성본 덮음)
python -I hq_settlement.py --step settle      # 3) MODEL_MAST 재주입(면적) → SALE_COST ALTER → 결산 체인
python -I hq_settlement.py --step verify      # 4) 검증(읽기전용, PL 항등식 자동검산)
```

- `--step all` 은 base→settle→verify (carryover 미포함 — 재실행 사고 방지). **carryover 는 반드시 base 前**에 1회만.
- ⚠️ **순서 주의**: CarryOver 는 BOM/DEPT 를 전월본으로 생성하고 base 가 이를 엑셀로 교체한다. carryover 를 base 뒤에 돌리면 방금 적재한 정상 BOM/DEPT 가 전월 stale 로 덮인다(`run_carryover()` 가 DOI_ACCT 존재 시 스킵하도록 가드).

---

## 1. 기초자료 적재 (A) — 12종

| # | 테이블 | 엑셀(시트) | 핵심 매핑 / 주의 |
|---|--------|-----------|------------------|
| 1 | `DOI_DEPT_COST` | 계정별비용조회(**코스트센터**) | 코스트센터/분류/유형/계정코드/계정과목/비용구분/차변/대변/집계제외. 제외여부=**집계제외열이 '제외'인 행만 '제외', 그 외 NULL**(원본 기준; 하위 UP_DOI_EXPEN_MATL 필터용). 계정코드 없는 행 스킵. **⚠️ API 적재분 사용 금지**(원천 ERP 코스트센터 = 재배부 전). 반드시 **결산담당자 재배부 확정본 엑셀**. 검증=차변·대변 TOTAL |
| 2 | `DOI_MATL_RESC` | 재고수불부(**재고금액(YYYYMM)**) | 41개 데이터열 위치대응. 타입은 **DB 컬럼명 기반**(수량·단가→float, 금액·원가→Decimal). 투입금액/수량은 재료비 배부 원천. 검증=기초·입고금액 TOTAL |
| 3 | `DOI_STOCK` | 재고수불부(**창고수불(…)**) | 필터 품목자산분류 IN ('제품','카세트제품'). 제품 MODEL←품명(5), 카세트 MODEL←품번(6), MODEL_TYPE←품번(6), STOCK←창고(11). headline BOH13/IN14/OUT15/EOH16. breakdown 위치대응(**공정재투입←37열**). **RMA_AMT·OUT_RETURN=0 하드코딩**(창고수불에 금액소스 없음) — **⚠️ RMA 반품 수량>0 인 달은 RMA_AMT 금액소스(별도 반품 엑셀)를 주입해야 함**(로더가 경고). **⚠️ API 적재분은 breakdown 전부 NULL → 엑셀 필수**. 검증=수불 합 + **OUT=거래명세표+수출Invoice+기타출고+이동(출)** + 흐름 `BOH+IN−OUT=EOH` + 공정재투입 roundtrip |
| 4 | `DOI_PROD_SUBUL` | 재고수불부(**재고금액** = 재공품수불) | 도우코드=모델열(2), 작업구분=끝글자(P/D), 도우모델=코드[:-1]. **타계정입고(9)=기타입고 롤업**, 제품R/W(12)→**기타입고_RMA_RW**. 31컬럼 INSERT. 검증=항등식 `기초+입고+타계정입고 = 출고+LOSS+타계정출고+재고` + 제품R/W roundtrip. **⚠️ 미매핑 개별버킷(불량R/W11·샘플15·기타16·폐기19·샘플출20·연구개발21)은 '전부 0' 가정 — 0 아니면 상세 소실하므로 로더가 중단·경고**(nonzero 달엔 확장열 매핑 추가 필요) |
| 5 | `DOI_원장상계` | 유상사급 모델별 상계(**N월**) | 모델행(구분 P/D, 모델=도우코드 as-is, 원장사용량=FLOOR) + **회계-조정 행**(구분='회계', 매칭/사용량 NULL). TOTAL행 제외(독립 대조). **⚠️ 회계-조정 금액 월별 급변 가능 → 로더가 값 표면화 + |1억| 초과 시 경고. 담당자 확인** |
| 6 | `DOI_CST_RATE` | (카세트팀 원가 배부) | **결산 필수**(UP_DOI_EXPEN_MATL STEP1이 0행이면 중단). 카세트 실적 없으면 UTG=1.0/VINA_CST=0.0 1행, DOI_VNCST_RATE 0행. **★ 카세트 창고 입출고가 감지되면 로더가 중단**(1.0 적용 금지) → '카세트팀 원가 배부' 엑셀로 UTG/VINA 비율 산정해 DOI_CST_RATE/DOI_VNCST_RATE 수기 적재(담당자). (메모리: 외주가공비 53020010 67/33%, dept448 소모품비 등) |
| 7 | `DOI_BOM_MAST` | 제품별공정별소요자재조회(Sheet1) | col1~26 → DB 1:1(col27 무시). **⚠️ API 적재분 소요량 정밀도 오류(0.1667↔0.1666)·신규모델 누락 → 엑셀 전체교체 필수**. 검증=소요량 0.1667 건수 0. **★ HTG(H접두) 제품명 'H' 누락 교정**: H818VT·H8075T 등 제품명이 'H' 뺀 값으로 와 배부 조인(BOM.제품명=도우모델)이 818VD로 오조인 → 제품번호 H접두 & 제품명≠품목중분류면 제품명=품목중분류로 교정(로더 내장, 818VT 등 비H 미접촉) |
| 8 | `DOI_DEPT` | 부서및코스트센터코드(코스트센터) | **CarryOver가 생성** → 엑셀과 코스트센터명·분류(EXPEN_AREA) 일치만 검증(불일치 시 재적재 검토) |
| 9 | `doi_sale_resc` | 매출품목(세금계산서) | 위치대응. 보통 사전 적재됨 → DB 합계 vs 엑셀 TOTAL 눈대조 |
| 10 | `doi_invoice_resc` | 매출품목(수출신고필증) | 위치대응. 사전 적재분 대조 |
| 11 | `DOI_ETC_INOUT` | 기타입출고금액조회(통합) | 사전 적재분. **⚠️ 엑셀 TOTAL셀은 스테일 → 행레벨 합과 대조** |
| 12 | 품목별투입조회 | — | **HQ 미적재(VN 전용) → SKIP** |

`hq_settlement.py` 의 `run_base_loads()` 가 1~7 적재 + 8~11 검증(`verify_preloaded`)을 수행한다. 8~11이 이미 올바르면 유지, 불일치면 담당자가 재적재 결정.

---

## 2. 결산 체인 (B)

`run_settle()` = 선행조건 점검 → **DOI_MODEL_MAST 주입(면적)** → (최초1회) SALE_COST ALTER → 프로시저 순차 EXEC(오류 시 즉시 중단).
각 EXEC 파라미터: `@YYYYMM, @SITE='HQ', @SEL_CODE='ACTUAL'`.

### 2-1. 선행조건 — ★ CarryOver, BOM/DEPT, 그리고 DOI_MODEL_MAST 주입

**`UP_DOI_CarryOver`** 는 `DOI_ACCT · DOI_BOM_MAST · DOI_DEPT · DOI_MODEL_MAST` 4개를 전월 복사로 **생성**한다. `--step carryover`(`run_carryover()`) 가 실행:

```sql
EXEC UP_DOI_CarryOver @YYYYMM = '<결산 대상(신규) 월>', @SITE = 'HQ', @PREV_YYYYMM = '<전월>';
```

- ⚠️ **`@YYYYMM` 에는 '결산 대상(신규) 월'**, `@PREV_YYYYMM` 에는 '전월' 을 넣는다. (`@YYYYMM='202610', @PREV_YYYYMM='202609'`). `@YYYYMM` 에 전월을 넣으면 전전월→전월을 이월해 전부 틀어진다.
- 이미 생성돼 있으면 **재실행 금지**(방금 적재한 BOM/DEPT 를 전월 stale 로 덮음) — `run_carryover()` 가 `DOI_ACCT` 존재 시 자동 스킵.
- 전월 복사라 **당월 신규 모델**은 BOM/MODEL_MAST 에서 빠질 수 있음 → **BOM 은 엑셀 전체교체(§1-7)**, **MODEL_MAST 는 Spec 재주입(아래)** 이 보완.
- **신규 월 순서**: `carryover` → `base`(BOM 재적재·DEPT 검증) → `settle`(MODEL_MAST 재주입 포함). `DOI_MODEL_MAST` 는 CarryOver 본(stale)을 쓰지 않고 아래 방법으로 매월 재주입한다.

#### ★ DOI_MODEL_MAST 주입 (면적 X/Y/XY) — 배부 前 필수

재료비·경비 배부적수 = **환산량 × XY(면적)**. 누락 모델은 배부 0, 틀린 면적은 원가 왜곡. `inject_model_mast()` 가 매월 **3단계**로 재주입한다:

1. **MES.dw_product_mast → 원가.dw_product_mast 전체 복사** (원가쪽 DELETE 후).
   - 원가 인스턴스(10.100.40.17,14233)의 **링크드 서버 `MES`(10.100.40.250)** 경유: `MES.[도우제조MES시스템DB].dbo.dw_product_mast`.
   - ⚠️ MES 와 원가의 `dw_product_mast` 는 **컬럼 순서가 다름**(MES: …Mass_Prod/use_yn/Note…, 원가: …Mass_Prod/Note/…/use_yn) → **`SELECT *` 금지, 명시적 컬럼리스트**(이름 일치)로 복사.
2. **`dw_product_mast.Spec` 파싱 → `doi_model_mast` INSERT** (해당 월 DELETE 후).
   - Spec `장변[*×Xx]단변` 분리 → `±`/`M`·콤마 정제 → `X`/`Y`/`XY = X*Y`. 쿼리는 `inject_model_mast()` 에 내장(결산월만 바뀜).
3. **전월 `doi_model_mast` 의 `ADD_YN='Y'` 이월** (Spec 에 치수 없는 **수기 추가 모델**: 716D·H8075·H8133·H818V 등). 중복 모델은 방어적으로 제외.

검증: `inject_model_mast()` 가 **XY 전부 유효 + 재공 모델 전부 커버**를 확인 후 commit(실패 시 rollback).

> 202610 실측: Spec 393행 + 이월(ADD_YN=Y) 4행 = **397행**, XY 전부 유효, 재공 53모델 전부 커버.

### 2-2. ★ UP_DOI_SALE_COST 도우코드 열 대응 (최초 1회, 멱등)

2026-10-23 도우코드 전환(`db/hq_procs/dwcode_passthrough_261022/`)이 `DOI_SLCO·DOI_SMCE_COST` 끝에 **`도우코드` 열**을 추가했다. `UP_DOI_SALE_COST`(2026-09-17 버전)의 **위치기반 INSERT 2개**가 이 열과 개수가 안 맞아 **오류 213**으로 중단된다. (202609는 열 추가 前이라 성공, 202610이 첫 실패)

→ 수정: 두 INSERT에 **명시적 컬럼리스트**(도우코드 생략) 추가. **값·산식·배부·총액 불변.** 도우코드는 결산 끝 `UP_DOI_FILL_DWCODE` 가 채운다.

- SQL: [`UP_DOI_SALE_COST_fix261110_dwcode_collist.sql`](UP_DOI_SALE_COST_fix261110_dwcode_collist.sql)
- 운영 DB에 **2026-11-10 이미 적용됨**. `ensure_sale_cost_alter()` 가 미적용 시에만 ALTER(멱등).

### 2-3. 프로시저 순서

```
UP_DOI_EXPEN_MATL      경비집계 → DOI_EXPEN_MATL        (RMA_RW 재투입 반영 = 특이사항1)
UP_DOI_MAT_AMT         재료비집계 → doi_mat_amt
UP_DOI_MAT_COST        재료비배부 → DOI_MAT_COST
UP_DOI_COST            가공비배부 → DOI_COST            (도우코드 인라인 채움)
UP_DOI_STOCK_BOH       제품BOH → DOI_STOCK_BOH, DOI_STCO 집계
UP_DOI_STOCK_COST      제품수불금액 → DOI_STUC/DOI_STCO (@R_Message OUTPUT, 도우코드 인라인)
UP_DOI_SALE_COST       매출원가·판관비 → DOI_SLCO/DOI_SMCE_COST
(DOI_IVDD 복사)         DOI_MATL_RESC → DOI_IVDD        (SCOF 선행조건, 아래 참고)
UP_DOI_SCOF            매출상계 → DOI_SCOF(0행 정상)·DOI_POST 기표
EXEC UP_DOI_FILL_DWCODE 도우코드 채움: SLCO/SMCE/STCO(재공LOSS 폴백). COST/STCO는 멱등
```

- **★ `UP_DOI_FAB_COST` 는 제외**(현행 미사용, execlog에 없음).
- **DOI_IVDD 복사**: `UP_DOI_SCOF` 는 DOI_IVDD를 **읽기만** 하는데 INSERT 개체가 없다. DOI_MATL_RESC에서 복사하되 **IVDD 텍스트열이 nvarchar(바이트 max_length)** 이므로 LEFT 폭 = `max_length/2`(nvarchar), varchar는 `max_length` CONVERT(한글 바이트 절단). `copy_ivdd()` 가 폭을 동적 계산.
- `DOI_SCOF` 0행은 정상(유상사급 상계는 리포트가 `DOI_원장상계` 를 직접 읽음).

---

## 3. 검증 (C)

- **특이사항 반영**: `verify_special_cases()` — 해당 월 특이사항 모델로 조정해 확인.
- **PL tie-out**: `verify_tie_out()` — `DOI_PL_ByModel` Z합계 출력 + **항등식 자동검산**. **통과 기준**(모두 ✓ 여야 함):
  - 매출총이익 = 매출액 − 매출원가
  - 영업이익 = 매출총이익 − 판관비
  - 판관비 ByModel(`DOI_SMCE_COST` DIST_AMT 합) = 원천(`DOI_ACCT_EXPEN` CC)
  - 리포트가 **도우코드 라벨**(양산8136P 등)로 출력되면 도우코드 전환 정상
- 추가 권장(수동): 제조경비 ByModel=ByDept, 매출실적, 총원가 교차검증.

---

## 4. 202610 실제 결과 (참고 기준값)

- **기초 적재**: DEPT_COST 674 · MATL_RESC 298 · STOCK 110 · PROD_SUBUL 53 · 원장상계 15 · CST_RATE 1 · BOM 1315 · DEPT 83 · sale 24 · invoice 19 · ETC 129.
- **특이사항 1 (8176P 공정재투입/제품R/W)**: 재공 제품R/W=43 → `기타입고_RMA_RW`, 제품 공정재투입=43 → `DOI_STCO.OUT_REWORK`. 매출원가(제품)·제조원가(재공) 양 화면 반영 확인.
- **특이사항 2 (8213D 공용자재 배부)**: 예상(환산량0→배부0) **미발생**. 8210/8211/8212 는 당월 생산 없음 → 공용자재 3종(DWD05821W0 25,600·DWD04821B1 51,300·DWD04821F1 51,200 = **128,100**)이 유일 소비처 8213D에 **전액 정상 배부**(배부방식=BOM, 생산출력 기반). **교정 불필요.**
  - **재사용 패턴(매월 점검)**: 공용자재(여러 모델이 공유하는 BOM 자재)를 '환산량 0인 모델'이 공동 소비할 때 주의. (a) 공동 소비 모델들이 **모두** 생산 있음 → 배부는 환산량 비중으로 분배(0인 모델엔 0). (b) **환산량 0인 모델만** 당월 생산(타 공유모델 생산 無) → 전액 그 모델로 배부(=이번 8213D 사례, 정상). 결산 후 `DOI_MAT_COST` 에서 해당 자재의 모델별 배부금액 합 = `in_amt`(총투입) 인지, 누락/중복이 없는지 확인.
- **PL tie-out**: 매출액 4,831,183,969(제품매출 5,006,239,403 − 유상사급 175,055,434) · 매출원가 3,298,107,237(제품매출원가 3,280,167,761) · 매출총이익 1,533,076,732 · **판관비 1,348,622,555** · **영업이익 184,454,177**.
  - ⚠️ 유상사급 175,055,434 에 **회계-조정 -773,988,566**(이례적 큰 음수) 포함 — 담당자 확인 필요.

---

## 5. 남은 단계 (이 패키지 미포함 — 결산 완료 후)

### 5-1. 재고자산충당금 → `DOI_재고자산평가`

> ★ **결산이 끝난 뒤, 담당자로부터 '재고자산충당금 내역'을 받으면 그때 적재/업데이트한다.** 결산 전에는 충당금 값이 확정되지 않으므로 이 단계는 결산 완료 후에 진행한다. 내역이 갱신되어 다시 오면 같은 방식으로 재적재(해당 월 DELETE 후 재INSERT)한다.

- 엑셀: `…재고자산충당금 내역…★ CMS 결산 후 재조정.xlsx` 의 **N월** 시트. **데이터행만**(맨 끝 '재공품 합계'/'제품 합계'/TOTAL 행 제외).
- `DELETE FROM DOI_재고자산평가 WHERE YYYYMM=<월> AND SITE='HQ'` 후 INSERT.
- 열 매핑(엑셀 1~14 → DB): 재고자산구분(1)·구분(2)·품번(3)·재고수량(4,int)·취득원가(5)·판매단가_KRW(6)·판매단가_USD(7)·환율(8)·NRV(9)·차이(10)·충당금기설정액(11)·조정금액(12)·충당금잔액(13)·비고(14). (YYYYMM/SEL_CODE='ACTUAL'/SITE='HQ' 선두)
- **PL (4)재고금액평가손실 = 당월 차이(10)합 − 전월 차이합** 으로 리포트가 자동 반영.
- 202610 참고: 데이터 14행, 차이합 **42,642,963**(재공품 24,588,186 + 제품 18,054,777), 전월 33,664,206 → (4) = **8,978,757**.

### 5-2. 마감 → `DOI_CLOSING_MONTH`

> 위 충당금까지 반영·검증하고 최종 승인된 뒤에 마감한다. (마감하면 해당 월 적재/변환 인터페이스가 차단됨)

```sql
INSERT INTO DOI_CLOSING_MONTH (YYYYMM, SITE, IS_CLOSED, CLOSED_AT, CLOSED_BY, NOTE)
VALUES ('<월>', 'HQ', 'Y', GETDATE(), '<작업자>', '2026년 N월 결산 마감');
```

- 컬럼: YYYYMM · SITE · IS_CLOSED('Y') · CLOSED_AT(datetime) · CLOSED_BY(예 'SYSADMIN') · NOTE. (전월 예: 202609 → NOTE '2026년 9월 결산 마감')

---

## 6. 트러블슈팅

- **오류 213 (INSERT 값 개수 불일치)** @ UP_DOI_SALE_COST → §2-2 ALTER 미적용. 수정 SQL 실행.
- **오류 2628/8152 (문자열 잘림)** @ DOI_IVDD 복사 → nvarchar 폭을 바이트(max_length)로 오인. `max_length/2` 사용(`copy_ivdd` 동적 계산).
- **UP_DOI_EXPEN_MATL STEP1 0행 중단** → DOI_CST_RATE 미적재. §1-6.
- **배부 0 / 출고O 원가0** → DOI_MODEL_MAST 면적(XY) 누락 모델. §2-1 주입 3단계 재확인.
- **DOI_MODEL_MAST 주입 중 `CAST varchar→real` 오류** → Spec 치수 뒤에 공백+텍스트가 붙은 행(예: `200*200 1.1T (WAFER)` → y=`200 1.1T (WAFER)`). 쿼리에서 x·y 를 `LTRIM` 후 `CHARINDEX(' ')` 앞까지 `LEFT` 로 공백절단하고, XY 를 `TRY_CONVERT(real,x)*TRY_CONVERT(real,y)` 로 바꿔 재실행(이상행은 XY NULL → 검증에서 걸림). 202610 데이터는 오류 없었음.
- **MES 링크드서버 접근 실패** → `SELECT name FROM sys.servers WHERE is_linked=1` 로 'MES'(10.100.40.250) 존재/권한 확인. MES DB명 = `도우제조MES시스템DB`.
- **BOM 소요량 0.1667** → API 적재분. 엑셀 전체교체(§1-7).
- **515 + execlog 0건** → 결산 프로시저 @Message NULL 함정 가능. 읽기전용 재현으로 원인 확정 후 대응.
- 결산 프로시저는 **공유 라이브 개체** — 편집 전 `OBJECT_DEFINITION` 으로 최신본 받아 그 위에서 수정, 백업(`db/hq_procs/bak…`) 필수.
