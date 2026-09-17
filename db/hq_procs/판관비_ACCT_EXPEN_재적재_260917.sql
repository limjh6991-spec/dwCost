-- =====================================================================
-- 판관비(비용구분='판관') 전용 DOI_ACCT_EXPEN 재적재
--   DOI_DEPT_COST의 판관 행만 수정한 경우, 전체 UP_DOI_EXPEN_MATL 재실행 없이
--   DOI_ACCT_EXPEN의 판관(ACCT_CLASS='CC') 행만 원천에서 다시 채운다.
--   ※ UP_DOI_EXPEN_MATL STEP3의 적재 로직과 동일. 필터만 '비용구분=판관' 추가.
--   ※ 제조(ACCT_CLASS='AA') 행은 손대지 않음 → 제조원가/재고/매출원가 base 불변.
--
-- 적용 순서:
--   1) 본 스크립트 실행 (DOI_ACCT_EXPEN 판관 재적재)
--   2) EXEC UP_DOI_SALE_COST  (판관비 배부 DOI_SMCE_COST 갱신 + 매출원가 DOI_SLCO 재생성)
--   → STOCK_BOH / STOCK_COST 는 불필요(제조·재고 미변경).
--
-- 검증(2026-09-17, TX 시뮬): 제조(AA) 불변(3,814,849,391/198행),
--   판관(CC) 1,262,962,432(397) → 1,265,378,164(352) = DOI_DEPT_COST 판관 원천 일치.
-- ⚠ 전제: 수정이 판관 행의 '금액'에 한정(비용구분 재분류 없음). 비용구분 자체가
--   제조<->판관으로 바뀐 행이 있으면 본 스크립트 대신 UP_DOI_EXPEN_MATL 전체 재실행 권장.
-- =====================================================================
SET NOCOUNT ON;
DECLARE @YYYYMM   VARCHAR(6)  = '202608';
DECLARE @SITE     VARCHAR(10) = 'HQ';
DECLARE @SEL_CODE VARCHAR(20) = 'ACTUAL';

BEGIN TRY
    BEGIN TRANSACTION;

    -- 적용 전 판관(CC) 현황
    DECLARE @cc_before_cnt INT, @cc_before_amt BIGINT;
    SELECT @cc_before_cnt = COUNT(*), @cc_before_amt = SUM(CAST(ACCT_AMT AS BIGINT))
    FROM DOI_ACCT_EXPEN
    WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND ACCT_CLASS='CC';

    -- (1) 판관(CC) 행만 삭제
    DELETE FROM DOI_ACCT_EXPEN
    WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE
      AND ACCT_CLASS='CC';
    DECLARE @deleted INT = @@ROWCOUNT;

    -- (2) DOI_DEPT_COST의 판관 행만 재적재 (STEP3 로직 동일 + 비용구분='판관' 필터)
    INSERT INTO DOI_ACCT_EXPEN
        (YYYYMM, SEL_CODE, SITE, ACCT_CLASS, DEPT, ACCT, ACCT_NAME, ITEM_NAME,
         ACCT_AMT, DBT_AMT, CRT_AMT, EXPEN_SEL, EXPEN_SEL명, DISP_SEQ)
    SELECT
        a.yyyymm                                    AS YYYYMM,
        @SEL_CODE                                   AS SEL_CODE,
        a.site                                      AS SITE,
        CASE WHEN a.비용구분 = '판관' THEN 'CC'
             WHEN a.비용구분 = '제조' THEN 'AA'
             ELSE a.비용구분 END                    AS ACCT_CLASS,
        b.dept                                      AS DEPT,
        a.계정코드                                  AS ACCT,
        a.계정과목                                  AS ACCT_NAME,
        c.소분류                                    AS ITEM_NAME,
        a.차변금액 - a.대변금액                     AS ACCT_AMT,
        a.차변금액                                  AS DBT_AMT,
        a.대변금액                                  AS CRT_AMT,
        c.expen_sel                                 AS EXPEN_SEL,
        c.expen_sel명                               AS EXPEN_SEL명,
        c.disp_seq                                  AS DISP_SEQ
    FROM DOI_DEPT_COST a
    LEFT JOIN (SELECT DISTINCT dept, dept_name FROM doi_dept
               WHERE yyyymm=@YYYYMM AND site=@SITE) b
           ON (a.코스트센터 = b.dept_name)
    LEFT JOIN doi_acct c
           ON (a.yyyymm=c.yyyymm AND a.sel_code=c.sel_code AND a.site=c.site AND a.계정코드=c.acct)
    WHERE a.yyyymm=@YYYYMM AND a.site=@SITE
      AND coalesce(nullif(a.제외여부,''),'N') = 'N'
      AND a.비용구분 = '판관';
    DECLARE @inserted INT = @@ROWCOUNT;

    -- 적용 후 판관(CC) 현황 + 원천 대사
    DECLARE @cc_after_cnt INT, @cc_after_amt BIGINT, @src_cnt INT, @src_amt BIGINT;
    SELECT @cc_after_cnt = COUNT(*), @cc_after_amt = SUM(CAST(ACCT_AMT AS BIGINT))
    FROM DOI_ACCT_EXPEN
    WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND ACCT_CLASS='CC';

    SELECT @src_cnt = COUNT(*), @src_amt = SUM(CAST(차변금액-대변금액 AS BIGINT))
    FROM DOI_DEPT_COST
    WHERE yyyymm=@YYYYMM AND site=@SITE AND 비용구분='판관'
      AND coalesce(nullif(제외여부,''),'N')='N';

    PRINT '판관(CC) 삭제=' + CAST(@deleted AS VARCHAR) + ', 재적재=' + CAST(@inserted AS VARCHAR);
    PRINT '판관(CC) 합계: 전 ' + CAST(@cc_before_amt AS VARCHAR) + ' → 후 ' + CAST(@cc_after_amt AS VARCHAR);
    PRINT '원천(DOI_DEPT_COST 판관) 합계=' + CAST(@src_amt AS VARCHAR) + ' (일치여부는 위 값과 비교)';

    IF @cc_after_amt <> @src_amt OR @cc_after_cnt <> @src_cnt
    BEGIN
        PRINT '⚠ 재적재 결과가 원천과 불일치 — 롤백';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        COMMIT TRANSACTION;
        PRINT '커밋 완료. 다음: EXEC UP_DOI_SALE_COST 로 판관비 배부(DOI_SMCE_COST) 갱신.';
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
