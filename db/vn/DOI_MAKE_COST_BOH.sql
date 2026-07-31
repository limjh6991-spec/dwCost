CREATE OR ALTER Procedure dbo.DOI_MAKE_COST_BOH
(
    @YYYYMM varchar(6),
    @SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
		DELETE FROM doi_cost_boh WHERE YYYYMM=@YYYYMM AND SITE=@SITE;

		-- [260731] 컬럼 명시 (도우코드/공정 추가로 컬럼수 불일치 방지) + 도우코드 이월, 공정='*'
		INSERT INTO doi_cost_boh
		  (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
		select @YYYYMM, SEL_CODE, SITE, 구분, MODEL, ISNULL(도우코드,''), N'*',
		       expen_sel명, ACCT_NAME, ITEM_NAME, EXPEN_SEL, ADJ_YN, EOH_QTY, EOH
		from doi_cost
		where YYYYMM=FORMAT(DATEADD(MONTH, -1, CONVERT(date, @YYYYMM + '01')), 'yyyyMM') and SITE=@SITE;

		SELECT * FROM doi_cost_boh WHERE YYYYMM=@YYYYMM AND SITE=@SITE
		ORDER BY 1,2,3,4,5,6,7,8,9,10;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
