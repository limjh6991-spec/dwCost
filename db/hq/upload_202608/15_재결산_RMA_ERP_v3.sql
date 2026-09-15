/* ============================================================
   202608 HQ 재결산 — RMA R/W 재공 재투입 ERP 투입금액(총평균) 통일 v3
   선행: db/hq_procs/UP_DOI_EXPEN_MATL_fix260915v3_rma_erp.sql
         db/hq_procs/UP_DOI_STOCK_COST_fix260915v3_rma_erp.sql  (둘 다 성공 후 실행)
   백업: 프로시저 *_bak260915v3, 데이터 *_bak260915v3_hq (2026-09-15 14:35 결산 상태)
   ============================================================ */

-- [0] 마감 상태면 중단
IF EXISTS (SELECT 1 FROM DOI_CLOSING_MONTH WHERE YYYYMM = '202608' AND SITE = 'HQ' AND IS_CLOSED = 'Y')
BEGIN
    RAISERROR(N'202608 HQ 가 마감 상태입니다. 마감 해제 후 실행하세요.', 16, 1);
    SET NOEXEC ON;
END
GO

-- [1] 재결산 (기존 결산 순서 그대로)
EXEC UP_DOI_EXPEN_MATL '202608', 'HQ', 'ACTUAL';
GO
EXEC UP_DOI_MAT_AMT '202608', 'HQ', 'ACTUAL';
GO
EXEC UP_DOI_MAT_COST '202608', 'HQ', 'ACTUAL';
GO
EXEC UP_DOI_COST '202608', 'HQ', 'ACTUAL';
GO
EXEC UP_DOI_STOCK_BOH '202608', 'HQ', 'ACTUAL';   -- 내부에서 UP_DOI_STOCK_COST 호출
GO
-- ⚠ UP_DOI_STOCK_BOH 는 STOCK_COST 호출 뒤 구 후처리(DOI_STCO RMA행 기말·양산 OUTETC=rma_amt)를 다시 적용해
--   STOCK_COST 의 양산 반품크레딧 접기와 겹친다(양산 반품 8모델 크레딧 이중, RMA 기말 3,565,861로 틀어짐).
--   2026-09-15 실측. STOCK_COST 를 한 번 더 단독 실행해 DOI_STCO 를 STOCK_COST 결과로 되돌린다.
DECLARE @m nvarchar(max) = N'';
EXEC UP_DOI_STOCK_COST @YYYYMM = '202608', @SITE = 'HQ', @SEL_CODE = 'ACTUAL', @R_Message = @m OUTPUT;
GO
EXEC UP_DOI_SALE_COST '202608', 'HQ', 'ACTUAL';
GO
SET NOEXEC OFF;
GO

-- [2] 실행 결과 (6건 모두 SUCCESS 여야 함)
SELECT exec_date, proc_name, exec_rslt
FROM doi_execlog
WHERE yyyymm = '202608' AND site = 'HQ' AND exec_date >= DATEADD(MINUTE, -30, GETDATE())
ORDER BY exec_date;

-- [3] 7073 확인
-- 재공 재투입: 기대 [in] = ETC_IN_RMA_AMT = 8,146,083 / 258개
SELECT model, SUM([in]) AS 재투입_in, SUM(ETC_IN_RMA_AMT) AS ETC_IN_RMA_AMT, MAX(ETC_IN_RMA_QTY) AS 수량
FROM DOI_EXPEN_MATL
WHERE yyyymm = '202608' AND site = 'HQ' AND sel_code = 'ACTUAL' AND model = '7073' AND EXPEN_SEL = 'RMA1'
GROUP BY model;

-- 제품 RMA: 기대 공정재투입 = 타계정출고 = 8,146,083 / 출고 0 / 기말 2,241,752 (변경 전: 6,821,974 / 6,821,974 / -1,324,109 / 2,241,752)
SELECT 'AFTER' AS 시점, BOH_AMT, RMA_IN_AMT, OUT_AMT, OUTETC_AMT, OUT_REWORK_AMT, EOH_AMT,
       OUT_AMT - OUTETC_AMT + ISNULL(OUT_RMA_AMT, 0) AS 매출원가반영
FROM DOI_STCO WHERE yyyymm = '202608' AND site = 'HQ' AND sel_code = 'ACTUAL' AND 구분 = N'RMA' AND MODEL = '7073'
UNION ALL
SELECT 'BEFORE', BOH_AMT, RMA_IN_AMT, OUT_AMT, OUTETC_AMT, OUT_REWORK_AMT, EOH_AMT,
       OUT_AMT - OUTETC_AMT + ISNULL(OUT_RMA_AMT, 0)
FROM DOI_STCO_bak260915v3_hq WHERE sel_code = 'ACTUAL' AND 구분 = N'RMA' AND MODEL = '7073';

-- [4] 변경 전 스냅샷 대비 모델별 차이 (기대: 7073 재공만 IN/EOH +1,324,109, 제품은 RMA 7073 행만 변경)
SELECT 'DOI_COST' AS 테이블, ISNULL(a.model, b.model) AS model,
       ISNULL(a.i, 0) - ISNULL(b.i, 0) AS IN_차이, ISNULL(a.e, 0) - ISNULL(b.e, 0) AS EOH_차이, ISNULL(a.o, 0) - ISNULL(b.o, 0) AS OUT_차이
FROM (SELECT model, SUM([IN]) i, SUM(EOH) e, SUM([OUT]) o FROM DOI_COST WHERE yyyymm = '202608' AND site = 'HQ' AND sel_code = 'ACTUAL' GROUP BY model) a
FULL JOIN (SELECT model, SUM([IN]) i, SUM(EOH) e, SUM([OUT]) o FROM DOI_COST_bak260915v3_hq WHERE sel_code = 'ACTUAL' GROUP BY model) b ON a.model = b.model
WHERE ABS(ISNULL(a.i, 0) - ISNULL(b.i, 0)) + ABS(ISNULL(a.e, 0) - ISNULL(b.e, 0)) + ABS(ISNULL(a.o, 0) - ISNULL(b.o, 0)) > 0.5;

SELECT 'DOI_STCO' AS 테이블, ISNULL(a.구분, b.구분) AS 구분, ISNULL(a.model, b.model) AS model,
       ISNULL(a.o, 0) - ISNULL(b.o, 0) AS OUT_차이, ISNULL(a.x, 0) - ISNULL(b.x, 0) AS OUTETC_차이, ISNULL(a.e, 0) - ISNULL(b.e, 0) AS EOH_차이
FROM (SELECT 구분, model, SUM(OUT_AMT) o, SUM(OUTETC_AMT) x, SUM(EOH_AMT) e FROM DOI_STCO WHERE yyyymm = '202608' AND site = 'HQ' AND sel_code = 'ACTUAL' GROUP BY 구분, model) a
FULL JOIN (SELECT 구분, model, SUM(OUT_AMT) o, SUM(OUTETC_AMT) x, SUM(EOH_AMT) e FROM DOI_STCO_bak260915v3_hq WHERE sel_code = 'ACTUAL' GROUP BY 구분, model) b ON a.구분 = b.구분 AND a.model = b.model
WHERE ABS(ISNULL(a.o, 0) - ISNULL(b.o, 0)) + ABS(ISNULL(a.x, 0) - ISNULL(b.x, 0)) + ABS(ISNULL(a.e, 0) - ISNULL(b.e, 0)) > 0.5;
