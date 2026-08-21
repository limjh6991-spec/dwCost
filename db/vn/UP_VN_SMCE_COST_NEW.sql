
CREATE PROCEDURE UP_VN_SMCE_COST_NEW
    @YYYYMM varchar(6), @SITE varchar(4)='VN', @SEL_CODE varchar(6)='ACTUAL'
AS
BEGIN
    SET NOCOUNT ON;
    -- [VN 260821] 판관비: doi_acct_expen(acct_class='CC') 을 매출(doi_invoice_resc)비율 배부. 단수차 최대매출모델 보정.
    DELETE FROM DOI_SMCE_COST WHERE yyyymm=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE;
    WITH sale_data AS (
        SELECT 구분, model, Local구분, 판매단위, 거래처, SUM(SALE_AMT) SALE_AMT FROM (
            SELECT CASE WHEN RIGHT(품번,1)='D' THEN N'개발' ELSE N'양산' END 구분,
                   품명 model, N'일반수출' Local구분, N'CELL' 판매단위, N'*' 거래처,
                   CAST(원화판매금액 AS float) SALE_AMT
            FROM DOI_INVOICE_RESC WHERE yyyymm=@YYYYMM AND site=@SITE
        ) x GROUP BY 구분, model, Local구분, 판매단위, 거래처
    ),
    sale_total AS (SELECT SUM(SALE_AMT) TOT_SALE_AMT FROM sale_data),
    expen_data AS (
        SELECT YYYYMM, SITE, ACCT_NAME SUB_NAME, MAX(ITEM_NAME) ITEM_NAME, EXPEN_SEL, MIN(EXPEN_SEL명) EXPEN_SEL명,
               SUM(CAST(ACCT_AMT AS float)) TOT_ACCT, SUM(SUM(CAST(ACCT_AMT AS float))) OVER() TOT_SMCE
        FROM DOI_ACCT_EXPEN
        WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_class='CC' AND sel_code=@SEL_CODE
        GROUP BY YYYYMM, SITE, EXPEN_SEL, ACCT_NAME
    )
    INSERT INTO DOI_SMCE_COST (YYYYMM, sel_code, SITE, 구분, model, Local구분, 판매단위, 거래처, EXPEN_SEL명, SUB_NAME, ITEM_NAME, EXPEN_SEL, TOT_ACCT, SALE_AMT, TOT_AMT, TOT_SMCE, DIST_RATE, DIST_AMT, DIST_AMT_ORI)
    SELECT YYYYMM, @SEL_CODE, SITE, 구분, model, Local구분, 판매단위, 거래처, EXPEN_SEL명, SUB_NAME, ITEM_NAME, EXPEN_SEL,
        TOT_ACCT, SALE_AMT, TOT_AMT, TOT_SMCE, DIST_RATE,
        Base_Dist_Amt + CASE WHEN RN=1 THEN (TOT_ACCT - Grp_Sum_Amt) ELSE 0 END AS DIST_AMT,
        DIST_AMT_ORI
    FROM (
        SELECT A.*,
            SUM(Base_Dist_Amt) OVER (PARTITION BY EXPEN_SEL, SUB_NAME) AS Grp_Sum_Amt,
            ROW_NUMBER() OVER (PARTITION BY EXPEN_SEL, SUB_NAME ORDER BY SALE_AMT DESC) AS RN
        FROM (
            SELECT e.YYYYMM, e.SITE, s.구분, s.model, s.Local구분, s.판매단위, s.거래처,
                e.EXPEN_SEL명, e.SUB_NAME, e.ITEM_NAME, e.EXPEN_SEL, e.TOT_ACCT, e.TOT_SMCE,
                s.SALE_AMT, t.TOT_SALE_AMT TOT_AMT,
                CASE WHEN ISNULL(t.TOT_SALE_AMT,0)=0 THEN 0 ELSE CAST(s.SALE_AMT AS float)/t.TOT_SALE_AMT END DIST_RATE,
                CASE WHEN ISNULL(t.TOT_SALE_AMT,0)=0 THEN 0 ELSE ROUND(e.TOT_ACCT*(CAST(s.SALE_AMT AS float)/t.TOT_SALE_AMT),2) END Base_Dist_Amt,
                e.TOT_ACCT*(CAST(s.SALE_AMT AS float)/NULLIF(t.TOT_SALE_AMT,0)) DIST_AMT_ORI
            FROM expen_data e CROSS JOIN sale_data s CROSS JOIN sale_total t
        ) A
    ) Final;
    SELECT @@ROWCOUNT AS inserted;
END
