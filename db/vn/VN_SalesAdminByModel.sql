CREATE OR ALTER PROCEDURE VN_SalesAdminByModel(
	@YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @Columns NVARCHAR(MAX);
		DECLARE @Null_Columns NVARCHAR(MAX);
		DECLARE @SQL NVARCHAR(MAX);
		DECLARE @Prod_Rate DECIMAL(18,6) = 0;
		DECLARE @Dev_Rate  DECIMAL(18,6) = 0;

		-- 1) 금액(#amt) : doi_smce_cost → doi_dept_cost(판관) 브리지 → doi_acct.상위계정과목
		IF OBJECT_ID('tempdb..#amt') IS NOT NULL DROP TABLE #amt;
		SELECT b.구분 + replace(ISNULL(NULLIF(LTRIM(RTRIM(mc.도우코드)),''),b.model),' ','') model, COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목) item, SUM(b.dist_amt) amt
		INTO #amt
		FROM doi_smce_cost b
		LEFT JOIN (SELECT DISTINCT MODEL, 도우코드 FROM DOI_VN_STCO WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE) mc ON mc.MODEL=b.model
		JOIN (SELECT yyyymm,site,계정과목,MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분=N'판관' GROUP BY yyyymm,site,계정과목) dc
			ON dc.yyyymm=b.yyyymm AND dc.site=b.site AND dc.계정과목=b.sub_name
		JOIN doi_acct a ON a.yyyymm=b.yyyymm AND a.site=b.site AND a.acct=dc.계정코드
		WHERE b.yyyymm=@YYYYMM AND b.site=@SITE AND b.sel_code=@SEL_CODE
		  AND ISNULL(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),'')<>''
		GROUP BY b.구분 + replace(ISNULL(NULLIF(LTRIM(RTRIM(mc.도우코드)),''),b.model),' ',''), COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목);

		-- 2) @Columns : 모델(구분+model) + X/Y/Z합계
		SELECT @Columns = COALESCE(@Columns + N'],[', N'') + model FROM (SELECT DISTINCT model FROM #amt UNION SELECT N'X합계' UNION SELECT N'Y합계' UNION SELECT N'Z합계') A;
		SELECT @Columns = N'[' + @Columns + N']';
		SELECT @Null_Columns = COALESCE(@Null_Columns, N'') + model + N'],0) as [' + model + N'],coalesce([' FROM (SELECT DISTINCT model FROM #amt UNION SELECT N'X합계' UNION SELECT N'Y합계' UNION SELECT N'Z합계') A;
		SELECT @Null_Columns = N'rn,gubun,' + REPLACE(N'coalesce([' + @Null_Columns + N']', N',coalesce([]', N'');

		-- 3) 골격 : 배부율(rn=0) + 판관 27개 고정항목 + 합계(rn=99990)
		IF OBJECT_ID('tempdb..#skel') IS NOT NULL DROP TABLE #skel;
		CREATE TABLE #skel(rn int, gubun nvarchar(200), item nvarchar(200));
		INSERT #skel(rn, gubun, item)
		SELECT seq*10, N'    (' + CAST(seq AS varchar(3)) + N') ' + item, item
		FROM (VALUES
			(1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
			(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
			(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
			(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
			(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
			(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비')
		) v(seq,item);
		INSERT #skel(rn, gubun, item) VALUES (0, N'    판관비 배부율 (제품별 매출비중)', N'__RATE'), (99990, N'    합계', N'__TOT');

		-- 4) 소스 : 모델 × 골격, 항목=금액 / 합계=27항목합 / 배부율=모델합/총합
		IF OBJECT_ID('tempdb..#sourceTable1') IS NOT NULL DROP TABLE #sourceTable1;
		;WITH item_amt AS (SELECT a.model, sk.rn, SUM(a.amt) amt FROM #amt a JOIN #skel sk ON sk.item=a.item GROUP BY a.model, sk.rn),
		 mtot AS (SELECT model, SUM(amt) tot FROM item_amt GROUP BY model),
		 g AS (SELECT NULLIF(SUM(tot),0) g FROM mtot)
		SELECT m.model, sk.rn, sk.gubun,
			-- 배부율(rn=0)은 4자리, 금액은 2자리값(#1 dist_amt 2자리) → 공유 CAST 18,4 (금액은 표시시 2자리 포맷)
			CAST(CASE WHEN sk.rn=0     THEN mt.tot / (SELECT g FROM g)
			          WHEN sk.rn=99990 THEN mt.tot
			          ELSE ISNULL(ia.amt,0) END AS DECIMAL(18,4)) amt
		INTO #sourceTable1
		FROM (SELECT DISTINCT model FROM #amt) m
		CROSS JOIN #skel sk
		LEFT JOIN mtot mt ON mt.model=m.model
		LEFT JOIN item_amt ia ON ia.model=m.model AND ia.rn=sk.rn;

		-- 5) 양산/개발 배부율(매출비중) : 27항목합 기준
		SELECT @Prod_Rate = SUM(CASE WHEN model LIKE N'양산%' THEN tot ELSE 0 END) / NULLIF(SUM(tot),0),
		       @Dev_Rate  = SUM(CASE WHEN model LIKE N'개발%' THEN tot ELSE 0 END) / NULLIF(SUM(tot),0)
		FROM (SELECT a.model, SUM(a.amt) tot FROM #amt a JOIN #skel sk ON sk.item=a.item GROUP BY a.model) z;

		-- 6) 동적 PIVOT
		SET @SQL = N'
SELECT ' + @Null_Columns + N'
FROM (
	select * from #sourceTable1
	union all select N''X합계'' model, rn, gubun, CASE WHEN rn=0 THEN ' + CAST(@Prod_Rate as varchar(30)) + N' ELSE sum(amt) END amt from #sourceTable1 where model like N''양산%'' group by rn, gubun
	union all select N''Y합계'' model, rn, gubun, CASE WHEN rn=0 THEN ' + CAST(@Dev_Rate as varchar(30)) + N' ELSE sum(amt) END amt from #sourceTable1 where model like N''개발%'' group by rn, gubun
	union all select N''Z합계'' model, rn, gubun, CASE WHEN rn=0 THEN 1 ELSE sum(amt) END amt from #sourceTable1 group by rn, gubun
) AS SourceTable
PIVOT ( SUM(AMT) FOR model IN (' + @Columns + N') ) AS PivotTable
order by rn;';
		EXEC sp_executesql @SQL;

		DROP TABLE #sourceTable1; DROP TABLE #skel; DROP TABLE #amt;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

