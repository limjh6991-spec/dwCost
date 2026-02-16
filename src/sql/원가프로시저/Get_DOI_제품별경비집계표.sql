CREATE       Procedure Get_DOI_제품별경비집계표(
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
		FROM (SELECT DISTINCT TOP 500 model 
				FROM (
				SELECT DISTINCT 도우모델 as model from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE UNION ALL
				SELECT model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE
			  	)A
				ORDER BY 1 )AS 도우모델 ;
			select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
		FROM (SELECT DISTINCT TOP 500 model 
				FROM (
				SELECT DISTINCT 도우모델 as model from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE UNION ALL
				SELECT model from doi_expen_matl where yyyymm=@YYYYMM and site=@SITE
			  	)A
				ORDER BY 1 )AS 도우모델 ;
			select @Null_Columns=  '순서,구분,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns
		-- 동적 SQL 생성
		SET @SQL = '
		SELECT 
		    '+ @Null_Columns +'
		FROM
		   (select 1 순서,''원재료_원장'' 구분,도우모델 AS MODEL ,sum(배부금액) AMT from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''원자재''+''원자재'' group by 구분,도우모델 union all
			select 2,''원재료_카세트 부품'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''원자재''+''카세트'' group by 구분,도우모델 union all
			select 3,''부재료_필름'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''부자재''+''필름'' group by 구분,도우모델 union all
			select 4,''부재료_트레이'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+자재대분류 =''부자재''+''트레이'' group by 구분,도우모델 union all
			select 5,''부재료_약액'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+coalesce(자재대분류,''1'') =''약액''+''1'' group by 구분,도우모델 union all
			select 6,''부재료_기타'' 구분,도우모델,sum(배부금액) from doi_mat_cost where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and mat_class+coalesce(자재대분류,''1'') in (''부자재''+''1'',''부자재''+''부자재'',''부자재''+''카세트'') group by 구분,도우모델 UNION ALL
			select 7 순서,''제)임원급여'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-임원'' group by 구분 ,model union all
			select 8,''	 제)급여-임원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-임원'' group by 구분 ,model union all
			select 9,''제)직원급여'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-직원'' group by 구분 ,model union all
			select 10,''	 제)급여-직원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-직원'' group by 구분 ,model union all
			select 11,''제)상여금구분'' 구분,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)상여금-직원'' group by 구분 ,model union all
			select 12,''	 제)상여금-직원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)상여금-직원'' group by 구분 ,model union all
			select 13,''제)제수당'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name in(''제)제수당-연차'',''제)제수당-일반'') group by 구분 ,model union all
			select 14,''	 제)제수당-연차'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)제수당-연차'' group by 구분 ,model union all
			select 15,''	 제)제수당-일반'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)제수당-일반'' group by 구분 ,model union all
			select 16,''제)퇴직급여'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name in(''제)급여-임원'',''제)퇴직급여-직원'') group by 구분 ,model union all
			select 17,''	 제)퇴직급여-임원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)급여-임원'' group by 구분 ,model union all
			select 18,''	 제)퇴직급여-직원'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)퇴직급여-직원'' group by 구분 ,model union all
			select 19,''제)주식보상비용'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)주식보상비용'' group by 구분 ,model union all
			select 20,''	 제)주식보상비용'' 구분 ,model,sum([in]) as amt from doi_expen_matl where yyyymm='''+@YYYYMM + ''' and site='''+@SITE + ''' and acct_name=''제)주식보상비용'' group by 구분 ,model 
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
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
