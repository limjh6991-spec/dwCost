/*
 * VN_StockLedger_Detail  (제품 수불부 VN / C0009002 VN 탭)
 *   원천 DOI_VN_STOCK_RESC (도우코드 그레인, 완제품창고 WH0006 수불 수량 단일값).
 *   표시=모델(=도우코드)/구분(division). 컬럼 별칭은 프론트 CamelMap(fgLastMonth 등)과 매칭.
 *   OUTPUT SHIP(A급)은 PAID(유상)=OUT_SHIP_A, FREE(무상)=0(원천 미분리).
 */
CREATE OR ALTER PROCEDURE VN_StockLedger_Detail
(
    @YYYYMM   varchar(10),
    @SITE     varchar(4),
    @SEL_CODE varchar(10) = 'ACTUAL'
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
              도우코드 AS MODEL
            , division AS DIVISION
            , BOH AS BOH
            -- INPUT > NORMAL FG INPUT
            , IN_NORMAL_LAST AS FG_LAST_MONTH
            , IN_NORMAL_THIS AS FG_THIS_MONTH
            -- INPUT > RW FROM LINE → FG-WAREHOUSE
            , IN_RW_BACKSHIP_SORT AS BACK_SHIP_SORTING
            , IN_RW_BACKSHIP_PFRW AS BACK_SHIP_PF_RW
            , IN_RW_BACKSHIP_PLRW AS BACK_SHIP_PL_RW
            , IN_RW_WHRET_SORT    AS WH_RETURN_SORTING
            , IN_RW_WHRET_PFRW    AS WH_RETURN_PF_RW
            , IN_RW_WHRET_PLRW    AS WH_RETURN_PL_RW
            , T_INPUT AS T_INPUT
            -- 기타입고
            , ETCIN_RMA       AS IE_RMA
            , ETCIN_SEMI_PAID AS IE_RETURN_PAID
            , ETCIN_SEMI_FREE AS IE_RETURN_FREE
            , ETCIN_ETC       AS IE_OTHER
            , ETCIN_TOTAL     AS IE_TOTAL
            -- OUTPUT (SHIP A급: PAID(유상)/FREE(무상))
            , OUT_SHIP_A AS SHIP_A_PAID
            , CAST(0 AS decimal(18,2)) AS SHIP_A_FREE
            , OUT_SHIP_B AS SHIP_B_PAID
            , T_OUTPUT AS T_OUTPUT
            -- 기타출고
            , ETCOUT_RESORT   AS OE_RESORTING
            , ETCOUT_REWORK   AS OE_REWORK
            , ETCOUT_FREESALE AS OE_FREE_SALE
            , ETCOUT_ETC      AS OE_OTHER
            , ETCOUT_TOTAL    AS OE_TOTAL
            , LOSS AS LOSS
            , EOH_WH0006 AS EOH
        FROM DOI_VN_STOCK_RESC WITH (NOLOCK)
        WHERE SEL_CODE = @SEL_CODE AND YYYYMM = @YYYYMM
          AND 도우코드 IS NOT NULL AND LTRIM(RTRIM(도우코드)) <> '' AND 도우코드 <> N'TOTAL'
        ORDER BY division, 도우코드;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
