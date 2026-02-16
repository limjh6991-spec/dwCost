CREATE       PROCEDURE DOI_PL_ByModel
(
    @YYYYMM VARCHAR(6),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

       	DECLARE @PivotColumns NVARCHAR(MAX);
        DECLARE @Columns     VARCHAR(3000);
        DECLARE @SQL         NVARCHAR(MAX);
       	DECLARE @SCOFTotal DECIMAL(18,2) = 0;

        ----------------------------------------------------------------------
        -- 1. 모델 목록 (#MODEL)
        ----------------------------------------------------------------------
		;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SEL_CODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),
		MODEL_LIST AS (
		    -- 국내(매출)
		    SELECT DISTINCT
		        CASE 
		          WHEN A.품번 LIKE N'VN%' THEN N'카세트'
		          WHEN MI.품번 IS NOT NULL THEN N'구매'
		          WHEN RIGHT(A.품번,1)='P' THEN N'양산'
		          ELSE N'개발'
		        END AS 구분,
		        A.품명 AS model
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		      AND A.SITE   = @SITE
		
		    UNION
		
		    -- 해외(인보이스)
		    SELECT DISTINCT
		        CASE 
		          WHEN B.품번 LIKE N'VN%' THEN N'카세트'
		          WHEN MI.품번 IS NOT NULL THEN N'구매'
		          WHEN RIGHT(B.품번,1)='P' THEN N'양산'
		          ELSE N'개발'
		        END AS 구분,
		        B.품명 AS model
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		)
		SELECT DISTINCT
		    model, 구분
		INTO #MODEL
		FROM MODEL_LIST;

		SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
		FROM DOI_SCOF WITH(NOLOCK)
		WHERE yyyymm   = @YYYYMM
		  AND site     = @SITE
		  AND SEL_CODE = @SEL_CODE;

		 ;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SEL_CODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),
        ----------------------------------------------------------------------
        -- 2~5. 연간 매출 / 매출원가 / 판관비
        ----------------------------------------------------------------------
        SALES_RAW AS (
            ------------------------------------------------------------------
            -- (1) 매출 : 국내/해외
            ------------------------------------------------------------------
		    -- 국내매출
		    SELECT
		          A.SITE
		        , CASE 
			          WHEN A.품번 LIKE N'VN%' THEN N'카세트'
			          WHEN MI.품번 IS NOT NULL THEN N'구매'
			          WHEN RIGHT(A.품번,1)='P' THEN N'양산'
		          	ELSE N'개발'
		          END AS 구분
		        , A.품번
		        , A.품명          AS model
		        , N'국내'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , A.원화판매금액   AS amt
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		      AND A.SITE   = @SITE
		
		    UNION ALL
		
		    -- 해외매출
		    SELECT
		          B.SITE
		        , CASE 
			          WHEN B.품번 LIKE N'VN%' THEN N'카세트'
			          WHEN MI.품번 IS NOT NULL THEN N'구매'
			          WHEN RIGHT(B.품번,1)='P' THEN N'양산'
		          	ELSE N'개발'
		          END AS 구분
		        , B.품번
		        , B.품명          AS model
		        , N'해외'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , B.원화판매금액   AS amt
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		
		    UNION ALL
		
		    -- 기타매출(원천이 DOI_SLCO면 품번이 없으니 별도 라벨)
		    SELECT
		          S.SITE
				, S.구분 AS 구분
		        , NULL AS 품번
		        , S.model
		        , N'*' AS 매출구분
		        , N'기타' AS 매출대분류
		        , ISNULL(S.out_amt,0) AS amt
		    FROM DOI_SLCO S WITH(NOLOCK)
		    WHERE S.YYYYMM = @YYYYMM
		      AND S.SITE   = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.expen_sel명 = N'기타매출'
        )
        , SALES_BASE AS (
            ------------------------------------------------------------------
            -- (2) 모델별 매출 집계
            ------------------------------------------------------------------
            SELECT
		          구분
		        , model
		        , SUM(CASE WHEN 매출대분류 = N'제품' THEN amt ELSE 0 END) AS prod_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'상품' THEN amt ELSE 0 END) AS merch_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'기타' THEN amt ELSE 0 END) AS etc_sale_amt
		        , SUM(amt) AS total_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'국내' THEN amt ELSE 0 END) AS domestic_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'해외' THEN amt ELSE 0 END) AS export_sale_amt
		    FROM SALES_RAW
		    GROUP BY 구분, model
        )
		, MERCH_SALES AS (
		    SELECT
		          S.구분
		        , S.model
		        , SUM(S.amt) AS merch_sale_amt
		    FROM SALES_RAW S
		    INNER JOIN DOI_MATL_RESC M WITH(NOLOCK)
		      ON M.YYYYMM = @YYYYMM
		     AND M.SITE   = @SITE
		     AND M.SEL_CODE = @SEL_CODE
		     AND M.품목자산분류 = N'상품'
		     AND M.품번 = S.품번
		    WHERE S.품번 IS NOT NULL
		    GROUP BY S.구분, S.model
		)
		, MERCH_SALES_SUM AS (
		    SELECT SUM(merch_sale_amt) AS merch_sale_total
		    FROM MERCH_SALES
		)
		, MERCH_COGS_TOTAL AS (
		    SELECT SUM(ISNULL(출고금액,0)) AS merch_cogs_total
		    FROM DOI_MATL_RESC WITH(NOLOCK)
		    WHERE YYYYMM = @YYYYMM
		      AND SITE   = @SITE
		      AND SEL_CODE = @SEL_CODE
		      AND 품목자산분류 = N'상품'
		)
		, MERCH_COGS_ALLOC AS (
		    SELECT
		          MS.구분
		        , MS.model
		        , CASE
		            WHEN MSS.merch_sale_total = 0 THEN 0
		            ELSE MCT.merch_cogs_total * (MS.merch_sale_amt / MSS.merch_sale_total)
		          END AS merch_cogs_amt
		    FROM MERCH_SALES MS
		    CROSS JOIN MERCH_SALES_SUM MSS
		    CROSS JOIN MERCH_COGS_TOTAL MCT
		)        
		, STCO_BASE AS (
		    SELECT
		        S.구분 AS 구분
		        , S.MODEL AS model
		        , SUM(ISNULL(S.BOH_AMT, 0)) AS begin_fg_amt
		        , SUM(ISNULL(S.IN_AMT, 0))  AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , SUM(ISNULL(S.EOH_AMT, 0)) AS end_fg_amt
		        , SUM(S.out_amt) AS prod_cogs_amt
		    FROM DOI_STCO S
		    WHERE S.YYYYMM   = @YYYYMM
		      AND S.SITE     = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		    GROUP BY S.구분, S.MODEL
		)
		, COGS_BASE AS (
		    -- 1) STCO 있는 모델: 상품원가 붙이기
		    SELECT
		          S.구분
		        , S.model
		        , S.begin_fg_amt
		        , S.cur_mfg_cost_amt
		        , S.trans_out_amt
		        , S.end_fg_amt
		        , ISNULL(MCA.merch_cogs_amt,0) AS merch_cogs_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS merch_purchase_amt
		        , S.prod_cogs_amt
		    FROM STCO_BASE S
		    LEFT JOIN MERCH_COGS_ALLOC MCA
		      ON MCA.구분  = S.구분
		     AND MCA.model = S.model
		
		    UNION ALL
		
		    -- 2) STCO 없는 모델(상품만 판매된 품명): 행을 새로 만들어서 상품원가만 넣기
		    SELECT
		          MCA.구분
		        , MCA.model
		        , CAST(0 AS DECIMAL(18,2)) AS begin_fg_amt
		        , CAST(0 AS DECIMAL(18,2)) AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , CAST(0 AS DECIMAL(18,2)) AS end_fg_amt
		        , ISNULL(MCA.merch_cogs_amt,0) AS merch_cogs_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS merch_purchase_amt
		        , CAST(0 AS DECIMAL(18,2)) AS prod_cogs_amt
		    FROM MERCH_COGS_ALLOC MCA
		    WHERE NOT EXISTS (
		        SELECT 1
		        FROM STCO_BASE S
		        WHERE S.구분 = MCA.구분
		    AND S.model = MCA.model
		    )
		)
		, COGS_ADJ AS (
		    SELECT
		        a.구분 AS 구분
		        , a.model
		        , SUM(a.out_amt) AS adj_amt
		    FROM DOI_SLCO a WITH(NOLOCK)
		    WHERE a.YYYYMM = @YYYYMM
		      AND a.SITE   = @SITE
		      AND a.SEL_CODE = @SEL_CODE
		      AND a.expen_sel명 = N'기타매출'
		    GROUP BY a.구분, a.model
		)                
        , SGNA_BASE AS (
            ------------------------------------------------------------------
            -- (4) 판관비
            ------------------------------------------------------------------
            SELECT
            	구분
                , MODEL           AS model
                , SUB_NAME
                , SUM(ISNULL(DIST_AMT,0)) AS amt      -- 배부된 판관비 금액
            FROM DOI_SMCE_COST
            WHERE YYYYMM 	= @YYYYMM
              AND SITE 		= @SITE
              AND SEL_CODE  = @SEL_CODE 
            GROUP BY 구분, MODEL, SUB_NAME
        )
        , SGNA_SUM AS (
            ------------------------------------------------------------------
            -- (5) 모델별 판관비 합계
            ------------------------------------------------------------------
            SELECT
                  구분, model
                , SUM(amt) AS sgna_amt
            FROM SGNA_BASE
            GROUP BY 구분, model
        )

        ----------------------------------------------------------------------
        -- 6. PL 헤더(I~III, IV 합계, V 영업이익) : PL_HEAD
        ----------------------------------------------------------------------
        , PL_HEAD AS (
            ------------------------------------------------------------------
            --  I. 매출액
            ------------------------------------------------------------------
            SELECT 1 rn, '  I. 매출액' AS gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) amt FROM #MODEL M 
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
            UNION ALL
            SELECT 2 rn, '    (1) 제품매출' gubun, M.구분, M.model, ISNULL(S.prod_sale_amt,0) FROM #MODEL M 
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
            UNION ALL
            SELECT 3 rn, '    (2) 유상사급' gubun, M.구분, M.model, CAST(0 AS DECIMAL(18,2)) AS amt FROM #MODEL M 
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
            UNION ALL
            SELECT 4 rn, '    (3) 상품매출' gubun, M.구분, M.model, ISNULL(S.merch_sale_amt,0) FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분

            ------------------------------------------------------------------
            --  II. 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 5 rn, '  II. 매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) amt FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            UNION ALL
            SELECT 6 rn, '    (1) 제품매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0)  + ISNULL(A.adj_amt,0) AS amt FROM #MODEL M 
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분 and C.구분 = M.구분
            LEFT JOIN COGS_ADJ  A ON A.model = M.model AND A.구분 = M.구분
/*            UNION ALL
          SELECT 7 rn, '      1. 기초제품재고액' gubun, M.구분, M.model, ISNULL(C.begin_fg_amt,0) FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            UNION ALL
            SELECT 8 rn, '      2. 당기제품제조원가' gubun, M.구분, M.model, ISNULL(C.cur_mfg_cost_amt,0) FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            UNION ALL
            SELECT 9 rn, '      3. 타계정으로제품대체액' gubun, M.구분, M.model, C.trans_out_amt FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            UNION ALL
            SELECT 10 rn, '      4. 기말제품재고액' gubun,  M.구분, M.model, ISNULL(C.end_fg_amt,0) FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분*/
            UNION ALL
            SELECT 11 rn, '    (2) 상품매출원가' gubun, M.구분, M.model, C.merch_cogs_amt FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            /*UNION ALL
            SELECT 12 rn, '      1. 당기상품매입액' gubun, M.구분, M.model, C.merch_purchase_amt FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분*/

            ------------------------------------------------------------------
            --  III. 매출총이익 = 매출액 - 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 13 rn, '  III. 매출총이익' gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) )  AS amt FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
			LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            ------------------------------------------------------------------
            --  IV. 판매비와관리비 (전체 합계)
            ------------------------------------------------------------------
            UNION ALL
            SELECT 14 rn, '  IV. 판매비와관리비' gubun, M.구분, M.model, ISNULL(G.sgna_amt,0) AS amt FROM #MODEL M
            LEFT JOIN SGNA_SUM G ON G.model = M.model and G.구분 = M.구분
            ------------------------------------------------------------------
            --  V. 영업이익 = 매출총이익 - 판관비
            ------------------------------------------------------------------
            UNION ALL
            SELECT 141 rn, '  V. 영업이익'+ REPLICATE(NCHAR(0x3000), 7) gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) ) - ISNULL(G.sgna_amt,0) amt FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            LEFT JOIN SGNA_SUM G ON G.model = M.model and G.구분 = M.구분
        )

        ----------------------------------------------------------------------
        -- 7. 판관비 세부 항목(이미지 기준 풀버전) : PL_SGNA
        ----------------------------------------------------------------------
        , PL_SGNA AS (
            SELECT 15 rn, '    (1) 판)임원급여' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)급여-임원' GROUP BY 구분, model
            UNION ALL
/*            SELECT 16 rn, '      1. 판)급여-임원' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)급여-임원' GROUP BY 구분, model
            UNION ALL*/
            SELECT 17 rn, '    (2) 판)직원급여' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)급여-직원' GROUP BY 구분, model
            UNION ALL
/*            SELECT 18 rn, '      1. 판)급여-직원' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)급여-직원' GROUP BY 구분, model
            UNION ALL*/
            SELECT 19 rn, '    (3) 판)상여금' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)상여금-직원' GROUP BY 구분, model
            UNION ALL
/*            SELECT 20 rn, '      1. 판)상여금-직원' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)상여금-직원' GROUP BY 구분, model
            UNION ALL*/
            SELECT 21 rn, '    (4) 판)제수당' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)제수당-연차', '판)제수당-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 22 rn, '      1. 판)제수당-연차' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)제수당-연차' GROUP BY 구분, model
            UNION ALL
            SELECT 23 rn, '      2. 판)제수당-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)제수당-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 24 rn, '    (5) 판)퇴직급여' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)퇴직급여-임원', '판)퇴직급여-직원') GROUP BY 구분, model
            UNION ALL
/*            SELECT 25 rn, '      1. 판)퇴직급여-임원' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)퇴직급여-임원' GROUP BY 구분, model
            UNION ALL
            SELECT 26 rn, '      2. 판)퇴직급여-직원' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)퇴직급여-직원' GROUP BY 구분, model
            UNION ALL*/
            SELECT 27 rn, '    (6) 판)복리후생비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE  WHERE SUB_NAME IN ('판)복리후생비-건강,장기요양보험', '판)복리후생비-사내식대', '판)복리후생비-외부식대등', '판)복리후생비-경조사비', '판)복리후생비-일반', '판)복리후생비-의료')  GROUP BY 구분, model
            UNION ALL
/*            SELECT 28 rn, '      1. 판)복리후생비-건강,장기요양보험' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)복리후생비-건강,장기요양보험' GROUP BY 구분, model
            UNION ALL
            SELECT 29 rn, '      2. 판)복리후생비-사내식대' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)복리후생비-사내식대' GROUP BY 구분, model
            UNION ALL
    		SELECT 30 rn, '      3. 판)복리후생비-외부식대등' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE  WHERE SUB_NAME = '판)복리후생비-외부식대등' GROUP BY 구분, model
            UNION ALL
            SELECT 31 rn, '      4. 판)복리후생비-경조사비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)복리후생비-경조사비' GROUP BY 구분, model
            UNION ALL
            SELECT 32 rn, '      5. 판)복리후생비-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)복리후생비-일반' GROUP BY 구분, model
            UNION ALL
            SELECT 33 rn, '      6. 판)복리후생비-의료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)복리후생비-의료' GROUP BY 구분, model
            UNION ALL*/
            SELECT 34 rn, '    (7) 판)여비교통비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)여비교통비-국내출장경비(법인)', '판)여비교통비-국내출장경비(기타)', '판)여비교통비-해외출장경비', '판)여비교통비-기타') GROUP BY 구분, model
            UNION ALL
/*            SELECT 35 rn, '      1. 판)여비교통비-국내출장경비(법인)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)여비교통비-국내출장경비(법인)' GROUP BY 구분, model
            UNION ALL
            SELECT 36 rn, '      2. 판)여비교통비-국내출장경비(기타)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)여비교통비-국내출장경비(기타)' GROUP BY 구분, model
            UNION ALL
            SELECT 37 rn, '      3. 판)여비교통비-해외출장경비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)여비교통비-해외출장경비' GROUP BY 구분, model
            UNION ALL
            SELECT 38 rn, '      4. 판)여비교통비-기타' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)여비교통비-기타' GROUP BY 구분, model
            UNION ALL*/
            SELECT 39 rn, '    (8) 판)접대비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)접대비-식대', '판)접대비-경조금', '판)접대비-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 40 rn, '      1. 판)접대비-식대' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)접대비-식대' GROUP BY 구분, model
            UNION ALL
            SELECT 41 rn, '      2. 판)접대비-경조금' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)접대비-경조금' GROUP BY 구분, model
            UNION ALL
            SELECT 42 rn, '      3. 판)접대비-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)접대비-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 43 rn, '    (9) 판)통신비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)통신비' GROUP BY 구분, model
            UNION ALL
/*            SELECT 44 rn, '      1. 판)통신비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)통신비' GROUP BY 구분, model
            UNION ALL*/
            SELECT 45 rn, '    (10) 판)수도광열비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)수도광열비-수도료' GROUP BY 구분, model
            UNION ALL
/*            SELECT 46, '      1. 판)수도광열비-수도료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)수도광열비-수도료' GROUP BY 구분, model
            UNION ALL*/
            SELECT 47 rn, '    (11) 판)세금과공과' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE
            WHERE SUB_NAME IN ('판)세금과공과-연금보험', '판)세금과공과-사업소세', '판)세금과공과-재산세종부세', '판)세금과공과-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 48 rn, '      1. 판)세금과공과-연금보험' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)세금과공과-연금보험' GROUP BY 구분, model
   UNION ALL
            SELECT 49 rn, '      2. 판)세금과공과-사업소세' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)세금과공과-사업소세' GROUP BY 구분, model
UNION ALL
           SELECT 50 rn, '      3. 판)세금과공과-재산세종부세' gubun, 구분, model, SUM(amt) AS amt FROM SGNA_BASE WHERE SUB_NAME = '판)세금과공과-재산세종부세' GROUP BY 구분, model
            UNION ALL
            SELECT 51 rn, '      4. 판)세금과공과-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)세금과공과-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 52 rn, '    (12) 판)감가상각비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE
    		WHERE SUB_NAME IN ('판)감가상각비-건물', '판)감가상각비-기계장치', '판)감가상각비-차량운반구', '판)감가상각비-비품', '판)감가상각비-시설장치' ) GROUP BY 구분, model
            UNION ALL
/*            SELECT 53 rn, '      1. 판)감가상각비-건물' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)감가상각비-건물' GROUP BY 구분, model
            UNION ALL
            SELECT 54 rn, '      2. 판)감가상각비-기계장치' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)감가상각비-기계장치' GROUP BY 구분, model
            UNION ALL
       		SELECT 55 rn, '      3. 판)감가상각비-차량운반구' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)감가상각비-차량운반구' GROUP BY 구분, model
            UNION ALL
            SELECT 56 rn, '      4. 판)감가상각비-비품' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)감가상각비-비품' GROUP BY 구분, model
            UNION ALL
            SELECT 57 rn, '      5. 판)감가상각비-시설장치' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)감가상각비-시설장치' GROUP BY 구분, model
            UNION ALL*/
            SELECT 58 rn, '    (13) 판)지급임차료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)지급임차료-건물', '판)지급임차료-차량', '판)지급임차료-비품', '판)지급임차료-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 59 rn, '      1. 판)지급임차료-건물' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급임차료-건물' GROUP BY 구분, model
            UNION ALL
            SELECT 60 rn, '      2. 판)지급임차료-차량' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급임차료-차량' GROUP BY 구분, model
            UNION ALL
            SELECT 61 rn, '      3. 판)지급임차료-비품' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급임차료-비품' GROUP BY 구분, model
            UNION ALL
            SELECT 62 rn, '      4. 판)지급임차료-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급임차료-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 63 rn, '    (14) 판)수선비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)수선비' GROUP BY 구분, model
            UNION ALL
/*            SELECT 64 rn, '      1. 판)수선비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)수선비' GROUP BY 구분, model
            UNION ALL*/
            SELECT 65 rn, '    (15) 판)보험료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE  WHERE SUB_NAME IN ('판)보험료-산재.고용보험', '판)보험료-차량', '판)보험료-건물', '판)보험료-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 66 rn, '      1. 판)보험료-산재.고용보험' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)보험료-산재.고용보험' GROUP BY 구분, model
     UNION ALL
            SELECT 67 rn, '      2. 판)보험료-차량' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)보험료-차량' GROUP BY 구분, model
            UNION ALL
            SELECT 68 rn, '      3. 판)보험료-건물' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)보험료-건물' GROUP BY 구분, model
            UNION ALL
            SELECT 69 rn, '      4. 판)보험료-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)보험료-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 70 rn, '    (16) 판)차량유지비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)차량유지비-유류비', '판)차량유지비-관리비', '판)차량유지비-일반', '판)차량유지비-자동차세') GROUP BY 구분, model
UNION ALL
/*            SELECT 71 rn, '      1. 판)차량유지비-유류비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)차량유지비-유류비' GROUP BY 구분, model
            UNION ALL
            SELECT 72 rn, '      2. 판)차량유지비-관리비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)차량유지비-관리비' GROUP BY 구분, model
            UNION ALL
            SELECT 73 rn, '      3. 판)차량유지비-일반' gubun, 구분, model, SUM(amt) AS amt FROM SGNA_BASE WHERE SUB_NAME = '판)차량유지비-일반' GROUP BY 구분, model
            UNION ALL
            SELECT 74 rn, '      4. 판)차량유지비-자동차세' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)차량유지비-자동차세' GROUP BY 구분, model
            UNION ALL*/
            SELECT 75 rn, '    (17) 판)경상연구개발비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE
            WHERE SUB_NAME IN ('판)경상연구개발비-일반', '판)경상연구개발비-개발소모품', '판)경상연구개발비-지급수수료', '판)경상연구개발비-국내출장경비(법인)', '판)경상연구개발비-국내출장경비(기타)', '판)경상연구개발비-해외출장경비', 
            '판)경상연구개발비-해외출장경비(여비)', '판)경상연구개발비-사내식대', '판)경상연구개발비-외부식대등', '판)경상연구개발비-경조사비', '판)경상연구개발비(차량유지비-유류비)', '판)경상연구개발비(차량유지비-보험료)', '판)경상연구개발비(차량유지비-관리비)', 
            '판)경상연구개발비(차량유지비-일반)', '판)경상연구개발비(차량유지비-자동차세)', '판)경상연구개발비(급여-임원)', '판)경상연구개발비(급여-직원)', '판)경상연구개발비(상여금-직원)', '판)경상연구개발비(제수당-연차)', '판)경상연구개발비(제수당-일반)', 
            '판)경상연구개발비(잡급)', '판)경상연구개발비(퇴직급여-임원)', '판)경상연구개발비(퇴직급여-직원)', '판)경상연구개발비-건강,장기요양보험', '판)경상연구개발비-연금보험', '판)경상연구개발비-산재.고용보험', '판)경상연구개발비(지급임차료-건물)', 
            '판)경상연구개발비(지급임차료-일반)', '판)경상연구개발비(지급임차료-차량)', '판)경상연구개발비-특허.심사료') GROUP BY 구분, model
            UNION ALL
/*            SELECT 76 rn, '      1. 판)경상연구개발비-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-일반' GROUP BY 구분, model
            UNION ALL
            SELECT 77 rn, '      2. 판)경상연구개발비-개발소모품' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-개발소모품' GROUP BY 구분, model
            UNION ALL
            SELECT 78 rn, '      3. 판)경상연구개발비-지급수수료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-지급수수료' GROUP BY 구분, model
            UNION ALL
            SELECT 79 rn, '      4. 판)경상연구개발비-국내출장경비(법인)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-국내출장경비(법인)' GROUP BY 구분, model
            UNION ALL
            SELECT 80 rn, '      5. 판)경상연구개발비-국내출장경비(기타)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-국내출장경비(기타)' GROUP BY 구분, model
            UNION ALL
            SELECT 81 rn, '      6. 판)경상연구개발비-해외출장경비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-해외출장경비' GROUP BY 구분, model
            UNION ALL
            SELECT 82 rn, '      7. 판)경상연구개발비-해외출장경비(여비)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-해외출장경비(여비)' GROUP BY 구분, model
            UNION ALL
            SELECT 83 rn, '      8. 판)경상연구개발비-사내식대' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-사내식대' GROUP BY 구분, model
            UNION ALL
            SELECT 84 rn, '      9. 판)경상연구개발비-외부식대등' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-외부식대등' GROUP BY 구분, model
            UNION ALL
            SELECT 85 rn, '     10. 판)경상연구개발비-경조사비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-경조사비' GROUP BY 구분, model
            UNION ALL
            SELECT 86 rn, '     11. 판)경상연구개발비(차량유지비-유류비)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(차량유지비-유류비)' GROUP BY 구분, model
            UNION ALL
            SELECT 87 rn, '     12. 판)경상연구개발비(차량유지비-보험료)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(차량유지비-보험료)' GROUP BY 구분, model
            UNION ALL
            SELECT 88 rn, '     13. 판)경상연구개발비(차량유지비-관리비)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(차량유지비-관리비)' GROUP BY 구분, model
            UNION ALL
            SELECT 89 rn, '     14. 판)경상연구개발비(차량유지비-일반)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(차량유지비-일반)' GROUP BY 구분, model
            UNION ALL
            SELECT 90 rn, '     15. 판)경상연구개발비(차량유지비-자동차세)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(차량유지비-자동차세)' GROUP BY 구분, model
            UNION ALL
 SELECT 91 rn, '     16. 판)경상연구개발비(급여-임원)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(급여-임원)' GROUP BY 구분, model
            UNION ALL
            SELECT 92 rn, '     17. 판)경상연구개발비(급여-직원)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(급여-직원)' GROUP BY 구분, model
            UNION ALL
            SELECT 93 rn, '     18. 판)경상연구개발비(상여금-직원)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(상여금-직원)' GROUP BY 구분, model
   			UNION ALL
   			SELECT 94 rn, '     19. 판)경상연구개발비(제수당-연차)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(제수당-연차)' GROUP BY 구분, model
            UNION ALL
            SELECT 95 rn, '     20. 판)경상연구개발비(제수당-일반)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(제수당-일반)' GROUP BY 구분, model
            UNION ALL
            SELECT 96 rn, '     21. 판)경상연구개발비(잡급)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(잡급)' GROUP BY 구분, model
            UNION ALL
            SELECT 97 rn, '     22. 판)경상연구개발비(퇴직급여-임원)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(퇴직급여-임원)' GROUP BY 구분, model
            UNION ALL
            SELECT 98 rn, '     23. 판)경상연구개발비(퇴직급여-직원)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(퇴직급여-직원)' GROUP BY 구분, model
            UNION ALL
            SELECT 99 rn, '     24. 판)경상연구개발비-건강,장기요양보험' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-건강,장기요양보험' GROUP BY 구분, model
            UNION ALL
            SELECT 100 rn, '     25. 판)경상연구개발비-연금보험' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-연금보험' GROUP BY 구분, model
            UNION ALL
            SELECT 101 rn, '    26. 판)경상연구개발비-산재.고용보험' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-산재.고용보험' GROUP BY 구분, model
            UNION ALL
            SELECT 102 rn, '    27. 판)경상연구개발비(지급임차료-건물)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(지급임차료-건물)' GROUP BY 구분, model
            UNION ALL
            SELECT 103 rn, '    28. 판)경상연구개발비(지급임차료-일반)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(지급임차료-일반)' GROUP BY 구분, model
            UNION ALL
            SELECT 104 rn, '    29. 판)경상연구개발비(지급임차료-차량)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비(지급임차료-차량)' GROUP BY 구분, model
            UNION ALL
            SELECT 105 rn, '    30. 판)경상연구개발비-특허.심사료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)경상연구개발비-특허.심사료' GROUP BY 구분, model
            UNION ALL*/
            SELECT 106 rn, '    (18) 판)운반비' gubun, 구분, model, SUM(amt)amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)운반비-국내운송료', '판)운반비-해외운송료') GROUP BY 구분, model
            UNION ALL
/*            SELECT 107 rn, '      1. 판)운반비-국내운송료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)운반비-국내운송료' GROUP BY 구분, model
            UNION ALL
            SELECT 108 rn, '      2. 판)운반비-해외운송료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)운반비-해외운송료' GROUP BY 구분, model
            UNION ALL*/
            SELECT 109 rn, '    (19) 판)교육훈련비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)교육훈련비-사외' GROUP BY 구분, model
            UNION ALL
/*            SELECT 110 rn, '      1. 판)교육훈련비-사외' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)교육훈련비-사외' GROUP BY 구분, model
            UNION ALL*/
            SELECT 111 rn, '    (20) 판)도서인쇄비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)도서인쇄비' GROUP BY 구분, model
     UNION ALL
/*            SELECT 112 rn, '      1. 판)도서인쇄비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)도서인쇄비' GROUP BY 구분, model
            UNION ALL*/
            SELECT 113 rn, '    (21) 판)소모품비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)소모품비-비품', '판)소모품비-사무용품', '판)소모품비-전산용품', '판)소모품비-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 114 rn, '      1. 판)소모품비-비품' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)소모품비-비품' GROUP BY 구분, model
            UNION ALL
            SELECT 115 rn, '      2. 판)소모품비-사무용품' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)소모품비-사무용품' GROUP BY 구분, model
            UNION ALL
            SELECT 116 rn, '      3. 판)소모품비-전산용품' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)소모품비-전산용품' GROUP BY 구분, model
            UNION ALL
            SELECT 117 rn, '      4. 판)소모품비-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)소모품비-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 118 rn, '    (22) 판)지급수수료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)지급수수료-건물관리비', '판)지급수수료-보안용역료', '판)지급수수료-유지보수료', '판)지급수수료-금융.제증명', 
            '판)지급수수료-감사.법률.자문', '판)지급수수료-특허.심사료', '판)지급수수료-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 119 rn, '      1. 판)지급수수료-건물관리비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-건물관리비' GROUP BY 구분, model
            UNION ALL
            SELECT 120 rn, '      2. 판)지급수수료-보안용역료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-보안용역료' GROUP BY 구분, model
            UNION ALL
            SELECT 121 rn, '      3. 판)지급수수료-유지보수료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-유지보수료' GROUP BY 구분, model
            UNION ALL
            SELECT 122 rn, '      4. 판)지급수수료-금융.제증명' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-금융.제증명' GROUP BY 구분, model
            UNION ALL
            SELECT 123 rn, '      5. 판)지급수수료-감사.법률.자문' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-감사.법률.자문' GROUP BY 구분, model
            UNION ALL
            SELECT 124 rn, '      6. 판)지급수수료-특허.심사료' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-특허.심사료' GROUP BY 구분, model
            UNION ALL
            SELECT 125 rn, '      7. 판)지급수수료-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)지급수수료-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 126 rn, '    (23) 판)광고선전비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)광고선전비-IR', '판)광고선전비-일반') GROUP BY 구분, model
            UNION ALL
/*            SELECT 127 rn, '      1. 판)광고선전비-IR' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)광고선전비-IR' GROUP BY 구분, model
            UNION ALL
            SELECT 128 rn, '      2. 판)광고선전비-일반' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)광고선전비-일반' GROUP BY 구분, model
            UNION ALL*/
            SELECT 129 rn, '    (24) 판)무형자산상각비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)무형자산상각비' GROUP BY 구분, model
            UNION ALL
/*            SELECT 130 rn, '  1. 판)무형자산상각비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)무형자산상각비' GROUP BY 구분, model
            UNION ALL*/
            SELECT 131 rn, '    (25) 판)견본비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)견본비' GROUP BY 구분, model
            UNION ALL
/*            SELECT 132 rn, '      1. 판)견본비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)견본비' GROUP BY 구분, model
            UNION ALL*/
            SELECT 133 rn, '    (26) 판)사용권자산감가상각비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)사용권자산감가상각비-건물', '판)사용권자산감가상각비-차량') GROUP BY 구분, model
            UNION ALL
/*            SELECT 134 rn, '      1. 판)사용권자산상각비-건물' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)사용권자산상각비-건물' GROUP BY 구분, model
            UNION ALL
SELECT 135 rn, '      2. 판)사용권자산상각비-차량' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)사용권자산상각비-차량' GROUP BY 구분, model
           UNION ALL*/
            SELECT 136 rn, '    (27) 판)주식보상비용' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)주식보상비용' GROUP BY 구분, model
            UNION ALL
/*            SELECT 137 rn, '      1. 판)주식보상비용' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE 
            WHERE SUB_NAME = '판)주식보상비용' GROUP BY 구분, model
            UNION ALL*/
            SELECT 138 rn, '    (28) 판)해외시장개척비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME IN ('판)해외시장개척비', '판)해외시장개척비(여비)') GROUP BY 구분, model
/*       		UNION ALL
     		SELECT 139 rn, '  1. 판)해외시장개척비' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)해외시장개척비' GROUP BY 구분, model
            UNION ALL
            SELECT 140 rn, '      2. 판)해외시장개척비(여비)' gubun, 구분, model, SUM(amt) amt FROM SGNA_BASE WHERE SUB_NAME = '판)해외시장개척비(여비)' GROUP BY 구분, model*/
        )

        ----------------------------------------------------------------------
        -- 8. PL_HEAD + PL_SGNA 통합 소스 : PL_SOURCE
        ----------------------------------------------------------------------
        , PL_SOURCE AS (
            SELECT rn, gubun, 구분, model, amt
            FROM PL_HEAD

            UNION ALL

            SELECT rn, gubun, 구분, model, amt
            FROM PL_SGNA
        )

        ----------------------------------------------------------------------
        -- 9. PL_SOURCE → #sourceTable
        ----------------------------------------------------------------------
        SELECT
        	구분
            , model
            , rn
            , gubun
            , amt
        INTO #sourceTable
        FROM PL_SOURCE;
       
        ----------------------------------------------------------------------
        -- 10. Z합계 행 추가
        ----------------------------------------------------------------------
        INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
        SELECT
        	'' as 구분
            ,  N'Z합계' AS model
            , rn
		    , gubun
            , SUM(amt) AS amt
        FROM #sourceTable
        GROUP BY rn, gubun;

       -- 개발 모델 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'개발' AS 구분,
		    N'Z합계개발' AS model,
		    rn,
		    gubun,
		    SUM(amt) AS amt
		FROM #sourceTable
		WHERE 구분 = N'개발'
		GROUP BY rn, 구분, gubun;
		
		-- 양산 모델 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'양산' AS 구분,
		    N'Z합계양산' AS model,
		    rn,
		    gubun,
		    SUM(amt) AS amt
		FROM #sourceTable
		WHERE 구분 = N'양산'
		GROUP BY rn, 구분, gubun;
	
		-- 카세트 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'카세트',
		    N'Z합계카세트',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'카세트'
		GROUP BY rn, gubun;
		
		-- 구매 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'구매',
		    N'Z합계구매',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'구매'
		GROUP BY rn, gubun;	
	
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		VALUES (N'', N'Z합계', 3, N'    (2) 유상사급', @SCOFTotal);
	
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) - @SCOFTotal
		WHERE model = N'Z합계'
		  AND rn    = 1
		  AND gubun = N'  I. 매출액';
       
        ----------------------------------------------------------------------
        -- 11. PIVOT용 컬럼
        ----------------------------------------------------------------------
		;WITH COLS AS (
		    SELECT DISTINCT
		        sort_key = CASE 
		                     WHEN 구분 = N'양산'   THEN 10
		                     WHEN 구분 = N'개발'   THEN 20
		                     WHEN 구분 = N'카세트' THEN 30
		                     WHEN 구분 = N'구매'   THEN 40
		                     ELSE 99
		                   END,
		        model_sort = model,
		        col_name = 구분 + model
		    FROM #MODEL
		
		    UNION ALL SELECT 910, N'ZZZ', N'양산Z합계양산'
		    UNION ALL SELECT 920, N'ZZZ', N'개발Z합계개발'
		    UNION ALL SELECT 930, N'ZZZ', N'카세트Z합계카세트'
		    UNION ALL SELECT 940, N'ZZZ', N'구매Z합계구매'
		    UNION ALL SELECT 999, N'ZZZ', N'Z합계'
		)
		SELECT
		    @Columns = STRING_AGG(QUOTENAME(col_name), N', ')
		              WITHIN GROUP (ORDER BY sort_key, model_sort, col_name),
		    @PivotColumns = STRING_AGG(
		                      N'COALESCE(' + QUOTENAME(col_name) + N',0) AS ' + QUOTENAME(col_name),
		                      N', '
		                   )
		                   WITHIN GROUP (ORDER BY sort_key, model_sort, col_name)
		FROM COLS;
        
        ----------------------------------------------------------------------
        -- 12. 동적 PIVOT 실행
        ----------------------------------------------------------------------
        SET @SQL = N'
            SELECT 
                P.rn,
                P.gubun,
                ' + @PivotColumns + '
            FROM (
                SELECT rn, gubun, 구분+model as model, amt
                FROM #sourceTable
         ) AS S
            PIVOT (
                SUM(amt) FOR model IN (' + @Columns + ')
            ) AS P
            ORDER BY P.rn;
        ';
		print @SQL;
        EXEC sp_executesql @SQL;


        DROP TABLE #sourceTable;
        DROP TABLE #MODEL;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
     IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
