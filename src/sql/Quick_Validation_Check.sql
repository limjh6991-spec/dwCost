-- =====================================================
-- 빠른 데이터 정합성 진단 (5분 완성)
-- 용도: 시스템 셋업 시 현황 빠른 파악
-- 실행: SQL Server Management Studio 또는 Azure Data Studio
-- =====================================================

-- 📝 실행 전 파라미터 설정
DECLARE @START_YYYYMM CHAR(6) = '202508';  -- 시작 월 (예: 2025년 8월)
DECLARE @END_YYYYMM CHAR(6) = '202510';    -- 종료 월 (예: 2025년 10월)
DECLARE @SITE VARCHAR(10) = 'HQ';          -- 'HQ', 'VN', 'ALL'

PRINT '=====================================================';
PRINT '빠른 진단 리포트';
PRINT '진단 기간: ' + @START_YYYYMM + ' ~ ' + @END_YYYYMM;
PRINT '사업장: ' + @SITE;
PRINT '생성일시: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '=====================================================';
PRINT '';

-- =====================================================
-- 1. 생산수불 기본 통계
-- =====================================================
PRINT '📈 [1] 생산수불 기본 통계';
PRINT '-----------------------------------------------------';

SELECT 
    '1. 생산수불 통계' AS [구분],
    YYYYMM AS [년월],
    DW_SITE AS [사이트],
    COUNT(*) AS [총건수],
    SUM(CASE WHEN EOH_MONTH < 0 THEN 1 ELSE 0 END) AS [음수재고건수],
    SUM(CASE 
        WHEN ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) 
            - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0))) > 0.01 
        THEN 1 ELSE 0 
    END) AS [수식오류건수],
    CASE 
        WHEN SUM(CASE WHEN EOH_MONTH < 0 THEN 1 ELSE 0 END) = 0 
            AND SUM(CASE 
                WHEN ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) 
                    - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0))) > 0.01 
                THEN 1 ELSE 0 
            END) = 0 
        THEN '✅ 정상'
        ELSE '⚠️ 오류 있음'
    END AS [상태]
FROM DOI_PROD_SUBUL
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR DW_SITE = @SITE)
GROUP BY YYYYMM, DW_SITE
ORDER BY YYYYMM, DW_SITE;

PRINT '';

-- =====================================================
-- 2. 재고수불 기본 통계
-- =====================================================
PRINT '📈 [2] 재고수불 기본 통계';
PRINT '-----------------------------------------------------';

SELECT 
    '2. 재고수불 통계' AS [구분],
    YYYYMM AS [년월],
    SITE AS [사이트],
    COUNT(*) AS [총건수],
    SUM(CASE WHEN EOH < 0 THEN 1 ELSE 0 END) AS [음수재고건수],
    SUM(CASE 
        WHEN ABS(EOH - (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ)) > 0.01 
        THEN 1 ELSE 0 
    END) AS [수식오류건수],
    CASE 
        WHEN SUM(CASE WHEN EOH < 0 THEN 1 ELSE 0 END) = 0 
            AND SUM(CASE 
                WHEN ABS(EOH - (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ)) > 0.01 
                THEN 1 ELSE 0 
            END) = 0 
        THEN '✅ 정상'
        ELSE '⚠️ 오류 있음'
    END AS [상태]
FROM DOI_STOCK
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR SITE = @SITE)
GROUP BY YYYYMM, SITE
ORDER BY YYYYMM, SITE;

PRINT '';

-- =====================================================
-- 3. 생산→재고 연결 검증 (핵심)
-- =====================================================
PRINT '🔗 [3] 생산→재고 연결 검증 ⭐ 핵심';
PRINT '-----------------------------------------------------';

SELECT 
    '3. 생산→재고 연결' AS [구분],
    P.YYYYMM AS [년월],
    P.DW_SITE AS [사이트],
    COUNT(*) AS [총건수],
    SUM(CASE WHEN S.INPUT_PROD IS NULL THEN 1 ELSE 0 END) AS [재고누락건수],
    SUM(CASE 
        WHEN S.INPUT_PROD IS NOT NULL 
            AND ABS(P.OUT_MONTH - S.INPUT_PROD) > 0.01 
        THEN 1 ELSE 0 
    END) AS [수량불일치건수],
    CASE 
        WHEN SUM(CASE WHEN S.INPUT_PROD IS NULL THEN 1 ELSE 0 END) = 0 
            AND SUM(CASE 
                WHEN S.INPUT_PROD IS NOT NULL 
                    AND ABS(P.OUT_MONTH - S.INPUT_PROD) > 0.01 
                THEN 1 ELSE 0 
            END) = 0 
        THEN '✅ 정상'
        ELSE '⚠️ 오류 있음'
    END AS [상태]
FROM DOI_PROD_SUBUL P
LEFT JOIN DOI_STOCK S ON P.YYYYMM = S.YYYYMM 
    AND P.DW_SITE = S.SITE 
    AND P.도우모델 = S.MODEL
WHERE P.YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR P.DW_SITE = @SITE)
    AND P.구분 IN ('제품', '반제품')
GROUP BY P.YYYYMM, P.DW_SITE
ORDER BY P.YYYYMM, P.DW_SITE;

PRINT '';

-- =====================================================
-- 4. 음수 재고 상세 (상위 20건)
-- =====================================================
PRINT '🔴 [4] 음수 재고 상세 (상위 20건)';
PRINT '-----------------------------------------------------';

-- 4-1. 생산수불 음수 재고
SELECT TOP 20
    '생산수불' AS [테이블],
    YYYYMM AS [년월],
    DW_SITE AS [사이트],
    도우모델 AS [모델],
    구분 AS [구분],
    BOH_MONTH AS [기초],
    IN_MONTH AS [입고],
    OUT_MONTH AS [출고],
    EOH_MONTH AS [기말],
    '즉시 수정 필요' AS [조치사항]
FROM DOI_PROD_SUBUL
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    AND (BOH_MONTH < 0 OR EOH_MONTH < 0)
ORDER BY EOH_MONTH;

-- 4-2. 재고수불 음수 재고
SELECT TOP 20
    '재고수불' AS [테이블],
    YYYYMM AS [년월],
    SITE AS [사이트],
    MODEL AS [모델],
    ITEM_GUBUN AS [구분],
    BOH AS [기초],
    (INPUT_PROD + INPUT_PURCH) AS [입고],
    (OUT_INVOICE + OUT_ADJ) AS [출고],
    EOH AS [기말],
    '즉시 수정 필요' AS [조치사항]
FROM DOI_STOCK
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR SITE = @SITE)
    AND (BOH < 0 OR EOH < 0)
ORDER BY EOH;

PRINT '';

-- =====================================================
-- 5. 종합 요약
-- =====================================================
PRINT '=====================================================';
PRINT '📋 종합 요약';
PRINT '=====================================================';

DECLARE @생산음수재고 INT;
DECLARE @재고음수재고 INT;
DECLARE @생산수식오류 INT;
DECLARE @재고수식오류 INT;
DECLARE @생산재고불일치 INT;

SELECT @생산음수재고 = COUNT(*) 
FROM DOI_PROD_SUBUL 
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM 
    AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    AND (BOH_MONTH < 0 OR EOH_MONTH < 0);

SELECT @재고음수재고 = COUNT(*) 
FROM DOI_STOCK 
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM 
    AND (@SITE = 'ALL' OR SITE = @SITE)
    AND (BOH < 0 OR EOH < 0);

SELECT @생산수식오류 = COUNT(*) 
FROM DOI_PROD_SUBUL 
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM 
    AND (@SITE = 'ALL' OR DW_SITE = @SITE)
    AND ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) 
        - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0))) > 0.01;

SELECT @재고수식오류 = COUNT(*) 
FROM DOI_STOCK 
WHERE YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM 
    AND (@SITE = 'ALL' OR SITE = @SITE)
    AND ABS(EOH - (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ)) > 0.01;

SELECT @생산재고불일치 = COUNT(*) 
FROM DOI_PROD_SUBUL P
LEFT JOIN DOI_STOCK S ON P.YYYYMM = S.YYYYMM 
    AND P.DW_SITE = S.SITE 
    AND P.도우모델 = S.MODEL
WHERE P.YYYYMM BETWEEN @START_YYYYMM AND @END_YYYYMM
    AND (@SITE = 'ALL' OR P.DW_SITE = @SITE)
    AND P.구분 IN ('제품', '반제품')
    AND (S.INPUT_PROD IS NULL OR ABS(P.OUT_MONTH - S.INPUT_PROD) > 0.01);

PRINT '';
PRINT '검증 항목                    결과         상태';
PRINT '-----------------------------------------------------';
PRINT 'PS005 (생산 음수재고)        ' + CAST(@생산음수재고 AS VARCHAR) + '건        ' + 
    CASE WHEN @생산음수재고 = 0 THEN '✅ 정상' ELSE '🔴 긴급' END;
PRINT 'ST005 (재고 음수재고)        ' + CAST(@재고음수재고 AS VARCHAR) + '건        ' + 
    CASE WHEN @재고음수재고 = 0 THEN '✅ 정상' ELSE '🔴 긴급' END;
PRINT 'PS001 (생산수식 오류)        ' + CAST(@생산수식오류 AS VARCHAR) + '건        ' + 
    CASE WHEN @생산수식오류 = 0 THEN '✅ 정상' ELSE '⚠️ 주의' END;
PRINT 'ST001 (재고수식 오류)        ' + CAST(@재고수식오류 AS VARCHAR) + '건        ' + 
    CASE WHEN @재고수식오류 = 0 THEN '✅ 정상' ELSE '⚠️ 주의' END;
PRINT 'ST002 (생산→재고 연결)       ' + CAST(@생산재고불일치 AS VARCHAR) + '건        ' + 
    CASE WHEN @생산재고불일치 = 0 THEN '✅ 정상' ELSE '⚠️ 주의' END;
PRINT '';

DECLARE @총오류건수 INT = @생산음수재고 + @재고음수재고 + @생산수식오류 + @재고수식오류 + @생산재고불일치;

PRINT '총 오류 건수: ' + CAST(@총오류건수 AS VARCHAR) + '건';
PRINT '';

IF @총오류건수 = 0
BEGIN
    PRINT '✅ 모든 검증 통과! 데이터 정합성 양호';
    PRINT '';
    PRINT '📍 다음 단계:';
    PRINT '  → 검증 시스템 구축으로 바로 진행';
    PRINT '  → Week 5~7: 백엔드/프론트엔드 개발';
END
ELSE
BEGIN
    PRINT '⚠️  데이터 정리가 필요합니다.';
    PRINT '';
    PRINT '📍 다음 단계:';
    PRINT '  1. 위 결과를 Excel로 저장 (우클릭 → 결과를 다른 이름으로 저장)';
    PRINT '  2. 우선순위 결정:';
    PRINT '     - 1순위: 음수 재고 (' + CAST(@생산음수재고 + @재고음수재고 AS VARCHAR) + '건) → 물리 실사';
    PRINT '     - 2순위: 생산→재고 연결 (' + CAST(@생산재고불일치 AS VARCHAR) + '건) → 매핑 확인';
    PRINT '     - 3순위: 수식 오류 (' + CAST(@생산수식오류 + @재고수식오류 AS VARCHAR) + '건) → 재계산';
    PRINT '  3. 데이터 클렌징 (1~2주)';
    PRINT '  4. 재검증 → ERROR 0건 확인';
    PRINT '';
    PRINT '📄 참조: docs/빠른_시작_가이드.md';
END

PRINT '=====================================================';
PRINT '진단 완료';
PRINT '=====================================================';
