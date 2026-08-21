
CREATE PROCEDURE UP_VN_SALE_COST_NEW
    @YYYYMM varchar(6), @SITE varchar(4)='VN', @SEL_CODE varchar(6)='ACTUAL'
AS
BEGIN
    SET NOCOUNT ON;
    -- [VN 260821] VN 매출원가: 매출원가 = T_OUTPUT_QTY × UNIT_COST (=T_OUTPUT_AMT). 원천 doi_vn_stco.
    -- PK(구분,MODEL,EXPEN_SEL,거래처,Local구분) 기준 집계. 거래처='*'/Local구분='일반수출' 상수.
    DELETE FROM doi_slco WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE;
    INSERT INTO doi_slco
        (YYYYMM, SITE, SEL_CODE, 구분, MODEL, Local구분, 판매단위, 거래처, EXPEN_SEL, EXPEN_SEL명, OUT_qty, OUT_AMT, 도우코드)
    SELECT @YYYYMM, @SITE, @SEL_CODE, 구분, MODEL, N'일반수출', N'CELL', N'*', EXPEN_SEL, MAX(expen_sel명),
        CAST(SUM(CAST(T_OUTPUT_QTY AS float)) AS numeric(18,2)),
        CAST(SUM(CAST(T_OUTPUT_AMT AS float)) AS numeric(18,2)),
        MAX(도우코드)
    FROM doi_vn_stco WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE
    GROUP BY 구분, MODEL, EXPEN_SEL;
    SELECT @@ROWCOUNT AS inserted;
END
