CREATE   PROCEDURE UP_DOI_CarryOver
(
      @YYYYMM       VARCHAR(6)
    , @SITE         VARCHAR(5)
    , @PREV_YYYYMM  VARCHAR(6) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET LOCK_TIMEOUT 10000;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @Message NVARCHAR(MAX) = N'';
    DECLARE @status  VARCHAR(30) = 'OK';

    -- 테이블별 처리 건수
    DECLARE @nAcct  INT = 0,
            @nDept  INT = 0,
            @nBom   INT = 0,
            @nModel INT = 0;

    BEGIN TRY
        ---------------------------------------------------------------------
        -- 0) 이전월 자동 계산
        ---------------------------------------------------------------------
        IF (@PREV_YYYYMM IS NULL OR @PREV_YYYYMM = '')
        BEGIN
            DECLARE @d DATE = CONVERT(DATE, LEFT(@YYYYMM,4) + '-' + RIGHT(@YYYYMM,2) + '-01');
            SET @d = DATEADD(MONTH, -1, @d);
            SET @PREV_YYYYMM = CONVERT(VARCHAR(6), @d, 112);
        END

        SET @Message = N'[START] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
                     + CHAR(9) + N'- 기준정보 데이타 이월: ' + @PREV_YYYYMM + N' → ' + @YYYYMM
                     + N' (' + CASE WHEN @SITE='HQ' THEN N'본사' ELSE N'VINA' END + N')';

        BEGIN TRANSACTION;

        ---------------------------------------------------------------------
        -- 1) DOI_ACCT (동적 컬럼 복사)
        ---------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM DOI_ACCT WHERE YYYYMM=@YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 원가계정정보(DOI_ACCT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 이미 존재합니다';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM DOI_ACCT WHERE YYYYMM=@PREV_YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 원가계정정보(DOI_ACCT) 테이블에 '+@PREV_YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
        END
        ELSE
        BEGIN
            DECLARE @sql NVARCHAR(MAX), @colsInsert NVARCHAR(MAX), @colsSelect NVARCHAR(MAX);

            ;WITH C AS (
                SELECT c.name, c.column_id
                FROM sys.columns c
                WHERE c.object_id = OBJECT_ID(N'DOI_ACCT')
                  AND c.is_identity = 0
                  AND c.is_computed = 0
            )
            SELECT
                @colsInsert = STRING_AGG(QUOTENAME(name), ',') WITHIN GROUP (ORDER BY column_id),
                @colsSelect = STRING_AGG(
                                CASE WHEN name = 'YYYYMM' THEN '@YYYYMM AS ' + QUOTENAME(name)
                                     ELSE QUOTENAME(name)
                                END, ','
                              ) WITHIN GROUP (ORDER BY column_id)
            FROM C;

            SET @sql = N'
                INSERT INTO DOI_ACCT (' + @colsInsert + N')
                SELECT ' + @colsSelect + N'
                FROM DOI_ACCT
                WHERE YYYYMM=@PREV_YYYYMM AND SITE=@SITE;
            ';

            EXEC sp_executesql
                @sql,
                N'@YYYYMM VARCHAR(6), @PREV_YYYYMM VARCHAR(6), @SITE VARCHAR(5)',
                @YYYYMM=@YYYYMM, @PREV_YYYYMM=@PREV_YYYYMM, @SITE=@SITE;

            SET @nAcct = @@ROWCOUNT;
            SET @Message += CHAR(10) + N' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
                     +   ' 원가계정정보(DOI_ACCT) 테이블 이월 완료 (' + CAST(@nAcct AS NVARCHAR(20)) + N'건)';
        END

        ---------------------------------------------------------------------
        -- 2) DOI_DEPT
        ---------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM DOI_DEPT WHERE YYYYMM=@YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서정보(DOI_DEPT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 이미 존재합니다';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM DOI_DEPT WHERE YYYYMM=@PREV_YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서정보(DOI_DEPT) 테이블에 '+@PREV_YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
        END
        ELSE
        BEGIN
            DECLARE @sql2 NVARCHAR(MAX), @colsInsert2 NVARCHAR(MAX), @colsSelect2 NVARCHAR(MAX);

            ;WITH C AS (
                SELECT c.name, c.column_id
                FROM sys.columns c
                WHERE c.object_id = OBJECT_ID(N'DOI_DEPT')
                  AND c.is_identity = 0
                  AND c.is_computed = 0
            )
            SELECT
                @colsInsert2 = STRING_AGG(QUOTENAME(name), ',') WITHIN GROUP (ORDER BY column_id),
                @colsSelect2 = STRING_AGG(
                                CASE WHEN name = 'YYYYMM' THEN '@YYYYMM AS ' + QUOTENAME(name)
                                     ELSE QUOTENAME(name)
                                END, ','
                              ) WITHIN GROUP (ORDER BY column_id)
            FROM C;

            SET @sql2 = N'
                INSERT INTO DOI_DEPT (' + @colsInsert2 + N')
                SELECT ' + @colsSelect2 + N'
                FROM DOI_DEPT
                WHERE YYYYMM=@PREV_YYYYMM AND SITE=@SITE;
            ';

            EXEC sp_executesql
                @sql2,
                N'@YYYYMM VARCHAR(6), @PREV_YYYYMM VARCHAR(6), @SITE VARCHAR(5)',
                @YYYYMM=@YYYYMM, @PREV_YYYYMM=@PREV_YYYYMM, @SITE=@SITE;

            SET @nDept = @@ROWCOUNT;
            SET @Message += CHAR(10) + N' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
                     + ' 부서정보(DOI_DEPT) 테이블 이월 완료 (' + CAST(@nDept AS NVARCHAR(20)) + N'건)';
        END

        ---------------------------------------------------------------------
        -- 3) DOI_BOM_MAST
        ---------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM DOI_BOM_MAST WHERE YYYYMM=@YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 자재정보(DOI_BOM_MAST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 이미 존재합니다';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM DOI_BOM_MAST WHERE YYYYMM=@PREV_YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 자재정보(DOI_BOM_MAST) 테이블에 '+@PREV_YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
        END
        ELSE
        BEGIN
            DECLARE @sql3 NVARCHAR(MAX), @colsInsert3 NVARCHAR(MAX), @colsSelect3 NVARCHAR(MAX);

            ;WITH C AS (
                SELECT c.name, c.column_id
                FROM sys.columns c
                WHERE c.object_id = OBJECT_ID(N'DOI_BOM_MAST')
                  AND c.is_identity = 0
                  AND c.is_computed = 0
            )
            SELECT
                @colsInsert3 = STRING_AGG(QUOTENAME(name), ',') WITHIN GROUP (ORDER BY column_id),
                @colsSelect3 = STRING_AGG(
                                CASE WHEN name = 'YYYYMM' THEN '@YYYYMM AS ' + QUOTENAME(name)
                                     ELSE QUOTENAME(name)
                                END, ','
                              ) WITHIN GROUP (ORDER BY column_id)
            FROM C;

            SET @sql3 = N'
                INSERT INTO DOI_BOM_MAST (' + @colsInsert3 + N')
                SELECT ' + @colsSelect3 + N'
                FROM DOI_BOM_MAST
                WHERE YYYYMM=@PREV_YYYYMM AND SITE=@SITE;
';

            EXEC sp_executesql
                @sql3,
                N'@YYYYMM VARCHAR(6), @PREV_YYYYMM VARCHAR(6), @SITE VARCHAR(5)',
                @YYYYMM=@YYYYMM, @PREV_YYYYMM=@PREV_YYYYMM, @SITE=@SITE;

            SET @nBom = @@ROWCOUNT;
            SET @Message += CHAR(10) + N' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
                     + ' 자재정보(DOI_BOM_MAST) 테이블 이월 완료 (' + CAST(@nBom AS NVARCHAR(20)) + N'건)';
        END

        ---------------------------------------------------------------------
        -- 4) DOI_MODEL_MAST (현재월 생성)
        ---------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM DOI_MODEL_MAST WHERE YYYYMM=@YYYYMM AND SITE=@SITE)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 면적기준정보(DOI_MODEL_MAST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 이미 존재합니다';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM DW_PRODUCT_MAST)
        BEGIN
			SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품정보(DW_PRODUCT_MAST) 테이블에 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
        END
        ELSE
        BEGIN
            ;WITH Spec_split1 AS (
                SELECT
                    Model,
                    UPPER(Spec) AS spec,
                    Inch, Glass_thick, Sheet, Block, Cell, RUN_SIZE,
                    SUBSTRING(Spec, 1, PATINDEX('%[*|×|X|x]%', Spec) - 1) AS x,
                    SUBSTRING(Spec, PATINDEX('%[*|×|X|x]%', Spec) + 1, LEN(Spec)) AS y
                FROM dw_product_mast
                WHERE PATINDEX('%[*|×|X|x]%', Spec) > 0
            ),
            Spec_split2 AS (
                SELECT
                    model,
                    spec, Inch, Glass_thick, Sheet, Block, Cell, RUN_SIZE,
                    REPLACE(
                        CASE WHEN PATINDEX('%[±|M]%', x) = 0 THEN x
                             ELSE SUBSTRING(x, 1, PATINDEX('%[±|M]%', x) - 1) END
                    , ',', '.') AS x,
                    REPLACE(
                        CASE WHEN PATINDEX('%[±|M]%', y) = 0 THEN y
                             ELSE SUBSTRING(y, 1, PATINDEX('%[±|M]%', y) - 1) END
                    , ',', '.') AS y,
                    ROW_NUMBER() OVER (PARTITION BY model ORDER BY x DESC, y DESC) AS rn
                FROM Spec_split1
            ),
            Spec_split3 AS (
                SELECT
                    @YYYYMM AS YYYYMM,
                    'ACTUAL' AS SEL_CODE,
                    @SITE AS SITE,
                    model,
                    spec, Inch, Glass_thick, Sheet, Block, Cell, RUN_SIZE,
                    x,
                    REPLACE(
                        CASE WHEN PATINDEX('%*%', y) = 0 THEN y
                             ELSE SUBSTRING(y, 1, PATINDEX('%*%', y) - 1) END
                    , ',', '.') AS y
                FROM Spec_split2
                WHERE rn = 1
            )
            INSERT INTO DOI_MODEL_MAST
            (
                YYYYMM, SEL_CODE, SITE, MODEL,
                SPEC, INCH, GLASS_THICK, SHEET, BLOCK, CELL, RUN_SIZE,
                X, Y, XY
            )
            SELECT
                YYYYMM, SEL_CODE, SITE, model,
                spec, Inch, Glass_thick, Sheet, Block, Cell, RUN_SIZE,
                x, y,
                CAST(x AS NUMERIC(38,25)) * CAST(y AS NUMERIC(38,25)) AS xy
            FROM Spec_split3;

            SET @nModel = @@ROWCOUNT;
            SET @Message += CHAR(10) + N' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
                     + ' 면적기준정보(DOI_MODEL_MAST) 테이블 이월 완료 (' + CAST(@nModel AS NVARCHAR(20)) + N'건)';
        END

        COMMIT TRANSACTION;

        SET @Message += CHAR(10) + N'[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
  + CHAR(9) + N'- ' + @YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '기준정보 데이타 이월 완료했습니다';

        SELECT
            'OK' AS status,
            @Message AS retMessage,
            @PREV_YYYYMM AS prevYyyymm,
            @YYYYMM AS curYyyymm,
       @SITE AS site,
            @nAcct AS ins_acct,
            @nDept AS ins_dept,
            @nBom  AS ins_bom,
            @nModel AS ins_model;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @Message += CHAR(10) + N'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120)
                      + CHAR(9) + ERROR_MESSAGE();

        SELECT
            'ERROR' AS status,
            @Message AS retMessage,
            @PREV_YYYYMM AS prevYyyymm,
            @YYYYMM AS curYyyymm,
            @SITE AS site;

        RETURN -1;
    END CATCH
END;
