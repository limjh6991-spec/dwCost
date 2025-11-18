-- ============================================================================
-- SITE 별 경영 실행 (국내) 레포트 쿼리 - 완성본
-- 작성일: 2025-11-15
-- 설명: 이미지 장표와 동일한 형식으로 월별 경영 실행 데이터를 조회
-- 
-- 테이블 및 금액 컬럼 매핑:
-- - 재료비/노무비: DOI_FAB_COST.[in]
-- - 제조경비: DOI_SLCO.OUT_AMT
-- - 판매관리비: DOI_SMCE_COST.DIST_AMT
-- 
-- 경비 코드 매핑:
-- - MDAX: 재료비
-- - EDAX: 인건비
-- - EIAS: 복리후생
-- - PDAS: 인원성경비
-- - CDAS: 관리가능비 (기타경비)
-- - NDAS: 관리불능비 (기타경비)
-- - RDAS: 임차료 (기타경비)
-- - UDAS: 유틸리티비
-- - TDAS: 수선유지비
-- - SDAS: 생소비/포장비
-- - DIAS: 기타감가 (감가비)
-- - DDAS: 공통감가 (주요감가)
-- ============================================================================

-- 연도 파라미터 설정
DECLARE @YYYY VARCHAR(4) = '2025';

-- 월별 YYYYMM 생성 (CTE 사용)
WITH GEN_YYYYMM AS (
    SELECT 
        CAST(@YYYY + '0101' AS DATE) AS DT,
        FORMAT(CAST(@YYYY + '0101' AS DATE), 'yyyyMM') AS YYYYMM,
        CAST(RIGHT(@YYYY + '01', 2) AS INT) AS 월번호
    UNION ALL
    SELECT 
        DATEADD(MONTH, 1, DT),
        FORMAT(DATEADD(MONTH, 1, DT), 'yyyyMM') AS YYYYMM,
        CAST(RIGHT(FORMAT(DATEADD(MONTH, 1, DT), 'yyyyMM'), 2) AS INT) AS 월번호
    FROM GEN_YYYYMM
    WHERE DT < CAST(@YYYY + '1201' AS DATE)
)
SELECT * INTO #GEN_YYYYMM FROM GEN_YYYYMM
OPTION (MAXRECURSION 12);

-- ============================================================================
-- 최종 결과 조회
-- ============================================================================
SELECT 
    구분,
    MAX(CASE WHEN 월 = '1월' THEN 금액 END) AS '1월',
    MAX(CASE WHEN 월 = '2월' THEN 금액 END) AS '2월',
    MAX(CASE WHEN 월 = '3월' THEN 금액 END) AS '3월',
    MAX(CASE WHEN 월 = '4월' THEN 금액 END) AS '4월',
    MAX(CASE WHEN 월 = '5월' THEN 금액 END) AS '5월',
    MAX(CASE WHEN 월 = '6월' THEN 금액 END) AS '6월',
    MAX(CASE WHEN 월 = '7월' THEN 금액 END) AS '7월',
    MAX(CASE WHEN 월 = '8월' THEN 금액 END) AS '8월',
    MAX(CASE WHEN 월 = '9월' THEN 금액 END) AS '9월',
    MAX(CASE WHEN 월 = '10월' THEN 금액 END) AS '10월',
    MAX(CASE WHEN 월 = '11월' THEN 금액 END) AS '11월',
    MAX(CASE WHEN 월 = '12월' THEN 금액 END) AS '12월'
FROM (
    -- ========================================================================
    -- 1. 매출액
    -- ========================================================================
    SELECT 
        1 AS 순서,
        '매출액' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.원화판매금액계), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 수량 (Cell)
    SELECT 
        2 AS 순서,
        '  수량 (Cell)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.수량), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 판가 (단위:원)
    SELECT 
        3 AS 순서,
        '  판가 (단위:원)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        CASE 
            WHEN SUM(ISNULL(b.수량, 0)) = 0 THEN 0
            ELSE SUM(ISNULL(b.원화판매금액계, 0)) / NULLIF(SUM(ISNULL(b.수량, 0)), 0)
        END AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 2. 양산매출
    -- ========================================================================
    SELECT 
        4 AS 순서,
        '양산매출' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.원화판매금액계), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND RIGHT(b.품번, 1) != 'D')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 수량 (Cell)
    SELECT 
        5 AS 순서,
        '  수량 (Cell)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.수량), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND RIGHT(b.품번, 1) != 'D')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 판가 (단위:원)
    SELECT 
        6 AS 순서,
        '  판가 (단위:원)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        CASE 
            WHEN SUM(ISNULL(b.수량, 0)) = 0 THEN 0
            ELSE SUM(ISNULL(b.원화판매금액계, 0)) / NULLIF(SUM(ISNULL(b.수량, 0)), 0)
        END AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND RIGHT(b.품번, 1) != 'D')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 3. 개발매출
    -- ========================================================================
    SELECT 
        7 AS 순서,
        '개발매출' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.원화판매금액계), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND RIGHT(b.품번, 1) = 'D')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 수량 (Cell)
    SELECT 
        8 AS 순서,
        '  수량 (Cell)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.수량), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND RIGHT(b.품번, 1) = 'D')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 판가 (단위:원)
    SELECT 
        9 AS 순서,
        '  판가 (단위:원)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        CASE 
            WHEN SUM(ISNULL(b.수량, 0)) = 0 THEN 0
            ELSE SUM(ISNULL(b.원화판매금액계, 0)) / NULLIF(SUM(ISNULL(b.수량, 0)), 0)
        END AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND RIGHT(b.품번, 1) = 'D')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 4. CST매출 (TODO: CST 조건 확인 필요)
    -- ========================================================================
    SELECT 
        10 AS 순서,
        'CST매출' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 5. 수량 (Cell) - CST
    -- ========================================================================
    SELECT 
        11 AS 순서,
        '  수량 (Cell)' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 6. 판가 (단위:원) - CST
    -- ========================================================================
    SELECT 
        12 AS 순서,
        '  판가 (단위:원)' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 7. 원장상계 外
    -- ========================================================================
    SELECT 
        13 AS 순서,
        '원장상계 外' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 8. 상품매출
    -- ========================================================================
    SELECT 
        14 AS 순서,
        '상품매출' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 9. 기타매출
    -- ========================================================================
    SELECT 
        15 AS 순서,
        '기타매출' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 10. 매출원가
    -- ========================================================================
    SELECT 
        16 AS 순서,
        '매출원가' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_STOCK_COST b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 11. 기초제품재고액
    -- ========================================================================
    SELECT 
        17 AS 순서,
        '  기초제품재고액' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.BOH_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_STOCK_COST b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 12. 당기제품제조원가
    -- ========================================================================
    SELECT 
        18 AS 순서,
        '  당기제품제조원가' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.IN_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_STOCK_COST b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 13. 타계정으로(샘플,….) (TODO: 조건 확인)
    -- ========================================================================
    SELECT 
        19 AS 순서,
        '  타계정으로(샘플,….)' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 14. 타계정으로(재공) (TODO: 조건 확인)
    -- ========================================================================
    SELECT 
        20 AS 순서,
        '  타계정으로(재공)' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 15. 관세환급금 (TODO: 조건 확인)
    -- ========================================================================
    SELECT 
        21 AS 순서,
        '  관세환급금' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 16. 기말제품재고액
    -- ========================================================================
    SELECT 
        22 AS 순서,
        '  기말제품재고액' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.EOH_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_STOCK_COST b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 17. 상품매출원가 (TODO: 조건 확인)
    -- ========================================================================
    SELECT 
        23 AS 순서,
        '  상품매출원가' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 18. 재료비 (DOI_FAB_COST에서 재료비 집계)
    -- ========================================================================
    SELECT 
        24 AS 순서,
        '재료비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.[in]), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_FAB_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL IN ('MDAX', 'MIAX')  -- 재료비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 원재료
    SELECT 
        25 AS 순서,
        '  원재료' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.[in]), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_FAB_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'MDAX'  -- 원재료 (재료비)
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 부재료
    SELECT 
        26 AS 순서,
        '  부재료' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.[in]), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_FAB_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'MIAX'  -- 부재료
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 19. 노무비
    -- ========================================================================
    SELECT 
        27 AS 순서,
        '노무비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.[in]), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_FAB_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL IN ('EDAX', 'EIAX')  -- 인건비, 복리후생
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)인건비
    SELECT 
        28 AS 순서,
        '  제)인건비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.[in]), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_FAB_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'EDAX'  -- 인건비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 도급비 (TODO: 도급비 코드 확인 필요)
    SELECT 
        29 AS 순서,
        '  도급비' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 20. 제조경비
    -- ========================================================================
    SELECT 
        30 AS 순서,
        '제조경비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL IN ('CDAX', 'CDBX', 'CDCX', 'CDDX', 'CDEX', 'CDFX', 'CDGX', 'CDHX', 'DIAX', 'DDAX')  -- 경비, 감가비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)복리후생비-건강,장기요양보험
    SELECT 
        31 AS 순서,
        '  제)복리후생비-건강,장기요양보험' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'EIAX'  -- 복리후생
        AND b.SEL_CODE LIKE '%61005%'  -- 건강,장기요양보험 계정 (확인 필요)
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)복리후생비-사내식대
    SELECT 
        32 AS 순서,
        '  제)복리후생비-사내식대' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)복리후생비-기타
    SELECT 
        33 AS 순서,
        '  제)복리후생비-기타' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)여비교통비
    SELECT 
        34 AS 순서,
        '  제)여비교통비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'CDAX'  -- 인원성경비
        AND b.SEL_CODE LIKE '%61009%'  -- 여비교통비 계정 (확인 필요)
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)접대비
    SELECT 
        35 AS 순서,
        '  제)접대비' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)통신비
    SELECT 
        36 AS 순서,
        '  제)통신비' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)수도광열비
    SELECT 
        37 AS 순서,
        '  제)수도광열비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'CDEX'  -- 유틸리티비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)전력비
    SELECT 
        38 AS 순서,
        '  제)전력비' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액  -- 전력비는 수도광열비에 포함되어 있을 수 있음
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)세금과공과-연금보험
    SELECT 
        39 AS 순서,
        '  제)세금과공과-연금보험' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)세금과공과-기타
    SELECT 
        40 AS 순서,
        '  제)세금과공과-기타' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)감가상각비
    SELECT 
        41 AS 순서,
        '  제)감가상각비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL IN ('DIAX', 'DDAX')  -- 기타감가, 주요감가
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)지급임차료
    SELECT 
        42 AS 순서,
        '  제)지급임차료' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'CDDX'  -- 임차료
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)수선비
    SELECT 
        43 AS 순서,
        '  제)수선비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'CDFX'  -- 수선유지비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)보험료-고용,산재보험
    SELECT 
        44 AS 순서,
        '  제)보험료-고용,산재보험' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)보험료-차량
    SELECT 
        45 AS 순서,
        '  제)보험료-차량' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)보험료-기타
    SELECT 
        46 AS 순서,
        '  제)보험료-기타' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)차량유지비-유류비
    SELECT 
        47 AS 순서,
        '  제)차량유지비-유류비' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)차량유지비-기타
    SELECT 
        48 AS 순서,
        '  제)차량유지비-기타' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)차량유지비-자동차세
    SELECT 
        49 AS 순서,
        '  제)차량유지비-자동차세' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)운반비
    SELECT 
        50 AS 순서,
        '  제)운반비' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)소모품비
    SELECT 
        51 AS 순서,
        '  제)소모품비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'CDGX'  -- 생소비/포장비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)지급수수료-기타
    SELECT 
        52 AS 순서,
        '  제)지급수수료-기타' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'CDBX'  -- 관리가능비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 제)지급수수료-유지보수료
    SELECT 
        53 AS 순서,
        '  제)지급수수료-유지보수료' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)지급수수료-감사.법률.자문
    SELECT 
        54 AS 순서,
        '  제)지급수수료-감사.법률.자문' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 제)기타
    SELECT 
        55 AS 순서,
        '  제)기타' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SLCO b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL IN ('CDCX', 'CDHX')  -- 관리불능비, 외주가공
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 당기총제조비용 (TODO: 계산 로직 확인)
    -- ========================================================================
    SELECT 
        56 AS 순서,
        '당기총제조비용' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 기초재공품재고액 (TODO: 조건 확인)
    SELECT 
        57 AS 순서,
        '기초재공품재고액' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- 기말재공품재고액 (TODO: 조건 확인)
    SELECT 
        58 AS 순서,
        '기말재공품재고액' AS 구분,
        CAST(월번호 AS VARCHAR) + '월' AS 월,
        0 AS 금액
    FROM #GEN_YYYYMM
    
    UNION ALL
    
    -- ========================================================================
    -- 매출총이익 (매출액 - 매출원가)
    -- ========================================================================
    SELECT 
        59 AS 순서,
        '매출총이익' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.원화판매금액계), 0) - ISNULL(SUM(c.OUT_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    LEFT JOIN DOI_STOCK_COST c ON (a.YYYYMM = c.YYYYMM AND c.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- (매출총이익률) = 매출총이익 / 매출액 * 100
    SELECT 
        60 AS 순서,
        '(매출총이익률)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        CASE 
            WHEN SUM(ISNULL(b.원화판매금액계, 0)) = 0 THEN 0
            ELSE (SUM(ISNULL(b.원화판매금액계, 0)) - SUM(ISNULL(c.OUT_AMT, 0))) / NULLIF(SUM(ISNULL(b.원화판매금액계, 0)), 0) * 100
        END AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    LEFT JOIN DOI_STOCK_COST c ON (a.YYYYMM = c.YYYYMM AND c.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- ========================================================================
    -- 판매관리비 (DOI_SMCE_COST)
    -- ========================================================================
    SELECT 
        61 AS 순서,
        '판매관리비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SMCE_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 판)인건비
    SELECT 
        62 AS 순서,
        '  판)인건비' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SMCE_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'EDAS'  -- 판관 인건비
    )
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- 판)복리후생비-건강,장기요양보험
    SELECT 
        63 AS 순서,
        '  판)복리후생비-건강,장기요양보험' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SMCE_COST b ON (
        a.YYYYMM = b.YYYYMM 
        AND b.SITE = 'HQ'
        AND b.EXPEN_SEL = 'EIAS'  -- 판관 복리후생
    )
    GROUP BY a.YYYYMM, a.월번호
    
    -- TODO: 추가 판관비 상세 항목들...
    -- 판)복리후생비-사내식대
    -- 판)복리후생비-기타
    -- 판)여비교통비
    -- ...
    -- 판)기타
    
    UNION ALL
    
    -- ========================================================================
    -- 영업이익 (매출총이익 - 판매관리비)
    -- ========================================================================
    SELECT 
        90 AS 순서,
        '영업이익' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        (ISNULL(SUM(b.원화판매금액계), 0) - ISNULL(SUM(c.OUT_AMT), 0)) - ISNULL(SUM(d.DIST_AMT), 0) AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    LEFT JOIN DOI_STOCK_COST c ON (a.YYYYMM = c.YYYYMM AND c.SITE = 'HQ')
    LEFT JOIN DOI_SMCE_COST d ON (a.YYYYMM = d.YYYYMM AND d.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
    UNION ALL
    
    -- (영업이익률) = 영업이익 / 매출액 * 100
    SELECT 
        91 AS 순서,
        '(영업이익률)' AS 구분,
        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
        CASE 
            WHEN SUM(ISNULL(b.원화판매금액계, 0)) = 0 THEN 0
            ELSE ((SUM(ISNULL(b.원화판매금액계, 0)) - SUM(ISNULL(c.OUT_AMT, 0))) - SUM(ISNULL(d.DIST_AMT, 0))) / NULLIF(SUM(ISNULL(b.원화판매금액계, 0)), 0) * 100
        END AS 금액
    FROM #GEN_YYYYMM a 
    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ')
    LEFT JOIN DOI_STOCK_COST c ON (a.YYYYMM = c.YYYYMM AND c.SITE = 'HQ')
    LEFT JOIN DOI_SMCE_COST d ON (a.YYYYMM = d.YYYYMM AND d.SITE = 'HQ')
    GROUP BY a.YYYYMM, a.월번호
    
) AS SourceData
GROUP BY 구분, 순서
ORDER BY 순서;

-- 임시 테이블 정리
DROP TABLE #GEN_YYYYMM;
