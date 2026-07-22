

CREATE OR ALTER Procedure DOI_ManufacturingExpenseByDept(
	@YYYYMM varchar(10),
 	@SITE varchar(4),
 	@SEL_CODE varchar(10)
 )
AS
BEGIN
		-- ============================================================
	-- [VN 전용 동적 분기] doi_acct(상위계정과목/총원가_순서) + doi_dept_cost(코스트센터) 기반
	--   섹션: 재료비/노무비/경비 (상위계정과목 계열로 판정, 제)직원급여=노무비 통합)
	--   부서: 코스트센터(없으면 제조공통), 금액: 센터채움 차변-대변, 원재료=doi_mat_amt
	-- ============================================================
	IF @SITE = 'VN'
	BEGIN
		BEGIN TRY
			DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

			-- 1) 부서(코스트센터) 목록 : 제조 발생센터 + 제조공통(부서없음) + 합계
			IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
			SELECT dept_name, ord INTO #vdept FROM (
				SELECT DISTINCT LTRIM(RTRIM(코스트센터)) dept_name, 1 ord
					FROM doi_dept_cost
					WHERE yyyymm=@YYYYMM AND site=@SITE AND 비용구분='제조'
						AND LTRIM(RTRIM(ISNULL(코스트센터,'')))<>''
				UNION SELECT N'제조공통', 0
				UNION SELECT N'합계', 2
			) t;

			-- 2) 항목(상위계정과목) 금액 : 원재료(doi_mat_amt) + 부재료/노무/경비(doi_dept_cost 센터채움 차변-대변)
			IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
			SELECT dept_name, 상위계정과목, sec, SUM(amt) amt
			INTO #vamt
			FROM (
				SELECT N'제조공통' dept_name, N'원재료비' 상위계정과목, 1 sec, SUM(in_amt) amt
					FROM doi_mat_amt
					WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
				UNION ALL
				SELECT CASE WHEN LTRIM(RTRIM(ISNULL(d.코스트센터,'')))='' THEN N'제조공통' ELSE LTRIM(RTRIM(d.코스트센터)) END dept_name,
						a.상위계정과목,
						CASE WHEN a.상위계정과목 IN (N'원재료비',N'부재료비',N'부재료비 (6272)') THEN 1
							WHEN a.상위계정과목 IN (N'제)임원급여',N'제)직원급여',N'제)상여금',N'제)제수당',N'제)퇴직급여',N'제)주식보상비용') THEN 2
							ELSE 3 END sec,
						d.차변금액 - d.대변금액 amt
					FROM doi_dept_cost d
					JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.ACCT=d.계정코드
					WHERE d.yyyymm=@YYYYMM AND d.site=@SITE AND d.비용구분='제조'
						AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
						AND ISNULL(a.상위계정과목,'')<>''
			) s
			GROUP BY dept_name, 상위계정과목, sec;

			-- 3) 골격(섹션 헤더 + 항목행) : 데이터에 존재하는 상위계정과목으로 동적 구성
			IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
			;WITH items AS (
				SELECT DISTINCT sec, 상위계정과목 FROM #vamt WHERE ISNULL(상위계정과목,'')<>''
			), ordv AS (
				SELECT i.sec, i.상위계정과목,
					CASE i.sec
						WHEN 1 THEN CASE WHEN i.상위계정과목=N'원재료비' THEN 1 WHEN i.상위계정과목 LIKE N'부재료%' THEN 2 ELSE 3 END
						WHEN 2 THEN CASE i.상위계정과목 WHEN N'제)임원급여' THEN 1 WHEN N'제)직원급여' THEN 2 WHEN N'제)상여금' THEN 3 WHEN N'제)제수당' THEN 4 WHEN N'제)퇴직급여' THEN 5 WHEN N'제)주식보상비용' THEN 6 ELSE 9 END
						ELSE ISNULL((SELECT TRY_CONVERT(int,NULLIF(MAX(a.총원가_순서),'')) FROM doi_acct a WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND a.상위계정과목=i.상위계정과목),99)
					END wi
				FROM items i
			)
			SELECT CAST(sec*10000 + ROW_NUMBER() OVER (PARTITION BY sec ORDER BY wi, 상위계정과목)*10 AS int) rn,
					sec, 상위계정과목, N'    ' + 상위계정과목 gubun
			INTO #vskel FROM ordv;
			INSERT #vskel(rn, sec, 상위계정과목, gubun) VALUES
				(10000, 1, N'__H1', N'  I. 재료비'),
				(20000, 2, N'__H2', N'  II. 노무비'),
				(30000, 3, N'__H3', N'  III. 경비'),
				(90000, 9, N'__T',  N'  IV. 당기총제조원가');

			-- 4) 소스테이블 : 부서 × 골격 크로스 + 금액(항목/헤더/총계)
			IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
			;WITH amt_item AS (
				SELECT v.dept_name, sk.rn, SUM(v.amt) amt
				FROM #vamt v JOIN #vskel sk ON sk.sec=v.sec AND sk.상위계정과목=v.상위계정과목
				GROUP BY v.dept_name, sk.rn
			), amt_hdr AS (
				SELECT v.dept_name, sk.rn, SUM(v.amt) amt
				FROM #vamt v JOIN #vskel sk ON sk.rn IN (10000,20000,30000) AND sk.sec=v.sec
				GROUP BY v.dept_name, sk.rn
			), amt_tot AS (
				SELECT dept_name, 90000 rn, SUM(amt) amt FROM #vamt GROUP BY dept_name
			), amt_all AS (
				SELECT * FROM amt_item UNION ALL SELECT * FROM amt_hdr UNION ALL SELECT * FROM amt_tot
			)
			SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
			INTO #vsource
			FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
			LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

			-- 5) 피벗 컬럼 동적 생성 (부서 순서: 제조공통 → 센터명 → 합계)
			SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name
			FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
			SELECT @vColumns = N'[' + @vColumns + N']';

			SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce(['
			FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
			SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');

			-- 6) 동적 PIVOT (합계행 포함)
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
--		BEGIN TRANSACTION;
		--declare @YYYYMM varchar(10)='202510', @SITE varchar(4)='HQ';
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + dept_name
		FROM (SELECT TOP 500 dept_name 
				FROM (		
					select distinct dept, dept_name from (
						select A.*, B.dept from (
							select distinct 코스트센터 dept_name from doi_dept_cost where YYYYMM = @YYYYMM and site = @SITE and 비용구분 = '제조' and LTRIM(RTRIM(ISNULL(코스트센터,''))) != '' 
							union 
							select '제조공통' dept_name 
							union 
							select '카세트팀' dept_name
							union 
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
					select distinct dept, dept_name from (
						select A.*, B.dept from (
							select distinct 코스트센터 dept_name from doi_dept_cost where YYYYMM = @YYYYMM and site = @SITE and 비용구분 = '제조' and LTRIM(RTRIM(ISNULL(코스트센터,''))) != '' 
							union 
							select '제조공통' dept_name 
							union 
							select '카세트팀' dept_name
							union 
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
					select distinct 코스트센터 dept_name from doi_dept_cost where YYYYMM = @YYYYMM and site = @SITE and 비용구분 = '제조' and LTRIM(RTRIM(ISNULL(코스트센터,''))) != '' 
					union 
					select '제조공통' dept_name 
					union 
					select '카세트팀' dept_name
				) A 
				left join (
					select distinct dept, dept_name from doi_dept where YYYYMM = @YYYYMM and site = @SITE
				) B 
				on A.dept_name = B.dept_name
			) A 
		) A 
		cross join 
		(
		select 1 rn, '  I. 재료비' gubun
		union all select 2 rn, '    (1) 원재료_원장' gubun
		union all select 3 rn, '    (2) 원재료_카세트 부품' gubun
		union all select 4 rn, '    (3) 원재료_필름' gubun
		union all select 5 rn, '    (4) 원재료_약액' gubun		
		union all select 6 rn, '    (5) 부재료_트레이' gubun
		union all select 7 rn, '    (6) 부재료_기타' gubun
		union all select 8 rn, '  II. 노무비' gubun
		union all select 9 rn, '    (1) 제)임원급여' gubun
/*		union all select 10 rn, '      1. 제)급여-임원' gubun*/
		union all select 11 rn, '    (2) 제)직원급여' gubun
/*		union all select 12 rn, '      1. 제)급여-직원' gubun*/
		union all select 13 rn, '    (3) 제)상여금' gubun
/*		union all select 14 rn, '      1. 제)상여금-직원' gubun*/
		union all select 15 rn, '    (4) 제)제수당' gubun
/*		union all select 16 rn, '      1. 제)제수당-연차' gubun
		union all select 17 rn, '      2. 제)제수당-일반' gubun*/
		union all select 18 rn, '    (5) 제)퇴직급여' gubun
/*		union all select 19 rn, '      1. 제)퇴직급여-임원' gubun
		union all select 20 rn, '      2. 제)퇴직급여-직원' gubun*/
		union all select 21 rn, '    (6) 제)주식보상비용' gubun
/*		union all select 22 rn, '      1. 제)주식보상비용' gubun*/
		union all select 23 rn, '  III. 경비' gubun
		union all select 24 rn, '    (1) 제)복리후생비' gubun
/*		union all select 25 rn, '      1. 제)복리후생비-건강,장기요양보험' gubun
		union all select 26 rn, '      2. 제)복리후생비-사내식대' gubun
		union all select 27 rn, '  3. 제)복리후생비-외부식대등' gubun
		union all select 28 rn, '      4. 제)복리후생비-경조사비' gubun
		union all select 29 rn, '      5. 제)복리후생비-일반' gubun
		union all select 30 rn, '      6. 제)복리후생비-의료' gubun*/
		union all select 31 rn, '    (2) 제)여비교통비' gubun
/*		union all select 32 rn, '      1. 제)여비교통비-국내출장경비(법인)' gubun
		union all select 33 rn, '      2. 제)여비교통비-국내출장경비(기타)' gubun*/
		union all select 34 rn, '    (3) 제)통신비' gubun
/*		union all select 35 rn, '      1. 제)통신비' gubun*/
		union all select 36 rn, '    (4) 제)수도광열비' gubun
/*		union all select 37 rn, '      1. 제)수도광열비-수도료' gubun
		union all select 38 rn, '      2. 제)수도광열비-연료비' gubun*/
		union all select 39 rn, '    (5) 제)전력비' gubun
/*		union all select 40 rn, '      1. 제)전력비' gubun*/
		union all select 41 rn, '    (6) 제)세금과공과' gubun
/*		union all select 42 rn, '      1. 제)세금과공과-연금보험' gubun
		union all select 43 rn, '      2. 제)세금과공과-일반' gubun*/
		union all select 44 rn, '    (7) 제)감가상각비' gubun
/*		union all select 45 rn, '      1. 제)감가상각비-건물' gubun
		union all select 46 rn, '      2. 제)감가상각비-구축물' gubun
		union all select 47 rn, '      3. 제)감가상각비-기계장치' gubun
		union all select 48 rn, '      4. 제)감가상각비-공구와기구' gubun
		union all select 49 rn, '      5. 제)감가상각비-비품' gubun
		union all select 50 rn, '      6. 제)감가상각비-시설장치' gubun*/
		union all select 51 rn, '    (8) 제)지급임차료' gubun
/*		union all select 52 rn, '      1. 제)지급임차료-건물' gubun
		union all select 53 rn, '      2. 제)지급임차료-차량' gubun
		union all select 54 rn, '      3. 제)지급임차료-일반' gubun*/
		union all select 55 rn, '    (9) 제)수선비' gubun
/*		union all select 56 rn, '      1. 제)수선비' gubun*/
		union all select 57 rn, '    (10) 제)보험료' gubun
/*		union all select 58 rn, '      1. 제)보험료-고용,산재보험' gubun
		union all select 59 rn, '      2. 제)보험료-차량' gubun
		union all select 60 rn, '      3. 제)보험료-건물' gubun
		union all select 61 rn, '      4. 제)보험료-일반' gubun*/
		union all select 62 rn, '    (11) 제)차량유지비' gubun
/*		union all select 63 rn, '      1. 제)차량유지비-유류비' gubun
		union all select 64 rn, '      2. 제)차량유지비-관리비' gubun
		union all select 65 rn, '      3. 제)차량유지비-일반' gubun
		union all select 66 rn, '      4. 제)차량유지비-자동차세' gubun*/
		union all select 67 rn, '    (12) 제)운반비' gubun
/*		union all select 68 rn, '      1. 제)운반비-국내운송료' gubun
		union all select 69 rn, '      2. 제)운반비-해외운송료' gubun*/
		union all select 70 rn, '    (13) 제)교육훈련비' gubun
/*		union all select 71 rn, '      1. 제)교육훈련비-사외' gubun*/
		union all select 72 rn, '    (14) 제)도서인쇄비' gubun
/*		union all select 73 rn, '      1. 제)도서인쇄비' gubun*/
		union all select 74 rn, '    (15) 제)소모품비' gubun
/*		union all select 75 rn, '      1. 제)소모품비-비품' gubun
		union all select 76 rn, '      2. 제)소모품비-사무용품' gubun
		union all select 77 rn, '      3. 제)소모품비-일반' gubun*/
		union all select 78 rn, '    (16) 제)지급수수료' gubun
/*		union all select 79 rn, '      1. 제)지급수수료-유지보수료' gubun
		union all select 80 rn, '      2. 제)지급수수료-검사.측정료' gubun
		union all select 81 rn, '      3. 제)지급수수료-일반' gubun*/
		union all select 82 rn, '    (17) 제)외주가공비' gubun
/*		union all select 83 rn, '      1. 제)외주가공비' gubun*/
		union all select 84 rn, '    (18) 제)사용권자산감가상각비' gubun
/*		union all select 85 rn, '      1. 제)사용권자산상각비-건물' gubun
		union all select 86 rn, '      2. 제)사용권자산상각비-차량' gubun*/
		union all select 87 rn, '    (19) 제)검사비' gubun
/*		union all select 88 rn, '      1. 제)검사비' gubun*/
		union all select 89 rn, '    (20) 제)견본비' gubun
/*		union all select 90 rn, '      1. 제)견본비' gubun*/
		union all select 91 rn, '  IV. 당기총제조원가' gubun
		) B 
	) X 
	left join (
		select 1 rn, '  I. 재료비' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and 
		(
			(mat_class in ('원자재','더미글라스','약액'))
			or 
			(자재대분류 in ('필름', '트레이','약액','타부서 구매품'))
			/*or 
			(mat_class='약액')*/
			or 
			(MAT_GUBUN+mat_class+coalesce(자재대분류,'1') IN ('제품'+'부자재'+'1','제품'+'부자재'+'부자재','제품'+'더미글라스'+'부자재'))
		)
		union all 
		select 1 rn, '  I. 재료비' gubun,'카세트팀' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and 
		(
			(mat_gubun='카세트제품' and mat_class='원자재')
			or
			(MAT_GUBUN+mat_class+coalesce(자재대분류,'1') = '카세트제품'+'부자재'+'1')
		)
		union all 
		select 2 rn, '    (1) 원재료_원장' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and /*mat_gubun='제품' and mat_class='원자재' */ 원가자재분류 ='원장'
		union all 
		select 3 rn, '    (2) 원재료_카세트 부품' gubun,'카세트팀' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and (( mat_gubun='카세트제품' and mat_class='원자재') OR 원가자재분류 ='카세트' )
		union all 
		select 4 rn, '    (3) 원재료_필름' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and (자재대분류='필름' OR 원가자재분류 ='필름')
		union all 
		select 5 rn, '    (4) 원재료_약액' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and (mat_class='약액' or 자재대분류='약액'  OR 원가자재분류 ='약액')		
		union all 
		select 6 rn, '    (5) 부재료_트레이' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and ( 자재대분류='트레이' OR 원가자재분류 ='트레이' )
		union all
		select 7 rn, '    (6) 부재료_기타' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and (MAT_GUBUN+mat_class+coalesce(자재대분류,'1') IN ('제품'+'부자재'+'1','제품'+'부자재'+'부자재','제품'+'더미글라스'+'부자재','부자재'+'더미글라스'+'부자재','부자재'+'부자재'+'타부서 구매품')
		    AND COALESCE(NULLIF(LTRIM(RTRIM(원가자재분류)),''), N'기타') = N'기타')
		union all
		select 7 rn, '    (6) 부재료_기타' gubun,'카세트팀' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and ((MAT_GUBUN+mat_class+coalesce(자재대분류,'1') = '카세트제품'+'부자재'+'1' AND COALESCE(NULLIF(LTRIM(RTRIM(원가자재분류)),''), N'기타') = N'기타'))
		union all 
		select 8 rn, '  II. 노무비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
		and 계정과목 in ('제)급여-임원','제)급여-직원','제)상여금-직원','제)제수당-연차','제)제수당-일반','제)퇴직급여-임원','제)퇴직급여-직원')
		group by 코스트센터
		union all 
		select 9 rn, '    (1) 제)임원급여' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)급여-임원' group by 코스트센터
		union all
/*		select 10 rn, '      1. 제)급여-임원' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)급여-임원' group by 코스트센터
		union all*/
		select 11 rn, '    (2) 제)직원급여' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)급여-직원' group by 코스트센터
		union all
/*		select 12 rn, '      1. 제)급여-직원' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)급여-직원' group by 코스트센터
		union all*/
		select 13 rn, '    (3) 제)상여금' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)상여금-직원' group by 코스트센터
		union all
/*		select 14 rn, '      1. 제)상여금-직원' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)상여금-직원' group by 코스트센터
		union all */
		select 15 rn, '    (4) 제)제수당' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in('제)제수당-연차','제)제수당-일반') group by 코스트센터
		union all 
/*		select 16 rn, '      1. 제)제수당-연차' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)제수당-연차' group by 코스트센터
		union all 
		select 17 rn, '      2. 제)제수당-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)제수당-일반' group by 코스트센터
		union all */
		select 18 rn, '    (5) 제)퇴직급여' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)퇴직급여-임원','제)퇴직급여-직원') group by 코스트센터
		union all 
/*		select 19 rn, '      1. 제)퇴직급여-임원' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)퇴직급여-임원' group by 코스트센터
		union all 
		select 20 rn, '      2. 제)퇴직급여-직원' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)퇴직급여-직원' group by 코스트센터
		union all */
		select 21 rn, '    (6) 제)주식보상비용' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)주식보상비용' group by 코스트센터
		union all 
/*		select 22 rn, '      1. 제)주식보상비용' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)주식보상비용' group by 코스트센터
		union all */
		select 23 rn, '  III. 경비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE 
		and 계정과목 in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료','제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)'
		,'제)통신비','제)수도광열비-수도료','제)수도광열비-연료비','제)전력비','제)세금과공과-연금보험','제)세금과공과-일반','제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치'
		,'제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반','제)수선비','제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반','제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세'
		,'제)운반비-국내운송료','제)운반비-해외운송료','제)교육훈련비-사외','제)도서인쇄비','제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반','제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반','제)외주가공비','제)사용권자산상각비-건물','제)사용권자산상각비-차량','제)검사비','제)견본비')
		group by 코스트센터
		union all 
		select 24 rn, '    (1) 제)복리후생비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료') group by 코스트센터
		union all 
/*		select 25 rn, '      1. 제)복리후생비-건강,장기요양보험' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)복리후생비-건강,장기요양보험' group by 코스트센터
		union all 
		select 26 rn, '      2. 제)복리후생비-사내식대' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)복리후생비-사내식대' group by 코스트센터
		union all 
		select 27 rn, '      3. 제)복리후생비-외부식대등' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)복리후생비-외부식대등' group by 코스트센터
		union all 
		select 28 rn, '      4. 제)복리후생비-경조사비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)복리후생비-경조사비' group by 코스트센터
		union all 
		select 29 rn, '      5. 제)복리후생비-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)복리후생비-일반' group by 코스트센터
		union all 
		select 30 rn, '      6. 제)복리후생비-의료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)복리후생비-의료' group by 코스트센터
		union all */
		select 31 rn, '    (2) 제)여비교통비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)') group by 코스트센터
		union all 
/*		select 32 rn, '      1. 제)여비교통비-국내출장경비(법인)' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)여비교통비-국내출장경비(법인)' group by 코스트센터
		union all 
		select 33 rn, '      2. 제)여비교통비-국내출장경비(기타)' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)여비교통비-국내출장경비(기타)' group by 코스트센터
		union all */
		select 34 rn, '    (3) 제)통신비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)통신비' group by 코스트센터
		union all 
/*		select 35 rn, '      1. 제)통신비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)통신비' group by 코스트센터
		union all*/ 
		select 36 rn, '    (4) 제)수도광열비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)수도광열비-수도료','제)수도광열비-연료비') group by 코스트센터
		union all 
/*		select 37 rn, '      1. 제)수도광열비-수도료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)수도광열비-수도료' group by 코스트센터
		union all 
		select 38 rn, '     2. 제)수도광열비-연료비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)수도광열비-연료비' group by 코스트센터
		union all */
		select 39 rn, '    (5) 제)전력비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)전력비' group by 코스트센터
		union all 
/*		select 40 rn, '      1. 제)전력비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)전력비' group by 코스트센터
		union all */
		select 41 rn, '    (6) 제)세금과공과' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)세금과공과-연금보험','제)세금과공과-일반') group by 코스트센터
		union all 
/*		select 42 rn, '      1. 제)세금과공과-연금보험' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)세금과공과-연금보험' group by 코스트센터
		union all 
		select 43 rn, '      2. 제)세금과공과-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)세금과공과-일반' group by 코스트센터
		union all */
		select 44 rn, '    (7) 제)감가상각비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치') group by 코스트센터
		union all 
/*		select 45 rn, '      1. 제)감가상각비-건물' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)감가상각비-건물' group by 코스트센터
		union all 
		select 46 rn, '      2. 제)감가상각비-구축물' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)감가상각비-구축물' group by 코스트센터
		union all 
		select 47 rn, '      3. 제)감가상각비-기계장치' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)감가상각비-기계장치' group by 코스트센터
		union all 
		select 48 rn, '      4. 제)감가상각비-공구와기구' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)감가상각비-공구와기구' group by 코스트센터
		union all 
		select 49 rn, '      5. 제)감가상각비-비품' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)감가상각비-비품' group by 코스트센터
		union all 
		select 50 rn, '      6. 제)감가상각비-시설장치' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)감가상각비-시설장치' group by 코스트센터
		union all */
		select 51 rn, '    (8) 제)지급임차료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반') group by 코스트센터
		union all 
/*		select 52 rn, '      1. 제)지급임차료-건물' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)지급임차료-건물' group by 코스트센터
		union all 
		select 53 rn, '      2. 제)지급임차료-차량' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)지급임차료-차량' group by 코스트센터
		union all 
		select 54 rn, '      3. 제)지급임차료-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)지급임차료-일반' group by 코스트센터
		union all */
		select 55 rn, '    (9) 제)수선비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)수선비' group by 코스트센터
		union all 
/*		select 56 rn, '      1. 제)수선비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)수선비' group by 코스트센터
		union all*/ 
		select 57 rn, '    (10) 제)보험료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반') group by 코스트센터
		union all 
/*		select 58 rn, '      1. 제)보험료-고용,산재보험' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)보험료-고용,산재보험' group by 코스트센터
		union all 
		select 59 rn, '      2. 제)보험료-차량' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)보험료-차량' group by 코스트센터
		union all 
		select 60 rn, '      3. 제)보험료-건물' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)보험료-건물' group by 코스트센터
		union all 
		select 61 rn, '      4. 제)보험료-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)보험료-일반' group by 코스트센터
		union all */
		select 62 rn, '    (11) 제)차량유지비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세') group by 코스트센터
		union all 
/*		select 63 rn, '      1. 제)차량유지비-유류비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)차량유지비-유류비' group by 코스트센터
		union all 
		select 64 rn, '      2. 제)차량유지비-관리비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)차량유지비-관리비' group by 코스트센터
		union all 
		select 65 rn, '      3. 제)차량유지비-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)차량유지비-일반' group by 코스트센터
		union all 
		select 66 rn, '      4. 제)차량유지비-자동차세' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)차량유지비-자동차세' group by 코스트센터
		union all */
		select 67 rn, '    (12) 제)운반비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)운반비-국내운송료','제)운반비-해외운송료') group by 코스트센터
		union all 
/*		select 68 rn, '      1. 제)운반비-국내운송료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)운반비-국내운송료' group by 코스트센터
		union all 
		select 69 rn, '      2. 제)운반비-해외운송료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)운반비-해외운송료' group by 코스트센터
		union all */
		select 70 rn, '    (13) 제)교육훈련비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)교육훈련비-사외') group by 코스트센터
		union all 
/*		select 71 rn, '      1. 제)교육훈련비-사외' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)교육훈련비-사외' group by 코스트센터
		union all */
		select 72 rn, '    (14) 제)도서인쇄비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)도서인쇄비' group by 코스트센터
		union all 
/*		select 73 rn, '      1. 제)도서인쇄비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)도서인쇄비' group by 코스트센터
		union all */
		select 74 rn, '    (15) 제)소모품비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반') group by 코스트센터
		union all 
/*		select 75 rn, '      1. 제)소모품비-비품' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)소모품비-비품' group by 코스트센터
		union all 
		select 76 rn, '     2. 제)소모품비-사무용품' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)소모품비-사무용품' group by 코스트센터
		union all 
		select 77 rn, '      3. 제)소모품비-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)소모품비-일반' group by 코스트센터
		union all */
		select 78 rn, '    (16) 제)지급수수료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반') group by 코스트센터
		union all 
/*		select 79 rn, '      1. 제)지급수수료-유지보수료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)지급수수료-유지보수료' group by 코스트센터
		union all 
		select 80 rn, '      2. 제)지급수수료-검사.측정료' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)지급수수료-검사.측정료' group by 코스트센터
		union all 
		select 81 rn, '      3. 제)지급수수료-일반' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)지급수수료-일반' group by 코스트센터
		union all */
		select 82 rn, '    (17) 제)외주가공비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)외주가공비' group by 코스트센터
		union all 
/*		select 83 rn, '      1. 제)외주가공비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)외주가공비' group by 코스트센터
		union all */
		select 84 rn, '    (18) 제)사용권자산감가상각비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목 in ('제)사용권자산상각비-건물','제)사용권자산상각비-차량') group by 코스트센터
		union all 
/*		select 85 rn, '      1. 제)사용권자산상각비-건물' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)사용권자산상각비-건물' group by 코스트센터
		union all 
		select 86 rn, '      2. 제)사용권자산상각비-차량' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)사용권자산상각비-차량' group by 코스트센터
		union all */
		select 87 rn, '    (19) 제)검사비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)검사비' group by 코스트센터
		union all 
/*		select 88 rn, '      1. 제)검사비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)검사비' group by 코스트센터
		union all */
		select 89 rn, '    (20) 제)견본비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)견본비' group by 코스트센터
		union all 
/*		select 90 rn, '      1. 제)견본비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE and 계정과목='제)견본비' group by 코스트센터
		union all*/		
		select 91 rn, '  IV. 당기총제조원가' gubun, dept_name, sum(amt) amt 
		from(
			select 1 rn, '  I. 재료비' gubun,'제조공통' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
			/*and 
			(
				(mat_gubun='제품' and mat_class='원자재')
				or 
				(자재대분류 in ('필름', '트레이'))
				or 
				(mat_class='약액')
				or 
				(MAT_GUBUN+mat_class+coalesce(자재대분류,'1') IN ('제품'+'부자재'+'1','제품'+'부자재'+'부자재'))
			)
			union all 
			select 1 rn, '  I. 재료비' gubun,'카세트팀' dept_name, sum(in_amt) amt from doi_mat_amt where yyyymm = @YYYYMM and site = @SITE and sel_code = @SEL_CODE
			and 
			(
				(mat_gubun='카세트제품' and mat_class='원자재')
				or
				(MAT_GUBUN+mat_class+coalesce(자재대분류,'1') = '카세트제품'+'부자재'+'1')
			)*/
			union all 
			select 8 rn, '  II. 노무비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE 
			and 계정과목 in ('제)급여-임원','제)급여-직원','제)상여금-직원','제)제수당-연차','제)제수당-일반','제)퇴직급여-임원','제)퇴직급여-직원')
			group by 코스트센터
			union all
			select 23 rn, '  III. 경비' gubun,코스트센터 dept_name, sum(차변금액-대변금액) amt from doi_dept_cost where yyyymm = @YYYYMM and site = @SITE 
			and 계정과목 in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료','제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)'
			,'제)통신비','제)수도광열비-수도료','제)수도광열비-연료비','제)전력비','제)세금과공과-연금보험','제)세금과공과-일반','제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치'
			,'제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반','제)수선비','제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반','제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세'
			,'제)운반비-국내운송료','제)운반비-해외운송료','제)교육훈련비-사외','제)도서인쇄비','제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반','제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반','제)외주가공비','제)사용권자산상각비-건물','제)사용권자산상각비-차량','제)검사비','제)견본비')
			group by 코스트센터
		) A
		group by dept_name
	) Y
	on 1=1
	and X.rn = Y.rn 
	and X.gubun = Y.gubun 
	and X.dept_name = Y.dept_name
)
SELECT * INTO #sourceTable FROM sourceTable;

-- 동적 SQL 생성
		SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
	select * from #sourceTable
	union all 
	SELECT ''합계'' dept_name, rn, gubun, sum(amt) amt from #sourceTable group by rn, gubun
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
--		COMMIT TRANSACTION;
		
-- 임시 테이블 정리
DROP TABLE #sourceTable;
	END TRY
	
	BEGIN CATCH
--	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;