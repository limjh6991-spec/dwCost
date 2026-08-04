/*
 * VN_WipCostLedger_Subul  (제조원가(재공)_VN / C0009007 TAB090017)
 *   원천 doi_vn_cost (도우코드 × 계정 그레인). 표시=모델(=도우코드)/구분(division: MP/R&D), 도우코드 그레인.
 *   집계 규칙: 수량(QTY)은 도우코드별 동일값 반복 → MAX, 금액(AMT)은 계정별 분해 → SUM.
 *   PFL 전=B(50%)/후=A(90%). 소계는 계산: A_SUB=LINE_WIP+LINE_FGS, B_SUB=B_WIP+B_FGS, T_BOH=A_SUB+B_SUB,
 *     inTotal=CODE+RESORT+REWORK+SEMI+ETC, outTotal=CODE+SEMI_PAID+SEMI_FREE+ETC,
 *     T_WIP=LINE_WIP+B_WIP, T_FGS=LINE_FGS+B_FGS, TOTAL_EOH=T_WIP+T_FGS.
 *   컬럼 별칭은 CamelMap(전→B/후→A) 규칙: 예 BOH_LINE_WIP_B_QTY→bohLineWipBQty.
 */
CREATE OR ALTER PROCEDURE VN_WipCostLedger_Subul
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
        ;WITH a AS (
            SELECT 도우코드,
                MAX(division) AS division,
                -- 기초 BOH (전=B / 후=A)
                MAX(ISNULL(BOH_LINE_WIP_전_QTY,0)) blwBQ, SUM(ISNULL(BOH_LINE_WIP_전_AMT,0)) blwBA, MAX(ISNULL(BOH_LINE_WIP_후_QTY,0)) blwAQ, SUM(ISNULL(BOH_LINE_WIP_후_AMT,0)) blwAA,
                MAX(ISNULL(BOH_LINE_FGS_전_QTY,0)) blfBQ, SUM(ISNULL(BOH_LINE_FGS_전_AMT,0)) blfBA, MAX(ISNULL(BOH_LINE_FGS_후_QTY,0)) blfAQ, SUM(ISNULL(BOH_LINE_FGS_후_AMT,0)) blfAA,
                MAX(ISNULL(BOH_B_WIP_전_QTY,0))    bbwBQ, SUM(ISNULL(BOH_B_WIP_전_AMT,0))    bbwBA, MAX(ISNULL(BOH_B_WIP_후_QTY,0))    bbwAQ, SUM(ISNULL(BOH_B_WIP_후_AMT,0))    bbwAA,
                MAX(ISNULL(BOH_B_FGS_전_QTY,0))    bbfBQ, SUM(ISNULL(BOH_B_FGS_전_AMT,0))    bbfBA, MAX(ISNULL(BOH_B_FGS_후_QTY,0))    bbfAQ, SUM(ISNULL(BOH_B_FGS_후_AMT,0))    bbfAA,
                -- 입고
                MAX(ISNULL(USC_INPUT_QTY,0)) uiQ, SUM(ISNULL(USC_INPUT_AMT,0)) uiA,
                -- 기타입고
                MAX(ISNULL(ETCIN_CODE_QTY,0))   icQ,  SUM(ISNULL(ETCIN_CODE_AMT,0))   icA,
                MAX(ISNULL(ETCIN_RESORT_QTY,0)) irsQ, SUM(ISNULL(ETCIN_RESORT_AMT,0)) irsA,
                MAX(ISNULL(ETCIN_REWORK_QTY,0)) irwQ, SUM(ISNULL(ETCIN_REWORK_AMT,0)) irwA,
                MAX(ISNULL(ETCIN_SEMI_QTY,0))   ismQ, SUM(ISNULL(ETCIN_SEMI_AMT,0))   ismA,
                MAX(ISNULL(ETCIN_ETC_QTY,0))    ieQ,  SUM(ISNULL(ETCIN_ETC_AMT,0))    ieA,
                -- 출고
                MAX(ISNULL(OUTPUT_A_QTY,0)) oaQ, SUM(ISNULL(OUTPUT_A_AMT,0)) oaA,
                -- 기타출고 (전=B / 후=A)
                MAX(ISNULL(ETCOUT_CODE_전_QTY,0))      ocBQ,  SUM(ISNULL(ETCOUT_CODE_전_AMT,0))      ocBA,  MAX(ISNULL(ETCOUT_CODE_후_QTY,0))      ocAQ,  SUM(ISNULL(ETCOUT_CODE_후_AMT,0))      ocAA,
                MAX(ISNULL(ETCOUT_SEMI_PAID_전_QTY,0)) ospBQ, SUM(ISNULL(ETCOUT_SEMI_PAID_전_AMT,0)) ospBA, MAX(ISNULL(ETCOUT_SEMI_PAID_후_QTY,0)) ospAQ, SUM(ISNULL(ETCOUT_SEMI_PAID_후_AMT,0)) ospAA,
                MAX(ISNULL(ETCOUT_SEMI_FREE_전_QTY,0)) osfBQ, SUM(ISNULL(ETCOUT_SEMI_FREE_전_AMT,0)) osfBA, MAX(ISNULL(ETCOUT_SEMI_FREE_후_QTY,0)) osfAQ, SUM(ISNULL(ETCOUT_SEMI_FREE_후_AMT,0)) osfAA,
                MAX(ISNULL(ETCOUT_ETC_전_QTY,0))       oeBQ,  SUM(ISNULL(ETCOUT_ETC_전_AMT,0))       oeBA,  MAX(ISNULL(ETCOUT_ETC_후_QTY,0))       oeAQ,  SUM(ISNULL(ETCOUT_ETC_후_AMT,0))       oeAA,
                -- LOSS (전=B / 후=A)
                MAX(ISNULL(LOSS_전_QTY,0)) lBQ, SUM(ISNULL(LOSS_전_AMT,0)) lBA, MAX(ISNULL(LOSS_후_QTY,0)) lAQ, SUM(ISNULL(LOSS_후_AMT,0)) lAA,
                -- 재고 EOH (전=B / 후=A)
                MAX(ISNULL(EOH_LINE_WIP_전_QTY,0)) elwBQ, SUM(ISNULL(EOH_LINE_WIP_전_AMT,0)) elwBA, MAX(ISNULL(EOH_LINE_WIP_후_QTY,0)) elwAQ, SUM(ISNULL(EOH_LINE_WIP_후_AMT,0)) elwAA,
                MAX(ISNULL(EOH_LINE_FGS_전_QTY,0)) elfBQ, SUM(ISNULL(EOH_LINE_FGS_전_AMT,0)) elfBA, MAX(ISNULL(EOH_LINE_FGS_후_QTY,0)) elfAQ, SUM(ISNULL(EOH_LINE_FGS_후_AMT,0)) elfAA,
                MAX(ISNULL(EOH_B_WIP_전_QTY,0))    ebwBQ, SUM(ISNULL(EOH_B_WIP_전_AMT,0))    ebwBA, MAX(ISNULL(EOH_B_WIP_후_QTY,0))    ebwAQ, SUM(ISNULL(EOH_B_WIP_후_AMT,0))    ebwAA,
                MAX(ISNULL(EOH_B_FGS_전_QTY,0))    ebfBQ, SUM(ISNULL(EOH_B_FGS_전_AMT,0))    ebfBA, MAX(ISNULL(EOH_B_FGS_후_QTY,0))    ebfAQ, SUM(ISNULL(EOH_B_FGS_후_AMT,0))    ebfAA
            FROM doi_vn_cost WITH (NOLOCK)
            WHERE SITE=@SITE AND SEL_CODE=@SEL_CODE
              AND ( (NULLIF(@YYYYMM,'') IS NOT NULL AND YYYYMM=@YYYYMM)
                 OR (NULLIF(@YYYYMM,'') IS NULL AND SUBSTRING(YYYYMM,1,4)=@YYYY) )
              AND 도우코드 IS NOT NULL AND LTRIM(RTRIM(도우코드))<>''
            GROUP BY 도우코드
        )
        SELECT
              도우코드 AS MODEL
            , division AS DIVISION
            -- 기초 BOH
            , blwBQ AS BOH_LINE_WIP_B_QTY, blwBA AS BOH_LINE_WIP_B_AMT, blwAQ AS BOH_LINE_WIP_A_QTY, blwAA AS BOH_LINE_WIP_A_AMT
            , blfBQ AS BOH_LINE_FGS_B_QTY, blfBA AS BOH_LINE_FGS_B_AMT, blfAQ AS BOH_LINE_FGS_A_QTY, blfAA AS BOH_LINE_FGS_A_AMT
            , (blwBQ+blfBQ) AS BOH_A_SUB_B_QTY, (blwBA+blfBA) AS BOH_A_SUB_B_AMT, (blwAQ+blfAQ) AS BOH_A_SUB_A_QTY, (blwAA+blfAA) AS BOH_A_SUB_A_AMT
            , bbwBQ AS BOH_B_WIP_B_QTY, bbwBA AS BOH_B_WIP_B_AMT, bbwAQ AS BOH_B_WIP_A_QTY, bbwAA AS BOH_B_WIP_A_AMT
            , bbfBQ AS BOH_B_FGS_B_QTY, bbfBA AS BOH_B_FGS_B_AMT, bbfAQ AS BOH_B_FGS_A_QTY, bbfAA AS BOH_B_FGS_A_AMT
            , (bbwBQ+bbfBQ) AS BOH_B_SUB_B_QTY, (bbwBA+bbfBA) AS BOH_B_SUB_B_AMT, (bbwAQ+bbfAQ) AS BOH_B_SUB_A_QTY, (bbwAA+bbfAA) AS BOH_B_SUB_A_AMT
            , (blwBQ+blfBQ+bbwBQ+bbfBQ) AS T_BOH_B_QTY, (blwBA+blfBA+bbwBA+bbfBA) AS T_BOH_B_AMT, (blwAQ+blfAQ+bbwAQ+bbfAQ) AS T_BOH_A_QTY, (blwAA+blfAA+bbwAA+bbfAA) AS T_BOH_A_AMT
            -- 입고
            , uiQ AS USC_INPUT_QTY, uiA AS USC_INPUT_AMT
            -- 기타입고
            , icQ  AS IN_CODE_QTY,   icA  AS IN_CODE_AMT
            , irsQ AS IN_RESORT_QTY, irsA AS IN_RESORT_AMT
            , irwQ AS IN_REWORK_QTY, irwA AS IN_REWORK_AMT
            , ismQ AS IN_SEMI_QTY,   ismA AS IN_SEMI_AMT
            , ieQ  AS IN_ETC_QTY,    ieA  AS IN_ETC_AMT
            , (icQ+irsQ+irwQ+ismQ+ieQ) AS IN_TOTAL_QTY, (icA+irsA+irwA+ismA+ieA) AS IN_TOTAL_AMT
            -- 출고
            , oaQ AS OUTPUT_A_QTY, oaA AS OUTPUT_A_AMT
            -- 기타출고 (B/A)
            , ocBQ  AS OUT_CODE_B_QTY,      ocBA  AS OUT_CODE_B_AMT,      ocAQ  AS OUT_CODE_A_QTY,      ocAA  AS OUT_CODE_A_AMT
            , ospBQ AS OUT_SEMI_PAID_B_QTY, ospBA AS OUT_SEMI_PAID_B_AMT, ospAQ AS OUT_SEMI_PAID_A_QTY, ospAA AS OUT_SEMI_PAID_A_AMT
            , osfBQ AS OUT_SEMI_FREE_B_QTY, osfBA AS OUT_SEMI_FREE_B_AMT, osfAQ AS OUT_SEMI_FREE_A_QTY, osfAA AS OUT_SEMI_FREE_A_AMT
            , oeBQ  AS OUT_ETC_B_QTY,       oeBA  AS OUT_ETC_B_AMT,       oeAQ  AS OUT_ETC_A_QTY,       oeAA  AS OUT_ETC_A_AMT
            , (ocBQ+ospBQ+osfBQ+oeBQ) AS OUT_TOTAL_B_QTY, (ocBA+ospBA+osfBA+oeBA) AS OUT_TOTAL_B_AMT, (ocAQ+ospAQ+osfAQ+oeAQ) AS OUT_TOTAL_A_QTY, (ocAA+ospAA+osfAA+oeAA) AS OUT_TOTAL_A_AMT
            -- LOSS (B/A)
            , lBQ AS LOSS_B_QTY, lBA AS LOSS_B_AMT, lAQ AS LOSS_A_QTY, lAA AS LOSS_A_AMT
            -- 재고 EOH
            , elwBQ AS EOH_LINE_WIP_B_QTY, elwBA AS EOH_LINE_WIP_B_AMT, elwAQ AS EOH_LINE_WIP_A_QTY, elwAA AS EOH_LINE_WIP_A_AMT
            , elfBQ AS EOH_LINE_FGS_B_QTY, elfBA AS EOH_LINE_FGS_B_AMT, elfAQ AS EOH_LINE_FGS_A_QTY, elfAA AS EOH_LINE_FGS_A_AMT
            , ebwBQ AS EOH_B_WIP_B_QTY, ebwBA AS EOH_B_WIP_B_AMT, ebwAQ AS EOH_B_WIP_A_QTY, ebwAA AS EOH_B_WIP_A_AMT
            , ebfBQ AS EOH_B_FGS_B_QTY, ebfBA AS EOH_B_FGS_B_AMT, ebfAQ AS EOH_B_FGS_A_QTY, ebfAA AS EOH_B_FGS_A_AMT
            , (elwBQ+ebwBQ) AS EOH_T_WIP_B_QTY, (elwBA+ebwBA) AS EOH_T_WIP_B_AMT, (elwAQ+ebwAQ) AS EOH_T_WIP_A_QTY, (elwAA+ebwAA) AS EOH_T_WIP_A_AMT
            , (elfBQ+ebfBQ) AS EOH_T_FGS_B_QTY, (elfBA+ebfBA) AS EOH_T_FGS_B_AMT, (elfAQ+ebfAQ) AS EOH_T_FGS_A_QTY, (elfAA+ebfAA) AS EOH_T_FGS_A_AMT
            , (elwBQ+ebwBQ+elfBQ+ebfBQ) AS TOTAL_EOH_B_QTY, (elwBA+ebwBA+elfBA+ebfBA) AS TOTAL_EOH_B_AMT, (elwAQ+ebwAQ+elfAQ+ebfAQ) AS TOTAL_EOH_A_QTY, (elwAA+ebwAA+elfAA+ebfAA) AS TOTAL_EOH_A_AMT
        FROM a
        ORDER BY division, 도우코드;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
