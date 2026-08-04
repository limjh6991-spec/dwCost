CREATE OR ALTER PROCEDURE VN_PL_ByModel --운영
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
        DECLARE @Columns     NVARCHAR(MAX);
        DECLARE @SQL         NVARCHAR(MAX);
       	DECLARE @SCOFTotal DECIMAL(18,2) = 0;
		DECLARE @CostAdj     DECIMAL(18,2) = 0;
		DECLARE @LossAdj     DECIMAL(18,2) = 0;    	

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
		        CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN A.품번 ELSE A.품명 END AS model
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
		        CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN B.품번 ELSE B.품명 END AS model
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		      
		UNION
		
		SELECT
			O.구분,O.모델 AS model
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
		 
		-- DOI_COST LOSS 조정 제거 (@LossAdj=0 유지)
		SET @LossAdj = 0;
		 
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
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN A.품번 ELSE A.품명 END AS model
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
		        , CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN B.품번 ELSE B.품명 END AS model
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
		        , S.도우코드 AS model
		        , SUM(ISNULL(S.BOH_AMT, 0)) AS begin_fg_amt
		        , SUM(ISNULL(S.IN_AMT, 0))  AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , SUM(ISNULL(S.EOH_AMT, 0)) AS end_fg_amt
		        , SUM(S.out_amt) AS prod_cogs_amt --select *
		    FROM (SELECT *, @SITE AS site, T_OUTPUT_AMT AS out_amt, T_INPUT_AMT AS IN_AMT, EOH_WH0006_AMT AS EOH_AMT, ETCOUT_TOTAL_AMT AS OUTETC_AMT, CAST('X' AS varchar(10)) AS COST_TYPE FROM DOI_VN_STCO WITH(NOLOCK)) S
		    WHERE S.YYYYMM   = @YYYYMM
		      AND S.SITE     = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.COST_TYPE != 'LOSS'
		    GROUP BY S.구분, S.도우코드
		)
		, STCO_OUTETC AS (
			SELECT
			      구분
			    , 도우코드 AS model
			    , SUM(
			        CASE
			            WHEN 구분 = N'양산'
			            THEN -ISNULL(OUTETC_AMT,0)
			            ELSE  ISNULL(OUTETC_AMT,0)
			        END
			      ) AS outetc_amt
			FROM (SELECT *, @SITE AS site, T_OUTPUT_AMT AS out_amt, T_INPUT_AMT AS IN_AMT, EOH_WH0006_AMT AS EOH_AMT, ETCOUT_TOTAL_AMT AS OUTETC_AMT, CAST('X' AS varchar(10)) AS COST_TYPE FROM DOI_VN_STCO WITH(NOLOCK)) S2
			WHERE YYYYMM = @YYYYMM
			  AND SITE = @SITE
			  AND SEL_CODE = @SEL_CODE
			  AND ISNULL(OUTETC_AMT,0) <> 0
			GROUP BY 구분, 도우코드
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
		        , a.도우코드 AS model
		        , SUM(a.out_amt) AS adj_amt
		    FROM DOI_SLCO a WITH(NOLOCK)
		    WHERE a.YYYYMM = @YYYYMM
		      AND a.SITE   = @SITE
		      AND a.SEL_CODE = @SEL_CODE
		      AND a.expen_sel명 = N'기타매출'
		    GROUP BY a.구분, a.도우코드
		)
        , SGNA_BASE AS (
            ------------------------------------------------------------------
            -- (4) 판관비
            ------------------------------------------------------------------
            SELECT
            	구분
                , ISNULL(NULLIF(LTRIM(RTRIM(mm.도우코드)),''),S.MODEL) AS model
                , SUB_NAME
                , SUM(ISNULL(DIST_AMT,0)) AS amt      -- 배부된 판관비 금액
            FROM DOI_SMCE_COST S
            LEFT JOIN (SELECT DISTINCT MODEL, 도우코드 FROM DOI_VN_STCO WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE) mm ON mm.MODEL=S.MODEL
            JOIN (SELECT yyyymm,site,계정과목,MIN(계정코드) 계정코드 FROM doi_dept_cost WHERE 비용구분=N'판관' GROUP BY yyyymm,site,계정과목) dc
              ON dc.yyyymm=S.yyyymm AND dc.site=S.site AND dc.계정과목=S.SUB_NAME
            JOIN doi_acct da ON da.yyyymm=S.yyyymm AND da.site=S.site AND da.acct=dc.계정코드
            WHERE S.YYYYMM = @YYYYMM
              AND S.SITE = @SITE
              AND S.SEL_CODE = @SEL_CODE
              AND da.상위계정과목 <> N'비용제외' AND ISNULL(da.상위계정과목,N'') <> N''
            GROUP BY S.구분, ISNULL(NULLIF(LTRIM(RTRIM(mm.도우코드)),''),S.MODEL), S.SUB_NAME
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
		              구분
		            , 모델 AS model
		            , SUM(COALESCE(매출상계,0)) AS scof_amt
		        FROM DOI_원장상계
		        where  1=1
				   AND YYYYMM = @YYYYMM
				   AND SITE   = @SITE
				   AND SEL_CODE = @SEL_CODE
		        GROUP BY 구분, 모델
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
            SELECT 5 rn, '  II. 매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) /*- ISNULL(SC.scof_amt,0)*/ AS amt 
            FROM #MODEL M 
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
 			LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분  = M.구분
-- 			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
            UNION ALL
            SELECT 6 rn, '    (1) 제품매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0)  + ISNULL(A.adj_amt,0)  AS amt FROM #MODEL M 
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
            - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(D.adj_amt,0) )  AS amt
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
        - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(D.adj_amt,0) ) - ISNULL(G.sgna_amt,0)  AS amt 
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
        -- 판관비 세부: 고정 27항목 골격 (집계표 VN_SalesAdminByModel과 동일 목록/순서)
        , SGNA_SKEL AS (
            SELECT seq, item FROM (VALUES
                (1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
                (6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
                (11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
                (16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
                (21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
                (26,N'판)잡비'),(27,N'기술이전비 및 기술지원비')
            ) v(seq,item)
        )
        , SGNA_AMT AS (
            -- doi_smce_cost → doi_dept_cost(판관) 브리지 → doi_acct.상위계정과목(경영계획 우선), 모델별 dist_amt 합
            SELECT B.구분, B.model,
                   COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목) AS item,
                   SUM(ISNULL(B.dist_amt,0)) AS amt
            FROM doi_smce_cost B WITH (NOLOCK)
            JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분 = N'판관' GROUP BY yyyymm, site, 계정과목) dc
                ON dc.yyyymm = B.yyyymm AND dc.site = B.site AND dc.계정과목 = B.sub_name
            JOIN doi_acct A WITH (NOLOCK)
                ON A.yyyymm = B.yyyymm AND A.site = B.site AND A.acct = dc.계정코드
            WHERE B.YYYYMM = @YYYYMM AND B.SITE = @SITE AND B.SEL_CODE = @SEL_CODE
              AND ISNULL(COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목),N'') <> N''
            GROUP BY B.구분, B.model, COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목)
        )
        , PL_SGNA AS (
            SELECT
                14 + SK.seq AS rn,
                N'    (' + CAST(SK.seq AS varchar(2)) + N') ' + SK.item AS gubun,
                M.구분,
                M.model,
                CAST(ISNULL(SUM(AM.amt), 0) AS DECIMAL(18, 2)) AS amt
            FROM SGNA_SKEL SK
            CROSS JOIN #MODEL M
            LEFT JOIN SGNA_AMT AM ON AM.구분 = M.구분 AND AM.model = M.model AND AM.item = SK.item
            GROUP BY SK.seq, SK.item, M.구분, M.model
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
		
--		UPDATE #sourceTable
--		SET amt = COALESCE(amt,0) - @SCOFTotal--- (@CostAdj + @LossAdj)
--		WHERE model = N'Z합계'
--		  AND rn = 13;
		
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) -- - (@CostAdj + @LossAdj)
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
