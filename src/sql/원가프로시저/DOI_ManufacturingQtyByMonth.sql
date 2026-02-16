CREATE          Procedure DOI_ManufacturingQtyByMonth(
	@YYYY varchar(10),
 	@SITE varchar(4)
 )
AS
BEGIN
	BEGIN TRY
--		BEGIN TRANSACTION;
--		DECLARE @YYYY VARCHAR(4) = '2025';
		DECLARE @Columns NVARCHAR(MAX);
		DECLARE @PivotColumns NVARCHAR(MAX);
		DECLARE @SQL NVARCHAR(MAX);
		
		-- 1. 월별 컬럼 및 연간 컬럼 동적 생성
		WITH Months AS (
		    SELECT 
		        CAST(@YYYY + '0101' AS DATE) AS StartDate,
		        CAST(@YYYY + '1201' AS DATE) AS EndDate
		)
		SELECT 
		    @PivotColumns = STRING_AGG(QUOTENAME(월), ', ') WITHIN GROUP (ORDER BY 월번호) + ', [합계]',
		    @Columns = STRING_AGG('coalesce('+QUOTENAME(월)+',0) as' +QUOTENAME(월),', ') WITHIN GROUP (ORDER BY 월번호) + ', coalesce([합계],0) as [합계]'  
		FROM (
		    SELECT 
		        월번호,
		        CAST(월번호 AS VARCHAR) + '월' AS 월
		    FROM (
		        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS 월번호
		        FROM master.dbo.spt_values
		        WHERE type = 'P' AND number BETWEEN 1 AND 12
		    ) AS M
		) AS MonthlyCols; --select @PivotColumns;select  @Columns
		
		-- 2. 메인 쿼리
		SET @SQL = N'
		WITH GEN_YYYYMM AS (
		    SELECT 
		        DATEADD(MONTH, number-1, DATEFROMPARTS('''+@YYYY+''', 1, 1)) AS DT,
		        FORMAT(DATEADD(MONTH, number-1, DATEFROMPARTS('''+@YYYY+''', 1, 1)), ''yyyyMM'') AS YYYYMM,
		        number AS 월번호,
		        CAST(number AS VARCHAR) + ''월'' AS 월표시
		    FROM master.dbo.spt_values
		    WHERE type = ''P'' 
		      AND number BETWEEN 1 AND 12
		   UNION ALL   
		   SELECT '''+@YYYY+''','''+@YYYY+''',3,''합계''
		),
		GubunList AS (
		    SELECT * FROM (VALUES
		        (1, ''기초(BOH)''),
		        (2, ''투입(IN)''),
		        (4, ''출고(OUT)''),
		        (5, ''재고(EOH)''),
		        (7, ''기타(LOSS)''),
		        (8, ''LOSS율'')
		    ) AS t(rn, gubun)
		),
		MonthlyData AS (
		    SELECT 
		        g.rn,
		        g.gubun,
		        d.model,
		        d.구분,
		        d.dw_site,
		        d.도우모델,
				d.Inch,
		        m.월번호,
		        m.월표시 AS 월,
		        COALESCE(CASE 
		            WHEN g.rn = 1 THEN COALESCE(d.BOH_MONTH, 0)
		            WHEN g.rn = 2 THEN COALESCE(d.IN_MONTH, 0)
		            WHEN g.rn = 4 THEN COALESCE(d.OUT_MONTH, 0)
		            WHEN g.rn = 5 THEN COALESCE(d.EOH_MONTH, 0)
		            WHEN g.rn = 7 THEN COALESCE(d.LOSS_MONTH, 0)
		            WHEN g.rn = 8 THEN 
		                CASE 
		                    WHEN COALESCE(d.LOSS_MONTH, 0) = 0 THEN 0
		                    ELSE ROUND((COALESCE(d.BOH_MONTH, 0) + COALESCE(d.IN_MONTH, 0)) / NULLIF(d.LOSS_MONTH, 0), 2)
		                END
		        END,0) AS QTY
		    FROM GEN_YYYYMM m
		    CROSS JOIN GubunList g
		    LEFT JOIN doi_prod_subul d 
		        ON m.YYYYMM = d.YYYYMM 
		        AND g.rn IN (1, 2, 4, 5, 7, 8)
		    WHERE d.YYYYMM LIKE '''+@YYYY+''' + ''%''
		        OR d.YYYYMM IS NULL
		),
		YearlyData AS (
		    SELECT 
		        g.rn,
		        g.gubun,
		        d.model,
		        d.구분,
		        d.dw_site,
		        d.도우모델,
				d.Inch,
		        13 AS 월번호,
		        ''합계'' AS 월,
		        CASE WHEN g.rn < 8  THEN
				        SUM(CASE 
				            WHEN g.rn = 1 THEN COALESCE(d.BOH_MONTH, 0)
				            WHEN g.rn = 2 THEN COALESCE(d.IN_MONTH, 0)
				            WHEN g.rn = 4 THEN COALESCE(d.OUT_MONTH, 0)
				            WHEN g.rn = 5 THEN COALESCE(d.EOH_MONTH, 0)
				            WHEN g.rn = 7 THEN COALESCE(d.LOSS_MONTH, 0) END) 
			         WHEN g.rn = 8 THEN 
		                CASE 
		                    WHEN SUM(COALESCE(d.LOSS_MONTH, 0)) = 0 THEN 0
		                    ELSE ROUND((SUM(COALESCE(d.BOH_MONTH, 0)) + SUM(COALESCE(d.IN_MONTH, 0))) 
		                              / NULLIF(SUM(COALESCE(d.LOSS_MONTH, 0)), 0), 2)
		                END
		        END AS QTY
		    FROM GubunList g
		    LEFT JOIN doi_prod_subul d ON d.YYYYMM LIKE '''+@YYYY+''' + ''%''
		    WHERE g.rn IN (1, 2, 4, 5, 7, 8)
		    GROUP BY g.rn, g.gubun, d.model, d.구분, d.dw_site, d.도우모델,d.Inch
		),
		AllData AS (
		    SELECT * FROM MonthlyData
		    UNION ALL
		    SELECT * FROM YearlyData
		)
		SELECT 
		    model,
		    구분,
		    dw_site,
		    도우모델,
			Inch,
		    gubun,
		    ' + @Columns + '
		FROM (
		    SELECT 
		        model,
		        구분,
		        dw_site,
		        도우모델,
		        gubun,
				Inch,
		        월,
		        SUM(QTY) AS QTY
		    FROM AllData
		    WHERE 도우모델 IS NOT NULL
		    GROUP BY model, 구분, dw_site, 도우모델, Inch, gubun, 월
		) AS SourceTable
		PIVOT (
		    SUM(QTY)
		    FOR 월 IN (' + @PivotColumns + ')
		) AS PivotTable
		ORDER BY 구분 DESC, 도우모델, 
		    CASE gubun
		        WHEN ''기초(BOH)'' THEN 1
		        WHEN ''투입(IN)'' THEN 2
		        WHEN ''출고(OUT)'' THEN 4
		        WHEN ''재고(EOH)'' THEN 6
		        WHEN ''기타(LOSS)'' THEN 7
		        WHEN ''LOSS율'' THEN 8
		        ELSE 9
		    END;
		';
		
--	PRINT @SQL;
	EXEC sp_executesql @SQL;
	END TRY
	
	BEGIN CATCH
--	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;	
