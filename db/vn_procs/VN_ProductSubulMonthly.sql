/*
 * VN_ProductSubulMonthly  (생산실적 > 월별 집계(수량_VN) / C0009001 TAB090015)
 *   원천 DOI_VN_PROD_RESC (도우코드 그레인, 수량 단일값). 표시=모델(=도우코드)/구분(division).
 *   전=B(PFL전 50%) / 후=A(PFL후 90%). BOH/EOH 소계·T_BOH·T_EOH·TOTAL_EOH·기타입출고 합계는
 *   원천에 pre-계산돼 있어 직접 매핑. 컬럼 별칭은 CamelMap 규칙(전→B/후→A).
 */
CREATE OR ALTER PROCEDURE VN_ProductSubulMonthly
(
    @YYYY     varchar(4)  = NULL,
    @YYYYMM   varchar(10) = NULL,
    @SITE     varchar(4)  = NULL,
    @SEL_CODE varchar(10) = 'ACTUAL'
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
              도우코드 AS MODEL
            , division AS DIVISION
            -- 기초 BOH (전=B / 후=A)
            , BOH_LINE_WIP_전 AS BOH_LINE_WIP_B, BOH_LINE_WIP_후 AS BOH_LINE_WIP_A
            , BOH_LINE_FGS_전 AS BOH_LINE_FGS_B, BOH_LINE_FGS_후 AS BOH_LINE_FGS_A
            , BOH_A_SUB_전    AS BOH_A_SUB_B,    BOH_A_SUB_후    AS BOH_A_SUB_A
            , BOH_B_WIP_전    AS BOH_B_WIP_B,    BOH_B_WIP_후    AS BOH_B_WIP_A
            , BOH_B_FGS_전    AS BOH_B_FGS_B,    BOH_B_FGS_후    AS BOH_B_FGS_A
            , BOH_B_SUB_전    AS BOH_B_SUB_B,    BOH_B_SUB_후    AS BOH_B_SUB_A
            , T_BOH_전        AS T_BOH_B,        T_BOH_후        AS T_BOH_A
            -- 입고
            , USC_INPUT AS USC_INPUT
            -- 기타입고
            , ETCIN_CODE AS IN_CODE, ETCIN_RESORT AS IN_RESORT, ETCIN_REWORK AS IN_REWORK
            , ETCIN_SEMI AS IN_SEMI, ETCIN_ETC AS IN_ETC, ETCIN_TOTAL AS IN_TOTAL
            -- 출고
            , OUTPUT_A AS OUTPUT_A
            -- 기타출고 (전=B / 후=A)
            , ETCOUT_CODE_전      AS OUT_CODE_B,      ETCOUT_CODE_후      AS OUT_CODE_A
            , ETCOUT_SEMI_PAID_전 AS OUT_SEMI_PAID_B, ETCOUT_SEMI_PAID_후 AS OUT_SEMI_PAID_A
            , ETCOUT_SEMI_FREE_전 AS OUT_SEMI_FREE_B, ETCOUT_SEMI_FREE_후 AS OUT_SEMI_FREE_A
            , ETCOUT_ETC_전       AS OUT_ETC_B,       ETCOUT_ETC_후       AS OUT_ETC_A
            , ETCOUT_TOTAL_전     AS OUT_TOTAL_B,     ETCOUT_TOTAL_후     AS OUT_TOTAL_A
            -- LOSS (전=B / 후=A)
            , LOSS_전 AS LOSS_B, LOSS_후 AS LOSS_A
            -- 재고 EOH (전=B / 후=A) — 그리드 필드: lineWip/lineFgs/bWip/bFgs/tEohWip/tEohFgs/totalEoh
            , EOH_LINE_WIP_전 AS LINE_WIP_B, EOH_LINE_WIP_후 AS LINE_WIP_A
            , EOH_LINE_FGS_전 AS LINE_FGS_B, EOH_LINE_FGS_후 AS LINE_FGS_A
            , EOH_B_WIP_전    AS B_WIP_B,    EOH_B_WIP_후    AS B_WIP_A
            , EOH_B_FGS_전    AS B_FGS_B,    EOH_B_FGS_후    AS B_FGS_A
            , T_EOH_WIP_전    AS T_EOH_WIP_B, T_EOH_WIP_후   AS T_EOH_WIP_A
            , T_EOH_FGS_전    AS T_EOH_FGS_B, T_EOH_FGS_후   AS T_EOH_FGS_A
            , TOTAL_EOH_전    AS TOTAL_EOH_B, TOTAL_EOH_후   AS TOTAL_EOH_A
        FROM DOI_VN_PROD_RESC WITH (NOLOCK)
        WHERE SEL_CODE = @SEL_CODE
          AND ( (NULLIF(@YYYYMM,'') IS NOT NULL AND YYYYMM = @YYYYMM)
             OR (NULLIF(@YYYYMM,'') IS NULL AND SUBSTRING(YYYYMM,1,4) = @YYYY) )
          AND 도우코드 IS NOT NULL AND LTRIM(RTRIM(도우코드)) <> ''
        ORDER BY division, 도우코드;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
