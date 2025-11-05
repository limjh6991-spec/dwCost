-- =====================================================
-- 현재 데이터 정합성 진단 리포트
-- dwisCOST 원가 시스템 셋업용
-- 작성일: 2025-11-04
-- 용도: 기존 수작업 → 자동화 전환 시 데이터 현황 파악
-- 실행 시기: 시스템 셋업 시 (초기 1회) 및 월마감 시
-- =====================================================

-- 실행 방법:
-- 1. 진단 대상 기간 설정 (최근 3~6개월 권장)
-- 2. SQL Server Management Studio에서 실행
-- 3. Results to Grid 모드로 각 섹션별 결과 확인
-- 4. Excel로 Export하여 분석
-- 5. 월마감 시: 익월 1일~3일 사이 실행

DECLARE @START_YYYYMM CHAR(6) = '202508';  -- 시작 월 (예: 2025년 8월)
DECLARE @END_YYYYMM CHAR(6) = '202510';    -- 종료 월 (예: 2025년 10월)
DECLARE @SITE VARCHAR(10) = 'HQ';          -- 'HQ', 'VN', 'ALL'

PRINT '=====================================================';
PRINT '데이터 정합성 진단 리포트';
PRINT '진단 기간: ' + @START_YYYYMM + ' ~ ' + @END_YYYYMM;
PRINT '사업장: ' + @SITE;
PRINT '생성일시: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '=====================================================';
PRINT '';

-- =====================================================
-- PART 1: 생산수불 정합성 진단
-- =====================================================
PRINT '============== PART 1: 생산수불 정합성 ==============';
PRINT '';

-- 1-1. 생산수불 기본 수식 검증 (EOH = BOH + IN + BONUS - OUT - LOSS - NG)
PRINT '1-1. 생산수불 수식 검증 (불일치 건수)';
PRINT '-------------------------------------------------------';

SELECT 
    'PS001' AS RULE_CODE,
    '생산수불 수식 불일치' AS ISSUE_TYPE,
    YYYYMM,
    DW_SITE AS SITE,
    구분 AS PROD_GUBUN,
    도우모델 AS MODEL,
    MODEL_N_TYPE,
    
    -- 실제값
    BOH_MONTH,
    IN_MONTH,
    BONUS_MONTH,
    OUT_MONTH,
    LOSS_MONTH,
    NG_MONTH,
    EOH_MONTH,
    
    -- 계산값
    (BOH_MONTH + IN_MONTH + BONUS_MONTH - OUT_MONTH - LOSS_MONTH - NG_MONTH) AS CALC_EOH,
    
    -- 차이
    (EOH_MONTH - (BOH_MONTH + IN_MONTH + BONUS_MONTH - OUT_MONTH - LOSS_MONTH - NG_MONTH)) AS DIFF,
    
    CASE 
        WHEN ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + BONUS_MONTH - OUT_MONTH - LOSS_MONTH - NG_MONTH)) > 0.01 
        THEN 'ERROR'
        ELSE 'OK'
    END AS SEVERITY

FROM DOI_PROD_SUBUL
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    AND ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + BONUS_MONTH - OUT_MONTH - LOSS_MONTH - NG_MONTH)) > 0.01
ORDER BY YYYYMM, DW_SITE, 도우모델, DIFF DESC;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 1-2. 생산수불 BOH/EOH 월간 연결성 검증 (전월 EOH = 당월 BOH)
PRINT '1-2. 생산수불 월간 연결성 검증 (전월EOH ≠ 당월BOH)';
PRINT '-------------------------------------------------------';

WITH MonthlyData AS (
    SELECT 
        YYYYMM,
        DW_SITE,
        구분,
        도우모델,
        MODEL_N_TYPE,
        BOH_MONTH,
        EOH_MONTH,
        LAG(EOH_MONTH) OVER (
            PARTITION BY DW_SITE, 구분, 도우모델, MODEL_N_TYPE 
            ORDER BY YYYYMM
        ) AS PREV_EOH
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
)
SELECT 
    'PS003' AS RULE_CODE,
    '월간 연결성 오류' AS ISSUE_TYPE,
    YYYYMM,
    DW_SITE AS SITE,
    구분 AS PROD_GUBUN,
    도우모델 AS MODEL,
    MODEL_N_TYPE,
    PREV_EOH AS PREV_MONTH_EOH,
    BOH_MONTH AS CURR_MONTH_BOH,
    (BOH_MONTH - PREV_EOH) AS DIFF,
    CASE 
        WHEN ABS(BOH_MONTH - PREV_EOH) > 0.01 THEN 'ERROR'
        ELSE 'OK'
    END AS SEVERITY
FROM MonthlyData
WHERE PREV_EOH IS NOT NULL
    AND ABS(BOH_MONTH - PREV_EOH) > 0.01
ORDER BY YYYYMM, DW_SITE, 도우모델, DIFF DESC;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 1-3. 생산수불 음수 재고 검증
PRINT '1-3. 생산수불 음수 재고 검증';
PRINT '-------------------------------------------------------';

SELECT 
    'PS005' AS RULE_CODE,
    '음수 재고 발생' AS ISSUE_TYPE,
    YYYYMM,
    DW_SITE AS SITE,
    구분 AS PROD_GUBUN,
    도우모델 AS MODEL,
    MODEL_N_TYPE,
    BOH_MONTH,
    EOH_MONTH,
    CASE 
        WHEN BOH_MONTH < 0 AND EOH_MONTH < 0 THEN 'BOH & EOH 모두 음수'
        WHEN BOH_MONTH < 0 THEN 'BOH 음수'
        WHEN EOH_MONTH < 0 THEN 'EOH 음수'
    END AS ISSUE_DETAIL,
    'ERROR' AS SEVERITY
FROM DOI_PROD_SUBUL
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    AND (BOH_MONTH < 0 OR EOH_MONTH < 0)
ORDER BY YYYYMM, DW_SITE, 도우모델;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 1-4. 생산수불 합계 vs LOT/RUN 합계 비교
PRINT '1-4. 생산수불 합계 vs LOT/RUN 상세 비교';
PRINT '-------------------------------------------------------';

WITH SubulSummary AS (
    SELECT 
        YYYYMM,
        DW_SITE,
        구분,
        도우모델,
        MODEL_N_TYPE,
        SUM(BOH_MONTH) AS SUBUL_BOH,
        SUM(IN_MONTH) AS SUBUL_IN,
        SUM(OUT_MONTH) AS SUBUL_OUT,
        SUM(EOH_MONTH) AS SUBUL_EOH
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    GROUP BY YYYYMM, DW_SITE, 구분, 도우모델, MODEL_N_TYPE
),
LotRunSummary AS (
    SELECT 
        YYYYMM,
        DW_SITE,
        구분,
        MODEL,
        MODEL_N_TYPE,
        SUM(BOH_MONTH) AS LOTRUN_BOH,
        SUM(IN_MONTH) AS LOTRUN_IN,
        SUM(OUT_MONTH) AS LOTRUN_OUT,
        SUM(EOH_MONTH) AS LOTRUN_EOH
    FROM DOI_PROD_LOTRUN
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    GROUP BY YYYYMM, DW_SITE, 구분, MODEL, MODEL_N_TYPE
)
SELECT 
    'PS002' AS RULE_CODE,
    'SUBUL vs LOTRUN 불일치' AS ISSUE_TYPE,
    s.YYYYMM,
    s.DW_SITE AS SITE,
    s.구분 AS PROD_GUBUN,
    s.도우모델 AS MODEL,
    s.MODEL_N_TYPE,
    
    -- BOH 비교
    s.SUBUL_BOH,
    ISNULL(l.LOTRUN_BOH, 0) AS LOTRUN_BOH,
    (s.SUBUL_BOH - ISNULL(l.LOTRUN_BOH, 0)) AS BOH_DIFF,
    
    -- IN 비교
    s.SUBUL_IN,
    ISNULL(l.LOTRUN_IN, 0) AS LOTRUN_IN,
    (s.SUBUL_IN - ISNULL(l.LOTRUN_IN, 0)) AS IN_DIFF,
    
    -- OUT 비교
    s.SUBUL_OUT,
    ISNULL(l.LOTRUN_OUT, 0) AS LOTRUN_OUT,
    (s.SUBUL_OUT - ISNULL(l.LOTRUN_OUT, 0)) AS OUT_DIFF,
    
    -- EOH 비교
    s.SUBUL_EOH,
    ISNULL(l.LOTRUN_EOH, 0) AS LOTRUN_EOH,
    (s.SUBUL_EOH - ISNULL(l.LOTRUN_EOH, 0)) AS EOH_DIFF,
    
    CASE 
        WHEN ABS(s.SUBUL_EOH - ISNULL(l.LOTRUN_EOH, 0)) > 0.01 THEN 'ERROR'
        ELSE 'WARNING'
    END AS SEVERITY

FROM SubulSummary s
LEFT JOIN LotRunSummary l 
    ON s.YYYYMM = l.YYYYMM
    AND s.DW_SITE = l.DW_SITE
    AND s.구분 = l.구분
    AND s.도우모델 = l.MODEL
    AND s.MODEL_N_TYPE = l.MODEL_N_TYPE
WHERE (
    ABS(s.SUBUL_BOH - ISNULL(l.LOTRUN_BOH, 0)) > 0.01
    OR ABS(s.SUBUL_IN - ISNULL(l.LOTRUN_IN, 0)) > 0.01
    OR ABS(s.SUBUL_OUT - ISNULL(l.LOTRUN_OUT, 0)) > 0.01
    OR ABS(s.SUBUL_EOH - ISNULL(l.LOTRUN_EOH, 0)) > 0.01
)
ORDER BY s.YYYYMM, s.DW_SITE, s.도우모델;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- =====================================================
-- PART 2: 재고수불 정합성 진단
-- =====================================================
PRINT '============== PART 2: 재고수불 정합성 ==============';
PRINT '';

-- 2-1. 재고 기본 수식 검증 (EOH = BOH + INPUT - OUT)
PRINT '2-1. 재고 수식 검증 (불일치 건수)';
PRINT '-------------------------------------------------------';

SELECT 
    'ST001' AS RULE_CODE,
    '재고 수식 불일치' AS ISSUE_TYPE,
    YYYYMM,
    SITE,
    MODEL,
    STOCK,
    
    -- 실제값
    BOH,
    [INPUT],
    [OUT],
    EOH,
    
    -- 계산값
    (BOH + [INPUT] - [OUT]) AS CALC_EOH,
    
    -- 차이
    (EOH - (BOH + [INPUT] - [OUT])) AS DIFF,
    
    CASE 
        WHEN ABS(EOH - (BOH + [INPUT] - [OUT])) > 0.01 THEN 'ERROR'
        ELSE 'OK'
    END AS SEVERITY

FROM DOI_STOCK
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR SITE = @SITE)
    AND ABS(EOH - (BOH + [INPUT] - [OUT])) > 0.01
ORDER BY YYYYMM, SITE, MODEL, STOCK, DIFF DESC;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 2-2. 재고 BOH/EOH 월간 연결성 검증
PRINT '2-2. 재고 월간 연결성 검증 (전월EOH ≠ 당월BOH)';
PRINT '-------------------------------------------------------';

WITH StockMonthly AS (
    SELECT 
        YYYYMM,
        SITE,
        MODEL,
        STOCK,
        BOH,
        EOH,
        LAG(EOH) OVER (
            PARTITION BY SITE, MODEL, STOCK 
            ORDER BY YYYYMM
        ) AS PREV_EOH
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
)
SELECT 
    'ST003' AS RULE_CODE,
    '재고 월간 연결성 오류' AS ISSUE_TYPE,
    YYYYMM,
    SITE,
    MODEL,
    STOCK,
    PREV_EOH AS PREV_MONTH_EOH,
    BOH AS CURR_MONTH_BOH,
    (BOH - PREV_EOH) AS DIFF,
    CASE 
        WHEN ABS(BOH - PREV_EOH) > 0.01 THEN 'ERROR'
        ELSE 'OK'
    END AS SEVERITY
FROM StockMonthly
WHERE PREV_EOH IS NOT NULL
    AND ABS(BOH - PREV_EOH) > 0.01
ORDER BY YYYYMM, SITE, MODEL, STOCK, DIFF DESC;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 2-3. 생산수불 OUT vs 재고 INPUT_PROD 비교 (핵심!)
PRINT '2-3. 생산 OUT → 재고 IN 연결성 검증 (불일치 건수)';
PRINT '-------------------------------------------------------';

WITH ProdOut AS (
    SELECT 
        YYYYMM,
        DW_SITE AS SITE,
        도우모델 AS MODEL,
        SUM(OUT_MONTH) AS PROD_OUT_QTY
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
        AND 구분 IN ('제품', '반제품')  -- 재고로 이동 가능한 구분만
    GROUP BY YYYYMM, DW_SITE, 도우모델
),
StockIn AS (
    SELECT 
        YYYYMM,
        SITE,
        MODEL,
        SUM(INPUT_PROD) AS STOCK_IN_QTY
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
    GROUP BY YYYYMM, SITE, MODEL
)
SELECT 
    'ST002' AS RULE_CODE,
    '생산OUT → 재고IN 불일치' AS ISSUE_TYPE,
    COALESCE(p.YYYYMM, s.YYYYMM) AS YYYYMM,
    COALESCE(p.SITE, s.SITE) AS SITE,
    COALESCE(p.MODEL, s.MODEL) AS MODEL,
    
    ISNULL(p.PROD_OUT_QTY, 0) AS PROD_OUT_QTY,
    ISNULL(s.STOCK_IN_QTY, 0) AS STOCK_IN_QTY,
    
    (ISNULL(p.PROD_OUT_QTY, 0) - ISNULL(s.STOCK_IN_QTY, 0)) AS DIFF,
    
    CASE 
        WHEN p.PROD_OUT_QTY IS NULL THEN '생산수불 없음'
        WHEN s.STOCK_IN_QTY IS NULL THEN '재고입고 없음'
        WHEN ABS(ISNULL(p.PROD_OUT_QTY, 0) - ISNULL(s.STOCK_IN_QTY, 0)) > 0.01 THEN '수량 불일치'
    END AS ISSUE_DETAIL,
    
    CASE 
        WHEN ABS(ISNULL(p.PROD_OUT_QTY, 0) - ISNULL(s.STOCK_IN_QTY, 0)) > 0.01 THEN 'ERROR'
        ELSE 'OK'
    END AS SEVERITY

FROM ProdOut p
FULL OUTER JOIN StockIn s 
    ON p.YYYYMM = s.YYYYMM
    AND p.SITE = s.SITE
    AND p.MODEL = s.MODEL
WHERE ABS(ISNULL(p.PROD_OUT_QTY, 0) - ISNULL(s.STOCK_IN_QTY, 0)) > 0.01
ORDER BY YYYYMM, SITE, MODEL;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 2-4. 재고 수량 vs 금액 일치성 검증
PRINT '2-4. 재고 수량 vs 금액 일치성 검증';
PRINT '-------------------------------------------------------';

WITH StockQty AS (
    SELECT 
        YYYYMM,
        SITE,
        MODEL,
        SUM(BOH) AS QTY_BOH,
        SUM([INPUT]) AS QTY_INPUT,
        SUM([OUT]) AS QTY_OUT,
        SUM(EOH) AS QTY_EOH
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
    GROUP BY YYYYMM, SITE, MODEL
),
StockAmt AS (
    SELECT 
        YYYYMM,
        SITE,
        MODEL,
        SUM(BOH) AS AMT_BOH_QTY,
        SUM(INPUT) AS AMT_INPUT_QTY,
        SUM([OUT]) AS AMT_OUT_QTY,
        SUM(EOH) AS AMT_EOH_QTY
    FROM DOI_STOCK_COST
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
    GROUP BY YYYYMM, SITE, MODEL
)
SELECT 
    'ST004' AS RULE_CODE,
    '재고 수량/금액 불일치' AS ISSUE_TYPE,
    q.YYYYMM,
    q.SITE,
    q.MODEL,
    
    -- 수량 테이블 (DOI_STOCK)
    q.QTY_BOH,
    q.QTY_INPUT,
    q.QTY_OUT,
    q.QTY_EOH,
    
    -- 금액 테이블 (DOI_STOCK_COST)
    ISNULL(a.AMT_BOH_QTY, 0) AS AMT_BOH_QTY,
    ISNULL(a.AMT_INPUT_QTY, 0) AS AMT_INPUT_QTY,
    ISNULL(a.AMT_OUT_QTY, 0) AS AMT_OUT_QTY,
    ISNULL(a.AMT_EOH_QTY, 0) AS AMT_EOH_QTY,
    
    -- 차이
    (q.QTY_EOH - ISNULL(a.AMT_EOH_QTY, 0)) AS EOH_DIFF,
    
    'WARNING' AS SEVERITY

FROM StockQty q
LEFT JOIN StockAmt a 
    ON q.YYYYMM = a.YYYYMM
    AND q.SITE = a.SITE
    AND q.MODEL = a.MODEL
WHERE ABS(q.QTY_EOH - ISNULL(a.AMT_EOH_QTY, 0)) > 0.01
ORDER BY q.YYYYMM, q.SITE, q.MODEL;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 2-5. 재고 음수 검증
PRINT '2-5. 재고 음수 검증';
PRINT '-------------------------------------------------------';

SELECT 
    'ST005' AS RULE_CODE,
    '음수 재고 발생' AS ISSUE_TYPE,
    YYYYMM,
    SITE,
    MODEL,
    STOCK,
    BOH,
    EOH,
    CASE 
        WHEN BOH < 0 AND EOH < 0 THEN 'BOH & EOH 모두 음수'
        WHEN BOH < 0 THEN 'BOH 음수'
        WHEN EOH < 0 THEN 'EOH 음수'
    END AS ISSUE_DETAIL,
    'ERROR' AS SEVERITY
FROM DOI_STOCK
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR SITE = @SITE)
    AND (BOH < 0 OR EOH < 0)
ORDER BY YYYYMM, SITE, MODEL, STOCK;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- =====================================================
-- PART 3: 원천 데이터 누락 진단
-- =====================================================
PRINT '============== PART 3: 원천 데이터 누락 진단 ==============';
PRINT '';

-- 3-1. FRONT 생산실적 → 생산수불 누락 체크
PRINT '3-1. FRONT 생산실적 → 생산수불 반영 누락';
PRINT '-------------------------------------------------------';

SELECT 
    'PS004' AS RULE_CODE,
    'FRONT 실적 미반영' AS ISSUE_TYPE,
    LEFT(f.작업일시, 6) AS YYYYMM,
    f.LOT_NO,
    f.PANEL_ID,
    f.MODEL,
    SUM(f.양품수량) AS FRONT_GOOD_QTY,
    SUM(f.불량수량) AS FRONT_NG_QTY,
    '생산수불 미생성' AS ISSUE_DETAIL,
    'WARNING' AS SEVERITY
FROM DW_PROD_FRONT f
WHERE LEFT(f.작업일시, 6) BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND NOT EXISTS (
        SELECT 1 
        FROM DOI_PROD_LOTRUN l
        WHERE l.LOTRUN_NO = f.LOT_NO
            AND l.YYYYMM = LEFT(f.작업일시, 6)
    )
GROUP BY LEFT(f.작업일시, 6), f.LOT_NO, f.PANEL_ID, f.MODEL
ORDER BY YYYYMM, LOT_NO;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 3-2. BACK 생산실적 → 생산수불 누락 체크
PRINT '3-2. BACK 생산실적 → 생산수불 반영 누락';
PRINT '-------------------------------------------------------';

SELECT 
    'PS004' AS RULE_CODE,
    'BACK 실적 미반영' AS ISSUE_TYPE,
    LEFT(b.작업일시, 6) AS YYYYMM,
    b.RUN_NO,
    b.MODEL,
    SUM(b.양품수량) AS BACK_GOOD_QTY,
    SUM(b.불량수량) AS BACK_NG_QTY,
    '생산수불 미생성' AS ISSUE_DETAIL,
    'WARNING' AS SEVERITY
FROM DW_PROD_BACK b
WHERE LEFT(b.작업일시, 6) BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND NOT EXISTS (
        SELECT 1 
        FROM DOI_PROD_LOTRUN l
        WHERE l.LOTRUN_NO = b.RUN_NO
            AND l.YYYYMM = LEFT(b.작업일시, 6)
    )
GROUP BY LEFT(b.작업일시, 6), b.RUN_NO, b.MODEL
ORDER BY YYYYMM, RUN_NO;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- =====================================================
-- PART 4: 종합 통계 (Executive Summary)
-- =====================================================
PRINT '============== PART 4: 종합 통계 ==============';
PRINT '';

-- 4-1. 월별 오류 건수 통계
PRINT '4-1. 월별 오류 건수 통계';
PRINT '-------------------------------------------------------';

WITH AllErrors AS (
    -- 생산수불 수식 오류
    SELECT YYYYMM, DW_SITE AS SITE, 'PS001' AS RULE_CODE, '생산수불 수식' AS CATEGORY
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
        AND ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + BONUS_MONTH - OUT_MONTH - LOSS_MONTH - NG_MONTH)) > 0.01
    
    UNION ALL
    
    -- 재고 수식 오류
    SELECT YYYYMM, SITE, 'ST001' AS RULE_CODE, '재고 수식' AS CATEGORY
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
        AND ABS(EOH - (BOH + [INPUT] - [OUT])) > 0.01
    
    UNION ALL
    
    -- 생산수불 음수
    SELECT YYYYMM, DW_SITE AS SITE, 'PS005' AS RULE_CODE, '음수 재고' AS CATEGORY
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
        AND (BOH_MONTH < 0 OR EOH_MONTH < 0)
    
    UNION ALL
    
    -- 재고 음수
    SELECT YYYYMM, SITE, 'ST005' AS RULE_CODE, '음수 재고' AS CATEGORY
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
        AND (BOH < 0 OR EOH < 0)
)
SELECT 
    YYYYMM,
    SITE,
    CATEGORY,
    COUNT(*) AS ERROR_COUNT
FROM AllErrors
GROUP BY YYYYMM, SITE, CATEGORY
ORDER BY YYYYMM, SITE, CATEGORY;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

-- 4-2. 규칙별 오류 건수
PRINT '4-2. 규칙별 오류 건수 (전체 기간)';
PRINT '-------------------------------------------------------';

WITH AllErrors AS (
    SELECT 'PS001' AS RULE_CODE, '생산수불 수식 오류' AS RULE_NAME, COUNT(*) AS ERROR_COUNT
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
        AND ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + BONUS_MONTH - OUT_MONTH - LOSS_MONTH - NG_MONTH)) > 0.01
    
    UNION ALL
    
    SELECT 'ST001' AS RULE_CODE, '재고 수식 오류' AS RULE_NAME, COUNT(*) AS ERROR_COUNT
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
        AND ABS(EOH - (BOH + [INPUT] - [OUT])) > 0.01
    
    UNION ALL
    
    SELECT 'PS005' AS RULE_CODE, '생산수불 음수 재고' AS RULE_NAME, COUNT(*) AS ERROR_COUNT
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR DW_SITE = @SITE)
        AND (BOH_MONTH < 0 OR EOH_MONTH < 0)
    
    UNION ALL
    
    SELECT 'ST005' AS RULE_CODE, '재고 음수' AS RULE_NAME, COUNT(*) AS ERROR_COUNT
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
        AND (@SITE = 'ALL' OR SITE = @SITE)
        AND (BOH < 0 OR EOH < 0)
)
SELECT 
    RULE_CODE,
    RULE_NAME,
    ERROR_COUNT,
    CASE 
        WHEN ERROR_COUNT = 0 THEN '✅ 정상'
        WHEN ERROR_COUNT < 10 THEN '⚠️ 경미한 오류'
        WHEN ERROR_COUNT < 50 THEN '🔶 주의 필요'
        ELSE '🔴 심각한 오류'
    END AS SEVERITY_LEVEL
FROM AllErrors
ORDER BY ERROR_COUNT DESC;

PRINT '';
PRINT '-------------------------------------------------------';
PRINT '';

PRINT '=====================================================';
PRINT '진단 완료';
PRINT '=====================================================';
PRINT '';
PRINT '다음 단계:';
PRINT '1. 각 섹션별 결과를 Excel로 Export';
PRINT '2. 오류 건수가 많은 규칙부터 우선 해결';
PRINT '3. 원천 데이터(DW_PROD_*) 정합성 먼저 확인';
PRINT '4. 생산수불 → 재고 → 원가 순서로 데이터 정리';
PRINT '';
PRINT '=====================================================';
