-- [2026-09-15] 양품(반품입고) 노출: DOI_STCO.OUT_GOOD_RTN_QTY/AMT -> 결과셋. 라이브 기반.

ALTER PROCEDURE DOI_ProductCOGS
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
                , MAX(BOH)     AS BOH_QTY
                , SUM(BOH_AMT) AS BOH_AMT
                /* [변경 전] 2026-07-15 입고수량에 타계정 미포함
                , MAX(INPUT)   AS IN_QTY
                [변경 전 끝] */
                -- [변경] 2026-07-15 입고수량에 타계정(INETC) 포함
                , MAX(INPUT) + MAX(ISNULL(INETC,0))   AS IN_QTY
                /* [변경 전] 2026-07-15 입고금액에 타계정 미포함
                , SUM(IN_AMT)  AS IN_AMT
                [변경 전 끝] */
                -- [변경] 2026-07-15 입고금액에 타계정(INETC_AMT) 포함
                , SUM(IN_AMT+ISNULL(INETC_AMT,0))  AS IN_AMT
/*                , SUM(CASE WHEN EXPEN_SEL IN ('MDAX','MIAX') THEN IN_AMT ELSE 0 END) AS IN_MAT_AMT*/
                /* [변경 전] 2026-07-15 출고수량에 타계정 미포함
                , MAX([OUT])   AS OUT_QTY
                [변경 전 끝] */
                -- [변경] 2026-07-15 출고수량에 타계정(OUTETC) 포함
                -- [변경] 2026-08-18 OUT=전체출고(기타출고 포함). 중복합산(OUT+OUTETC) 제거
                , MAX([OUT])   AS OUT_QTY
                , /* [변경 전] 2026-07-15 출고(OUT)에 타계정 미포함
                SUM(OUT_AMT) AS OUT_AMT
                [변경 전 끝] */
                -- [변경] 2026-07-15 출고(OUT)에 타계정(OUTETC_AMT) 포함
                -- [변경] 2026-08-18 OUT_AMT=전체출고금액(기타출고 포함). 중복합산 제거
                SUM(OUT_AMT) AS OUT_AMT
                , MAX(EOH)     AS EOH_QTY
                , SUM(EOH_AMT) AS EOH_AMT
                , MAX (INETC) AS IN_ETC_QTY
                , SUM (INETC_AMT) AS IN_ETC_AMT
                /* [변경 전] 2026-07-13 MAX-AVG 혼용 및 OUT-OUTETC 잘못된 계산으로 마이너스 양품 발생
                , MAX([OUT]) - AVG(OUTETC) AS OUT_GOOD_QTY
                , SUM(OUT_AMT) -SUM(OUTETC_AMT) AS OUT_GOOD_AMT
                [변경 전 끝] */
                -- [변경] 2026-07-13 [OUT]이 양품수량, OUT_AMT가 양품금액임 (OUTETC와 별도)
                -- [사유] [OUT]=양품, OUTETC=기타출고로 별도 컬럼. 뺄셈 불필요
                -- [변경] 2026-08-18 source 재정의: OUT=전체출고. 양품 = 전체출고 - 기타출고(OUTETC)
                , MAX([OUT]) - MAX(ISNULL(OUTETC,0)) AS OUT_GOOD_QTY
                , SUM(OUT_AMT) - SUM(ISNULL(OUTETC_AMT,0)) AS OUT_GOOD_AMT
                , MAX(OUTETC) AS OUTETC_QTY
                , SUM(OUTETC_AMT) AS OUTETC_AMT
                , MAX(RMAIN_QTY) AS RMAIN_QTY
                , SUM(RMAIN_AMT) AS RMAIN_AMT                
                , MAX(AREAOUT_QTY) AS AREAOUT_QTY
                , SUM(AREAOUT_AMT) AS AREAOUT_AMT
                , MAX(IN_MAT_QTY)         AS IN_MAT_QTY
                , SUM(IN_MAT_AMT)         AS IN_MAT_AMT
                , MAX(IN_OTHER_QTY)       AS IN_OTHER_QTY
                , SUM(IN_OTHER_AMT)       AS IN_OTHER_AMT
            , MAX(OUT_ETC_QTY)        AS OUT_ETC_QTY
                , SUM(OUT_ETC_AMT)        AS OUT_ETC_AMT
                , MAX(OUT_RMA_QTY)        AS OUT_RMA_QTY
                , SUM(OUT_RMA_AMT)        AS OUT_RMA_AMT
                , MAX(OUT_REWORK_QTY)     AS OUT_REWORK_QTY
                , SUM(OUT_REWORK_AMT)     AS OUT_REWORK_AMT
                , MAX(OUT_RND_QTY)        AS OUT_RND_QTY
                , SUM(OUT_RND_AMT)        AS OUT_RND_AMT
                , MAX(OUT_TECH_EVAL_QTY)  AS OUT_TECH_EVAL_QTY
                , SUM(OUT_TECH_EVAL_AMT)  AS OUT_TECH_EVAL_AMT
                , MAX(OUT_SHIP_INSP_QTY)  AS OUT_SHIP_INSP_QTY
                , SUM(OUT_SHIP_INSP_AMT)  AS OUT_SHIP_INSP_AMT
                , MAX(OUT_DISPOSE_QTY)    AS OUT_DISPOSE_QTY
                , SUM(OUT_DISPOSE_AMT)    AS OUT_DISPOSE_AMT
                , MAX(OUT_INV_ADJ_QTY)    AS OUT_INV_ADJ_QTY
                , SUM(OUT_INV_ADJ_AMT)    AS OUT_INV_ADJ_AMT
                , MAX(OUT_OTHER_QTY)      AS OUT_OTHER_QTY
                , SUM(OUT_OTHER_AMT)      AS OUT_OTHER_AMT
                , MAX(OUT_GOOD_RTN_QTY) AS OUT_GOOD_RTN_QTY   -- [2026-09-15] 양품 반품입고(표시전용)
                , SUM(OUT_GOOD_RTN_AMT) AS OUT_GOOD_RTN_AMT
            FROM DOI_STCO WITH(NOLOCK)
            WHERE SUBSTRING(YYYYMM,1,4)=@YYYY
              AND SITE=@SITE
              AND SEL_CODE = @SEL_CODE
              AND ACCT_NAME != N'기타출고'
      		  AND COST_TYPE != 'LOSS'              
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
                , MAX(RMAIN_QTY) AS RMA_IN_QTY
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

            , /* [변경 전] 2026-07-15 IN_QTY에 타계정이 포함되어 양품에서 분리 필요
            CASE WHEN SA.구분 != 'RMA' THEN SA.IN_QTY ELSE 0 END AS IN_MAT_QTY
            [변경 전 끝] */
            -- [변경] 2026-07-15 양품입고 = IN(전체) - 타계정(INETC)
            CASE WHEN SA.구분 != 'RMA' THEN SA.IN_QTY - ISNULL(SA.IN_ETC_QTY,0) ELSE 0 END AS IN_MAT_QTY
            , /* [변경 전] 2026-07-15
            CASE WHEN SA.구분 != 'RMA' THEN SA.IN_AMT ELSE 0 END AS IN_MAT_AMT
            [변경 전 끝] */
            -- [변경] 2026-07-15 양품입고금액 = IN(전체) - 타계정(INETC)
            CASE WHEN SA.구분 != 'RMA' THEN SA.IN_AMT - ISNULL(SA.IN_ETC_AMT,0) ELSE 0 END AS IN_MAT_AMT
            --, MA.IN_MAT_AMT AS IN_MAT_AMT
/*            , SA.IN_MAT_AMT*/

            , SA.IN_ETC_QTY
            , SA.IN_ETC_AMT

--            , RI.RMA_IN_QTY
--            , RI.RMA_IN_AMT
            
            , COALESCE(SA.RMAIN_QTY,0) AS RMA_IN_QTY
            , COALESCE(SA.RMAIN_AMT,0) AS RMA_IN_AMT

            , COALESCE(SA.OUT_GOOD_QTY,0) AS OUT_GOOD_QTY
            , COALESCE(SA.OUT_GOOD_AMT,0) AS OUT_GOOD_AMT
            , COALESCE(SA.OUT_GOOD_RTN_QTY,0) AS OUT_GOOD_RTN_QTY   -- [2026-09-15] 양품(반품입고)
            , COALESCE(SA.OUT_GOOD_RTN_AMT,0) AS OUT_GOOD_RTN_AMT

            , (SA.OUTETC_QTY + ISNULL(SA.AREAOUT_QTY,0)) AS OUT_ETC_QTY
            , (SA.OUTETC_AMT + ISNULL(SA.AREAOUT_AMT,0)) AS OUT_ETC_AMT

            , COALESCE(SA.IN_OTHER_QTY,0)      AS IN_OTHER_QTY
            , COALESCE(SA.IN_OTHER_AMT,0)      AS IN_OTHER_AMT

            , COALESCE(SA.OUT_RMA_QTY,0)       AS OUT_RMA_QTY
            , COALESCE(SA.OUT_RMA_AMT,0)       AS OUT_RMA_AMT

            , COALESCE(SA.OUT_REWORK_QTY,0)    AS OUT_REWORK_QTY
            , COALESCE(SA.OUT_REWORK_AMT,0)    AS OUT_REWORK_AMT

            , COALESCE(SA.OUT_RND_QTY,0)       AS OUT_RND_QTY
            , COALESCE(SA.OUT_RND_AMT,0)       AS OUT_RND_AMT

            , COALESCE(SA.OUT_TECH_EVAL_QTY,0) AS OUT_TECH_EVAL_QTY
            , COALESCE(SA.OUT_TECH_EVAL_AMT,0) AS OUT_TECH_EVAL_AMT

            , COALESCE(SA.OUT_SHIP_INSP_QTY,0) AS OUT_SHIP_INSP_QTY
            , COALESCE(SA.OUT_SHIP_INSP_AMT,0) AS OUT_SHIP_INSP_AMT

            , COALESCE(SA.OUT_DISPOSE_QTY,0)   AS OUT_DISPOSE_QTY
            , COALESCE(SA.OUT_DISPOSE_AMT,0)   AS OUT_DISPOSE_AMT

            , COALESCE(SA.OUT_INV_ADJ_QTY,0)   AS OUT_INV_ADJ_QTY
            , COALESCE(SA.OUT_INV_ADJ_AMT,0)   AS OUT_INV_ADJ_AMT

            , COALESCE(SA.OUT_OTHER_QTY,0)     AS OUT_OTHER_QTY
            , COALESCE(SA.OUT_OTHER_AMT,0)     AS OUT_OTHER_AMT            
            
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