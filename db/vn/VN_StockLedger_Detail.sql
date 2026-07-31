CREATE OR ALTER PROCEDURE VN_StockLedger_Detail
(
    @YYYYMM  varchar(10),
    @SITE    varchar(4),
    @SEL_CODE varchar(10)
)
AS
BEGIN
    SET NOCOUNT ON;
    /* ------------------------------------------------------------------
       제품 수불부 (VN) - 완제품창고(WH0006) 재고수불 상세 [스캐폴딩]
       원천: DOI_STOCK, STOCK = 'WH0006-출하창고' (EOH WH0006).
             MODEL = MODEL_TYPE(품번, 예: 7075P).
       현재: 합계 컬럼(BOH / T_INPUT / T_OUTPUT / LOSS / EOH)만 DOI_STOCK에서 채움.
             WH0006 세부 분해 컬럼(NORMAL FG / BACK-SHIP / WH RETURN / 기타입고 /
             SHIP(A·B) / 기타출고)은 0.
       TODO: 세부 컬럼 산식(DOI_STOCK 원천 → 리포트 매핑)은 확정 후 반영.
       컬럼명은 언더스코어 구분 → 프론트 CamelMap(fgLastMonth 등)과 매칭.
    ------------------------------------------------------------------ */
    SELECT
          MODEL_TYPE                       AS MODEL
        , SUM(ISNULL(BOH,0))               AS BOH
        -- INPUT > NORMAL FG INPUT
        , CAST(0 AS decimal(18,2))         AS FG_LAST_MONTH
        , CAST(0 AS decimal(18,2))         AS FG_THIS_MONTH
        -- INPUT > RW FROM LINE → FG-WAREHOUSE
        , CAST(0 AS decimal(18,2))         AS BACK_SHIP_SORTING
        , CAST(0 AS decimal(18,2))         AS BACK_SHIP_PF_RW
        , CAST(0 AS decimal(18,2))         AS BACK_SHIP_PL_RW
        , CAST(0 AS decimal(18,2))         AS WH_RETURN_SORTING
        , CAST(0 AS decimal(18,2))         AS WH_RETURN_PF_RW
        , CAST(0 AS decimal(18,2))         AS WH_RETURN_PL_RW
        , SUM(ISNULL(INPUT,0))             AS T_INPUT
        -- 기타입고
        , CAST(0 AS decimal(18,2))         AS IE_RMA
        , CAST(0 AS decimal(18,2))         AS IE_RETURN_PAID
        , CAST(0 AS decimal(18,2))         AS IE_RETURN_FREE
        , CAST(0 AS decimal(18,2))         AS IE_OTHER
        , CAST(0 AS decimal(18,2))         AS IE_TOTAL
        -- OUTPUT
        , CAST(0 AS decimal(18,2))         AS SHIP_A_PAID
        , CAST(0 AS decimal(18,2))         AS SHIP_B_PAID
        , SUM(ISNULL(OUT,0))               AS T_OUTPUT
        -- 기타출고
        , CAST(0 AS decimal(18,2))         AS OE_RESORTING
        , CAST(0 AS decimal(18,2))         AS OE_REWORK
        , CAST(0 AS decimal(18,2))         AS OE_RMA
        , CAST(0 AS decimal(18,2))         AS OE_FREE_SALE
        , CAST(0 AS decimal(18,2))         AS OE_OTHER
        , CAST(0 AS decimal(18,2))         AS OE_TOTAL
        , SUM(ISNULL(폐기,0))              AS LOSS
        , SUM(ISNULL(EOH,0))               AS EOH
    FROM DOI_STOCK WITH(NOLOCK)
    WHERE YYYYMM   = @YYYYMM
      AND SITE     = @SITE
      AND SEL_CODE = @SEL_CODE
      AND STOCK LIKE N'WH0006%'
    GROUP BY MODEL_TYPE
    ORDER BY MODEL_TYPE;
END;
