CREATE                 PROCEDURE DOI_ProductCOGS
(
    @YYYY VARCHAR(4),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ----------------------------------------------------------------------
        -- 1. 연도 기준 YYYYMM 생성
        ----------------------------------------------------------------------
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


        ----------------------------------------------------------------------
        -- 2. 모델 기준 목록 생성 (INCH / 두께 / 제품구조 포함)
        ----------------------------------------------------------------------
        ;WITH MODEL_BASE AS (
            SELECT 
                  S.SITE AS SITE
                , S.구분
                , S.MODEL AS 모델
                , MAX(B.원장_두께) AS 두께
                , MAX(B.대각인치) AS Inch
                , MAX(B.고객사) AS 고객사
                , CASE 
                      WHEN LEFT(S.MODEL, 1) = 'I' THEN 'ITG'
                      WHEN LEFT(S.MODEL, 1) = 'H' THEN 'HTG'
                      WHEN LEFT(S.MODEL, 1) = 'C' THEN 'Coated'
                      ELSE 'UTG'
                  END AS 제품구조
            FROM DOI_STCO S WITH(NOLOCK)
            LEFT JOIN dw_모델기본정보 B
                   ON B.model = S.MODEL
                  AND B.구분 = S.구분
                  AND ACCT_NAME != N'기타출고'
            WHERE SUBSTRING(S.YYYYMM, 1, 4) = @YYYY
              AND S.SITE 	 = @SITE
              AND S.SEL_CODE = @SEL_CODE
           GROUP BY S.SITE, S.구분, S.MODEL
        )
        SELECT *
        INTO #MODEL_BASE
        FROM MODEL_BASE;


        ----------------------------------------------------------------------
        -- 3. STCO 집계
        ----------------------------------------------------------------------
        ;WITH STCO_AGG AS (
            SELECT
                  YYYYMM, SITE, 구분, MODEL
                , AVG(BOH)     AS BOH_QTY
                , SUM(BOH_AMT) AS BOH_AMT
                , AVG(INPUT)   AS IN_QTY
                , SUM(IN_AMT)  AS IN_AMT
/*                , SUM(CASE WHEN EXPEN_SEL IN ('MDAX','MIAX') THEN IN_AMT ELSE 0 END) AS IN_MAT_AMT*/
                , AVG([OUT])   AS OUT_QTY
                , SUM(OUT_AMT/*+OUTETC_AMT*/) AS OUT_AMT
                , AVG(EOH)     AS EOH_QTY
                , SUM(EOH_AMT) AS EOH_AMT
                , AVG (INETC) AS IN_ETC_QTY
                , SUM (INETC_AMT) AS IN_ETC_AMT
                , AVG (OUTETC) AS OUTETC_QTY
                , SUM (OUTETC_AMT) AS OUTETC_AMT
                , AVG(RMAOUT_QTY) AS RMAOUT_QTY
                , SUM(RMAOUT_AMT) AS RMAOUT_AMT
            FROM DOI_STCO WITH(NOLOCK)
            WHERE SUBSTRING(YYYYMM,1,4)=@YYYY
              AND SITE=@SITE
              AND SEL_CODE = @SEL_CODE
              AND ACCT_NAME != N'기타출고'              
            GROUP BY YYYYMM, SITE, 구분, MODEL
        )
        SELECT *
        INTO #STCO_AGG
        FROM STCO_AGG;


        ----------------------------------------------------------------------
        -- 4. MAT COST
        ----------------------------------------------------------------------
        /*;WITH MAT_IN_AGG AS (
            SELECT
                  YYYYMM, SITE, 도우모델 AS MODEL
                , SUM(배부금액) AS IN_MAT_AMT
            FROM DOI_MAT_COST WITH(NOLOCK)
            WHERE SUBSTRING(YYYYMM,1,4)=@YYYY
              AND SITE=@SITE
              AND SEL_CODE = @SEL_CODE
   GROUP BY YYYYMM, SITE, 도우모델
        )
        SELECT * INTO #MAT_IN_AGG FROM MAT_IN_AGG;*/


        ----------------------------------------------------------------------
        -- 5. RMA COST
        ----------------------------------------------------------------------
        ;WITH RMA_IN_AGG AS (
            SELECT
                  YYYYMM, SITE, 구분, MODEL
                , AVG(RMAIN_QTY) AS RMA_IN_QTY
                , SUM(RMAIN_AMT) AS RMA_IN_AMT
            FROM DOI_COST WITH(NOLOCK)
            WHERE SUBSTRING(YYYYMM,1,4)=@YYYY
              AND SITE=@SITE
              AND SEL_CODE = @SEL_CODE
            GROUP BY YYYYMM, SITE, 구분, MODEL
        )
        SELECT * INTO #RMA_IN_AGG FROM RMA_IN_AGG;


        ----------------------------------------------------------------------
        -- 6. 최종 결과
        ----------------------------------------------------------------------
        SELECT
              M.구분
            , M.모델
            , M.두께
            , M.Inch
            , M.제품구조
            , M.고객사 AS 판매처
            , CAST(G.월번호 AS VARCHAR(2)) + '월' AS 월

            , SA.BOH_QTY, SA.BOH_AMT
            , SA.IN_QTY,  SA.IN_AMT
            , SA.OUT_QTY, SA.OUT_AMT
            , SA.EOH_QTY, SA.EOH_AMT

            , SA.IN_QTY AS IN_MAT_QTY
            , SA.IN_AMT AS IN_MAT_AMT
            --, MA.IN_MAT_AMT AS IN_MAT_AMT
            --, SA.IN_MAT_AMT

            , SA.IN_ETC_QTY
            , SA.IN_ETC_AMT

            , RI.RMA_IN_QTY
            , RI.RMA_IN_AMT

            , NULL AS OUT_GOOD_QTY
            , NULL AS OUT_GOOD_AMT

            , (SA.OUTETC_QTY + ISNULL(SA.RMAOUT_QTY,0)) AS OUT_ETC_QTY
            , (SA.OUTETC_AMT + ISNULL(SA.RMAOUT_AMT,0)) AS OUT_ETC_AMT

        FROM #MODEL_BASE M
        CROSS JOIN #GEN_YYYYMM G
        INNER JOIN #STCO_AGG SA
               ON SA.YYYYMM = G.YYYYMM
              AND SA.SITE   = M.SITE
              AND SA.구분    = M.구분
              AND SA.MODEL  = M.모델
        /*LEFT JOIN #MAT_IN_AGG MA
               ON MA.YYYYMM = G.YYYYMM
              AND MA.SITE   = M.SITE
              AND MA.MODEL  = M.모델*/
        LEFT JOIN #RMA_IN_AGG RI
               ON RI.YYYYMM = G.YYYYMM
              AND RI.SITE   = M.SITE
              AND RI.구분    = M.구분
              AND RI.MODEL  = M.모델

        ORDER BY M.구분, M.모델, G.월번호;


        ----------------------------------------------------------------------
        -- 7. 임시테이블 삭제
        ----------------------------------------------------------------------
        DROP TABLE #GEN_YYYYMM;
        DROP TABLE #MODEL_BASE;
        DROP TABLE #STCO_AGG;
--        DROP TABLE #MAT_IN_AGG;
        DROP TABLE #RMA_IN_AGG;

    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

