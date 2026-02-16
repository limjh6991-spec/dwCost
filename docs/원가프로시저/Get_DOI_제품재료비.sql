CREATE   Procedure Get_DOI_제품재료비(
	@YYYYMM varchar(10),
 	@SITE varchar(4)
 )
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		--declare @YYYYMM varchar(10)='202510', @SITE varchar(4)='HQ';
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + 도우모델
		FROM (SELECT DISTINCT TOP 500 도우모델 from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE
			  ORDER BY 1 )AS 도우모델 ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + 도우모델 +'],0) as ['+도우모델+'],coalesce([' 
		FROM (SELECT DISTINCT TOP 500 도우모델 from doi_mat_cost where yyyymm=@YYYYMM  and site=@SITE
			  ORDER BY 1 )AS 도우모델 ;
			select @Null_Columns=  '순서,구분,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]','');
		-- 동적 SQL 생성
		SET @SQL = '
		SELECT 
		    '+ @Null_Columns +'
		FROM
		   (select 1 순서,''원재료_원장'' 구분,도우모델,sum(배부금액) AMT from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''원자재''+''원자재'' group by 구분,도우모델 union all
			select 2,''원재료_카세트 부품'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''원자재''+''카세트'' group by 구분,도우모델 union all
			select 3,''부재료_필름'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''부자재''+''필름'' group by 구분,도우모델 union all
			select 4,''부재료_트레이'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''부자재''+''트레이'' group by 구분,도우모델 union all
			select 5,''부재료_약액'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+coalesce(자재대분류,''1'') =''약액''+''1'' group by 구분,도우모델 union all
			select 6,''부재료_기타'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+coalesce(자재대분류,''1'') in (''부자재''+''1'',''부자재''+''부자재'',''부자재''+''카세트'') group by 구분,도우모델
		) AS SourceTable
		PIVOT 
		(
		    SUM(AMT)
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

