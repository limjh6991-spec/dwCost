CREATE                         Procedure DOI_AnnualReportBySite
(
    @YYYY varchar(4),
    @SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
-- ============================================================================
-- SITE 별 경영 실행 (국내) 레포트 쿼리 - 완성본
-- 작성일: 2025-11-15
-- 설명: 이미지 장표와 동일한 형식으로 월별 경영 실행 데이터를 조회
-- 
-- 테이블 및 금액 컬럼 매핑:
-- - 재료비/노무비: DOI_COST.[in]
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
SELECT 구분
, "1월"+"2월"+"3월"+"4월"+"5월"+"6월"+"7월"+"8월"+"9월"+"10월"+"11월"+"12월" AS tot 
, "1월","2월","3월","4월","5월","6월","7월","8월","9월","10월","11월","12월"
FROM(
	SELECT 
	    구분,
	    순서,
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
--	    LEFT JOIN DOI_SALE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
	    LEFT JOIN 
	    (SELECT YYYYMM, SUM(원화판매금액계) as 원화판매금액계 
	     FROM(
			select YYYYMM, 원화판매금액계
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = @YYYY
      		  and SITE 	 = @SITE
	        union all
	        select YYYYMM,원화판매금액
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = @YYYY
      		  and SITE 	 = @SITE
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 수량 (Cell)
	    SELECT 
	        2 AS 순서,
	        '  수량 (Cell)' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.수량), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN 
	    (SELECT YYYYMM, SUM(수량) as 수량 
	     FROM(
			select YYYYMM, 수량
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
	        union all
	        select YYYYMM,수량
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
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
	    LEFT JOIN 
	    (SELECT YYYYMM, SUM(수량) as 수량 ,SUM(원화판매금액계) as 원화판매금액계
	     FROM(
			select YYYYMM, 수량,원화판매금액계
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
	        union all
	        select YYYYMM,수량,원화판매금액
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
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
	    LEFT JOIN 
	    (SELECT YYYYMM, SUM(원화판매금액계) as 원화판매금액계 
	     FROM(
			select YYYYMM, 원화판매금액계
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) != 'D'
	        union all
	        select YYYYMM, 원화판매금액
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) != 'D'
      		  and Buyer != '도우VINA'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 수량 (Cell)
	    SELECT 
	        5 AS 순서,
	        '  수량 (Cell)' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.수량), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN  
	    (SELECT YYYYMM, SUM(수량) as 수량 
	     FROM(
			select YYYYMM, 수량
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) != 'D'
	        union all
	        select YYYYMM, 수량
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) != 'D'
      		  and Buyer != '도우VINA'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
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
	    LEFT JOIN
	    (SELECT YYYYMM, SUM(수량) as 수량 ,SUM(원화판매금액계) as 원화판매금액계
	     FROM(
			select YYYYMM, 수량,원화판매금액계
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) != 'D'
	        union all
	        select YYYYMM,수량,원화판매금액
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) != 'D'
      		  and Buyer != '도우VINA'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
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
	    LEFT JOIN
	    (SELECT YYYYMM, SUM(원화판매금액계) as 원화판매금액계 
	     FROM(
			select YYYYMM, 원화판매금액계
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) = 'D'
	        union all
	        select YYYYMM, 원화판매금액
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) = 'D'
      		  and Buyer != '도우VINA'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 수량 (Cell)
	    SELECT 
	        8 AS 순서,
	        '  수량 (Cell)' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.수량), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN
	    (SELECT YYYYMM, SUM(수량) as 수량 
	     FROM(
			select YYYYMM, 수량
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) = 'D'
	        union all
	        select YYYYMM, 수량
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) = 'D'
      		  and Buyer != '도우VINA'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
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
	    LEFT JOIN
	    (SELECT YYYYMM, SUM(수량) as 수량 ,SUM(원화판매금액계) as 원화판매금액계
	     FROM(
			select YYYYMM, 수량,원화판매금액계
			from DOI_SALE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) = 'D'
	        union all
	        select YYYYMM,수량,원화판매금액
			from DOI_INVOICE_RESC
			where 1=1 
			  and SUBSTRING(YYYYMM,1,4) = '2025'
      		  and SITE 	 = 'HQ'
      		  and RIGHT(품번, 1) = 'D'
      		  and Buyer != '도우VINA'
      		)a	
      		group by YYYYMM  
        ) b ON (a.yyyymm=b.yyyymm)
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- ========================================================================
	    -- 4. CST매출 (TODO: CST 조건 확인 필요)
	    -- ========================================================================
	    SELECT 
	        10 AS 순서,
	        'CST매출' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.원화판매금액), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_INVOICE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND Buyer='도우VINA')
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- ========================================================================
	    -- 5. 수량 (Cell) - CST
	    -- ========================================================================
	    SELECT 
	        11 AS 순서,
	        '  수량 (EA)' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.수량), 0) AS 수량
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_INVOICE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND Buyer='도우VINA')
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- ========================================================================
	    -- 6. 판가 (단위:원) - CST
	    -- ========================================================================
	    SELECT 
	        12 AS 순서,
	        '  판가 (단위:원)' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        CASE 
	            WHEN SUM(ISNULL(b.수량, 0)) = 0 THEN 0
	            ELSE SUM(ISNULL(b.원화판매금액, 0)) / NULLIF(SUM(ISNULL(b.수량, 0)), 0)
	        END AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_INVOICE_RESC b ON (a.YYYYMM = b.YYYYMM AND b.SITE = 'HQ' AND Buyer='도우VINA')
	    GROUP BY a.YYYYMM, a.월번호
	    
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
	    LEFT JOIN DOI_STCO b ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
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
	    LEFT JOIN DOI_STCO b ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
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
	    LEFT JOIN DOI_STCO b ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
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
	    LEFT JOIN DOI_STCO b ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
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
	    -- 18. 재료비 (DOI_COST에서 재료비 집계)
	    -- ========================================================================
	    SELECT 
	        24 AS 순서,
	        '재료비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.[in]), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
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
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
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
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
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
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL IN ('MHRB', 'SCHED')  -- 인건비, 도급비(나중에 외주프로세스 발생할수 있음)
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
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MHRB'  -- 인건비
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL IN ('MHLT',	'MEAL',	'MWEL',	'MTRV',	'MENT',	'MCOM',	'MUTI',	'MELC',	'MPEN',	'MTAX',	'MDEP',	'MRNT',	'MREP',	'MEMP',	'MCAR',	'MINS',	'MFUE',	'MVEH',	'MCAT',	'MTRS',	'MISC',	'MSUP',	'MFEE',	'MMNT',	'MAUD')  -- 경비, 감가비
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MHLT'  -- 복리후생
	  --AND b.SEL_CODE LIKE '%61005%'  -- 건강,장기요양보험 계정 (확인 필요)
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)복리후생비-사내식대
	    SELECT 
	        32 AS 순서,
	        '  제)복리후생비-사내식대' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MEAL'  -- 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    
	    UNION ALL
	    
	    -- 제)복리후생비-기타
	    SELECT 
	        33 AS 순서,
	        '  제)복리후생비-기타' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MWEL'  -- 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MTRV'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)접대비
	    SELECT 
	        35 AS 순서,
	        '  제)접대비' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MENT'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)통신비
	    SELECT 
	        36 AS 순서,
	        '  제)통신비' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MCOM'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MUTI'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)전력비
	    SELECT 
	        38 AS 순서,
	        '  제)전력비' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액  -- 전력비는 수도광열비에 포함되어 있을 수 있음
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MELC'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)세금과공과-연금보험
	    SELECT 
	        39 AS 순서,
	        '  제)세금과공과-연금보험' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MPEN'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)세금과공과-기타
	    SELECT 
	        40 AS 순서,
	        '  제)세금과공과-기타' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MTAX'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MDEP'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    UNION ALL
	    
	    -- 제)지급임차료
	    SELECT 
	        42 AS 순서,
	        '  제)지급임차료' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM  a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MRNT'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)수선비
	    SELECT 
	        43 AS 순서,
	        '  제)수선비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM  a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MREP'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)보험료-고용,산재보험
	    SELECT 
	        44 AS 순서,
	        '  제)보험료-고용,산재보험' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MEMP'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)보험료-차량
	    SELECT 
	        45 AS 순서,
	        '  제)보험료-차량' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MCAR'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)보험료-기타
	    SELECT 
	        46 AS 순서,
	        '  제)보험료-기타' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MINS'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)차량유지비-유류비
	    SELECT 
	        47 AS 순서,
	        '  제)차량유지비-유류비' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MFUE'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)차량유지비-기타
	    SELECT 
	        48 AS 순서,
	        '  제)차량유지비-기타' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MVEH'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)차량유지비-자동차세
	    SELECT 
	        49 AS 순서,
	        '  제)차량유지비-자동차세' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MCAT'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)운반비
	    SELECT 
	        50 AS 순서,
	        '  제)운반비' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MTRS'  
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MSUP'  -- 생소비/포장비
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MFEE'  -- 관리가능비
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 제)지급수수료-유지보수료
	    SELECT 
	        53 AS 순서,
	        '  제)지급수수료-유지보수료' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MMNT'  -- 관리가능비
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	 
	    -- 제)지급수수료-감사.법률.자문
	    SELECT 
	        54 AS 순서,
	        '  제)지급수수료-감사.법률.자문' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.OUT_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SLCO b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MAUD'  -- 관리가능비
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'MISC'  -- 관리불능비, 외주가공
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
	        sum([in]) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE  -- 당기총제조비용
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 기초재공품재고액 (TODO: 조건 확인)
	    SELECT 
	        57 AS 순서,
	        '기초재공품재고액' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	        sum([boh]) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE  -- 기초재공품재고액
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- 기말재공품재고액 (TODO: 조건 확인)
	    SELECT 
	        58 AS 순서,
	        '기말재공품재고액' AS 구분,
	        CAST(월번호 AS VARCHAR) + '월' AS 월,
	         sum([eoh]) AS 금액
	    FROM #GEN_YYYYMM a
	    LEFT JOIN DOI_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE  -- 기말재공품재고액 
	    )
	    GROUP BY a.YYYYMM, a.월번호
	    
	    UNION ALL
	    
	    -- ========================================================================
	    -- 매출총이익 (매출액 - 매출원가)
	    -- ========================================================================
		SELECT 
		59 AS 순서,
		'매출총이익' AS 구분,
		CAST(a.월번호 AS VARCHAR) + '월' AS 월,
		b.원화판매금액계 + d.원화판매금액계 - c.OUT_AMT AS 금액
		FROM #GEN_YYYYMM a 
		LEFT JOIN (
				SELECT a.yyyymm,
				ISNULL(SUM(b.원화판매금액계), 0) as  원화판매금액계
				FROM #GEN_YYYYMM a
				LEFT JOIN DOI_SALE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
				GROUP BY a.yyyymm
				) b ON (a.YYYYMM = b.YYYYMM)
		LEFT JOIN (
				SELECT a.yyyymm,
				ISNULL(SUM(c.OUT_AMT), 0) OUT_AMT
				FROM #GEN_YYYYMM a
				LEFT JOIN DOI_STCO c with (nolock) ON (a.YYYYMM = c.YYYYMM AND c.SITE = @SITE)
				GROUP BY a.yyyymm
				) c ON (a.YYYYMM = c.YYYYMM)
		LEFT JOIN (
				SELECT a.yyyymm,
				ISNULL(SUM(b.원화판매금액), 0) as  원화판매금액계
				FROM #GEN_YYYYMM a
				LEFT JOIN DOI_INVOICE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
				GROUP BY a.yyyymm
				) d ON (a.YYYYMM = d.YYYYMM)
		UNION ALL
		-- (매출총이익률) = 매출총이익 / 매출액 * 100
		SELECT 
		60 AS 순서,
		'(매출총이익률)' AS 구분,
		CAST(a.월번호 AS VARCHAR) + '월' AS 월,
		CASE 
		WHEN b.원화판매금액계 = 0 THEN 0
		ELSE (b.원화판매금액계 - c.OUT_AMT) / NULLIF(b.원화판매금액계,0) * 100
		END AS 금액
		FROM #GEN_YYYYMM a 
		LEFT JOIN (
				SELECT a.yyyymm,
				ISNULL(SUM(b.원화판매금액계), 0) as  원화판매금액계
				FROM #GEN_YYYYMM a
				LEFT JOIN DOI_SALE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
				GROUP BY a.yyyymm
				) b ON (a.YYYYMM = b.YYYYMM)
		LEFT JOIN (
				SELECT a.yyyymm,
				ISNULL(SUM(c.OUT_AMT), 0) OUT_AMT
				FROM #GEN_YYYYMM a
				LEFT JOIN DOI_STCO c with (nolock) ON (a.YYYYMM = c.YYYYMM AND c.SITE = @SITE)
				GROUP BY a.yyyymm
				) c ON (a.YYYYMM = c.YYYYMM)
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
	        AND b.SITE = @SITE
	        AND expen_sel in ('SHRB',	'SHLT',	'SEAL',	'SWEL',	'STRV',	'SENT',	'SCOM',	'SUTI',	'SELC',	'SPEN',	'STAX',	'SDEP',	'SRNT',	'SREP',	'SINS',	'SCAR',	'SINC',	'SFUE',	'SVEH',	'SCAT',	'SRND',	'SRUP',	'SHRD',	'SFNS',	'STRN',	'SOTC',	'SSUP',	'SFEE',	'SMNT',	'SAUD',	'SEXP')
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SHRB'  -- 판관 인건비
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
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SHLT'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호    
	    
	    UNION ALL
	    
	    -- 판)복리후생비-사내식대
	    SELECT 
	        64 AS 순서,
	        '  판)복리후생비-사내식대' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SEAL'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)복리후생비-기타
	    SELECT 
	        65 AS 순서,
	        '  판)복리후생비-기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SWEL'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)여비교통비
	    SELECT 
	        66 AS 순서,
	        '  판)여비교통비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'STRV'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)접대비
	    SELECT 
	        67 AS 순서,
	        '  판)접대비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SENT'  -- 판관 복리후생
	  )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)통신비
	    SELECT 
	        68 AS 순서,
	        '  판)통신비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SCOM'  -- 판관 복리후생
	    )
	 GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)수도광열비
	    SELECT 
	        69 AS 순서,
	        '  판)수도광열비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SUTI'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)전력비
	    SELECT 
	        70 AS 순서,
	        '  판)전력비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SELC'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)세금과공과-연금보험
	    SELECT 
	        71 AS 순서,
	        '  판)세금과공과-연금보험' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	     AND b.EXPEN_SEL = 'SPEN'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)세금과공과-기타
	    SELECT 
	        72 AS 순서,
	        '  판)세금과공과-기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'STAX'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)감가상각비
	    SELECT 
	        73 AS 순서,
	        '  판)감가상각비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SDEP'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)지급임차료
	    SELECT 
	        74 AS 순서,
	        '  판)지급임차료' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SRNT'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)수선비
	    SELECT 
	        75 AS 순서,
	        '  판)수선비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SREP'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)보험료-산재,고용보험
	    SELECT 
	        76 AS 순서,
	        '  판)보험료-산재,고용보험' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SINS'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)보험료-차량
	    SELECT 
	        77 AS 순서,
	        '  판)보험료-차량' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	       a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SCAR'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)보험료-기타
	    SELECT 
	        78 AS 순서,
	        '  판)보험료-기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SINC'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)차량유지비-유류비
	    SELECT 
	        79 AS 순서,
	        '  판)차량유지비-유류비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SFUE'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)차량유지비-기타
	    SELECT 
	        80 AS 순서,
	        '  판)차량유지비-기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SVEH'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)차량유지비-자동차세
	    SELECT 
	        81 AS 순서,
	        '  판)차량유지비-자동차세' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SCAT'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)경상연구개발비-기타
	    SELECT 
	        82 AS 순서,
	        '  판)경상연구개발비-기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SRND'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)경상연구개발비-개발소모품
	    SELECT 
	        83 AS 순서,
	        '  판)경상연구개발비-개발소모품' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SRUP'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)경상연구개발비-인건비
	    SELECT 
	        84 AS 순서,
	        '  판)경상연구개발비-인건비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SHRD'  -- 판관 복리후생
	    )
	   GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)경상연구개발비-4대보험
	    SELECT 
	        85 AS 순서,
	        '  판)경상연구개발비-4대보험' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SFNS'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)운반비
	    SELECT 
	        86 AS 순서,
	        '  판)운반비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'STRN'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)소모품비
	    SELECT 
	        87 AS 순서,
	   '  판)소모품비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SSUP'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)지급수수료-기타
	    SELECT 
	        88 AS 순서,
	   '  판)지급수수료-기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SFEE'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)지급수수료-유지보수료
	    SELECT 
	        89 AS 순서,
	        '  판)지급수수료-유지보수료' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SMNT'  -- 판관 복리후생
	    )
	 GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)지급수수료-감사.법률.자문
	    SELECT 
	        90 AS 순서,
	        '  판)지급수수료-감사.법률.자문' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SAUD'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	   
	   UNION ALL
	    
	    -- 판)해외시장개척비
	    SELECT 
	        91 AS 순서,
	        '  판)해외시장개척비' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SEXP'  -- 판관 복리후생
	    )
	    GROUP BY a.YYYYMM, a.월번호   
	    
	    UNION ALL
	    
	    -- 판)기타
	    SELECT 
	        92 AS 순서,
	        '  판)기타' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        ISNULL(SUM(b.DIST_AMT), 0) AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN DOI_SMCE_COST b ON (
	        a.YYYYMM = b.YYYYMM 
	        AND b.SITE = @SITE
	        AND b.EXPEN_SEL = 'SOTC'  -- 판관 복리후생
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
	        93 AS 순서,
	        '영업이익' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        b.원화판매금액계 + e.원화판매금액계  - c.OUT_AMT - d.DIST_AMT AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(b.원화판매금액계), 0) 원화판매금액계
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_SALE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
			      GROUP BY a.yyyymm
		   		 ) b ON (a.yyyymm = b.yyyymm)
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(c.OUT_AMT), 0) OUT_AMT
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_STCO c with (nolock) ON (a.YYYYMM = c.YYYYMM AND c.SITE = @SITE)
			      GROUP BY a.yyyymm
		    	) c ON (a.YYYYMM = c.YYYYMM)
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(d.DIST_AMT), 0) DIST_AMT
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_SMCE_COST d with (nolock) ON (a.YYYYMM = d.YYYYMM AND d.SITE = @SITE)
			      GROUP BY a.yyyymm
		    	) d  ON (a.yyyymm = d.yyyymm)
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(b.원화판매금액), 0) 원화판매금액계
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_INVOICE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
			      GROUP BY a.yyyymm
		   		 ) e ON (a.yyyymm = e.yyyymm)
	    UNION ALL
	    
	    -- (영업이익률) = 영업이익 / 매출액 * 100
	    SELECT 
	        94 AS 순서,
	        '(영업이익률)' AS 구분,
	        CAST(a.월번호 AS VARCHAR) + '월' AS 월,
	        CASE 
	            WHEN b.원화판매금액계 = 0 THEN 0
	            ELSE ((b.원화판매금액계 + e.원화판매금액계 - c.OUT_AMT) - d.DIST_AMT) / NULLIF(b.원화판매금액계, 0) * 100
	        END AS 금액
	    FROM #GEN_YYYYMM a 
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(b.원화판매금액계), 0) 원화판매금액계
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_SALE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
			      GROUP BY a.yyyymm
		   		 ) b ON (a.yyyymm = b.yyyymm)
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(c.OUT_AMT), 0) OUT_AMT
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_STCO c with (nolock) ON (a.YYYYMM = c.YYYYMM AND c.SITE = @SITE)
			      GROUP BY a.yyyymm
		    	) c ON (a.YYYYMM = c.YYYYMM)
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(d.DIST_AMT), 0) DIST_AMT
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_SMCE_COST d with (nolock) ON (a.YYYYMM = d.YYYYMM AND d.SITE = @SITE)
			      GROUP BY a.yyyymm
		    	) d  ON (a.yyyymm = d.yyyymm)
	    LEFT JOIN (
			      SELECT a.yyyymm,
			      		ISNULL(SUM(b.원화판매금액), 0) 원화판매금액계
			      FROM #GEN_YYYYMM a
			      LEFT JOIN DOI_INVOICE_RESC b with (nolock) ON (a.YYYYMM = b.YYYYMM AND b.SITE = @SITE)
			      GROUP BY a.yyyymm
		   		 ) e ON (a.yyyymm = e.yyyymm)
	    
	) AS SourceData
	GROUP BY 구분, 순서
) AS SourceData2
ORDER BY 순서;


-- 임시 테이블 정리
DROP TABLE #GEN_YYYYMM;
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	   SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
