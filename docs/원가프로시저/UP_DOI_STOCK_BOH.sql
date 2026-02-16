CREATE             PROCEDURE UP_DOI_STOCK_BOH
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

    BEGIN TRY
        ---------------------------------------------------------------------
        -- START LOG
        ---------------------------------------------------------------------
        SET @Message =  N'[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
                      + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '
                      + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
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
                         + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
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
                             + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
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
                         + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
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
                     + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
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
                            CASE WHEN RIGHT(a.model_type,1)='P' THEN '양산' ELSE '개발' END AS 구분,
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
                            (a.out_etc + a.out_moving) * b.out_단가 AS Ori_OutEtc_amt,
                            ROUND((a.out_etc + a.out_moving) * b.out_단가,0) AS Base_OutEtc_amt,
                            'model_1' AS 조건,
                            b.inch,
                            a.boh,
                            a.[input],
                            a.[out],
                            a.eoh,
                            a.input_etc AS in_etc,
                            (a.out_etc + a.out_moving) AS out_etc,
                            b.out_단가
                        FROM DOI_STOCK a
                        INNER JOIN MODEL_OUT단가 b
                          ON a.model = b.model
                         AND ( b.구분 = CASE WHEN RIGHT(a.model_type,1)='P' THEN '양산' ELSE '개발' END
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
                            CASE WHEN RIGHT(a.model_type,1)='P' THEN '양산' ELSE '개발' END AS 구분,
                            a.model,
                            a.model_type,
                            b.expen_sel,
                            b.expen_sel명,
                            b.acct_name,
                            b.item_name,
                            a.stock,
                            a.input_etc * b.out_단가 AS Ori_InEtc_amt,
                            ROUND(a.input_etc * b.out_단가,0) AS Base_InEtc_amt,
                            (a.out_etc + a.out_moving) * b.out_단가 AS Ori_OutEtc_amt,
                            ROUND((a.out_etc + a.out_moving) * b.out_단가,0) AS Base_OutEtc_amt,
                            'model_1' AS 조건,
                            b.inch,
                            a.boh,
                            a.[input],
                            a.[out],
                            a.eoh,
                            a.input_etc AS in_etc,
                            (a.out_etc + a.out_moving) AS out_etc,
                            b.out_단가
                        FROM DOI_STOCK a
                        INNER JOIN MODEL_OUT단가 b
                          ON a.model = b.model
                         AND ( b.구분 = CASE WHEN RIGHT(a.model_type,1)='P' THEN '양산' ELSE '개발' END
                               OR b.model_구분 = 1 )
                        WHERE a.YYYYMM = @YYYYMM
                          AND a.SITE   = @SITE
                          AND NOT EXISTS (
                              SELECT 1
                              FROM MODEL_OUT단가 c
                              WHERE c.model = b.model
                                AND c.구분 = CASE WHEN RIGHT(a.model_type,1)='D' THEN '개발' ELSE '양산' END
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
                            CASE WHEN RIGHT(a.model_type,1)='P' THEN '양산' ELSE '개발' END AS 구분,
                            a.model,
                            a.model_type,
                            c.expen_sel,
                            c.expen_sel명,
                            c.acct_name,
                            c.item_name,
                            a.stock,
                            a.input_etc * c.out_단가 AS Ori_InEtc_amt,
                            ROUND(a.input_etc * c.out_단가,0) AS Base_InEtc_amt,
                            (a.out_etc + a.out_moving) * c.out_단가 AS Ori_OutEtc_amt,
                            ROUND((a.out_etc + a.out_moving) * c.out_단가,0) AS Base_OutEtc_amt,
                            'inch' AS 조건,
                            b.inch,
                            a.boh,
                            a.[input],
                            a.[out],
                            a.eoh,
                            a.input_etc as in_etc,
                            (a.out_etc + a.out_moving) AS out_etc,
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
            WHERE yyyymm   = '202511'
              AND site     = 'HQ'
              AND sel_code = 'ACTUAL'
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
            f.inch, f.boh, f.[input], f.[out], f.eoh, f.in_etc, f.out_etc, f.out_단가
        FROM FIX f;

        SET @Message = @Message + CHAR(10)
                     + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
                     + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '
                     + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
                     + N' 제품BOH 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 입력했습니다';

 --2026.01.17 22:21        
 update	doi_stock_boh
set
	OutEtc_Amt = round(out_etc * case when out_단가 != 0 then out_단가 else (boh_amt + input + InEtc_Amt)/(boh + [input] + in_etc) end, 0)
WHERE
	yyyymm = '202511'
	and site = 'HQ'
	and sel_code = 'ACTUAL'
	and boh = eoh + out_etc
	and out_etc != 0
	and out_단가 = 0;
        
        SET @Message = @Message + CHAR(10)
                     + N'  [END]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
                     + N'- 제품BOH집계(DOI_STOCK_BOH) 테이블에 ' + @YYYYMM + N'월 '
                     + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
                     + N' 제품BOH 집계 완료했습니다';

        ---------------------------------------------------------------------
        -- 제품수불금액 집계 호출
        ---------------------------------------------------------------------
        DECLARE @Ret_M nvarchar(MAX) = N'';
        EXEC UP_DOI_STOCK_COST
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
          AND site   = @SITE;

        SET @Message = @Message + CHAR(10) + CHAR(10)
                     + N' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
                     + N'- OUT단가(DOI_STUC) 테이블에 ' + @YYYYMM + N'월 '
                     + CASE WHEN @SITE ='HQ' THEN N'본사' ELSE N'VINA' END
                     + N' 단가 데이타 ' + CAST(@@ROWCOUNT AS VARCHAR) + N'건을 삭제 했습니다';

       	/*select
			s.YYYYMM,
			s.SEL_CODE,
			s.SITE,
			s.구분,
			s.MODEL,		
			s.EXPEN_SEL,
			s.EXPEN_SEL명,
			s.ACCT_NAME,
			'STCO' as SRC,
			(s.BOH_AMT+s.IN_AMT) AMT,		
			(s.BOH+s.[INPUT]) as QTY,
			(s.BOH_AMT+s.IN_AMT) / NULLIF((s.BOH+s.[INPUT]),0) AS OUT_UNITCOST -- into DOI_STUC
		from	doi_stco s
		where 1=1
			and yyyymm = '202508'
			and site = 'HQ'
			and sel_code = 'ACTUAL'
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
			c.ACCT_NAME,
			'COST' as SRC,
			(c.BOH + c.[IN]) AMT,		
			c.ADJ_QTY as QTY, 
			--(c.BOH + c.[IN]) / ((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty) ,
			c.OUT_단가 as OUT_UNITCOST 
			from doi_cost c
				where 1=1
			and c.yyyymm = '202508'
			and c.site = 'HQ'
			and c.sel_code = 'ACTUAL'
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
			  )*/             
                    
        ---------------------------------------------------------------------
        -- 실행로그
        ---------------------------------------------------------------------
        INSERT INTO doi_execlog
        VALUES (@YYYYMM, @SEL_CODE, @SITE, GETDATE(), @Message, 'system', '제품 수불', 'UP_DOI_STOCK_BOH', 'SUCCESS');

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
        VALUES (@YYYYMM, @SEL_CODE, @SITE, GETDATE(), @Message, 'system', '제품 수불', 'UP_DOI_STOCK_BOH', 'FAIL');

        SELECT @Message AS retMessage;
        RETURN -1;
    END CATCH
END;
