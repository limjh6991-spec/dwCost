-- ========================================
-- 재료비배부(UP_DOI_MAT_COST) 중복 분석 쿼리
-- ========================================

DECLARE @YYYYMM VARCHAR(6) = '202510';
DECLARE @SITE VARCHAR(2) = 'HQ';

-- ========================================
-- 1. 전체 배부 결과 요약
-- ========================================
PRINT '========================================';
PRINT '1. 전체 배부 결과 요약';
PRINT '========================================';

SELECT 
    배부방식,
    COUNT(*) as 건수,
    COUNT(DISTINCT 자재번호) as 고유자재수,
    COUNT(DISTINCT 도우모델) as 고유모델수,
    SUM(배부금액) as 배부금액합계
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'
GROUP BY 배부방식;

-- ========================================
-- 2. 공통 배부 중복 확인
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '2. 공통 배부 - 모델별 중복 확인';
PRINT '========================================';

SELECT 
    도우모델,
    COUNT(*) as 건수,
    COUNT(DISTINCT 자재번호) as 자재수
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'
  AND 배부방식 = '공통'
GROUP BY 도우모델
ORDER BY 도우모델;

-- ========================================
-- 3. 특정 자재의 공통 배부 상세 (필름)
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '3. 특정 자재(DW00200700) 공통 배부 상세';
PRINT '========================================';

SELECT 
    도우모델,
    배부율,
    in_amt as 원재료비,
    배부금액
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'
  AND 자재번호 = 'DW00200700'
  AND 배부방식 = '공통'
ORDER BY 도우모델;

SELECT 
    '합계' as 구분,
    COUNT(*) as 건수,
    SUM(배부율) as 배부율합계,
    MAX(in_amt) as 원재료비,
    SUM(배부금액) as 배부금액합계
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'
  AND 자재번호 = 'DW00200700'
  AND 배부방식 = '공통';

-- ========================================
-- 4. 배부율 합계가 1.0이 아닌 자재 목록
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '4. 배부율 합계가 1.0이 아닌 자재';
PRINT '========================================';

SELECT 
    자재번호,
    COUNT(*) as 배부건수,
    SUM(배부율) as 배부율합계,
    MAX(in_amt) as 원재료비,
    SUM(배부금액) as 배부금액합계,
    배부방식
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'
GROUP BY 자재번호, 배부방식
HAVING ABS(SUM(배부율) - 1.0) > 0.0001
ORDER BY SUM(배부금액) DESC;

-- ========================================
-- 5. CHGQTY CTE 검증
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '5. CHGQTY CTE 검증';
PRINT '========================================';

WITH CHGQTY AS (
    select
        a.yyyymm,
        a.sel_code,
        a.DW_SITE,
        a.도우모델,
        sum(a.IN_MONTH) in_qty,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
)
SELECT 
    도우모델,
    환산량
FROM CHGQTY
ORDER BY 도우모델;

SELECT 
    '총계' as 구분,
    COUNT(*) as 모델수,
    SUM(환산량) as 환산량합계
FROM (
    select
        a.도우모델,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
) a;

-- ========================================
-- 6. MAT_COMM_RATE CTE 검증
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '6. MAT_COMM_RATE CTE 검증';
PRINT '========================================';

WITH CHGQTY AS (
    select
        a.yyyymm,
        a.sel_code,
        a.DW_SITE,
        a.도우모델,
        sum(a.IN_MONTH) in_qty,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
),
MAT_COMM_RATE AS (
    select 
        a.*,
        (환산량 * b.xy)/sum(환산량 * b.xy) over() as comm_rate,
        b.xy
    from CHGQTY A   
    inner join DOI_MODEL_MAST B ON (a.도우모델 = b.MODEL and b.YYYYMM = @YYYYMM and a.DW_SITE = b.SITE)
)
SELECT 
    도우모델,
    환산량,
    xy,
    comm_rate
FROM MAT_COMM_RATE
ORDER BY 도우모델;

-- 배부율 합계 확인
WITH CHGQTY AS (
    select
        a.yyyymm,
        a.sel_code,
        a.DW_SITE,
        a.도우모델,
        sum(a.IN_MONTH) in_qty,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
),
MAT_COMM_RATE AS (
    select 
        a.*,
        (환산량 * b.xy)/sum(환산량 * b.xy) over() as comm_rate,
        b.xy
    from CHGQTY A   
    inner join DOI_MODEL_MAST B ON (a.도우모델 = b.MODEL and b.YYYYMM = @YYYYMM and a.DW_SITE = b.SITE)
)
SELECT 
    '배부율 합계' as 구분,
    COUNT(*) as 모델수,
    SUM(comm_rate) as 배부율합계
FROM MAT_COMM_RATE;

-- ========================================
-- 7. CHGQTY와 DOI_MODEL_MAST 조인 확인
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '7. CHGQTY와 DOI_MODEL_MAST 조인 상세';
PRINT '========================================';

WITH CHGQTY AS (
    select
        a.yyyymm,
        a.sel_code,
        a.DW_SITE,
        a.도우모델,
        sum(a.IN_MONTH) in_qty,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
)
SELECT 
    a.도우모델,
    COUNT(*) as join_count,
    MAX(a.환산량) as 환산량,
    MAX(b.xy) as xy
FROM CHGQTY A   
INNER JOIN DOI_MODEL_MAST B ON (a.도우모델 = b.MODEL and b.YYYYMM = @YYYYMM and a.DW_SITE = b.SITE)
GROUP BY a.도우모델
ORDER BY a.도우모델;

-- ========================================
-- 8. DOI_MODEL_MAST에 없는 CHGQTY 모델
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '8. DOI_MODEL_MAST에 없는 CHGQTY 모델';
PRINT '========================================';

WITH CHGQTY AS (
    select
        a.yyyymm,
        a.sel_code,
        a.DW_SITE,
        a.도우모델,
        sum(a.IN_MONTH) in_qty,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
)
SELECT 
    c.도우모델,
    c.환산량
FROM CHGQTY c
LEFT JOIN DOI_MODEL_MAST m ON (c.도우모델 = m.MODEL and m.YYYYMM = @YYYYMM and c.DW_SITE = m.SITE)
WHERE m.MODEL IS NULL
ORDER BY c.도우모델;

-- ========================================
-- 9. 공통 배부 INSERT 예상 건수
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '9. 공통 배부 INSERT 예상 건수';
PRINT '========================================';

WITH BOM as (
    select * FROM (
        select
            b.yyyymm as byyyymm, 
            b.자재번호, 
            b.제품명, 
            b.자재대분류,
            sum(소요량) 소요량, 
            count(*) cnt,
            row_number() over (partition by b.자재번호, b.제품명 order by (b.자재대분류)) rn, 
            row_number() over (partition by b.자재번호 order by (b.자재대분류)) rn1
        from doi_bom_mast b
        where yyyymm=@YYYYMM 
            and site=@SITE 
            and nullif(자재번호, '') IS NOT NULL
        group by b.yyyymm, b.자재번호, b.제품명, b.자재대분류
    ) a WHERE rn1 = 1
),
CHGQTY AS (
    select
        a.yyyymm,
        a.sel_code,
        a.DW_SITE,
        a.도우모델,
        sum(a.IN_MONTH) in_qty,
        sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2 as 환산량
    from doi_prod_subul a
    where a.yyyymm = @YYYYMM
        and a.sel_code = 'ACTUAL'
        and a.DW_SITE = @SITE
    group by a.yyyymm,a.sel_code,a.DW_SITE,a.도우모델
    having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
),
MAT_COMM_RATE AS (
    select 
        a.*, 
        (환산량 * b.xy)/sum(환산량 * b.xy) over() as comm_rate, 
        b.xy
    from CHGQTY A   
    inner join DOI_MODEL_MAST B ON (a.도우모델 = b.MODEL and b.YYYYMM = @YYYYMM and a.DW_SITE = b.SITE)
)
SELECT 
    '예상 INSERT 건수' as 구분,
    COUNT(*) as 건수
FROM DOI_MAT_AMT a with(nolock)
INNER JOIN MAT_COMM_RATE b ON (1 = 1)
WHERE a.yyyymm = @YYYYMM 
    AND a.site = @SITE 
    AND a.sel_code = 'ACTUAL'
    AND NOT EXISTS (SELECT 1 FROM BOM c WHERE a.mat_code = c.자재번호);

-- 공통 배부 대상 자재 수
SELECT 
    '공통 배부 대상 자재' as 구분,
    COUNT(DISTINCT a.mat_code) as 자재수,
    SUM(a.in_amt) as 금액합계
FROM DOI_MAT_AMT a with(nolock)
WHERE a.yyyymm = @YYYYMM 
    AND a.site = @SITE 
    AND a.sel_code = 'ACTUAL'
    AND NOT EXISTS (
        SELECT 1 
        FROM doi_bom_mast b 
        WHERE a.mat_code = b.자재번호 
            AND b.yyyymm = @YYYYMM 
            AND b.site = @SITE
    );

-- ========================================
-- 10. 소스 vs 타겟 금액 비교
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '10. 소스 vs 타겟 금액 비교';
PRINT '========================================';

SELECT 
    'SOURCE (DOI_MAT_AMT)' as 구분,
    COUNT(*) as 건수,
    SUM(in_amt) as 금액
FROM DOI_MAT_AMT
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'

UNION ALL

SELECT 
    'TARGET (DOI_MAT_COST - 전체합계)' as 구분,
    COUNT(*) as 건수,
    SUM(배부금액) as 금액
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL'

UNION ALL

SELECT 
    'TARGET (DOI_MAT_COST - 자재별)' as 구분,
    COUNT(DISTINCT 자재번호) as 건수,
    SUM(배부금액) as 금액
FROM DOI_MAT_COST
WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = 'ACTUAL';
