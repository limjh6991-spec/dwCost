CREATE    PROCEDURE DOI_Journal
(
    @YYYYMM VARCHAR(6),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON;
    SET LOCK_TIMEOUT 5000; -- 10초로 증가
	
	WITH MAT_RAW_IN AS (
		SELECT	SUM(IN_AMT) mat_raw_amt
		FROM	DOI_MAT_AMT
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
		  AND cost_gubun='원재료'
	),MAT_AUX_IN AS (
		SELECT	SUM(IN_AMT) mat_AUX_amt
		FROM	DOI_MAT_AMT
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
		  AND cost_gubun!='원재료'
	), COST_MAT_IN AS(
		SELECT SUM([IN]) as COST_MAT
		FROM DOI_COST 
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
		  AND EXPEN_SEL IN('MIAX','MDAX')
	), COST_LABOR AS(
		SELECT SUM([IN]) as LABOR_AMT
		FROM DOI_COST 
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
		  AND EXPEN_SEL IN('MHRB')
	), COST_EXPEN AS(
		SELECT SUM([IN]) as expn_AMT
		FROM DOI_COST 
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
		  AND EXPEN_SEL NOT IN('MHRB','MIAX','MDAX')
	), COST_OUT AS (
		SELECT SUM([OUT]+ADJ_BOH) COST_OUT_AMT  --select *
		FROM DOI_COST 
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
	), STCO_IN AS (
		SELECT SUM(IN_AMT) STCO_IN_AMT --select distinct expen_sel명
		FROM DOI_STCO 
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
		  AND ACCT_NAME != N'기타출고' 
	), STCO_OUT AS (
		SELECT SUM(OUT_AMT) STCO_OUT_AMT
		FROM DOI_STCO 
		WHERE 1=1 
		  AND YYYYMM = @YYYYMM
		  AND SEL_CODE = @SEL_CODE
		  AND SITE = @SITE
	)
	select @YYYYMM YYYYMM,'원재료비' as 차변명,mat_raw_amt as 차변금액,'원재료' as 대변명,mat_raw_amt as 대변금액 FROM MAT_RAW_IN
	UNION ALL
	select @YYYYMM YYYYMM,'부재료비' as 차변명,mat_aux_amt as 차변,'부재료' as 대변명,mat_aux_amt as 차변 FROM MAT_aux_IN
	UNION ALL
	select @YYYYMM YYYYMM,'재공품' as 차변명,COST_MAT as 차변,'재료비집합계정' as 대변명,COST_MAT as 차변 FROM COST_MAT_IN
	UNION ALL
	select @YYYYMM YYYYMM,'재공품' as 차변명,LABOR_AMT as 차변,'제)노무비집합계정' as 대변명,LABOR_AMT as 차변 FROM COST_LABOR
	UNION ALL
	select @YYYYMM YYYYMM,'재공품' as 차변명,expn_AMT as 차변,'제)경비집합계정' as 대변명,expn_AMT as 차변 FROM COST_EXPEN
	UNION ALL
	select @YYYYMM YYYYMM,'제품제조원가' as 차변명,COST_OUT_AMT as 차변,'재공품' as 대변명,COST_OUT_AMT as 차변 FROM COST_OUT
	UNION ALL
	select @YYYYMM YYYYMM,'제품' as 차변명,STCO_IN_AMT as 차변,'제품제조원가' as 대변명,STCO_IN_AMT as 차변 FROM STCO_IN
	UNION ALL
	select @YYYYMM YYYYMM,'제품매출원가' as 차변명,STCO_OUT_AMT as 차변,'제품판매(제품 OUT 금액)' as 대변명,STCO_OUT_AMT as 차변 FROM STCO_OUT
	;

    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;	
