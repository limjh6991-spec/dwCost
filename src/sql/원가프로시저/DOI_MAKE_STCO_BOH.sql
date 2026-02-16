CREATE               Procedure DOI_MAKE_STCO_BOH
(
    @YYYYMM varchar(6),
    @SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
	
	DELETE FROM doi_stco_boh WHERE YYYYMM=@YYYYMM AND SITE=@SITE;
	
	INSERT INTO doi_stco_boh
	select @YYYYMM YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel, expen_sel명, ACCT_NAME, EOH BOH_QTY,  EOH_AMT BOH_AMT
	from doi_stco
	where YYYYMM=FORMAT(DATEADD(MONTH, -1, CONVERT(date, @YYYYMM + '01')), 'yyyyMM') and SITE=@SITE;
	
	SELECT * FROM doi_stco_boh WHERE YYYYMM=@YYYYMM AND SITE=@SITE
    ORDER BY 1,2,3,4,5,6,7,8;
	
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	   SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
