CREATE               Procedure DOI_ManufacturingExpenseByModel_세목(
	@YYYYMM varchar(10),
 	@SITE varchar(4)
 )
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		--declare @YYYYMM varchar(10)=@YYYYMM, @SITE varchar(4)=@SITE;
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + model
		FROM (SELECT TOP 500 CONCAT(구분, model) model 
				FROM (
					SELECT DISTINCT 구분, model 
					FROM (
						SELECT DISTINCT 구분, replace(도우모델,' ','') as model FROM doi_mat_cost where yyyymm=@YYYYMM and site=@SITE  group by 구분, 도우모델 UNION 
						SELECT 구분, replace(model,' ','') as model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE group by 구분, model UNION
						SELECT 'Z' 구분, CONCAT(구분, '합계') model FROM (
							SELECT DISTINCT 구분 from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE  group by 구분 UNION 
							SELECT 구분 FROM doi_expen_matl where yyyymm=@YYYYMM and site=@SITE group by 구분
						)a
						UNION
						SELECT 'Z' 구분, '합계' model
					) A 
				) A 
				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			
						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
		FROM (SELECT TOP 500 CONCAT(구분, model) model 
				FROM (
					SELECT DISTINCT 구분, model 
					FROM (
						SELECT DISTINCT 구분, replace(도우모델,' ','') as model FROM doi_mat_cost where yyyymm=@YYYYMM and site=@SITE  group by 구분, 도우모델 UNION 
						SELECT 구분, replace(model,' ','') as model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE group by 구분, model UNION
						SELECT 'Z' 구분, CONCAT(구분, '합계') model FROM (
							SELECT DISTINCT 구분 from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE  group by 구분 UNION 
							SELECT 구분 FROM doi_expen_matl where yyyymm=@YYYYMM and site=@SITE group by 구분
						)a
						UNION
						SELECT 'Z' 구분, '합계' model
					) A 
				) A 
				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			
						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;
			select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns


with sourceTable as (
	select X.*, COALESCE(Y.amt,0) amt from (
		select * from (
			SELECT DISTINCT TOP 500 구분, model 
			FROM (
				SELECT DISTINCT 구분, replace(도우모델,' ','') as model FROM doi_mat_cost where yyyymm=@YYYYMM and site=@SITE  group by 구분, 도우모델 UNION 
				SELECT 구분, replace(model,' ','') as model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE group by 구분, model
			) A 
		) A 
		cross join 
		(
		select 1 rn, '  I. 재료비' gubun
		union all select 2 rn, '    (1) 원재료_원장' gubun
		union all select 3 rn, '    (2) 원재료_카세트 부품' gubun
		union all select 4 rn, '    (3) 부재료_필름' gubun
		union all select 5 rn, '    (4) 부재료_트레이' gubun
		union all select 6 rn, '    (5) 부재료_약액' gubun
		union all select 7 rn, '    (6) 부재료_기타' gubun
		union all select 8 rn, '  II. 노무비' gubun
		union all select 9 rn, '    (1) 제)임원급여' gubun
		union all select 10 rn, '      1. 제)급여-임원' gubun
		union all select 11 rn, '    (2) 제)직원급여' gubun
		union all select 12 rn, '      1. 제)급여-직원' gubun
		union all select 13 rn, '    (3) 제)상여금' gubun
		union all select 14 rn, '      1. 제)상여금-직원' gubun
		union all select 15 rn, '    (4) 제)제수당' gubun
		union all select 16 rn, '      1. 제)제수당-연차' gubun
		union all select 17 rn, '      2. 제)제수당-일반' gubun
		union all select 18 rn, '    (5) 제)퇴직급여' gubun
		union all select 19 rn, '      1. 제)퇴직급여-임원' gubun
		union all select 20 rn, '      2. 제)퇴직급여-직원' gubun
		union all select 21 rn, '    (6) 제)주식보상비용' gubun
		union all select 22 rn, '      1. 제)주식보상비용' gubun
		union all select 23 rn, '  III. 경비' gubun
		union all select 24 rn, '    (1) 제)복리후생비' gubun
		union all select 25 rn, '      1. 제)복리후생비-건강,장기요양보험' gubun
		union all select 26 rn, '      2. 제)복리후생비-사내식대' gubun
		union all select 27 rn, '      3. 제)복리후생비-외부식대등' gubun
		union all select 28 rn, '      4. 제)복리후생비-경조사비' gubun
		union all select 29 rn, '      5. 제)복리후생비-일반' gubun
		union all select 30 rn, '      6. 제)복리후생비-의료' gubun
		union all select 31 rn, '    (2) 제)여비교통비' gubun
		union all select 32 rn, '      1. 제)여비교통비-국내출장경비(법인)' gubun
		union all select 33 rn, '      2. 제)여비교통비-국내출장경비(기타)' gubun
		union all select 34 rn, '    (3) 제)통신비' gubun
		union all select 35 rn, '      1. 제)통신비' gubun
		union all select 36 rn, '    (4) 제)수도광열비' gubun
		union all select 37 rn, '      1. 제)수도광열비-수도료' gubun
		union all select 38 rn, '      2. 제)수도광열비-연료비' gubun
		union all select 39 rn, '    (5) 제)전력비' gubun
		union all select 40 rn, '      1. 제)전력비' gubun
		union all select 41 rn, '    (6) 제)세금과공과' gubun
		union all select 42 rn, '      1. 제)세금과공과-연금보험' gubun
		union all select 43 rn, '      2. 제)세금과공과-일반' gubun
		union all select 44 rn, '    (7) 제)감가상각비' gubun
		union all select 45 rn, '      1. 제)감가상각비-건물' gubun
		union all select 46 rn, '      2. 제)감가상각비-구축물' gubun
		union all select 47 rn, '      3. 제)감가상각비-기계장치' gubun
		union all select 48 rn, '      4. 제)감가상각비-공구와기구' gubun
		union all select 49 rn, '      5. 제)감가상각비-비품' gubun
		union all select 50 rn, '    6. 제)감가상각비-시설장치' gubun
		union all select 51 rn, '    (8) 제)지급임차료' gubun
		union all select 52 rn, '      1. 제)지급임차료-건물' gubun
		union all select 53 rn, '      2. 제)지급임차료-차량' gubun
		union all select 54 rn, '      3. 제)지급임차료-일반' gubun
		union all select 55 rn, ' (9) 제)수선비' gubun
		union all select 56 rn, '      1. 제)수선비' gubun
		union all select 57 rn, '    (10) 제)보험료' gubun
		union all select 58 rn, '      1. 제)보험료-고용,산재보험' gubun
		union all select 59 rn, '      2. 제)보험료-차량' gubun
		union all select 60 rn, '      3. 제)보험료-건물' gubun
		union all select 61 rn, '      4. 제)보험료-일반' gubun
		union all select 62 rn, '    (11) 제)차량유지비' gubun
		union all select 63 rn, '      1. 제)차량유지비-유류비' gubun
		union all select 64 rn, '      2. 제)차량유지비-관리비' gubun
		union all select 65 rn, '      3. 제)차량유지비-일반' gubun
		union all select 66 rn, '      4. 제)차량유지비-자동차세' gubun
		union all select 67 rn, '    (12) 제)운반비' gubun
		union all select 68 rn, '      1. 제)운반비-국내운송료' gubun
		union all select 69 rn, '      2. 제)운반비-해외운송료' gubun
		union all select 70 rn, '    (13) 제)교육훈련비' gubun
		union all select 71 rn, '      1. 제)교육훈련비-사외' gubun
		union all select 72 rn, '    (14) 제)도서인쇄비' gubun
		union all select 73 rn, '      1. 제)도서인쇄비' gubun
		union all select 74 rn, '    (15) 제)소모품비' gubun
		union all select 75 rn, '      1. 제)소모품비-비품' gubun
		union all select 76 rn, '      2. 제)소모품비-사무용품' gubun
		union all select 77 rn, '      3. 제)소모품비-일반' gubun
		union all select 78 rn, '    (16) 제)지급수수료' gubun
		union all select 79 rn, '      1. 제)지급수수료-유지보수료' gubun
		union all select 80 rn, '      2. 제)지급수수료-검사.측정료' gubun
		union all select 81 rn, '      3. 제)지급수수료-일반' gubun
		union all select 82 rn, '    (17) 제)외주가공비' gubun
		union all select 83 rn, '      1. 제)외주가공비' gubun
		union all select 84 rn, '    (18) 제)사용권자산감가상각비' gubun
		union all select 85 rn, '      1. 제)사용권자산상각비-건물' gubun
		union all select 86 rn, '      2. 제)사용권자산상각비-차량' gubun
		union all select 87 rn, '    (19) 제)검사비' gubun
		union all select 88 rn, '      1. 제)검사비' gubun
		union all select 89 rn, '    (20) 제)견본비' gubun
		union all select 90 rn, '      1. 제)견본비' gubun
		union all select 91 rn, '  IV. 당기총제조원가' gubun
		) B 
	) X 
	left join (
		select 1 rn, '  I. 재료비' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and 
		(
			(mat_class+자재대분류 ='원자재'+'원자재')
			or 
			(mat_class+자재대분류 ='원자재'+'카세트' )
			or 
			(mat_class+자재대분류 ='부자재'+'필름' )
			or
			(mat_class+자재대분류 ='부자재'+'트레이' )
			or 
			(mat_class+coalesce(자재대분류,'1') ='약액'+'1'  )
			or
			(mat_class+coalesce(자재대분류,'1') in ('부자재'+'1','부자재'+'부자재','부자재'+'카세트','더미글라스'+'부자재') )
		)
		group by 구분,도우모델
		union all 
		select 2 rn, '    (1) 원재료_원장' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and mat_class+자재대분류 ='원자재'+'원자재'
		group by 구분,도우모델
		union all 
		select 3 rn, '    (2) 원재료_카세트 부품' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and (mat_class+자재대분류 ='원자재'+'카세트' )
		group by 구분,도우모델		
		union all 
		select 4 rn, '    (3) 부재료_필름' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and (mat_class+자재대분류 ='부자재'+'필름' )
		group by 구분,도우모델
		union all 
		select 5 rn, '    (4) 부재료_트레이' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and (mat_class+자재대분류 ='부자재'+'트레이' )
		group by 구분,도우모델
		union all 
		select 6 rn, '    (5) 부재료_약액' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and (mat_class+coalesce(자재대분류,'1') ='약액'+'1'  )
		group by 구분,도우모델
		union all
		select 7 rn, '    (6) 부재료_기타' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
		and (mat_class+coalesce(자재대분류,'1') in ('부자재'+'1','부자재'+'부자재','부자재'+'카세트','더미글라스'+'부자재') )
		group by 구분,도우모델
		union all 
		select 8 rn, '  II. 노무비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE 
		and acct_name in ('제)급여-임원','제)급여-직원','제)상여금-직원','제)제수당-연차','제)제수당-일반','제)퇴직급여-임원','제)퇴직급여-직원')
		group by 구분,model
		union all 
		select 9 rn, '    (1) 제)임원급여' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)급여-임원' group by 구분,model
		union all
		select 10 rn, '      1. 제)급여-임원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)급여-임원' group by 구분,model
		union all
		select 11 rn, '    (2) 제)직원급여' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)급여-직원' group by 구분,model
		union all
		select 12 rn, '      1. 제)급여-직원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)급여-직원' group by 구분,model
		union all
		select 13 rn, '    (3) 제)상여금' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)상여금-직원' group by 구분,model
		union all
		select 14 rn, '      1. 제)상여금-직원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)상여금-직원' group by 구분,model
		union all 
		select 15 rn, '    (4) 제)제수당' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in('제)제수당-연차','제)제수당-일반') group by 구분,model
		union all 
		select 16 rn, '      1. 제)제수당-연차' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)제수당-연차' group by 구분,model
		union all 
		select 17 rn, '      2. 제)제수당-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)제수당-일반' group by 구분,model
		union all 
		select 18 rn, '    (5) 제)퇴직급여' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)퇴직급여-임원','제)퇴직급여-직원') group by 구분,model
		union all 
		select 19 rn, '      1. 제)퇴직급여-임원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)퇴직급여-임원' group by 구분,model
		union all 
		select 20 rn, '      2. 제)퇴직급여-직원' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)퇴직급여-직원' group by 구분,model
		union all 
		select 21 rn, '    (6) 제)주식보상비용' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)주식보상비용' group by 구분,model
		union all 
		select 22 rn, '      1. 제)주식보상비용' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)주식보상비용' group by 구분,model
		union all 
		select 23 rn, '  III. 경비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE 
		and acct_name in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료','제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)'
		,'제)통신비','제)수도광열비-수도료','제)수도광열비-연료비','제)전력비','제)세금과공과-연금보험','제)세금과공과-일반','제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치'
		,'제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반','제)수선비','제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반','제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세'
		,'제)운반비-국내운송료','제)운반비-해외운송료','제)교육훈련비-사외','제)도서인쇄비','제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반','제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반','제)외주가공비','제)사용권자산상각비-건물','제)사용권자산상각비-차량','제)검사비','제)견본비')
		group by 구분,model
		union all 
		select 24 rn, '    (1) 제)복리후생비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료') group by 구분,model
		union all 
		select 25 rn, '      1. 제)복리후생비-건강,장기요양보험' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-건강,장기요양보험' group by 구분,model
		union all 
		select 26 rn, '      2. 제)복리후생비-사내식대' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-사내식대' group by 구분,model
		union all 
		select 27 rn, '      3. 제)복리후생비-외부식대등' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-외부식대등' group by 구분,model
		union all 
		select 28 rn, '      4. 제)복리후생비-경조사비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-경조사비' group by 구분,model
		union all 
		select 29 rn, '      5. 제)복리후생비-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-일반' group by 구분,model
		union all 
		select 30 rn, '      6. 제)복리후생비-의료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)복리후생비-의료' group by 구분,model
		union all 
		select 31 rn, '    (2) 제)여비교통비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)') group by 구분,model
		union all 
		select 32 rn, '      1. 제)여비교통비-국내출장경비(법인)' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)여비교통비-국내출장경비(법인)' group by 구분,model
		union all 
		select 33 rn, '      2. 제)여비교통비-국내출장경비(기타)' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)여비교통비-국내출장경비(기타)' group by 구분,model
		union all 
		select 34 rn, '    (3) 제)통신비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)통신비' group by 구분,model
		union all 
		select 35 rn, '      1. 제)통신비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)통신비' group by 구분,model
		union all 
		select 36 rn, '    (4) 제)수도광열비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)수도광열비-수도료','제)수도광열비-연료비') group by 구분,model
		union all 
		select 37 rn, '      1. 제)수도광열비-수도료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수도광열비-수도료' group by 구분,model
		union all 
		select 38 rn, '      2. 제)수도광열비-연료비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수도광열비-연료비' group by 구분,model
		union all 
		select 39 rn, '    (5) 제)전력비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)전력비' group by 구분,model
		union all 
		select 40 rn, '      1. 제)전력비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)전력비' group by 구분,model
		union all 
		select 41 rn, '    (6) 제)세금과공과' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)세금과공과-연금보험','제)세금과공과-일반') group by 구분,model
		union all 
		select 42 rn, '      1. 제)세금과공과-연금보험' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)세금과공과-연금보험' group by 구분,model
		union all 
		select 43 rn, '      2. 제)세금과공과-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)세금과공과-일반' group by 구분,model
		union all 
		select 44 rn, '    (7) 제)감가상각비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치') group by 구분,model
		union all 
		select 45 rn, '      1. 제)감가상각비-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-건물' group by 구분,model
		union all 
		select 46 rn, '      2. 제)감가상각비-구축물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-구축물' group by 구분,model
		union all 
		select 47 rn, '      3. 제)감가상각비-기계장치' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-기계장치' group by 구분,model
		union all 
		select 48 rn, '      4. 제)감가상각비-공구와기구' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-공구와기구' group by 구분,model
		union all 
		select 49 rn, '      5. 제)감가상각비-비품' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-비품' group by 구분,model
		union all 
		select 50 rn, '      6. 제)감가상각비-시설장치' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)감가상각비-시설장치' group by 구분,model
		union all 
		select 51 rn, '    (8) 제)지급임차료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반') group by 구분,model
		union all 
		select 52 rn, '      1. 제)지급임차료-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급임차료-건물' group by 구분,model
		union all 
		select 53 rn, '      2. 제)지급임차료-차량' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급임차료-차량' group by 구분,model
		union all 
		select 54 rn, '      3. 제)지급임차료-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급임차료-일반' group by 구분,model
		union all 
		select 55 rn, '    (9) 제)수선비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수선비' group by 구분,model
		union all 
		select 56 rn, '      1. 제)수선비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)수선비' group by 구분,model
		union all 
		select 57 rn, '    (10) 제)보험료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반') group by 구분,model
		union all 
		select 58 rn, '      1. 제)보험료-고용,산재보험' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-고용,산재보험' group by 구분,model
		union all 
		select 59 rn, '      2. 제)보험료-차량' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-차량' group by 구분,model
		union all 
		select 60 rn, '      3. 제)보험료-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-건물' group by 구분,model
		union all 
		select 61 rn, '      4. 제)보험료-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)보험료-일반' group by 구분,model
		union all 
		select 62 rn, '    (11) 제)차량유지비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세') group by 구분,model
		union all 
		select 63 rn, '      1. 제)차량유지비-유류비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-유류비' group by 구분,model
		union all 
		select 64 rn, '      2. 제)차량유지비-관리비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-관리비' group by 구분,model
		union all 
		select 65 rn, '      3. 제)차량유지비-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-일반' group by 구분,model
		union all 
		select 66 rn, '      4. 제)차량유지비-자동차세' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)차량유지비-자동차세' group by 구분,model
		union all 
		select 67 rn, '    (12) 제)운반비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)운반비-국내운송료','제)운반비-해외운송료') group by 구분,model
		union all 
		select 68 rn, '      1. 제)운반비-국내운송료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)운반비-국내운송료' group by 구분,model
		union all 
		select 69 rn, '      2. 제)운반비-해외운송료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)운반비-해외운송료' group by 구분,model
		union all 
		select 70 rn, '    (13) 제)교육훈련비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)교육훈련비-사외') group by 구분,model
		union all 
		select 71 rn, '      1. 제)교육훈련비-사외' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)교육훈련비-사외' group by 구분,model
		union all 
		select 72 rn, '    (14) 제)도서인쇄비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)도서인쇄비' group by 구분,model
		union all 
		select 73 rn, '      1. 제)도서인쇄비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)도서인쇄비' group by 구분,model
		union all 
		select 74 rn, '    (15) 제)소모품비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반') group by 구분,model
		union all 
		select 75 rn, '      1. 제)소모품비-비품' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)소모품비-비품' group by 구분,model
		union all 
		select 76 rn, '      2. 제)소모품비-사무용품' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)소모품비-사무용품' group by 구분,model
		union all 
		select 77 rn, '      3. 제)소모품비-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)소모품비-일반' group by 구분,model
		union all 
		select 78 rn, '    (16) 제)지급수수료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반') group by 구분,model
		union all 
		select 79 rn, '      1. 제)지급수수료-유지보수료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급수수료-유지보수료' group by 구분,model
		union all 
		select 80 rn, '      2. 제)지급수수료-검사.측정료' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급수수료-검사.측정료' group by 구분,model
		union all 
		select 81 rn, '      3. 제)지급수수료-일반' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)지급수수료-일반' group by 구분,model
		union all 
		select 82 rn, '    (17) 제)외주가공비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)외주가공비' group by 구분,model
		union all 
		select 83 rn, '      1. 제)외주가공비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)외주가공비' group by 구분,model
		union all 
		select 84 rn, '    (18) 제)사용권자산감가상각비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name in ('제)사용권자산상각비-건물','제)사용권자산상각비-차량') group by 구분,model
		union all 
		select 85 rn, '      1. 제)사용권자산상각비-건물' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)사용권자산상각비-건물' group by 구분,model
		union all 
		select 86 rn, '      2. 제)사용권자산상각비-차량' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)사용권자산상각비-차량' group by 구분,model
		union all 
		select 87 rn, '    (19) 제)검사비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)검사비' group by 구분,model
		union all 
		select 88 rn, '      1. 제)검사비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)검사비' group by 구분,model
		union all 
		select 89 rn, '    (20) 제)견본비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)견본비' group by 구분,model
		union all 
		select 90 rn, '      1. 제)견본비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE and acct_name='제)견본비' group by 구분,model
		union all		
		select 91 rn, '  IV. 당기총제조원가' gubun,구분,model, sum(amt) amt 
		from(
			select 1 rn, '  I. 재료비' gubun,구분,도우모델 AS MODEL, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
			and 
			(
				(mat_class+자재대분류 ='원자재'+'원자재')
				or 
				(mat_class+자재대분류 ='원자재'+'카세트' )
				or 
				(mat_class+자재대분류 ='부자재'+'필름' )
				or
				(mat_class+자재대분류 ='부자재'+'트레이' )
				or 
				(mat_class+coalesce(자재대분류,'1') ='약액'+'1'  )
				or
				(mat_class+coalesce(자재대분류,'1') in ('부자재'+'1','부자재'+'부자재','부자재'+'카세트') )
			)
			group by 구분,도우모델
			union all
			select 8 rn, '  II. 노무비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE 
			and acct_name in ('제)급여-임원','제)급여-직원','제)상여금-직원','제)제수당-연차','제)제수당-일반','제)퇴직급여-임원','제)퇴직급여-직원')
			group by 구분,model
			union all
			select 23 rn, '  III. 경비' gubun,구분,model, sum([in]) amt from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE 
			and acct_name in ('제)복리후생비-건강,장기요양보험','제)복리후생비-사내식대','제)복리후생비-외부식대등','제)복리후생비-경조사비','제)복리후생비-일반','제)복리후생비-의료','제)여비교통비-국내출장경비(법인)','제)여비교통비-국내출장경비(기타)'
			,'제)통신비','제)수도광열비-수도료','제)수도광열비-연료비','제)전력비','제)세금과공과-연금보험','제)세금과공과-일반','제)감가상각비-건물','제)감가상각비-구축물','제)감가상각비-기계장치','제)감가상각비-공구와기구','제)감가상각비-비품','제)감가상각비-시설장치'
			,'제)지급임차료-건물','제)지급임차료-차량','제)지급임차료-일반','제)수선비','제)보험료-고용,산재보험','제)보험료-차량','제)보험료-건물','제)보험료-일반','제)차량유지비-유류비','제)차량유지비-관리비','제)차량유지비-일반','제)차량유지비-자동차세'
			,'제)운반비-국내운송료','제)운반비-해외운송료','제)교육훈련비-사외','제)도서인쇄비','제)소모품비-비품','제)소모품비-사무용품','제)소모품비-일반','제)지급수수료-유지보수료','제)지급수수료-검사.측정료','제)지급수수료-일반','제)외주가공비','제)사용권자산상각비-건물','제)사용권자산상각비-차량','제)검사비','제)견본비')
			group by 구분,model
		) A
		group by 구분,model
	) Y
	on 1=1
	and X.rn = Y.rn 
	and X.gubun = Y.gubun 
	and X.구분 = Y.구분
	and X.model = replace(Y.model,' ','')
)
SELECT * INTO #sourceTable FROM sourceTable;

-- 동적 SQL 생성
		SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
	select CONCAT(구분,model) model, rn, gubun, amt from #sourceTable
	union all 
	select ''Z합계'' model, rn, gubun, sum(amt) amt from #sourceTable group by rn, gubun
	union all  
	select CONCAT(''Z'',구분,''합계'') model, rn, gubun, amt from (
		select rn, gubun, 구분, sum(amt) amt from #sourceTable group by rn, gubun, 구분 
	) a 	
) AS SourceTable
PIVOT 
(
	SUM(AMT)
	FOR model IN (' + @Columns + ')
) AS PivotTable
order by 1,2 desc;';
		
		-- 동적 SQL 실행
		--select @SQL;
		EXEC sp_executesql @SQL;
		COMMIT TRANSACTION;
-- 임시 테이블 정리
DROP TABLE #sourceTable;	
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
