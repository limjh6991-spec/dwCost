

ALTER PROCEDURE UP_VN_STOCK_BOH

(

    @YYYYMM    varchar(10), -- 집계 년/월

    @SITE      varchar(2),  -- 사업장 (HQ/VN)

    @SEL_CODE  varchar(10)

)

AS

BEGIN

    SET NOCOUNT ON;

    SET LOCK_TIMEOUT 10000;

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;



    DECLARE @Message  NVARCHAR(MAX) = N'';

    DECLARE @CNT      INT = 0;

    DECLARE @CHECK    BIT = 0;



	IF EXISTS (

	    SELECT 1

	    FROM DOI_CLOSING_MONTH

	    WHERE YYYYMM = @YYYYMM

	      AND IS_CLOSED = 'Y'

	)

	BEGIN

	    RAISERROR(N'마감된 결산월(%s)은 실행할 수 없습니다.', 16, 1, @YYYYMM);

	    RETURN;

	END   

   

    BEGIN TRY

        ---------------------------------------------------------------------

        -- START LOG

        ---------------------------------------------------------------------

        SET @Message =  N'[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                      + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '

                      + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                      + N' 제품BOH 집계를 시작합니다';



        ---------------------------------------------------------------------

        -- 데이터 체크

        ---------------------------------------------------------------------

        SELECT @CNT = COUNT(*)

        FROM DOI_MODEL_MAST

        WHERE yyyymm = @YYYYMM

          AND site   = @SITE;



        IF @CNT = 0

        BEGIN

            SET @Message = @Message + CHAR(10)

                         + N'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                         + N'- 면적정보(DOI_MODEL_MAST) 테이블에 ' + @YYYYMM + N'월 '

                         + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                         + N' 데이타가 없습니다';

            SET @CHECK = 1;

        END



        IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('DOI_COST') AND type IN ('U'))

        BEGIN

            SELECT @CNT = COUNT(*)

            FROM DOI_COST

            WHERE yyyymm   = @YYYYMM

              AND site     = @SITE

              AND sel_code = @SEL_CODE;



            IF @CNT = 0

            BEGIN

                SET @Message = @Message + CHAR(10)

                             + N'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                             + N'- 가공비 배부(DOI_COST) 테이블에 ' + @YYYYMM + N'월 '

                             + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                             + N' 데이타가 없습니다';

                SET @CHECK = 1;

            END

        END

        ELSE

        BEGIN

            SET @Message = @Message + CHAR(10)

                         + N'[ERROR] 가공비 배부(DOI_COST)테이블이 존재하지 않습니다.';

            SET @CHECK = 1;

        END



        SELECT @CNT = COUNT(*)

        FROM DOI_STOCK

        WHERE yyyymm = @YYYYMM

          AND site   = @SITE;



        IF @CNT = 0

        BEGIN

            SET @Message = @Message + CHAR(10)

                         + N'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                         + N'- 제품수불(DOI_STOCK) 테이블에 ' + @YYYYMM + N'월 '

                         + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                         + N' 데이타가 없습니다';

            SET @CHECK = 1;

        END



        IF @CHECK = 1

        BEGIN

            SELECT @Message AS retMessage;

            RETURN -1;

        END



        ---------------------------------------------------------------------

        -- MAIN

        ---------------------------------------------------------------------

        BEGIN TRANSACTION;

--

--        DECLARE @PREV_YYYYMM VARCHAR(6);

--        SET @PREV_YYYYMM = CONVERT(VARCHAR(6), DATEADD(MONTH, -1, CAST(@YYYYMM + '01' AS DATE)), 112);

--

--        /* 1. 당월 DOI_STOCK 기준으로 DOI_ST_BOH_AMT 대상행 생성 */

--        INSERT INTO DOI_ST_BOH_AMT

--        (

--            YYYYMM,

--            SEL_CODE,

--            SITE,

--            구분,

--            품명,

--            품번,

--  BOH_AMT

--        )

--        SELECT

--            @YYYYMM,

--            s.SEL_CODE,

--            s.SITE,

--			s.구분,

--            s.MODEL AS 품명,

--            s.MODEL_TYPE AS 품번,

--            0 AS BOH_AMT

--        FROM

--        (

--            SELECT DISTINCT

--                SEL_CODE,

--                SITE,

--	            CASE 

--		            WHEN RIGHT(MODEL_TYPE,1) = 'P' THEN '양산'

--	            	WHEN RIGHT(MODEL_TYPE,1) = 'R' THEN 'RMA'

--	            	ELSE '개발'

--	            END AS 구분,

--                MODEL,

--                MODEL_TYPE

--            FROM DOI_STOCK

--            WHERE YYYYMM   = @YYYYMM

--              AND SITE     = @SITE

--              AND SEL_CODE = @SEL_CODE

--        ) s

--        WHERE NOT EXISTS

--        (

--            SELECT 1

--            FROM DOI_ST_BOH_AMT t

--            WHERE t.YYYYMM   = @YYYYMM

--              AND t.SEL_CODE = s.SEL_CODE

--              AND t.SITE     = s.SITE

--              AND t.구분     = s.구분

--              AND t.품명     = s.MODEL

--              AND t.품번     = s.MODEL_TYPE

--        );

--

--        /* 2. 기존 BOH_AMT 초기화 */

--        UPDATE DOI_ST_BOH_AMT

--           SET BOH_AMT = 0

--        WHERE YYYYMM   = @YYYYMM

--          AND SITE     = @SITE

--          AND SEL_CODE = @SEL_CODE;

--

--        /* 3. 전월 EOH_AMT를 그대로 반영 */

--        ;WITH PREV_EOH AS

--        (

--            SELECT

--                s.구분,

--                s.MODEL,

--                SUM(COALESCE(s.EOH_AMT, 0)) AS PREV_EOH_AMT

--            FROM DOI_STCO s

--            WHERE s.YYYYMM   = @PREV_YYYYMM

--              AND s.SITE     = @SITE

--              AND s.SEL_CODE = @SEL_CODE

--            GROUP BY

--                s.구분,

--                s.MODEL

--        ),

--        TARGET AS

--        (

--            SELECT

--                a.YYYYMM,

--                a.SEL_CODE,

--                a.SITE,

--                a.구분,

--                a.품명,

--                a.품번,

--                ROW_NUMBER() OVER (

--                    PARTITION BY a.구분, a.품명

--                    ORDER BY a.품번

--                ) AS RN

--            FROM DOI_ST_BOH_AMT a

--            WHERE a.YYYYMM   = @YYYYMM

--              AND a.SITE     = @SITE

--              AND a.SEL_CODE = @SEL_CODE

--        )

--        UPDATE a

--           SET a.BOH_AMT = CASE

--                               WHEN t.RN = 1 THEN p.PREV_EOH_AMT

--                               ELSE 0

--                           END

--        FROM DOI_ST_BOH_AMT a

--        INNER JOIN TARGET t

--                ON a.YYYYMM   = t.YYYYMM

--               AND a.SEL_CODE = t.SEL_CODE

--               AND a.SITE     = t.SITE

--               AND a.구분     = t.구분

--               AND a.품명     = t.품명

--               AND a.품번     = t.품번

--        LEFT JOIN PREV_EOH p

--               ON t.구분 = p.구분

--              AND t.품명 = p.MODEL

--        WHERE a.YYYYMM   = @YYYYMM

--          AND a.SITE     = @SITE

--          AND a.SEL_CODE = @SEL_CODE;       

       

        ---------------------------------------------------------------------

        -- 기존 결과 삭제

        ---------------------------------------------------------------------

        DELETE FROM DOI_STOCK_BOH

        WHERE yyyymm   = @YYYYMM

          AND site     = @SITE

          AND sel_code = @SEL_CODE;



        SET @Message = @Message + CHAR(10)

   + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                     + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '

                     + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

 + N' 제품BOH 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 삭제 했습니다';



        ---------------------------------------------------------------------

        -- 1) OUT단가/항목 기준 데이터 만들기

        ---------------------------------------------------------------------

        IF OBJECT_ID('tempdb..#stboh') IS NOT NULL DROP TABLE #stboh;



        ;WITH MODEL_OUT단가 AS

        (

            SELECT

                a.YYYYMM,

                a.SITE,

                a.구분,

                a.model,

                b.inch,

         a.expen_sel,

                MAX(a.expen_sel명) AS expen_sel명,

                a.acct_name,

                a.item_name,

                SUM(a.out_단가)   AS out_단가,

                SUM(a.unit_cost) AS unit_cost,

                AVG(SUM(a.out_단가)) OVER (PARTITION BY b.inch) AS avg_cost,

                ROW_NUMBER() OVER (

                    PARTITION BY b.Inch, a.expen_sel, a.acct_name, a.item_name

                    ORDER BY a.model, a.expen_sel

                ) AS rn,

                COUNT(1) OVER (

                    PARTITION BY a.model, a.expen_sel, a.acct_name, a.item_name

                    ORDER BY a.item_name

                ) AS model_구분

            FROM DOI_COST a

            LEFT JOIN DOI_MODEL_MAST b

              ON a.model  = b.model

             AND a.yyyymm = b.yyyymm

             AND a.site   = b.site

            WHERE a.YYYYMM   = @YYYYMM

              AND a.SITE     = @SITE

              AND a.SEL_CODE = @SEL_CODE

            GROUP BY

                a.YYYYMM, a.SITE, a.구분,

                b.inch, a.model, a.expen_sel, a.acct_name, a.item_name

        )

        SELECT

            YYYYMM,

            SITE,

            sel_code,

            구분,

            model,

            model_type,

            expen_sel,

            expen_sel명,

            acct_name,

            item_name,

            stock,

            CAST(0 AS float) AS boh_amt,

            Final_InEtc  AS InEtc_Amt,

            Final_OutEtc AS OutEtc_Amt,

            조건,

            inch,

            boh,

            [input],

            [out],

            eoh,

            in_etc,

            out_etc,

            out_단가,

            CAST(NULL AS float) AS BOH_AMT_SRC  -- BOH 총액(원천) 컬럼

        INTO #stboh

        FROM

        (

            -----------------------------------------------------------------

            -- UNION 1) model 매칭(개발/양산 또는 model_구분=1 허용)

            -----------------------------------------------------------------

            SELECT

                YYYYMM, SITE, sel_code, 구분, model, model_type,

                expen_sel, expen_sel명, acct_name, item_name, stock,

                Final_InEtc, Final_OutEtc, 조건, inch, boh, [input], [out], eoh, in_etc, out_etc, out_단가

            FROM

            (

                SELECT t.*,

                       Base_InEtc_amt  + CASE WHEN rn_inetc=1  THEN ROUND(Ori_InEtc_total,0)  - Base_InEtc_total  ELSE 0 END AS Final_InEtc,

                       Base_OutEtc_amt + CASE WHEN rn_outetc=1 THEN ROUND(Ori_OutEtc_total,0) - Base_OutEtc_total ELSE 0 END AS Final_OutEtc

                FROM

                (

                    SELECT a.*,

                           ROW_NUMBER() OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name ORDER BY Ori_InEtc_amt DESC, item_name) AS RN_InEtc,

                           SUM(Ori_InEtc_amt)  OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Ori_InEtc_total,

                           SUM(Base_InEtc_amt) OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Base_InEtc_total,



                           ROW_NUMBER() OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name ORDER BY Ori_OutEtc_amt DESC, item_name) AS RN_OutEtc,

                           SUM(Ori_OutEtc_amt)  OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Ori_OutEtc_total,

                           SUM(Base_OutEtc_amt) OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Base_OutEtc_total

                    FROM

                    (

                        SELECT

                            a.YYYYMM,

                            a.SITE,

                            @SEL_CODE AS sel_code,

                            CASE 

	                            WHEN RIGHT(a.model_type,1)='P' THEN '양산' 

                            	WHEN RIGHT(a.model_type,1)='R' THEN 'RMA'

                            	ELSE '개발' 

                            END AS 구분,

                            a.model,

                            a.model_type,

                            b.expen_sel,

                            b.expen_sel명,

                            b.acct_name,

                            b.item_name,

                            a.stock,

                            -- ★ BOH 금액 계산 금지: 제거(여기선 In/OutEtc만)

                            a.input_etc * b.out_단가 AS Ori_InEtc_amt,

                            ROUND(a.input_etc * b.out_단가,0) AS Base_InEtc_amt,

                            (a.out_etc/* + a.out_moving*/) * b.out_단가 AS Ori_OutEtc_amt,

                            ROUND((a.out_etc/* + a.out_moving*/) * b.out_단가,0) AS Base_OutEtc_amt,

                            'model_1' AS 조건,

                            b.inch,

                            a.boh,

                            a.input_prod AS [input],

                            (a.out_sheet + a.out_invoice ) AS [out],

                            a.eoh,

                            a.input_etc AS in_etc,

                            (a.out_etc/* + a.out_moving*/) AS out_etc,

                            b.out_단가

                        FROM DOI_STOCK a

                        INNER JOIN MODEL_OUT단가 b

                          ON a.model = b.model

                         AND ( b.구분 = 

                         		CASE 

	                         		WHEN RIGHT(a.model_type,1)='P' THEN '양산'

	                         		WHEN RIGHT(a.model_type,1)='R' THEN 'RMA'

	                         		ELSE '개발' END

                               OR b.model_구분 = 1 )

                        WHERE a.YYYYMM = @YYYYMM

                          AND a.SITE   = @SITE

                    ) a

                ) t

            ) Final1



            UNION ALL

            -----------------------------------------------------------------

            -- UNION 2) model 존재하지만 해당 구분(개발/양산) 단가가 없을 때(model_구분=1로 커버)

            -----------------------------------------------------------------

            SELECT

                YYYYMM, SITE, sel_code, 구분, model, model_type,

                expen_sel, expen_sel명, acct_name, item_name, stock,

                Final_InEtc, Final_OutEtc, 조건, inch, boh, [input], [out], eoh, in_etc, out_etc, out_단가

            FROM

            (

                SELECT t.*,

                       Base_InEtc_amt  + CASE WHEN rn_inetc=1  THEN ROUND(Ori_InEtc_total,0)  - Base_InEtc_total  ELSE 0 END AS Final_InEtc,

                       Base_OutEtc_amt + CASE WHEN rn_outetc=1 THEN ROUND(Ori_OutEtc_total,0) - Base_OutEtc_total ELSE 0 END AS Final_OutEtc

                FROM

                (

                    SELECT a.*,

                           ROW_NUMBER() OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name ORDER BY Ori_InEtc_amt DESC, item_name) AS RN_InEtc,

                           SUM(Ori_InEtc_amt)  OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Ori_InEtc_total,

                           SUM(Base_InEtc_amt) OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Base_InEtc_total,



                           ROW_NUMBER() OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name ORDER BY Ori_OutEtc_amt DESC, item_name) AS RN_OutEtc,

                           SUM(Ori_OutEtc_amt)  OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Ori_OutEtc_total,

                           SUM(Base_OutEtc_amt) OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Base_OutEtc_total

                    FROM

                    (

                        SELECT

				 			a.YYYYMM,

				      a.SITE,

                            @SEL_CODE AS sel_code,

                            CASE 

	                            WHEN RIGHT(a.model_type,1)='P' THEN '양산'

	                            WHEN RIGHT(a.model_type,1)='R' THEN 'RMA'

	                            ELSE '개발' 

	                        END AS 구분,

                            a.model,

                            a.model_type,

                            b.expen_sel,

                            b.expen_sel명,

                            b.acct_name,

                            b.item_name,

                            a.stock,

                            a.input_etc * b.out_단가 AS Ori_InEtc_amt,

                            ROUND(a.input_etc * b.out_단가,0) AS Base_InEtc_amt,

                            (a.out_etc/* + a.out_moving*/) * b.out_단가 AS Ori_OutEtc_amt,

                            ROUND((a.out_etc/* + a.out_moving*/) * b.out_단가,0) AS Base_OutEtc_amt,

                            'model_1' AS 조건,

                            b.inch,

                            a.boh,

                            a.input_prod AS [input],

                            (a.out_sheet + a.out_invoice ) AS [out],

                            a.eoh,

                            a.input_etc AS in_etc,

                            (a.out_etc/* + a.out_moving*/) AS out_etc,

                            b.out_단가

                        FROM DOI_STOCK a

                        INNER JOIN MODEL_OUT단가 b

                          ON a.model = b.model

                         AND ( b.구분 = 

                         			CASE 

	                         			WHEN RIGHT(a.model_type,1)='P' THEN '양산'

	                         			WHEN RIGHT(a.model_type,1)='R' THEN 'RMA'

	                         			ELSE '개발' END

                               OR b.model_구분 = 1 )

                        WHERE a.YYYYMM = @YYYYMM

                          AND a.SITE   = @SITE

                          AND NOT EXISTS (

                              SELECT 1

                              FROM MODEL_OUT단가 c

                              WHERE c.model = b.model

                                AND c.구분 = CASE 

	                                			WHEN RIGHT(a.model_type,1)='P' THEN '양산'

	                                			WHEN RIGHT(a.model_type,1)='R' THEN 'RMA'

                                				ELSE '개발' END

                          )

                    ) a

                ) t

            ) Final2



            UNION ALL

            -----------------------------------------------------------------

            -- UNION 3) model 자체 단가가 없으면 inch(대표 rn=1)로 fallback

            -----------------------------------------------------------------

            SELECT

                YYYYMM, SITE, sel_code, 구분, model, model_type,

                expen_sel, expen_sel명, acct_name, item_name, stock,

                Final_InEtc, Final_OutEtc, 조건, inch, boh, [input], [out], eoh, in_etc, out_etc, out_단가

            FROM

            (

                SELECT t.*,

                       Base_InEtc_amt  + CASE WHEN rn_inetc=1  THEN ROUND(Ori_InEtc_total,0)  - Base_InEtc_total  ELSE 0 END AS Final_InEtc,

                       Base_OutEtc_amt + CASE WHEN rn_outetc=1 THEN ROUND(Ori_OutEtc_total,0) - Base_OutEtc_total ELSE 0 END AS Final_OutEtc

                FROM

                (

                    SELECT a.*,

                           ROW_NUMBER() OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name ORDER BY Ori_InEtc_amt DESC, item_name) AS RN_InEtc,

                           SUM(Ori_InEtc_amt)  OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Ori_InEtc_total,

                           SUM(Base_InEtc_amt) OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Base_InEtc_total,



                           ROW_NUMBER() OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name ORDER BY Ori_OutEtc_amt DESC, item_name) AS RN_OutEtc,

                           SUM(Ori_OutEtc_amt)  OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Ori_OutEtc_total,

                           SUM(Base_OutEtc_amt) OVER (PARTITION BY YYYYMM,SITE,sel_code,구분,model,expen_sel,acct_name,item_name) AS Base_OutEtc_total

                    FROM

                    (

                        SELECT

                            a.YYYYMM,

			                a.SITE,

			             	@SEL_CODE AS sel_code,

                            CASE 

	                            WHEN RIGHT(a.model_type,1)='P' THEN '양산'

	                            WHEN RIGHT(a.model_type,1)='R' THEN 'RMA'

	                            ELSE '개발' 

	                        END AS 구분,

                            a.model,

                            a.model_type,

                            c.expen_sel,

                            c.expen_sel명,

                            c.acct_name,

                            c.item_name,

                            a.stock,

                            a.input_etc * c.out_단가 AS Ori_InEtc_amt,

                            ROUND(a.input_etc * c.out_단가,0) AS Base_InEtc_amt,

                            (a.out_etc /*+ a.out_moving*/) * c.out_단가 AS Ori_OutEtc_amt,

                            ROUND((a.out_etc/* + a.out_moving*/) * c.out_단가,0) AS Base_OutEtc_amt,

                            'inch' AS 조건,

                            b.inch,

                            a.boh,

                            a.input_prod AS [input],

                            (a.out_sheet + a.out_invoice ) AS [out],

                            a.eoh,

                            a.input_etc as in_etc,

                            (a.out_etc /*+ a.out_moving*/) AS out_etc,

                            COALESCE(c.out_단가,0) AS out_단가

                        FROM DOI_STOCK a

                        LEFT JOIN DOI_MODEL_MAST b

                          ON a.model  = b.model

                         AND a.yyyymm = b.yyyymm

                         AND a.site   = b.site

                        LEFT JOIN MODEL_OUT단가 c

                          ON c.inch =

                                CASE

                                    WHEN b.inch IN (7.99,8.01) THEN 8

                                    WHEN b.inch = 7.61 THEN 7.72

                                    WHEN b.inch IN (6.86,7.55) THEN 7.56

                                    ELSE b.inch

                                END

                         AND c.rn = 1

                        WHERE a.YYYYMM = @YYYYMM

                          AND a.SITE   = @SITE

                          AND NOT EXISTS (SELECT 1 FROM MODEL_OUT단가 m WHERE m.model = a.model)

                    ) a

                ) t

            ) Final3

        ) F;



--        UPDATE doi_stock_boh SET boh_amt = 0 where yyyymm = @YYYYMM 

       

		/* =========================================================

		   전월 DOI_STCO EOH -> 당월 DOI_STOCK_BOH BOH 반영

		   ========================================================= */

		

		DECLARE @PREV_MONTH VARCHAR(6);

		SELECT @PREV_MONTH = FORMAT(DATEADD(MONTH, -1, CAST(@YYYYMM + '01' AS DATE)), 'yyyyMM');

		

		;WITH PREV_EOH AS

		(

		    SELECT

		        SITE,

		        SEL_CODE,

		        구분,

		        MODEL,

		        EXPEN_SEL,

		        EXPEN_SEL명,

		        ACCT_NAME,

		        SUM(COALESCE(EOH_AMT, 0)) AS EOH_AMT,

		        SUM(COALESCE(EOH, 0))     AS EOH_QTY

		    FROM DOI_STCO

		    WHERE YYYYMM   = @PREV_MONTH

		      AND SITE     = @SITE

		      AND SEL_CODE = @SEL_CODE

		      AND COALESCE(EOH_AMT, 0) <> 0

		    GROUP BY

		        SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME

		),

		PREV_EOH_TARGET AS

		(

		    SELECT

		        @YYYYMM AS YYYYMM,

		        P.SITE,

		        P.SEL_CODE,

		        P.구분,

		        P.MODEL,

		        COALESCE(X.MODEL_TYPE, Y.MODEL_TYPE, P.MODEL + CASE WHEN P.구분 = 'RMA' THEN 'R' WHEN P.구분 = '양산' THEN 'P' ELSE 'D' END) AS MODEL_TYPE,

		        P.EXPEN_SEL,

		        P.EXPEN_SEL명,

		        P.ACCT_NAME,

		        P.EOH_AMT,

		 P.EOH_QTY

		    FROM PREV_EOH P

		    OUTER APPLY

		    (

		        SELECT TOP 1 MODEL_TYPE

		        FROM #stboh X

		        WHERE X.구분      = P.구분

		          AND X.MODEL     = P.MODEL

		          AND X.EXPEN_SEL = P.EXPEN_SEL

		          AND X.ACCT_NAME = P.ACCT_NAME

		        ORDER BY X.MODEL_TYPE

		    ) X

		    OUTER APPLY

		    (

		        SELECT TOP 1 S.MODEL_TYPE

		        FROM DOI_STOCK S

		        WHERE S.YYYYMM   = @YYYYMM

		          AND S.SITE     = @SITE

		          AND S.SEL_CODE = @SEL_CODE

		          AND LEFT(S.MODEL_TYPE, LEN(S.MODEL_TYPE)-1) = P.MODEL

		        ORDER BY S.MODEL_TYPE

		    ) Y

		)

		MERGE DOI_STOCK_BOH AS T

		USING PREV_EOH_TARGET AS S

		   ON T.YYYYMM    = S.YYYYMM

		  AND T.SITE      = S.SITE

		  AND T.SEL_CODE  = S.SEL_CODE

		  AND T.구분      = S.구분

		  AND T.MODEL     = S.MODEL

		  AND T.EXPEN_SEL = S.EXPEN_SEL

		  AND T.ACCT_NAME = S.ACCT_NAME

		

		WHEN MATCHED THEN

		    UPDATE SET

		        T.BOH_AMT = S.EOH_AMT,

		        T.BOH     = S.EOH_QTY,

		        T.EOH     = S.EOH_QTY,

		        T.[INPUT] = 0,

		        T.[OUT]   = 0,

		        T.IN_ETC  = 0,

		        T.OUT_ETC = 0,

		        T.OUT_단가 = 0

		

		WHEN NOT MATCHED BY TARGET THEN

		    INSERT

		    (

		        YYYYMM, SITE, SEL_CODE, 구분, MODEL, MODEL_TYPE,

		        EXPEN_SEL, EXPEN_SEL명, ACCT_NAME, ITEM_NAME,

		        STOCK, BOH_AMT, InEtc_Amt, OutEtc_Amt, 조건,

		        INCH, BOH, [INPUT], [OUT], EOH, IN_ETC, OUT_ETC, OUT_단가

		    )

		    VALUES

		    (

		        S.YYYYMM, S.SITE, S.SEL_CODE, S.구분, S.MODEL, S.MODEL_TYPE,

		        S.EXPEN_SEL, S.EXPEN_SEL명, S.ACCT_NAME, NULL,

		        0, S.EOH_AMT, 0, 0, 'PREV',

		        NULL, S.EOH_QTY, 0, 0, S.EOH_QTY, 0, 0, 0

		    );       

 /*      

        ---------------------------------------------------------------------

        -- 2) BOH 총액(원천)은 DOI_ST_BOH_AMT에서만 가져와서 #stboh에 부착

        ---------------------------------------------------------------------

        UPDATE a

           SET a.BOH_AMT_SRC = b.BOH_AMT

        FROM #stboh a

        JOIN DOI_ST_BOH_AMT b

          ON b.yyyymm   = @YYYYMM

         AND b.site 	= @SITE

         AND b.sel_code = @SEL_CODE

         AND b.구분     = a.구분

         AND b.품번     = a.model_type;



        ---------------------------------------------------------------------

        -- 3) BOH 금액은 EXPEN_ACCT_RATE로만 배부해서 DOI_STOCK_BOH에 INSERT

        ---------------------------------------------------------------------

    ;WITH EXPEN_ACCT_RATE AS

        (

            /*SELECT

                EXPEN_SEL,

                ACCT_NAME,

                SUB_NAME,

                SUM([IN]) AS IN_AMT,

                CAST(SUM([IN]) AS float) / NULLIF(SUM(SUM([IN])) OVER(), 0) AS ACCT_RATE

            FROM DOI_EXPEN_MATL

            WHERE yyyymm   = @YYYYMM

              AND site     = @SITE

              AND sel_code = @SEL_CODE

            GROUP BY EXPEN_SEL, ACCT_NAME, SUB_NAME*/

        	SELECT

                EXPEN_SEL,

                ACCT_NAME,

                ITEM_NAME,

                SUM([IN]) AS IN_AMT,

                CAST(SUM([IN]) AS float) / NULLIF(SUM(SUM([IN])) OVER(), 0) AS ACCT_RATE

  FROM DOI_COST

            WHERE yyyymm   = @YYYYMM

              AND site     = @SITE

              AND sel_code = @SEL_CODE

            GROUP BY EXPEN_SEL, ACCT_NAME, ITEM_NAME

        ),

        DIST AS

        (

            SELECT

                a.*,

                COALESCE(r.ACCT_RATE, 0.0) AS ACCT_RATE,

                ROUND(a.BOH_AMT_SRC * COALESCE(r.ACCT_RATE, 0.0), 0) AS Base_BOH

            FROM #stboh a

            LEFT JOIN EXPEN_ACCT_RATE r

              ON a.expen_sel  = r.expen_sel

             AND a.acct_name  = r.acct_name

             AND a.item_name  = r.item_name

              -- OR a.expen_sel = '*'

              -- OR a.expen_sel IS NULL

        ),

        FIX AS

        (

            SELECT

                d.*,

                SUM(d.Base_BOH) OVER (

  PARTITION BY d.YYYYMM, d.SITE, d.sel_code, d.구분, d.model, d.model_type

                ) AS Sum_Base_BOH,

                MAX(d.BOH_AMT_SRC) OVER (

                    PARTITION BY d.YYYYMM, d.SITE, d.sel_code, d.구분, d.model, d.model_type

                ) AS BOH_AMT_GRP,

                ROW_NUMBER() OVER (

                    PARTITION BY d.YYYYMM, d.SITE, d.sel_code, d.구분, d.model, d.model_type

                    ORDER BY d.Base_BOH DESC, d.expen_sel, d.acct_name, d.item_name

                ) AS RN

            FROM DIST d

        )

        INSERT INTO DOI_STOCK_BOH

        (

            YYYYMM, SITE, sel_code, 구분, model, model_type,

            expen_sel, expen_sel명, acct_name, item_name,

            stock, boh_amt, InEtc_Amt,/* OutEtc_Amt,*/ 조건,

            inch, boh, [input], [out], eoh, in_etc, out_etc, out_단가

        )

        SELECT

            f.YYYYMM, f.SITE, f.sel_code, f.구분, f.model, f.model_type,

            f.expen_sel, f.expen_sel명, f.acct_name, f.item_name,

            f.stock,

            ( f.Base_BOH

              + CASE WHEN f.RN = 1 THEN (ROUND(f.BOH_AMT_GRP,0) - f.Sum_Base_BOH) ELSE 0 END

            ) AS boh_amt,

            f.InEtc_Amt,

            /*f.OutEtc_Amt,*/

            f.조건,

            f.inch, f.boh, 

			f.INPUT,

			f.[out], f.eoh, f.in_etc, f.out_etc, f.out_단가

    	FROM FIX f;



*/

		   

        SET @Message = @Message + CHAR(10)

                     + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                     + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '

                     + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                     + N' 제품BOH 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 입력했습니다';		   

		   

		 --2026.01.17 22:21        

		update	doi_stock_boh

		set

			OutEtc_Amt = round(out_etc * case when out_단가 != 0 then out_단가 else (boh_amt + [input] + InEtc_Amt)/(boh + [input] + in_etc) end, 0)

		WHERE

			yyyymm = @YYYYMM

			and site = @SITE

			and sel_code = @SEL_CODE

			and boh = eoh + out_etc

			and out_etc != 0

			and out_단가 = 0;

 

        SET @Message = @Message + CHAR(10)

                     + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                     + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '

                     + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                     + N'기타출고금액(OUTETC_AMT) ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 업데이트 했습니다';  



       ---------------------------------------------------------------------

        -- 제품수불금액 집계 호출

        ---------------------------------------------------------------------

        DECLARE @Ret_M nvarchar(MAX) = N'';

        EXEC UP_VN_STOCK_COST

             @YYYYMM    = @YYYYMM,

             @SITE      = @SITE,

             @SEL_CODE  = @SEL_CODE,

             @R_Message = @Ret_M OUTPUT;



        SET @Message = @Message + @Ret_M;



        ---------------------------------------------------------------------

        -- OUT단가 테이블 삭제

        ---------------------------------------------------------------------

        DELETE FROM DOI_STUC

        WHERE yyyymm = @YYYYMM

          AND site   = @SITE

         AND sel_code = @SEL_CODE;



        SET @Message = @Message + CHAR(10) + CHAR(10)

                     + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                     + N'- OUT단가(DOI_STUC) 테이블에 ' + @YYYYMM + N'월 '

                     + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                     + N' 제품 출고단가 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 삭제 했습니다';

  

        ---------------------------------------------------------------------

        -- OUT단가 테이블 입력

        ---------------------------------------------------------------------

		  INSERT INTO  DOI_STUC

		  (YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,EXPEN_SEL명,ACCT_NAME,ITEM_NAME,SRC_TABLE,OUT_AMT,OUT_QTY,OUT_UNITCOST)

		  select

					s.YYYYMM,

					s.SEL_CODE,

					s.SITE,

					s.구분,

					s.MODEL,		

					s.EXPEN_SEL,

					s.EXPEN_SEL명,

					s.ACCT_NAME,

					'제품단가' as ITEM_NAME,

					'STCO' as SRC,

					(s.BOH_AMT+s.IN_AMT) AMT,		

					(s.BOH+s.[INPUT]) as QTY,

					COALESCE(cast((s.BOH_AMT+s.IN_AMT) as numeric(24,12)) / NULLIF((s.BOH+s.[INPUT]),0),0) AS OUT_UNITCOST

				from	doi_stco s 

				where 1=1

					and yyyymm = @YYYYMM

					and site = @SITE

					and sel_code = @SEL_CODE

					AND expen_sel != '*'

					and acct_name != '기타출고'

				union all

					select 		

					c.YYYYMM,

					c.SEL_CODE,

					c.SITE,

					c.구분,

					c.MODEL,		

					c.EXPEN_SEL,

					c.EXPEN_SEL명,

					c.acct_name,

					c.item_name,

					'COST' as SRC,

					(c.BOH + c.[IN]) AMT,		

					((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty) as QTY, 

					c.OUT_단가 as OUT_UNITCOST 

					from doi_cost c

						where 1=1

					and c.yyyymm = @YYYYMM

					and c.site = @SITE

					and c.sel_code = @SEL_CODE

					AND c.expen_sel != '*'

					and c.acct_name != '기타출고'

					  and not exists (

					      select 1

					      from doi_stco s

					      where s.yyyymm   = c.yyyymm

					        and s.site     = c.site

					        and s.sel_code = c.sel_code

					        and s.구분      = c.구분

					        and s.model    = c.model

					        and s.expen_sel <> '*'

					        and s.acct_name <> N'기타출고'

					  ) ;

        

        SET @Message = @Message + CHAR(10)

                     + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                     + N'- OUT단가(DOI_STUC) 테이블에 ' + @YYYYMM + N'월 '

                     + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                     + N' 제품 출고단가 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 입력했습니다';

                                        

			--RMA STCO 중복 삭제      

/*			WITH duplicates AS (

			    SELECT model,

			           ROW_NUMBER() OVER (

			               PARTITION BY model 

			               ORDER BY expen_sel

			           ) AS rn -- select *

			    FROM doi_stco

			    WHERE yyyymm = @YYYYMM

			      AND sel_code = @SEL_CODE

			      AND site = @SITE

			      AND 구분 = 'RMA'

			)

			DELETE FROM duplicates

			WHERE rn > 1;*/

			

		;WITH RMA_SUM AS (

		    SELECT

		        yyyymm,

		        site,

		        sel_code,

		        model,

		        SUM(ISNULL(boh_amt, 0))    AS boh_amt,

		        SUM(ISNULL(in_amt, 0))     AS in_amt,

		        SUM(ISNULL(eoh_amt, 0))    AS eoh_amt,

		        SUM(ISNULL(out_amt, 0))    AS out_amt,

		        SUM(ISNULL(inetc_amt, 0))  AS inetc_amt,

		        SUM(ISNULL(outetc_amt, 0)) AS outetc_amt

		    FROM doi_stco

		    WHERE yyyymm   = @YYYYMM

		      AND sel_code = @SEL_CODE

		      AND site     = @SITE

		      AND 구분     = 'RMA'

		    GROUP BY

		        yyyymm, site, sel_code, model

		),

		RMA_RN AS (

		    SELECT

		        yyyymm,

		        site,

		        sel_code,

		        구분,

		        model,

		        expen_sel,

		        acct_name,

		        ROW_NUMBER() OVER (

		            PARTITION BY yyyymm, site, sel_code, model

		            ORDER BY expen_sel, acct_name

		        ) AS rn

		    FROM doi_stco

		    WHERE yyyymm   = @YYYYMM

		      AND sel_code = @SEL_CODE

		      AND site     = @SITE

		      AND 구분     = 'RMA'

		)

		UPDATE t

		SET

		    expen_sel   = CASE WHEN r.rn = 1 THEN 'RMA1' ELSE t.expen_sel END,

		    expen_sel명 = CASE WHEN r.rn = 1 THEN 'RMA1' ELSE t.expen_sel명 END,

		    acct_name   = CASE WHEN r.rn = 1 THEN 'RMA1' ELSE t.acct_name END,

		    boh_amt     = CASE WHEN r.rn = 1 THEN s.boh_amt    ELSE 0 END,

		    in_amt      = CASE WHEN r.rn = 1 THEN s.in_amt     ELSE 0 END,

		    eoh_amt     = CASE WHEN r.rn = 1 THEN s.eoh_amt    ELSE 0 END,

		    out_amt     = CASE WHEN r.rn = 1 THEN s.out_amt    ELSE 0 END,

		    inetc_amt   = CASE WHEN r.rn = 1 THEN s.inetc_amt  ELSE 0 END,

		    outetc_amt  = CASE WHEN r.rn = 1 THEN s.outetc_amt ELSE 0 END

		FROM doi_stco t

		JOIN RMA_RN r

		  ON t.yyyymm    = r.yyyymm

		 AND t.site      = r.site

		 AND t.sel_code  = r.sel_code

		 AND t.구분      = r.구분

		 AND t.model     = r.model

		 AND t.expen_sel = r.expen_sel

		 AND t.acct_name = r.acct_name

		JOIN RMA_SUM s

		  ON r.yyyymm    = s.yyyymm

		 AND r.site      = s.site

		 AND r.sel_code  = s.sel_code

		 AND r.model     = s.model

		WHERE t.yyyymm   = @YYYYMM

		  AND t.sel_code = @SEL_CODE

		  AND t.site     = @SITE

		  AND t.구분     = 'RMA';

		

		-- 0 처리된 RMA 보조행 삭제

		DELETE FROM doi_stco

		WHERE yyyymm   = @YYYYMM

		  AND sel_code = @SEL_CODE

		  AND site     = @SITE

		  AND 구분     = 'RMA'

		  AND ISNULL(boh_amt,0)    = 0

		  AND ISNULL(in_amt,0)     = 0

		  AND ISNULL(eoh_amt,0)    = 0

		  AND ISNULL(out_amt,0)    = 0

		  AND ISNULL(inetc_amt,0)  = 0

		  AND ISNULL(outetc_amt,0) = 0;                           

                    

		-- STCO RMA 모델 RMA금액 업데이트

		;WITH RMA_STOCK AS (

		    SELECT

		        yyyymm,

		        sel_code,

		        site,

		        model,

		        SUM(ISNULL(rma_amt, 0)) AS rma_amt

		    FROM doi_stock

		    WHERE yyyymm   = @YYYYMM

		      AND sel_code = @SEL_CODE

		      AND site     = @SITE

		      AND model_type LIKE '%R'

		    GROUP BY

		        yyyymm, sel_code, site, model

		)

		UPDATE s

		SET

		   expen_sel   = 'RMA1',

		   expen_sel명 = 'RMA1',

		   acct_name   = 'RMA1',

		   in_amt      = r.rma_amt,

		   eoh_amt     = CASE

		                    WHEN ISNULL(s.[input],0) = 0

		                     AND ISNULL(s.[out],0) = 0

		                     AND ISNULL(s.outetc,0) = 0

		                      THEN ISNULL(s.boh_amt,0) + ISNULL(r.rma_amt,0)

		                    ELSE ISNULL(r.rma_amt,0)

		                 END,

		   RMAIN_QTY   = s.[input],

		   RMAIN_AMT   = r.rma_amt

		FROM doi_stco s

		LEFT JOIN RMA_STOCK r

		  ON s.yyyymm   = r.yyyymm

		 AND s.sel_code = r.sel_code

		 AND s.site     = r.site

		 AND s.model    = r.model

		WHERE s.yyyymm   = @YYYYMM

		  AND s.sel_code = @SEL_CODE

		  AND s.site     = @SITE

		  AND s.구분     = 'RMA';

			 

			--STCO RMA 양산모델 기타출고금액 0으로 업데이트

			WITH duplicates_zero AS (

			    SELECT model,expen_sel,acct_name,

			           ROW_NUMBER() OVER (

			               PARTITION BY model 

			               ORDER BY expen_sel

			           ) AS rn --select *

			    FROM doi_stco s

			    WHERE yyyymm = @YYYYMM

			      AND sel_code = @SEL_CODE

			      AND site = @SITE

			      AND 구분 = '양산'

			      AND exists (select 1 FROM   doi_stco r 

			      WHERE s.yyyymm = r.yyyymm and s.sel_code = r.sel_code and s.site = r.site and s.model = r.MODEL AND r.구분 = 'RMA')

			)

			UPDATE t

			SET -- OUT_AMT		= OUT_AMT + OUTETC_AMT,

				OUTETC_AMT  = 0

			FROM doi_stco t

			JOIN duplicates_zero d ON t.model = d.model and  t.expen_sel=d.expen_sel and t.acct_name=d.acct_name

			WHERE t.yyyymm = @YYYYMM

			      AND t.sel_code = @SEL_CODE

			      AND t.site = @SITE

			      AND t.구분 = '양산'

			      AND exists (select 1 FROM   doi_stco r 

			            WHERE t.yyyymm = r.yyyymm and t.sel_code = r.sel_code and t.site = r.site and t.model = r.MODEL AND r.구분 = 'RMA');

			

			--STCO RMA 양산모델 기타출고금액을 RMA금액으로 업데이트

			with rma_duplicates AS (

			    SELECT model,expen_sel,acct_name,

			           ROW_NUMBER() OVER (

			               PARTITION BY model 

			               ORDER BY expen_sel

			           ) AS rn --select *

			    FROM doi_stco s

			    WHERE yyyymm = @YYYYMM

			      AND sel_code = @SEL_CODE

			      AND site = @SITE

			      AND 구분 = '양산'

			      AND exists (select 1 FROM   doi_stco r 

			      WHERE s.yyyymm = r.yyyymm and s.sel_code = r.sel_code and s.site = r.site and s.model = r.MODEL AND r.구분 = 'RMA')

			)--select * from duplicates where rn=1

			UPDATE t

			SET OUTETC_AMT = s.rma_amt

			FROM doi_stco t

			JOIN rma_duplicates d ON t.model = d.model and  t.expen_sel=d.expen_sel and t.acct_name=d.acct_name

			JOIN doi_stock s 

			ON t.yyyymm = s.yyyymm

			and t.site  = s.site

			and t.sel_code = s.sel_code

			and t.model = s.model 

			and s.model_type LIKE '%R'

			WHERE d.rn = 1 

			  AND t.yyyymm = @YYYYMM

			  AND t.sel_code = @SEL_CODE

			  AND t.site = @SITE

			  AND t.구분 = '양산'

			  AND exists (select 1 FROM   doi_stco r 

			        WHERE t.yyyymm = r.yyyymm and t.sel_code = r.sel_code and t.site = r.site and t.model = r.MODEL AND r.구분 = 'RMA')

			                    

            INSERT INTO DOI_STCO 

			(YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel, expen_sel명, acct_name, [out], out_amt, outetc, outetc_amt)

			select

				s.YYYYMM,

				s.SITE,

				s.SEL_CODE,

				'양산' 구분,

				s.MODEL,

				'RMA0' expen_sel,

				'RMA0' expen_sel명,

				'RMA0' acct_name,

				0 as [out],

				0 as out_amt,

				s.input as outetc,

				s.in_amt as outetc_amt --select *

			from

				DOI_STCO s

			WHERE

				1 = 1

			   AND s.yyyymm = @YYYYMM

			   AND s.sel_code = @SEL_CODE

			   AND s.site = @SITE

			   AND s.구분 = 'RMA'

			   AND not exists

					   (select 1 from DOI_STCO r where s.yyyymm = r.yyyymm

					      and s.sel_code = r.sel_code

					      and s.site = r.site

					      and s.model = r.model

					      and r.구분 like '양산') 

					      

		/*;WITH STUC_AGG AS

		(

		    SELECT

		        yyyymm, site, sel_code, 구분, model, expen_sel,

		        MAX(expen_sel명) AS expen_sel명, acct_name,

		        SUM(ISNULL(out_amt,0)) AS out_amt_sum,

		        SUM(ISNULL(out_qty,0)) AS out_qty_sum,

		        CASE WHEN SUM(ISNULL(out_qty,0)) = 0 THEN 0

		             ELSE SUM(ISNULL(out_amt,0)) / SUM(ISNULL(out_qty,0))

		        END AS out_unitcost

		    FROM DOI_STUC

		    WHERE site = @SITE

		      AND sel_code = @SEL_CODE

		    GROUP BY yyyymm, site, sel_code, 구분, model, expen_sel, acct_name

		),

		OUT단가 AS

		(

		    SELECT

		      *,

		        SUM(out_unitcost) OVER (PARTITION BY yyyymm, site, sel_code, 구분, model) AS model_outuc,

		        DENSE_RANK() OVER (

		            PARTITION BY site, sel_code, 구분, model, expen_sel, acct_name

		          ORDER BY yyyymm DESC

		        ) AS rn

		    FROM STUC_AGG

		),

		RMAIN_STCO AS

		(

		    SELECT

		        T.*,

		        Base_Amt + CASE WHEN RN=1 THEN (modelAmt - Sum_Base_Amt) ELSE 0 END AS RMAIN_AMT

		    FROM

		    (

		        SELECT

		            A.*,

		            SUM(Base_Amt) OVER (PARTITION BY yyyymm, site, sel_code, 구분, model) AS Sum_Base_Amt,

		            ROW_NUMBER() OVER (PARTITION BY yyyymm, site, sel_code, 구분, model ORDER BY Base_Amt DESC, expen_sel) AS RN

		        FROM

		        (

		            SELECT

		                a.yyyymm,

		                a.site,

		                a.sel_code,

		                b.구분,

		                b.model,

		                b.expen_sel,

		                b.expen_sel명,

		                b.acct_name,

		                a.rma_in AS RMAIN_QTY,

		                ROUND(a.rma_in * b.model_outuc, 0) AS modelAmt,

		                ROUND(a.rma_in * b.out_unitcost, 0) AS Base_Amt

		            FROM DOI_RMA_INOUT a

		            INNER JOIN OUT단가 b

		              ON a.yyyymm = b.yyyymm

		       AND a.site   = b.site

		             AND a.sel_code = b.sel_code

		        AND LEFT(a.도우코드, 4) = b.model

		             AND b.구분 = CASE WHEN RIGHT(a.도우코드,1)='P' THEN '양산' ELSE '개발' END

		             AND b.rn = 1

		            WHERE a.yyyymm   = @YYYYMM

		              AND a.site     = @SITE

		              AND a.sel_code = @SEL_CODE

		              AND ISNULL(a.rma_in,0) <> 0

		        ) A

		    ) T

		)

		MERGE DOI_STCO AS t

		USING RMAIN_STCO AS s

		   ON t.YYYYMM    = s.YYYYMM

		  AND t.SITE      = s.SITE

		  AND t.SEL_CODE  = s.SEL_CODE

		  AND t.구분      = s.구분

		  AND t.MODEL     = s.MODEL

		  AND t.EXPEN_SEL = s.EXPEN_SEL

		  AND t.ACCT_NAME = s.ACCT_NAME

		WHEN MATCHED THEN

		    UPDATE SET

		        t.RMAIN_QTY = s.RMAIN_QTY,

		        t.RMAIN_AMT = s.RMAIN_AMT

		WHEN NOT MATCHED BY TARGET THEN

		    INSERT (YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel, expen_sel명, acct_name, RMAIN_QTY, RMAIN_AMT)

		    VALUES (s.YYYYMM, s.SITE, s.SEL_CODE, s.구분, s.MODEL, s.expen_sel, s.expen_sel명, s.acct_name, s.RMAIN_QTY, s.RMAIN_AMT);            

		

		SET @Message = @Message + CHAR(10) + CHAR(10)

		             + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

		             + N'- 제품수불금액(DOI_STCO) 테이블에 ' + @YYYYMM + N'월 '

		             + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END

		             + N' RMA IN 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 업데이트 했습니다';



		;WITH STUC_AGG AS

		(

		    SELECT

		        yyyymm, site, sel_code, 구분, model, expen_sel,

		        MAX(expen_sel명) AS expen_sel명, acct_name,

		        SUM(ISNULL(out_amt,0)) AS out_amt_sum,

		        SUM(ISNULL(out_qty,0)) AS out_qty_sum,

		        CASE WHEN SUM(ISNULL(out_qty,0)) = 0 THEN 0

		             ELSE SUM(ISNULL(out_amt,0)) / SUM(ISNULL(out_qty,0))

		        END AS out_unitcost

		    FROM DOI_STUC

		    WHERE site     = @SITE

		      AND sel_code = @SEL_CODE

		    GROUP BY yyyymm, site, sel_code, 구분, model, expen_sel, acct_name

		),

		OUT단가 AS

		(

		    SELECT

		        *,

		        SUM(out_unitcost) OVER (PARTITION BY yyyymm, site, sel_code, 구분, model) AS model_outuc,

		        DENSE_RANK() OVER (

		            PARTITION BY site, sel_code, 구분, model, expen_sel, acct_name

		            ORDER BY yyyymm DESC

		        ) AS rn

		    FROM STUC_AGG

		),

		AREAOUT_STCO AS

		(

		    SELECT

		        T.*,

		        Base_Amt + CASE WHEN RN=1 THEN (modelAmt - Sum_Base_Amt) ELSE 0 END AS AREAOUT_AMT

		    FROM

		    (

		        SELECT

		            A.*,

		            SUM(Base_Amt) OVER (PARTITION BY site, 구분, model) AS Sum_Base_Amt,

		            ROW_NUMBER() OVER (PARTITION BY site, 구분, model ORDER BY Base_Amt DESC, expen_sel) AS RN

		        FROM

		        (

		            SELECT

		                a.yyyymm,

		                a.site,

		                a.sel_code,

		                b.구분,

		 b.model,

		              b.expen_sel,

		                b.expen_sel명,

		                b.acct_name,

		                a.area_out AS AREAOUT_QTY,

		                ROUND(a.area_out * b.model_outuc, 0) AS modelAmt,

		                ROUND(a.area_out * b.out_unitcost, 0) AS Base_Amt

		            FROM DOI_RMA_INOUT a

		            INNER JOIN OUT단가 b

		              ON a.yyyymm = b.yyyymm

		             AND a.site   = b.site

		             AND a.sel_code = b.sel_code

		             AND LEFT(a.도우코드, 4) = b.model

		             AND b.구분 = CASE WHEN RIGHT(a.도우코드,1)='P' THEN '양산' ELSE '개발' END

		             AND b.rn = 1

		            WHERE a.yyyymm   = @YYYYMM

		              AND a.site     = @SITE

		              AND a.sel_code = @SEL_CODE

		              AND ISNULL(a.area_out,0) <> 0

		        ) A

		    ) T

		)

		MERGE DOI_STCO AS t

		USING AREAOUT_STCO AS s

		   ON t.YYYYMM    = s.YYYYMM

		  AND t.SITE      = s.SITE

		  AND t.SEL_CODE  = s.SEL_CODE

		  AND t.구분      = s.구분

		  AND t.MODEL     = s.MODEL

		  AND t.EXPEN_SEL = s.EXPEN_SEL

		  AND t.ACCT_NAME = s.ACCT_NAME

		WHEN MATCHED THEN

		    UPDATE SET

		        t.AREAOUT_QTY = s.AREAOUT_QTY,

		        t.AREAOUT_AMT = s.AREAOUT_AMT

		WHEN NOT MATCHED BY TARGET THEN

		    INSERT (YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel, expen_sel명, acct_name, AREAOUT_QTY, AREAOUT_AMT)

		    VALUES (s.YYYYMM, s.SITE, s.SEL_CODE, s.구분, s.MODEL, s.expen_sel, s.expen_sel명, s.acct_name, s.AREAOUT_QTY, s.AREAOUT_AMT);



   		SET @Message = @Message + CHAR(10) + CHAR(10)

             + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

             + N'- 제품수불금액(DOI_STCO) 테이블에 ' + @YYYYMM + N'월 '

             + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END

             + N' AREA OUT 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 업데이트 했습니다';

		-----------------------------------------------------------------------

		-- RMA IN (DOI_COST 업데이트/추가)  * ACCT_NAME != 'CST'

		-----------------------------------------------------------------------

		;WITH STCO_SRC AS

		(

		    SELECT

		        yyyymm, site, sel_code, 구분, model, expen_sel,

		        SUM(ISNULL(areaout_qty,0)) AS TOT_QTY,

		        SUM(ISNULL(areaout_amt,0)) AS TOT_AMT

		    FROM DOI_STCO

		  WHERE yyyymm   = @YYYYMM

		      AND site     = @SITE

		      AND sel_code = @SEL_CODE

		      AND ISNULL(areaout_qty,0) <> 0

		    GROUP BY yyyymm, site, sel_code, 구분, model, expen_sel

		),

		COST_LINES AS

		(

		    SELECT

		        c.*,

		        s.TOT_QTY,

		        s.TOT_AMT,

		        SUM(ABS(ISNULL(c.out_단가,0))) OVER

		          (PARTITION BY c.yyyymm,c.site,c.sel_code,c.구분,c.model,c.expen_sel) AS SumW,

		        ROW_NUMBER() OVER

		          (PARTITION BY c.yyyymm,c.site,c.sel_code,c.구분,c.model,c.expen_sel

		           ORDER BY ABS(ISNULL(c.out_단가,0)) DESC, c.acct_name, c.item_name) AS RN

		    FROM DOI_COST c

		    JOIN STCO_SRC s

		      ON c.yyyymm   = s.yyyymm

		     AND c.site     = s.site

		     AND c.sel_code = s.sel_code

		     AND c.구분     = s.구분

		     AND c.model    = s.model

		     AND c.expen_sel= s.expen_sel

		    WHERE c.ACCT_NAME <> 'CST'

		),

		DIST AS

		(

		    SELECT

		        a.*,

		        CASE WHEN NULLIF(a.SumW,0) IS NULL THEN 0.0

		             ELSE ABS(ISNULL(a.out_단가,0)) / NULLIF(a.SumW,0)

		        END AS RATE,

		        ROUND(a.TOT_AMT * (

		            CASE WHEN NULLIF(a.SumW,0) IS NULL THEN 0.0

		                 ELSE ABS(ISNULL(a.out_단가,0)) / NULLIF(a.SumW,0)

		            END

		        ), 0) AS Base_AMT

		    FROM COST_LINES a

		),

		FIX AS

		(

		    SELECT

		        d.*,

		        SUM(d.Base_AMT) OVER

		          (PARTITION BY yyyymm,site,sel_code,구분,model,expen_sel) AS Sum_Base_AMT

		    FROM DIST d

		)

		UPDATE t

		   SET t.RMAIN_QTY = CASE WHEN f.RN = 1 THEN f.TOT_QTY ELSE 0 END,

		       t.RMAIN_AMT = (f.Base_AMT

		                      + CASE WHEN f.RN = 1 THEN (ROUND(f.TOT_AMT,0) - f.Sum_Base_AMT) ELSE 0 END)

		FROM DOI_COST t

		JOIN FIX f

		  ON t.yyyymm    = f.yyyymm

		 AND t.site      = f.site

		 AND t.sel_code  = f.sel_code

		 AND t.구분      = f.구분

		 AND t.model     = f.model

		 AND t.expen_sel = f.expen_sel

		 AND t.acct_name = f.acct_name

		 AND t.item_name = f.item_name

		WHERE t.ACCT_NAME <> 'CST';



		SET @Message = @Message + CHAR(10) + CHAR(10)

		             + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

		             + N'- 재공평가(DOI_COST) 테이블에 ' + @YYYYMM + N'월 '

		             + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END

		             + N' RMA IN 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 업데이트 했습니다';	

	*/

        SET @Message = @Message + CHAR(10)

                     + N'  [END]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                     + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '

                     + CASE WHEN @SITE = 'HQ' THEN N'본사' ELSE N'VINA' END

                     + N' 제품BOH 집계 완료했습니다';		   

                    

        ---------------------------------------------------------------------

        -- 실행로그

        ---------------------------------------------------------------------

        INSERT INTO doi_execlog

        (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)

        VALUES (@YYYYMM, @SEL_CODE, @SITE, GETDATE(), @Message, 'system', '제품 수불', 'UP_VN_STOCK_BOH', 'SUCCESS');



        COMMIT TRANSACTION;



        SELECT @Message AS retMessage;

        RETURN 0;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;



        SET @Message = @Message + CHAR(10)

             + N'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)

                   + ERROR_MESSAGE();



INSERT INTO doi_execlog

        (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)

        VALUES (@YYYYMM, @SEL_CODE, @SITE, GETDATE(), @Message, 'system', '제품 수불', 'UP_VN_STOCK_BOH', 'FAIL');



        SELECT @Message AS retMessage;

        RETURN -1;

    END CATCH

END;



