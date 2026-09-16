
-- [2026-09-15k] 출고(OUT) = 양품(출고) + 양품(반품입고) + 타계정. 양품과 타계정은 겹치지 않음(사용자 확정).
--   8월 저장 출고에는 타계정이 빠져 있어 기초+입고-출고≠기말이던 것 해소. 1~7월은 기존 출고와 같은 값.
-- [2026-09-15i] 양품(출고) 저장값 없는 행: 후처리월(현 STOCK_COST 결산, 출고에 타계정 제외)=출고 그대로,
--   그외 월(1~7월, 출고에 타계정 포함)=출고-타계정 유지. 8월 개발 모델·RMA 7073 양품 음수(-타계정) 해소.
-- [2026-09-15h] 입고상세 RMA(품번변경)=DOI_STCO.RMA_IN_QTY/AMT(구 RMAIN_* 는 전 기간 0), 기타=타계정-RMA(품번변경),
--   출고상세 양산 RMA(품번변경)/타계정 금액=같은 모델 RMA 행의 품번변경 입고금액(저장 OUT_RMA_AMT=0 일 때만). 표시 전용.
-- [2026-09-15g] DOI_ProductCOGS OUT_GOOD 하이브리드: 후처리월(저장 OUT_GOOD 존재)=저장값,
-- 그외 월(1~7월 등 미후처리)=기존 파생(OUT-OUTETC)로 폴백. fix260915d 저장값전용의 1~7월=0 회귀 수정.
-- 리포트 전용(SELECT). ALTER만으로 즉시 반영, 재결산 불필요.
-- [2026-09-15] 양품(출고) 저장값(매출문서 기반 OUT_GOOD_QTY/AMT) 사용. 파생(OUT-OUTETC) 폐기.
-- [2026-09-15] 양품(반품입고) 노출: DOI_STCO.OUT_GOOD_RTN_QTY/AMT -> 결과셋. 라이브 기반.

CREATE PROCEDURE DOI_ProductCOGS
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
        -- 3-0. [2026-09-15i] 후처리월 판정 (월 단위)
        --   현 UP_DOI_STOCK_COST 로 결산한 달은 양품 저장값(OUT_GOOD_*/OUT_GOOD_RTN_*)이 있고 출고(OUT/OUT_AMT)에 타계정이 빠져 있음.
        --   1~7월처럼 예전 로직으로 결산한 달은 저장값이 없고 출고에 타계정이 포함됨.
        ----------------------------------------------------------------------
        SELECT YYYYMM AS PP_YYYYMM, SITE AS PP_SITE, 1 AS POSTPROC
        INTO #POSTPROC_MONTH
        FROM DOI_STCO WITH(NOLOCK)
        WHERE SUBSTRING(YYYYMM,1,4)=@YYYY
          AND SITE=@SITE
          AND SEL_CODE = @SEL_CODE
          AND (ISNULL(OUT_GOOD_AMT,0) <> 0 OR ISNULL(OUT_GOOD_QTY,0) <> 0 OR ISNULL(OUT_GOOD_RTN_AMT,0) <> 0 OR ISNULL(OUT_GOOD_RTN_QTY,0) <> 0)
        GROUP BY YYYYMM, SITE;


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
                /* [변경 전] 2026-09-15i 저장값 없는 행은 후처리월에도 출고-타계정 → 8월(출고에 타계정 제외) 양품이 -타계정으로 음수
                , CASE WHEN (SUM(ISNULL(OUT_GOOD_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_QTY,0)) <> 0 OR SUM(ISNULL(OUT_GOOD_RTN_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_RTN_QTY,0)) <> 0) THEN MAX(ISNULL(OUT_GOOD_QTY,0)) ELSE MAX([OUT]) - MAX(ISNULL(OUTETC,0)) END AS OUT_GOOD_QTY  -- [2026-09-15g] 후처리월(저장값 존재)=저장값, 그외=파생(OUT-OUTETC) 폴백
                , CASE WHEN (SUM(ISNULL(OUT_GOOD_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_QTY,0)) <> 0 OR SUM(ISNULL(OUT_GOOD_RTN_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_RTN_QTY,0)) <> 0) THEN SUM(ISNULL(OUT_GOOD_AMT,0)) ELSE SUM(OUT_AMT) - SUM(ISNULL(OUTETC_AMT,0)) END AS OUT_GOOD_AMT  -- [2026-09-15g] 후처리월=저장값, 그외=파생 폴백
                [변경 전 끝] */
                -- [변경] 2026-09-15i 저장값 있는 행=저장값 / 저장값 없는 행: 후처리월=출고 그대로(타계정 빼지 않음), 그외 월(1~7월)=출고-타계정
                , CASE WHEN (SUM(ISNULL(OUT_GOOD_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_QTY,0)) <> 0 OR SUM(ISNULL(OUT_GOOD_RTN_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_RTN_QTY,0)) <> 0) THEN MAX(ISNULL(OUT_GOOD_QTY,0))
                       WHEN MAX(ISNULL(PM.POSTPROC,0)) = 1 THEN MAX([OUT])
                       ELSE MAX([OUT]) - MAX(ISNULL(OUTETC,0)) END AS OUT_GOOD_QTY
                , CASE WHEN (SUM(ISNULL(OUT_GOOD_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_QTY,0)) <> 0 OR SUM(ISNULL(OUT_GOOD_RTN_AMT,0)) <> 0 OR MAX(ISNULL(OUT_GOOD_RTN_QTY,0)) <> 0) THEN SUM(ISNULL(OUT_GOOD_AMT,0))
                       WHEN MAX(ISNULL(PM.POSTPROC,0)) = 1 THEN SUM(OUT_AMT)
                       ELSE SUM(OUT_AMT) - SUM(ISNULL(OUTETC_AMT,0)) END AS OUT_GOOD_AMT
                , MAX(OUTETC) AS OUTETC_QTY
                , SUM(OUTETC_AMT) AS OUTETC_AMT
                , MAX(ISNULL(RMA_IN_QTY,0)) AS RMA_IN_QTY   -- [2026-09-15h] RMA(품번변경) 입고: UP_DOI_STOCK_COST 저장 컬럼
                , SUM(ISNULL(RMA_IN_AMT,0)) AS RMA_IN_AMT
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
            LEFT JOIN #POSTPROC_MONTH PM                    -- [2026-09-15i]
                   ON PM.PP_YYYYMM = DOI_STCO.YYYYMM
                  AND PM.PP_SITE   = DOI_STCO.SITE
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

        -- [2026-09-15h] 양산 RMA(품번변경) 출고금액(표시용)
        --   UP_DOI_STOCK_COST 가 양산 반품크레딧을 OUT_AMT 에 접으면서 OUTETC_AMT=0, OUT_RMA_AMT=0(매출원가식 OUT-OUTETC+OUT_RMA 보호)으로
        --   저장해 출고상세 타계정/RMA(품번변경) 금액이 비어 보임. 같은 모델 RMA 행의 품번변경 입고금액을 출고수량 비율로 표시.
        --   저장 OUT_RMA_AMT 가 있는 월(예: 202601)은 대상 아님.
        SELECT P.YYYYMM, P.SITE, P.MODEL
             , CASE WHEN P.OUT_RMA_QTY = R.RMA_IN_QTY THEN R.RMA_IN_AMT
                    ELSE ROUND(R.RMA_IN_AMT * 1.0 * P.OUT_RMA_QTY / R.RMA_IN_QTY, 0) END AS XFER_AMT
        INTO #RMA_XFER
        FROM #STCO_AGG P
        INNER JOIN #STCO_AGG R
                ON R.YYYYMM = P.YYYYMM
               AND R.SITE   = P.SITE
               AND R.MODEL  = P.MODEL
               AND R.구분    = N'RMA'
        WHERE P.구분 = N'양산'
          AND ISNULL(P.OUT_RMA_AMT,0) = 0
          AND ISNULL(P.OUT_RMA_QTY,0) <> 0
          AND ISNULL(R.RMA_IN_QTY,0) <> 0;


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
            /* [변경 전] 2026-09-15k 저장 출고 그대로(8월 등 후처리월은 타계정이 빠져 있음)
            , SA.OUT_QTY, SA.OUT_AMT
            [변경 전 끝] */
            -- [변경] 2026-09-15k 출고 = 양품(출고) + 양품(반품입고) + 타계정
            , ISNULL(SA.OUT_GOOD_QTY,0) + ISNULL(SA.OUT_GOOD_RTN_QTY,0) + ISNULL(D.OUT_ETC_QTY,0) AS OUT_QTY
            , ISNULL(SA.OUT_GOOD_AMT,0) + ISNULL(SA.OUT_GOOD_RTN_AMT,0) + ISNULL(D.OUT_ETC_AMT,0) AS OUT_AMT
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
            
            /* [변경 전] 2026-09-15h 구 컬럼(RMAIN_*)은 전 기간 0 — 현 결산은 RMA_IN_* 에 저장되어 화면이 비어 보임
            , COALESCE(SA.RMAIN_QTY,0) AS RMA_IN_QTY
            , COALESCE(SA.RMAIN_AMT,0) AS RMA_IN_AMT
            [변경 전 끝] */
            -- [변경] 2026-09-15h RMA(품번변경) 입고 = DOI_STCO.RMA_IN_QTY/AMT
            , COALESCE(SA.RMA_IN_QTY,0) AS RMA_IN_QTY
            , COALESCE(SA.RMA_IN_AMT,0) AS RMA_IN_AMT

            , COALESCE(SA.OUT_GOOD_QTY,0) AS OUT_GOOD_QTY
            , COALESCE(SA.OUT_GOOD_AMT,0) AS OUT_GOOD_AMT
            , COALESCE(SA.OUT_GOOD_RTN_QTY,0) AS OUT_GOOD_RTN_QTY   -- [2026-09-15] 양품(반품입고)
            , COALESCE(SA.OUT_GOOD_RTN_AMT,0) AS OUT_GOOD_RTN_AMT

            -- [변경] 2026-09-15k 타계정 표시값은 아래 CROSS APPLY D 로 이동(출고 합계와 공용). 계산식은 fix260915h 와 같음
            , D.OUT_ETC_QTY
            , D.OUT_ETC_AMT

            /* [변경 전] 2026-09-15h DOI_STCO.IN_OTHER_QTY = ERP 기타입고 전체(RMA 품번변경 포함)라 RMA 수량이 기타에 중복 표시
            , COALESCE(SA.IN_OTHER_QTY,0)      AS IN_OTHER_QTY
            , COALESCE(SA.IN_OTHER_AMT,0)      AS IN_OTHER_AMT
            [변경 전 끝] */
            -- [변경] 2026-09-15h 기타 입고 = 타계정 입고 - RMA(품번변경). 상세(IN_OTHER/RMA_IN)가 저장된 행만, 상세 미저장 행(2025년 등)은 기존값
            , CASE WHEN ISNULL(SA.IN_OTHER_QTY,0) <> 0 OR ISNULL(SA.IN_OTHER_AMT,0) <> 0 OR ISNULL(SA.RMA_IN_QTY,0) <> 0 OR ISNULL(SA.RMA_IN_AMT,0) <> 0
                   THEN ISNULL(SA.IN_ETC_QTY,0) - ISNULL(SA.RMA_IN_QTY,0) ELSE COALESCE(SA.IN_OTHER_QTY,0) END AS IN_OTHER_QTY
            , CASE WHEN ISNULL(SA.IN_OTHER_QTY,0) <> 0 OR ISNULL(SA.IN_OTHER_AMT,0) <> 0 OR ISNULL(SA.RMA_IN_QTY,0) <> 0 OR ISNULL(SA.RMA_IN_AMT,0) <> 0
                   THEN ISNULL(SA.IN_ETC_AMT,0) - ISNULL(SA.RMA_IN_AMT,0) ELSE COALESCE(SA.IN_OTHER_AMT,0) END AS IN_OTHER_AMT

            , COALESCE(SA.OUT_RMA_QTY,0)       AS OUT_RMA_QTY
            -- [변경] 2026-09-15h 양산 반품(품번변경) 행은 #RMA_XFER 표시금액 (전: COALESCE(SA.OUT_RMA_AMT,0))
            , COALESCE(RX.XFER_AMT, SA.OUT_RMA_AMT, 0) AS OUT_RMA_AMT

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
        LEFT JOIN #RMA_XFER RX                          -- [2026-09-15h]
               ON RX.YYYYMM = SA.YYYYMM
              AND RX.SITE   = SA.SITE
              AND RX.MODEL  = SA.MODEL
              AND SA.구분    = N'양산'
        CROSS APPLY (                                   -- [2026-09-15k] 타계정 표시값 (출고상세 타계정·출고 합계 공용)
            SELECT (SA.OUTETC_QTY + ISNULL(SA.AREAOUT_QTY,0)) AS OUT_ETC_QTY
                 -- [2026-09-15h] 양산 반품(품번변경) 행은 출고상세 합(RMA(품번변경) 표시금액 포함). 그 외 행은 저장값
                 , CASE WHEN RX.XFER_AMT IS NOT NULL
                        THEN RX.XFER_AMT + ISNULL(SA.OUT_REWORK_AMT,0) + ISNULL(SA.OUT_RND_AMT,0) + ISNULL(SA.OUT_TECH_EVAL_AMT,0) + ISNULL(SA.OUT_SHIP_INSP_AMT,0)
                           + ISNULL(SA.OUT_DISPOSE_AMT,0) + ISNULL(SA.OUT_INV_ADJ_AMT,0) + ISNULL(SA.OUT_OTHER_AMT,0) + ISNULL(SA.AREAOUT_AMT,0)
                        ELSE (SA.OUTETC_AMT + ISNULL(SA.AREAOUT_AMT,0)) END AS OUT_ETC_AMT
        ) D

        ORDER BY M.구분, M.모델, G.월번호;


        ----------------------------------------------------------------------
        -- 7. 임시테이블 삭제
        ----------------------------------------------------------------------
        DROP TABLE #GEN_YYYYMM;
        DROP TABLE #MODEL_BASE;
        DROP TABLE #STCO_AGG;
--        DROP TABLE #MAT_IN_AGG;
        DROP TABLE #RMA_IN_AGG;
        DROP TABLE #RMA_XFER;
        DROP TABLE #POSTPROC_MONTH;

    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
