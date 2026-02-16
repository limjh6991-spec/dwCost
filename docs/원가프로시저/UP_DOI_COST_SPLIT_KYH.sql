-- =============================================
-- Author:      System  
-- Create date: 2025-11-23
-- Description: 부서별 비용을 4개 테이블로 분할 배부 (V4 - 복수 테이블 배부)
-- 배부 로직:
--   제조경비(DOI_MFG_EXP):
--     - 원가 100% 부서 → 100% 제조경비
--     - 원가 90% 부서 → 90% 제조경비
--     - 총원가 10% 부서(RND_YN='N') → 90% 제조경비
--   판관비(DOI_SGA):
--     - 총원가 100% 부서(RND_YN='N') → 100% 판관비
--     - 총원가 10% 부서(RND_YN='N') → 10% 판관비
--     - 원가 90% 부서 → 10% 판관비
--   연구개발비(DOI_RND):
--     - RND_YN='Y' 부서 → 100% 연구개발비
--   카세트팀(DOI_CASET):
--     - DEPT='400','448' → UTG/VINA_CST 비율로 배부
-- =============================================
CREATE   PROCEDURE dbo.UP_DOI_COST_SPLIT_KYH
    @YYYYMM VARCHAR(6),
    @SEL_CODE VARCHAR(6) = 'ACTUAL',
    @SITE VARCHAR(4) = 'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MSG NVARCHAR(500)
    DECLARE @원본금액 BIGINT
    DECLARE @배부금액 BIGINT
    DECLARE @차이 BIGINT
    
    -- 원본 금액 확인 (DOI_DEPT_COST 직접 합계 - 조인하면 중복 카운트됨)
    SELECT @원본금액 = SUM(차변금액)
    FROM DOI_DEPT_COST
    WHERE YYYYMM = @YYYYMM
        AND SEL_CODE = @SEL_CODE
        AND SITE = @SITE
        AND 차변금액 > 0
    
    PRINT '========================================================================'
    PRINT '부서별 비용 분할 배부 시작: ' + @YYYYMM
    PRINT '========================================================================'
    PRINT '원본 금액: ' + CAST(@원본금액 AS VARCHAR(20)) + '원'
    PRINT ''
    
    -- 1. DOI_MFG_EXP (제조경비) 삭제 및 입력
    DELETE FROM DOI_MFG_EXP 
    WHERE YYYYMM = @YYYYMM AND SEL_CODE = @SEL_CODE AND SITE = @SITE
    
    -- 1-1. 원가 부서 → COST_DIST_RATE 비율로 제조경비
    INSERT INTO DOI_MFG_EXP (
        YYYYMM, SEL_CODE, SITE,
        FROM_DEPT_CODE, FROM_DEPT_NAME,
        FROM_ACCT_CODE, FROM_ACCT_NAME,
        EXPEN_SEL, EXPEN_SEL_NAME,
        ACCT_AMT
    )
    SELECT 
        dc.YYYYMM,
        dc.SEL_CODE,
        dc.SITE,
        d.DEPT AS FROM_DEPT_CODE,
        dc.코스트센터 AS FROM_DEPT_NAME,
        dc.계정코드 AS FROM_ACCT_CODE,
        dc.계정과목 AS FROM_ACCT_NAME,
        a.EXPEN_SEL,
        a.EXPEN_SEL명 AS EXPEN_SEL_NAME,
        CAST(dc.차변금액 * ISNULL(d.COST_DIST_RATE, 100) / 100.0 AS BIGINT) AS ACCT_AMT
    FROM DOI_DEPT_COST dc
    INNER JOIN DOI_DEPT d 
        ON dc.YYYYMM = d.YYYYMM
        AND dc.코스트센터 = d.DEPT_NAME
    LEFT JOIN DOI_ACCT a
        ON dc.YYYYMM = a.YYYYMM
        AND dc.SEL_CODE = a.SEL_CODE
        AND dc.SITE = a.SITE
        AND dc.계정코드 = a.ACCT
    WHERE dc.YYYYMM = @YYYYMM
        AND dc.SEL_CODE = @SEL_CODE
        AND dc.SITE = @SITE
        AND (d.COST_DIST = N'원가' OR d.COST_DIST IS NULL)
        AND d.DEPT NOT IN ('400','448')
        AND dc.차변금액 > 0
    
    SET @MSG = '1. 제조경비(DOI_MFG_EXP): ' + CAST(@@ROWCOUNT AS VARCHAR) + '건 입력'
    PRINT @MSG
    
    
    
    -- 2. DOI_SGA (판매관리비) 삭제 및 입력
    DELETE FROM DOI_SGA 
    WHERE YYYYMM = @YYYYMM AND SEL_CODE = @SEL_CODE AND SITE = @SITE
    
    -- 2-1. 총원가 부서 (RND_YN='N') → COST_DIST_RATE 비율로 판관비
    INSERT INTO DOI_SGA (
        YYYYMM, SEL_CODE, SITE,
        FROM_DEPT_CODE, FROM_DEPT_NAME,
        FROM_ACCT_CODE, FROM_ACCT_NAME,
        EXPEN_SEL, EXPEN_SEL_NAME,
        ACCT_AMT
    )
    SELECT 
        dc.YYYYMM,
        dc.SEL_CODE,
        dc.SITE,
        d.DEPT AS FROM_DEPT_CODE,
        dc.코스트센터 AS FROM_DEPT_NAME,
        dc.계정코드 AS FROM_ACCT_CODE,
        dc.계정과목 AS FROM_ACCT_NAME,
        a.EXPEN_SEL,
        a.EXPEN_SEL명 AS EXPEN_SEL_NAME,
        CAST(dc.차변금액 * ISNULL(d.COST_DIST_RATE, 100) / 100.0 AS BIGINT) AS ACCT_AMT
    FROM DOI_DEPT_COST dc
    INNER JOIN DOI_DEPT d 
        ON dc.YYYYMM = d.YYYYMM
        AND dc.코스트센터 = d.DEPT_NAME
    LEFT JOIN DOI_ACCT a
        ON dc.YYYYMM = a.YYYYMM
        AND dc.SEL_CODE = a.SEL_CODE
        AND dc.SITE = a.SITE
        AND dc.계정코드 = a.ACCT
    WHERE dc.YYYYMM = @YYYYMM
        AND dc.SEL_CODE = @SEL_CODE
        AND dc.SITE = @SITE
        AND (d.COST_DIST = N'총원가' OR d.COST_DIST LIKE N'총원가%')
        AND d.RND_YN = 'N'
        AND dc.차변금액 > 0
    
    SET @MSG = '2. 판매관리비(DOI_SGA): ' + CAST(@@ROWCOUNT AS VARCHAR) + '건 입력'
    PRINT @MSG
    
    
    -- 3. DOI_RND (연구개발비) 삭제 및 입력
    DELETE FROM DOI_RND 
    WHERE YYYYMM = @YYYYMM AND SEL_CODE = @SEL_CODE AND SITE = @SITE
    
    INSERT INTO DOI_RND (
        YYYYMM, SEL_CODE, SITE,
        FROM_DEPT_CODE, FROM_DEPT_NAME,
        FROM_ACCT_CODE, FROM_ACCT_NAME,
        EXPEN_SEL, EXPEN_SEL_NAME,
        ACCT_AMT,
        COST_TYPE
    )
    SELECT 
        dc.YYYYMM,
        dc.SEL_CODE,
        dc.SITE,
        d.DEPT AS FROM_DEPT_CODE,
        dc.코스트센터 AS FROM_DEPT_NAME,
        dc.계정코드 AS FROM_ACCT_CODE,
        dc.계정과목 AS FROM_ACCT_NAME,
        a.EXPEN_SEL,
        a.EXPEN_SEL명 AS EXPEN_SEL_NAME,
        dc.차변금액 AS ACCT_AMT,
        CASE 
            WHEN a.EXPEN_SEL = N'인건비' THEN N'판관비'
            ELSE N'제조비용'
        END AS COST_TYPE
    FROM DOI_DEPT_COST dc
    INNER JOIN DOI_DEPT d 
        ON dc.YYYYMM = d.YYYYMM
        AND dc.코스트센터 = d.DEPT_NAME
    LEFT JOIN DOI_ACCT a
        ON dc.YYYYMM = a.YYYYMM
        AND dc.SEL_CODE = a.SEL_CODE
        AND dc.SITE = a.SITE
        AND dc.계정코드 = a.ACCT
    WHERE dc.YYYYMM = @YYYYMM
        AND dc.SEL_CODE = @SEL_CODE
        AND dc.SITE = @SITE
        AND d.RND_YN = 'Y'
        AND dc.차변금액 > 0
    
    SET @MSG = '3. 연구개발비(DOI_RND): ' + CAST(@@ROWCOUNT AS VARCHAR) + '건 입력'
    PRINT @MSG
    
    
    -- 4. DOI_CASET (카세트팀 비용) 삭제 및 입력
    DELETE FROM DOI_CASET 
    WHERE YYYYMM = @YYYYMM AND SEL_CODE = @SEL_CODE
    
    -- 4-1. UTG 비율 적용 (SITE='HQ')
    INSERT INTO DOI_CASET (
        YYYYMM, SEL_CODE, SITE,
        FROM_DEPT_CODE, FROM_DEPT_NAME,
        FROM_ACCT_CODE, FROM_ACCT_NAME,
        EXPEN_SEL, EXPEN_SEL_NAME,
        ACCT_AMT
    )
    SELECT 
        dc.YYYYMM,
        dc.SEL_CODE,
        'HQ' AS SITE,
        d.DEPT AS FROM_DEPT_CODE,
        dc.코스트센터 AS FROM_DEPT_NAME,
        dc.계정코드 AS FROM_ACCT_CODE,
        dc.계정과목 AS FROM_ACCT_NAME,
        a.EXPEN_SEL,
        a.EXPEN_SEL명 AS EXPEN_SEL_NAME,
        CAST(dc.차변금액 * ISNULL(r.UTG, 1.0) AS BIGINT) AS ACCT_AMT
    FROM DOI_DEPT_COST dc
    INNER JOIN DOI_DEPT d 
        ON dc.YYYYMM = d.YYYYMM
        AND dc.코스트센터 = d.DEPT_NAME
    LEFT JOIN DOI_ACCT a
        ON dc.YYYYMM = a.YYYYMM
        AND dc.SEL_CODE = a.SEL_CODE
        AND dc.SITE = a.SITE
        AND dc.계정코드 = a.ACCT
    LEFT JOIN DOI_CST_RATE r 
        ON dc.YYYYMM = r.YYYYMM
    WHERE dc.YYYYMM = @YYYYMM
        AND dc.SEL_CODE = @SEL_CODE
        AND d.DEPT IN ('400','448')
        AND dc.차변금액 > 0
    
    -- 4-2. VINA_CST 비율 적용 (SITE='VN')
    INSERT INTO DOI_CASET (
        YYYYMM, SEL_CODE, SITE,
        FROM_DEPT_CODE, FROM_DEPT_NAME,
        FROM_ACCT_CODE, FROM_ACCT_NAME,
        EXPEN_SEL, EXPEN_SEL_NAME,
        ACCT_AMT
    )
    SELECT 
        dc.YYYYMM,
        dc.SEL_CODE,
        'VN' AS SITE,
        d.DEPT AS FROM_DEPT_CODE,
        dc.코스트센터 AS FROM_DEPT_NAME,
        dc.계정코드 AS FROM_ACCT_CODE,
        dc.계정과목 AS FROM_ACCT_NAME,
        a.EXPEN_SEL,
        a.EXPEN_SEL명 AS EXPEN_SEL_NAME,
        CAST(dc.차변금액 * ISNULL(r.VINA_CST, 1.0) AS BIGINT) AS ACCT_AMT
    FROM DOI_DEPT_COST dc
    INNER JOIN DOI_DEPT d 
        ON dc.YYYYMM = d.YYYYMM
        AND dc.코스트센터 = d.DEPT_NAME
    LEFT JOIN DOI_ACCT a
        ON dc.YYYYMM = a.YYYYMM
        AND dc.SEL_CODE = a.SEL_CODE
        AND dc.SITE = a.SITE
        AND dc.계정코드 = a.ACCT
    LEFT JOIN DOI_CST_RATE r 
        ON dc.YYYYMM = r.YYYYMM
    WHERE dc.YYYYMM = @YYYYMM
        AND dc.SEL_CODE = @SEL_CODE
        AND d.DEPT IN ('400','448')
        AND dc.차변금액 > 0
    
    SET @MSG = '4. 카세트팀(DOI_CASET): ' + CAST(@@ROWCOUNT AS VARCHAR) + '건 입력 (HQ+VN)'
    PRINT @MSG
    
    PRINT ''
    PRINT '========================================================================'
PRINT '배부 검증'
    PRINT '========================================================================'
    
    -- 배부 금액 합계
    DECLARE @MFG_AMT BIGINT, @SGA_AMT BIGINT, @RND_AMT BIGINT, @CASET_AMT BIGINT
    DECLARE @CASET_원본 BIGINT
    
    SELECT @MFG_AMT = ISNULL(SUM(ACCT_AMT), 0) FROM DOI_MFG_EXP WHERE YYYYMM = @YYYYMM
    SELECT @SGA_AMT = ISNULL(SUM(ACCT_AMT), 0) FROM DOI_SGA WHERE YYYYMM = @YYYYMM
    SELECT @RND_AMT = ISNULL(SUM(ACCT_AMT), 0) FROM DOI_RND WHERE YYYYMM = @YYYYMM
    
    -- 카세트팀: HQ+VN 합계와 원본 금액
    SELECT @CASET_AMT = ISNULL(SUM(ACCT_AMT), 0) FROM DOI_CASET WHERE YYYYMM = @YYYYMM
    SELECT @CASET_원본 = ISNULL(SUM(dc.차변금액), 0)
    FROM DOI_DEPT_COST dc
    INNER JOIN DOI_DEPT d ON dc.YYYYMM = d.YYYYMM AND dc.코스트센터 = d.DEPT_NAME
    WHERE dc.YYYYMM = @YYYYMM AND dc.SEL_CODE = @SEL_CODE AND dc.SITE = @SITE
        AND d.DEPT IN ('400','448')
    
    SET @배부금액 = @MFG_AMT + @SGA_AMT + @RND_AMT + @CASET_AMT
    SET @차이 = @원본금액 - @배부금액
    
    PRINT '원본 금액: ' + CAST(@원본금액 AS VARCHAR(20)) + '원'
    PRINT '배부 금액: ' + CAST(@배부금액 AS VARCHAR(20)) + '원'
    PRINT '차이:      ' + CAST(@차이 AS VARCHAR(20)) + '원'
    PRINT ''
    
    PRINT '상세 내역:'
    PRINT '  - 제조경비:   ' + CAST(@MFG_AMT AS VARCHAR(20)) + '원'
    PRINT '  - 판매관리비: ' + CAST(@SGA_AMT AS VARCHAR(20)) + '원'
    PRINT '  - 연구개발비: ' + CAST(@RND_AMT AS VARCHAR(20)) + '원'
    PRINT '  - 카세트팀:   ' + CAST(@CASET_AMT AS VARCHAR(20)) + '원 (원본: ' + CAST(@CASET_원본 AS VARCHAR(20)) + '원)'
    PRINT ''
    
    IF ABS(@차이) < 100
    BEGIN
        PRINT '✓ 검증 성공: 차이가 100원 미만입니다.'
    END
    ELSE
    BEGIN
        PRINT '✗ 검증 실패: ' + CAST(@차이 AS VARCHAR(20)) + '원 차이 발생'
    END
    
    PRINT '========================================================================'
    
END

