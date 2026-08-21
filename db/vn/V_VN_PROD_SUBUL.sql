
CREATE VIEW V_VN_PROD_SUBUL AS
-- [VN 260821] VN 전용 생산수불: doi_vn_prod_resc(WIP 포지션)→생산수불 물량 매핑.
-- 컬럼 시그니처는 V_DOI_PROD_SUBUL과 동일(VN 결산 프로시저 호환).
SELECT r.yyyymm YYYYMM, r.sel_code SEL_CODE, 'VN' SITE,
  CASE WHEN r.division IN ('MASS','MP') THEN N'양산' ELSE N'개발' END 구분,
  CASE WHEN r.division IN ('MASS','MP') THEN 1 ELSE 2 END 구분_ord,
  r.도우코드,
  CASE WHEN LEN(r.도우코드)>1 THEN LEFT(r.도우코드,LEN(r.도우코드)-1) ELSE r.도우코드 END 도우모델,
  CAST(NULL AS nvarchar(50)) 작업구분, CAST(NULL AS nvarchar(50)) org작업구분,
  CASE WHEN LEN(r.도우코드)>1 THEN LEFT(r.도우코드,LEN(r.도우코드)-1) ELSE r.도우코드 END model,
  CAST(NULL AS nvarchar(20)) Inch, 'VINA' DW_Site,
  (ISNULL(r.T_BOH_전,0)+ISNULL(r.T_BOH_후,0)) BOH_MONTH,
  ISNULL(r.USC_INPUT,0) IN_MONTH, CAST(0 AS float) BONUS_MONTH,
  (ISNULL(r.TOTAL_EOH_전,0)+ISNULL(r.TOTAL_EOH_후,0)) EOH_MONTH,
  ISNULL(r.OUTPUT_A,0) OUT_MONTH,
  (ISNULL(r.LOSS_전,0)+ISNULL(r.LOSS_후,0)) LOSS_MONTH,
  CAST(0 AS float) NG_MONTH, CAST(0 AS float) 수율제외_MONTH, CAST(0 AS float) REWORK진행_MONTH,
  CAST(0 AS float) SHIPPING_PLAN_MONTH, CAST(0 AS float) SHIPPING_ACTUAL_MONTH,
  CAST(0 AS float) material_loss, CAST(0 AS float) recall_loss, CAST('N' AS varchar(1)) Adj_YN
FROM doi_vn_prod_resc r
