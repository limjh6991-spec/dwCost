CREATE OR ALTER Procedure VN_ManufacturingExpenseByDept_Cum(
	@FROM_YYYYMM varchar(10),
	@TO_YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

		-- 1) 금액(#vamt) : 재료(원재료=doi_mat_amt 단일) + 노무/경비(doi_dept_cost 세분 브리지)  (기간 누적)
		--    항목 = 세분(경영계획과목 우선, 없으면 상위계정과목), 섹션 = 계정코드(6272재료,622직접노무,627간접경비)
		IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
		SELECT dept_name, sec, item, MIN(iord) iord, SUM(amt) amt
		INTO #vamt
		FROM (
			SELECT N'제조공통' dept_name, 1 sec, N'원재료비' item, CAST(0 AS bigint) iord, SUM(in_amt) amt
				FROM doi_mat_amt WHERE yyyymm BETWEEN @FROM_YYYYMM AND @TO_YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
			UNION ALL
			SELECT LTRIM(RTRIM(d.코스트센터)) dept_name,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN 1
					 WHEN LEFT(d.계정코드,3)='622' THEN 2
					 WHEN LEFT(d.계정코드,3)='627' THEN 3 ELSE 9 END sec,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN N'부재료비 (6272)' ELSE REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') END item,
				MIN(TRY_CONVERT(bigint,d.계정코드)) iord,
				SUM(d.차변금액 - d.대변금액) amt
			FROM doi_dept_cost d
			JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.acct=d.계정코드
			WHERE d.yyyymm BETWEEN @FROM_YYYYMM AND @TO_YYYYMM AND d.site=@SITE AND d.비용구분='제조'
			  AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
			  AND LEFT(d.계정코드,3) IN ('622','627')
			  AND ISNULL(REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N''),'')<>''
			GROUP BY LTRIM(RTRIM(d.코스트센터)),
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN 1 WHEN LEFT(d.계정코드,3)='622' THEN 2 WHEN LEFT(d.계정코드,3)='627' THEN 3 ELSE 9 END,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN N'부재료비 (6272)' ELSE REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') END
		) t
		WHERE sec IN (1,2,3)
		GROUP BY dept_name, sec, item;

		-- 2) 부서 목록
		IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
		SELECT dept_name, ord INTO #vdept FROM (
			SELECT DISTINCT dept_name, CASE WHEN dept_name=N'제조공통' THEN 0 ELSE 1 END ord FROM #vamt
			UNION SELECT N'합계', 2
		) t;

		-- 3) 골격(섹션 헤더 + 세분항목, (N) 번호)
		IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
		CREATE TABLE #vskel(rn int, sec int, item nvarchar(200), gubun nvarchar(200));
		INSERT #vskel(rn, sec, item, gubun)
		SELECT sec*10000 + seq*10, sec, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
		FROM (VALUES
			(1,1,N'원재료비'),(1,2,N'부재료비 (6272)'),
			(2,1,N'제)급여-직원'),(2,2,N'제)상여금'),(2,3,N'제)제수당'),(2,4,N'제)퇴직급여'),(2,5,N'제)주식보상비용'),(2,6,N'제)급여-사회보험료'),(2,7,N'제)급여-건강보험'),(2,8,N'제)급여-노동자실업보험료'),(2,9,N'제)급여-노동자노조비'),(2,10,N'제)급여-개인소득세'),(2,11,N'제)급여-기타'),
			(3,1,N'제)직원급여'),(3,2,N'제)상여금'),(3,3,N'제)제수당'),(3,4,N'제)퇴직급여'),(3,5,N'제)주식보상비용'),(3,6,N'제)급여-사회보험료'),(3,7,N'제)급여-건강보험'),(3,8,N'제)급여-노동자실업보험료'),(3,9,N'제)급여-노동자노조비'),(3,10,N'제)급여-개인소득세'),(3,11,N'제)급여-기타'),
			(3,12,N'제)급여-기타비용'),(3,13,N'제)여비교통비'),(3,14,N'제)통신비'),(3,15,N'제)수도광열비'),(3,16,N'제)전력비'),(3,17,N'제)감가상각비'),(3,18,N'제)지급임차료'),(3,19,N'제)수선비'),(3,20,N'제)보험료'),(3,21,N'제)차량유지비'),(3,22,N'제)운반비'),(3,23,N'제)교육훈련비'),
			(3,24,N'제)도서인쇄비'),(3,25,N'제)소모품비'),(3,26,N'제)지급수수료'),(3,27,N'제)외주가공비'),(3,28,N'제)사용권자산감가상각비'),(3,29,N'제)검사비'),(3,30,N'제)견본비'),(3,31,N'기술지원 및 기술이전비')
		) v(sec,seq,item);
		INSERT #vskel(rn, sec, item, gubun) VALUES
			(10000,1,N'__H1',N'  I. 재료비'),
			(20000,2,N'__H2',N'  II. 직접노무비'),
			(30000,3,N'__H3',N'  III. 간접제조경비'),
			(90000,9,N'__T', N'  IV. 당기총제조원가');

		-- 4) 소스테이블
		IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
		;WITH matched AS (SELECT v.dept_name, v.sec, sk.rn, v.amt FROM #vamt v JOIN #vskel sk ON sk.sec=v.sec AND sk.item=v.item),
		 amt_item AS (SELECT dept_name, rn, SUM(amt) amt FROM matched GROUP BY dept_name, rn),
		 amt_hdr AS (SELECT dept_name, sec*10000 rn, SUM(amt) amt FROM matched GROUP BY dept_name, sec),
		 amt_tot AS (SELECT dept_name, 90000 rn, SUM(amt) amt FROM matched GROUP BY dept_name),
		 amt_all AS (SELECT * FROM amt_item UNION ALL SELECT * FROM amt_hdr UNION ALL SELECT * FROM amt_tot)
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
