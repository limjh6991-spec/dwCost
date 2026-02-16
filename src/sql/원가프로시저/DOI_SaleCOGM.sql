CREATE         PROCEDURE DOI_SaleCOGM
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
            SELECT DISTINCT
                  S.SITE AS SITE
                , S.MODEL AS 모델
                , S.구분
                , S.Local구분
                , S.판매단위
                , S.거래처
                , CASE 
                      WHEN LEFT(S.MODEL, 1) = 'I' THEN 'ITG'
                      WHEN LEFT(S.MODEL, 1) = 'H' THEN 'HTG'
                      WHEN LEFT(S.MODEL, 1) = 'C' THEN 'Coated'
                      ELSE 'UTG'
                  END AS 제품구조  --select *
            FROM DOI_SLCO S WITH(NOLOCK)
            WHERE SUBSTRING(S.YYYYMM, 1, 4) = @YYYY
              AND S.SITE 	 = @SITE
              AND S.SEL_CODE = @SEL_CODE
	      	  AND S.expen_sel명 != N'기타매출'
        )
        SELECT *
        INTO #MODEL_BASE
        FROM MODEL_BASE;


        ----------------------------------------------------------------------
        -- 3. STCO 집계
        ----------------------------------------------------------------------
        ;WITH SLCO_AGG AS (
            SELECT
                  YYYYMM, SITE, MODEL, 구분, Local구분, 판매단위, 거래처
                , AVG(OUT_QTY)     AS OUT_QTY
                , SUM(OUT_AMT) AS OUT_AMT --select *
            FROM DOI_SLCO WITH(NOLOCK)
            WHERE SUBSTRING(YYYYMM,1,4)=@YYYY
              AND SITE		= @SITE
              AND SEL_CODE  = @SEL_CODE
	      	  AND expen_sel명 != N'기타매출'
            GROUP BY YYYYMM, SITE, MODEL, 구분, Local구분, 판매단위, 거래처
        )
        SELECT *
        INTO #SLCO_AGG
        FROM SLCO_AGG;
      

        ----------------------------------------------------------------------
        -- 4. 최종 결과
        ----------------------------------------------------------------------
        SELECT
              M.구분
            , M.모델
            , M.Local구분
            , M.판매단위
            , M.거래처
            , CAST(G.월번호 AS VARCHAR(2)) + '월' AS 월

            , SA.OUT_QTY, SA.OUT_AMT
        FROM #MODEL_BASE M
        CROSS JOIN #GEN_YYYYMM G
        INNER JOIN #SLCO_AGG SA
               ON SA.YYYYMM = G.YYYYMM
              AND SA.SITE   = M.SITE
              AND SA.MODEL  = M.모델
              AND SA.구분 = M.구분
              AND SA.Local구분 = M.Local구분
              AND SA.판매단위 = M.판매단위
			  AND SA.거래처 = M.거래처
        ORDER BY CASE WHEN M.구분 = '양산' THEN 1 ELSE 2 END, M.구분, M.모델, M.Local구분, M.판매단위, M.거래처, G.월번호;


        ----------------------------------------------------------------------
        -- 5. 임시테이블 삭제
        ----------------------------------------------------------------------
        DROP TABLE #GEN_YYYYMM;
        DROP TABLE #MODEL_BASE;
        DROP TABLE #SLCO_AGG;

    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
