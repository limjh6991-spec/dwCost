CREATE OR ALTER PROCEDURE DOI_ManufacturingCostOfWIP
(
    @YYYY VARCHAR(4),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        ------------------------------------------------------------
        -- 1. 연도 기준 YYYYMM 생성 (1~12월)
        ------------------------------------------------------------
        ;WITH GEN_YYYYMM AS (
            SELECT 
                  CAST(@YYYY + '0101' AS DATE) AS DT
                , FORMAT(CAST(@YYYY + '0101' AS DATE), 'yyyyMM') AS YYYYMM
                , 1 AS 월번호
            UNION ALL
            SELECT 
                  DATEADD(MONTH, 1, DT)
                , FORMAT(DATEADD(MONTH, 1, DT), 'yyyyMM')
                , MONTH(DATEADD(MONTH, 1, DT))
            FROM GEN_YYYYMM
            WHERE DT < CAST(@YYYY + '1201' AS DATE)
        )
        SELECT *
        INTO #GEN_YYYYMM
        FROM GEN_YYYYMM
        OPTION (MAXRECURSION 12);
        ------------------------------------------------------------
        -- 2. 모델 기준 목록 생성 (SOURCE = DOI_COST)
        ------------------------------------------------------------
        ;WITH MODEL_BASE AS (
        	SELECT *, 
        	row_number() over(partition by 모델 order by case when Inch is null then '0' else '1' end + 구분 DESC) as RN  
        	FROM (
	            SELECT DISTINCT
	                  C.SITE
	                , C.MODEL AS 모델
	                , C.구분
	                , B.원장_두께 AS 두께
	                , B.대각인치 AS Inch
	                , B.고객사   AS 판매처
	                , CASE 
	                      WHEN LEFT(C.MODEL, 1) = 'I' THEN 'ITG'
	                      WHEN LEFT(C.MODEL, 1) = 'H' THEN 'HTG'
	                      WHEN LEFT(C.MODEL, 1) = 'C' THEN 'Coated'
	                      ELSE 'UTG'
	                  END AS 제품구조
	            FROM ( SELECT SITE,MODEL,구분 FROM DOI_COST  WITH (NOLOCK) 
	            		WHERE SUBSTRING(YYYYMM, 1, 4) = @YYYY
	            		  AND SEL_CODE=@SEL_CODE
	            		  AND SITE=@SITE
	            	    UNION
	                 	SELECT SITE,MODEL,구분 FROM DOI_BOH_AMT  WITH (NOLOCK) 
	            		WHERE SUBSTRING(YYYYMM, 1, 4) = @YYYY
	            		  AND SEL_CODE=@SEL_CODE
	            		  AND SITE=@SITE
	            	  ) C  
	            LEFT JOIN dw_모델기본정보 B
	                   ON B.model = C.MODEL
	                  AND B.구분 = C.구분
	            /*WHERE SUBSTRING(C.YYYYMM, 1, 4) = @YYYY
	              AND C.SITE = @SITE     -- 사업장 필터(HQ / VN)
	              AND C.SEL_CODE = @SEL_CODE*/
	        )A
        )
        SELECT *
        INTO #MODEL_BASE
        FROM MODEL_BASE WHERE RN = 1;
        ------------------------------------------------------------
        -- 3. COST 집계 (#COST_AGG)
        --    - 불량률 = LOSS / (BOH + IN)
        ------------------------------------------------------------
        ;WITH COST_AGG AS (
            SELECT
                  YYYYMM
                , SITE
                , 구분
                , MODEL
                , MAX(BOH_QTY) AS BOH_QTY
                , SUM(CASE WHEN [in] is null then 0 else BOH end + ADJ_BOH )  AS BOH_AMT
                , MAX(IN_QTY)  AS IN_QTY
                , SUM([IN])    AS IN_AMT
                , MAX(OUT_QTY)    AS OUT_QTY
                , SUM([OUT]+ADJ_BOH)      AS OUT_AMT
                , MAX(LOSS_QTY)   AS LOSS_QTY
                , SUM(LOSS)       AS LOSS_AMT
                -- RMA_IN (타계정입고)
                , MAX(BOH_QTY) AS OUT_ETC_QTY
                , SUM(OUT_ETC) AS OUT_ETC_AMT
                , (
                    SUM(LOSS) * 1.0 
                    / NULLIF(SUM(BOH) + SUM([IN]), 0) * 100
                  ) AS 불량률
                , MAX(EOH_QTY)    AS EOH_QTY
                , SUM(EOH)        AS EOH_AMT
                , MAX(LOSS_DEFECT_QTY)      AS LOSS_DEFECT_QTY
				, SUM(LOSS_DEFECT_AMT)      AS LOSS_DEFECT_AMT
				, MAX(LOSS_SALE_QTY)        AS LOSS_SALE_QTY
				, SUM(LOSS_SALE_AMT)        AS LOSS_SALE_AMT
				, MAX(ETC_IN_LOT_QTY)       AS ETC_IN_LOT_QTY
				, SUM(ETC_IN_LOT_AMT)       AS ETC_IN_LOT_AMT
				, MAX(ETC_IN_DEF_RW_QTY)    AS ETC_IN_DEF_RW_QTY
				, SUM(ETC_IN_DEF_RW_AMT)    AS ETC_IN_DEF_RW_AMT
				, MAX(ETC_IN_RMA_QTY)       AS ETC_IN_RMA_QTY
				, SUM(ETC_IN_RMA_AMT)       AS ETC_IN_RMA_AMT
				, MAX(ETC_IN_PREV_DEF_QTY)  AS ETC_IN_PREV_DEF_QTY
				, SUM(ETC_IN_PREV_DEF_AMT)  AS ETC_IN_PREV_DEF_AMT
				, MAX(ETC_IN_CUR_DEF_QTY)   AS ETC_IN_CUR_DEF_QTY
				, SUM(ETC_IN_CUR_DEF_AMT)   AS ETC_IN_CUR_DEF_AMT
				, MAX(ETC_OUT_LOT_QTY)      AS ETC_OUT_LOT_QTY
				, SUM(ETC_OUT_LOT_AMT)      AS ETC_OUT_LOT_AMT
				, MAX(ETC_OUT_ETC_QTY)      AS ETC_OUT_ETC_QTY
				, SUM(ETC_OUT_ETC_AMT)      AS ETC_OUT_ETC_AMT
            FROM DOI_COST WITH (NOLOCK)
            WHERE SUBSTRING(YYYYMM,1,4) = @YYYY
              AND SITE 		= @SITE --and adj_yn='Y'
              AND SEL_CODE  = @SEL_CODE 
            GROUP BY YYYYMM, SITE, MODEL, 구분
        )
        SELECT *
        INTO #COST_AGG
        FROM COST_AGG;
        ------------------------------------------------------------
        -- 4. 최종 결과 출력
        ------------------------------------------------------------
        SELECT
              SA.구분
            , M.모델
            , M.Inch
            , M.판매처
            , CAST(G.월번호 AS VARCHAR(2)) + '월' AS 월
  -- 기초재공품재고(BOH)
            , SA.BOH_QTY
            , SA.BOH_AMT
            -- 입고(IN)
            , SA.IN_QTY
            , SA.IN_AMT
            -- 출고(OUT)
            , SA.OUT_QTY
            , SA.OUT_AMT
            -- LOSS
            , SA.LOSS_QTY
            , SA.LOSS_AMT
            , SA.LOSS_DEFECT_QTY
			, SA.LOSS_DEFECT_AMT
			, SA.LOSS_SALE_QTY
			, SA.LOSS_SALE_AMT
            -- 타계정입고(RMA_IN) = 입고 상세 컬럼 합계
        	, (ISNULL(SA.ETC_IN_LOT_QTY,0) + ISNULL(SA.ETC_IN_DEF_RW_QTY,0) + ISNULL(SA.ETC_IN_RMA_QTY,0) + ISNULL(SA.ETC_IN_PREV_DEF_QTY,0) + ISNULL(SA.ETC_IN_CUR_DEF_QTY,0)) AS RMA_IN_QTY
            , (ISNULL(SA.ETC_IN_LOT_AMT,0) + ISNULL(SA.ETC_IN_DEF_RW_AMT,0) + ISNULL(SA.ETC_IN_RMA_AMT,0) + ISNULL(SA.ETC_IN_PREV_DEF_AMT,0) + ISNULL(SA.ETC_IN_CUR_DEF_AMT,0)) AS RMA_IN_AMT
            , SA.ETC_IN_LOT_QTY
			, SA.ETC_IN_LOT_AMT
			, SA.ETC_IN_DEF_RW_QTY
			, SA.ETC_IN_DEF_RW_AMT
			, SA.ETC_IN_RMA_QTY
			, SA.ETC_IN_RMA_AMT
			, SA.ETC_IN_PREV_DEF_QTY
			, SA.ETC_IN_PREV_DEF_AMT
			, SA.ETC_IN_CUR_DEF_QTY
			, SA.ETC_IN_CUR_DEF_AMT
            -- 타계정출고(RMA_OUT) : 현재 미사용 → NULL
            , CASE WHEN SA.OUT_ETC_AMT != 0 THEN SA.OUT_ETC_QTY ELSE 0 END     AS OUT_ETC_QTY
            , SA.OUT_ETC_AMT      AS OUT_ETC_AMT
            , SA.ETC_OUT_LOT_QTY
			, SA.ETC_OUT_LOT_AMT
			, SA.ETC_OUT_ETC_QTY
			, SA.ETC_OUT_ETC_AMT
            , SA.불량률       AS 불량률
            -- PL전/PL후 (재공 완성률 환산 수량, EOH 왼쪽)
            , PS.PL전 AS PL_BEFORE
            , PS.PL후 AS PL_AFTER
            -- PL전/PL후 금액 (EOH_AMT를 완성환산비율 PL전×0.5 : PL후×0.9 로 안분)
            , CAST(ROUND(SA.EOH_AMT * (ISNULL(PS.PL전,0)*0.5)
                   / NULLIF(ISNULL(PS.PL전,0)*0.5 + ISNULL(PS.PL후,0)*0.9, 0), 2) AS decimal(18,2)) AS PL_BEFORE_AMT
            , CAST(ROUND(SA.EOH_AMT * (ISNULL(PS.PL후,0)*0.9)
                   / NULLIF(ISNULL(PS.PL전,0)*0.5 + ISNULL(PS.PL후,0)*0.9, 0), 2) AS decimal(18,2)) AS PL_AFTER_AMT
            -- 기말재공품재고(EOH)
            , SA.EOH_QTY
            , SA.EOH_AMT
        FROM #MODEL_BASE M
        CROSS JOIN #GEN_YYYYMM G
        INNER JOIN #COST_AGG SA
               ON SA.YYYYMM = G.YYYYMM
              AND SA.SITE   = @SITE
              AND SA.MODEL  = M.모델
        LEFT JOIN (
            SELECT yyyymm, site, 구분, 도우모델 AS model,
                   SUM(TRY_CONVERT(int, REPLACE(REPLACE(ISNULL(PL전, N'0'), N',', N''), N' ', N''))) AS PL전,
                   SUM(TRY_CONVERT(int, REPLACE(REPLACE(ISNULL(PL후, N'0'), N',', N''), N' ', N''))) AS PL후
            FROM doi_prod_subul WITH (NOLOCK)
            WHERE site = @SITE
            GROUP BY yyyymm, site, 구분, 도우모델
        ) PS ON PS.yyyymm = G.YYYYMM AND PS.site = @SITE AND PS.model = M.모델 AND PS.구분 = SA.구분
        ORDER BY SA.구분, M.모델, G.월번호;
        ------------------------------------------------------------
        -- 5. 임시테이블 삭제
        ------------------------------------------------------------
        DROP TABLE #GEN_YYYYMM;
        DROP TABLE #MODEL_BASE;
        DROP TABLE #COST_AGG;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
