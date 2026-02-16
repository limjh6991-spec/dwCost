CREATE   PROCEDURE DOI_변동비_ByModel
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
		  AND ACCT_CLASS = 'AA' AND 원가구분 = '변동비';

		SELECT acct_name
		INTO #ACCT_SGA
		FROM DOI_ACCT WITH(NOLOCK)
		WHERE yyyymm = @YYYYMM
		  AND ACCT_CLASS = 'CC' AND 원가구분 = '변동비';		 
       
        -- 변동비 합계 --INSERT INTO #FIX (rn, gubun, 구분, model, amt)
            SELECT rn, gubun, 구분, model, SUM(amt)  AS amt
            FROM (
                SELECT 1 rn, N'  제조변동비' gubun,구분, model, CAST(out_amt AS DECIMAL(18,2)) amt
                FROM doi_stco WITH(NOLOCK)
                WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code = @SELCODE
                  AND ( acct_name IN (SELECT acct_name FROM #ACCT_MFG) OR expen_sel in('MIAX','MDAX'))
                UNION ALL
                -- 판)운반비
                SELECT 2 rn, N'  판관변동비' gubun,구분, model, CAST(dist_amt AS DECIMAL(18,2)) amt
                FROM doi_smce_cost WITH(NOLOCK)
                WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code = @SELCODE
                  AND sub_name IN (SELECT acct_name FROM #ACCT_SGA)
            ) X
            GROUP BY rn, gubun,구분, model
 		
     	DROP TABLE #ACCT_MFG;
		DROP TABLE #ACCT_SGA;           
        COMMIT TRAN;
     	
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
