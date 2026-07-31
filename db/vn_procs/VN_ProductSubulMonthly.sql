/*
 * VN_ProductSubulMonthly  (생산실적 > 월별 집계(수량_VN) / C0009001 TAB090015)
 *   원천 DOI_PROD_SUBUL, 도우코드 그레인. 표시=모델(=도우코드)/구분(도우코드 끝자리 P->MP, 그 외 R&D).
 *   우선 DOI_PROD_SUBUL에서 매칭되는 월수량만 채움:
 *     T_BOH_B=BOH_MONTH, USC_INPUT=IN_MONTH, OUTPUT_A=OUT_MONTH, LOSS=LOSS_MONTH,
 *     TOTAL_EOH_B=PL전, TOTAL_EOH_A=PL후 (PL전/후는 콤마 텍스트 → TRY_CONVERT).
 *   재공 공정수불 세부 분해(IN_CODE/OUT_CODE/LINE_WIP/… B_LEVEL 등)는 0 (산식 추후 정의).
 */
CREATE OR ALTER PROCEDURE VN_ProductSubulMonthly
(
    @YYYYMM varchar(10),
    @SITE   varchar(4)
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
              도우코드 AS MODEL
            , CASE WHEN RIGHT(RTRIM(도우코드),1)=N'P' THEN N'MP' ELSE N'R&D' END AS DIVISION
            -- 기초 BOH (PFL전=BOH_MONTH, PFL후 스텁)
            , CAST(SUM(ISNULL(BOH_MONTH,0)) AS INT) AS T_BOH_B, CAST(0 AS INT) AS T_BOH_A
            -- 입고
            , CAST(SUM(ISNULL(IN_MONTH,0)) AS INT) AS USC_INPUT
            , CAST(0 AS INT) AS IN_CODE, CAST(0 AS INT) AS IN_RESORT, CAST(0 AS INT) AS IN_REWORK
            , CAST(0 AS INT) AS IN_SEMI, CAST(0 AS INT) AS IN_ETC, CAST(0 AS INT) AS IN_TOTAL
            -- 출고
            , CAST(SUM(ISNULL(OUT_MONTH,0)) AS INT) AS OUTPUT_A
            , CAST(0 AS INT) AS OUT_CODE, CAST(0 AS INT) AS OUT_SEMI_PAID, CAST(0 AS INT) AS OUT_SEMI_FREE
            , CAST(0 AS INT) AS OUT_ETC, CAST(0 AS INT) AS OUT_TOTAL
            -- LOSS
            , CAST(SUM(ISNULL(LOSS_MONTH,0)) AS INT) AS LOSS
            -- 재고 EOH 세부(스텁)
            , CAST(0 AS INT) AS LINE_WIP_B, CAST(0 AS INT) AS LINE_WIP_A
            , CAST(0 AS INT) AS LINE_FGS_B, CAST(0 AS INT) AS LINE_FGS_A
            , CAST(0 AS INT) AS B_WIP_B,    CAST(0 AS INT) AS B_WIP_A
            , CAST(0 AS INT) AS B_FGS_B,    CAST(0 AS INT) AS B_FGS_A
            , CAST(0 AS INT) AS T_EOH_WIP_B, CAST(0 AS INT) AS T_EOH_WIP_A
            , CAST(0 AS INT) AS T_EOH_FGS_B, CAST(0 AS INT) AS T_EOH_FGS_A
            -- TOTAL_EOH = PL전 / PL후 (완성환산 수량)
            , CAST(SUM(TRY_CONVERT(int, REPLACE(REPLACE(ISNULL(PL전, N'0'), N',', N''), N' ', N''))) AS INT) AS TOTAL_EOH_B
            , CAST(SUM(TRY_CONVERT(int, REPLACE(REPLACE(ISNULL(PL후, N'0'), N',', N''), N' ', N''))) AS INT) AS TOTAL_EOH_A
        FROM DOI_PROD_SUBUL WITH (NOLOCK)
        WHERE YYYYMM = @YYYYMM
          AND SITE   = @SITE
          AND 도우코드 IS NOT NULL AND LTRIM(RTRIM(도우코드)) <> ''
        GROUP BY 도우코드
        ORDER BY DIVISION, 도우코드;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
