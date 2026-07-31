/*
 * VN_ProductCostLedger_Subul
 *   매출원가(제품)_VN (C0009007 TAB090016) 데이터 소스.
 *   완제품창고(WH0006) 제품 수불 구조 + 항목별 수량/금액, 도우코드 그레인.
 *
 *   ⚠️ 현재는 "구조 스텁": 도우코드 그레인 행집합(도우코드/모델/구분)만 DOI_COST에서 산출하고,
 *      모든 수량/금액 측정값은 0으로 반환. (WH0006 수불 세부 산식/소스 매핑 미정)
 *      → 화면 레이아웃/그레인 검증용. 산식 확정 후 각 컬럼을 채운다.
 *   SEL_CODE 는 VN 표준인 'ACTUAL' 고정.
 */
CREATE OR ALTER PROCEDURE VN_ProductCostLedger_Subul
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4)
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
              도우코드 AS DOWOO_CODE
            , MODEL     AS MODEL
            , 구분      AS DIVISION
            , CAST(0 AS DECIMAL(18,2)) AS BOH_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_AMT
            , CAST(0 AS DECIMAL(18,2)) AS FG_LAST_MONTH_QTY
            , CAST(0 AS DECIMAL(18,2)) AS FG_LAST_MONTH_AMT
            , CAST(0 AS DECIMAL(18,2)) AS FG_THIS_MONTH_QTY
            , CAST(0 AS DECIMAL(18,2)) AS FG_THIS_MONTH_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BACK_SHIP_SORTING_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BACK_SHIP_SORTING_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BACK_SHIP_PF_RW_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BACK_SHIP_PF_RW_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BACK_SHIP_PL_RW_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BACK_SHIP_PL_RW_AMT
            , CAST(0 AS DECIMAL(18,2)) AS WH_RETURN_SORTING_QTY
            , CAST(0 AS DECIMAL(18,2)) AS WH_RETURN_SORTING_AMT
            , CAST(0 AS DECIMAL(18,2)) AS WH_RETURN_PF_RW_QTY
            , CAST(0 AS DECIMAL(18,2)) AS WH_RETURN_PF_RW_AMT
            , CAST(0 AS DECIMAL(18,2)) AS WH_RETURN_PL_RW_QTY
            , CAST(0 AS DECIMAL(18,2)) AS WH_RETURN_PL_RW_AMT
            , CAST(0 AS DECIMAL(18,2)) AS T_INPUT_QTY
            , CAST(0 AS DECIMAL(18,2)) AS T_INPUT_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IE_RMA_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IE_RMA_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IE_RETURN_PAID_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IE_RETURN_PAID_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IE_RETURN_FREE_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IE_RETURN_FREE_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IE_OTHER_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IE_OTHER_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IE_TOTAL_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IE_TOTAL_AMT
            , CAST(0 AS DECIMAL(18,2)) AS SHIP_A_PAID_QTY
            , CAST(0 AS DECIMAL(18,2)) AS SHIP_A_PAID_AMT
            , CAST(0 AS DECIMAL(18,2)) AS SHIP_B_PAID_QTY
            , CAST(0 AS DECIMAL(18,2)) AS SHIP_B_PAID_AMT
            , CAST(0 AS DECIMAL(18,2)) AS T_OUTPUT_QTY
            , CAST(0 AS DECIMAL(18,2)) AS T_OUTPUT_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OE_RESORTING_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OE_RESORTING_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OE_REWORK_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OE_REWORK_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OE_RMA_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OE_RMA_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OE_FREE_SALE_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OE_FREE_SALE_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OE_OTHER_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OE_OTHER_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OE_TOTAL_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OE_TOTAL_AMT
            , CAST(0 AS DECIMAL(18,2)) AS LOSS_QTY
            , CAST(0 AS DECIMAL(18,2)) AS LOSS_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_AMT
        FROM DOI_COST WITH (NOLOCK)
        WHERE YYYYMM = @YYYYMM
          AND SITE   = @SITE
          AND SEL_CODE = 'ACTUAL'
          AND 도우코드 IS NOT NULL
          AND LTRIM(RTRIM(도우코드)) <> ''
        GROUP BY 도우코드, MODEL, 구분
        ORDER BY 구분, MODEL, 도우코드;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
