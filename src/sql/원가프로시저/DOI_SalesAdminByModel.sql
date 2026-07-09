
CREATE                   Procedure DOI_SalesAdminByModel(
	@YYYYMM varchar(10),
 	@SITE varchar(4),
 	@SEL_CODE varchar(10)
 )
AS
BEGIN
	BEGIN TRY
		-- [FIX] 읽기전용 집계(동적 PIVOT) 프로시저: 불필요한 트랜잭션 제거
		--       (CATCH의 무조건 ROLLBACK이 오류를 마스킹해 resultset 미반환처럼 보이던 원인)
		--declare @YYYYMM varchar(10)=@yyyymm , @SITE varchar(4)=@site;
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + model
		FROM (SELECT DISTINCT TOP 500 model 
				FROM (
				SELECT DISTINCT model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
				union all
				SELECT 'Z합계' model
			  	)A
				ORDER BY 1 )AS 도우모델 ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
		FROM (SELECT DISTINCT TOP 500 model 
				FROM (
				SELECT DISTINCT model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
				union all
				SELECT 'Z합계' model
			  	)A
				ORDER BY 1 )AS 도우모델 ;
			select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns


with sourceTable as (
	select X.*, COALESCE(Y.amt,0) amt from (
		select * from (
			SELECT DISTINCT TOP 500 model 
			FROM (
				SELECT DISTINCT model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
			)A
			ORDER BY 1
		) A 
		cross join 
		(
		select 0 as rn, '    판관비 배부율 (제품별 매출비중)' as gubun
		union all select 1, '    (1) 판)임원급여'
/*		union all select 2, '      1. 판)급여-임원'*/
		union all select 3, '    (2) 판)직원급여'
/*		union all select 4, '      1. 판)급여-직원'*/
		union all select 5, '    (3) 판)상여금'
/*		union all select 6, '      1. 판)상여금-직원'*/
		union all select 7, '    (4) 판)제수당'
/*		union all select 8, '      1. 판)제수당-연차'
		union all select 9, '      2. 판)제수당-일반'*/
		union all select 10, '    (5) 판)퇴직급여'
/*		union all select 11, '      1. 판)퇴직급여-임원'
		union all select 12, '      2. 판)퇴직급여-직원'*/
		union all select 13, '    (6) 판)복리후생비'
/*		union all select 14, '      1. 판)복리후생비-건강,장기요양보험'
		union all select 15, '      2. 판)복리후생비-사내식대'
		union all select 16, '      3. 판)복리후생비-외부식대등'
		union all select 17, '      4. 판)복리후생비-경조사비'
		union all select 18, '      5. 판)복리후생비-일반'
		union all select 19, '      6. 판)복리후생비-의료'*/
		union all select 20, '    (7) 판)여비교통비'
/*		union all select 21, '      1. 판)여비교통비-국내출장경비(법인)'
		union all select 22, '      2. 판)여비교통비-국내출장경비(기타)'
		union all select 23, '      3. 판)여비교통비-해외출장경비'
		union all select 24, '      4. 판)여비교통비-기타'*/
		union all select 25, '    (8) 판)접대비'
/*		union all select 26, '      1. 판)접대비-식대'
		union all select 27, '      2. 판)접대비-경조금'
		union all select 28, '      3. 판)접대비-일반'*/
		union all select 29, '    (9) 판)통신비'
/*		union all select 30, '      1. 판)통신비'*/
		union all select 31, '    (10) 판)수도광열비'
/*		union all select 32, '      1. 판)수도광열비-수도료'*/
		union all select 33, '    (11) 판)세금과공과'
/*		union all select 34, '      1. 판)세금과공과-연금보험'
		union all select 35, '      2. 판)세금과공과-사업소세'
		union all select 36, '      3. 판)세금과공과-재산세종부세'
		union all select 37, '      4. 판)세금과공과-일반'*/
		union all select 38, '    (12) 판)감가상각비'
/*		union all select 39, '      1. 판)감가상각비-건물'
		union all select 40, '      2. 판)감가상각비-기계장치'
		union all select 41, '      3. 판)감가상각비-차량운반구'
		union all select 42, '      4. 판)감가상각비-비품'
		union all select 43, '      5. 판)감가상각비-시설장치'*/
		union all select 44, '    (13) 판)지급임차료'
/*		union all select 45, '      1. 판)지급임차료-건물'
		union all select 46, '      2. 판)지급임차료-차량'
		union all select 47, '      3. 판)지급임차료-비품'
		union all select 48, '      4. 판)지급임차료-일반'*/
		union all select 49, '    (14) 판)수선비'
/*		union all select 50, '      1. 판)수선비'*/
		union all select 51, '    (15) 판)보험료'
/*		union all select 52, '      1. 판)보험료-산재,고용보험'
		union all select 53, '      2. 판)보험료-차량'
		union all select 54, '      3. 판)보험료-건물'
		union all select 55, '      4. 판)보험료-일반'*/
		union all select 56, '    (16) 판)차량유지비'
/*		union all select 57, '      1. 판)차량유지비-유류비'
		union all select 58, ' 2. 판)차량유지비-관리비'*/
/*		union all select 59, '      3. 판)차량유지비-일반'
		union all select 60, '      4. 판)차량유지비-자동차세'*/
		union all select 61, '    (17) 판)경상연구개발비'
/*		union all select 62, '      1. 판)경상연구개발비-일반'
		union all select 63, '      2. 판)경상연구개발비-개발소모품'
		union all select 64, '      3. 판)경상연구개발비-지급수수료'
		union all select 65, '      4. 판)경상연구개발비-국내출장경비(법인)'
		union all select 66, '      5. 판)경상연구개발비-국내출장경비(기타)'
		union all select 67, '      6. 판)경상연구개발비-해외출장경비'
		union all select 68, '      7. 판)경상연구개발비-해외출장경비(여비)'
		union all select 69, '      8. 판)경상연구개발비-사내식대'
		union all select 70, '      9. 판)경상연구개발비-외부식대등'
		union all select 71, '      10. 판)경상연구개발비-경조사비'
		union all select 72, '      11. 판)경상연구개발비(차량유지비-유류비)'
		union all select 73, '      12. 판)경상연구개발비(차량유지비-보험료)'
		union all select 74, '      13. 판)경상연구개발비(차량유지비-관리비)'
		union all select 75, '      14. 판)경상연구개발비(차량유지비-일반)'
		union all select 76, '      15. 판)경상연구개발비(차량유지비-자동차세)'
		union all select 77, '      16. 판)경상연구개발비(급여-임원)'
		union all select 78, '      17. 판)경상연구개발비(급여-직원)'
		union all select 79, '      18. 판)경상연구개발비(상여금-직원)'
		union all select 80, '      19. 판)경상연구개발비(제수당-연차)'
		union all select 81, '      20. 판)경상연구개발비(제수당-일반)'
		union all select 82, '      21. 판)경상연구개발비(잡급)'
		union all select 83, '      22. 판)경상연구개발비(퇴직급여-임원)'
		union all select 84, '      23. 판)경상연구개발비(퇴직급여-직원)'
		union all select 85, '      24. 판)경상연구개발비-건강,장기요양보험'
		union all select 86, '      25. 판)경상연구개발비-연금보험'
		union all select 87, '      26. 판)경상연구개발비-산재.고용보험'
		union all select 88, '      27. 판)경상연구개발비(지급임차료-건물)'
		union all select 89, '      28. 판)경상연구개발비(지급임차료-일반)'
		union all select 90, '      29. 판)경상연구개발비(지급임차료-차량)'
		union all select 91, '      30. 판)경상연구개발비-특허.심사료'*/
		union all select 92, '    (18) 판)운반비'
/*		union all select 93, '      1. 판)운반비-국내운송료'
		union all select 94, '      2. 판)운반비-해외운송료'*/
		union all select 95, '    (19) 판)교육훈련비'
/*		union all select 96, '      1. 판)교육훈련비-사외'*/
		union all select 97, '    (20) 판)도서인쇄비'
/*		union all select 98, '      1. 판)도서인쇄비'*/
		union all select 99, '    (21) 판)소모품비'
/*		union all select 100, '      1. 판)소모품비-비품'
		union all select 101, '      2. 판)소모품비-사무용품'
		union all select 102, '      3. 판)소모품비-전산용품'
		union all select 103, '      4. 판)소모품비-일반'*/
		union all select 104, '    (22) 판)지급수수료'
/*		union all select 105, '      1. 판)지급수수료-건물관리비'
		union all select 106, '      2. 판)지급수수료-보안용역료'
		union all select 107, '      3. 판)지급수수료-유지보수료'
		union all select 108, '      4. 판)지급수수료-금융.제증명'
		union all select 109, '      5. 판)지급수수료-감사.법률.자문'
		union all select 110, '      6. 판)지급수수료-특허.심사료'
		union all select 111, '      7. 판)지급수수료-일반'*/
		union all select 112, '    (23) 판)광고선전비'
/*		union all select 113, '      1. 판)광고선전비-IR'
		union all select 114, '      2. 판)광고선전비-일반'*/
		union all select 115, '    (24) 판)무형자산상각비'
/*		union all select 116, '      1. 판)무형자산상각비'*/
		union all select 117, '    (25) 판)견본비'
/*		union all select 118, '      1. 판)견본비'*/
		union all select 119, '    (26) 판)사용권자산감가상각비'
/*		union all select 120, '      1. 판)사용권자산상각비-건물'
		union all select 121, '      2. 판)사용권자산상각비-차량'*/
		union all select 122, '    (27) 판)주식보상비용'
/*		union all select 123, '      1. 판)주식보상비용'*/
		union all select 124, '    (28) 판)해외시장개척비'
/*		union all select 125, '      1. 판)해외시장개척비'
		union all select 126, '      2. 판)해외시장개척비(여비)'*/
		union all select 999, '    (29) 합계'
		) B 
	) X 
	left join (
	select 0 as rn, '    판관비 배부율 (제품별 매출비중)'as gubun, model, cast(amt/sum(amt) over() as numeric(10,3)) as amt
	from (
		select model, sum(dist_amt) as amt
		from doi_smce_cost
		where yyyymm = @yyyymm and site =  @site and sel_code=@SEL_CODE
		group by model
	) A
	union all
	select 1 as rn, '    (1) 판)임원급여' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name = '판)급여-임원' and sel_code=@SEL_CODE
	group by model
	union all
	select 3 as rn, '    (2) 판)직원급여' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name = '판)급여-직원' and sel_code=@SEL_CODE
	group by model
	union all
	select 5 as rn, '    (3) 판)상여금' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name = '판)상여금-직원' and sel_code=@SEL_CODE
	group by model
	union all
	select 7 as rn, '    (4) 판)제수당' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)제수당%' and sel_code=@SEL_CODE
	group by model
	union all
	select 10 as rn, '    (5) 판)퇴직급여' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)퇴직급여%' and sel_code=@SEL_CODE
	group by model
	union all
	select 13 as rn, '    (6) 판)복리후생비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)복리후생비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 20 as rn, '    (7) 판)여비교통비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)여비교통비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 25 as rn, '    (8) 판)접대비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)접대비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 29 as rn, '    (9) 판)통신비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)통신비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 31 as rn, '    (10) 판)수도광열비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)수도광열비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 33 as rn, '    (11) 판)세금과공과' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)세금과공과%' and sel_code=@SEL_CODE
	group by model
	union all
	select 38 as rn, '    (12) 판)감가상각비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)감가상각비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 44 as rn, '    (13) 판)지급임차료' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)지급임차료%' and sel_code=@SEL_CODE
	group by model
	union all
	select 49 as rn, '    (14) 판)수선비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)수선비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 51 as rn, '    (15) 판)보험료' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)보험료%' and sel_code=@SEL_CODE
	group by model
	union all
	select 56 as rn, '    (16) 판)차량유지비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)차량유지비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 61 as rn, '    (17) 판)경상연구개발비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)경상연구개발비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 92 as rn, '    (18) 판)운반비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)운반비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 95 as rn, '    (19) 판)교육훈련비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)교육훈련비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 97 as rn, '    (20) 판)도서인쇄비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)도서인쇄비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 99 as rn, '    (21) 판)소모품비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)소모품비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 104 as rn, '    (22) 판)지급수수료' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)지급수수료%' and sel_code=@SEL_CODE
	group by model
	union all
	select 112 as rn, '    (23) 판)광고선전비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)광고선전비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 115 as rn, '    (24) 판)무형자산상각비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)무형자산상각비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 117 as rn, '    (25) 판)견본비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)견본비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 119 as rn, '    (26) 판)사용권자산감가상각비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)사용권자산상각비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 122 as rn, '    (27) 판)주식보상비용' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)주식보상비용%' and sel_code=@SEL_CODE
	group by model
	union all
	select 124 as rn, '    (28) 판)해외시장개척비' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sub_name like '판)해외시장개척비%' and sel_code=@SEL_CODE
	group by model
	union all
	select 999 as rn, '    (29) 합계' as gubun, model, sum(dist_amt) as amt
	from doi_smce_cost
	where yyyymm = @yyyymm and site = @site and sel_code=@SEL_CODE
	group by model
	) Y
	on 1=1
	and X.rn = Y.rn 
	and X.gubun = Y.gubun 
	and X.model = Y.model
)
SELECT * INTO #sourceTable FROM sourceTable;

-- 동적 SQL 생성
		SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
	select * from #sourceTable
	union all 
	select ''Z합계'' model, rn, gubun, CASE WHEN RN=0 THEN 1 ELSE sum(amt) END amt from #sourceTable group by rn, gubun
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
		-- [FIX] COMMIT 제거(트랜잭션 미사용)
-- 임시 테이블 정리
--DROP TABLE #sourceTable;	
	END TRY
	
	BEGIN CATCH
	    -- [FIX] 트랜잭션 미사용이므로 무조건 ROLLBACK 제거(안전을 위해 잔여 트랜잭션만 정리)
	    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
