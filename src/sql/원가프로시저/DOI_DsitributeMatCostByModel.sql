
CREATE Procedure DOI_DsitributeMatCostByModel(
	@YYYYMM varchar(10),
 	@SITE varchar(4),
 	@SEL_CODE varchar(10)
 )
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + 도우모델
		FROM (SELECT DISTINCT TOP 500 도우모델 from (
				SELECT 도우모델 from DOI_MAT_COST where yyyymm=@YYYYMM and site=@SITE and sel_code = @SEL_CODE
				union all 
				select 'Z합계' 도우모델 
			  ) A
			  ORDER BY 1 )AS models ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + 도우모델 +'],0) as ['+도우모델+'],coalesce([' 
		FROM (SELECT DISTINCT TOP 500 도우모델 from (
				SELECT 도우모델 from DOI_MAT_COST where yyyymm=@YYYYMM and site=@SITE and sel_code = @SEL_CODE
				union all 
				select 'Z합계' 도우모델 
			  ) A
			  ORDER BY 1 )AS models ;
			select @Null_Columns=  '자재분류,자재대분류,자재중분류,자재명,자재번호,규격,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --select @Null_Columns;
		-- 동적 SQL 생성
		SET @SQL = '			
			WITH MAT_INFO AS 
			( 
				SELECT * 
				FROM 
				(	select DISTINCT 품번,품명,규격,재고자산종류 
					  from doi_matl_resc a 
					where a.YYYYMM = '''+@YYYYMM + ''' and site='''+@SITE + '''
				) as mat
				LEFT JOIN
				(	select DISTINCT 자재명,자재번호,자재자산분류,자재대분류,자재중분류 
					from doi_bom_mast a 
					where a.YYYYMM = '''+@YYYYMM + ''' and site='''+@SITE + '''
				)as BOM ON (mat.품번 = bom.자재번호)
			)
		SELECT 
		    '+ @Null_Columns +'
		FROM
		(select	IIF(a.mat_class = ''원자재'', ''원자재'', ''부자재'') as 자재분류 ,coalesce(b.자재대분류,a.mat_class) as 자재대분류,b.자재중분류,b.자재명,
				a.자재번호,b.규격,
				a.도우모델,a.배부금액
				--a.*,b.*
			from	DOI_MAT_COST a
			 left join 	mat_info b ON(a.자재번호=b.자재번호)
			where
				a.YYYYMM = '''+@YYYYMM + ''' and site='''+@SITE + '''  and sel_code =''' + @SEL_CODE + '''
			union all
			select 자재분류, 자재대분류, 자재중분류, 자재명, 자재번호, 규격, ''Z합계'' 도우모델, sum(배부금액) 배부금액 from (
				select	IIF(a.mat_class = ''원자재'', ''원자재'', ''부자재'') as 자재분류 ,coalesce(b.자재대분류,a.mat_class) as 자재대분류,b.자재중분류,b.자재명,
						a.자재번호,b.규격,
						a.도우모델,a.배부금액
						--a.*,b.*
					from	DOI_MAT_COST a
					 left join 	mat_info b ON(a.자재번호=b.자재번호)
					where
						a.YYYYMM = '''+@YYYYMM + ''' and site='''+@SITE + '''  and sel_code =''' + @SEL_CODE + '''
			)A 
			group by 자재분류, 자재대분류, 자재중분류, 자재명, 자재번호, 규격
		) AS SourceTable
		PIVOT 
		(
		    SUM(배부금액)
		    FOR 도우모델 IN (' + @Columns + ')
		) AS PivotTable
		order by 1,2 desc;';
		-- 동적 SQL 실행
		--select @SQL;
		EXEC sp_executesql @SQL;
		COMMIT TRANSACTION;
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;		
