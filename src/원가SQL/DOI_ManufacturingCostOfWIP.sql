CREATE           PROCEDURE DOI_ManufacturingCostOfWIP
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
	            FROM DOI_COST C WITH (NOLOCK)
	            LEFT JOIN dw_모델기본정보 B
	                   ON B.model = C.MODEL
	                  AND B.구분 = C.구분
	            WHERE SUBSTRING(C.YYYYMM, 1, 4) = @YYYY
	              AND C.SITE = @SITE     -- 사업장 필터(HQ / VN)
	              AND C.SEL_CODE = @SEL_CODE
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

                , AVG(BOH_QTY) AS BOH_QTY
                , SUM(BOH+ADJ_BOH)     AS BOH_AMT

                , AVG(IN_QTY)  AS IN_QTY
                , SUM([IN])    AS IN_AMT

                , AVG(OUT_QTY)    AS OUT_QTY
                , SUM([OUT]+ADJ_BOH)      AS OUT_AMT

                , AVG(LOSS_QTY)   AS LOSS_QTY
                , SUM(LOSS)       AS LOSS_AMT
                -- RMA_IN (타계정입고)
                , AVG(BOH_QTY) AS OUT_ETC_QTY
                , SUM(OUT_ETC) AS OUT_ETC_AMT
                , (
                    SUM(LOSS) * 1.0 
                    / NULLIF(SUM(BOH) + SUM([IN]), 0) * 100
                  ) AS 불량률

                , AVG(EOH_QTY)    AS EOH_QTY
                , SUM(EOH)        AS EOH_AMT
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
            
            -- 타계정입고(RMA_IN)
        	, NULL RMA_IN_QTY
            , NULL RMA_IN_AMT
            
            -- 타계정출고(RMA_OUT) : 현재 미사용 → NULL
            , CASE WHEN SA.OUT_ETC_AMT != 0 THEN SA.OUT_ETC_QTY ELSE 0 END     AS OUT_ETC_QTY
            , SA.OUT_ETC_AMT      AS OUT_ETC_AMT
            
            , SA.불량률       AS 불량률
            
            -- 기말재공품재고(EOH)
            , SA.EOH_QTY
            , SA.EOH_AMT

        FROM #MODEL_BASE M
        CROSS JOIN #GEN_YYYYMM G
        INNER JOIN #COST_AGG SA
               ON SA.YYYYMM = G.YYYYMM
              AND SA.SITE   = @SITE
              AND SA.MODEL  = M.모델
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