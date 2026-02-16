CREATE   PROCEDURE DOI_고정비_ByModel
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4),
    @SELCODE VARCHAR(10) 
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;
       	SELECT acct_name
		INTO #ACCT_MFG
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'AA' AND 원가구분 = '고정비';
		
		SELECT acct_name
		INTO #ACCT_SGA
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'CC' AND 원가구분 = '고정비';

        /*==============================================================
          2) FACT : (rn, gubun, 구분, model, amt)
        ==============================================================*/
		;WITH A0 AS (
		    SELECT 3 rn, N'  제조고정비' gubun,
		        A.구분,
		        A.model,
		        sum(A.out_amt) AS amt
		    FROM doi_stco A WITH(NOLOCK)
		    WHERE A.yyyymm=@YYYYMM AND A.site=@SITE AND A.sel_code=@SELCODE
		      AND A.acct_name IN (SELECT acct_name FROM #ACCT_MFG)
		    group by 구분,model
		),
		SGA_S0 AS (
		    SELECT 4 rn, N'  판관비(합계)' gubun,
		        S.구분,
		        S.model,
		        SUM(S.dist_amt) AS amt
		    FROM doi_smce_cost S WITH(NOLOCK)
		    WHERE S.yyyymm=@YYYYMM AND S.site=@SITE AND S.sel_code=@SELCODE
		      AND S.sub_name IN (SELECT acct_name FROM #ACCT_SGA)
		    group by 구분,model 
		)
		SELECT rn, gubun, 구분, model, amt FROM A0
   		UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA_S0;
   			
     	DROP TABLE #ACCT_MFG;
		DROP TABLE #ACCT_SGA;  
     	
        COMMIT TRAN;
     	
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;	
