CREATE       Procedure Get_DOI_제품노무비(
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
		SELECT @Columns = COALESCE(@Columns + '], [', '') + model
		FROM (SELECT DISTINCT TOP 500 model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE
			  ORDER BY 1 )AS models ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + model +'],0) as ['+model+'],coalesce([' 
		FROM (SELECT DISTINCT TOP 500 model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE
			  ORDER BY 1 )AS models ;
			select @Null_Columns=  '순서,구분,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]','');
		-- 동적 SQL 생성
		SET @SQL = '
		SELECT 
		    '+ @Null_Columns +'
		FROM
		   (select 1 순서,''제)임원급여'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-임원'' group by 구분 ,model union all
			select 2,''	 제)급여-임원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-임원'' group by 구분 ,model union all
			select 3,''제)직원급여'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-직원'' group by 구분 ,model union all
			select 4,''	 제)급여-직원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-직원'' group by 구분 ,model union all
			select 5,''제)상여금구분'' 구분,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)상여금-직원'' group by 구분 ,model union all
			select 6,''	 제)상여금-직원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)상여금-직원'' group by 구분 ,model union all
			select 7,''제)제수당'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name in(''제)제수당-연차'',''제)제수당-일반'') group by 구분 ,model union all
			select 8,''	 제)제수당-연차'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)제수당-연차'' group by 구분 ,model union all
			select 9,''	 제)제수당-일반'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)제수당-일반'' group by 구분 ,model union all
			select 10,''제)퇴직급여'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name in(''제)급여-임원'',''제)퇴직급여-직원'') group by 구분 ,model union all
			select 11,''	 제)퇴직급여-임원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-임원'' group by 구분 ,model union all
			select 12,''	 제)퇴직급여-직원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)퇴직급여-직원'' group by 구분 ,model union all
			select 13,''제)주식보상비용'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)주식보상비용'' group by 구분 ,model union all
			select 14,''	 제)주식보상비용'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)주식보상비용'' group by 구분 ,model
		) AS SourceTable
		PIVOT 
		(
		    SUM(AMT)
		    FOR MODEL IN (' + @Columns + ')
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

