CREATE       PROCEDURE DOI_VariableCostByModel
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4),
    @SELCODE VARCHAR(10) 
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* =============================
           1) 모델 마스터 (구분+모델)
        ============================= */
		SELECT acct_name
		INTO #ACCT_MFG
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'AA' AND 원가구분 = '변동비';

		SELECT acct_name
		INTO #ACCT_SGA
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'CC' AND 원가구분 = '변동비';		 
       
        ;WITH M AS (
            SELECT 구분, 도우모델 AS model
            FROM doi_mat_cost WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE

            UNION
            SELECT 구분, model
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE
            
            UNION
            SELECT 구분, model
            FROM doi_smce_cost WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE          
        )
        SELECT
              구분
            , model
            , (CASE WHEN 구분 IN (N'카세트') THEN N'카세트'
                    WHEN 구분 IN (N'개발')   THEN N'개발'
                    ELSE N'양산' END) + model AS pivot_key
            , CASE WHEN 구분 IN (N'양산') THEN 1
                   WHEN 구분 IN (N'개발') THEN 2
                   WHEN 구분 IN (N'카세트') THEN 3
                   ELSE 9 END AS sort_group
            , CASE
                  WHEN LEFT(model,1)='I' THEN 1
                  WHEN LEFT(model,1)='H' THEN 2
                  WHEN LEFT(model,1)='C' THEN 3
                  ELSE 4
              END AS sort_model
        INTO #MODEL
        FROM M;

        /* =============================
           2) RN (행 정의)
        ============================= */
        SELECT *
        INTO #RN
        FROM (
            SELECT  1 rn, N'  변동비'            gubun UNION ALL
            SELECT  2,    N'    원재료비'        UNION ALL
            SELECT  3,    N'    부재료비'        UNION ALL
            SELECT  4,    N'    제)직원급여'     UNION ALL
            SELECT  5,    N'    제)상여금'       UNION ALL
            SELECT  6,    N'    제)제수당'       UNION ALL
            SELECT  7,    N'    제)퇴직급여'     UNION ALL
            SELECT  8,    N'    제)수도광열비'   UNION ALL
            SELECT  9,    N'    제)전력비'       UNION ALL
            SELECT 10,    N'    제)세금과공과'   UNION ALL
            SELECT 11,    N'    제)운반비'       UNION ALL
            SELECT 12,    N'    제)소모품비'     UNION ALL
            SELECT 13,    N'    제)지급수수료'   UNION ALL
            SELECT 14,    N'    제)외주가공비'   UNION ALL
            SELECT 15,    N'    판)운반비'       
        ) A;

        /* =============================
           3) FACT 집계 (구분+model 단위)
        ============================= */
        ;WITH /*MAT AS ( --2026-02-13 kyh 삭제
            SELECT
                  구분
                , 도우모델 AS model
                , mat_class
                , 자재대분류
                , COALESCE(자재대분류,'') AS 자재대분류2
                , CAST(배부금액 AS DECIMAL(18,2)) AS amt
            FROM doi_mat_cost WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SELCODE
        ),*/
        VC_FACT AS (
            -- 변동비 합계
            SELECT 1 rn, N'  변동비' gubun, 구분, model,
                   CAST(
                       COALESCE(SUM(CASE WHEN 1=1 THEN amt END),0)
                   AS DECIMAL(18,2)) AS amt
            FROM (
                -- 재료비(원+부)
                --SELECT 구분, model, amt FROM MAT  --2026-02-13 kyh 삭제
            	SELECT 구분, model, CAST(out_amt AS DECIMAL(18,2)) amt
                FROM doi_stco WITH(NOLOCK)
                WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code = @SELCODE and expen_sel in ('MDAX','MIAX')
                UNION ALL
                -- 제조변동(아래 항목들)
                SELECT 구분, model, CAST(out_amt AS DECIMAL(18,2)) amt
                FROM doi_stco WITH(NOLOCK)
                WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code = @SELCODE
                  AND acct_name IN (SELECT acct_name FROM #ACCT_MFG
                  )
                UNION ALL
                -- 판)운반비
                SELECT 구분, model, CAST(dist_amt AS DECIMAL(18,2)) amt
                FROM doi_smce_cost WITH(NOLOCK)
                WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code = @SELCODE
                  AND sub_name IN (SELECT acct_name FROM #ACCT_SGA)
            ) X
            GROUP BY 구분, model

            /*UNION ALL  --2026-02-13 kyh 삭제
            -- 원재료비
            SELECT 2 rn, N'    원재료비', 구분, model, SUM(amt)
            FROM MAT
            WHERE mat_class = N'원자재' AND 자재대분류 = N'원자재'
            GROUP BY 구분, model

            UNION ALL
            -- 부재료비(= 원재료비 제외한 재료비 전부)
            SELECT 3 rn, N'    부재료비', 구분, model, SUM(amt)
            FROM MAT
            WHERE NOT (mat_class = N'원자재' AND 자재대분류 = N'원자재')
            GROUP BY 구분, model

            UNION ALL
            SELECT 4 rn, N'    제)직원급여', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name = N'제)급여-직원' AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 5 rn, N'    제)상여금', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name = N'제)상여금-직원' AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 6 rn, N'    제)제수당', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)제수당-연차', N'제)제수당-일반')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 7 rn, N'    제)퇴직급여', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)퇴직급여-임원', N'제)퇴직급여-직원')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 8 rn, N'    제)수도광열비', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)수도광열비-수도료', N'제)수도광열비-연료비')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 9 rn, N'    제)전력비', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name = N'제)전력비'
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 10 rn, N'    제)세금과공과', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)세금과공과-연금보험', N'제)세금과공과-일반')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 11 rn, N'    제)운반비', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)운반비-국내운송료', N'제)운반비-해외운송료')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 12 rn, N'    제)소모품비', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)소모품비-비품', N'제)소모품비-사무용품', N'제)소모품비-일반')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 13 rn, N'    제)지급수수료', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
     FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name IN (N'제)지급수수료-유지보수료', N'제)지급수수료-검사.측정료', N'제)지급수수료-일반')
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 14 rn, N'    제)외주가공비', 구분, model, SUM(CAST(out_amt AS DECIMAL(18,2)))
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_name = N'제)외주가공비'
             AND sel_code = @SELCODE
            GROUP BY 구분, model

            UNION ALL
            SELECT 15 rn, N'    판)운반비', 구분, model, SUM(CAST(dist_amt AS DECIMAL(18,2)))
            FROM doi_smce_cost WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND sub_name LIKE N'판)운반비%' AND sel_code = @SELCODE
            GROUP BY 구분, model*/
        ),
        BASE AS (
            SELECT
                  R.rn
                , R.gubun
                , M.구분
                , M.model
                , M.pivot_key
                , COALESCE(F.amt, 0) AS amt
            FROM #RN R
            CROSS JOIN #MODEL M
            LEFT JOIN VC_FACT F
                   ON F.rn = R.rn
                  AND F.gubun = R.gubun
                  AND F.구분 = M.구분
                  AND F.model = M.model
        )
        SELECT rn, gubun, 구분, model, pivot_key, amt
        INTO #BASE
        FROM BASE;

        /* =============================
           4) 결과
        ============================= */
		SELECT
		      rn
		    , gubun
		    , 구분
		    , model
		    , amt
		FROM #BASE
		ORDER BY
		      rn
		    , CASE
		          WHEN 구분 = N'양산' THEN 1
		          WHEN 구분 = N'개발' THEN 2
		          WHEN 구분 = N'카세트' THEN 3
		          ELSE 9
		      END
		    , model;
       
        DROP TABLE #BASE;
        DROP TABLE #RN;
        DROP TABLE #MODEL;
        DROP TABLE #ACCT_MFG;
        DROP TABLE #ACCT_SGA;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
