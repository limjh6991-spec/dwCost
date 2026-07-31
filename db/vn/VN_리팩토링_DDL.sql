/* ============================================================
   VN 원가 리팩토링 DDL (260731) — 신규 테이블/뷰 + 공유테이블 변경
   방침: VN 전용. 본사 무영향(도우코드='' , 공정='*' 기본값).
   함수 5개: UP_VN_EXPN_INPUT(투입) → UP_VN_COST_BOH(기초) → UP_VN_COST_UNIT(단가) → UP_VN_WIP_EVAL(재공평가)
   ============================================================ */

-- (1) 투입 집계 (재료비+가공비, 수량/금액만, 공정별)
IF OBJECT_ID('dbo.doi_vn_expn_matl') IS NULL
CREATE TABLE dbo.doi_vn_expn_matl (
  YYYYMM varchar(6) NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분 nvarchar(10) NOT NULL, 도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL DEFAULT '',
  공정 nvarchar(10) NOT NULL,              -- PL전/PL후
  원가구분 nvarchar(10) NOT NULL,           -- 재료비/가공비
  EXPEN_SEL varchar(10) NOT NULL, 분류 nvarchar(60) NOT NULL DEFAULT '',  -- 분류=ACCT_NAME
  항목 nvarchar(60) NOT NULL,               -- 항목=ITEM_NAME(자재번호 / UTG)
  투입수량 numeric(18,2) NOT NULL DEFAULT 0, 투입금액 numeric(18,2) NOT NULL DEFAULT 0,
  edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_vn_expn_matl PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,공정,원가구분,EXPEN_SEL,분류,항목));

-- (2) 재공단가
IF OBJECT_ID('dbo.doi_cost_unit') IS NULL
CREATE TABLE dbo.doi_cost_unit (
  YYYYMM varchar(6) NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분 nvarchar(10) NOT NULL, 도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL DEFAULT '',
  공정 nvarchar(10) NOT NULL, 원가구분 nvarchar(10) NOT NULL,
  EXPEN_SEL varchar(10) NOT NULL, 분류 nvarchar(60) NOT NULL DEFAULT '', 항목 nvarchar(60) NOT NULL,
  단가 numeric(24,12) NOT NULL DEFAULT 0, edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_cost_unit PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,공정,원가구분,EXPEN_SEL,분류,항목));

-- (3) 재공평가 결과 (EOH + PL전/후/입고전_AMT)
IF OBJECT_ID('dbo.doi_cost_wip') IS NULL
CREATE TABLE dbo.doi_cost_wip (
  YYYYMM varchar(6) NOT NULL, SEL_CODE varchar(10) NOT NULL, SITE varchar(4) NOT NULL,
  구분 nvarchar(10) NOT NULL, 도우코드 varchar(18) NOT NULL, 도우모델 varchar(18) NOT NULL DEFAULT '',
  원가구분 nvarchar(10) NOT NULL, EXPEN_SEL varchar(10) NOT NULL, 분류 nvarchar(60) NOT NULL DEFAULT '', 항목 nvarchar(60) NOT NULL,
  BOH numeric(18,2) NOT NULL DEFAULT 0, [IN] numeric(18,2) NOT NULL DEFAULT 0, UNIT_COST numeric(24,12) NOT NULL DEFAULT 0,
  EOHEQ numeric(18,4) NOT NULL DEFAULT 0, EOH numeric(18,2) NOT NULL DEFAULT 0,
  PL전_AMT numeric(18,2) NOT NULL DEFAULT 0, PL후_AMT numeric(18,2) NOT NULL DEFAULT 0, 입고전_AMT numeric(18,2) NOT NULL DEFAULT 0,
  edit_date datetime DEFAULT GETDATE(),
  CONSTRAINT PK_doi_cost_wip PRIMARY KEY (YYYYMM,SEL_CODE,SITE,구분,도우코드,원가구분,EXPEN_SEL,분류,항목));

-- (4) 공정(PL전/PL후) 비율 뷰 — doi_prod_subul.PL전/PL후 수량비율. 규칙 변경시 이 뷰만 교체.
GO
CREATE OR ALTER VIEW dbo.V_VN_PROCESS_RATE AS
WITH q AS (
  SELECT yyyymm, site, 구분, 도우코드,
    SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,'0'),',',''),' ',''))) pl전,
    SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,'0'),',',''),' ',''))) pl후
  FROM DOI_PROD_SUBUL GROUP BY yyyymm, site, 구분, 도우코드)
SELECT yyyymm, site, 구분, 도우코드, v.공정,
  CASE WHEN (pl전+pl후)>0 THEN v.수량/(pl전+pl후)
       ELSE CASE WHEN v.공정=N'PL후' THEN 1.0 ELSE 0.0 END END AS 비율   -- WIP 0이면 PL후 100%(잠정)
FROM q CROSS APPLY (VALUES (N'PL전', pl전), (N'PL후', pl후)) v(공정, 수량);
GO

-- (5) 공유테이블 DOI_COST_BOH 변경 (VN 기초 저장용, 본사 미사용·0행 확인 후)
--   - 도우코드/공정 컬럼 추가, BOH 소수점(달러) 확보, PK에 도우코드+공정 포함(다대일 대응)
-- ALTER TABLE dbo.DOI_COST_BOH ADD 도우코드 varchar(18) NOT NULL DEFAULT '', 공정 nvarchar(20) NOT NULL DEFAULT '';
-- ALTER TABLE dbo.DOI_COST_BOH ALTER COLUMN BOH numeric(18,2);
-- ALTER TABLE dbo.DOI_COST_BOH DROP CONSTRAINT PK_DOI_FAB_COST_BOH;
-- ALTER TABLE dbo.DOI_COST_BOH ADD CONSTRAINT PK_DOI_FAB_COST_BOH PRIMARY KEY CLUSTERED
--   (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN);
