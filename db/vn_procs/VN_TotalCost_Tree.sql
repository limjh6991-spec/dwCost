CREATE OR ALTER PROCEDURE VN_TotalCost_Tree
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4),
    @SELCODE VARCHAR(6)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @Columns         NVARCHAR(MAX) = N'';
        DECLARE @ModelSelectCols NVARCHAR(MAX) = N'';
        DECLARE @SumYangsan      NVARCHAR(MAX) = N'0';
        DECLARE @SumDev          NVARCHAR(MAX) = N'0';
        DECLARE @SumCassette     NVARCHAR(MAX) = N'0';
       	DECLARE @SumPurchase     NVARCHAR(MAX) = N'0';
        DECLARE @SumYangsan_Sale NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Qty  NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Sale     NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Qty      NVARCHAR(MAX)=N'0';
		DECLARE @SumCas_Sale     NVARCHAR(MAX)=N'0';
		DECLARE @SumCas_Qty      NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Sale     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Qty      NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Bep NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Bep     NVARCHAR(MAX)=N'0';  --손익분기점 : Break-Even Point (BEP) Operating Profit
		DECLARE @SumCas_Bep     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Bep     NVARCHAR(MAX)=N'0';
		DECLARE @SumYangsan_Cm  NVARCHAR(MAX)=N'0';  -- 한계이익 : Contribution Margin
		DECLARE @SumDev_Cm      NVARCHAR(MAX)=N'0';
		DECLARE @SumCas_Cm      NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Cm      NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Op NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Op     NVARCHAR(MAX)=N'0';  -- 영업이익  : Operating Profit
		DECLARE @SumCas_Op     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Op     NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_FiX  NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Fix      NVARCHAR(MAX)=N'0';
--		DECLARE @SumCas_Fix      NVARCHAR(MAX)=N'0';
--		DECLARE @SumPur_Fix      NVARCHAR(MAX)=N'0';

        DECLARE @SCOFTotal DECIMAL(18,2) = 0;

        DECLARE @SQL             NVARCHAR(MAX);

        /*==============================================================
          0) 매출 발생 모델만 추출 (SALES_BASE)
        ==============================================================*/
		;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SELCODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),        
       SALES_RAW AS (
		    -- 국내매출
		    SELECT
		          A.SITE
		        , CASE
			        WHEN MI.품번 IS NOT NULL THEN N'구매'
		            WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		            WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		            ELSE N'개발'
		          END AS 구분
		        , A.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , N'국내' AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , CAST(A.원화판매금액 AS DECIMAL(18,2)) AS amt
		    FROM DOI_SALE_RESC A WITH(NOLOCK)
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		      AND A.SITE   = @SITE
		
		    UNION ALL
		    -- 해외매출
		    SELECT
		          B.SITE
		        , CASE
			        WHEN MI.품번 IS NOT NULL THEN N'구매'			        
		            WHEN LEFT(B.품번, 2) = 'VN' THEN N'카세트'
		            WHEN RIGHT(B.품번, 1) = 'P' THEN N'양산'
		            ELSE N'개발'
		          END AS 구분
		        , B.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번) - 1) ELSE B.품명 END AS model
		        , N'해외' AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , CAST(B.원화판매금액 AS DECIMAL(18,2)) AS amt
		    FROM DOI_INVOICE_RESC B WITH(NOLOCK)
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		       
		    /*UNION ALL  --2026.02.15 KYH 삭제
		      
            --기타매출
			SELECT
	          S.SITE
	        , S.구분
	        , NULL AS 품번
	        , S.model
	        , N'*'  AS 매출구분
	        , N'기타' AS 매출대분류
	        , CAST(ISNULL(/*S.out_amt*/0,0) AS DECIMAL(18,2)) AS amt
	    FROM DOI_SLCO S WITH(NOLOCK)
	    WHERE S.YYYYMM = @YYYYMM
	      AND S.SITE   = @SITE
	      AND S.SEL_CODE = @SELCODE
	      AND S.expen_sel명 = N'기타매출'*/
	  
	     UNION ALL  
		      
            --기타매출
			SELECT
	          S.SITE
	        , S.구분
	        , NULL AS 품번
	        , S.model
	        , N'*'  AS 매출구분
	        , N'기타' AS 매출대분류
	        , CAST(ISNULL(/*S.out_amt*/0,0) AS DECIMAL(18,2)) AS amt
	    FROM DOI_SLCO S WITH(NOLOCK)
	    WHERE S.YYYYMM = @YYYYMM
	      AND S.SITE   = @SITE
	      AND S.SEL_CODE = @SELCODE
	      AND S.MODEL = 'EXTRA' 
			  
        ),
        SALES_BASE AS (
		    SELECT
		          구분
		        , model
		        , SUM(CASE WHEN 매출대분류 = N'제품' THEN amt ELSE 0 END) AS prod_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'상품' THEN amt ELSE 0 END) AS merch_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'기타' THEN amt ELSE 0 END) AS etc_sale_amt
		        , SUM(amt) AS total_sale_amt
		    FROM SALES_RAW
		    GROUP BY 구분, model
        )
        SELECT *
        INTO #SALES_BASE
        FROM SALES_BASE;
        --WHERE COALESCE(total_sale_amt,0) <> 0;

        /*==============================================================
          1) #MODEL : 모델 + 제품구조/카세트 포함
        ==============================================================*/
        ;WITH MODEL_BASE AS (
            SELECT
                  S.model
                , S.구분 AS 구분
                , CASE
	                  WHEN S.구분 = N'구매' THEN N'상품'
                      WHEN S.구분 = N'카세트' THEN N'카세트'
                      WHEN LEFT(S.model, 1) = 'I' THEN 'ITG'
                      WHEN LEFT(S.model, 1) = 'H' THEN 'HTG'
                      WHEN LEFT(S.model, 1) = 'C' THEN 'Coated'
                      ELSE 'UTG'
                  END AS 제품구조
                , CASE
                      WHEN S.구분 = N'카세트' THEN 1
                      WHEN LEFT(S.model, 2) = 'VN' THEN 1   -- 안전장치(모델명이 VN으로 오는 경우)
                      ELSE 0
                  END AS is_cassette
            FROM #SALES_BASE S
        )
        SELECT
              model
            , 구분
            , 제품구조
            , is_cassette
            , (CASE
                  WHEN 구분 = N'카세트' THEN N'카세트'
                  WHEN 구분 = N'개발'   THEN N'개발'
                  WHEN 구분 = N'구매'   THEN N'구매'                  
                  ELSE N'양산'
               END) + model AS pivot_key
			,	CASE
				    WHEN LEFT(model, 1) BETWEEN '0' AND '9' THEN 0
				    ELSE 1
				END AS sort_numeric  
            , CASE
                  WHEN 구분 = N'양산' THEN 1
                  WHEN 구분 = N'개발' THEN 2
                  WHEN 구분 = N'카세트' THEN 3
                  WHEN 구분 = N'구매' THEN 4                  
                  ELSE 9
              END AS sort_group
            , CASE 제품구조
                  WHEN 'UTG' THEN 1
                  WHEN 'ITG' THEN 2
                  WHEN 'HTG' THEN 3
                  WHEN 'Coated' THEN 4
                  WHEN N'카세트' THEN 8
                  WHEN N'상품' THEN 9                  
                  ELSE 9
              END AS sort_structure
        INTO #MODEL
        FROM MODEL_BASE;
       
       SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
	   FROM DOI_SCOF WITH(NOLOCK)
	   WHERE yyyymm  = @YYYYMM
	    AND site   	 = @SITE
        AND sel_code = @SELCODE

		/*==============================================================
		  (추가) 1-1) 변동비/고정비 프로시저 결과 받아오기 (세로형)
		==============================================================*/
		IF OBJECT_ID('tempdb..#VAR') IS NOT NULL DROP TABLE #VAR;
		IF OBJECT_ID('tempdb..#FIX') IS NOT NULL DROP TABLE #FIX;
		
		CREATE TABLE #VAR (
		  rn   INT,
		  gubun NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  구분  NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
		  model NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  amt  DECIMAL(18,2)
		);
		
		CREATE TABLE #FIX (
		  rn   INT,
		  gubun NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  구분  NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
		  model NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  amt  DECIMAL(18,2)
		);
		
		INSERT INTO #VAR (rn, gubun, 구분, model, amt)
		EXEC DOI_변동비_ByModel @YYYYMM=@YYYYMM, @SITE=@SITE , @SELCODE = @SELCODE;
		--EXEC DOI_VariableCostByModel @YYYYMM=@YYYYMM, @SITE=@SITE , @SELCODE = @SELCODE;
		
		INSERT INTO #FIX (rn, gubun, 구분, model, amt)
		EXEC DOI_고정비_ByModel @YYYYMM=@YYYYMM, @SITE=@SITE, @SELCODE = @SELCODE; 
		--EXEC DOI_FixedCostByModel @YYYYMM=@YYYYMM, @SITE=@SITE, @SELCODE = @SELCODE; 

       SELECT @SumYangsan_FiX = CAST(COALESCE(SUM(AMT),0) AS DECIMAL(18,2)) 
       FROM #FIX 
       WHERE 구분=N'양산'

       SELECT @SumDev_Fix = CAST(COALESCE(SUM(AMT),0) AS DECIMAL(18,2)) 
       FROM #FIX 
       WHERE 구분=N'개발'
      
        /*==============================================================
          2) #RN
        ==============================================================*/
        -- 고정 항목 골격 (집계표 VN_ManufacturingExpense* / VN_SalesAdmin* 와 동일 목록/순서)
        IF OBJECT_ID('tempdb..#SKL_LAB') IS NOT NULL DROP TABLE #SKL_LAB;
        IF OBJECT_ID('tempdb..#SKL_EXP') IS NOT NULL DROP TABLE #SKL_EXP;
        IF OBJECT_ID('tempdb..#SKL_SGA') IS NOT NULL DROP TABLE #SKL_SGA;
        SELECT N'12.'+RIGHT(N'0'+CAST(seq AS varchar(2)),2) tree_id, 15+seq rn,
               N'    ('+CAST(seq AS varchar(2))+N') '+item gubun, CAST(item AS nvarchar(200)) item, seq
        INTO #SKL_LAB
        FROM (VALUES (1,N'제)급여-직원'),(2,N'제)상여금'),(3,N'제)제수당'),(4,N'제)퇴직급여'),(5,N'제)주식보상비용'),(6,N'제)급여-사회보험료'),(7,N'제)급여-건강보험'),(8,N'제)급여-노동자실업보험료'),(9,N'제)급여-노동자노조비'),(10,N'제)급여-개인소득세'),(11,N'제)급여-기타')) v(seq,item);
        SELECT CAST(N'13.'+RIGHT(N'0'+CAST(seq AS varchar(2)),2) AS nvarchar(20)) tree_id, 30+seq+CASE WHEN seq>=13 THEN 2 ELSE 0 END rn,
               CAST(N'    ('+CAST(seq AS varchar(2))+N') '+item AS nvarchar(200)) gubun, CAST(item AS nvarchar(200)) item, seq
        INTO #SKL_EXP
        FROM (VALUES (1,N'제)직원급여'),(2,N'제)상여금'),(3,N'제)제수당'),(4,N'제)퇴직급여'),(5,N'제)주식보상비용'),(6,N'제)급여-사회보험료'),(7,N'제)급여-건강보험'),(8,N'제)급여-노동자실업보험료'),(9,N'제)급여-노동자노조비'),(10,N'제)급여-개인소득세'),(11,N'제)급여-기타'),(12,N'제)급여-기타비용'),(13,N'제)여비교통비'),(14,N'제)통신비'),(15,N'제)수도광열비'),(16,N'제)전력비'),(17,N'제)감가상각비'),(18,N'제)지급임차료'),(19,N'제)수선비'),(20,N'제)보험료'),(21,N'제)차량유지비'),(22,N'제)운반비'),(23,N'제)교육훈련비'),(24,N'제)도서인쇄비'),(25,N'제)소모품비'),(26,N'제)지급수수료'),(27,N'제)외주가공비'),(28,N'제)사용권자산감가상각비'),(29,N'제)검사비'),(30,N'제)견본비'),(31,N'기술지원 및 기술이전비')) v(seq,item);
        -- 공구 및 도구비용 별도 2항목 ((12) 뒤 rn43/44, 감가상각비에서 제외)
        INSERT #SKL_EXP(tree_id, rn, gubun, item, seq) VALUES
          (N'13.51', 43, N'    (1-1) 제)공구 및 도구 비용 - 상각비용', N'제)공구 및 도구 비용 - 상각비용', 121),
          (N'13.52', 44, N'    (1-2) 제)공구 및 도구 비용 -일회성비용', N'제)공구 및 도구 비용 -일회성비용', 122);
        SELECT N'16.'+RIGHT(N'0'+CAST(seq AS varchar(2)),2) tree_id, 75+seq rn,
               N'    ('+CAST(seq AS varchar(2))+N') '+item gubun, CAST(item AS nvarchar(200)) item, seq
        INTO #SKL_SGA
        FROM (VALUES (1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비'),(28,N'판)외주용역비')) v(seq,item);

        SELECT tree_id, rn, gubun
        INTO #RN
        FROM (
            SELECT N'10' tree_id, 1 rn, N'  I. 매출액' gubun UNION ALL
            SELECT N'10.01', 2, N'    (1) 제품매출' UNION ALL
            SELECT N'10.02', 3, N'        수량' UNION ALL
            SELECT N'10.03', 4, N'        단가' UNION ALL
            SELECT N'10.04', 5, N'    (2) 유상사급' UNION ALL
            SELECT N'10.05', 6, N'    (3) 상품매출' UNION ALL
            SELECT N'10.06', 7, N'    (4) 기타매출' UNION ALL
            SELECT N'11', 8, N'  II. 재료비' UNION ALL
            SELECT N'11.01', 9, N'    (1) 원재료비' UNION ALL
            SELECT N'12', 15, N'  III. 노무비' UNION ALL
            SELECT N'13', 30, N'  IV. 제조경비' UNION ALL
            SELECT N'14', 70, N'  V. 매출원가' UNION ALL
            SELECT N'14.01', 71, N'    (1) 제품매출원가' UNION ALL
            SELECT N'14.02', 72, N'    (2) 상품매출원가' UNION ALL
            SELECT N'16', 75, N'  VI. 판관비' UNION ALL
            SELECT N'17', 110, N'  VII. 총원가' UNION ALL
            SELECT N'18', 111, N'  VIII. 영업이익' UNION ALL
            SELECT N'18.01', 112, N'    영업이익률' UNION ALL
            SELECT N'19', 120, N'  IX. 한계이익' UNION ALL
            SELECT N'19.01', 121, N'    한계이익률' UNION ALL
            SELECT N'20', 130, N'  X. 손익분기점'+ REPLICATE(NCHAR(0x3000), 5) UNION ALL
            SELECT tree_id, rn, gubun FROM #SKL_LAB UNION ALL
            SELECT tree_id, rn, gubun FROM #SKL_EXP UNION ALL
            SELECT tree_id, rn, gubun FROM #SKL_SGA
        ) A;
       
        /*==============================================================
          3) FACT (rn/gubun/model/amt)
             - 매출: #SALES_BASE
             - 재료비: doi_mat_cost
             - 노무비/제조경비: doi_expen_matl
             - V 재고조정: DOI_COST + DOI_STCO
             - VI 판관비: DOI_SMCE_COST
             - VII 총원가: 재고조정 + 판관비
             - VIII 영업이익: 매출액 - 총원가 
             - IX~X: 우선 NULL
        ==============================================================*/
        ;WITH MERCH_ITEM AS (
      SELECT DISTINCT M.품번
            FROM DOI_MATL_RESC M WITH(NOLOCK)
            WHERE M.YYYYMM   = @YYYYMM
              AND M.SITE     = @SITE
              AND M.SEL_CODE = @SELCODE
              AND M.품목자산분류 = N'상품'
              AND M.품번 IS NOT NULL
        ),
       SALES_FACT AS (
            SELECT 1 rn, N'  I. 매출액'     AS gubun, 구분, model, total_sale_amt AS amt FROM #SALES_BASE
            UNION ALL
            SELECT 2 rn, N'    (1) 제품매출' AS gubun, 구분, model, prod_sale_amt AS amt FROM #SALES_BASE
   			UNION ALL
    		SELECT 6 rn, N'    (3) 상품매출'   AS gubun, 구분, model, merch_sale_amt  AS amt FROM #SALES_BASE        
           ),
        QTY_BASE AS (
		    SELECT
		          CASE
                      WHEN MI.품번 IS NOT NULL THEN N'구매'     
		              WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		              WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		              ELSE N'개발'
		          END AS 구분
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , SUM(A.수량) AS qty
		    FROM (
                SELECT YYYYMM, SITE, 품번, 품명, 수량 FROM DOI_SALE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
                UNION ALL
                SELECT YYYYMM, SITE, 품번, 품명, 수량 FROM DOI_INVOICE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
		    ) A
            LEFT JOIN MERCH_ITEM MI ON MI.품번 = A.품번
            GROUP BY
                CASE
                    WHEN MI.품번 IS NOT NULL THEN N'구매'
                    WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
                    WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
                    ELSE N'개발'
                END,
                CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END
		),
		QTY_FACT AS (
		    SELECT
		          3 AS rn
		        , N'        수량' AS gubun
		        , 구분
		        , model
		        , CAST(qty AS DECIMAL(18,2)) AS amt
		    FROM QTY_BASE
		),
		PRICE_BASE AS (
		    SELECT
		          CASE
		              WHEN MI.품번 IS NOT NULL THEN N'구매'
		              WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		              WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		              ELSE N'개발'
		          END AS 구분
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , SUM(A.매출금액) AS sale_amt
		        , SUM(A.수량)     AS qty
		    FROM (
		        SELECT 품번, 품명, 수량, 원화판매금액 AS 매출금액 FROM DOI_SALE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
		        UNION ALL
		        SELECT 품번, 품명, 수량, 원화판매금액 AS 매출금액 FROM DOI_INVOICE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
		    ) A
		    LEFT JOIN MERCH_ITEM MI ON MI.품번 = A.품번
		    GROUP BY
		        CASE
		            WHEN MI.품번 IS NOT NULL THEN N'구매'
		            WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		            WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		            ELSE N'개발'
		        END,
		        CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END
		),
		PRICE_FACT AS (
		    SELECT
		          4 AS rn
		        , N'        단가' AS gubun
		        , 구분
		        , model
		        , CAST(
		              CASE WHEN qty = 0 THEN 0
		                   ELSE sale_amt / qty
		              END
		          AS DECIMAL(18,2)) AS amt
		    FROM PRICE_BASE
		),
		SCOF_BASE AS (
		    SELECT
		          5 AS rn
		        , N'    (2) 유상사급' AS gubun
		        , N'총합계' AS 구분
		        , N'총합계' AS model
		        , CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2)) AS amt
		    FROM DOI_SCOF WITH(NOLOCK)
		    WHERE yyyymm  = @YYYYMM
		      AND site    = @SITE
              AND sel_code= @SELCODE
		),
		ETC_SALE_BASE AS (
            SELECT 7 rn, 
                   N'    매출원가조정' gubun, 
                   구분, 
                 model,
                   SUM(out_amt) AS amt
            FROM doi_slco a WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM
              AND site   = @SITE
              AND sel_code = @SELCODE
              and EXPEN_SEL명 = '기타매출'
            GROUP BY 구분, model
		),		
		MAT_BASE AS (
            SELECT
            	구분
                , model    
                , acct_name
                , out_amt AS amt --select distinct acct_name
   FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM
              AND site   = @SITE
              AND sel_code = @SELCODE
              and expen_sel IN('MDAX','MIAX')  --직접재료비, 간접재료비
              and out_amt != 0
        ),
        MAT_AGG AS (
            -- II. 재료비 (VN: 단일 원재료비)
            SELECT 8 rn, N'  II. 재료비' gubun, 구분, model, SUM(amt) amt
            FROM MAT_BASE
            GROUP BY 구분, model
            UNION ALL
            SELECT 9 rn, N'    (1) 원재료비' gubun, 구분, model, SUM(amt) amt
            FROM MAT_BASE
            GROUP BY 구분, model
          ),
        LABOR_BASE AS (
         SELECT 15+총원가_순서 rn, N'    ('+CAST(총원가_순서 as varchar(1))+') '+b.상위계정과목 as gubun, a.구분, a.model,
                   SUM(out_amt) AS amt
            FROM doi_stco a WITH(NOLOCK)
            LEFT JOIN (SELECT DISTINCT yyyymm, site, 계정과목, 계정코드 FROM doi_dept_cost) dc
                   ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.acct_name
            inner join doi_acct b on(a.yyyymm=b.yyyymm and a.site=b.site
                   and ( b.acct_name = a.acct_name
                         OR ( b.acct = dc.계정코드
                              AND NOT EXISTS (SELECT 1 FROM doi_acct bx WHERE bx.yyyymm=a.yyyymm AND bx.site=a.site AND bx.acct_name=a.acct_name) ) ) )
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND b.상위계정과목 in ('제)임원급여','제)직원급여', '제)상여금', '제)제수당', '제)퇴직급여', '제)주식보상비용')
            GROUP BY a.구분, a.model ,b.상위계정과목,b.총원가_순서
        ),  
        LABOR_AGG AS (
            SELECT 15 rn, N'  III. 노무비' gubun, 구분, model,
                   SUM(amt) AS amt
            FROM LABOR_BASE 
            GROUP BY 구분, model
        ),
        EXP_BASE AS (
                 SELECT 22+총원가_순서 rn, N'    ('+CAST(총원가_순서 as varchar(2))+') '+b.상위계정과목 as gubun, a.구분, a.model,
                   SUM(out_amt) AS amt
            FROM doi_stco a WITH(NOLOCK)
            LEFT JOIN (SELECT DISTINCT yyyymm, site, 계정과목, 계정코드 FROM doi_dept_cost) dc
                   ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.acct_name
            inner join doi_acct b on(a.yyyymm=b.yyyymm and a.site=b.site
                   and ( b.acct_name = a.acct_name
                         OR ( b.acct = dc.계정코드
                              AND NOT EXISTS (SELECT 1 FROM doi_acct bx WHERE bx.yyyymm=a.yyyymm AND bx.site=a.site AND bx.acct_name=a.acct_name) ) ) )
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND b.상위계정과목 in ('제)복리후생비','제)여비교통비','제)통신비','제)수도광열비','제)전력비','제)세금과공과','제)감가상각비','제)지급임차료','제)수선비','제)보험료','제)차량유지비','제)운반비','제)교육훈련비','제)도서인쇄비','제)소모품비','제)지급수수료','제)외주가공비','제)사용권자산감가상각비','제)검사비','제)견본비','제)공구 및 도구비용')
            GROUP BY a.구분, a.model ,b.상위계정과목,b.총원가_순서
            UNION ALL
            /*SELECT 22 rn, N'  EXTRA' gubun, 구분, model, out_amt
             FROM doi_slco a WITH(NOLOCK)
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND a.model = 'EXTRA'
            UNION ALL*/
            SELECT 22 rn, N'  기타출고' gubun, 구분, model, out_amt
             FROM doi_stco a WITH(NOLOCK)
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND a.acct_name = '*'
              AND a.out_amt != 0
        ),
        EXP_AGG AS (
            SELECT 30 rn, N'  IV. 제조경비' gubun, 구분, model,
                   SUM(amt) AS amt
            FROM EXP_BASE 
            GROUP BY 구분, model
        ),

        /* ====== 상품매출원가 ====== */
        MERCH_COGS AS ( 
            SELECT 99 rn, N'    상품매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(SUM(R.출고금액),0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_MATL_RESC R WITH(NOLOCK)
              ON R.YYYYMM = @YYYYMM
             AND R.SITE   = @SITE
             AND R.SEL_CODE = @SELCODE
             AND R.품목자산분류 = N'상품'
             AND (CASE WHEN @SITE = N'VN' AND LEN(R.품번) > 1 THEN LEFT(R.품번, LEN(R.품번) - 1) ELSE R.품명 END) = M.model
            WHERE M.구분 = N'구매'
            GROUP BY M.구분, M.model
        ),				
		
        /* ====== 제품매출원가(doi_stco OUT, 비LOSS) = 실제 제품출고원가 ====== */
        PROD_COGS AS (
            SELECT 구분, model, CAST(SUM(out_amt) AS DECIMAL(18,2)) AS amt
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SELCODE
              AND COST_TYPE <> 'LOSS'
            GROUP BY 구분, model
        ),
        TOTAL_MFG AS (
            /*SELECT 43 rn, N'    당기총제조원가' gubun, M.구분, M.model,
                   SUM(COALESCE(A.[in],0)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_COST A  
            ON A.YYYYMM   = @YYYYMM
            AND A.SITE     = @SITE
            AND A.SEL_CODE = @SELCODE
            AND A.model = M.model 
            AND A.구분 = M.구분
            GROUP BY M.구분, M.MODEL*/
            -- V 매출원가 = 제품매출원가(doi_stco 실제출고원가) + 상품매출원가
			SELECT 70 rn, N'  V. 매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(PC.amt,0) + COALESCE(XX.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN PROD_COGS     PC ON PC.model = M.model AND PC.구분 = M.구분
            LEFT JOIN MERCH_COGS    XX ON XX.model = M.model AND XX.구분 = M.구분
            ),
        /* ====== V 매출원가 하위: (1)제품매출원가 (2)상품매출원가 ====== */
        PROD_COGS_FACT AS (
            SELECT 71 rn, N'    (1) 제품매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(PC.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN PROD_COGS PC ON PC.model = M.model AND PC.구분 = M.구분
            ),
        MERCH_COGS_FACT AS (
            SELECT 72 rn, N'    (2) 상품매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(XX.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN MERCH_COGS XX ON XX.model = M.model AND XX.구분 = M.구분
            ),
        ADJ_SALE AS (  --26-02-13 삭제
            SELECT 44 rn, N'    매출원가조정' gubun, M.구분, M.model,
                   COALESCE(E.amt,0) AS amt
            FROM #MODEL M
            LEFT JOIN ETC_SALE_BASE E ON E.model = M.model AND E.구분 = M.구분
        ),
        
        /* ====== V 재고조정 ======
           재고조정 = (기초재공 - 기말재공) + (기초제품 - 기말제품)
                   + (타계정입고(재공/제품) - 타계정출고(재공/제품))
        */
		COST_ADJ AS (  --26-02-13 삭제
		    SELECT
		          YYYYMM, SITE, 구분, MODEL
		        , SUM(COALESCE(BOH+ADJ_BOH,0))       AS BOH
		        , SUM(COALESCE(EOH,0))       AS EOH
		        , SUM(COALESCE(RMAIN_AMT,0)) AS RMAIN_AMT
		    FROM DOI_COST WITH(NOLOCK)
		    WHERE YYYYMM  = @YYYYMM
		      AND SITE    = @SITE
              AND SEL_CODE= @SELCODE
		    GROUP BY YYYYMM, SITE, 구분, MODEL
		),
		STCO_ADJ AS ( 
		    SELECT
		          YYYYMM, SITE, 구분, MODEL
		        , SUM(COALESCE(BOH_AMT,0))    AS BOH_AMT
		        , SUM(COALESCE(EOH_AMT,0))    AS EOH_AMT
		        , SUM(COALESCE(INETC_AMT,0))  AS INETC_AMT
		        , SUM(COALESCE(OUTETC_AMT,0)) AS OUTETC_AMT
		    FROM DOI_STCO WITH(NOLOCK)
		    WHERE YYYYMM = @YYYYMM
		      AND SITE   = @SITE
		      AND SEL_CODE = @SELCODE
		      AND ACCT_NAME != '기타출고'
		    GROUP BY YYYYMM, SITE, 구분, MODEL
		),
		INV_ADJ AS (
		    SELECT
		          45 rn
		        , N'  V. 재고조정' gubun
		        , M.구분
		        , M.model
		        , CAST(
		              (COALESCE(C.BOH,0) - COALESCE(C.EOH,0))
		            + (COALESCE(S.BOH_AMT,0) - COALESCE(S.EOH_AMT,0))
		            /*+ COALESCE(C.RMAIN_AMT,0)*/
		            + COALESCE(S.INETC_AMT,0)
		            - COALESCE(S.OUTETC_AMT,0)
		          AS DECIMAL(18,2)) AS amt
		    FROM #MODEL M
		    LEFT JOIN COST_ADJ C
		           ON C.YYYYMM = @YYYYMM
		          AND C.SITE   = @SITE
		          AND C.MODEL  = M.model
		          AND C.구분    = M.구분
		    LEFT JOIN STCO_ADJ S
		           ON S.YYYYMM = @YYYYMM
		          AND S.SITE   = @SITE
		       AND S.MODEL  = M.model
		          AND S.구분    = M.구분
		),
    /* ====== VI 판관비 ====== */
		SGA_BASE AS (
			SELECT 47+b.총원가_순서 rn,
			       N'    ('+CAST(b.총원가_순서 as varchar(2))+') '+b.상위계정과목 as gubun,
			       a.구분,
			       a.model,
			       SUM(a.dist_amt) AS amt
			FROM doi_smce_cost a WITH(NOLOCK)
			-- VN: sub_name(원장명)은 doi_acct.acct_name과 매칭 안 되므로 doi_dept_cost(판관) 브리지
			left join (select distinct yyyymm, site, 계정과목, 계정코드 from doi_dept_cost where 비용구분=N'판관') dc
			  on @SITE=N'VN' and dc.yyyymm=a.yyyymm and dc.site=a.site and dc.계정과목=a.sub_name
			inner join doi_acct b
			  on (a.yyyymm=b.yyyymm and a.site=b.site
			      and ( (@SITE<>N'VN' and a.sub_name=b.acct_name)
			            or (@SITE=N'VN' and b.acct=dc.계정코드) ))
			WHERE a.yyyymm = CASE WHEN @SITE=N'VN' THEN @YYYYMM ELSE '202508' END
			  AND a.site   = CASE WHEN @SITE=N'VN' THEN @SITE  ELSE 'HQ' END
			  AND a.sel_code = CASE WHEN @SITE=N'VN' THEN @SELCODE ELSE 'ACTUAL' END
			  AND ( (@SITE<>N'VN' AND b.상위계정과목 in (
				'판)임원급여','판)직원급여','판)상여금','판)제수당','판)퇴직급여','판)복리후생비',
				'판)여비교통비','판)접대비','판)통신비','판)수도광열비','판)세금과공과','판)감가상각비',
				'판)지급임차료','판)수선비','판)보험료','판)차량유지비','판)경상연구개발비','판)운반비',
				'판)교육훈련비','판)도서인쇄비','판)소모품비','판)지급수수료','판)광고선전비',
				'판)무형자산상각비','판)견본비','판)사용권자산감가상각비','판)주식보상비용','판)해외시장개척비'
			  ))
			    OR (@SITE=N'VN' AND b.상위계정과목 LIKE N'판)%' AND NULLIF(b.총원가_순서,N'') IS NOT NULL) )
			GROUP BY a.구분, a.model, b.상위계정과목, b.총원가_순서
		),
        SGA AS (
      	SELECT
                  75 rn
                , N'  VI. 판관비' gubun
                , CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE M.구분 END 구분
                , M.model
                , CAST(COALESCE(SUM(X.dist_amt),0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_SMCE_COST X WITH(NOLOCK)
            ON X.YYYYMM = @YYYYMM
                  AND X.SITE   = @SITE
                  AND X.SEL_CODE = @SELCODE
                  AND X.MODEL  = M.model
                  AND M.구분 = CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE M.구분 END
            GROUP BY CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE M.구분 END, M.model
        ),

        TOTAL_COST AS (
            -- VII 총원가 = 당기총제조원가 + 재고조정 + 판관비 + 매출원가조정
			SELECT 110 rn, N'  VII. 총원가' gubun, M.구분, M.model,
                   CAST(COALESCE(A.amt,0) /*+ COALESCE(V.amt,0)*/ + COALESCE(VI.amt,0) /*+ COALESCE(B.amt,0)*/ AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN TOTAL_MFG A ON A.model = M.model AND A.구분 = M.구분 
            --LEFT JOIN INV_ADJ V ON V.model = M.model AND V.구분 = M.구분
            LEFT JOIN SGA     VI ON VI.model = M.model AND VI.구분 = M.구분
            --LEFT JOIN ETC_SALE_BASE B ON B.model  = M.model AND B.구분 = M.구분
        ),
        OP_PROFIT AS (
            -- VIII 영업이익 = 매출액 - 총원가
            SELECT 111 rn, N'  VIII. 영업이익' gubun, M.구분, M.model,
                   CAST(COALESCE(SL.total_sale_amt,0) - COALESCE(TC.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN TOTAL_COST TC  ON TC.model = M.model AND TC.구분 = M.구분
        ),
        OP_MARGIN AS (
            -- VIII 영업이익률 = 영업이익 / 매출액
            SELECT 112 rn, N'    영업이익률' gubun, M.구분, M.model,
                   CAST(
                        CASE WHEN COALESCE(SL.total_sale_amt,0) = 0 THEN NULL
                             ELSE (COALESCE(OP.amt,0) / SL.total_sale_amt) * 100
                        END
                   AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
 			LEFT JOIN OP_PROFIT OP   ON OP.model = M.model AND OP.구분 = M.구분
        ),
        /*==============================================================
    (추가) IX~X 계산용: 변동비/고정비 (모델별)
          - (총합계/양산/개발/카세트) 중에서 "현재 모델의 구분"만 매칭
        ==============================================================*/
        VAR_TOTAL AS (
            SELECT
                  M.구분
                , M.model
                , CAST(COALESCE(SUM(V.amt),0) AS DECIMAL(18,2)) AS var_amt
            FROM #MODEL M
            LEFT JOIN #VAR V
                   ON V.model = M.model
                  AND V.구분 = M.구분
                  --AND V.rn    = 1   -- ✅ 변동비 합계 rn
            GROUP BY M.구분, M.model
        ),
        FIX_TOTAL AS (
            -- VN: 고정비 = 총원가 - 변동비 (DOI_고정비_ByModel이 VN 미지원 → #FIX 공백이라 유도)
            SELECT
                  M.구분
                , M.model
                , CAST(COALESCE(TC.amt,0) - COALESCE(VT.var_amt,0) AS DECIMAL(18,2)) AS fix_amt
            FROM #MODEL M
            LEFT JOIN TOTAL_COST TC ON TC.model = M.model AND TC.구분 = M.구분
            LEFT JOIN VAR_TOTAL  VT ON VT.model = M.model AND VT.구분 = M.구분
        ),
        CM_PROFIT AS (
            -- IX. 한계이익 = 매출액 - 변동비
            SELECT
                  120 rn
                , N'  IX. 한계이익' gubun
                , M.구분
                , M.model
                , CAST(COALESCE(SL.total_sale_amt,0) - COALESCE(VT.var_amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN VAR_TOTAL VT   ON VT.model = M.model AND VT.구분 = M.구분
        ),
        CM_MARGIN AS (
            -- IX. 한계이익률(%) = 한계이익 / 매출액 * 100
            SELECT
                  121 rn
                , N'    한계이익률' gubun
                , M.구분
                , M.model
        , CAST(
                      CASE WHEN COALESCE(SL.total_sale_amt,0) = 0 THEN NULL
                           ELSE (COALESCE(CM.amt,0) / SL.total_sale_amt) * 100
                      END
                  AS DECIMAL(18,2)) AS amt
      FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN CM_PROFIT CM   ON CM.model = M.model AND CM.구분 = M.구분
        ),
        BEP AS (
            -- X. 손익분기점(BEP 매출) = 고정비 / (한계이익/매출액)
            SELECT
  				130 rn
            	, N'  X. 손익분기점' gubun 
                , M.구분
                , M.model
                , CAST(
                      CASE
                        WHEN COALESCE(SL.total_sale_amt,0) = 0 THEN NULL
                        WHEN (COALESCE(CM.amt,0) / NULLIF(SL.total_sale_amt,0)) = 0 THEN NULL
                        ELSE COALESCE(FT.fix_amt,0) / ((COALESCE(CM.amt,0) / SL.total_sale_amt))
                      END  AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN CM_PROFIT CM   ON CM.model = M.model AND CM.구분 = M.구분
            LEFT JOIN FIX_TOTAL FT   ON FT.model = M.model AND FT.구분 = M.구분
        ),
        /* ===== 세부 항목(집계표 골격): doi_stco(제조 622/627) + doi_smce_cost(판관) 브리지 ===== */
        STCO_OH AS (
            SELECT a.구분, a.model, LEFT(dc.계정코드,3) code3,
                   CASE WHEN a.acct_name=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN a.acct_name=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목),N'(간접)',N'') END item,
                   SUM(a.out_amt) amt
            FROM doi_stco a WITH(NOLOCK)
            JOIN (SELECT DISTINCT yyyymm,site,계정과목,계정코드 FROM doi_dept_cost) dc
              ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.acct_name
            JOIN doi_acct b WITH(NOLOCK)
              ON b.yyyymm=a.yyyymm AND b.site=a.site AND b.acct=dc.계정코드
            WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND a.sel_code=@SELCODE
              AND LEFT(dc.계정코드,3) IN ('622','627') AND a.out_amt<>0
              AND ISNULL(CASE WHEN a.acct_name=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN a.acct_name=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목),N'(간접)',N'') END,N'')<>N''
            GROUP BY a.구분, a.model, LEFT(dc.계정코드,3),
                     CASE WHEN a.acct_name=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN a.acct_name=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목),N'(간접)',N'') END
        ),
        LABOR_ITEMS AS (
            SELECT sk.rn, sk.gubun, o.구분, o.model, CAST(SUM(o.amt) AS DECIMAL(18,2)) amt
            FROM STCO_OH o JOIN #SKL_LAB sk ON sk.item=o.item AND o.code3='622'
            GROUP BY sk.rn, sk.gubun, o.구분, o.model
        ),
        EXP_ITEMS AS (
            SELECT sk.rn, sk.gubun, o.구분, o.model, CAST(SUM(o.amt) AS DECIMAL(18,2)) amt
            FROM STCO_OH o JOIN #SKL_EXP sk ON sk.item=o.item AND o.code3='627'
            GROUP BY sk.rn, sk.gubun, o.구분, o.model
        ),
        SGA_OH AS (
            SELECT a.구분, a.model,
                   COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목) item,
                   SUM(a.dist_amt) amt
            FROM doi_smce_cost a WITH(NOLOCK)
            JOIN (SELECT yyyymm,site,계정과목,MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분=N'판관' GROUP BY yyyymm,site,계정과목) dc
              ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.sub_name
            JOIN doi_acct b WITH(NOLOCK)
              ON b.yyyymm=a.yyyymm AND b.site=a.site AND b.acct=dc.계정코드
            WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND a.sel_code=@SELCODE
            GROUP BY a.구분, a.model, COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목)
        ),
        SGA_ITEMS AS (
            SELECT sk.rn, sk.gubun, o.구분, o.model, CAST(SUM(o.amt) AS DECIMAL(18,2)) amt
            FROM SGA_OH o JOIN #SKL_SGA sk ON sk.item=o.item
            GROUP BY sk.rn, sk.gubun, o.구분, o.model
        ),
        FACT AS (
            SELECT rn, gubun, 구분, model, amt FROM SALES_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM QTY_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM PRICE_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM SCOF_BASE
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM ETC_SALE_BASE    		    		
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM MAT_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM LABOR_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM LABOR_ITEMS
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM EXP_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM EXP_ITEMS
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM TOTAL_MFG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM PROD_COGS_FACT
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM MERCH_COGS_FACT
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM ADJ_SALE
--            UNION ALL SELECT rn, gubun, 구분, model, amt FROM INV_ADJ  --26/02/13 KYH삭제
--            UNION ALL SELECT rn, gubun, 구분, model, amt FROM MERCH_COGS    --26/02/13 KYH삭제         
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA        
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA_ITEMS
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM TOTAL_COST
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM OP_PROFIT
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM OP_MARGIN
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM CM_PROFIT
        UNION ALL SELECT rn, gubun, 구분, model, amt FROM CM_MARGIN
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM BEP            
        ),
        BASE AS (
            SELECT
            	R.tree_id
                , R.rn
                , R.gubun
                , M.구분
                , M.model
                , M.pivot_key
                , COALESCE(F.amt, 0) AS amt
            FROM #RN R
            CROSS JOIN #MODEL M
            LEFT JOIN FACT F
                   ON F.rn    = R.rn
                  AND F.gubun = R.gubun
                  AND F.model = M.model
                  AND F.구분 = M.구분
        )
        SELECT 구분, tree_id, rn, gubun, model, pivot_key, amt
        INTO #BASE
        FROM BASE;

        /*==============================================================
          4) 동적 PIVOT + 피벗 후 합계컬럼 생성
             - 총합계 = 양산 + 개발 + 카세트 + 상품매출(NULL) + 기타매출(NULL)
             - (표시는 상품/기타는 NULL, 계산에는 포함 안됨)
        ==============================================================*/
        ;WITH COLS AS (
            SELECT 구분, model, pivot_key, sort_group, sort_structure, sort_numeric FROM #MODEL
        )
        SELECT
              @Columns = STRING_AGG(QUOTENAME(pivot_key), N', ')
           WITHIN GROUP (ORDER BY sort_group, sort_structure, sort_numeric, model)
            , @ModelSelectCols = STRING_AGG(
                    N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0) AS ' + QUOTENAME(pivot_key)
                  , N', '
        ) WITHIN GROUP (ORDER BY sort_group, sort_structure, sort_numeric, model)         
        FROM COLS;

        SELECT
            @SumYangsan = COALESCE(
                STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
           N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'양산'
          AND is_cassette = 0;

		SELECT @SumYangsan_Sale =
		  COALESCE(STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;
		
		SELECT @SumYangsan_Qty =
		  COALESCE(STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;
                  
        SELECT
            @SumDev = COALESCE(
          STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
        WITHIN GROUP (ORDER BY sort_structure, model),
                N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'개발';

       	SELECT @SumDev_Sale =
		  COALESCE(STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
		
		SELECT @SumDev_Qty =
		  COALESCE(STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
       
        SELECT
            @SumCassette = COALESCE(
                STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
                N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;

        SELECT
            @SumCas_Sale = COALESCE(
                STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
                N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;
          
        SELECT
            @SumCas_Qty = COALESCE(
                STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
              N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;             

        SELECT @SumPurchase = COALESCE(
            STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';

        SELECT @SumPur_Sale = COALESCE(
            STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL WHERE 구분 = N'구매';

        SELECT @SumPur_Qty = COALESCE(
            STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL WHERE 구분 = N'구매';  
        
        -------------
		SELECT @SumYangsan_Bep =
		  COALESCE(STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;

       	SELECT @SumDev_Bep =
		  COALESCE(STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
		
       	SELECT
            @SumCas_Bep = COALESCE(
                STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
              N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;             

        SELECT @SumPur_Bep = COALESCE(
            STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';
        ---------------
        -- 한계이익(IX) 모델 합계식 (한계이익률 합계 = 한계이익/매출 계산용)
        SELECT @SumYangsan_Cm =
          COALESCE(STRING_AGG(N'COALESCE(Cm.' + QUOTENAME(pivot_key) + N',0)', N' + ')
            WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL WHERE 구분=N'양산' AND is_cassette=0;

        SELECT @SumDev_Cm =
          COALESCE(STRING_AGG(N'COALESCE(Cm.' + QUOTENAME(pivot_key) + N',0)', N' + ')
            WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL WHERE 구분=N'개발' AND is_cassette=0;

        SELECT @SumCas_Cm = COALESCE(
            STRING_AGG(N'COALESCE(Cm.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'카세트' OR is_cassette = 1;

        SELECT @SumPur_Cm = COALESCE(
            STRING_AGG(N'COALESCE(Cm.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';
        ---------------
		SELECT @SumYangsan_Op =
		  COALESCE(STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;

       	SELECT @SumDev_Op =
		  COALESCE(STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
		
       	SELECT
            @SumCas_Op = COALESCE(
                STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
              N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;     

        SELECT @SumPur_Op = COALESCE(
            STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';     
          
		SET @SQL = N'
		;WITH P AS (
		    SELECT tree_id, TRY_CONVERT(INT, rn) AS rn, gubun, ' + @Columns + N'
		    FROM (
		        SELECT tree_id, TRY_CONVERT(INT, rn) AS rn, gubun, pivot_key, amt
		        FROM #BASE
		    ) S
		    PIVOT (SUM(amt) FOR pivot_key IN (' + @Columns + N')) PV
		)
		SELECT
			Cur.tree_id
      		, Cur.rn
		    , Cur.gubun
		
		    -- ✅ 총합계: 유상사급/매출액만 특수 처리
		    , CAST(
					CASE
					  WHEN Cur.rn = 5 THEN @SCOF
					  WHEN Cur.rn = 4 THEN
					      ((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + '))
					      / NULLIF(((' + @SumYangsan_Qty + ')+(' + @SumDev_Qty + ')+(' + @SumCas_Qty + ')+(' + @SumPur_Qty + ')),0)
            		  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumYangsan_Op + ')+(' + @SumDev_Op + ')+(' + @SumCas_Op + ')+(' + @SumPur_Op +'))
					      /NULLIF(((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ')),0)*100
           			  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
						  ((' + @SumYangsan_Cm + ')+(' + @SumDev_Cm + ')+(' + @SumCas_Cm + ')+(' + @SumPur_Cm + '))
					      /NULLIF(((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ')),0)*100
					  WHEN Cur.rn = 1 THEN ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + ')) - @SCOF
					  ELSE ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + '))
					END
		      AS DECIMAL(18,2)) AS [총합계]
		
		    -- ✅ 양산/개발/카세트 합계: 유상사급은 0으로
		    , CAST(
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumYangsan_Sale + ') / NULLIF((' + @SumYangsan_Qty + '),0))
            	  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumYangsan_Op  +'))
					      /NULLIF(((' + @SumYangsan_Sale + ')),0)*100
         		  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
					  (' + @SumYangsan_Cm + ')
				      /NULLIF((' + @SumYangsan_Sale + '),0)*100
				  ELSE (' + @SumYangsan + ')
				END AS DECIMAL(18,2)) AS [양산합계]
			, CAST(
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumDev_Sale + ') / NULLIF((' + @SumDev_Qty + '),0))
            	  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumDev_Op +'))
					      /NULLIF(((' + @SumDev_Sale + ')),0)*100
          		  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
					  (' + @SumDev_Cm + ')
				      /NULLIF((' + @SumDev_Sale + '),0)*100
				  ELSE (' + @SumDev + ')
				END AS DECIMAL(18,2)) AS [개발합계]
			, CAST(	
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumCas_Sale + ') / NULLIF((' + @SumCas_Qty + '),0))
				  ELSE (' + @SumCassette + ')
				END AS DECIMAL(18,2)) AS [카세트합계]

            , CAST( 
                CASE
                  WHEN Cur.rn = 5 THEN 0
                  WHEN Cur.rn = 4 THEN ((' + @SumPur_Sale + ') / NULLIF((' + @SumPur_Qty + '),0))
                  ELSE (' + @SumPurchase + ')
                END AS DECIMAL(18,2)) AS [구매합계]
		
		    -- 요청: 상품/기타매출은 NULL
		    , CAST(NULL AS DECIMAL(18,2)) AS [상품매출]
		    , CAST(NULL AS DECIMAL(18,2)) AS [기타매출]
		
		    , ' + @ModelSelectCols + N'
		FROM P Cur
		LEFT JOIN P Sales ON Sales.rn = 1 
		LEFT JOIN P Qty   ON Qty.rn   = 3
    	LEFT JOIN P Op    ON LTRIM(Op.gubun) = N''VIII. 영업이익''
    	LEFT JOIN P Cm    ON LTRIM(Cm.gubun) = N''IX. 한계이익''
    	LEFT JOIN P Bep   ON LTRIM(Bep.gubun) LIKE N''X. 손익분기점%''
		ORDER BY TRY_CONVERT(INT, Cur.rn);
		';
		
		--SELECT @SQL;
		EXEC sp_executesql @SQL, N'@SCOF DECIMAL(18,2)', @SCOF = @SCOFTotal;

        DROP TABLE #BASE;
        DROP TABLE #RN;
        DROP TABLE #MODEL;
        DROP TABLE #SALES_BASE;
        DROP TABLE #VAR;
        DROP TABLE #FIX;
        DROP TABLE #SKL_LAB; DROP TABLE #SKL_EXP; DROP TABLE #SKL_SGA;       

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT 
         ERROR_NUMBER()  AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE()   AS ErrorState,
        ERROR_LINE()    AS ErrorLine,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_MESSAGE() AS ErrorMessage;
       
    THROW;   
    END CATCH
END;

