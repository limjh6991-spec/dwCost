/*
 * VN_WipCostLedger_Subul
 *   제조원가(재공)_VN (C0009007 TAB090017) 데이터 소스.
 *   재공품 공정 수불(생산실적 TAB090015) 구조 + 항목별 수량/금액, 도우코드 그레인.
 *   기초/BOH·재고/EOH 는 항목별 PFL전50%/PFL후90% × 수량/금액.
 *
 *   ⚠️ 현재는 "구조 스텁": 도우코드 그레인 행집합(도우코드/모델/구분)만 DOI_COST에서 산출하고,
 *      모든 수량/금액 측정값은 0으로 반환. (재공 공정수불 세부 산식/소스 매핑 미정)
 *      → 화면 레이아웃/그레인 검증용. 산식 확정 후 각 컬럼을 채운다.
 *   SEL_CODE 는 VN 표준인 'ACTUAL' 고정.
 */
CREATE OR ALTER PROCEDURE VN_WipCostLedger_Subul
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
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_WIP_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_WIP_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_WIP_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_WIP_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_FGS_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_FGS_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_FGS_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_LINE_FGS_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_A_SUB_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_A_SUB_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_A_SUB_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_A_SUB_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_WIP_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_WIP_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_WIP_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_WIP_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_FGS_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_FGS_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_FGS_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_FGS_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_SUB_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_SUB_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_SUB_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS BOH_B_SUB_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS T_BOH_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS T_BOH_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS T_BOH_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS T_BOH_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_WIP_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_WIP_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_WIP_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_WIP_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_FGS_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_FGS_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_FGS_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_LINE_FGS_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_WIP_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_WIP_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_WIP_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_WIP_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_FGS_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_FGS_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_FGS_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_B_FGS_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_WIP_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_WIP_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_WIP_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_WIP_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_FGS_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_FGS_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_FGS_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS EOH_T_FGS_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS TOTAL_EOH_B_QTY
            , CAST(0 AS DECIMAL(18,2)) AS TOTAL_EOH_B_AMT
            , CAST(0 AS DECIMAL(18,2)) AS TOTAL_EOH_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS TOTAL_EOH_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS USC_INPUT_QTY
            , CAST(0 AS DECIMAL(18,2)) AS USC_INPUT_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IN_CODE_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IN_CODE_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IN_RESORT_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IN_RESORT_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IN_REWORK_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IN_REWORK_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IN_SEMI_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IN_SEMI_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IN_ETC_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IN_ETC_AMT
            , CAST(0 AS DECIMAL(18,2)) AS IN_TOTAL_QTY
            , CAST(0 AS DECIMAL(18,2)) AS IN_TOTAL_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OUTPUT_A_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OUTPUT_A_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OUT_CODE_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OUT_CODE_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OUT_SEMI_PAID_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OUT_SEMI_PAID_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OUT_SEMI_FREE_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OUT_SEMI_FREE_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OUT_ETC_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OUT_ETC_AMT
            , CAST(0 AS DECIMAL(18,2)) AS OUT_TOTAL_QTY
            , CAST(0 AS DECIMAL(18,2)) AS OUT_TOTAL_AMT
            , CAST(0 AS DECIMAL(18,2)) AS LOSS_QTY
            , CAST(0 AS DECIMAL(18,2)) AS LOSS_AMT
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
