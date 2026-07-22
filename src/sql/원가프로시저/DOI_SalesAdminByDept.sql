

CREATE OR ALTER Procedure DOI_SalesAdminByDept(
	@YYYYMM varchar(10),
 	@SITE varchar(4)
 )
AS
BEGIN
		-- ============================================================
	-- [VN 전용 동적 분기] 판매관리비 부서별집계표
	--   doi_dept_cost(비용구분='판관', 센터채움 차변-대변) + doi_acct(상위계정과목/총원가_순서)
	--   상위계정과목 있는 판)계열만(금융635/기타811/손익911 자동 제외), 부서없음→관리공통
	-- ============================================================
	IF @SITE = 'VN'
	BEGIN
		BEGIN TRY
			DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

			-- 1) 항목(부서×상위계정과목) 금액
			IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
			SELECT x.dept_name, a.상위계정과목,
					MAX(TRY_CONVERT(int,NULLIF(a.총원가_순서,''))) 순서,
					SUM(d.차변금액 - d.대변금액) amt
			INTO #vamt
			FROM doi_dept_cost d
			JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.ACCT=d.계정코드
			CROSS APPLY (SELECT CASE WHEN LTRIM(RTRIM(ISNULL(d.코스트센터,'')))='' THEN N'관리공통' ELSE LTRIM(RTRIM(d.코스트센터)) END dept_name) x
			WHERE d.yyyymm=@YYYYMM AND d.site=@SITE AND d.비용구분='판관'
				AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
				AND ISNULL(a.상위계정과목,'')<>''
			GROUP BY x.dept_name, a.상위계정과목;

			-- 2) 부서 목록 : 데이터에 존재하는 부서 + 합계
			IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
			SELECT dept_name, ord INTO #vdept FROM (
				SELECT DISTINCT dept_name, CASE WHEN dept_name=N'관리공통' THEN 0 ELSE 1 END ord FROM #vamt
				UNION SELECT N'합계', 2
			) t;

			-- 3) 골격 : 합계행(rn=0) + 상위계정과목 항목(총원가_순서 정렬)
			IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
			SELECT CAST(ROW_NUMBER() OVER (ORDER BY ISNULL(순서,99), 상위계정과목)*10 AS int) rn,
					상위계정과목, N'    ' + 상위계정과목 gubun
			INTO #vskel
			FROM (SELECT 상위계정과목, MAX(순서) 순서 FROM #vamt GROUP BY 상위계정과목) t;
			INSERT #vskel(rn, 상위계정과목, gubun) VALUES (0, N'__T', N'합계');

			-- 4) 소스테이블 : 부서 × 골격 + 금액(항목/합계행)
			IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
			;WITH amt_item AS (
				SELECT v.dept_name, sk.rn, SUM(v.amt) amt
				FROM #vamt v JOIN #vskel sk ON sk.상위계정과목=v.상위계정과목
				GROUP BY v.dept_name, sk.rn
			), amt_tot AS (
				SELECT dept_name, 0 rn, SUM(amt) amt FROM #vamt GROUP BY dept_name
			), amt_all AS (
				SELECT * FROM amt_item UNION ALL SELECT * FROM amt_tot
			)
			SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
			INTO #vsource
			FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
			LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

			-- 5) 피벗 컬럼 동적 생성 (관리공통 → 센터명 → 합계)
			SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name
			FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
			SELECT @vColumns = N'[' + @vColumns + N']';

			SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce(['
			FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
			SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');

			-- 6) 동적 PIVOT (합계열 포함)
			SET @vSQL = N'
SELECT ' + @vNullCols + N'
FROM (
	SELECT dept_name, rn, gubun, amt FROM #vsource
	UNION ALL
	SELECT N''합계'' dept_name, rn, gubun, SUM(amt) amt FROM #vsource GROUP BY rn, gubun
) AS S
PIVOT ( SUM(amt) FOR dept_name IN (' + @vColumns + N') ) AS P
ORDER BY rn;';
			EXEC sp_executesql @vSQL;

			DROP TABLE #vsource; DROP TABLE #vskel; DROP TABLE #vamt; DROP TABLE #vdept;
		END TRY
		BEGIN CATCH
			SELECT ERROR_MESSAGE() AS ErrorMessage;
		END CATCH;
		RETURN;
	END;


	BEGIN TRY
		BEGIN TRANSACTION;
		--declare @YYYYMM varchar(10)='202510', @SITE varchar(4)='HQ';
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + dept_name
		FROM (SELECT TOP 500 dept_name 
				FROM (		
					select dept, dept_name from (
						select A.*, B.dept from (
							select distinct 코스트센터 dept_name from doi_dept_cost where YYYYMM = @YYYYMM and site = @SITE and 비용구분 = '판관' 
							union all 
							SELECT '합계' dept_name
						) A 
						left join (
							select distinct dept, dept_name from doi_dept where YYYYMM = @YYYYMM and site = @SITE
							union all
							SELECT '999999' dept, '합계' dept_name
						) B 
						on A.dept_name = B.dept_name
					) A 
				)A
				ORDER BY dept )AS dept_name ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + dept_name +'],0) as ['+dept_name+'],coalesce([' 
		FROM (SELECT TOP 500 dept_name 
				FROM (		
					select dept, dept_name from (
						select A.*, B.dept from (
							select distinct 코스트센터 dept_name from doi_dept_cost where YYYYMM = @YYYYMM and site = @SITE and 비용구분 = '판관' 
							union all 
							SELECT '합계' dept_name
						) A 
						left join (
							select distinct dept, dept_name from doi_dept where YYYYMM = @YYYYMM and site = @SITE
							union all 
							SELECT '999999' dept, '합계' dept_name
						) B 
						on A.dept_name = B.dept_name
					) A 
				)A
				ORDER BY dept )AS dept_name ;
			select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns


with sourceTable as (
	select X.*, COALESCE(Y.amt,0) amt from (
		select * from (
			select distinct dept_name from (
				select A.*, B.dept from (
					select distinct 코스트센터 dept_name from doi_dept_cost where YYYYMM = @YYYYMM and site = @SITE and 비용구분 = '판관' 
				) A 
				left join (
					select distinct dept, dept_name from doi_dept where YYYYMM = @YYYYMM and site = @SITE
				) B 
				on A.dept_name = B.dept_name
			) A 
		) A 
		cross join 
		(
			select 1 rn, '합계' gubun union all
			select 2 rn, '    (1) 판)임원급여' gubun union all
--			select 3 rn, '      1. 판)급여-임원' gubun union all
			select 4 rn, '    (2) 판)직원급여' gubun union all
--			select 5 rn, '      1. 판)급여-직원' gubun union all
			select 6 rn, '    (3) 판)상여금' gubun union all
--			select 7 rn, '      1. 판)상여금-직원' gubun union all
			select 8 rn, '    (4) 판)제수당' gubun union all
/*			select 9 rn, '      1. 판)제수당-연차' gubun union all
			select 10 rn, '      2. 판)제수당-일반' gubun union all*/
			select 11 rn, '    (5) 판)퇴직급여' gubun union all
/*			select 12 rn, '      1. 판)퇴직급여-임원' gubun union all
			select 13 rn, '      2. 판)퇴직급여-직원' gubun union all*/
			select 14 rn, '    (6) 판)복리후생비' gubun union all
/*			select 15 rn, '      1. 판)복리후생비-건강,장기요양보험' gubun union all
			select 16 rn, '      2. 판)복리후생비-사내식대' gubun union all
			select 17 rn, '      3. 판)복리후생비-외부식대등' gubun union all
			select 18 rn, '      4. 판)복리후생비-경조사비' gubun union all
			select 19 rn, '      5. 판)복리후생비-일반' gubun union all
			select 20 rn, '      6. 판)복리후생비-의료' gubun union all*/
			select 21 rn, '    (7) 판)여비교통비' gubun union all
/*			select 22 rn, '      1. 판)여비교통비-국내출장경비(법인)' gubun union all
			select 23 rn, '      2. 판)여비교통비-국내출장경비(기타)' gubun union all
			select 24 rn, '      3. 판)여비교통비-해외출장경비' gubun union all
			select 25 rn, '      4. 판)여비교통비-기타' gubun union all*/
			select 26 rn, '    (8) 판)접대비' gubun union all
/*			select 27 rn, '      1. 판)접대비-식대' gubun union all
			select 28 rn, '      2. 판)접대비-경조금' gubun union all
			select 29 rn, '      3. 판)접대비-일반' gubun union all*/
			select 30 rn, '    (9) 판)통신비' gubun union all
/*			select 31 rn, '      1. 판)통신비' gubun union all*/
			select 32 rn, '   (10) 판)수도광열비' gubun union all
/*			select 33 rn, '      1. 판)수도광열비-수도료' gubun union all*/
			select 34 rn, '   (11) 판)세금과공과' gubun union all
/*			select 35 rn, '      1. 판)세금과공과-연금보험' gubun union all
			select 36 rn, '      2. 판)세금과공과-사업소세' gubun union all
			select 37 rn, '      3. 판)세금과공과-재산세종부세' gubun union all
			select 38 rn, '      4. 판)세금과공과-일반' gubun union all*/
			select 39 rn, '   (12) 판)감가상각비' gubun union all
/*			select 40 rn, '      1. 판)감가상각비-건물' gubun union all
			select 41 rn, '      2. 판)감가상각비-기계장치' gubun union all
			select 42 rn, '      3. 판)감가상각비-차량운반구' gubun union all
			select 43 rn, '      4. 판)감가상각비-비품' gubun union all
			select 44 rn, '      5. 판)감가상각비-시설장치' gubun union all*/
			select 45 rn, '   (13) 판)지급임차료' gubun union all
/*			select 46 rn, '      1. 판)지급임차료-건물' gubun union all
			select 47 rn, '      2. 판)지급임차료-차량' gubun union all
			select 48 rn, '      3. 판)지급임차료-비품' gubun union all
			select 49 rn, '      4. 판)지급임차료-일반' gubun union all*/
			select 50 rn, '   (14) 판)수선비' gubun union all
/*			select 51 rn, '      1. 판)수선비' gubun union all*/
			select 52 rn, '   (15) 판)보험료' gubun union all
/*			select 53 rn, '      1. 판)보험료-산재,고용보험' gubun union all
			select 54 rn, '      2. 판)보험료-차량' gubun union all
			select 55 rn, '      3. 판)보험료-건물' gubun union all
			select 56 rn, '      4. 판)보험료-일반' gubun union all*/
			select 57 rn, '   (16) 판)차량유지비' gubun union all
/*			select 58 rn, '      1. 판)차량유지비-유류비' gubun union all
			select 59 rn, '      2. 판)차량유지비-관리비' gubun union all
			select 60 rn, '      3. 판)차량유지비-일반' gubun union all
			select 61 rn, '      4. 판)차량유지비-자동차세' gubun union all*/
			select 62 rn, '   (17) 판)경상연구개발비' gubun union all
/*			select 63 rn, '      1. 판)경상연구개발비-일반' gubun union all
			select 64 rn, '      2. 판)경상연구개발비-개발소모품' gubun union all
			select 65 rn, '      3. 판)경상연구개발비-지급수수료' gubun union all
			select 66 rn, '      4. 판)경상연구개발비-국내출장경비(법인)' gubun union all
			select 67 rn, '      5. 판)경상연구개발비-국내출장경비(기타)' gubun union all
			select 68 rn, '      6. 판)경상연구개발비-해외출장경비' gubun union all
			select 69 rn, '      7. 판)경상연구개발비-해외출장경비(여비)' gubun union all
			select 70 rn, '      8. 판)경상연구개발비-사내식대' gubun union all
			select 71 rn, '      9. 판)경상연구개발비-외부식대등' gubun union all
			select 72 rn, '      10. 판)경상연구개발비-경조사비' gubun union all
			select 73 rn, '      11. 판)경상연구개발비(차량유지비-유류비)' gubun union all
			select 74 rn, '      12. 판)경상연구개발비(차량유지비-보험료)' gubun union all
			select 75 rn, '      13. 판)경상연구개발비(차량유지비-관리비)' gubun union all
			select 76 rn, '      14. 판)경상연구개발비(차량유지비-일반)' gubun union all
			select 77 rn, '      15. 판)경상연구개발비(차량유지비-자동차세)' gubun union all
			select 78 rn, '      16. 판)경상연구개발비(급여-임원)' gubun union all
			select 79 rn, '      17. 판)경상연구개발비(급여-직원)' gubun union all
			select 80 rn, '      18. 판)경상연구개발비(상여금-직원)' gubun union all
			select 81 rn, '      19. 판)경상연구개발비(제수당-연차)' gubun union all
			select 82 rn, '      20. 판)경상연구개발비(제수당-일반)' gubun union all
			select 83 rn, '      21. 판)경상연구개발비(잡급)' gubun union all
			select 84 rn, '      22. 판)경상연구개발비(퇴직급여-임원)' gubun union all
			select 85 rn, '      23. 판)경상연구개발비(퇴직급여-직원)' gubun union all
			select 86 rn, '      24. 판)경상연구개발비-건강,장기요양보험' gubun union all
			select 87 rn, '      25. 판)경상연구개발비-연금보험' gubun union all
			select 88 rn, '      26. 판)경상연구개발비-산재.고용보험' gubun union all
			select 89 rn, '      27. 판)경상연구개발비(지급임차료-건물)' gubun union all
			select 90 rn, '      28. 판)경상연구개발비(지급임차료-일반)' gubun union all
			select 91 rn, '      29. 판)경상연구개발비(지급임차료-차량)' gubun union all
			select 92 rn, '      30. 판)경상연구개발비-특허.심사료' gubun union all*/
			select 93 rn, '   (18) 판)운반비' gubun union all
/*			select 94 rn, '      1. 판)운반비-국내운송료' gubun union all
			select 95 rn, '      2. 판)운반비-해외운송료' gubun union all*/
			select 96 rn, '   (19) 판)교육훈련비' gubun union all
/*			select 97 rn, '      1. 판)교육훈련비-사외' gubun union all*/
			select 98 rn, '   (20) 판)도서인쇄비' gubun union all
/*			select 99 rn, '      1. 판)도서인쇄비' gubun union all*/
			select 100 rn, '   (21) 판)소모품비' gubun union all
/*			select 101 rn, '      1. 판)소모품비-비품' gubun union all
			select 102 rn, '      2. 판)소모품비-사무용품' gubun union all
			select 103 rn, '      3. 판)소모품비-전산용품' gubun union all
			select 104 rn, '      4. 판)소모품비-일반' gubun union all*/
			select 105 rn, '   (22) 판)지급수수료' gubun union all
/*			select 106 rn, '      1. 판)지급수수료-건물관리비' gubun union all
			select 107 rn, '      2. 판)지급수수료-보안용역료' gubun union all
			select 108 rn, '      3. 판)지급수수료-유지보수료' gubun union all
			select 109 rn, '      4. 판)지급수수료-금융.제증명' gubun union all
			select 110 rn, '      5. 판)지급수수료-감사.법률.자문' gubun union all
			select 111 rn, '      6. 판)지급수수료-특허.심사료' gubun union all
			select 112 rn, '      7. 판)지급수수료-일반' gubun union all*/
			select 113 rn, '   (23) 판)광고선전비' gubun union all
/*			select 114 rn, '      1. 판)광고선전비-IR' gubun union all
			select 115 rn, '      2. 판)광고선전비-일반' gubun union all*/
			select 116 rn, '   (24) 판)무형자산상각비' gubun union all
/*			select 117 rn, '      1. 판)무형자산상각비' gubun union all*/
			select 118 rn, '   (25) 판)견본비' gubun union all
/*			select 119 rn, '      1. 판)견본비' gubun union all*/
			select 120 rn, '   (26) 판)사용권자산감가상각비' gubun union all
/*			select 121 rn, '      1. 판)사용권자산상각비-건물' gubun union all
			select 122 rn, '      2. 판)사용권자산상각비-차량' gubun union all*/
			select 123 rn, '   (27) 판)주식보상비용' gubun union all
/*			select 124 rn, '      1. 판)주식보상비용' gubun union all*/
			select 125 rn, '   (28) 판)해외시장개척비' gubun /*union all
			select 126 rn, '      1. 판)해외시장개척비' gubun union all
			select 127 rn, '      2. 판)해외시장개척비(여비)' gubun */
		) B 
	) X 
	left join (
		select 1 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE 
		and (
			계정과목 in ('판)급여-임원', '판)급여-직원', '판)상여금-직원', '판)제수당-연차','판)제수당-일반','판)퇴직급여-임원','판)퇴직급여-직원','판)통신비','판)수도광열비-수도료', '판)수선비','판)도서인쇄비','판)무형자산상각비','판)견본비','판)주식보상비용') 
			or 
			계정과목 LIKE '판)복리후생비'+'%'
			or 
			계정과목 LIKE '판)여비교통비'+'%'
			or 
			계정과목 like '판)접대비'+'%' 
			or
			계정과목 like '판)세금과공과'+'%'
			or 
			계정과목 like '판)감가상각비' +'%'
			or 
			계정과목 LIKE '판)지급임차료' + '%'
			or 
			계정과목 LIKE '판)보험료' + '%'
			or 
			계정과목 LIKE '판)차량유지비' + '%'
			or 
			계정과목 LIKE '판)경상연구개발비'+'%' 
			or 
			계정과목 like '판)운반비' +'%'
			or 
			계정과목 LIKE '판)교육훈련비'+'%'
			or 
			계정과목 LIKE '판)소모품비' +'%'
			or 
			계정과목 LIKE '판)지급수수료'+'%'
			or 
			계정과목 LIKE '판)광고선전비'+'%'
			or
			계정과목 like '판)사용권자산상각비%'
			or
			계정과목 like '판)해외시장개척비'+'%' 		
		)
		group by  코스트센터 union all
		select 2 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)급여-임원' group by  코스트센터 union all
		select 3 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)급여-임원' group by  코스트센터 union all
		select 4 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)급여-직원' group by  코스트센터 union all
		select 5 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)급여-직원' group by  코스트센터 union all
		select 6 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)상여금-직원' group by  코스트센터 union all
		select 7 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)상여금-직원' group by  코스트센터 union all
		select 8 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 IN('판)제수당-연차','판)제수당-일반') group by  코스트센터 union all
		select 9 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)제수당-연차' group by  코스트센터 union all
		select 10 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)제수당-일반' group by  코스트센터 union all
		select 11 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 IN('판)퇴직급여-임원','판)퇴직급여-직원') group by  코스트센터 union all
		select 12 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)퇴직급여-임원' group by  코스트센터 union all
		select 13 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)퇴직급여-직원' group by  코스트센터 union all
		select 14 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)복리후생비'+'%' group by  코스트센터 union all
		select 15 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)복리후생비-건강,장기요양보험' group by  코스트센터 union all
		select 16 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)복리후생비-사내식대' group by  코스트센터 union all
		select 17 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)복리후생비-외부식대등' group by  코스트센터 union all
		select 18 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)복리후생비-경조사비' group by  코스트센터 union all
		select 19 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)복리후생비-일반' group by  코스트센터 union all
		select 20 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)복리후생비-의료' group by  코스트센터 union all
		select 21 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)여비교통비'+'%' group by  코스트센터 union all
		select 22 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)여비교통비-국내출장경비(법인)' group by  코스트센터 union all
		select 23 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)여비교통비-국내출장경비(기타)' group by  코스트센터 union all
		select 24 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)여비교통비-해외출장경비' group by  코스트센터 union all
		select 25 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)여비교통비-기타' group by  코스트센터 union all
		select 26 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 like '판)접대비'+'%'  group by  코스트센터 union all
		select 27 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)접대비-식대' group by  코스트센터 union all
		select 28 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)접대비-경조금' group by  코스트센터 union all
		select 29 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)접대비-일반' group by  코스트센터 union all
		select 30 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)통신비' group by  코스트센터 union all
		select 31 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)통신비' group by  코스트센터 union all
		select 32 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)수도광열비-수도료' group by  코스트센터 union all
		select 33 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)수도광열비-수도료' group by  코스트센터 union all
		select 34 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 like '판)세금과공과'+'%'  group by  코스트센터 union all
		select 35 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)세금과공과-연금보험' group by  코스트센터 union all
		select 36 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)세금과공과-사업소세' group by  코스트센터 union all
		select 37 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)세금과공과-재산세종부세' group by  코스트센터 union all
		select 38 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)세금과공과-일반' group by  코스트센터 union all
		select 39 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 like '판)감가상각비' +'%' group by  코스트센터 union all
		select 40 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)감가상각비-건물' group by  코스트센터 union all
		select 41 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)감가상각비-기계장치' group by  코스트센터 union all
		select 42 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)감가상각비-차량운반구' group by  코스트센터 union all
		select 43 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)감가상각비-비품' group by  코스트센터 union all
		select 44 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)감가상각비-시설장치' group by  코스트센터 union all
		select 45 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)지급임차료' + '%' group by  코스트센터 union all
		select 46 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급임차료-건물' group by  코스트센터 union all
		select 47 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급임차료-차량' group by  코스트센터 union all
		select 48 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급임차료-비품' group by  코스트센터 union all
		select 49 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급임차료-일반' group by  코스트센터 union all
		select 50 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)수선비' group by  코스트센터 union all
		select 51 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)수선비' group by  코스트센터 union all
		select 52 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)보험료' + '%' group by  코스트센터 union all
		select 53 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)보험료-산재,고용보험' group by  코스트센터 union all
		select 54 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)보험료-차량' group by  코스트센터 union all
		select 55 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)보험료-건물' group by  코스트센터 union all
		select 56 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)보험료-일반' group by  코스트센터 union all
		select 57 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)차량유지비' + '%' group by  코스트센터 union all
		select 58 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)차량유지비-유류비' group by  코스트센터 union all
		select 59 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)차량유지비-관리비' group by  코스트센터 union all
		select 60 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)차량유지비-일반' group by  코스트센터 union all
		select 61 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)차량유지비-자동차세' group by  코스트센터 union all
		select 62 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)경상연구개발비'+'%' group by  코스트센터 union all
		select 63 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-일반' group by  코스트센터 union all
		select 64 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-개발소모품' group by  코스트센터 union all
		select 65 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-지급수수료' group by  코스트센터 union all
		select 66 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-국내출장경비(법인)' group by  코스트센터 union all
		select 67 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-국내출장경비(기타)' group by  코스트센터 union all
		select 68 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-해외출장경비' group by  코스트센터 union all
		select 69 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-해외출장경비(여비)' group by  코스트센터 union all
		select 70 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-사내식대' group by  코스트센터 union all
		select 71 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-외부식대등' group by  코스트센터 union all
		select 72 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-경조사비' group by  코스트센터 union all
		select 73 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(차량유지비-유류비)' group by  코스트센터 union all
		select 74 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(차량유지비-보험료)' group by  코스트센터 union all
		select 75 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(차량유지비-관리비)' group by  코스트센터 union all
		select 76 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(차량유지비-일반)' group by  코스트센터 union all
		select 77 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(차량유지비-자동차세)' group by  코스트센터 union all
		select 78 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(급여-임원)' group by  코스트센터 union all
		select 79 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(급여-직원)' group by  코스트센터 union all
		select 80 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(상여금-직원)' group by  코스트센터 union all
		select 81 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(제수당-연차)' group by  코스트센터 union all
		select 82 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(제수당-일반)' group by  코스트센터 union all
		select 83 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(잡급)' group by  코스트센터 union all
		select 84 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(퇴직급여-임원)' group by  코스트센터 union all
		select 85 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(퇴직급여-직원)' group by  코스트센터 union all
		select 86 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-건강,장기요양보험' group by  코스트센터 union all
		select 87 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-연금보험' group by  코스트센터 union all
		select 88 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-산재.고용보험' group by  코스트센터 union all
		select 89 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(지급임차료-건물)' group by  코스트센터 union all
		select 90 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(지급임차료-일반)' group by  코스트센터 union all
		select 91 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비(지급임차료-차량)' group by  코스트센터 union all
		select 92 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)경상연구개발비-특허.심사료' group by  코스트센터 union all
		select 93 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 like '판)운반비' +'%' group by  코스트센터 union all
		select 94 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)운반비-국내운송료' group by  코스트센터 union all
		select 95 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)운반비-해외운송료' group by  코스트센터 union all
		select 96 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)교육훈련비'+'%' group by  코스트센터 union all
		select 97 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)교육훈련비-사외' group by  코스트센터 union all
		select 98 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)도서인쇄비' group by  코스트센터 union all
		select 99 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)도서인쇄비' group by  코스트센터 union all
		select 100 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)소모품비' +'%' group by  코스트센터 union all
		select 101 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)소모품비-비품' group by  코스트센터 union all
		select 102 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)소모품비-사무용품' group by  코스트센터 union all
		select 103 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)소모품비-전산용품' group by  코스트센터 union all
		select 104 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)소모품비-일반' group by  코스트센터 union all
		select 105 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)지급수수료'+'%' group by  코스트센터 union all
		select 106 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-건물관리비' group by  코스트센터 union all
		select 107 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-보안용역료' group by  코스트센터 union all
		select 108 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-유지보수료' group by  코스트센터 union all
		select 109 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-금융.제증명' group by  코스트센터 union all
		select 110 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-감사.법률.자문' group by  코스트센터 union all
		select 111 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-특허.심사료' group by  코스트센터 union all
		select 112 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)지급수수료-일반' group by  코스트센터 union all
		select 113 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 LIKE '판)광고선전비'+'%' group by  코스트센터 union all
		select 114 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)광고선전비-IR' group by  코스트센터 union all
		select 115 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)광고선전비-일반' group by  코스트센터 union all
		select 116 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)무형자산상각비' group by  코스트센터 union all
		select 117 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)무형자산상각비' group by  코스트센터 union all
		select 118 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)견본비' group by  코스트센터 union all
		select 119 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)견본비' group by  코스트센터 union all
		select 120 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 like '판)사용권자산상각비%' group by  코스트센터 union all
		select 121 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)사용권자산상각비-건물' group by  코스트센터 union all
		select 122 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)사용권자산상각비-차량' group by  코스트센터 union all
		select 123 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)주식보상비용' group by  코스트센터 union all
		select 124 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)주식보상비용' group by  코스트센터 union all
		select 125 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 like '판)해외시장개척비'+'%' group by  코스트센터 union all
		select 126 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)해외시장개척비' group by  코스트센터 union all
		select 127 rn, 코스트센터 dept_name, sum(차변금액-대변금액) as amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='판)해외시장개척비(여비)' group by  코스트센터
	) Y
	on 1=1
	and X.rn = Y.rn 
	and X.dept_name = Y.dept_name
)
SELECT * INTO #SA_SOURCETABLE FROM sourceTable;

-- 동적 SQL 생성
		SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
	select * from #SA_SOURCETABLE
	union all 
	SELECT ''합계'' dept_name, rn, gubun, sum(amt) amt from #SA_SOURCETABLE group by rn, gubun
) AS SourceTable
PIVOT 
(
	SUM(AMT)
	FOR dept_name IN (' + @Columns + ')
) AS PivotTable
order by 1,2 desc;';
		
		-- 동적 SQL 실행
		--select @SQL;
		EXEC sp_executesql @SQL;
		COMMIT TRANSACTION;
		
-- 임시 테이블 정리
DROP TABLE #SA_SOURCETABLE;
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;