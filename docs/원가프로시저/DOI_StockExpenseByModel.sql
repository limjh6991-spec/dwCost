CREATE                   PROCEDURE DOI_StockExpenseByModel(
	@YYYYMM varchar(10),
 	@SITE varchar(4),
 	@SEL_CODE varchar(10)
 )
AS
BEGIN
    SET NOCOUNT ON;

   /* WITH MODEL_OUT단가 AS (
        SELECT
            a.YYYYMM,
            a.SITE,
            a.구분,
            a.model,a.expen_sel,a.acct_name,
            SUM(a.out_단가) AS out_단가,
            SUM(a.unit_cost) AS unit_cost
        FROM DOI_COST a 
        LEFT JOIN DOI_MODEL_MAST b 
            ON  a.model  = b.model
            AND a.yyyymm = b.yyyymm
            AND a.site   = b.site
        WHERE 1 = 1
          AND a.YYYYMM = @YYYYMM and expen_sel명!='재료비;'
          AND a.SITE   = @SITE 
          AND a.UnitCost_YN = 1
        GROUP BY
            a.YYYYMM,
            a.SITE,
            a.구분,
            a.model,a.expen_sel,a.acct_name
        HAVING SUM(a.out_단가) > 0
    ) */
    SELECT 
        1 AS 순서,
        구분,
        a.MODEL AS 코드,
      	coalesce(b.대각인치,cast(d.Inch as varchar)+'"') AS Inch,
        b.고객사   AS DW_SITE,
        SUM(COALESCE(a.BOH_AMT, 0)) AS BOH,
        SUM(COALESCE(a.IN_AMT, 0)) AS INPUT,
        SUM(COALESCE(a.INETC_AMT, 0)) AS IN_ETC,
        SUM(COALESCE(a.OUT_AMT, 0)) AS OUTPUT,
        SUM(COALESCE(a.OUTETC_AMT, 0)) AS OUT_ETC, 
        SUM(COALESCE(a.EOH_AMT, 0)) AS EOH
    FROM DOI_STCO a
    LEFT JOIN (select model,max(고객사) 고객사,max(대각인치) 대각인치 from dw_모델기본정보 group by model) b 
        ON 1=1 -- b.구분 = IIF(RIGHT(a.model, 1) = 'D', '개발', '양산')
        AND a.model = b.model
    /* LEFT JOIN MODEL_OUT단가 c 
        ON  c.구분 = IIF(RIGHT(a.model, 1) = 'D', '개발', '양산')
        AND a.model = c.model*/
    LEFT JOIN (select model,max(Inch) Inch from  dw_product_mast group by model) d on(a.model=d.model)
    WHERE a.YYYYMM   = @YYYYMM
      AND a.SITE     = @SITE
      AND a.SEL_CODE = @SEL_CODE
      AND a.ACCT_NAME != N'기타출고'
    GROUP BY 
        구분,
        a.MODEL,
        coalesce(b.대각인치,cast(d.Inch as varchar)+'"'),
        b.고객사 

    UNION ALL

    SELECT 
        2 AS 순서,
        구분,
        a.MODEL AS 코드,
      	coalesce(b.대각인치,cast(d.Inch as varchar)+'"') AS Inch,
      	b.고객사   AS DW_SITE,
        AVG(a.BOH),
        AVG(a.INPUT),
        AVG(a.INETC) AS IN_ETC,
        AVG(a.OUT) AS OUTPUT,
        AVG(a.OUTETC) AS OUT_ETC, 
        AVG(a.EOH)
    FROM DOI_STCO a
    LEFT JOIN (select model,max(고객사) 고객사,max(대각인치) 대각인치 from dw_모델기본정보 group by model) b  
        ON  1=1 --b.구분 = IIF(RIGHT(a.model, 1) = 'D', '개발', '양산')
        AND a.model = b.model
    /*LEFT JOIN MODEL_OUT단가 c 
        ON  c.구분 = IIF(RIGHT(a.model, 1) = 'D', '개발', '양산')
        AND a.model = c.model*/
    LEFT JOIN (select model,max(Inch) Inch from  dw_product_mast group by model) d on(a.model=d.model)
    WHERE a.YYYYMM   = @YYYYMM
      AND a.SITE     = @SITE
      AND a.SEL_CODE = @SEL_CODE
      AND a.ACCT_NAME != N'기타출고'      
    GROUP BY 
        구분,
        a.MODEL,
        coalesce(b.대각인치,cast(d.Inch as varchar)+'"'),
        b.고객사
    ORDER BY 구분 DESC, 코드, 순서;
END;

