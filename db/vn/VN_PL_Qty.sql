CREATE OR ALTER PROCEDURE VN_PL_Qty
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;
    -- 제품별 손익계산서 '매출수량' : PL 금액(VN_PL_ByModel)과 동일 모델키(도우코드=품번, LEN>1)로 산출
    ;WITH MERCH_ITEM AS (
        SELECT DISTINCT M.품번
        FROM DOI_MATL_RESC M WITH(NOLOCK)
        WHERE M.YYYYMM = @YYYYMM AND M.SITE = @SITE AND M.SEL_CODE = @SEL_CODE
          AND M.품목자산분류 = N'상품' AND M.품번 IS NOT NULL
    )
    SELECT 구분, LTRIM(RTRIM(model)) AS model, SUM(qty) AS qty
    FROM (
        -- 국내매출
        SELECT
            CASE
              WHEN A.품번 LIKE N'VN%' THEN N'카세트'
              WHEN MI.품번 IS NOT NULL THEN N'구매'
              WHEN RIGHT(LTRIM(RTRIM(A.품번)),1)='P' THEN N'양산'
              ELSE N'개발'
            END AS 구분,
            CASE WHEN LEN(A.품번) > 1 THEN LTRIM(RTRIM(A.품번)) ELSE LTRIM(RTRIM(A.품명)) END AS model,
            ISNULL(A.수량,0) AS qty
        FROM doi_sale_resc A WITH(NOLOCK)
        LEFT JOIN MERCH_ITEM MI ON MI.품번 = A.품번
        WHERE A.yyyymm = @YYYYMM AND A.site = @SITE

        UNION ALL

        -- 해외매출
        SELECT
            CASE
              WHEN B.품번 LIKE N'VN%' THEN N'카세트'
              WHEN MI.품번 IS NOT NULL THEN N'구매'
              WHEN RIGHT(LTRIM(RTRIM(B.품번)),1)='P' THEN N'양산'
              ELSE N'개발'
            END AS 구분,
            CASE WHEN LEN(B.품번) > 1 THEN LTRIM(RTRIM(B.품번)) ELSE LTRIM(RTRIM(B.품명)) END AS model,
            ISNULL(B.수량,0) AS qty
        FROM doi_invoice_resc B WITH(NOLOCK)
        LEFT JOIN MERCH_ITEM MI ON MI.품번 = B.품번
        WHERE B.yyyymm = @YYYYMM AND B.site = @SITE
    ) A
    GROUP BY 구분, LTRIM(RTRIM(model))
    ORDER BY 구분 DESC, model;
END
