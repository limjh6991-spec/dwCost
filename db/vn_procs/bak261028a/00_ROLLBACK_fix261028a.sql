/* ============================================================
   UP_VN_STOCK_ADJ fix261028a 원복 — 2026-10-28 적용 직전 상태로 되돌린다. (DWCMSTEST)
   적용 내용: 6272 부재료 출고 필터에 베트남어 입출고구분(Xuất kho) 추가 후
             202608 VN ACTUAL 체인 재실행 (STOCK_ADJ → MATL_RESC → MAT_AMT → EXPN_INPUT
             → MAT_COST_NEW → COST_UNIT → STOCK_BOH_NEW → RSRW → WIP_EVAL_NEW
             → STOCK_COST_NEW → SALE_COST_NEW).
   ※ UP_VN_ACCT_EXPEN 은 마감월 차단 + 부재료 무관, UP_VN_COST_BOH 는 전월 이월이라 제외.
   ※ UP_VN_SMCE_COST_NEW 는 제외: DOI_INVOICE_RESC 에 202608 VN 행이 없어(10/28 기준)
     재실행하면 판관비 배부가 0행이 된다. 기존 468행 유지.
   결과: 재료비 투입 8,091,589.24 → 8,119,368.65 (부재료 +27,779.41), 매출원가 +22,214.12.
   데이터 스냅샷: <테이블>_bak261028a (202608 VN ACTUAL 행만)
   ============================================================ */

-- ① 프로시저 정의 원복
--    bak261028a/UP_VN_STOCK_ADJ.sql 실행

-- ② 데이터 원복 (스냅샷 → 원 테이블)
DECLARE @t sysname, @w nvarchar(400), @sql nvarchar(max);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT t FROM (VALUES ('doi_vn_stock_adj'),('doi_matl_resc'),('doi_mat_amt'),('doi_expn_matl'),('doi_mat_cost'),
                        ('doi_cost_unit'),('doi_stock_boh'),('doi_vn_rsrw'),('doi_vn_cost'),('doi_vn_stco'),('doi_slco')) v(t);
OPEN c; FETCH NEXT FROM c INTO @t;
BEGIN TRAN;
WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT @w = STRING_AGG(QUOTENAME(name) + N'=' + CASE LOWER(name) WHEN 'yyyymm' THEN N'''202608''' WHEN 'site' THEN N'''VN''' ELSE N'''ACTUAL''' END, N' AND ')
    FROM sys.columns WHERE object_id = OBJECT_ID(@t) AND LOWER(name) IN ('yyyymm','site','sel_code');
  SET @sql = N'DELETE FROM ' + @t + N' WHERE ' + @w + N'; INSERT INTO ' + @t + N' SELECT * FROM ' + @t + N'_bak261028a;';
  EXEC sp_executesql @sql;
  FETCH NEXT FROM c INTO @t;
END
COMMIT;
CLOSE c; DEALLOCATE c;
