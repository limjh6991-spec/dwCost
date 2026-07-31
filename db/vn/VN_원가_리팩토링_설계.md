# VN 가공비·재료비·재공평가 리팩토링 설계 (260731)

## ✅ 구축 완료 (as-built, 260731, DWCMSTEST 202606 검증)
소스 결정 = **기존 집계결과 추출**(권장): doi_mat_cost/doi_expen_matl → 신규 테이블. 총액 자동보존.

| # | 함수 | 출력 | 검증(202606 VN) |
|---|---|---|---|
| 1 | **UP_VN_EXPN_INPUT** | doi_vn_expn_matl(투입, 공정별) | 재료 5,124,416.21 / 가공 1,972,637.97 = 기존, 차 0 |
| 2 | **UP_VN_COST_BOH** | DOI_COST_BOH(기초) | 재료기초 219,010.29 / 가공기초 742,751.58 = 기존, 차 0 |
| 3 | **UP_VN_COST_UNIT** | doi_cost_unit(단가) | 단가 doi_mat_cost와 완전 일치 |
| 4 | **UP_VN_WIP_EVAL** | doi_cost_wip(재공평가) | EOH합 1,118,430 = DOI_COST, **불일치 0건**. PL전/후_AMT 완전 일치 |

- 716AP: 재료EOH 141,152 / 가공EOH 89,234 = 기존 DOI_COST 정확 일치
- 공정 = V_VN_PROCESS_RATE(doi_prod_subul PL전/PL후 비율, 716AP=72.24/27.76). 규칙변경시 뷰만 교체.
- DDL: db/vn/VN_리팩토링_DDL.sql · 함수: db/vn/UP_VN_*.sql

## ✅ 구축 2단계 (스위치·화면호환·투입수량·카세트, 260731)
- **#2 스위치**: `UP_VN_WIP_EVAL`이 재공평가 결과를 **DOI_COST에 직접 반영**(EOH/PL전/PL후/입고전_AMT) → 권위 소스. 검증: **EOH 행단위 0차이**, PL 총액 완전동일. PL전/후_AMT 대표행 위치만 37/29행 이동하나 (원본 UP_VN_COST가 가공행 ITEM_NAME='UTG' 동점으로 **원래 비결정적**) + **어떤 화면도 _AMT 3컬럼 미참조**(grep 확인) → 실질 무손실. 실행순서: UP_VN_COST 후 UP_VN_WIP_EVAL.
- **#3 화면호환**: `DOI_COST_BOH`는 미사용이 아니라 **C0007010(기초금액관리)+DOI_MAKE_COST_BOH 소유**였음. 도우코드/공정 2컬럼 추가로 컬럼목록 없는 INSERT가 깨져 **DOI_MAKE_COST_BOH를 컬럼명시+도우코드/공정 이월로 수정**(회귀 해소, 원본=DOI_MAKE_COST_BOH_ORIG_backup.sql). 그외 화면(C0008/C0009/C0003/C0007006)은 doi_mat_cost/doi_expen_matl/doi_cost 원본 참조 → 무영향.
- **#4 투입수량**: 직과재료(배부방식='직과')만 DOI_VN_MAT_INPUT 원천 투입수량 연결(716AP=1,008,753.42). 공통/가공은 0(면적배부/금액배부라 수량개념 없음).
- **#4 카세트**: VN은 doi_vncst_rate 미사용 → doi_expen_matl VINA CST IN=0, DOI_COST 카세트(len>5) 0행. **VN 대상 데이터 없음** → 파이프라인 len<=5 필터가 이미 정합. (추후 VN 카세트 생기면 별도 처리)

## 미결(운영화 잔여)
1. **배치/메뉴 연결**: 신규 4함수(INPUT→BOH→UNIT→WIP_EVAL)를 실행 배치에 편입(현재 수동 실행).
2. **UP_VN_COST 재공평가 블록 정리**(선택): 현재 UP_VN_COST가 EOH 계산 후 UP_VN_WIP_EVAL이 덮어씀(중복이나 무해). 완전 분리시 인라인 EOH/PL 블록 제거 — 단 OUT=BOH+IN-EOH가 EOH에 종속이라 신중.
3. **운영 DB 반영**: DDL+함수 6개 + DOI_MAKE_COST_BOH 수정.

## 방침
- **VN 전용** (본사는 doi_mat_cost/doi_expen_matl 기존 그대로)
- 투입(fact) / 기초 / 단가 / 재공평가(파생)를 **테이블·함수로 분리**
- 공정 = **PL전/PL후** 단계, 재공평가 EOH는 **DOI_COST 유지**
- 도우코드 로직(집계키·면적·기초분배) **재사용**

## 데이터 흐름
```
[투입]  DOI_VN_MAT_INPUT/DOI_MATL_RESC ─(UP_VN_MATL_INPUT)─┐
        doi_acct_expen                ─(UP_VN_EXPN_INPUT)─┴─▶ doi_vn_expn_matl (수량/금액)
[기초]  전월 EOH 이월 / DOI_BOH_AMT 시드 ─(UP_VN_COST_BOH)──▶ doi_cost_boh (원가항목별 BOH)
[단가]  doi_vn_expn_matl + doi_cost_boh ─(UP_VN_COST_UNIT)─▶ doi_cost_unit (재공단가)
[재공]  doi_cost_unit × EOHEQ + 위 ──(UP_VN_WIP_EVAL)──────▶ DOI_COST (BOH/IN/EOH/OUT)
```

## 1. 신규 테이블 DDL

### doi_vn_expn_matl (투입 집계 — 수량/금액만)
```sql
CREATE TABLE dbo.doi_vn_expn_matl (
  YYYYMM    varchar(6)   NOT NULL,
  SEL_CODE  varchar(10)  NOT NULL,
  SITE      varchar(4)   NOT NULL,
  구분      nvarchar(10) NOT NULL,
  도우코드  varchar(18)  NOT NULL,
  도우모델  varchar(18)  NOT NULL,
  공정      nvarchar(10) NOT NULL,          -- 'PL전' / 'PL후'
  원가구분  nvarchar(10) NOT NULL,          -- '재료비' / '가공비'
  EXPEN_SEL varchar(10)  NOT NULL,          -- MDAX/MIAX(재료) / E*(경비)
  항목      nvarchar(60) NOT NULL,          -- 자재번호 / ACCT
  분류      nvarchar(60) NULL,              -- mat_class / ACCT_NAME
  투입수량  numeric(18,2) NOT NULL DEFAULT 0,
  투입금액  numeric(18,2) NOT NULL DEFAULT 0,
  edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_vn_expn_matl PRIMARY KEY
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,공정,원가구분,EXPEN_SEL,항목)
);
```

### doi_cost_unit (재공단가)
```sql
CREATE TABLE dbo.doi_cost_unit (
  YYYYMM   varchar(6)  NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분     nvarchar(10) NOT NULL,
  도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL,
  공정     nvarchar(10) NOT NULL,           -- PL전/PL후
  원가구분 nvarchar(10) NOT NULL, EXPEN_SEL varchar(10) NOT NULL, 항목 nvarchar(60) NOT NULL,
  단가     numeric(24,12) NOT NULL DEFAULT 0,   -- (기초+투입)/(OUT+EOHEQ)
  edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_cost_unit PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,공정,원가구분,EXPEN_SEL,항목)
);
```

### doi_cost_boh (기존 테이블, 도우코드 컬럼 추가)
```sql
ALTER TABLE dbo.DOI_COST_BOH ADD 도우코드 varchar(18) NOT NULL DEFAULT '';
-- 기존: YYYYMM,SEL_CODE,SITE,구분,MODEL,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH
-- VN: MODEL=도우모델, 도우코드=도우코드, 공정 컬럼 필요시 추가
```

## 2. 함수 골격 (프로세스 순서)

| # | 함수 | 입력 → 출력 | 핵심 로직 |
|---|---|---|---|
| 1 | **UP_VN_MATL_INPUT** | DOI_VN_MAT_INPUT(직과)+DOI_MATL_RESC(공통) → doi_vn_expn_matl | 도우코드 집계, 직과=투입, 공통=환산량×면적 배부, **자재→공정(PL전/PL후) 귀속** |
| 2 | **UP_VN_EXPN_INPUT** | doi_acct_expen → doi_vn_expn_matl | 물량×면적 배부(도우코드), **부서/계정→공정 귀속** |
| 3 | **UP_VN_COST_BOH** | 전월 DOI_COST EOH 이월 / (초기)DOI_BOH_AMT → doi_cost_boh | 원가항목별 기초금액 확정 |
| 4 | **UP_VN_COST_UNIT** | doi_vn_expn_matl + doi_cost_boh → doi_cost_unit | 단가=(기초BOH+투입)/(OUT_QTY+EOHEQ), EOHEQ=PL전×0.5+PL후×0.9 |
| 5 | **UP_VN_WIP_EVAL** | doi_cost_unit×EOHEQ + doi_vn_expn_matl + doi_cost_boh → DOI_COST | BOH=기초, IN=투입, EOH=단가×EOHEQ, OUT=BOH+IN−EOH. DOI_COST 조립 |

→ 투입비용은 **doi_vn_expn_matl 하나**만 보면 됨. 재공평가는 UP_VN_WIP_EVAL로 완전 분리.

## 3. 공정(PL전/PL후) 귀속 — 확정
- **공정 소스 = `DOI_PROD_SUBUL.PL전 / PL후` 컬럼** (도우코드별 재공수량, 예 716AP: PL전 37,214 / PL후 14,303)
- **귀속 규칙(잠정)**: 각 도우코드의 투입(재료비/가공비)을 **PL전:PL후 수량비율**로 PL전/PL후에 배분
  - 예 716AP: PL전 72.2% / PL후 27.8% → 투입금액을 이 비율로 분할
- **★ 이후 변경 가능성 큼** → 비율/매핑을 **뷰 또는 매핑 함수로 분리**해 함수 본체는 안 건드리게 설계 (예: `V_VN_PROCESS_RATE(도우코드 → 공정, 비율)` 뷰를 두고 투입 함수가 그걸 조인). 규칙 바뀌면 뷰만 교체.
- ※ 참고: 총투입을 재공수량(기말WIP) 비율로 나누는 건 물리적 의미가 약함(기말 재공은 총생산의 일부). 잠정 규칙이므로 뷰로 격리해 나중에 실제 공정원가 기준으로 대체 가능하게 함.

## 4. 화면 호환 (후속)
현재 VN 화면(결산증빙자료 C0008, 총원가 등)이 doi_mat_cost/doi_expen_matl 직접 참조 → 신규 체계로 가면 (a) 그 화면들을 doi_vn_expn_matl 참조로 변경, 또는 (b) 호환 뷰 제공 필요. (EOH/재공평가는 DOI_COST 유지라 그쪽 화면은 영향 적음)
