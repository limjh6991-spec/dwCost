CREATE   PROCEDURE DOI_FixedCostByModel
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

        /*==============================================================
          0) #MODEL : 고정비가 존재하는 (구분, model)만 추출
              - doi_expen_matl : 제조 고정비
              - doi_smce_cost  : 판관/영업외/법인세 고정비
        ==============================================================*/
		SELECT acct_name
		INTO #ACCT_MFG
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'AA' AND 원가구분 = '고정비';
		
		SELECT acct_name
		INTO #ACCT_SGA
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'CC' AND 원가구분 = '고정비';

		;WITH MODEL_SRC AS (
			SELECT DISTINCT
		           A.구분,
		           A.model
		    FROM doi_stco A WITH(NOLOCK)
		    WHERE A.yyyymm = @YYYYMM
		      AND A.site   = @SITE
		      AND A.sel_code = @SELCODE
		      AND A.acct_name IN (SELECT acct_name FROM #ACCT_MFG)
		
		    UNION
		
		    SELECT DISTINCT
		           S.구분,
		           S.model
		    FROM doi_smce_cost S WITH(NOLOCK)
		    WHERE S.yyyymm = @YYYYMM
		      AND S.site   = @SITE
		      AND S.sel_code = @SELCODE
		      AND S.sub_name IN (SELECT acct_name FROM #ACCT_SGA)
		),
        MODEL_BASE AS (
            SELECT
                  M.model
                , M.구분
                , CASE
                      WHEN M.구분 = N'카세트' THEN N'카세트'
                      WHEN LEFT(M.model, 1) = 'I' THEN 'ITG'
                      WHEN LEFT(M.model, 1) = 'H' THEN 'HTG'
                      WHEN LEFT(M.model, 1) = 'C' THEN 'Coated'
                  ELSE 'UTG'
                  END AS 제품구조
                , CASE
                      WHEN M.구분 = N'카세트' THEN 1
                      WHEN LEFT(M.model, 2) = 'VN' THEN 1  -- 안전장치
                      ELSE 0
                  END AS is_cassette
            FROM MODEL_SRC M
        )
        SELECT
              model
            , 구분
            , 제품구조
            , is_cassette
            , CASE
                  WHEN 구분 = N'카세트' OR is_cassette = 1 THEN 3
                  WHEN 구분 = N'양산' THEN 1
                  WHEN 구분 = N'개발' THEN 2
                  ELSE 9
              END AS sort_group
            , CASE 제품구조
      WHEN 'UTG' THEN 1
                  WHEN 'ITG' THEN 2
                  WHEN 'HTG' THEN 3
      WHEN 'Coated' THEN 4
                  WHEN N'카세트' THEN 9
                  ELSE 9
              END AS sort_structure
        INTO #MODEL
        FROM MODEL_BASE;

        /*==============================================================
          1) #RN : 고정비 라인(표시용)
        ==============================================================*/
        SELECT *
        INTO #RN
        FROM (
            SELECT  1 rn, N'  고정비(합계)'                 gubun UNION ALL

            -- 제조 고정비
            SELECT 2 rn, N'  제조고정비(합계)'             UNION ALL
            SELECT 3 rn, N'    제)임원급여'                UNION ALL
            SELECT 4 rn, N'    제)주식보상비용'            UNION ALL
            SELECT 5 rn, N'    제)복리후생비'              UNION ALL
            SELECT 6 rn, N'    제)여비교통비'              UNION ALL
            SELECT 7 rn, N'    제)통신비'                  UNION ALL
            SELECT 8 rn, N'    제)감가상각비'              UNION ALL
            SELECT 9 rn, N'    제)지급임차료'              UNION ALL
            SELECT 10 rn, N'    제)수선비'                  UNION ALL
            SELECT 11 rn, N'    제)보험료'                  UNION ALL
            SELECT 12 rn, N'    제)차량유지비'              UNION ALL
            SELECT 13 rn, N'    제)교육훈련비'              UNION ALL
            SELECT 14 rn, N'    제)도서인쇄비'              UNION ALL
            SELECT 15 rn, N'    제)사용권자산감가상각비'    UNION ALL
            SELECT 16 rn, N'    제)검사비'                  UNION ALL
            SELECT 17 rn, N'    제)견본비'                  UNION ALL

            -- 판관 고정비
            SELECT 18 rn, N'  판관고정비(합계)'             UNION ALL
            SELECT 19 rn, N'    판)임원급여'                UNION ALL
            SELECT 20 rn, N'    판)직원급여'                UNION ALL
            SELECT 21 rn, N'    판)상여금'                  UNION ALL
            SELECT 22 rn, N'    판)제수당'                  UNION ALL
            SELECT 23 rn, N'    판)퇴직급여'                UNION ALL
            SELECT 24 rn, N'    판)복리후생비'              UNION ALL
            SELECT 25 rn, N'    판)여비교통비'              UNION ALL
            SELECT 26 rn, N'    판)접대비'                  UNION ALL
            SELECT 27 rn, N'    판)통신비'                  UNION ALL
            SELECT 28 rn, N'    판)수도광열비'              UNION ALL
            SELECT 29 rn, N'    판)세금과공과'              UNION ALL
            SELECT 30 rn, N'    판)감가상각비'              UNION ALL
            SELECT 31 rn, N'    판)지급임차료'              UNION ALL
            SELECT 32 rn, N'    판)수선비'                  UNION ALL
            SELECT 33 rn, N'    판)보험료'                  UNION ALL
            SELECT 34 rn, N'    판)차량유지비'              UNION ALL
            SELECT 35 rn, N'    판)경상연구개발비'          UNION ALL
            SELECT 36 rn, N'    판)교육훈련비'              UNION ALL
            SELECT 37 rn, N'    판)도서인쇄비'              UNION ALL
            SELECT 38 rn, N'    판)소모품비'                UNION ALL
            SELECT 39 rn, N'    판)지급수수료'              UNION ALL
            SELECT 40 rn, N'    판)광고선전비'              UNION ALL
            SELECT 41 rn, N'    판)무형자산상각비'          UNION ALL
            SELECT 42 rn, N'    판)견본비'                  UNION ALL
            SELECT 43 rn, N'    판)사용권자산감가상각비'    UNION ALL
            SELECT 44 rn, N'    판)주식보상비용'            UNION ALL
            SELECT 45 rn, N'    판)해외시장개척비'          UNION ALL

            -- 영업외/법인세
            SELECT 46 rn, N'  영업외/법인세(합계)'          UNION ALL
            SELECT 47 rn, N'    이자수익'                   UNION ALL
            SELECT 48 rn, N'    수입임대료'                 UNION ALL
            SELECT 49 rn, N'    외환차익'                   UNION ALL
            SELECT 50 rn, N'    외화환산이익'               UNION ALL
            SELECT 51 rn, N'    유형자산처분이익'           UNION ALL
            SELECT 52 rn, N'    당기손익인식금융자산'       UNION ALL
            SELECT 53 rn, N'    잡이익'                     UNION ALL
            SELECT 54 rn, N'    이자비용'                   UNION ALL
			SELECT 55 rn, N'    외환차손'                   UNION ALL
            SELECT 56 rn, N'    외화환산손실'               UNION ALL
            SELECT 57 rn, N'    유형자산처분손실'           UNION ALL
            SELECT 58 rn, N'    잡손실'                     UNION ALL
            SELECT 59 rn, N'    영업외지급수수료'           UNION ALL
            SELECT 60 rn, N'    법인세비용'
        ) R;

        /*==============================================================
          2) FACT : (rn, gubun, 구분, model, amt)
        ==============================================================*/
		;WITH A0 AS (
		    SELECT
		        A.구분,
		        A.model,
		        A.acct_name,
		        CAST(A.out_amt AS DECIMAL(18,2)) AS amt
		    FROM doi_stco A WITH(NOLOCK)
		    WHERE A.yyyymm=@YYYYMM AND A.site=@SITE AND A.sel_code=@SELCODE
		      AND A.acct_name IN (SELECT acct_name FROM #ACCT_MFG)
		),
		MFG_FIXED AS (
		    SELECT
		        CASE AC.상위계정과목
		            WHEN N'제)임원급여'             THEN 3
		 WHEN N'제)주식보상비용'          THEN 4
		            WHEN N'제)복리후생비'            THEN 5
		            WHEN N'제)여비교통비'            THEN 6
		            WHEN N'제)통신비'                THEN 7
		            WHEN N'제)감가상각비'            THEN 8
		            WHEN N'제)지급임차료'            THEN 9
		            WHEN N'제)수선비'                THEN 10
		            WHEN N'제)보험료'                THEN 11
		            WHEN N'제)차량유지비'            THEN 12
		            WHEN N'제)교육훈련비'            THEN 13
		            WHEN N'제)도서인쇄비'            THEN 14
		            WHEN N'제)사용권자산감가상각비'  THEN 15
		            WHEN N'제)검사비'                THEN 16
		            WHEN N'제)견본비'                THEN 17
		        END AS rn,
		        N'    ' + AC.상위계정과목 AS gubun,
		        A0.구분,
		        A0.model,
		        SUM(A0.amt) AS amt
		    FROM A0
		    INNER JOIN DOI_ACCT AC WITH(NOLOCK)
		        ON AC.yyyymm = @YYYYMM
		       AND AC.acct_name = A0.acct_name
		    GROUP BY AC.상위계정과목, A0.구분, A0.model
		),
        MFG_SUM AS (
            SELECT 2 rn, N'  제조고정비(합계)' gubun, 구분, model, SUM(amt) amt
            FROM MFG_FIXED
            GROUP BY 구분, model
        ),
		SGA_S0 AS (
		    SELECT
		        S.구분,
		        S.model,
		        S.sub_name,
		        CAST(S.dist_amt AS DECIMAL(18,2)) AS dist_amt
		    FROM doi_smce_cost S WITH(NOLOCK)
		    WHERE S.yyyymm=@YYYYMM AND S.site=@SITE AND S.sel_code=@SELCODE
		      AND S.sub_name IN (SELECT acct_name FROM #ACCT_SGA)
		),
		SGA_FIXED AS (
		    SELECT
		        CASE AC.상위계정과목
		            WHEN N'판)임원급여'             THEN 19
		            WHEN N'판)직원급여'             THEN 20
		            WHEN N'판)상여금'               THEN 21
		            WHEN N'판)제수당'               THEN 22
		            WHEN N'판)퇴직급여'             THEN 23
		            WHEN N'판)복리후생비'           THEN 24
		            WHEN N'판)여비교통비'           THEN 25
		            WHEN N'판)접대비'               THEN 26
		            WHEN N'판)통신비'               THEN 27
		            WHEN N'판)수도광열비'           THEN 28
		            WHEN N'판)세금과공과'           THEN 29
		            WHEN N'판)감가상각비'           THEN 30
		            WHEN N'판)지급임차료'           THEN 31
		            WHEN N'판)수선비'               THEN 32
		            WHEN N'판)보험료'               THEN 33
		            WHEN N'판)차량유지비'           THEN 34
		            WHEN N'판)경상연구개발비'       THEN 35
		            WHEN N'판)교육훈련비'           THEN 36
		            WHEN N'판)도서인쇄비'           THEN 37
		            WHEN N'판)소모품비'             THEN 38
		            WHEN N'판)지급수수료'           THEN 39
		            WHEN N'판)광고선전비'           THEN 40
		            WHEN N'판)무형자산상각비'       THEN 41
		            WHEN N'판)견본비'               THEN 42
		            WHEN N'판)사용권자산감가상각비' THEN 43
		            WHEN N'판)주식보상비용'         THEN 44
		            WHEN N'판)해외시장개척비'       THEN 45
		        END AS rn,
		        N'    ' + AC.상위계정과목 AS gubun,
		        S0.구분,
		        S0.model,
		        SUM(S0.dist_amt) AS amt
		    FROM SGA_S0 S0
		    INNER JOIN DOI_ACCT AC WITH(NOLOCK)
		        ON AC.yyyymm = @YYYYMM
		       AND AC.acct_name = S0.sub_name
		    GROUP BY AC.상위계정과목, S0.구분, S0.model
		),
        SGA_SUM AS (
            SELECT 18 rn, N'  판관고정비(합계)' gubun, 구분, model,
                   SUM(CASE WHEN rn BETWEEN 19 AND 45 THEN amt ELSE 0 END) AS amt
            FROM SGA_FIXED
            GROUP BY 구분, model
        ),
        NONOP_SUM AS (
            SELECT 46 rn, N'  영업외/법인세(합계)' gubun, 구분, model,
                   SUM(CASE WHEN rn BETWEEN 47 AND 60 THEN amt ELSE 0 END) AS amt
            FROM SGA_FIXED
            GROUP BY 구분, model
        ),
        TOTAL_SUM AS (
            SELECT 1 rn, N'  고정비(합계)' gubun, M.구분, M.model,
                   CAST(COALESCE(MF.amt,0) + COALESCE(SF.amt,0) + COALESCE(NO.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN MFG_SUM   MF ON MF.model = M.model AND MF.구분 = M.구분
            LEFT JOIN SGA_SUM   SF ON SF.model = M.model AND SF.구분 = M.구분
            LEFT JOIN NONOP_SUM NO ON NO.model = M.model AND NO.구분 = M.구분
        ),
        FACT AS (
            SELECT rn, gubun, 구분, model, amt FROM MFG_FIXED
   UNION ALL SELECT rn, gubun, 구분, model, amt FROM MFG_SUM
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA_FIXED
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA_SUM
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM NONOP_SUM
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM TOTAL_SUM
        ),
        BASE AS (
            SELECT
                  R.rn
                , R.gubun
                , M.구분
                , M.model
                , COALESCE(F.amt, 0) AS amt
            FROM #RN R
            CROSS JOIN #MODEL M
            LEFT JOIN FACT F
                   ON F.rn   = R.rn
                  AND F.model= M.model
                  AND F.구분 = M.구분
        )
        SELECT
              rn
            , gubun
            , 구분
            , model
            , CAST(amt AS DECIMAL(18,2)) AS amt
        INTO #BASE
        FROM BASE;

        /*==============================================================
          3) 결과
        ==============================================================*/
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

		DROP TABLE #ACCT_MFG;
		DROP TABLE #ACCT_SGA;        
        DROP TABLE #BASE;
        DROP TABLE #RN;
        DROP TABLE #MODEL;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

