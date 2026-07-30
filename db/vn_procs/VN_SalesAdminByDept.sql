CREATE OR ALTER Procedure VN_SalesAdminByDept(
	@YYYYMM varchar(10),
	@SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

		-- 1) 금액(#vamt) : doi_dept_cost(판관, 센터채움 차변-대변) → doi_acct.상위계정과목
		IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
		SELECT LTRIM(RTRIM(d.코스트센터)) dept_name, COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목) item, SUM(d.차변금액) amt
		INTO #vamt
		FROM doi_dept_cost d
		JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.acct=d.계정코드
		WHERE d.yyyymm=@YYYYMM AND d.site=@SITE AND d.비용구분=N'판관'
		  AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
		  AND ISNULL(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),'')<>''
		GROUP BY LTRIM(RTRIM(d.코스트센터)), COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목);

		-- 2) 부서 목록 (데이터 부서 + 합계)
		IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
		SELECT dept_name, ord INTO #vdept FROM (
			SELECT DISTINCT dept_name, 1 ord FROM #vamt
			UNION SELECT N'합계', 2
		) t;

		-- 3) 고정항목
		IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
		CREATE TABLE #vskel(rn int, item nvarchar(200), gubun nvarchar(200));
		INSERT #vskel(rn, item, gubun)
		SELECT seq*10, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
		FROM (VALUES
			(1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
			(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
			(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
			(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
			(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
			(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비')
		) v(seq,item);
		INSERT #vskel(rn, item, gubun) VALUES (0, N'__T', N'합계');

		-- 4) 소스테이블
		IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
		;WITH item_amt AS (SELECT v.dept_name, sk.rn, SUM(v.amt) amt FROM #vamt v JOIN #vskel sk ON sk.item=v.item GROUP BY v.dept_name, sk.rn),
		 tot AS (SELECT dept_name, 0 rn, SUM(amt) amt FROM item_amt GROUP BY dept_name),
		 amt_all AS (SELECT * FROM item_amt UNION ALL SELECT * FROM tot)
		SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
		INTO #vsource
		FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
		LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

		-- 5) 동적 PIVOT (부서 컬럼)
		SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vColumns = N'[' + @vColumns + N']';
		SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce([' FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');
		SET @vSQL = N'
SELECT ' + @vNullCols + N'
FROM ( SELECT dept_name, rn, gubun, amt FROM #vsource
       UNION ALL SELECT N''합계'' dept_name, rn, gubun, SUM(amt) amt FROM #vsource GROUP BY rn, gubun ) AS S
PIVOT ( SUM(amt) FOR dept_name IN (' + @vColumns + N') ) AS P
ORDER BY rn;';
		EXEC sp_executesql @vSQL;

		DROP TABLE #vsource; DROP TABLE #vskel; DROP TABLE #vamt; DROP TABLE #vdept;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

