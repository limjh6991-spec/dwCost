CREATE PROCEDURE DOI_WipProcessSubulReport
(
    @YYYYMM VARCHAR(6),
    @SITE VARCHAR(4)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
              MODEL               AS model
            , PROCESS             AS process
            , ISNULL(BOH_QTY, 0)  AS boh
            , ISNULL(IN_QTY, 0)   AS inQty
            , ISNULL(OUT_QTY, 0)  AS outQty
            , ISNULL(LOSS_QTY, 0) AS lossQty
            , ISNULL(ETC_IN_CODE, 0)    AS etcInCode
            , ISNULL(ETC_IN_RESORT, 0)  AS etcInResort
            , ISNULL(ETC_IN_REWORK, 0)  AS etcInRework
            , ISNULL(ETC_IN_SEMI, 0)    AS etcInSemi
            , ISNULL(ETC_IN_ETC, 0)     AS etcInEtc
            , ISNULL(OTHER_IN_TOT, 0)   AS otherAccInTotal
            , ISNULL(ETC_OUT_CODE, 0)      AS etcOutCode
            , ISNULL(ETC_OUT_SEMI_PAID, 0) AS etcOutSemiPaid
            , ISNULL(ETC_OUT_SEMI_FREE, 0) AS etcOutSemiFree
            , ISNULL(ETC_OUT_ETC, 0)       AS etcOutEtc
            , ISNULL(OTHER_OUT_TOT, 0)     AS otherAccOutTotal
            , ISNULL(EOH_QTY, 0)  AS eoh
            , ISNULL(WIP_VAL_RATE, 0.5) AS wipValRate
        FROM DOI_WIP_PROCESS_SUBUL WITH (NOLOCK)
        WHERE YYYYMM = @YYYYMM
          AND SITE   = @SITE
        ORDER BY MODEL, PROCESS_SEQ;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
