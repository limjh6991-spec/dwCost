-- ========================================
-- 재료비집계 쿼리 모음
-- ========================================

-- ========================================
-- 1. C0008005_Sch1: 자재별 투입실적 조회 (DOI_MATERIAL_RESC)
-- ========================================
-- 설명: 화면에서 "조회" 버튼 클릭 시 실행되는 쿼리
-- 소스: DOI_MATERIAL_RESC (원본 자재투입 데이터)
-- ========================================

DECLARE @yyyymm VARCHAR(6) = '202510';
DECLARE @site VARCHAR(2) = 'HQ';

WITH BOM AS (
    SELECT 
        자재번호,
        투입단위,
        자재대분류,
        ROW_NUMBER() OVER (PARTITION BY 자재번호 ORDER BY 자재명) AS rn
    FROM doi_bom_mast
    WHERE 1=1 
        AND YYYYMM = @yyyymm
        AND SITE = @site
)
SELECT
    CASE WHEN a.MAT_CLASS='원자재' THEN 'MDAX' ELSE 'MIAX' END AS expen_sel,
    CASE WHEN a.MAT_CLASS='원자재' THEN '직접재료비' ELSE '간접재료비' END AS expen_sel명,
    a.MAT_CODE,
    a.MAT_DESC,
    MAX(b.자재대분류) AS mat_lclass,
    MAX(b.투입단위) AS UNIT,
    SUM(a.IN_QTY) AS IN_QTY,
    AVG(a.UNIT_COST) AS UNIT_COST,
    SUM(a.IN_AMT) AS IN_AMT
FROM DOI_MATERIAL_RESC a
LEFT JOIN BOM b ON (a.mat_code = b.자재번호 AND b.rn=1)
WHERE 1=1
    AND a.sel_code = 'ACTUAL'
    AND a.YYYYMM = @yyyymm
    AND a.SITE = @site
GROUP BY	
    a.YYYYMM,
    a.SEL_CODE,
    a.SITE,
    a.MAT_CLASS,
    a.MAT_CODE,
    a.MAT_DESC
HAVING SUM(in_amt) > 0
ORDER BY 4, 1;

-- ========================================
-- 2. C0008005_Sch2: 자재 상세 조회 (mat_class 필터)
-- ========================================
-- 설명: 그리드에서 mat_class 클릭 시 상세 팝업
-- ========================================

DECLARE @matClass NVARCHAR(50) = '원자재'; -- 예시

SELECT
    YYYYMM,
    SEL_CODE,
    SITE,
    MAT_CODE,
    MAT_DESC,
    [SIZE],
    IN_QTY,
    UNIT_COST,
    IN_AMT,
    COST_GUBUN,
    MAT_CLASS,
    MODEL,
    MODEL_N_TYPE
FROM DOI_MATERIAL_RESC
WHERE 1=1
    AND sel_code = 'ACTUAL'
    AND YYYYMM = @yyyymm
    AND SITE = @site
    AND mat_class = @matClass
ORDER BY 1,2,3,4;

-- ========================================
-- 3. C0008005_Exec: 재료비집계 프로시저 실행
-- ========================================
-- 설명: 화면에서 "재료비집계 실행" 버튼 클릭 시 실행
-- 프로시저: UP_DOI_MAT_AMT
-- 결과: DOI_MAT_AMT 테이블에 집계 데이터 생성 + 검증 메시지 반환
-- ========================================

DECLARE @RET_CODE INT;
EXEC @RET_CODE = UP_DOI_MAT_AMT 
    @YYYYMM = @yyyymm,
    @SITE = @site,
    @SELCODE = 'ACTUAL';

-- ========================================
-- 4. DOI_MAT_AMT 테이블 직접 조회
-- ========================================
-- 설명: 프로시저 실행 후 결과 테이블 확인
-- ========================================

SELECT
    CASE WHEN mat_class='원자재' THEN 'MDAX' ELSE 'MIAX' END AS expen_sel,
    CASE WHEN mat_class='원자재' THEN '직접재료비' ELSE '간접재료비' END AS expen_sel명,
    mat_code,
    자재대분류 AS mat_lclass,
    in_qty,
    mat_unit_cost AS unit_cost,
    in_amt
FROM DOI_MAT_AMT
WHERE 1=1
    AND sel_code = 'ACTUAL'
    AND YYYYMM = @yyyymm
    AND SITE = @site
ORDER BY mat_class, mat_code;

-- ========================================
-- 5. 소스(DOI_MATERIAL_RESC) vs 타겟(DOI_MAT_AMT) 비교
-- ========================================

PRINT '========================================';
PRINT '소스 vs 타겟 비교';
PRINT '========================================';

-- 소스 집계
SELECT 
    'SOURCE' AS 구분,
    COUNT(*) AS 건수,
    SUM(in_qty) AS 수량,
    SUM(in_amt) AS 금액
FROM DOI_MATERIAL_RESC
WHERE yyyymm = @yyyymm 
    AND site = @site 
    AND sel_code = 'ACTUAL';

-- 타겟 집계
SELECT 
    'TARGET' AS 구분,
    COUNT(*) AS 건수,
    SUM(in_qty) AS 수량,
    SUM(in_amt) AS 금액
FROM DOI_MAT_AMT
WHERE yyyymm = @yyyymm 
    AND site = @site 
    AND sel_code = 'ACTUAL';

-- 자재대분류별 비교
SELECT 
    ISNULL(t.자재대분류, '미분류') AS 자재대분류,
    COUNT(DISTINCT s.mat_code) AS 소스자재수,
    COUNT(DISTINCT t.mat_code) AS 타겟자재수,
    ISNULL(SUM(s.in_amt), 0) AS 소스금액,
    ISNULL(SUM(t.in_amt), 0) AS 타겟금액,
    ISNULL(SUM(s.in_amt), 0) - ISNULL(SUM(t.in_amt), 0) AS 차이
FROM DOI_MAT_AMT t
LEFT JOIN DOI_MATERIAL_RESC s 
    ON t.yyyymm = s.yyyymm 
    AND t.site = s.site 
    AND t.mat_code = s.mat_code 
    AND t.sel_code = s.sel_code
WHERE t.yyyymm = @yyyymm 
    AND t.site = @site 
    AND t.sel_code = 'ACTUAL'
GROUP BY ISNULL(t.자재대분류, '미분류')
ORDER BY 타겟금액 DESC;
