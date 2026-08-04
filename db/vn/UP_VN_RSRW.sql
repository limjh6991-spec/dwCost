/* ============================================================
   [VN 260801] R/S·R/W 재공 기타입고(ETC-IN) 금액 확정 → DOI_VN_RSRW (원가항목별)
   - 수량: doi_vn_prod_resc (ETCIN_RESORT/REWORK), 도우코드 단위
   - 단가: 제품 재고기초 = DOI_STOCK_BOH (도우코드=model_type, division MP=양산/R&D=개발)
   - 우선순위: R/S 우선(기초금액 다 소진) → R/W. 총 기초금액 한도, 초과분 0.
   - 원가항목: 총 R/S·R/W 금액을 DOI_STOCK_BOH의 expen_sel(재료/가공) 구성비로 안분 → 재공단가 분자(ETC-IN)로 사용.
   ============================================================ */
IF OBJECT_ID('DOI_VN_RSRW') IS NOT NULL DROP TABLE DOI_VN_RSRW;
CREATE TABLE DOI_VN_RSRW (
  yyyymm varchar(6) NOT NULL, sel_code varchar(10) NOT NULL, 구분 varchar(10) NOT NULL, 도우코드 nvarchar(30) NOT NULL,
  EXPEN_SEL varchar(6) NOT NULL,
  boh_qty numeric(18,2), boh_amt numeric(18,2), es_boh_amt numeric(18,2),
  rs_qty numeric(18,2), rw_qty numeric(18,2), rs_amt numeric(18,2), rw_amt numeric(18,2),
  edit_dt datetime DEFAULT getdate(),
  CONSTRAINT PK_DOI_VN_RSRW PRIMARY KEY (yyyymm, sel_code, 구분, 도우코드, EXPEN_SEL)
);
GO
CREATE OR ALTER PROCEDURE UP_VN_RSRW @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_RSRW WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE;
  ;WITH bohtot AS (   -- 도우코드 총 재고기초 + 총단가
    SELECT model_type 도우코드, CASE WHEN 구분=N'양산' THEN 'MP' ELSE 'R&D' END division,
           SUM(CAST(boh AS float)) boh_qty, SUM(CAST(boh_amt AS float)) boh_amt,
           SUM(CAST(boh_amt AS float))/NULLIF(SUM(CAST(boh AS float)),0) 단가
    FROM DOI_STOCK_BOH WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY model_type, CASE WHEN 구분=N'양산' THEN 'MP' ELSE 'R&D' END),
  bohes AS (   -- expen_sel별 재고기초 금액 (안분 기준)
    SELECT model_type 도우코드, CASE WHEN 구분=N'양산' THEN 'MP' ELSE 'R&D' END division, expen_sel,
           SUM(CAST(boh_amt AS float)) es_amt
    FROM DOI_STOCK_BOH WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY model_type, CASE WHEN 구분=N'양산' THEN 'MP' ELSE 'R&D' END, expen_sel),
  rsrw AS (   -- R/S·R/W 수량 (재공 기타입고)
    SELECT 도우코드, division, SUM(CAST(ISNULL(ETCIN_RESORT,0) AS float)) rs_qty, SUM(CAST(ISNULL(ETCIN_REWORK,0) AS float)) rw_qty
    FROM doi_vn_prod_resc WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE GROUP BY 도우코드, division),
  tot AS (   -- 도우코드 총 R/S·R/W 금액 (R/S 우선 캡)
    SELECT r.도우코드, r.division, r.rs_qty, r.rw_qty, ISNULL(b.boh_qty,0) boh_qty, ISNULL(b.boh_amt,0) boh_amt,
           CASE WHEN r.rs_qty*ISNULL(b.단가,0) <= ISNULL(b.boh_amt,0) THEN r.rs_qty*ISNULL(b.단가,0) ELSE ISNULL(b.boh_amt,0) END rs_amt_tot
    FROM rsrw r LEFT JOIN bohtot b ON b.도우코드=r.도우코드 AND b.division=r.division),
  tot2 AS (SELECT *, CASE WHEN rw_qty*(CASE WHEN boh_qty=0 THEN 0 ELSE boh_amt/boh_qty END) <= boh_amt - rs_amt_tot
                         THEN rw_qty*(CASE WHEN boh_qty=0 THEN 0 ELSE boh_amt/boh_qty END) ELSE boh_amt - rs_amt_tot END rw_amt_tot
           FROM tot WHERE rs_qty<>0 OR rw_qty<>0)
  INSERT INTO DOI_VN_RSRW (yyyymm, sel_code, 구분, 도우코드, EXPEN_SEL, boh_qty, boh_amt, es_boh_amt, rs_qty, rw_qty, rs_amt, rw_amt)
  SELECT @YYYYMM, @SEL_CODE, t.division, t.도우코드, e.expen_sel,
     CAST(t.boh_qty AS numeric(18,2)), CAST(t.boh_amt AS numeric(18,2)), CAST(e.es_amt AS numeric(18,2)),
     CAST(t.rs_qty AS numeric(18,2)), CAST(t.rw_qty AS numeric(18,2)),
     CAST(t.rs_amt_tot * e.es_amt/NULLIF(t.boh_amt,0) AS numeric(18,2)),   -- 원가항목 안분
     CAST(t.rw_amt_tot * e.es_amt/NULLIF(t.boh_amt,0) AS numeric(18,2))
  FROM tot2 t JOIN bohes e ON e.도우코드=t.도우코드 AND e.division=t.division;
END
