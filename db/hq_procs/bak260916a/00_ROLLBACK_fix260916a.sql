/* ============================================================
   fix260916a(카세트 대분류 신설) 원복 — 2026-09-16 배포 직전 운영 정의로 되돌린다.
   같은 폴더의 각 .sql 이 원본이며, 이 파일은 그것을 ALTER 로 바꿔 한 번에 실행하는 용도다.
   SSMS 에서 통째로 실행(GO 구분).
   ============================================================ */

-- [2026-09-15] 제조원가(재공) 타계정입고 반영: RMA_IN=기타입고(LOT/불량RW/RMA RW/전월/당월) 상세합.
-- + IN_AMT에서 RMA1 재투입 제외(수기=당기총제조원가 일치, 재투입은 타계정입고로 표시, EOH 불변).
-- 리포트 프로시저 단독 ALTER: 재결산/jar 재빌드 불필요. 라이브 기반.
ALTER PROCEDURE DOI_ManufacturingCostOfWIP
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
                , SUM(CASE WHEN EXPEN_SEL = 'RMA1' THEN 0 ELSE [IN] END)    AS IN_AMT  -- [2026-09-15] 재투입(RMA1)은 IN 제외→타계정입고로 이동(수기 일치)

                , MAX(OUT_QTY)    AS OUT_QTY
                , SUM([OUT]+ADJ_BOH)      AS OUT_AMT

                , CASE WHEN ABS(MIN(ISNULL(LOSS_QTY,0))) > ABS(MAX(ISNULL(LOSS_QTY,0))) THEN MIN(ISNULL(LOSS_QTY,0)) ELSE MAX(ISNULL(LOSS_QTY,0)) END   AS LOSS_QTY
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
            -- 타계정입고(RMA_IN)
        	, (ISNULL(SA.ETC_IN_LOT_QTY,0)+ISNULL(SA.ETC_IN_DEF_RW_QTY,0)+ISNULL(SA.ETC_IN_RMA_QTY,0)+ISNULL(SA.ETC_IN_PREV_DEF_QTY,0)+ISNULL(SA.ETC_IN_CUR_DEF_QTY,0)) AS RMA_IN_QTY  -- [2026-09-15] 타계정입고=기타입고 상세합
            , (ISNULL(SA.ETC_IN_LOT_AMT,0)+ISNULL(SA.ETC_IN_DEF_RW_AMT,0)+ISNULL(SA.ETC_IN_RMA_AMT,0)+ISNULL(SA.ETC_IN_PREV_DEF_AMT,0)+ISNULL(SA.ETC_IN_CUR_DEF_AMT,0)) AS RMA_IN_AMT  -- [2026-09-15] 타계정입고=기타입고 상세합
            
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
GO


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
GO

ALTER PROCEDURE DOI_ManufacturingExpenseByModel(
	@YYYYMM varchar(10),
 	@SITE varchar(4),
 	@SEL_CODE varchar(10)
 )
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		--declare @YYYYMM varchar(10)=@YYYYMM, @SITE varchar(4)=@SITE;
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + model
		FROM (SELECT TOP 500 CONCAT(구분, model) model 
				FROM (
					SELECT DISTINCT 구분, model 
					FROM (
						SELECT DISTINCT 구분, replace(도우모델,' ','') as model 
						FROM doi_mat_cost 
						where yyyymm=@YYYYMM 
						  and site=@SITE 
						  and sel_code=@SEL_CODE
						  --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
						and not (구분 = N'개발' and 도우모델 like N'VN%') and 도우모델 <> N'VN034P'  /* [2026-09-14] 팬텀 카세트(수량有 금액0) 배제 */
						group by 구분, 도우모델
						UNION 
						SELECT 구분, replace(model,' ','') as model 
						  from doi_expen_matl 
						 where yyyymm=@YYYYMM 
						   and site=@SITE 
						   and sel_code=@SEL_CODE 
						   and not (ISNULL(in_qty,0) = 0 and ISNULL(out_qty,0) = 0 and ISNULL(loss_qty,0) = 0 and ISNULL([in],0) = 0)
							   and not (구분 = N'개발' and model like N'VN%') and model <> N'VN034P'  /* [2026-09-14] 팬텀 카세트(수량有 금액0) 배제 */
						group by 구분, model 
						UNION
						SELECT 'Z' 구분, CONCAT(구분, '합계') model 
						  FROM (
								SELECT DISTINCT 구분 
								  from doi_mat_cost 
								 where yyyymm=@YYYYMM 
								   and site=@SITE 
								   and sel_code=@SEL_CODE
						  		  -- and not (in_qty = 0 and out_qty = 0 and loss_qty = 0) 
								 group by 구분 
								 UNION 
								 SELECT 구분 
								   FROM doi_expen_matl 
								  where yyyymm=@YYYYMM 
								    and site=@SITE 
								    and sel_code=@SEL_CODE 								    
						   			and not (ISNULL(in_qty,0) = 0 and ISNULL(out_qty,0) = 0 and ISNULL(loss_qty,0) = 0 and ISNULL([in],0) = 0)
								  group by 구분
								)a
						UNION
						SELECT 'Z' 구분, '합계' model
					) A 
				) A 
				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			
						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;
		select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
		FROM (SELECT TOP 500 CONCAT(구분, model) model 
				FROM (
					SELECT DISTINCT 구분, model 
					FROM (
						SELECT DISTINCT 구분, replace(도우모델,' ','') as model 
						  FROM doi_mat_cost 
						 where yyyymm=@YYYYMM 
						   and site=@SITE 
						   and sel_code=@SEL_CODE 
						   --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
						and not (구분 = N'개발' and 도우모델 like N'VN%') and 도우모델 <> N'VN034P'  /* [2026-09-14] 팬텀 카세트(수량有 금액0) 배제 */
						group by 구분, 도우모델 
						UNION 
						SELECT 구분, replace(model,' ','') as model 
						  from doi_expen_matl 
						 where yyyymm=@YYYYMM 
						   and site=@SITE 
						   and sel_code=@SEL_CODE 
						   and not (ISNULL(in_qty,0) = 0 and ISNULL(out_qty,0) = 0 and ISNULL(loss_qty,0) = 0 and ISNULL([in],0) = 0)
							   and not (구분 = N'개발' and model like N'VN%') and model <> N'VN034P'  /* [2026-09-14] 팬텀 카세트(수량有 금액0) 배제 */
						group by 구분, model 
						UNION
						SELECT 'Z' 구분, CONCAT(구분, '합계') model 
						  FROM (
							SELECT DISTINCT 구분 
							  from doi_mat_cost 
							 where yyyymm=@YYYYMM 
							   and site=@SITE 
							   and sel_code=@SEL_CODE
							   --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
							group by 구분 
							UNION 
							SELECT 구분 
							  FROM doi_expen_matl 
							 where yyyymm=@YYYYMM 
							   and site=@SITE 
							   and sel_code=@SEL_CODE
							   and not (ISNULL(in_qty,0) = 0 and ISNULL(out_qty,0) = 0 and ISNULL(loss_qty,0) = 0 and ISNULL([in],0) = 0)
							group by 구분
						)a
						UNION
						SELECT 'Z' 구분, '합계' model
					) A 
				) A 
				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			
						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;
			select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns


with sourceTable as (
	select X.*, COALESCE(Y.amt,0) amt from (
		select * from (
			SELECT DISTINCT TOP 500 구분, model 
			FROM (
				SELECT DISTINCT 구분, replace(도우모델,' ','') as model 
				  FROM doi_mat_cost 
				 where yyyymm=@YYYYMM 
				   and site=@SITE 
				   and sel_code=@SEL_CODE
				   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
				 and not (구분 = N'개발' and 도우모델 like N'VN%') and 도우모델 <> N'VN034P'  /* [2026-09-14] 팬텀 카세트(수량有 금액0) 배제 */
				 group by 구분, 도우모델 
				UNION 
				SELECT 구분, replace(model,' ','') as model 
				  from doi_expen_matl 
				 where yyyymm=@YYYYMM 
				   and site=@SITE 
				   and sel_code=@SEL_CODE
				   and not (ISNULL(in_qty,0) = 0 and ISNULL(out_qty,0) = 0 and ISNULL(loss_qty,0) = 0 and ISNULL([in],0) = 0)
							   and not (구분 = N'개발' and model like N'VN%') and model <> N'VN034P'  /* [2026-09-14] 팬텀 카세트(수량有 금액0) 배제 */	
				 group by 구분, model
			) A 
		) A 
		cross join 
		(
		select 1 rn, '  I. 재료비' gubun
		union all select 2 rn, '    (1) 원재료_원장' gubun
		union all select 3 rn, '    (2) 원재료_카세트 부품' gubun
		union all select 4 rn, '    (3) 원재료_필름' gubun
		union all select 5 rn, '    (4) 원재료_약액' gubun		
		union all select 6 rn, '    (5) 부재료_트레이' gubun
		union all select 7 rn, '    (6) 부재료_기타' gubun
		union all select 8 rn, '  II. 노무비' gubun
		union all select 9 rn, '    (1) 제)임원급여' gubun
/*		union all select 10 rn, '      1. 제)급여-임원' gubun*/
		union all select 11 rn, '    (2) 제)직원급여' gubun
/*		union all select 12 rn, '      1. 제)급여-직원' gubun*/
		union all select 13 rn, '    (3) 제)상여금' gubun
/*		union all select 14 rn, '      1. 제)상여금-직원' gubun*/
		union all select 15 rn, '    (4) 제)제수당' gubun
/*		union all select 16 rn, '      1. 제)제수당-연차' gubun
		union all select 17 rn, '      2. 제)제수당-일반' gubun*/
		union all select 18 rn, '    (5) 제)퇴직급여' gubun
/*		union all select 19 rn, '      1. 제)퇴직급여-임원' gubun
		union all select 20 rn, '      2. 제)퇴직급여-직원' gubun*/
		union all select 21 rn, '    (6) 제)주식보상비용' gubun
/*		union all select 22 rn, '      1. 제)주식보상비용' gubun*/
		union all select 23 rn, '  III. 경비' gubun
		union all select 24 rn, '    (1) 제)복리후생비' gubun
/*		union all select 25 rn, '      1. 제)복리후생비-건강,장기요양보험' gubun
		union all select 26 rn, '      2. 제)복리후생비-사내식대' gubun
		union all select 27 rn, '      3. 제)복리후생비-외부식대등' gubun
		union all select 28 rn, '      4. 제)복리후생비-경조사비' gubun
		union all select 29 rn, '      5. 제)복리후생비-일반' gubun
		union all select 30 rn, '      6. 제)복리후생비-의료' gubun*/
		union all select 31 rn, '    (2) 제)여비교통비' gubun
/*		union all select 32 rn, '      1. 제)여비교통비-국내출장경비(법인)' gubun
		union all select 33 rn, '      2. 제)여비교통비-국내출장경비(기타)' gubun*/
		union all select 34 rn, '    (3) 제)통신비' gubun
/*		union all select 35 rn, '      1. 제)통신비' gubun*/
		union all select 36 rn, '    (4) 제)수도광열비' gubun
/*		union all select 37 rn, '      1. 제)수도광열비-수도료' gubun
		union all select 38 rn, '      2. 제)수도광열비-연료비' gubun*/
		union all select 39 rn, '    (5) 제)전력비' gubun
/*		union all select 40 rn, '      1. 제)전력비' gubun*/
		union all select 41 rn, '    (6) 제)세금과공과' gubun
/*		union all select 42 rn, '      1. 제)세금과공과-연금보험' gubun
		union all select 43 rn, '      2. 제)세금과공과-일반' gubun*/
		union all select 44 rn, '    (7) 제)감가상각비' gubun
/*		union all select 45 rn, '      1. 제)감가상각비-건물' gubun
		union all select 46 rn, '      2. 제)감가상각비-구축물' gubun
		union all select 47 rn, '      3. 제)감가상각비-기계장치' gubun
		union all select 48 rn, '      4. 제)감가상각비-공구와기구' gubun
		union all select 49 rn, '      5. 제)감가상각비-비품' gubun
		union all select 50 rn, '      6. 제)감가상각비-시설장치' gubun*/
		union all select 51 rn, '    (8) 제)지급임차료' gubun
/*		union all select 52 rn, '      1. 제)지급임차료-건물' gubun
		union all select 53 rn, '      2. 제)지급임차료-차량' gubun
		union all select 54 rn, '      3. 제)지급임차료-일반' gubun*/
		union all select 55 rn, '    (9) 제)수선비' gubun
/*		union all select 56 rn, '      1. 제)수선비' gubun*/
		union all select 57 rn, '    (10) 제)보험료' gubun
/*		union all select 58 rn, '      1. 제)보험료-고용,산재보험' gubun
		union all select 59 rn, '      2. 제)보험료-차량' gubun
		union all select 60 rn, '      3. 제)보험료-건물' gubun
		union all select 61 rn, '      4. 제)보험료-일반' gubun*/
		union all select 62 rn, '    (11) 제)차량유지비' gubun
/*		union all select 63 rn, '      1. 제)차량유지비-유류비' gubun
		union all select 64 rn, '      2. 제)차량유지비-관리비' gubun
		union all select 65 rn, '      3. 제)차량유지비-일반' gubun
		union all select 66 rn, '      4. 제)차량유지비-자동차세' gubun*/
		union all select 67 rn, '    (12) 제)운반비' gubun
/*		union all select 68 rn, '      1. 제)운반비-국내운송료' gubun
		union all select 69 rn, '      2. 제)운반비-해외운송료' gubun*/
		union all select 70 rn, '    (13) 제)교육훈련비' gubun
/*		union all select 71 rn, '      1. 제)교육훈련비-사외' gubun*/
		union all select 72 rn, '    (14) 제)도서인쇄비' gubun
/*		union all select 73 rn, '      1. 제)도서인쇄비' gubun*/
		union all select 74 rn, '    (15) 제)소모품비' gubun
/*		union all select 75 rn, '      1. 제)소모품비-비품' gubun
		union all select 76 rn, '      2. 제)소모품비-사무용품' gubun
		union all select 77 rn, '      3. 제)소모품비-일반' gubun*/
		union all select 78 rn, '    (16) 제)지급수수료' gubun
/*		union all select 79 rn, '      1. 제)지급수수료-유지보수료' gubun
		union all select 80 rn, '      2. 제)지급수수료-검사.측정료' gubun
		union all select 81 rn, '      3. 제)지급수수료-일반' gubun*/
		union all select 82 rn, '    (17) 제)외주가공비' gubun
/*		union all select 83 rn, '      1. 제)외주가공비' gubun*/
		union all select 84 rn, '    (18) 제)사용권자산감가상각비' gubun
/*		union all select 85 rn, '      1. 제)사용권자산상각비-건물' gubun
		union all select 86 rn, '      2. 제)사용권자산상각비-차량' gubun*/
		union all select 87 rn, '    (19) 제)검사비' gubun
/*		union all select 88 rn, '      1. 제)검사비' gubun*/
		union all select 89 rn, '    (20) 제)견본비' gubun
/*		union all select 90 rn, '      1. 제)견본비' gubun*/
		union all select 91 rn, '  IV. 당기총제조원가' gubun
		) B 
	) X 
	left join (
		select 1 rn, '  I. 재료비' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and 
		(
			(mat_class/*+자재대분류 */='원자재'/*+'원자재'*/)
			or 
			(mat_class+자재대분류 ='원자재'+'카세트' )
			or 
			(mat_class+자재대분류 ='부자재'+'필름' )
			or
			(mat_class+자재대분류 ='부자재'+'트레이' )
			or
			(mat_class+자재대분류 ='부자재'+'약액' )
			or 
			(mat_class+coalesce(자재대분류,'1') ='약액'+'1'  )
			or
			(mat_class+coalesce(자재대분류,'1') in ('부자재'+'1','부자재'+'부자재','부자재'+'카세트','더미글라스'+'부자재','부자재'+'타부서 구매품') )
		)
		group by 구분,도우모델
		union all 
		select 2 rn, '    (1) 원재료_원장' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and (mat_class+자재대분류 ='원자재' OR /*+'원자재'*/원가자재분류 = '원장')
		group by 구분,도우모델
		union all 
		select 3 rn, '    (2) 원재료_카세트 부품' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and ((mat_class+자재대분류 ='원자재'+'카세트' ) OR 원가자재분류 ='카세트')
		group by 구분,도우모델		
		union all 
		select 4 rn, '    (3) 원재료_필름' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and (mat_class+자재대분류 = '부자재' + '필름' OR 원가자재분류 ='필름' )
		group by 구분,도우모델
		union all 
		select 5 rn, '    (4) 원재료_약액' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and ((mat_class+coalesce(자재대분류,'1') ='약액'+'1'  ) or (mat_class+자재대분류 ='부자재'+'약액' ) OR 원가자재분류 = '약액')
		group by 구분,도우모델		
		union all 
		select 6 rn, '    (5) 부재료_트레이' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and (mat_class+자재대분류 ='부자재'+'트레이' OR 원가자재분류 = '트레이' )
		group by 구분,도우모델
		union all
		select 7 rn, '    (6) 부재료_기타' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and (mat_class+coalesce(자재대분류,'1') in ('부자재'+'1','부자재'+'부자재','부자재'+'카세트','더미글라스'+'부자재','부자재'+'타부서 구매품','부자재'+'카세트제품') 
			AND COALESCE(NULLIF(LTRIM(RTRIM(원가자재분류)),''), N'기타') = N'기타')
		group by 구분,도우모델
		union all 
		select 8 rn, '  II. 노무비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and acct_name in ('제)급여-임원','제)급여-직원','제)상여금-직원','제)제수당-연차','제)제수당-일반','제)퇴직급여-임원','제)퇴직급여-직원')
		group by 구분,model
		union all 
		select 9 rn, '    (1) 제)임원급여' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)급여-임원' group by 구분,model
		union all
/*		select 10 rn, '      1. 제)급여-임원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)급여-임원' group by 구분,model
		union all*/
		select 11 rn, '    (2) 제)직원급여' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)급여-직원' group by 구분,model
		union all
/*		select 12 rn, '      1. 제)급여-직원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)급여-직원' group by 구분,model
		union all*/
		select 13 rn, '    (3) 제)상여금' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)상여금-직원' group by 구분,model
		union all
/*		select 14 rn, '      1. 제)상여금-직원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)상여금-직원' group by 구분,model
		union all */
		select 15 rn, '    (4) 제)제수당' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in('제)제수당-연차','제)제수당-일반') group by 구분,model
		union all 
/*		select 16 rn, '      1. 제)제수당-연차' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)제수당-연차' group by 구분,model
		union all 
		select 17 rn, '      2. 제)제수당-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)제수당-일반' group by 구분,model
		union all */
		select 18 rn, '    (5) 제)퇴직급여' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)퇴직급여-임원','제)퇴직급여-직원') group by 구분,model
		union all 
/*		select 19 rn, '      1. 제)퇴직급여-임원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)퇴직급여-임원' group by 구분,model
		union all 
		select 20 rn, '      2. 제)퇴직급여-직원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)퇴직급여-직원' group by 구분,model
		union all */
		select 21 rn, '    (6) 제)주식보상비용' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)주식보상비용' group by 구분,model
		union all 
/*		select 22 rn, '      1. 제)주식보상비용' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)주식보상비용' group by 구분,model
		union all*/ 
		select 23 rn, '  III. 경비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
		and acct_name in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료','제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)'
		,'제)통신비','제)수도광열비-수도료','제)수도광열비-연료비','제)전력비','제)세금과공과-연금보험','제)세금과공과-일반','제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치'
		,'제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반','제)수선비','제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반','제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세'
		,'제)운반비-국내운송료','제)운반비-해외운송료','제)교육훈련비-사외','제)도서인쇄비','제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반','제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반','제)외주가공비','제)사용권자산상각비-건물','제)사용권자산상각비-차량','제)검사비','제)견본비')
		group by 구분,model
		union all 
		select 24 rn, '    (1) 제)복리후생비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료') group by 구분,model
		union all 
/*		select 25 rn, '      1. 제)복리후생비-건강,장기요양보험' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-건강,장기요양보험' group by 구분,model
		union all 
		select 26 rn, '      2. 제)복리후생비-사내식대' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-사내식대' group by 구분,model
		union all 
		select 27 rn, '      3. 제)복리후생비-외부식대등' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-외부식대등' group by 구분,model
		union all 
		select 28 rn, '      4. 제)복리후생비-경조사비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-경조사비' group by 구분,model
		union all 
		select 29 rn, '      5. 제)복리후생비-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-일반' group by 구분,model
		union all 
		select 30 rn, '      6. 제)복리후생비-의료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-의료' group by 구분,model
		union all */
		select 31 rn, '    (2) 제)여비교통비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)') group by 구분,model
		union all 
/*		select 32 rn, '      1. 제)여비교통비-국내출장경비(법인)' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)여비교통비-국내출장경비(법인)' group by 구분,model
		union all 
		select 33 rn, '      2. 제)여비교통비-국내출장경비(기타)' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)여비교통비-국내출장경비(기타)' group by 구분,model
		union all */
		select 34 rn, '    (3) 제)통신비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)통신비' group by 구분,model
		union all 
/*		select 35 rn, '      1. 제)통신비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)통신비' group by 구분,model
		union all */
		select 36 rn, '    (4) 제)수도광열비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)수도광열비-수도료','제)수도광열비-연료비') group by 구분,model
		union all 
/*		select 37 rn, '      1. 제)수도광열비-수도료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수도광열비-수도료' group by 구분,model
		union all 
		select 38 rn, '      2. 제)수도광열비-연료비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수도광열비-연료비' group by 구분,model
		union all */
		select 39 rn, '    (5) 제)전력비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)전력비' group by 구분,model
		union all 
/*		select 40 rn, '      1. 제)전력비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)전력비' group by 구분,model
		union all */
		select 41 rn, '    (6) 제)세금과공과' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)세금과공과-연금보험','제)세금과공과-일반') group by 구분,model
		union all 
/*		select 42 rn, '      1. 제)세금과공과-연금보험' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)세금과공과-연금보험' group by 구분,model
		union all 
		select 43 rn, '      2. 제)세금과공과-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)세금과공과-일반' group by 구분,model
		union all*/ 
		select 44 rn, '    (7) 제)감가상각비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치') group by 구분,model
		union all 
/*		select 45 rn, '      1. 제)감가상각비-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-건물' group by 구분,model
		union all 
		select 46 rn, '      2. 제)감가상각비-구축물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-구축물' group by 구분,model
		union all 
		select 47 rn, '      3. 제)감가상각비-기계장치' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-기계장치' group by 구분,model
		union all 
		select 48 rn, '      4. 제)감가상각비-공구와기구' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-공구와기구' group by 구분,model
		union all 
		select 49 rn, '      5. 제)감가상각비-비품' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-비품' group by 구분,model
		union all 
		select 50 rn, '      6. 제)감가상각비-시설장치' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-시설장치' group by 구분,model
		union all */
		select 51 rn, '    (8) 제)지급임차료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반') group by 구분,model
		union all 
/*		select 52 rn, '      1. 제)지급임차료-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급임차료-건물' group by 구분,model
		union all 
		select 53 rn, '      2. 제)지급임차료-차량' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급임차료-차량' group by 구분,model
		union all 
		select 54 rn, '      3. 제)지급임차료-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급임차료-일반' group by 구분,model
		union all */
		select 55 rn, '    (9) 제)수선비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)수선비' group by 구분,model
		union all 
/*		select 56 rn, '      1. 제)수선비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수선비' group by 구분,model
		union all */
		select 57 rn, '    (10) 제)보험료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반') group by 구분,model
		union all 
/*		select 58 rn, '      1. 제)보험료-고용,산재보험' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-고용,산재보험' group by 구분,model
		union all 
		select 59 rn, '      2. 제)보험료-차량' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-차량' group by 구분,model
		union all 
		select 60 rn, '      3. 제)보험료-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-건물' group by 구분,model
		union all 
		select 61 rn, '      4. 제)보험료-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-일반' group by 구분,model
		union all */
		select 62 rn, '    (11) 제)차량유지비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세') group by 구분,model
		union all 
/*		select 63 rn, '      1. 제)차량유지비-유류비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-유류비' group by 구분,model
		union all 
		select 64 rn, '      2. 제)차량유지비-관리비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-관리비' group by 구분,model
		union all 
		select 65 rn, '      3. 제)차량유지비-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-일반' group by 구분,model
		union all 
		select 66 rn, '      4. 제)차량유지비-자동차세' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-자동차세' group by 구분,model
		union all */
		select 67 rn, '    (12) 제)운반비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)운반비-국내운송료','제)운반비-해외운송료') group by 구분,model
		union all 
/*		select 68 rn, '      1. 제)운반비-국내운송료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)운반비-국내운송료' group by 구분,model
		union all 
		select 69 rn, '      2. 제)운반비-해외운송료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)운반비-해외운송료' group by 구분,model
		union all*/ 
		select 70 rn, '    (13) 제)교육훈련비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)교육훈련비-사외') group by 구분,model
		union all 
/*		select 71 rn, '      1. 제)교육훈련비-사외' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)교육훈련비-사외' group by 구분,model
		union all */
		select 72 rn, '    (14) 제)도서인쇄비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)도서인쇄비' group by 구분,model
		union all 
/*		select 73 rn, '      1. 제)도서인쇄비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)도서인쇄비' group by 구분,model
		union all */
		select 74 rn, '    (15) 제)소모품비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반') group by 구분,model
		union all 
/*		select 75 rn, '      1. 제)소모품비-비품' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)소모품비-비품' group by 구분,model
		union all 
		select 76 rn, '      2. 제)소모품비-사무용품' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)소모품비-사무용품' group by 구분,model
		union all 
		select 77 rn, '      3. 제)소모품비-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)소모품비-일반' group by 구분,model
		union all */
		select 78 rn, '    (16) 제)지급수수료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반') group by 구분,model
		union all 
/*		select 79 rn, '      1. 제)지급수수료-유지보수료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급수수료-유지보수료' group by 구분,model
		union all 
		select 80 rn, '      2. 제)지급수수료-검사.측정료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급수수료-검사.측정료' group by 구분,model
		union all 
		select 81 rn, '      3. 제)지급수수료-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급수수료-일반' group by 구분,model
		union all */
		select 82 rn, '    (17) 제)외주가공비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)외주가공비' group by 구분,model
		union all 
/*		select 83 rn, '      1. 제)외주가공비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)외주가공비' group by 구분,model
		union all */
		select 84 rn, '    (18) 제)사용권자산감가상각비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name in ('제)사용권자산상각비-건물','제)사용권자산상각비-차량') group by 구분,model
		union all 
/*		select 85 rn, '      1. 제)사용권자산상각비-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)사용권자산상각비-건물' group by 구분,model
		union all 
		select 86 rn, '      2. 제)사용권자산상각비-차량' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)사용권자산상각비-차량' group by 구분,model
		union all */
		select 87 rn, '    (19) 제)검사비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)검사비' group by 구분,model
		union all 
/*		select 88 rn, '      1. 제)검사비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)검사비' group by 구분,model
		union all */
		select 89 rn, '    (20) 제)견본비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE and acct_name='제)견본비' group by 구분,model
		union all 
/*		select 90 rn, '      1. 제)견본비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)견본비' group by 구분,model
		union all*/		
		select 91 rn, '  IV. 당기총제조원가' gubun,구분,model, sum(amt) amt 
		from(
			select 1 rn, '  I. 재료비' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
			/*and 
			(
				(mat_class+자재대분류 ='원자재'+'원자재')
				or 
				(mat_class+자재대분류 ='원자재'+'카세트' )
				or 
				(mat_class+자재대분류 ='부자재'+'필름' )
				or
				(mat_class+자재대분류 ='부자재'+'트레이' )
				or 
				(mat_class+coalesce(자재대분류,'1') ='약액'+'1'  )
				or
				(mat_class+coalesce(자재대분류,'1') in ('부자재'+'1','부자재'+'부자재','부자재'+'카세트') )
			)*/
			group by 구분,도우모델
			union all
			select 8 rn, '  II. 노무비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE 
			and acct_name in ('제)급여-임원','제)급여-직원','제)상여금-직원','제)제수당-연차','제)제수당-일반','제)퇴직급여-임원','제)퇴직급여-직원')
			group by 구분,model
			union all
			select 23 rn, '  III. 경비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE 
			and acct_name in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료','제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)'
			,'제)통신비','제)수도광열비-수도료','제)수도광열비-연료비','제)전력비','제)세금과공과-연금보험','제)세금과공과-일반','제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치'
			,'제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반','제)수선비','제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반','제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세'
			,'제)운반비-국내운송료','제)운반비-해외운송료','제)교육훈련비-사외','제)도서인쇄비','제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반','제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반','제)외주가공비','제)사용권자산상각비-건물','제)사용권자산상각비-차량','제)검사비','제)견본비')
			group by 구분,model
		) A
		group by 구분,model
	) Y
	on 1=1
	and X.rn = Y.rn 
	and X.gubun = Y.gubun 
	and X.구분 = Y.구분
	and X.model = replace(Y.model,' ','')
)
SELECT * INTO #sourceTable FROM sourceTable;

-- 동적 SQL 생성
		SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
	select CONCAT(구분,model) model, rn, gubun, amt from #sourceTable
	union all 
	select ''Z합계'' model, rn, gubun, sum(amt) amt from #sourceTable group by rn, gubun
	union all  
	select CONCAT(''Z'',구분,''합계'') model, rn, gubun, amt from (
		select rn, gubun, 구분, sum(amt) amt from #sourceTable group by rn, gubun, 구분 
	) a 	
) AS SourceTable
PIVOT 
(
	SUM(AMT)
	FOR model IN (' + @Columns + ')
) AS PivotTable
order by 1,2 desc;';
		
		-- 동적 SQL 실행
		--select @SQL;
		EXEC sp_executesql @SQL;
		COMMIT TRANSACTION;
-- 임시 테이블 정리
DROP TABLE #sourceTable;	
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
GO

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
		DECLARE @SCRAP_ADJ   DECIMAL(18,2) = 0;   -- 원부재료 재고폐기 (DOI_ETC_INOUT, 본사 전용)

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

		UNION

		-- 제품 폐기만 발생한 모델도 손익 대상에 포함.
		-- 매출이 없으면 위 UNION 들에 안 잡히는데, 폐기는 (3)제품매출원가조정으로 반영해야 하므로 모델을 살린다.
		-- DOI_STCO 의 폐기 행은 구분='RMA' 로 들어오므로 같은 모델의 정상 구분을 끌어온다.
		SELECT
		    COALESCE(MAX(CASE WHEN D.구분 <> N'RMA' THEN D.구분 END),
		             CASE WHEN LEFT(D.MODEL,2) = N'VN' THEN N'카세트' ELSE N'양산' END) AS 구분,
		    D.MODEL AS model
		FROM DOI_STCO D WITH(NOLOCK)
		WHERE D.YYYYMM = @YYYYMM AND D.SITE = @SITE AND D.SEL_CODE = @SEL_CODE
		GROUP BY D.MODEL
		HAVING SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) <> 0
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
		    COALESCE(MAX(CASE WHEN D.구분 <> N'RMA' THEN D.구분 END),
		             CASE WHEN LEFT(D.MODEL,2) = N'VN' THEN N'카세트' ELSE N'양산' END) AS 구분,
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

		-- 원부재료 재고폐기: 기타입출고금액(통합)에서 '재고폐기' AND 품목자산분류<>'제품'.
		-- 회계 열('회계-조정')의 (3)제품매출원가조정에 가산한다. 본사 전용(VN 미적용).
		IF @SITE = 'HQ'
		BEGIN
			SELECT @SCRAP_ADJ = CAST(COALESCE(SUM(금액),0) AS DECIMAL(18,2))
			FROM DOI_ETC_INOUT WITH(NOLOCK)
			WHERE yyyymm = @YYYYMM
			  AND 기타입출고구분 = N'재고폐기'
			  AND 품목자산분류 <> N'제품';
		END
		 
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
        -- 9-1. 원부재료 재고폐기를 회계 열('회계-조정')에 반영
        --      (3)제품매출원가조정(rn12)에 가산 → II.매출원가(rn5) 증가,
        --      III.매출총이익(rn13)·V.영업이익(rn141) 은 그만큼 감소.
        --      Z합계/Z합계회계 보다 먼저 적용해야 상위 합계에 전파된다.
        ----------------------------------------------------------------------
        IF @SCRAP_ADJ <> 0
        BEGIN
            UPDATE #sourceTable SET amt = COALESCE(amt,0) + @SCRAP_ADJ
             WHERE 구분 = N'회계' AND model = N'회계-조정' AND rn IN (5, 12);

            UPDATE #sourceTable SET amt = COALESCE(amt,0) - @SCRAP_ADJ
             WHERE 구분 = N'회계' AND model = N'회계-조정' AND rn IN (13, 141);
        END

        ----------------------------------------------------------------------
        -- 9-2. 제품 폐기를 모델별 (3)제품매출원가조정 에 반영
        --      매출원가(제품) 화면 출고상세-폐기(DOI_STCO.OUT_DISPOSE_AMT) 기준.
        --      rn12 가산 → rn5(II.매출원가) 증가, rn13·rn141 은 그만큼 감소.
        --      Z합계/구분별 합계보다 먼저 적용해야 상위 합계에 전파된다.
        ----------------------------------------------------------------------
        UPDATE s SET amt = COALESCE(s.amt,0) + d.amt
          FROM #sourceTable s
          JOIN #DISPOSE d ON d.구분 = s.구분 AND d.model = s.model
         WHERE s.rn IN (5, 12);

        UPDATE s SET amt = COALESCE(s.amt,0) - d.amt
          FROM #sourceTable s
          JOIN #DISPOSE d ON d.구분 = s.구분 AND d.model = s.model
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
GO

ALTER PROCEDURE DOI_SalesAdminByModel(
    @YYYYMM varchar(10),
     @SITE varchar(4),
     @SEL_CODE varchar(10)
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Columns VARCHAR(3000);
        DECLARE @Null_Columns VARCHAR(3000);
        DECLARE @SQL NVARCHAR(MAX);
		DECLARE @Prod_Rate DECIMAL(18,2) = 0;
		DECLARE @Dev_Rate DECIMAL(18,2)  = 0;

        SELECT @Columns = COALESCE(@Columns + '], [', '') + model
        FROM (SELECT DISTINCT TOP 500 model 
                FROM (
                SELECT DISTINCT 구분+model as model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
                union all SELECT 'X합계' model union all SELECT 'Y합계' model union all SELECT 'Z합계' model
                  )A
                ORDER BY 1 )AS 도우모델 ;
        
        select @Columns=  '['+@Columns+']';
        
        SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
        FROM (SELECT DISTINCT TOP 500 model 
                FROM (
                SELECT DISTINCT 구분+model as model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
                union all SELECT 'X합계' model union all SELECT 'Y합계' model union all SELECT 'Z합계' mode
                  )A
                ORDER BY 1 )AS 도우모델 ;
        
        select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]','');

        with sourceTable as (
            select X.*, COALESCE(Y.amt,0) amt from (
                select * from (
                    SELECT DISTINCT TOP 500 model 
                    FROM (
                        SELECT DISTINCT 구분+model as model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
                    )A
                    ORDER BY 1
                ) A 
                cross join 
                (
                select 0 as rn, '    판관비 배부율 (제품별 매출비중)' as gubun
                union all select 1, '    (1) 판)임원급여'
                union all select 3, '    (2) 판)직원급여'
                union all select 5, '    (3) 판)상여금'
                union all select 7, '    (4) 판)제수당'
                union all select 10, '    (5) 판)퇴직급여'
                union all select 13, '    (6) 판)복리후생비'
                union all select 20, '    (7) 판)여비교통비'
                union all select 25, '    (8) 판)접대비'
                union all select 29, '    (9) 판)통신비'
                union all select 31, '    (10) 판)수도광열비'
                union all select 33, '    (11) 판)세금과공과'
                union all select 38, '    (12) 판)감가상각비'
                union all select 44, '    (13) 판)지급임차료'
                union all select 49, '    (14) 판)수선비'
                union all select 51, '    (15) 판)보험료'
                union all select 56, '    (16) 판)차량유지비'
                union all select 61, '    (17) 판)경상연구개발비'
                union all select 92, '    (18) 판)운반비'
                union all select 95, '    (19) 판)교육훈련비'
                union all select 97, '    (20) 판)도서인쇄비'
                union all select 99, '    (21) 판)소모품비'
                union all select 104, '    (22) 판)지급수수료'
                union all select 112, '    (23) 판)광고선전비'
                union all select 115, '    (24) 판)무형자산상각비'
                union all select 117, '    (25) 판)견본비'
                union all select 119, '    (26) 판)사용권자산감가상각비'
                union all select 122, '    (27) 판)주식보상비용'
                union all select 124, '    (28) 판)해외시장개척비'
                union all select 999, '    (29) 합계'
                ) B 
            ) X 
            left join (
            select 0 as rn, '    판관비 배부율 (제품별 매출비중)'as gubun, model, cast(amt/sum(amt) over() as numeric(10,3)) as amt
            from (
                select 구분+model as model, sum(dist_amt) as amt
                from doi_smce_cost
                where yyyymm = @yyyymm and site =  @site and sel_code=@SEL_CODE
                group by 구분+model
            ) A
            union all
            select 1 as rn, '    (1) 판)임원급여' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name = '판)급여-임원' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 3 as rn, '    (2) 판)직원급여' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name = '판)급여-직원' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 5 as rn, '    (3) 판)상여금' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name = '판)상여금-직원' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 7 as rn, '    (4) 판)제수당' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)제수당%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 10 as rn, '    (5) 판)퇴직급여' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)퇴직급여%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 13 as rn, '    (6) 판)복리후생비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)복리후생비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 20 as rn, '    (7) 판)여비교통비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)여비교통비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 25 as rn, '    (8) 판)접대비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)접대비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 29 as rn, '    (9) 판)통신비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)통신비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 31 as rn, '    (10) 판)수도광열비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)수도광열비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 33 as rn, '    (11) 판)세금과공과' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)세금과공과%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 38 as rn, '    (12) 판)감가상각비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)감가상각비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 44 as rn, '    (13) 판)지급임차료' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)지급임차료%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 49 as rn, '    (14) 판)수선비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)수선비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 51 as rn, '    (15) 판)보험료' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)보험료%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 56 as rn, '    (16) 판)차량유지비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)차량유지비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 61 as rn, '    (17) 판)경상연구개발비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)경상연구개발비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 92 as rn, '    (18) 판)운반비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)운반비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 95 as rn, '    (19) 판)교육훈련비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)교육훈련비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 97 as rn, '    (20) 판)도서인쇄비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)도서인쇄비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 99 as rn, '    (21) 판)소모품비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)소모품비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 104 as rn, '    (22) 판)지급수수료' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)지급수수료%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 112 as rn, '    (23) 판)광고선전비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)광고선전비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 115 as rn, '    (24) 판)무형자산상각비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)무형자산상각비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 117 as rn, '    (25) 판)견본비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)견본비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 119 as rn, '    (26) 판)사용권자산감가상각비' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)사용권자산상각비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 122 as rn, '    (27) 판)주식보상비용' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)주식보상비용%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 124 as rn, '    (28) 판)해외시장개척비' as gubun, 구분+model as model, sum(dist_amt) as amt
 from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)해외시장개척비%' and sel_code=@SEL_CODE
            group by 구분+model
            union all
            select 999 as rn, '    (29) 합계' as gubun, 구분+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sel_code=@SEL_CODE
            group by 구분+model
            ) Y
            on 1=1
            and X.rn = Y.rn 
            and X.gubun = Y.gubun 
            and X.model = Y.model
        )
        SELECT * INTO #sourceTable1 FROM sourceTable;
        
        SELECT @Prod_Rate = sum(case when model like '양산%' then amt else 0 end)/SUM(amt) from #sourceTable1;
        SELECT @Dev_Rate  = sum(case when model like '개발%' then amt else 0 end)/SUM(amt) from #sourceTable1;

        SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
    select * from #sourceTable1
    union all 
    select ''X합계'' model, rn, gubun, CASE WHEN RN=0 THEN '+CAST(@Prod_Rate as varchar)+' ELSE sum(amt) END amt from #sourceTable1 
	where model like ''양산%'' group by rn, gubun
    union all 
    select ''Y합계'' model, rn, gubun, CASE WHEN RN=0 THEN '+CAST(@Dev_Rate as varchar)+' ELSE sum(amt) END amt from #sourceTable1 
	where model like ''개발%'' group by rn, gubun
    union all 
    select ''Z합계'' model, rn, gubun, CASE WHEN RN=0 THEN 1 ELSE sum(amt) END amt from #sourceTable1 group by rn, gubun
) AS SourceTable
PIVOT 
(
    SUM(AMT)
    FOR model IN (' + @Columns + ')
) AS PivotTable
order by 1,2 desc;';
        
--select @SQL;
        EXEC sp_executesql @SQL;
        COMMIT TRANSACTION;
       DROP TABLE #sourceTable1;	
    END TRY
    
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

ALTER PROCEDURE DOI_TotalCost_Tree
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
		DECLARE @SumYangsan_ProdSale NVARCHAR(MAX)=N'0';  -- 제품매출(rn=2), 매출단가용
		DECLARE @SumDev_ProdSale     NVARCHAR(MAX)=N'0';
		DECLARE @SumCas_ProdSale     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_ProdSale     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Qty      NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Bep NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Bep     NVARCHAR(MAX)=N'0';  --손익분기점 : Break-Even Point (BEP) Operating Profit
		DECLARE @SumCas_Bep     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Bep     NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Op NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Op     NVARCHAR(MAX)=N'0';  -- 영업이익  : Operating Profit
		DECLARE @SumCas_Op     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Op     NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_FiX  NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Fix      NVARCHAR(MAX)=N'0';
--		DECLARE @SumCas_Fix      NVARCHAR(MAX)=N'0';
--		DECLARE @SumPur_Fix      NVARCHAR(MAX)=N'0';

        DECLARE @SCOFTotal DECIMAL(18,2) = 0;
        DECLARE @CostAdj DECIMAL(18,2) = 0;
        DECLARE @LossAdj DECIMAL(18,2) = 0;
        DECLARE @LossAdjYangsan DECIMAL(18,2) = 0;
		DECLARE @LossAdjDev     DECIMAL(18,2) = 0;
		DECLARE @LossAdjCassette DECIMAL(18,2) = 0;
	
		DECLARE @ACC_PREV_PRICE DECIMAL(18,2) = 0;   -- 이전가격 (기타매출/41004010/재경그룹)
		DECLARE @ACC_IDLE_COMP  DECIMAL(18,2) = 0;   -- 비가동보상 (제품매출/41002010/재경그룹)
		DECLARE @ACC_ADJ        DECIMAL(18,2) = 0;   -- 조정 (제품매출/41002020/영업그룹 제외)
		DECLARE @ACC_TOTAL      DECIMAL(18,2) = 0;   -- 회계합계
		DECLARE @SCOF_ACC       DECIMAL(18,2) = 0;   -- 회계-조정 유상사급 (DOI_원장상계 구분='회계')
		DECLARE @ACC_SCRAP      DECIMAL(18,2) = 0;   -- 원부재료 재고폐기 (DOI_ETC_INOUT, 본사 전용)
		-- 제품 폐기 (매출원가(제품) 출고상세-폐기, DOI_STCO.OUT_DISPOSE_AMT) : 구분별 합계 열용
		DECLARE @DispAdj          DECIMAL(18,2) = 0;
		DECLARE @DispAdjYangsan   DECIMAL(18,2) = 0;
		DECLARE @DispAdjDev       DECIMAL(18,2) = 0;
		DECLARE @DispAdjCassette  DECIMAL(18,2) = 0;

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
		        , A.품명 AS model
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
		        , B.품명 AS model
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
        ;WITH LOSS_MODEL AS (
		    SELECT DISTINCT
		          C.model
		        , C.구분
		    FROM DOI_COST C WITH(NOLOCK)
		    WHERE C.YYYYMM   = @YYYYMM
		      AND C.SITE     = @SITE
		      AND C.SEL_CODE = @SELCODE
		      AND COALESCE(C.LOSS, 0) <> 0
		),
		DISPOSE_MODEL AS (
		    -- 제품 폐기만 발생한 모델도 열을 만든다 (매출·LOSS 가 없으면 위 소스에 안 잡힘).
		    -- 폐기 행은 구분='RMA' 라서 같은 모델의 정상 구분으로 되돌린다.
		    SELECT
		          D.MODEL AS model
		        , COALESCE(MAX(CASE WHEN D.구분 <> N'RMA' THEN D.구분 END),
		                   CASE WHEN LEFT(D.MODEL,2) = N'VN' THEN N'카세트' ELSE N'양산' END) AS 구분
		    FROM DOI_STCO D WITH(NOLOCK)
		    WHERE D.YYYYMM   = @YYYYMM
		      AND D.SITE     = @SITE
		      AND D.SEL_CODE = @SELCODE
		    GROUP BY D.MODEL
		    HAVING SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) <> 0
		),
		MODEL_BASE AS (
		    SELECT
		          S.model
		        , S.구분
		    FROM #SALES_BASE S

		    UNION

		    SELECT
		          L.model
		        , L.구분
		    FROM LOSS_MODEL L

		    UNION

		    SELECT
		          P.model
		        , P.구분
		    FROM DISPOSE_MODEL P

		    UNION
		
		    SELECT
		          CASE WHEN O.모델 = N'회계-조정' THEN O.모델 ELSE LEFT(O.모델, LEN(O.모델)-1) END
		        , O.구분
		    FROM DOI_원장상계 O
			WHERE 1=1
			  AND YYYYMM=@YYYYMM
			  AND COALESCE(O.매출상계,0) <> 0
			  AND O.구분 <> N'회계'   -- 회계-조정은 회계 컬럼에서 처리(모델컬럼 제외)
		  	  AND NULLIF(모델,'') IS NOT NULL
		)
		SELECT
		      CAST(model AS NVARCHAR(500)) AS model
		    , CAST(구분 AS NVARCHAR(50)) AS 구분
		    , CASE
		          WHEN 구분 = N'구매' THEN N'상품'
		          WHEN 구분 = N'카세트' THEN N'카세트'
		          WHEN LEFT(model, 1) = 'I' THEN 'ITG'
		          WHEN LEFT(model, 1) = 'H' THEN 'HTG'
		          WHEN LEFT(model, 1) = 'C' THEN 'Coated'
		          ELSE 'UTG'
		      END AS 제품구조
		    , CASE
		          WHEN 구분 = N'카세트' THEN 1
		          WHEN LEFT(model, 2) = 'VN' THEN 1
		          ELSE 0
		      END AS is_cassette
			, CAST(
			    (CASE
			        WHEN 구분 = N'카세트' OR LEFT(model, 2) = N'VN' THEN N'카세트'
			        WHEN 구분 = N'개발'   THEN N'개발'
			        WHEN 구분 = N'구매'   THEN N'구매'
			        ELSE N'양산'
			     END) + CAST(model AS NVARCHAR(500))
			  AS NVARCHAR(600)) AS pivot_key
		    , CASE
		          WHEN LEFT(model, 1) BETWEEN '0' AND '9' THEN 0
		          ELSE 1
		      END AS sort_numeric
		    , CASE
		          WHEN 구분 = N'카세트' OR LEFT(model, 2) = N'VN' THEN 3
		          WHEN 구분 = N'양산' THEN 1
		          WHEN 구분 = N'개발' THEN 2
		          WHEN 구분 = N'구매' THEN 4
		          ELSE 9
		      END AS sort_group
		    , CASE
		          WHEN 구분 = N'구매' THEN 9
		          WHEN 구분 = N'카세트' THEN 8
		          WHEN LEFT(model, 1) = 'I' THEN 2
		          WHEN LEFT(model, 1) = 'H' THEN 3
		          WHEN LEFT(model, 1) = 'C' THEN 4
		          ELSE 1
		      END AS sort_structure
		INTO #MODEL
		FROM MODEL_BASE;
       
--     SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
--	   FROM DOI_SCOF WITH(NOLOCK)
	  SELECT @SCOFTotal = CAST(COALESCE(SUM(매출상계),0) AS DECIMAL(18,2))
	   FROM DOI_원장상계 WITH(NOLOCK)
	   WHERE yyyymm  = @YYYYMM
	    AND site   	 = @SITE
        AND sel_code = @SELCODE

	  SELECT @SCOF_ACC = CAST(COALESCE(SUM(매출상계),0) AS DECIMAL(18,2))
	   FROM DOI_원장상계 WITH(NOLOCK)
	   WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE AND 구분 = N'회계';

        SELECT @CostAdj = COALESCE(ABS(SUM(ISNULL(대변금액,0))), 0)
		FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SELCODE
		  AND 계정과목 = N'제품매출원가'
		  AND 대변금액 <> 0;

		-- 회계 항목: 코스트센터 + 계정코드 조건(AND). 매출계정이므로 순액 = 대변 - 차변
		-- (대변 양수=양수, 차변 양수=음수). 코스트센터명은 월별 조직 스냅샷 접미(YYYYMMDD)를 허용하도록 LIKE 사용.
		 SELECT
      -- 이전가격: 41004010
      @ACC_PREV_PRICE =
          COALESCE(SUM(CASE WHEN 계정코드 = N'41004010'
                            THEN ISNULL(대변금액,0) - ISNULL(차변금액,0)
                            ELSE 0 END),0)

      -- 비가동보상: 재경그룹 AND 41002010
    , @ACC_IDLE_COMP =
          COALESCE(SUM(CASE WHEN 계정코드 = N'41002010'
                             AND 코스트센터 LIKE N'재경그룹%'
                            THEN ISNULL(대변금액,0) - ISNULL(차변금액,0)
                            ELSE 0 END),0)

      -- 조정: 41002020 / 영업그룹 제외 / 재경그룹은 차변 무시(대변만) / 나머지는 대변-차변
    , @ACC_ADJ = -@SCOF_ACC   /* 41002020 삭제 → 회계-조정 매출액 = 제품매출-유상사급 = -유상사급 2026-07-31 */
		FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SELCODE;

		SET @ACC_TOTAL =
		      @ACC_PREV_PRICE
		    + @ACC_IDLE_COMP
		    + @ACC_ADJ;

		-- 원부재료 재고폐기: 기타입출고금액(통합)에서 '재고폐기' AND 품목자산분류<>'제품'.
		-- 회계-기타 열의 (3)제품매출원가조정 위치에 표시하고 V.매출원가까지 올린다. 본사 전용(VN 미적용).
		IF @SITE = 'HQ'
		BEGIN
			SELECT @ACC_SCRAP = CAST(COALESCE(SUM(금액),0) AS DECIMAL(18,2))
			FROM DOI_ETC_INOUT WITH(NOLOCK)
			WHERE yyyymm = @YYYYMM
			  AND 기타입출고구분 = N'재고폐기'
			  AND 품목자산분류 <> N'제품';
		END
		 
		SELECT @LossAdj = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SELCODE;
		 
		SELECT @LossAdjYangsan = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SELCODE
		  AND 구분      = N'양산'
		  AND LEFT(model,2) <> N'VN';   -- 카세트 제외

		SELECT @LossAdjCassette = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SELCODE
		  AND LEFT(model,2) = N'VN';
		
		SELECT @LossAdjDev = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SELCODE
		  AND 구분      = N'개발';

		/* 제품 폐기(출고상세-폐기)를 구분별로 집계.
		   DOI_STCO 의 폐기 행은 구분='RMA' 로 들어오므로, 모델 단위로 묶은 뒤
		   같은 모델의 정상 구분(양산/개발/카세트)으로 되돌려 판정한다. */
		DROP TABLE IF EXISTS #DISPOSE;
		SELECT
		    COALESCE(MAX(CASE WHEN D.구분 <> N'RMA' THEN D.구분 END),
		             CASE WHEN LEFT(D.MODEL,2) = N'VN' THEN N'카세트' ELSE N'양산' END) AS 구분,
		    D.MODEL AS model,
		    CAST(SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) AS DECIMAL(18,2)) AS amt
		INTO #DISPOSE
		FROM DOI_STCO D WITH(NOLOCK)
		WHERE D.YYYYMM = @YYYYMM AND D.SITE = @SITE AND D.SEL_CODE = @SELCODE
		GROUP BY D.MODEL
		HAVING SUM(COALESCE(D.OUT_DISPOSE_AMT,0)) <> 0;

		SELECT @DispAdj = COALESCE(SUM(amt),0) FROM #DISPOSE;
		SELECT @DispAdjYangsan  = COALESCE(SUM(amt),0) FROM #DISPOSE WHERE 구분 = N'양산'   AND LEFT(model,2) <> N'VN';
		SELECT @DispAdjCassette = COALESCE(SUM(amt),0) FROM #DISPOSE WHERE LEFT(model,2) = N'VN';
		SELECT @DispAdjDev      = COALESCE(SUM(amt),0) FROM #DISPOSE WHERE 구분 = N'개발';

		/*==============================================================
		  (추가) 1-1) 변동비/고정비 프로시저 결과 받아오기 (세로형)
		==============================================================*/
		IF OBJECT_ID('tempdb..#VAR') IS NOT NULL DROP TABLE #VAR;
		IF OBJECT_ID('tempdb..#FIX') IS NOT NULL DROP TABLE #FIX;
		
		CREATE TABLE #VAR (
		  rn   INT,
		  gubun NVARCHAR(500) COLLATE DATABASE_DEFAULT,
		  구분  NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
		  model NVARCHAR(500) COLLATE DATABASE_DEFAULT,
		  amt  DECIMAL(18,2)
		);
		
		CREATE TABLE #FIX (
		  rn   INT,
		  gubun NVARCHAR(500) COLLATE DATABASE_DEFAULT,
		  구분  NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
		  model NVARCHAR(500) COLLATE DATABASE_DEFAULT,
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
        SELECT *
        INTO #RN
        FROM (
            -- I. 매출액
            SELECT  N'10' tree_id,     1 AS rn,        N'  I. 매출액'        AS gubun UNION ALL
            SELECT  N'10.01' tree_id,  2 AS rn,        N'    (1) 제품매출'    UNION ALL
            SELECT  N'10.02' tree_id,  3 AS rn,        N'        수량'       UNION ALL
 			SELECT  N'10.03' tree_id,  4 AS rn,        N'      단가'       UNION ALL
            SELECT  N'10.04' tree_id,  5 AS rn,        N'    (2) 유상사급'    UNION ALL
            SELECT  N'10.05' tree_id,  6 AS rn,        N'    (3) 상품매출'    UNION ALL
            SELECT  N'10.06' tree_id,  7 AS rn,        N'    (4) 기타매출'    UNION ALL

            -- II. 재료비
            SELECT  N'11' tree_id,     8 AS rn,        N'  II. 재료비'        UNION ALL
            SELECT  N'11.01' tree_id,  9 AS rn,        N'    (1) 원장'    UNION ALL
            SELECT  N'11.02' tree_id, 10 AS rn,        N'    (2) PF'          UNION ALL
  SELECT  N'11.03' tree_id, 11 AS rn,        N'    (3) 약액'        UNION ALL
            SELECT  N'11.04' tree_id, 12 AS rn,        N'    (4) 트레이'      UNION ALL
            SELECT  N'11.05' tree_id, 13 AS rn,        N'    (5) 더미글라스'  UNION ALL
            SELECT  N'11.06' tree_id, 14 AS rn,        N'    (6) 기타'        UNION ALL

            -- III~IV
            SELECT N'12' tree_id,     15 AS rn,        N'  III. 노무비'       UNION ALL            
            SELECT N'12.01' tree_id,  16 AS rn,        N'    (1) 제)임원급여'     UNION ALL
            SELECT N'12.02' tree_id,  17 AS rn,        N'    (2) 제)직원급여'     UNION ALL
            SELECT N'12.03' tree_id,  18 AS rn,        N'    (3) 제)상여금'       UNION ALL
            SELECT N'12.04' tree_id,  19 AS rn,        N'    (4) 제)제수당'       UNION ALL
            SELECT N'12.05' tree_id,  20 AS rn,        N'    (5) 제)퇴직급여'     UNION ALL
            SELECT N'12.06' tree_id,  21 AS rn,        N'    (6) 제)주식보상비용'   UNION ALL
            SELECT N'13' tree_id,     22 AS rn,        N'  IV. 제조경비'     	 UNION ALL
            SELECT N'13.01' tree_id,  23 AS rn,        N'    (1) 제)복리후생비'   UNION ALL
	        SELECT N'13.02' tree_id,  24 AS rn,        N'    (2) 제)여비교통비'  UNION ALL
            SELECT N'13.03' tree_id,  25 AS rn,        N'    (3) 제)통신비'    UNION ALL
            SELECT N'13.04' tree_id,  26 AS rn,        N'    (4) 제)수도광열비'  UNION ALL
            SELECT N'13.05' tree_id,  27 AS rn,        N'    (5) 제)전력비'     UNION ALL
            SELECT N'13.06' tree_id,  28 AS rn,        N'    (6) 제)세금과공과'   UNION ALL
            SELECT N'13.07' tree_id,  29 AS rn,        N'    (7) 제)감가상각비'   UNION ALL
            SELECT N'13.08' tree_id,  30 AS rn,        N'    (8) 제)지급임차료'   UNION ALL
            SELECT N'13.09' tree_id,  31 AS rn,        N'    (9) 제)수선비'     UNION ALL
            SELECT N'13.10' tree_id,  32 AS rn,        N'    (10) 제)보험료'    UNION ALL
            SELECT N'13.11' tree_id,  33 AS rn,        N'    (11) 제)차량유지비'  UNION ALL
	        SELECT N'13.12' tree_id,  34 AS rn,        N'    (12) 제)운반비'    UNION ALL
            SELECT N'13.13' tree_id,  35 AS rn,        N'    (13) 제)교육훈련비'  UNION ALL
            SELECT N'13.14' tree_id,  36 AS rn,  N'    (14) 제)도서인쇄비'  UNION ALL
            SELECT N'13.15' tree_id,  37 AS rn,        N'    (15) 제)소모품비'   UNION ALL
            SELECT N'13.16' tree_id,  38 AS rn,        N'    (16) 제)지급수수료'  UNION ALL
            SELECT N'13.17' tree_id,  39 AS rn,        N'    (17) 제)외주가공비'  UNION ALL
            SELECT N'13.18' tree_id,  40 AS rn,        N'    (18) 제)사용권자산감가상각비' UNION ALL
            SELECT N'13.19' tree_id,  41 AS rn,        N'    (19) 제)검사비' UNION ALL
            SELECT N'13.20' tree_id,  42 AS rn,        N'    (20) 제)견본비' UNION ALL
            SELECT N'13.21' tree_id,  43 AS rn,        N'    (21) 제)기타(RMA/생산X)' UNION ALL

            SELECT N'14' tree_id,     44 AS rn,        N'  V. 매출원가' UNION ALL
			SELECT N'14.01' AS tree_id, 45 AS rn, N'    (1) 제품매출원가' UNION ALL
			SELECT N'14.02' AS tree_id, 46 AS rn, N'    (2) 상품매출원가' UNION ALL
			SELECT N'14.03' AS tree_id, 47 AS rn, N'    (3) 제품매출원가조정' UNION ALL      

            -- V~X
--            SELECT N'15' tree_id, 45 AS rn,        N'  V. 재고조정'       UNION ALL
--            SELECT N'15.01' tree_id, 46 AS rn,       N'    상품매출원가' UNION ALL  */          
			SELECT N'16'    AS tree_id, 48 AS rn, N'  VI. 판관비' UNION ALL
			SELECT tree_id, rn, gubun FROM (
                SELECT N'16.' + RIGHT(N'0'+CAST(총원가_순서 AS varchar(2)),2) AS tree_id,
                       48 + 총원가_순서 AS rn,
                       N'    (' + CAST(총원가_순서 AS varchar(2)) + N') ' + 상위계정과목 AS gubun
                FROM (SELECT DISTINCT 상위계정과목, 총원가_순서 FROM doi_acct WITH(NOLOCK)
                      WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SELCODE
                        AND 대분류=N'판매관리비' AND 총원가_순서 IS NOT NULL) s
            ) sgna_tree /* [통일2026-08-18] 판관비 트리 하드코딩 28행 -> doi_acct 동적 */ UNION ALL
            SELECT N'17' 	AS tree_id, 77 AS rn, N'  VII. 총원가'       UNION ALL
            SELECT N'18' 	AS tree_id, 78 AS rn, N'  VIII. 영업이익'    UNION ALL
            SELECT N'18.01' AS tree_id, 79 AS rn, N'    영업이익률'  UNION ALL
            SELECT N'19' 	AS tree_id, 80 AS rn, N'  IX. 한계이익'   UNION ALL
            SELECT N'19.01' AS tree_id, 81 AS rn, N'    한계이익률'    UNION ALL
      SELECT N'20' 	AS tree_id, 82 AS rn, N'  X. 손익분기점'+ REPLICATE(NCHAR(0x3000), 5)
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
		SCOF_BASE AS (
		    /*SELECT
		          5 AS rn
		        , N'    (2) 유상사급' AS gubun
		        , N'총합계' AS 구분
		        , N'총합계' AS model
		        , CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2)) AS amt
		    FROM DOI_SCOF WITH(NOLOCK)
		    WHERE yyyymm  = @YYYYMM
		      AND site    = @SITE
              AND sel_code= @SELCODE*/
		
		    -- 상품매출원가
		    /*SELECT
		          5 AS rn
		        , N'    (2) 유상사급' AS gubun
		        , M.구분
		        , M.model
		        , CAST(COALESCE(XX.scof_amt,0) AS DECIMAL(18,2)) AS amt
		    FROM #MODEL M
		    LEFT JOIN (     
		    SELECT
              구분
            , 모델 AS model
            , SUM(COALESCE(매출상계,0)) AS scof_amt
        FROM DOI_원장상계
        WHERE 1=1
		  AND YYYYMM=@YYYYMM
		  AND COALESCE(매출상계,0) <> 0
		  --and NULLIF(모델,'') IS NOT NULL
        GROUP BY 구분, 모델*/
		SELECT
		     5 AS rn
		    , N'    (2) 유상사급' AS gubun
            , 구분
            , CASE WHEN 모델 = N'회계-조정' THEN 모델 ELSE LEFT(모델, LEN(모델)-1) END AS model
            , SUM(COALESCE(매출상계,0)) AS amt
        FROM DOI_원장상계
        WHERE 1=1
		  AND YYYYMM=@YYYYMM
		  AND COALESCE(매출상계,0) <> 0
		  GROUP BY 구분, CASE WHEN 모델 = N'회계-조정' THEN 모델 ELSE LEFT(모델, LEN(모델)-1) END
--    ) XX
--       ON XX.model = M.model
--      AND XX.구분 = M.구분
--		
		),
		SCOF_SUM AS (
		    SELECT
		          구분
		  , model
		        , SUM(amt) AS scof_amt
		    FROM SCOF_BASE
		    GROUP BY 구분, model
		),	        
       SALES_FACT AS (
            SELECT 1 rn, N'  I. 매출액'     AS gubun, 
            M.구분, M.model, 
            COALESCE(S.total_sale_amt,0) - COALESCE(SC.scof_amt,0) AS amt 
            FROM #MODEL M
            LEFT JOIN #SALES_BASE S ON S.model = M.model AND S.구분 = M.구분
            LEFT JOIN SCOF_SUM SC ON SC.model = M.model AND SC.구분 = M.구분
            UNION ALL
            SELECT 2 rn, N'    (1) 제품매출' AS gubun,
            M.구분, M.model, 
            S.prod_sale_amt AS amt 
            FROM #MODEL M
            LEFT JOIN #SALES_BASE S ON S.model = M.model AND S.구분 = M.구분           
   			UNION ALL
    		SELECT 6 rn, N'    (3) 상품매출'   AS gubun,
    		M.구분, M.model, 
    		S.merch_sale_amt  AS amt 
            FROM #MODEL M
            LEFT JOIN #SALES_BASE S ON S.model = M.model AND S.구분 = M.구분           
           ),
        QTY_BASE AS (
		    SELECT
		          CASE
                      WHEN MI.품번 IS NOT NULL THEN N'구매'     
		              WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		              WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		              ELSE N'개발'
		          END AS 구분
		        , A.품명 AS model
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
                A.품명
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
		        , A.품명 AS model
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
		        A.품명
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
		ETC_SALE_BASE AS (
			SELECT
                   구분, 
                   model,
    SUM(out_amt) AS adj_amt
            FROM doi_slco a WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM
              AND site   = @SITE
              AND sel_code = @SELCODE
              and EXPEN_SEL명 = N'기타매출'
            GROUP BY 구분, model
		),		
		MAT_BASE AS (
            SELECT
            	구분
                , model    
  				, acct_name
                , (out_amt - outetc_amt) AS amt --select distinct acct_name
   		FROM doi_stco WITH(NOLOCK)
       WHERE yyyymm = @YYYYMM
              AND site   = @SITE
              AND sel_code = @SELCODE
              and expen_sel IN('MDAX','MIAX')  --직접재료비, 간접재료비
              and out_amt != 0
        ),
        MAT_AGG AS (
            -- II.재료비 합계
            SELECT 8 rn, N'  II. 재료비' gubun, 구분, model, SUM(amt) amt
            FROM MAT_BASE
            GROUP BY 구분, model

            UNION ALL
            -- (1)원장
   			SELECT 9 rn, N'    (1) 원장', 구분, model, SUM(amt)
            FROM MAT_BASE
            WHERE acct_name = N'원장'
            GROUP BY 구분, model

            UNION ALL
            -- (2)PF (필름)
            SELECT 10 rn, N'    (2) PF', 구분, model, SUM(amt)
            FROM MAT_BASE
   			WHERE acct_name = N'PF'
            GROUP BY 구분, model

         	UNION ALL
            -- (3)약액
            SELECT 11 rn, N'    (3) 약액', 구분, model, SUM(amt)
            FROM MAT_BASE
            WHERE acct_name = N'약액'
            GROUP BY 구분, model

            UNION ALL
            -- (4)트레이
            SELECT 12 rn, N'    (4) 트레이', 구분, model, SUM(amt)
            FROM MAT_BASE
            WHERE acct_name = N'트레이'
            GROUP BY 구분, model

            UNION ALL
            -- (5)더미글라스
            SELECT 13 rn, N'    (5) 더미글라스', 구분, model, SUM(amt)
            FROM MAT_BASE
            WHERE acct_name = N'더미글라스'
            GROUP BY 구분, model

            UNION ALL
            -- (6)기타
  			SELECT 14 rn, N'    (6) 기타', 구분, model, SUM(amt)
            FROM MAT_BASE
       		WHERE acct_name = N'기타'
            GROUP BY 구분, model
          ),
        LABOR_BASE AS (
         SELECT 15+총원가_순서 rn, N'    ('+CAST(총원가_순서 as varchar(1))+') '+b.상위계정과목 as gubun, a.구분, a.model,
                   SUM(out_amt-outetc_amt) AS amt
            FROM doi_stco a WITH(NOLOCK)
            inner join doi_acct b on(a.yyyymm=b.yyyymm and a.site=b.site and a.acct_name=b.acct_name )
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
	    SELECT
	           22 + b.총원가_순서 AS rn,
	           N'    (' + CAST(b.총원가_순서 AS varchar(2)) + ') ' + b.상위계정과목 AS gubun,
	           a.구분,
	           a.model,
	           SUM(COALESCE(a.out_amt,0)) AS amt
	    FROM doi_stco a WITH(NOLOCK)
	    INNER JOIN doi_acct b
	      ON a.yyyymm = b.yyyymm
	     AND a.site = b.site
	     AND a.sel_code = b.sel_code
	     AND a.acct_name = b.acct_name
	    WHERE a.yyyymm = @YYYYMM
	      AND a.site = @SITE
	      AND a.sel_code = @SELCODE
	      AND b.상위계정과목 IN ('제)복리후생비','제)여비교통비','제)통신비','제)수도광열비','제)전력비','제)세금과공과','제)감가상각비','제)지급임차료','제)수선비','제)보험료','제)차량유지비','제)운반비','제)교육훈련비','제)도서인쇄비','제)소모품비','제)지급수수료','제)외주가공비','제)사용권자산감가상각비','제)검사비','제)견본비','제)기타(RMA/생산X)')
	      AND a.expen_sel NOT IN ('MHRB','MDAX','MIAX')
	      AND b.expen_sel NOT IN ('MHRB','MDAX','MIAX')
	    GROUP BY a.구분, a.model, b.상위계정과목, b.총원가_순서
	
	    UNION ALL
	
	    SELECT
	           43 AS rn,
	           N'    (21) 제)기타(RMA/생산X)' AS gubun,
	           a.구분,
	           a.model,
	           SUM(COALESCE(a.outetc_amt,0) * -1) AS amt
	    FROM doi_stco a WITH(NOLOCK)
	    INNER JOIN doi_acct b
	      ON a.yyyymm = b.yyyymm
	     AND a.site = b.site
	     AND a.sel_code = b.sel_code
	     AND a.acct_name = b.acct_name
	    WHERE a.yyyymm = @YYYYMM
	      AND a.site = @SITE
	      AND a.sel_code = @SELCODE
	      AND COALESCE(a.outetc_amt,0) <> 0
	      AND b.상위계정과목 IN ('제)복리후생비','제)여비교통비','제)통신비','제)수도광열비','제)전력비','제)세금과공과','제)감가상각비','제)지급임차료','제)수선비','제)보험료','제)차량유지비','제)운반비','제)교육훈련비','제)도서인쇄비','제)소모품비','제)지급수수료','제)외주가공비','제)사용권자산감가상각비','제)검사비','제)견본비','제)기타(RMA/생산X)')
	      AND a.expen_sel NOT IN ('MHRB','MDAX','MIAX')
	      AND b.expen_sel NOT IN ('MHRB','MDAX','MIAX')
	    GROUP BY a.구분, a.model
      /*UNION ALL
            SELECT 22 rn, N'  EXTRA' gubun, 구분, model, out_amt
             FROM doi_slco a WITH(NOLOCK)
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND a.model = 'EXTRA'
            UNION ALL
            SELECT 22 rn, N'  기타출고' gubun, 구분, model, out_amt
             FROM doi_stco a WITH(NOLOCK)
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND a.acct_name = '*'
              AND a.out_amt != 0*/
        ),
  EXP_AGG AS (
            SELECT 22 rn, N'  IV. 제조경비' gubun, 구분, model,
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
             AND R.품명 = M.model
            WHERE M.구분 = N'구매'
            GROUP BY M.구분, M.model
        ),
		LOSS_BY_MODEL AS (
		    SELECT
		          C.구분
		        , C.model
		        , CAST(SUM(COALESCE(C.LOSS,0)) AS DECIMAL(18,2)) AS loss_amt
		    FROM DOI_COST C WITH(NOLOCK)
		    WHERE C.YYYYMM   = @YYYYMM
		      AND C.SITE     = @SITE
		      AND C.SEL_CODE = @SELCODE
		    GROUP BY C.구분, C.model
		    HAVING SUM(COALESCE(C.LOSS,0)) <> 0
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
            -- V 매출원가 =  II.재료비 +  III.노무비 +  IV.제조경비
			SELECT 44 rn, N'  V. 매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(II.amt,0) + COALESCE(III.amt,0) + COALESCE(IV.amt,0) + COALESCE(XX.amt,0) + COALESCE(LB.loss_amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
   			LEFT JOIN #SALES_BASE SB ON SB.model = M.model AND SB.구분  = M.구분            
            LEFT JOIN (SELECT 구분, model, SUM(amt) amt FROM MAT_BASE GROUP BY 구분, model) II ON II.model = M.model AND II.구분 = M.구분 
            LEFT JOIN LABOR_AGG III ON III.model = M.model AND III.구분 = M.구분
            LEFT JOIN EXP_AGG    IV ON IV.model = M.model AND IV.구분 = M.구분
            LEFT JOIN MERCH_COGS XX ON XX.model = M.model AND XX.구분 = M.구분
    		LEFT JOIN LOSS_BY_MODEL LB ON LB.model = M.model AND LB.구분 = M.구분            
            ),
         PROD_COGS AS (
		    -- 제품매출원가 = 재료비 + 노무비 + 제조경비
		    SELECT
		          45 rn
		        , N'    (1) 제품매출원가' gubun
		        , M.구분
		        , M.model
		        , CAST(
		              COALESCE(II.amt,0)
		            + COALESCE(III.amt,0)
		            + COALESCE(IV.amt,0)
/*		            + COALESCE(EC.adj_amt,0)*/
		       AS DECIMAL(18,2)) AS amt
		    FROM #MODEL M
		    LEFT JOIN #SALES_BASE SB
            ON SB.model = M.model AND SB.구분  = M.구분    
		    LEFT JOIN (SELECT 구분, model, SUM(amt) amt FROM MAT_BASE GROUP BY 구분, model) II
		           ON II.model = M.model AND II.구분 = M.구분
		    LEFT JOIN LABOR_AGG III
		           ON III.model = M.model AND III.구분 = M.구분
		    LEFT JOIN EXP_AGG IV
		           ON IV.model = M.model AND IV.구분 = M.구분
/*		    LEFT JOIN ETC_SALE_BASE EC
		      ON EC.model = M.model AND EC.구분 = M.구분	*/	           
		),
		MERCH_COGS_FACT AS (
		    -- 상품매출원가
		    SELECT
		          46 rn
		        , N'    (2) 상품매출원가' gubun
		        , M.구분
		        , M.model
		        , CAST(COALESCE(XX.amt,0) AS DECIMAL(18,2)) AS amt
		    FROM #MODEL M
		    LEFT JOIN MERCH_COGS XX
		           ON XX.model = M.model AND XX.구분 = M.구분
		),
		LOSS_ADJ_BASE AS (
		    SELECT
		          47 AS rn
		        , N'    (3) 제품매출원가조정' AS gubun
		        , C.구분
		        , C.model
		        , CAST(SUM(COALESCE(C.LOSS,0)) AS DECIMAL(18,2)) AS amt
		    FROM DOI_COST C
		    WHERE C.YYYYMM   = @YYYYMM
		      AND C.SITE     = @SITE
		      AND C.SEL_CODE = @SELCODE
		    GROUP BY C.구분, C.model
    		HAVING SUM(COALESCE(C.LOSS,0)) <> 0		    
		),		
		DISPOSE_ADJ_BASE AS (
		    -- 제품 폐기를 모델별 (3)제품매출원가조정 에 반영
		    SELECT
		          47 AS rn
		        , N'    (3) 제품매출원가조정' AS gubun
		        , D.구분
		        , D.model
		        , D.amt
		    FROM #DISPOSE D
		),
		PROD_COGS_ADJ AS (
		    -- 제품매출원가조정: 총합계 전용이라 모델별 0
		    SELECT
		          47 AS rn
		        , N'    (3) 제품매출원가조정' AS gubun
		        , N'총합계' AS 구분
		        , N'총합계' AS model
	        	, CAST(@CostAdj + @LossAdj AS DECIMAL(18,2)) AS amt		    
		),      
--        ADJ_SALE AS (  --26-02-13 삭제
--            SELECT 45 rn, N'    매출원가조정' gubun, M.구분, M.model,
--                   COALESCE(E.amt,0) AS amt
--            FROM #MODEL M
--    LEFT JOIN ETC_SALE_BASE E ON E.model = M.model AND E.구분 = M.구분
--        ),
        
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
--		INV_ADJ AS (
--		    SELECT
--		          46 rn
--		        , N'  V. 재고조정' gubun
--		        , M.구분
--		        , M.model
--		        , CAST(
--		              (COALESCE(C.BOH,0) - COALESCE(C.EOH,0))
--		            + (COALESCE(S.BOH_AMT,0) - COALESCE(S.EOH_AMT,0))
--		            /*+ COALESCE(C.RMAIN_AMT,0)*/
--		        + COALESCE(S.INETC_AMT,0)
--		            - COALESCE(S.OUTETC_AMT,0)
--		          AS DECIMAL(18,2)) AS amt
--		    FROM #MODEL M
--		    LEFT JOIN COST_ADJ C
--		           ON C.YYYYMM = @YYYYMM
--		          AND C.SITE   = @SITE
--		          AND C.MODEL  = M.model
--		          AND C.구분    = M.구분
--		    LEFT JOIN STCO_ADJ S
--		           ON S.YYYYMM = @YYYYMM
--		          AND S.SITE   = @SITE
--		       AND S.MODEL  = M.model
--		          AND S.구분    = M.구분
--		),
    /* ====== VI 판관비 ====== */
		SGA_BASE AS (
			SELECT 48+m.총원가_순서 rn,
			       N'    ('+CAST(m.총원가_순서 as varchar(2))+') '+m.상위계정과목 as gubun,
			       a.구분,
			       a.model,
			       SUM(a.dist_amt) AS amt
			FROM doi_smce_cost a WITH(NOLOCK)
			CROSS APPLY (
			    SELECT TOP 1 b.상위계정과목, b.총원가_순서
			    FROM doi_acct b WITH(NOLOCK)
			    WHERE b.yyyymm=a.yyyymm AND b.site=a.site AND b.sel_code=a.sel_code
			      AND (b.acct_name = a.sub_name OR a.sub_name LIKE b.상위계정과목 + N'%')
			    ORDER BY CASE WHEN b.acct_name = a.sub_name THEN 0 ELSE 1 END, LEN(b.상위계정과목) DESC
			) m
			WHERE a.yyyymm = @YYYYMM
			  AND a.site   = @SITE
			  AND a.sel_code = @SELCODE
			  AND m.상위계정과목 LIKE N'판)%' AND m.총원가_순서 IS NOT NULL /* [통일2026-08-18] 28 IN-list 제거 */
			GROUP BY a.구분, a.model, m.상위계정과목, m.총원가_순서
		),
        SGA AS (
      	SELECT
                  48 rn
                , N'  VI. 판관비' gubun
                , CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE X.구분 END 구분
                , M.model
                , CAST(COALESCE(SUM(X.dist_amt),0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_SMCE_COST X WITH(NOLOCK)
            ON X.YYYYMM = @YYYYMM
                  AND X.SITE   = @SITE
                  AND X.SEL_CODE = @SELCODE
                  AND X.MODEL  = M.model
                  AND M.구분 = CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE X.구분 END
            GROUP BY CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE X.구분 END, M.model
        ),

        TOTAL_COST AS (
            -- VII 총원가 = 당기총제조원가 + 재고조정 + 판관비 + 매출원가조정
			SELECT 77 rn, N'  VII. 총원가' gubun, M.구분, M.model,
                   CAST(COALESCE(A.amt,0) /*+ COALESCE(V.amt,0)*/ + COALESCE(VI.amt,0) /*+ COALESCE(B.amt,0)*/ AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN TOTAL_MFG A ON A.model = M.model AND A.구분 = M.구분 
            --LEFT JOIN INV_ADJ V ON V.model = M.model AND V.구분 = M.구분
            LEFT JOIN SGA     VI ON VI.model = M.model AND VI.구분 = M.구분
            --LEFT JOIN ETC_SALE_BASE B ON B.model  = M.model AND B.구분 = M.구분
        ),
        OP_PROFIT AS (
            -- VIII 영업이익 = 매출액 - 총원가
            SELECT 78 rn, N'  VIII. 영업이익' gubun, M.구분, M.model,
                   CAST(COALESCE(SL.total_sale_amt,0) - COALESCE(TC.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN TOTAL_COST TC  ON TC.model = M.model AND TC.구분 = M.구분
        ),
        OP_MARGIN AS (
            -- VIII 영업이익률 = 영업이익 / 매출액
            SELECT 79 rn, N'    영업이익률' gubun, M.구분, M.model,
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
            SELECT
                  M.구분
                , M.model
                , CAST(COALESCE(SUM(F.amt),0) AS DECIMAL(18,2)) AS fix_amt
            FROM #MODEL M
            LEFT JOIN #FIX F
                   ON F.model = M.model
       AND F.구분 = M.구분
                  --AND F.rn    = 1 -- ✅ 고정비 합계 rn
            GROUP BY M.구분, M.model
        ),
        CM_PROFIT AS (
            -- IX. 한계이익 = 매출액 - 변동비
            SELECT
                  80 rn
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
                  81 rn
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
  				82 rn
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
        FACT AS (
            SELECT rn, gubun, 구분, model, amt FROM SALES_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM QTY_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM PRICE_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM SCOF_BASE
--    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM ETC_SALE_BASE    		    		
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM MAT_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM LABOR_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM LABOR_BASE  --26/02/13 KYH추가
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM EXP_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM EXP_BASE
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM TOTAL_MFG
		    UNION ALL SELECT rn, gubun, 구분, model, amt FROM PROD_COGS
		    UNION ALL SELECT rn, gubun, 구분, model, amt FROM MERCH_COGS_FACT
		    UNION ALL SELECT rn, gubun, 구분, model, amt FROM LOSS_ADJ_BASE
		    UNION ALL SELECT rn, gubun, 구분, model, amt FROM DISPOSE_ADJ_BASE
		    UNION ALL SELECT rn, gubun, 구분, model, amt FROM PROD_COGS_ADJ
--            UNION ALL SELECT rn, gubun, 구분, model, amt FROM ADJ_SALE
--  UNION ALL SELECT rn, gubun, 구분, model, amt FROM INV_ADJ  --26/02/13 KYH삭제
--            UNION ALL SELECT rn, gubun, 구분, model, amt FROM MERCH_COGS    --26/02/13 KYH삭제         
  UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA        
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA_BASE  --26/02/16 KYH추가
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
		-- 제품매출(rn=2) 합계 : 매출단가 = 제품매출/수량
		SELECT @SumYangsan_ProdSale = COALESCE(STRING_AGG(N'COALESCE(ProdSale.' + QUOTENAME(pivot_key) + N',0)', N' + ') WITHIN GROUP (ORDER BY sort_structure, model), N'0') FROM #MODEL WHERE 구분=N'양산' AND is_cassette=0;
		SELECT @SumDev_ProdSale = COALESCE(STRING_AGG(N'COALESCE(ProdSale.' + QUOTENAME(pivot_key) + N',0)', N' + ') WITHIN GROUP (ORDER BY sort_structure, model), N'0') FROM #MODEL WHERE 구분=N'개발' AND is_cassette=0;
		SELECT @SumCas_ProdSale = COALESCE(STRING_AGG(N'COALESCE(ProdSale.' + QUOTENAME(pivot_key) + N',0)', N' + ') WITHIN GROUP (ORDER BY sort_structure, model), N'0') FROM #MODEL WHERE 구분=N'카세트' OR is_cassette=1;
		SELECT @SumPur_ProdSale = COALESCE(STRING_AGG(N'COALESCE(ProdSale.' + QUOTENAME(pivot_key) + N',0)', N' + ') WITHIN GROUP (ORDER BY sort_structure, model), N'0') FROM #MODEL WHERE 구분=N'구매';
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
					      ((' + @SumYangsan_ProdSale + ')+(' + @SumDev_ProdSale + ')+(' + @SumCas_ProdSale + ')+(' + @SumPur_ProdSale + '))
					      / NULLIF(((' + @SumYangsan_Qty + ')+(' + @SumDev_Qty + ')+(' + @SumCas_Qty + ')+(' + @SumPur_Qty + ')),0)
            		  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumYangsan_Op + ')+(' + @SumDev_Op + ')+(' + @SumCas_Op + ')+(' + @SumPur_Op +'))
					      /NULLIF(((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ')),0)*100
       			  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
						  ('+@SumYangsan_FiX + ' + ' + @SumDev_Fix +')
					      /NULLIF(((' + @SumYangsan_Bep + ')+(' + @SumDev_Bep + ')+(' + @SumCas_Bep + ')+(' + @SumPur_Bep +')),0)*100
					       --/NULLIF(((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ')),0)*100
					WHEN Cur.rn = 1 THEN
					    ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + ') + @ACC_TOTAL ) /* [수정]2026-08-18 총합계매출액=양산+개발+카세트+구매+회계(@ACC_TOTAL): 구매누락·유상사급중복 제거 */

					WHEN Cur.rn = 2 THEN
					    ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ') + (@ACC_IDLE_COMP))   -- [규칙1] 제품매출(조정은 매출액으로 이동): 양산+개발+카세트+회계(비가동+조정)
					WHEN Cur.rn = 3 THEN
					    ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + '))   -- [수정]2026-08-18 수량 총합계 구매 포함

					WHEN Cur.rn = 6 THEN (' + @SumPurchase + ')

					WHEN Cur.rn = 7 THEN @ACC_PREV_PRICE   -- 기타매출 총합계: 이전가격만

					WHEN Cur.rn = 44 THEN
					    ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + ')) + ( @CostAdj /*+ @LossAdj*/ ) + @DispAdj
					
					WHEN Cur.rn = 47 THEN
					    @CostAdj + @LossAdj + @DispAdj
					
					WHEN Cur.rn = 77 THEN
					  ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + ')) + ( @CostAdj ) + @DispAdj
					
					WHEN Cur.rn = 78 THEN
					    /*(
					      ((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ') + @ACC_TOTAL)
					      - @SCOF
					    )
					    -*/
					    (
					      ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + ') - @SCOF + (@ACC_TOTAL - @ACC_ADJ) )
					     -- + ( @CostAdj )
					    )
					ELSE
					    ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + '))
					END		      
					AS DECIMAL(18,2)) AS [총합계]
		
		    -- ✅ 양산/개발/카세트 합계: 유상사급은 0으로
		    , CAST(
				CASE
				 -- WHEN Cur.rn = 5 and '+ @YYYYMM + '>= ''202604'' THEN @SCOF 
				  WHEN Cur.rn = 4 THEN ((' + @SumYangsan_ProdSale + ') / NULLIF((' + @SumYangsan_Qty + '),0))
           	  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumYangsan_Op  +'))
					      /NULLIF(((' + @SumYangsan_Sale + ')),0)*100
         		  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
					  ('+@SumYangsan_FiX +')
				      /NULLIF(((' + @SumYangsan_Bep +')),0)*100
		      WHEN Cur.rn = 44 THEN
		          ((' + @SumYangsan + ')) + @LossAdjYangsan + @DispAdjYangsan
		
		      WHEN Cur.rn = 47 THEN
		          @LossAdjYangsan + @DispAdjYangsan
		
		      WHEN Cur.rn = 77 THEN
		   ((' + @SumYangsan + ')) + @DispAdjYangsan
		
		      WHEN Cur.rn = 78 THEN
		          /*((' + @SumYangsan_Sale + '))
		          -*/
		          ((' + @SumYangsan + '))

				  ELSE (' + @SumYangsan + ')
				END AS DECIMAL(18,2)) AS [양산합계]
			, CAST(
				CASE
				  --WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumDev_ProdSale + ') / NULLIF((' + @SumDev_Qty + '),0))
            	  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumDev_Op +'))
					      /NULLIF(((' + @SumDev_Sale + ')),0)*100
          		  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
					  ('+ @SumDev_Fix +')
				      /NULLIF(((' + @SumDev_Bep +')),0)*100

			      WHEN Cur.rn = 44 THEN
			          ((' + @SumDev + ')) + @LossAdjDev + @DispAdjDev
			
			      WHEN Cur.rn = 47 THEN
			          @LossAdjDev + @DispAdjDev
			
			      WHEN Cur.rn = 77 THEN
			          ((' + @SumDev + ')) + @DispAdjDev
			
			      WHEN Cur.rn = 78 THEN
			          /*((' + @SumDev_Sale + '))
			          -*/
			          ((' + @SumDev + '))

				  ELSE (' + @SumDev + ')
				END AS DECIMAL(18,2)) AS [개발합계]
			, CAST(	
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumCas_ProdSale + ') / NULLIF((' + @SumCas_Qty + '),0))
				  WHEN Cur.rn = 44 THEN ((' + @SumCassette + ')) + @LossAdjCassette + @DispAdjCassette
				  WHEN Cur.rn = 47 THEN @LossAdjCassette + @DispAdjCassette
				  ELSE (' + @SumCassette + ')
				END AS DECIMAL(18,2)) AS [카세트합계]

            , CAST( 
                CASE
                  WHEN Cur.rn = 5 THEN 0
                  WHEN Cur.rn = 4 THEN ((' + @SumPur_ProdSale + ') / NULLIF((' + @SumPur_Qty + '),0))
                  ELSE (' + @SumPurchase + ')
                END AS DECIMAL(18,2)) AS [구매합계]
		
		    -- 요청: 상품/기타매출은 NULL
		    , CAST(NULL AS DECIMAL(18,2)) AS [상품매출]
		    , CAST(
			    CASE
			        WHEN Cur.rn = 7 THEN @ACC_TOTAL
			        ELSE NULL
			    END
			  AS DECIMAL(18,2)) AS [기타매출]

			-- 회계
			, CAST(
			    CASE
			        WHEN Cur.rn = 2 THEN (@ACC_IDLE_COMP)  -- 제품매출: 비가동보상 (조정은 매출액으로 이동)
			        WHEN Cur.rn = 7 THEN @ACC_PREV_PRICE              -- 기타매출: 이전가격
			        WHEN Cur.rn = 1 THEN @ACC_TOTAL
			        -- 재고폐기는 매출원가 가산 → 총원가(77) 증가, 영업이익(78) 감소
			        WHEN Cur.rn = 78 THEN @ACC_TOTAL - @ACC_SCRAP
			        WHEN Cur.rn IN (44,47,77) THEN @ACC_SCRAP
			        WHEN Cur.rn = 5 THEN @SCOF_ACC   -- 유상사급 란: 회계-조정 유상사급
			        ELSE 0
			    END
			  AS DECIMAL(18,2)) AS [회계합계]
			
			-- 회계-제품-비가동보상 : 매출액(rn=1) 합계 + 제품매출 행(rn=2)
			, CAST(
			    CASE
			        WHEN Cur.rn IN (1,2) THEN @ACC_IDLE_COMP
			        ELSE 0
			    END
			  AS DECIMAL(18,2)) AS [회계_비가동보상]

			-- 회계-제품-조정 : 매출액(rn=1) 합계 + 제품매출 행(rn=2)
			, CAST(
			    CASE
			        WHEN Cur.rn = 1 THEN @ACC_ADJ   -- 매출액 = 제품매출 - 유상사급 (= -유상사급)
			        WHEN Cur.rn = 5 THEN @SCOF_ACC   -- 유상사급 란
			        ELSE 0
			    END
			  AS DECIMAL(18,2)) AS [회계_조정]

			-- 회계-기타-이전가격 : 매출액(rn=1) 합계 + 기타매출 행(rn=7)
			, CAST(
			    CASE
			        WHEN Cur.rn IN (1,7) THEN @ACC_PREV_PRICE
			        -- 원부재료 재고폐기: (3)제품매출원가조정(47) 및 상위 V.매출원가(44)
			        WHEN Cur.rn IN (44,47) THEN @ACC_SCRAP
			        ELSE 0
			    END
			  AS DECIMAL(18,2)) AS [회계_이전가격]
		    , ' + @ModelSelectCols + N'

		FROM P Cur
		LEFT JOIN P Sales ON Sales.rn = 1
		LEFT JOIN P ProdSale ON ProdSale.rn = 2 
		LEFT JOIN P Qty   ON Qty.rn = 3
    	LEFT JOIN P Op    ON LTRIM(Op.gubun) = N''VIII. 영업이익''
    	LEFT JOIN P Bep   ON LTRIM(Bep.gubun) LIKE N''X. 손익분기점%''
		ORDER BY TRY_CONVERT(INT, Cur.rn);
		';
		
--		SELECT @SQL;
		EXEC sp_executesql @SQL, 
		N'@SCOF DECIMAL(18,2), @CostAdj DECIMAL(18,2), @LossAdj DECIMAL(18,2), @LossAdjYangsan DECIMAL(18,2), @LossAdjDev DECIMAL(18,2), @LossAdjCassette DECIMAL(18,2) ,@ACC_TOTAL decimal(18,2), @ACC_PREV_PRICE decimal(18,2), @ACC_IDLE_COMP decimal(18,2), @ACC_ADJ decimal(18,2), @SCOF_ACC decimal(18,2), @ACC_SCRAP decimal(18,2), @DispAdj decimal(18,2), @DispAdjYangsan decimal(18,2), @DispAdjDev decimal(18,2), @DispAdjCassette decimal(18,2)',
		@SCOF = @SCOFTotal,
    	@CostAdj = @CostAdj,
    	@LossAdj = @LossAdj,
        @LossAdjYangsan = @LossAdjYangsan,
   		@LossAdjDev     = @LossAdjDev,
        @LossAdjCassette = @LossAdjCassette,
		@ACC_TOTAL      = @ACC_TOTAL,
		@ACC_PREV_PRICE = @ACC_PREV_PRICE,
		@ACC_IDLE_COMP  = @ACC_IDLE_COMP,
		@ACC_ADJ        = @ACC_ADJ,
		@SCOF_ACC       = @SCOF_ACC,
		@ACC_SCRAP      = @ACC_SCRAP,
		@DispAdj        = @DispAdj,
		@DispAdjYangsan = @DispAdjYangsan,
		@DispAdjDev     = @DispAdjDev,
		@DispAdjCassette= @DispAdjCassette;

        DROP TABLE #BASE;
        DROP TABLE #RN;
        DROP TABLE #MODEL;
    DROP TABLE #SALES_BASE;
        DROP TABLE #VAR;
        DROP TABLE #FIX;       

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT 
         ERROR_NUMBER()  AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE()   AS ErrorState,
        ERROR_LINE() AS ErrorLine,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_MESSAGE() AS ErrorMessage;
       
    THROW;   
    END CATCH
END;
GO
