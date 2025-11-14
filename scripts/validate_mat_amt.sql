-- ========================================
-- 재료비집계(UP_DOI_MAT_AMT) 검증 쿼리
-- ========================================

DECLARE @YYYYMM VARCHAR(10) = '202510';
DECLARE @SITE VARCHAR(2) = 'HQ';
DECLARE @SELCODE VARCHAR(10) = 'ACTUAL';

DECLARE @SOURCE_AMT BIGINT = 0,
        @SOURCE_QTY DECIMAL(18,2) = 0,
        @SOURCE_CNT INT = 0,
        @TARGET_AMT BIGINT = 0,
        @TARGET_QTY DECIMAL(18,2) = 0,
        @TARGET_CNT INT = 0,
        @DIFF_AMT BIGINT = 0,
        @DIFF_QTY DECIMAL(18,2) = 0;

-- 소스 데이터 (DOI_MATERIAL_RESC)
SELECT @SOURCE_AMT = ISNULL(CAST(SUM(in_amt) AS BIGINT), 0),
       @SOURCE_QTY = ISNULL(SUM(in_qty), 0),
       @SOURCE_CNT = COUNT(*)
FROM DOI_MATERIAL_RESC
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE;

-- 타겟 데이터 (DOI_MAT_AMT)
SELECT @TARGET_AMT = ISNULL(CAST(SUM(in_amt) AS BIGINT), 0),
       @TARGET_QTY = ISNULL(SUM(in_qty), 0),
       @TARGET_CNT = COUNT(*)
FROM DOI_MAT_AMT
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE;

SET @DIFF_AMT = @SOURCE_AMT - @TARGET_AMT;
SET @DIFF_QTY = @SOURCE_QTY - @TARGET_QTY;

-- ========================================
-- 1. 소스 vs 타겟 금액/수량 검증
-- ========================================
PRINT '====================================================================================================';
PRINT '1. 소스 데이터와 타겟 데이터 금액/수량 검증';
PRINT '====================================================================================================';
PRINT '          구분                              건수          수량                금액';
PRINT '----------------------------------------------------------------------------------------------------';
PRINT '          소스(DOI_MATERIAL_RESC)           ' 
    + RIGHT(SPACE(10) + CAST(@SOURCE_CNT AS VARCHAR(10)), 10) + SPACE(4) 
    + RIGHT(SPACE(18) + FORMAT(@SOURCE_QTY, 'N2'), 18) 
    + RIGHT(SPACE(20) + FORMAT(@SOURCE_AMT, 'N0'), 20) + '원';
PRINT '          타겟(DOI_MAT_AMT)                 ' 
    + RIGHT(SPACE(10) + CAST(@TARGET_CNT AS VARCHAR(10)), 10) + SPACE(4) 
    + RIGHT(SPACE(18) + FORMAT(@TARGET_QTY, 'N2'), 18) 
    + RIGHT(SPACE(20) + FORMAT(@TARGET_AMT, 'N0'), 20) + '원';
PRINT '----------------------------------------------------------------------------------------------------';
PRINT '          차이                                                ' 
    + RIGHT(SPACE(18) + FORMAT(@DIFF_QTY, 'N2'), 18) 
    + RIGHT(SPACE(20) + FORMAT(@DIFF_AMT, 'N0'), 20) + '원';
PRINT '====================================================================================================';
PRINT '';

-- ========================================
-- 2. 자재대분류별 상세 집계
-- ========================================
PRINT '====================================================================================================';
PRINT '3. 자재대분류별 상세 집계';
PRINT '====================================================================================================';
PRINT '     자재대분류                              소스집계          타겟집계          차이금액';
PRINT '----------------------------------------------------------------------------------------------------';

-- 자재대분류별 집계
SELECT 
    SPACE(5) + LEFT(ISNULL(자재대분류, '미분류') + SPACE(40), 40)
    + RIGHT(SPACE(18) + FORMAT(소스집계, 'N0'), 18)
    + RIGHT(SPACE(18) + FORMAT(타겟집계, 'N0'), 18)
    + RIGHT(SPACE(18) + FORMAT(소스집계 - 타겟집계, 'N0'), 18) as 집계결과
FROM (
    -- 각 자재대분류별로 소스와 타겟 금액을 별도로 계산
    SELECT 
        ISNULL(b.자재대분류, '미분류') as 자재대분류,
        -- 소스: DOI_MATERIAL_RESC에서 해당 자재대분류의 자재들 합계
        (SELECT ISNULL(CAST(SUM(a.in_amt) AS BIGINT), 0)
         FROM DOI_MATERIAL_RESC a
         INNER JOIN (SELECT DISTINCT mat_code, 자재대분류 FROM DOI_MAT_AMT WHERE YYYYMM = @YYYYMM AND SITE = @SITE) m
            ON a.mat_code = m.mat_code
         WHERE a.yyyymm = @YYYYMM AND a.site = @SITE AND a.sel_code = @SELCODE
           AND ISNULL(m.자재대분류, '미분류') = ISNULL(b.자재대분류, '미분류')
        ) as 소스집계,
        -- 타겟: DOI_MAT_AMT 합계
        ISNULL(CAST(SUM(b.in_amt) AS BIGINT), 0) as 타겟집계
    FROM DOI_MAT_AMT b
    WHERE b.yyyymm = @YYYYMM 
        AND b.site = @SITE 
        AND b.sel_code = @SELCODE
    GROUP BY ISNULL(b.자재대분류, '미분류')
) x
ORDER BY 자재대분류;

PRINT '====================================================================================================';
