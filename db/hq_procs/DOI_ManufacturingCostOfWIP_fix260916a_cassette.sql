/* ============================================================
   DOI_ManufacturingCostOfWIP fix260916a — 제조원가(재공) 카세트 구분 신설
   근거: 「KR 로직 문의 (2).xlsx」 확인요청 6번 / 시트 '6.제조원가(재공)'
         변경 전 구분='양산'(VN034P1~P3) → 변경 후 구분='카세트'
   방식: 리포트 SELECT 전용 재분류(LEFT(MODEL,2)='VN'). 결산 테이블 불변, 재결산·jar 재빌드 불필요.
         집계 조인은 원본 구분(DOI_COST.구분) 그대로 사용하고 출력 구분만 재매핑한다.
   기준: db/hq_procs/DOI_ManufacturingCostOfWIP_fix260915.sql (2026-09-16 운영 정의와 동일 확인)
   검증: 2026-09-16 애드혹 읽기전용 실행(2026 HQ ACTUAL) — 336행 그대로,
         VN034P1~P3 의 7·8월 6행만 양산→카세트, 나머지 값 변화 0건, 정렬 개발→양산→카세트.
   ============================================================ */
-- [2026-09-16a] 카세트 구분 신설: 출력 구분 = LEFT(MODEL,2)='VN' → N'카세트', 그 외 원본 구분 유지.
--   #COST_AGG 조인/집계는 원본 구분 그대로라 금액 총액 불변. 정렬 개발→양산→카세트.
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
              CASE WHEN LEFT(SA.MODEL,2) = N'VN' THEN N'카세트' ELSE SA.구분 END AS 구분   -- [2026-09-16a] 카세트(VN034P*) 대분류 분리
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
        ORDER BY CASE WHEN LEFT(SA.MODEL,2) = N'VN' THEN 3 WHEN SA.구분 = N'개발' THEN 1 WHEN SA.구분 = N'양산' THEN 2 ELSE 4 END   -- [2026-09-16a] 개발→양산→카세트 순
               , SA.구분, M.모델, G.월번호;


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