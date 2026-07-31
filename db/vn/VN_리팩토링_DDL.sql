/* ============================================================
   VN 원가 리팩토링 DDL (260731-2, 정정본) — VN 전용 신규 테이블
   ★ 방침: VN은 doi_mat_cost / doi_expen_matl 미사용.
     원천(DOI_VN_MAT_INPUT·DOI_MATL_RESC·doi_acct_expen)에서 직접 배부.
   파이프라인: ① doi_expn_matl(투입) → ② DOI_COST_BOH(기초) → ③ doi_cost_unit(단가) → ④ doi_cost_wip(재공평가)
   함수: UP_VN_EXPN_INPUT → UP_VN_COST_BOH → UP_VN_COST_UNIT → UP_VN_WIP_EVAL
   공정(PL전/PL후)은 컬럼이 아니라 EOHEQ(V_VN_WIP_CONV)로 ③④에서만 반영.
   ============================================================ */

-- ① 투입 배부 (재료+가공, 제품=도우코드 배부, 투입금액+투입수량[=SUM(IN_MONTH)])
IF OBJECT_ID('dbo.doi_expn_matl') IS NULL
CREATE TABLE dbo.doi_expn_matl (
  YYYYMM varchar(6) NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분 nvarchar(10) NOT NULL, 도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL DEFAULT '',
  원가구분 nvarchar(10) NOT NULL,            -- 재료비/가공비
  EXPEN_SEL varchar(10) NOT NULL, expen_sel명 nvarchar(60) NULL,
  분류 nvarchar(60) NOT NULL DEFAULT '',      -- ACCT_NAME (원장/기타/계정과목)
  항목 nvarchar(60) NOT NULL,                 -- ITEM_NAME (자재번호 / UTG)
  배부방식 nvarchar(10) NULL,                 -- 직과/공통/-
  투입수량 numeric(18,2) NOT NULL DEFAULT 0,  -- 도우코드 SUM(IN_MONTH), 원가항목 행마다 반복
  투입금액 numeric(18,2) NOT NULL DEFAULT 0,
  edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_expn_matl PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,원가구분,EXPEN_SEL,분류,항목));

-- ③ 재공단가 = (기초+투입)/(OUT+EOHEQ)
IF OBJECT_ID('dbo.doi_cost_unit') IS NULL
CREATE TABLE dbo.doi_cost_unit (
  YYYYMM varchar(6) NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분 nvarchar(10) NOT NULL, 도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL DEFAULT '',
  원가구분 nvarchar(10) NOT NULL, EXPEN_SEL varchar(10) NOT NULL, 분류 nvarchar(60) NOT NULL DEFAULT '', 항목 nvarchar(60) NOT NULL,
  단가 numeric(24,12) NOT NULL DEFAULT 0, edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_cost_unit PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,원가구분,EXPEN_SEL,분류,항목));

-- ④ 재공평가(원가) — BOH/IN/EOH/OUT/LOSS + PL전/후/입고전_AMT (완전 원가보존)
IF OBJECT_ID('dbo.doi_cost_wip') IS NULL
CREATE TABLE dbo.doi_cost_wip (
  YYYYMM varchar(6) NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분 nvarchar(10) NOT NULL, 도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL DEFAULT '',
  원가구분 nvarchar(10) NOT NULL, EXPEN_SEL varchar(10) NOT NULL, 분류 nvarchar(60) NOT NULL DEFAULT '', 항목 nvarchar(60) NOT NULL,
  BOH numeric(18,2) NOT NULL DEFAULT 0, [IN] numeric(18,2) NOT NULL DEFAULT 0, UNIT_COST numeric(24,12) NOT NULL DEFAULT 0,
  EOHEQ numeric(18,4) NOT NULL DEFAULT 0, EOH numeric(18,2) NOT NULL DEFAULT 0,
  [OUT] numeric(18,2) NOT NULL DEFAULT 0, LOSS numeric(18,2) NOT NULL DEFAULT 0,
  PL전_AMT numeric(18,2) NOT NULL DEFAULT 0, PL후_AMT numeric(18,2) NOT NULL DEFAULT 0, 입고전_AMT numeric(18,2) NOT NULL DEFAULT 0,
  edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_cost_wip PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,원가구분,EXPEN_SEL,분류,항목));

-- ② 기초: 공유테이블 DOI_COST_BOH 재활용 (도우코드/공정 컬럼 추가, BOH 소수점, PK에 도우코드+공정)
-- ALTER TABLE dbo.DOI_COST_BOH ADD 도우코드 varchar(18) NOT NULL DEFAULT '', 공정 nvarchar(20) NOT NULL DEFAULT '';
-- ALTER TABLE dbo.DOI_COST_BOH ALTER COLUMN BOH numeric(18,2);
-- ALTER TABLE dbo.DOI_COST_BOH DROP CONSTRAINT PK_DOI_FAB_COST_BOH;
-- ALTER TABLE dbo.DOI_COST_BOH ADD CONSTRAINT PK_DOI_FAB_COST_BOH PRIMARY KEY CLUSTERED
--   (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN);
-- DOI_MAKE_COST_BOH: 컬럼목록 명시 + 도우코드/공정 이월 (회귀수정, 별도 파일)

-- (미사용) V_VN_PROCESS_RATE: 공정을 doi_expn_matl 컬럼으로 안 두어 현재 미사용. EOHEQ는 V_VN_WIP_CONV 사용.
