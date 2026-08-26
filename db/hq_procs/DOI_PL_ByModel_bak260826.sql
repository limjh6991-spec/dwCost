CREATE OR ALTER PROCEDURE DOI_PL_ByModel --운영
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
		DECLARE @CostAdj     DECIMAL(18,2) = 0;
		DECLARE @LossAdj     DECIMAL(18,2) = 0;
		DECLARE @SCOF_ACC    DECIMAL(18,2) = 0;   -- 회계-조정 유상사급 (DOI_원장상계 구분='회계')

       	DROP TABLE IF EXISTS #MODEL;

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
		      
		 UNION
		 
		 SELECT C.구분, C.MODEL
		 FROM DOI_STCO C
		    WHERE C.YYYYMM = @YYYYMM
		      AND C.SITE   = @SITE
		      AND C.SEL_CODE = @SEL_CODE
		      AND C.MODEL = 'EXTRA'
		UNION 
		SELECT 구분, MODEL
		FROM DOI_STCO
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND ACCT_NAME LIKE '기타출고'
		
		UNION
		
		SELECT
			CASE WHEN O.모델 = N'회계-조정' THEN N'회계' ELSE O.구분 END AS 구분, CASE WHEN O.모델 = N'회계-조정' THEN O.모델 ELSE LEFT(O.모델, LEN(O.모델)-1) END AS model
		FROM DOI_원장상계 O
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND COALESCE(O.매출상계,0) <> 0
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

		SELECT @CostAdj = COALESCE(ABS(SUM(ISNULL(대변금액,0))), 0)
		FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE
		  AND 계정과목 = N'제품매출원가'
		  AND 대변금액 <> 0;		 
		 
		SELECT @LossAdj = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE;

		SELECT @SCOF_ACC = CAST(COALESCE(SUM(매출상계),0) AS DECIMAL(18,2))
		FROM DOI_원장상계 WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE AND 구분 = N'회계';
		 
		DROP TABLE IF EXISTS #sourceTable;
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
		
		    /*UNION ALL
		
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
		      AND S.expen_sel명 = N'기타매출'*/
        )
        , SALES_BASE AS (
            ------------------------------------------------------------------
            -- (2) 모델별 매출 집계
            ------------------------------------------------------------------
            SELECT
		          구분
		        , model, 매출대분류
		        , SUM(CASE WHEN 매출대분류 = N'제품' THEN amt ELSE 0 END) AS prod_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'상품' THEN amt ELSE 0 END) AS merch_sale_amt
		        --, SUM(CASE WHEN 매출대분류 = N'기타' THEN amt ELSE 0 END) AS etc_sale_amt
		        , SUM(amt) AS total_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'국내' THEN amt ELSE 0 END) AS domestic_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'해외' THEN amt ELSE 0 END) AS export_sale_amt
		    FROM SALES_RAW
		    GROUP BY 구분, model, 매출대분류
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
		        , SUM(S.out_amt) AS prod_cogs_amt --select *
		    FROM DOI_STCO S
		    WHERE S.YYYYMM   = @YYYYMM
		      AND S.SITE     = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.COST_TYPE != 'LOSS'
		    GROUP BY S.구분, S.MODEL
		)
		, STCO_OUTETC AS (
			SELECT
			      구분
			    , MODEL AS model
			    , SUM(
			        CASE
			            WHEN 구분 = N'양산'
			            THEN -ISNULL(OUTETC_AMT,0)
			            ELSE  ISNULL(OUTETC_AMT,0)
			        END
			      ) AS outetc_amt
			FROM DOI_STCO
			WHERE YYYYMM = @YYYYMM
			  AND SITE = @SITE
			  AND SEL_CODE = @SEL_CODE
			  AND ISNULL(OUTETC_AMT,0) <> 0
			GROUP BY 구분, MODEL
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
		, SCOF_BASE AS (
		    SELECT
		          M.구분
		        , M.model
		        , CAST(COALESCE(XX.scof_amt,0) AS DECIMAL(18,2)) AS scof_amt
		    FROM #MODEL M
		    LEFT JOIN (
		        SELECT
		              CASE WHEN 모델 = N'회계-조정' THEN N'회계' ELSE 구분 END AS 구분
		            , CASE WHEN 모델 = N'회계-조정' THEN 모델 ELSE LEFT(모델, LEN(모델)-1) END AS model
		            , SUM(COALESCE(매출상계,0)) AS scof_amt
		        FROM DOI_원장상계
		        where  1=1
				   AND YYYYMM = @YYYYMM
				   AND SITE   = @SITE
				   AND SEL_CODE = @SEL_CODE
		        GROUP BY CASE WHEN 모델 = N'회계-조정' THEN N'회계' ELSE 구분 END, CASE WHEN 모델 = N'회계-조정' THEN 모델 ELSE LEFT(모델, LEN(모델)-1) END
		    ) XX
		       ON XX.model = M.model
		      AND XX.구분 = M.구분
		)        

        ----------------------------------------------------------------------
        -- 6. PL 헤더(I~III, IV 합계, V 영업이익) : PL_HEAD
        ----------------------------------------------------------------------
        , PL_HEAD AS (
            ------------------------------------------------------------------
            --  I. 매출액
            ------------------------------------------------------------------
            SELECT 1 rn, '  I. 매출액' AS gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0) AS amt FROM #MODEL M
        LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
			LEFT JOIN SCOF_BASE  SC ON SC.model = M.model AND SC.구분 = M.구분
 			-- WHERE S.매출대분류 != '기타'			
            UNION ALL
   			SELECT 2 rn, '    (1) 제품매출' gubun, M.구분, M.model, ISNULL(S.prod_sale_amt,0) FROM #MODEL M 
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
            UNION ALL
            SELECT 3 rn, '    (2) 유상사급' gubun, M.구분, M.model, ISNULL(SC.scof_amt,0) AS amt FROM #MODEL M 
			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
            UNION ALL
            SELECT 4 rn, '    (3) 상품매출' gubun, M.구분, M.model, ISNULL(S.merch_sale_amt,0) FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분

            ------------------------------------------------------------------
            --  II. 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 5 rn, '  II. 매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(A.adj_amt,0) /* II.매출원가 = 제품매출원가(양품)+상품+제품매출원가조정 2026-07-31 */ AS amt
            FROM #MODEL M
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
 			LEFT JOIN COGS_ADJ  A ON A.model = M.model AND A.구분 = M.구분
-- 			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
            UNION ALL
            SELECT 6 rn, '    (1) 제품매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0) /* 제품매출원가=양품(출고) 기준: 기타출고·조정 제외 2026-07-31 */  AS amt FROM #MODEL M
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분 and C.구분 = M.구분
            LEFT JOIN COGS_ADJ  A ON A.model = M.model AND A.구분 = M.구분
            LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분  = M.구분
            UNION ALL
            SELECT 11 rn, '    (2) 상품매출원가' gubun, M.구분, M.model, C.merch_cogs_amt FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            UNION ALL
            SELECT 12 rn, '    (3) 제품매출원가조정' gubun, M.구분, M.model, ISNULL(A.adj_amt,0) AS amt FROM #MODEL M
            LEFT JOIN COGS_ADJ  A ON A.model = M.model AND A.구분 = M.구분       
            ------------------------------------------------------------------
            --  III. 매출총이익 = 매출액 - 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 13 rn, '  III. 매출총이익' gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)
            - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) /* 매출원가=양품(출고) 기준: 기타출고 조정 제외 2026-07-31 */ + ISNULL(D.adj_amt,0) )  AS amt
			FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분            
			LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분  --where M.model='818U'
			LEFT JOIN COGS_ADJ D ON D.model = M.model and D.구분 = M.구분
			LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분 = M.구분
			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
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
            SELECT 141 rn, '  V. 영업이익'+REPLICATE(NCHAR(0x3000),7) gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)
        - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(D.adj_amt,0) /* 매출원가=양품(출고) 기준: 기타출고 조정 제외 2026-07-31 */ ) - ISNULL(G.sgna_amt,0)  AS amt
            FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분           
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
			LEFT JOIN COGS_ADJ D ON D.model = M.model and D.구분 = M.구분
            LEFT JOIN SGNA_SUM G ON G.model = M.model and G.구분 = M.구분
            LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분 = M.구분
			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
        )

        ----------------------------------------------------------------------
        -- 7. 판관비 세부 항목(이미지 기준 풀버전) : PL_SGNA
        ----------------------------------------------------------------------
        , PL_SGNA AS (
	SELECT
	    14 + C.총원가_순서 AS rn,
	    N'    (' + CAST(C.총원가_순서 AS varchar(2)) + N') ' + C.상위계정과목 AS gubun,
	    M.구분,
	    M.model,
	    CAST(ISNULL(SUM(S.dist_amt), 0) AS DECIMAL(18, 2)) AS amt
	FROM (
	    SELECT DISTINCT 상위계정과목, 총원가_순서
	    FROM doi_acct WITH (NOLOCK)
	    WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SEL_CODE = @SEL_CODE
	      -- [통일 2026-08-18] 하드코딩 IN-list 제거 → doi_acct 표준(대분류+총원가_순서) 동적 참조
	      AND 대분류 = N'판매관리비' AND 총원가_순서 IS NOT NULL
	) C
	CROSS JOIN #MODEL M
	LEFT JOIN (
	    -- 판관비 세부: smce sub_name을 상위계정과목으로 매핑(정확일치 우선 + 접두 폴백 → 미등록 계정 흡수)
	    SELECT B.구분, B.model, mp.상위계정과목, B.dist_amt
	    FROM doi_smce_cost B WITH (NOLOCK)
	    CROSS APPLY (
	        SELECT TOP 1 b2.상위계정과목
	        FROM doi_acct b2 WITH (NOLOCK)
	        WHERE b2.yyyymm = B.yyyymm AND b2.site = B.site AND b2.sel_code = B.sel_code
	          AND (b2.acct_name = B.sub_name OR B.sub_name LIKE b2.상위계정과목 + N'%')
	        ORDER BY CASE WHEN b2.acct_name = B.sub_name THEN 0 ELSE 1 END, LEN(b2.상위계정과목) DESC
	    ) mp
	    WHERE B.yyyymm = @YYYYMM AND B.site = @SITE AND B.sel_code = @SEL_CODE
	) S ON S.상위계정과목 = C.상위계정과목 AND S.구분 = M.구분 AND S.model = M.model
	GROUP BY
	    M.구분, M.model, C.상위계정과목, C.총원가_순서
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
        GROUP BY rn, gubun order by rn;
       
--		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
--		VALUES (N'', N'Z합계', 12, N'    (3) 제품매출원가조정', @CostAdj + @LossAdj);
		
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) /*+ @CostAdj + @LossAdj*/
		WHERE model = N'Z합계'
		  AND rn = 5;

		-- [총합계만] 회계-조정 유상사급을 매출액/매출총이익/영업이익에서 차감 (회계 컬럼 매출액은 0 유지) 2026-07-31
		UPDATE #sourceTable SET amt = COALESCE(amt,0) /* -@SCOF_ACC 제거 2026-08-18: 회계열 정상계산(-scof)이 합산에 이미 반영 */ WHERE model = N'Z합계' AND rn = 1;
		UPDATE #sourceTable SET amt = COALESCE(amt,0) /* -@SCOF_ACC 제거 2026-08-18: 회계열 정상계산(-scof)이 합산에 이미 반영 */ WHERE model = N'Z합계' AND rn = 13;

		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) /* -@SCOF_ACC 제거 2026-08-18: 회계열 정상계산(-scof)이 합산에 이미 반영 */
		WHERE model = N'Z합계'
		  AND rn = 141;

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

		-- 회계 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'회계',
		    N'Z합계회계',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'회계'
		GROUP BY rn, gubun;
	
/*		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		VALUES (N'', N'Z합계', 3, N'    (2) 유상사급', @SCOFTotal);
	
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) - @SCOFTotal
		WHERE model = N'Z합계'
		  AND rn    = 1
		  AND gubun = N'  I. 매출액';*/
       
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
                     WHEN 구분 = N'회계'   THEN 50
		                     ELSE 99
		                   END,
		        model_sort = model,
		        col_name = 구분 + model
		    FROM #MODEL
		    WHERE model != ''  --202604월 이전 유상사급 때문에 
		
		    UNION ALL SELECT 910, N'ZZZ', N'양산Z합계양산'
		    UNION ALL SELECT 920, N'ZZZ', N'개발Z합계개발'
		   UNION ALL SELECT 930, N'ZZZ', N'카세트Z합계카세트'
		    UNION ALL SELECT 940, N'ZZZ', N'구매Z합계구매'
		    UNION ALL SELECT 950, N'ZZZ', N'회계Z합계회계'
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
