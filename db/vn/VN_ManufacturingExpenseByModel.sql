CREATE OR ALTER Procedure VN_ManufacturingExpenseByModel(

	@YYYYMM varchar(10),

 	@SITE varchar(4),

 	@SEL_CODE varchar(10)

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

						SELECT DISTINCT 구분, replace(도우모델,' ','') as model 

						FROM doi_mat_cost 

						where yyyymm=@YYYYMM 

						  and site=@SITE 

						  and sel_code=@SEL_CODE

						  --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

						group by 구분, 도우모델

						UNION 

						SELECT 구분, replace(model,' ','') as model 

						  from doi_expen_matl 

						 where yyyymm=@YYYYMM 

						   and site=@SITE 

						   and sel_code=@SEL_CODE 

						   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

						group by 구분, model 

						UNION

						SELECT 'Z' 구분, CONCAT(구분, '합계') model 

						  FROM (

								SELECT DISTINCT 구분 

								  from doi_mat_cost 

								 where yyyymm=@YYYYMM 

								   and site=@SITE 

								   and sel_code=@SEL_CODE

						  		  -- and not (in_qty = 0 and out_qty = 0 and loss_qty = 0) 

								 group by 구분 

								 UNION 

								 SELECT 구분 

								   FROM doi_expen_matl 

								  where yyyymm=@YYYYMM 

								    and site=@SITE 

								    and sel_code=@SEL_CODE 								    

						   			and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

								  group by 구분

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

						SELECT DISTINCT 구분, replace(도우모델,' ','') as model 

						  FROM doi_mat_cost 

						 where yyyymm=@YYYYMM 

						   and site=@SITE 

						   and sel_code=@SEL_CODE 

						   --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

						group by 구분, 도우모델 

						UNION 

						SELECT 구분, replace(model,' ','') as model 

						  from doi_expen_matl 

						 where yyyymm=@YYYYMM 

						   and site=@SITE 

						   and sel_code=@SEL_CODE 

						   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

						group by 구분, model 

						UNION

						SELECT 'Z' 구분, CONCAT(구분, '합계') model 

						  FROM (

							SELECT DISTINCT 구분 

							  from doi_mat_cost 

							 where yyyymm=@YYYYMM 

							   and site=@SITE 

							   and sel_code=@SEL_CODE

							   --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

							group by 구분 

							UNION 

							SELECT 구분 

							  FROM doi_expen_matl 

							 where yyyymm=@YYYYMM 

							   and site=@SITE 

							   and sel_code=@SEL_CODE

							   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)

							group by 구분

						)a

						UNION

						SELECT 'Z' 구분, '합계' model

					) A 

				) A 

				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			

						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;

			select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns





	-- ===== [세분 기준 재작성] 금액(#amt) + 골격(#skel) + 소스(#sourceTable) =====

	-- 재료비: doi_mat_cost(도우모델 배부금액)

	-- 노무/경비: doi_expen_matl → doi_dept_cost(계정과목=ACCT_NAME) 브리지 → doi_acct.acct=계정코드

	--            항목 = 세분(경영계획과목 우선, 없으면 상위계정과목), 섹션 = 계정코드 접두(622 직접노무 / 627 간접경비)

	IF OBJECT_ID('tempdb..#amt') IS NOT NULL DROP TABLE #amt;

	SELECT 구분, model, sec, item, MIN(iord) iord, SUM(amt) amt

	INTO #amt

	FROM (

				select mc.구분, replace(mc.도우모델,' ','') model, 1 sec, case when m.품목자산분류=N'Raw Material' and m.자재소분류 like N'%Glass%' then N'원재료_원장' when m.품목자산분류=N'Raw Material' and m.자재소분류 like N'PF%' then N'원재료_PF' when m.품목자산분류=N'Raw Material' and m.자재소분류 like N'PL%' then N'원재료_PL' when m.품목자산분류=N'Raw Material' and upper(m.자재소분류) like N'%CHEMICAL%' then N'원재료_약액' when m.품목자산분류=N'Sub Material' then N'부재료비 (6272)' else N'원재료_기타' end item, CAST(case when m.품목자산분류=N'Raw Material' and m.자재소분류 like N'%Glass%' then 1 when m.품목자산분류=N'Raw Material' and m.자재소분류 like N'PF%' then 3 when m.품목자산분류=N'Raw Material' and m.자재소분류 like N'PL%' then 4 when m.품목자산분류=N'Raw Material' and upper(m.자재소분류) like N'%CHEMICAL%' then 5 when m.품목자산분류=N'Sub Material' then 6 else 9 end AS bigint) iord, mc.배부금액 amt from doi_mat_cost mc left join DOI_VN_MATERIAL m on m.자재번호=mc.자재번호 and m.yyyymm=mc.yyyymm where mc.yyyymm=@YYYYMM and mc.site=@SITE and mc.sel_code=@SEL_CODE

		union all

		select e.구분, replace(e.model,' ','') model,

		       case when left(dc.계정코드,4)='6272' then 1 when left(dc.계정코드,3)='622' then 2 else 3 end sec,

		       case when left(dc.계정코드,4)='6272' then N'부재료비 (6272)' when e.ACCT_NAME=N'공구 및 도구비용 - 상각비용' then N'제)공구 및 도구 비용 - 상각비용' when e.ACCT_NAME=N'공구 및 도구비용 - 일회성비용' then N'제)공구 및 도구 비용 -일회성비용' else REPLACE(a.상위계정과목,N'(간접)',N'') end item,

		       MIN(TRY_CONVERT(bigint, dc.계정코드)) iord,

		       sum(e.[in]) amt

		from doi_expen_matl e

		join (select distinct yyyymm,site,계정과목,계정코드 from doi_dept_cost) dc on dc.yyyymm=e.yyyymm and dc.site=e.site and dc.계정과목=e.ACCT_NAME

		join doi_acct a on a.yyyymm=e.yyyymm and a.site=e.site and a.acct=dc.계정코드

		where e.yyyymm=@YYYYMM and e.site=@SITE and e.sel_code=@SEL_CODE

		  and left(dc.계정코드,3) in ('622','627') and left(dc.계정코드,4)<>'6272'

		  and ISNULL(REPLACE(a.상위계정과목,N'(간접)',N''),'')<>''

		group by e.구분, replace(e.model,' ',''), case when left(dc.계정코드,4)='6272' then 1 when left(dc.계정코드,3)='622' then 2 else 3 end, case when left(dc.계정코드,4)='6272' then N'부재료비 (6272)' when e.ACCT_NAME=N'공구 및 도구비용 - 상각비용' then N'제)공구 및 도구 비용 - 상각비용' when e.ACCT_NAME=N'공구 및 도구비용 - 일회성비용' then N'제)공구 및 도구 비용 -일회성비용' else REPLACE(a.상위계정과목,N'(간접)',N'') end

	) t

	GROUP BY 구분, model, sec, item;



	-- 고정 골격 (재료2 + 직접노무11 + 간접경비31), 데이터 없으면 0, 목록 밖(공구도구 등)은 제외

	IF OBJECT_ID('tempdb..#skel') IS NOT NULL DROP TABLE #skel;

	CREATE TABLE #skel(rn int, sec int, item nvarchar(200), gubun nvarchar(200));

	INSERT #skel(rn, sec, item, gubun)

	SELECT sec*10000 + seq*10, sec, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item

	FROM (VALUES

		(1,1,N'원재료_원장'),(1,2,N'원재료_카세트 부품'),(1,3,N'원재료_PF'),(1,4,N'원재료_PL'),(1,5,N'원재료_약액'),(1,6,N'부재료비 (6272)'),

		(2,1,N'제)급여-직원'),(2,2,N'제)상여금'),(2,3,N'제)제수당'),(2,4,N'제)퇴직급여'),(2,5,N'제)주식보상비용'),(2,6,N'제)급여-사회보험료'),(2,7,N'제)급여-건강보험'),(2,8,N'제)급여-노동자실업보험료'),(2,9,N'제)급여-노동자노조비'),(2,10,N'제)급여-개인소득세'),(2,11,N'제)급여-기타'),

		(3,1,N'제)직원급여'),(3,2,N'제)상여금'),(3,3,N'제)제수당'),(3,4,N'제)퇴직급여'),(3,5,N'제)주식보상비용'),(3,6,N'제)급여-사회보험료'),(3,7,N'제)급여-건강보험'),(3,8,N'제)급여-노동자실업보험료'),(3,9,N'제)급여-노동자노조비'),(3,10,N'제)급여-개인소득세'),(3,11,N'제)급여-기타'),

		(3,12,N'제)급여-기타비용'),(3,13,N'제)여비교통비'),(3,14,N'제)통신비'),(3,15,N'제)수도광열비'),(3,16,N'제)전력비'),(3,17,N'제)감가상각비'),(3,18,N'제)지급임차료'),(3,19,N'제)수선비'),(3,20,N'제)보험료'),(3,21,N'제)차량유지비'),(3,22,N'제)운반비'),(3,23,N'제)교육훈련비'),

		(3,24,N'제)도서인쇄비'),(3,25,N'제)소모품비'),(3,26,N'제)지급수수료'),(3,27,N'제)외주가공비'),(3,28,N'제)사용권자산감가상각비'),(3,29,N'제)검사비'),(3,30,N'제)견본비'),(3,31,N'기술지원 및 기술이전비')

	) v(sec,seq,item);

	INSERT #skel(rn, sec, item, gubun) VALUES

		(10000,1,N'__H1',N'  I. 재료비'),

		(20000,2,N'__H2',N'  II. 직접노무비'),

		(30000,3,N'__H3',N'  III. 간접제조경비'),

		(90000,9,N'__T', N'  IV. 당기총제조원가');

	-- 공구 및 도구비용 별도 2항목 ((12) 뒤, 감가상각비에서 제외)

	INSERT #skel(rn, sec, item, gubun) VALUES

		(30125,3,N'제)공구 및 도구 비용 - 상각비용', N'    (1-1) 제)공구 및 도구 비용 - 상각비용'),

		(30126,3,N'제)공구 및 도구 비용 -일회성비용', N'    (1-2) 제)공구 및 도구 비용 -일회성비용');



	IF OBJECT_ID('tempdb..#sourceTable') IS NOT NULL DROP TABLE #sourceTable;

	;WITH mdl AS (SELECT DISTINCT 구분, model FROM #amt),

	matched AS (SELECT v.구분, v.model, v.sec, sk.rn, v.amt FROM #amt v JOIN #skel sk ON sk.sec=v.sec AND sk.item=v.item),

	amt_item AS (SELECT 구분, model, rn, SUM(amt) amt FROM matched GROUP BY 구분, model, rn),

	amt_hdr  AS (SELECT 구분, model, sec*10000 rn, SUM(amt) amt FROM matched GROUP BY 구분, model, sec),

	amt_tot  AS (SELECT 구분, model, 90000 rn, SUM(amt) amt FROM matched GROUP BY 구분, model),

	amt_all  AS (SELECT * FROM amt_item UNION ALL SELECT * FROM amt_hdr UNION ALL SELECT * FROM amt_tot)

	SELECT m.구분, m.model, sk.rn, sk.gubun, CAST(ISNULL(a.amt,0) AS decimal(18,2)) amt

	INTO #sourceTable

	FROM mdl m CROSS JOIN #skel sk

	LEFT JOIN amt_all a ON a.구분=m.구분 AND a.model=m.model AND a.rn=sk.rn;



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

