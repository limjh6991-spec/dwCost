-- [2026-09-22] DOI_PL_ByModel — (1)양품(출고) 화면정합 + (3)폐기/실사조정 재정의
--  (1)제품매출원가 = 매출원가(제품) 화면 양품: 후처리월=SUM(out_amt,비LOSS,ACCT_NAME<>'기타출고') / 그외월=SUM(out_amt-OUTETC_AMT,비LOSS,ACCT_NAME<>'기타출고').
--  (3)조정 = 전량LOSS+제품폐기+재공품폐기(COGS_ADJ) + 원부재료폐기+실사조정(@CostAdj). 기타매출 배제.
--  검증(202601~202608 8개월): (1) 화면 양품값과 전월 일치. 202608 (3)조정 110,090,849·매출원가 3,935,942,749·영업이익 383,990,006 — TotalCost_Tree와 tie-out.

ALTER PROCEDURE DOI_PL_ByModel --운영
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
		DECLARE @SCRAP_ADJ   DECIMAL(18,2) = 0;   -- 원부재료 재고폐기 (DOI_ETC_INOUT, 본사 전용) [case2①]
		DECLARE @InvAdj      DECIMAL(18,2) = 0;   -- 재고실사조정 (DOI_ETC_INOUT '실사재고조정', 본사 전용) [case4]
       	DROP TABLE IF EXISTS #MODEL;
		----------------------------------------------------------------------
		-- 1-0. [2026-09-16b] 매출 ↔ 재고평가 매칭 키 (#SALEKEY)
		--   종전에는 재고평가의 MODEL 과 매출의 '품명' 을 맞췄다. 품명은 자유 텍스트라
		--   카세트처럼 품목명이 들어오면(VINA N_OPPO 하단틀) 매칭이 깨져 원가가 통째로 누락됐다.
		--   → 매출의 '품번' 기준으로 바꾼다. 품번은 대개 모델코드+구분접미(P/D/T)지만
		--     접미가 없는 품번도 있어(818VT, VN034P1~P3) 무조건 1자를 떼면 818VT 가 818V 에 붙는다.
		--   규칙 ① 품번이 재고평가 MODEL 에 있으면 품번        (818VT, VN034P1~P3)
		--        ② 접미 1자를 뗀 값이 MODEL 에 있으면 그 값     (8136P→8136 등 일반)
		--        ③ 둘 다 아니면 품명                            (상품 등 재고평가가 없는 건)
		----------------------------------------------------------------------
		DROP TABLE IF EXISTS #STCO_MODEL;
		SELECT DISTINCT MODEL
		INTO #STCO_MODEL
		FROM DOI_STCO WITH(NOLOCK)
		WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SEL_CODE = @SEL_CODE;
		DROP TABLE IF EXISTS #SALEKEY;
		SELECT S.품번,
		       CASE WHEN M1.MODEL IS NOT NULL THEN S.품번
		            WHEN M2.MODEL IS NOT NULL THEN LEFT(S.품번, LEN(S.품번)-1)
		            ELSE S.품명 END AS model
		INTO #SALEKEY
		FROM (
			SELECT 품번, MAX(품명) AS 품명
			FROM (
				SELECT 품번, 품명 FROM DOI_SALE_RESC    WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE
				UNION ALL
				SELECT 품번, 품명 FROM DOI_INVOICE_RESC WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE
			) A
			WHERE NULLIF(LTRIM(RTRIM(품번)),'') IS NOT NULL
			GROUP BY 품번
		) S
		LEFT JOIN #STCO_MODEL M1 ON M1.MODEL = S.품번
		LEFT JOIN #STCO_MODEL M2 ON LEN(S.품번) > 1 AND M2.MODEL = LEFT(S.품번, LEN(S.품번)-1);
		----------------------------------------------------------------------
		-- [재고평가손실] DOI_재고자산평가 품번→모델키 매핑 후 구분별 조정금액 집계 (#INVEVAL)
		--   재공품/제품 무관 SUM(조정금액), 동일품번 양쪽이면 합산. 매핑=#STCO_MODEL 규칙(#SALEKEY 동일).
		----------------------------------------------------------------------
		DROP TABLE IF EXISTS #INVEVAL;
		;WITH EVAL_MAP AS (
		    SELECT
		        CASE WHEN ev.품번 LIKE N'VN%' THEN N'카세트' ELSE ev.구분 END AS 구분,
		        CASE WHEN ev.품번 LIKE N'VN%' THEN ev.품번
		             WHEN EXISTS(SELECT 1 FROM #STCO_MODEL sm WHERE sm.MODEL=ev.품번) THEN ev.품번
		             WHEN LEN(ev.품번)>1 AND EXISTS(SELECT 1 FROM #STCO_MODEL sm WHERE sm.MODEL=LEFT(ev.품번,LEN(ev.품번)-1)) THEN LEFT(ev.품번,LEN(ev.품번)-1)
		             ELSE ev.품번 END AS model,
		        ev.조정금액
		    FROM DOI_재고자산평가 ev WITH(NOLOCK)
		    WHERE ev.YYYYMM=@YYYYMM AND ev.SITE=@SITE AND ev.SEL_CODE=@SEL_CODE
		)
		SELECT 구분, model, CAST(SUM(조정금액) AS DECIMAL(18,2)) AS amt
		INTO #INVEVAL
		FROM EVAL_MAP GROUP BY 구분, model HAVING SUM(조정금액) <> 0;
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
		        COALESCE(SK.model, A.품명) AS model   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    LEFT JOIN #SALEKEY SK ON SK.품번 = A.품번   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
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
		        COALESCE(SK.model, B.품명) AS model   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    LEFT JOIN #SALEKEY SK ON SK.품번 = B.품번   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
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
		SELECT CASE WHEN LEFT(S.MODEL,2) = N'VN' THEN N'카세트' ELSE S.구분 END, S.MODEL   /* [2026-09-16b] 원가 쪽 구분도 카세트로 (모델키는 이미 VN034P*) */
		FROM DOI_STCO S
		WHERE 1=1
		   AND S.YYYYMM = @YYYYMM
		   AND S.SITE   = @SITE
		   AND S.SEL_CODE = @SEL_CODE
		   AND S.ACCT_NAME LIKE '기타출고'
		UNION
		SELECT
			CASE WHEN O.모델 = N'회계-조정' THEN N'회계' ELSE O.구분 END AS 구분, CASE WHEN O.모델 = N'회계-조정' THEN O.모델 ELSE LEFT(O.모델, LEN(O.모델)-1) END AS model
		FROM DOI_원장상계 O
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND COALESCE(O.매출상계,0) <> 0
		UNION
		-- 제품 폐기만 발생한 모델도 손익 대상에 포함.
		-- 매출이 없으면 위 UNION 들에 안 잡히는데, 폐기는 (3)제품매출원가조정으로 반영해야 하므로 모델을 살린다.
		-- DOI_STCO 의 폐기 행은 구분='RMA' 로 들어오므로 같은 모델의 정상 구분을 끌어온다.
		SELECT
		    CASE WHEN LEFT(D.MODEL,2) = N'VN' THEN N'카세트'   /* [2026-09-16b] 원가 쪽 구분도 카세트로 (모델키는 이미 VN034P*) */
		         ELSE COALESCE(MAX(CASE WHEN D.구분 <> N'RMA' THEN D.구분 END), N'양산') END AS 구분,
		    D.MODEL AS model
		FROM DOI_STCO D WITH(NOLOCK)
		WHERE D.YYYYMM = @YYYYMM AND D.SITE = @SITE AND D.SEL_CODE = @SEL_CODE
		GROUP BY D.MODEL
		HAVING SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) <> 0
		UNION
		-- [재고평가손실] 매출/폐기 없어도 모델 편입 (개발 815Y/815Z/8169 등 컬럼 생성)
		SELECT E.구분, E.model FROM #INVEVAL E
		)
		SELECT DISTINCT
		    model, 구분
		INTO #MODEL
		FROM MODEL_LIST;
		----------------------------------------------------------------------
		-- 1-1. 제품 폐기 (매출원가(제품) 화면 출고상세-폐기) : 모델별
		----------------------------------------------------------------------
		DROP TABLE IF EXISTS #DISPOSE;
		SELECT
		    CASE WHEN LEFT(D.MODEL,2) = N'VN' THEN N'카세트'  /* [2026-09-16b] 원가 쪽 구분도 카세트로 (모델키는 이미 VN034P*) */
		         ELSE COALESCE(MAX(CASE WHEN D.구분 <> N'RMA' THEN D.구분 END), N'양산') END AS 구분,
		    D.MODEL AS model,
		    CAST(SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) AS DECIMAL(18,2)) AS amt
		INTO #DISPOSE
		FROM DOI_STCO D WITH(NOLOCK)
		WHERE D.YYYYMM = @YYYYMM AND D.SITE = @SITE AND D.SEL_CODE = @SEL_CODE
		GROUP BY D.MODEL
		HAVING SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) <> 0;
		SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
		FROM DOI_SCOF WITH(NOLOCK)
		WHERE yyyymm   = @YYYYMM
		  AND site     = @SITE
		  AND SEL_CODE = @SEL_CODE;
		/* [이미지스펙으로 폐기] 구 @CostAdj = DOI_DEPT_COST 제품매출원가 대변. (3)조정 회계는 원부재료폐기+실사조정으로 재정의(아래 SET).
		SELECT @CostAdj = COALESCE(ABS(SUM(ISNULL(대변금액,0))), 0)
		FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND 계정과목=N'제품매출원가' AND 대변금액<>0;
		*/
		SELECT @LossAdj = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE;
		SELECT @SCOF_ACC = CAST(COALESCE(SUM(매출상계),0) AS DECIMAL(18,2))
		FROM DOI_원장상계 WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE AND 구분 = N'회계';
		-- 원부재료 재고폐기: 기타입출고금액(통합)에서 '재고폐기' AND 품목자산분류<>'제품'.
		-- 회계 열('회계-조정')의 (3)제품매출원가조정에 가산한다. 본사 전용(VN 미적용).
		IF @SITE = 'HQ'
		BEGIN
			-- [case2①] 원부재료 폐기 = 기타입출고 '재고폐기' AND 품목자산분류<>'제품'
			SELECT @SCRAP_ADJ = CAST(COALESCE(SUM(금액),0) AS DECIMAL(18,2))
			FROM DOI_ETC_INOUT WITH(NOLOCK)
			WHERE yyyymm = @YYYYMM
			  AND 기타입출고구분 = N'재고폐기'
			  AND 품목자산분류 <> N'제품';
			-- [case4] 재고실사조정 = 기타입출고 '실사재고조정'(수량/원가 구분없이 text 기준)
			SELECT @InvAdj = CAST(COALESCE(SUM(금액),0) AS DECIMAL(18,2))
			FROM DOI_ETC_INOUT WITH(NOLOCK)
			WHERE yyyymm = @YYYYMM
			  AND 기타입출고구분 LIKE N'실사재고조정%';
		END
		-- [이미지스펙] (3)제품매출원가조정 회계열 = 원부재료폐기(case2①) + 재고실사조정(case4). 회계-조정 모델행에 가산.
		SET @CostAdj = @SCRAP_ADJ + @InvAdj;
		-- [양품산식] (1)제품매출원가 = 매출원가(제품) 화면 양품(출고)+양품(반품입고). 후처리월=OUT_AMT / 그외월=OUT_AMT-OUTETC(타계정 제외).
		DECLARE @IsPostProc BIT = 0;
		SELECT @IsPostProc = CASE WHEN EXISTS(SELECT 1 FROM DOI_STCO WITH(NOLOCK)
		    WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE
		      AND (ISNULL(OUT_GOOD_AMT,0)<>0 OR ISNULL(OUT_GOOD_QTY,0)<>0 OR ISNULL(OUT_GOOD_RTN_AMT,0)<>0 OR ISNULL(OUT_GOOD_RTN_QTY,0)<>0))
		    THEN 1 ELSE 0 END;
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
		        , COALESCE(SK.model, A.품명) AS model   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
		        , N'국내'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , A.원화판매금액   AS amt
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    LEFT JOIN #SALEKEY SK ON SK.품번 = A.품번   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
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
		        , COALESCE(SK.model, B.품명) AS model   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
		        , N'해외'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , B.원화판매금액   AS amt
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    LEFT JOIN #SALEKEY SK ON SK.품번 = B.품번   /* [2026-09-16b] 매칭키: 품명 → 품번 기준 */
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
		        CASE WHEN LEFT(S.MODEL,2) = N'VN' THEN N'카세트' ELSE S.구분 END AS 구분   /* [2026-09-16b] 원가 쪽 구분도 카세트로 (모델키는 이미 VN034P*) */
		        , S.MODEL AS model
		        , SUM(ISNULL(S.BOH_AMT, 0)) AS begin_fg_amt
		        , SUM(ISNULL(S.IN_AMT, 0))  AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , SUM(ISNULL(S.EOH_AMT, 0)) AS end_fg_amt
		        , SUM(CASE WHEN ISNULL(S.ACCT_NAME,N'') <> N'기타출고' THEN S.out_amt - CASE WHEN @IsPostProc=1 THEN 0 ELSE ISNULL(S.OUTETC_AMT,0) END ELSE 0 END) AS prod_cogs_amt  -- [양품산식] 그외월 타계정(OUTETC) 차감, 화면과 동일하게 '기타출고' 행 제외
		    FROM DOI_STCO S
		    WHERE S.YYYYMM   = @YYYYMM
		      AND S.SITE     = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.COST_TYPE != 'LOSS'
		    GROUP BY CASE WHEN LEFT(S.MODEL,2) = N'VN' THEN N'카세트' ELSE S.구분 END, S.MODEL
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
		    -- [이미지스펙] (3)제품매출원가조정 모델부 = 전량LOSS(case1) + 제품폐기(case2③ #DISPOSE) + 재공품폐기(case2②)
		    SELECT 구분, model, CAST(SUM(amt) AS DECIMAL(18,2)) AS adj_amt FROM (
		        SELECT CASE WHEN LEFT(a.model,2)=N'VN' THEN N'카세트' ELSE a.구분 END AS 구분, a.model, SUM(ISNULL(a.LOSS,0)) AS amt
		        FROM DOI_COST a WITH(NOLOCK)
		        WHERE a.YYYYMM = @YYYYMM AND a.SITE = @SITE AND a.SEL_CODE = @SEL_CODE
		          AND ISNULL(a.OUT_QTY,0)=0 AND ISNULL(a.EOH_QTY,0)=0 AND ISNULL(a.LOSS_QTY,0)<>0  -- 전량 LOSS
		        GROUP BY CASE WHEN LEFT(a.model,2)=N'VN' THEN N'카세트' ELSE a.구분 END, a.model
		        UNION ALL
		        SELECT 구분, model, amt FROM #DISPOSE    -- 제품폐기(case2③): DOI_STCO OUT_DISPOSE
		        UNION ALL
		        SELECT CASE WHEN LEFT(b.model,2)=N'VN' THEN N'카세트' ELSE b.구분 END, b.model, SUM(ISNULL(b.ETC_OUT_ETC_AMT,0))  -- 재공품폐기(case2②)
		        FROM DOI_COST b WITH(NOLOCK)
		        WHERE b.YYYYMM=@YYYYMM AND b.SITE=@SITE AND b.SEL_CODE=@SEL_CODE AND ISNULL(b.ETC_OUT_ETC_AMT,0)<>0
		        GROUP BY CASE WHEN LEFT(b.model,2)=N'VN' THEN N'카세트' ELSE b.구분 END, b.model
		    ) u GROUP BY 구분, model
		)
        , SGNA_BASE AS (
            ------------------------------------------------------------------
            -- (4) 판관비
            ------------------------------------------------------------------
            SELECT
            	CASE WHEN LEFT(X.MODEL,2) = N'VN' THEN N'카세트' ELSE X.구분 END AS 구분   /* [2026-09-16b] 원가 쪽 구분도 카세트로 (모델키는 이미 VN034P*) */
                , X.MODEL         AS model
                , X.SUB_NAME
                , SUM(ISNULL(X.DIST_AMT,0)) AS amt      -- 배부된 판관비 금액
            FROM DOI_SMCE_COST X
            WHERE X.YYYYMM 	= @YYYYMM
              AND X.SITE 		= @SITE
              AND X.SEL_CODE  = @SEL_CODE 
            GROUP BY CASE WHEN LEFT(X.MODEL,2) = N'VN' THEN N'카세트' ELSE X.구분 END, X.MODEL, X.SUB_NAME
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
            UNION ALL
            SELECT 12.5 rn, '    (4) 재고금액평가손실' gubun, M.구분, M.model, ISNULL(EL.amt,0) AS amt FROM #MODEL M
            LEFT JOIN #INVEVAL EL ON EL.구분 = M.구분 AND EL.model = M.model
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
        -- 9-1. 원부재료 재고폐기를 회계 열('회계-조정')에 반영
        --      (3)제품매출원가조정(rn12)에 가산 → II.매출원가(rn5) 증가,
        --      III.매출총이익(rn13)·V.영업이익(rn141) 은 그만큼 감소.
        --      Z합계/Z합계회계 보다 먼저 적용해야 상위 합계에 전파된다.
        ----------------------------------------------------------------------
        IF @CostAdj <> 0   -- [스펙] (3)회계열 = 회계-조정(@CostAdj: DOI_DEPT_COST 제품매출원가 대변)
        BEGIN
            UPDATE #sourceTable SET amt = COALESCE(amt,0) + @CostAdj
             WHERE 구분 = N'회계' AND model = N'회계-조정' AND rn IN (5, 12);
            UPDATE #sourceTable SET amt = COALESCE(amt,0) - @CostAdj
             WHERE 구분 = N'회계' AND model = N'회계-조정' AND rn IN (13, 141);
        END
        ----------------------------------------------------------------------
        -- 9-2. 제품 폐기를 모델별 (3)제품매출원가조정 에 반영
        --      매출원가(제품) 화면 출고상세-폐기(DOI_STCO.OUT_DISPOSE_AMT) 기준.
        --      rn12 가산 → rn5(II.매출원가) 증가, rn13·rn141 은 그만큼 감소.
        --      Z합계/구분별 합계보다 먼저 적용해야 상위 합계에 전파된다.
        ----------------------------------------------------------------------
        -- [제품폐기 제외: 스펙 (3)=전량LOSS+회계조정, 폐기 미포함] (rn5,12 가산 제거)
        -- [제품폐기 제외] (rn13,141 차감 제거)
        ----------------------------------------------------------------------
        -- 9-3. 재고금액평가손실(DOI_재고자산평가.조정금액) 반영
        --      (4)행(rn12.5)은 PL_HEAD 생성. II.매출원가(rn5) 가산, III.매출총이익(rn13)·V.영업이익(rn141) 차감.
        ----------------------------------------------------------------------
        UPDATE s SET amt = COALESCE(s.amt,0) + e.amt
          FROM #sourceTable s JOIN #INVEVAL e ON e.구분 = s.구분 AND e.model = s.model
         WHERE s.rn = 5;
        UPDATE s SET amt = COALESCE(s.amt,0) - e.amt
          FROM #sourceTable s JOIN #INVEVAL e ON e.구분 = s.구분 AND e.model = s.model
         WHERE s.rn IN (13, 141);
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
