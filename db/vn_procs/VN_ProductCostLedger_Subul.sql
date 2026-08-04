/*
 * VN_ProductCostLedger_Subul  (매출원가(제품)_VN / C0009007 TAB090016)
 *   원천 DOI_VN_STCO (도우코드 × 계정 그레인). 도우코드로 집계: 수량=MAX(반복), 금액=SUM.
 *   표시=모델(=도우코드)/구분(division). 컬럼 별칭은 프론트 CamelMap(fgLastMonth 등)과 매칭.
 *   OUTPUT SHIP(A급)은 PAID(유상)=OUT_SHIP_A_PAID, FREE(무상)=OUT_SHIP_A_FREE. 기타출고 RMA 없음.
 *
 *   합계 행(맨 아래):
 *     · 월합계 : 특정 기준월(@YYYYMM) 선택 시, 해당월 전체 도우코드 합계 1행.
 *     · 총합계 : 1월(존재 최소월)~기준월(@LastMM) 누적. BOH=최초월, EOH=최종월, 나머지=구간 합.
 */
CREATE OR ALTER PROCEDURE VN_ProductCostLedger_Subul
( @YYYY VARCHAR(4)=NULL, @YYYYMM VARCHAR(6)=NULL, @SITE VARCHAR(4)=NULL, @SEL_CODE VARCHAR(10)='ACTUAL' )
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SC VARCHAR(10)=ISNULL(NULLIF(@SEL_CODE,''),'ACTUAL');
    BEGIN TRY
        DECLARE @DispMM VARCHAR(6) = NULLIF(@YYYYMM,'');   -- 월합계 대상(선택 기준월)
        DECLARE @LastMM VARCHAR(6);                        -- 누적 상한(최종 결산월)
        DECLARE @FirstMM VARCHAR(6);                       -- 누적 하한(1월/존재 최소월)

        IF @DispMM IS NOT NULL
            SET @LastMM = @DispMM;
        ELSE
            SELECT @LastMM = MAX(YYYYMM) FROM DOI_VN_STCO WITH(NOLOCK)
             WHERE SEL_CODE=@SC AND SUBSTRING(YYYYMM,1,4)=@YYYY;

        SELECT @FirstMM = MIN(YYYYMM) FROM DOI_VN_STCO WITH(NOLOCK)
         WHERE SEL_CODE=@SC AND YYYYMM BETWEEN @YYYY+'01' AND @LastMM;

        ;WITH a AS (   -- 표시 구간 도우코드 그레인
            SELECT 도우코드, MAX(division) division,
                MAX(ISNULL(BOH_QTY,0)) bohQ, SUM(ISNULL(BOH_AMT,0)) bohA,
                MAX(ISNULL(IN_NORMAL_LAST_QTY,0)) flQ, SUM(ISNULL(IN_NORMAL_LAST_AMT,0)) flA,
                MAX(ISNULL(IN_NORMAL_THIS_QTY,0)) ftQ, SUM(ISNULL(IN_NORMAL_THIS_AMT,0)) ftA,
                MAX(ISNULL(IN_RW_BACKSHIP_SORT_QTY,0)) bssQ, SUM(ISNULL(IN_RW_BACKSHIP_SORT_AMT,0)) bssA,
                MAX(ISNULL(IN_RW_BACKSHIP_PFRW_QTY,0)) bspQ, SUM(ISNULL(IN_RW_BACKSHIP_PFRW_AMT,0)) bspA,
                MAX(ISNULL(IN_RW_BACKSHIP_PLRW_QTY,0)) bslQ, SUM(ISNULL(IN_RW_BACKSHIP_PLRW_AMT,0)) bslA,
                MAX(ISNULL(IN_RW_WHRET_SORT_QTY,0)) wrsQ, SUM(ISNULL(IN_RW_WHRET_SORT_AMT,0)) wrsA,
                MAX(ISNULL(IN_RW_WHRET_PFRW_QTY,0)) wrpQ, SUM(ISNULL(IN_RW_WHRET_PFRW_AMT,0)) wrpA,
                MAX(ISNULL(IN_RW_WHRET_PLRW_QTY,0)) wrlQ, SUM(ISNULL(IN_RW_WHRET_PLRW_AMT,0)) wrlA,
                MAX(ISNULL(T_INPUT_QTY,0)) tiQ, SUM(ISNULL(T_INPUT_AMT,0)) tiA,
                MAX(ISNULL(ETCIN_RMA_QTY,0)) irmQ, SUM(ISNULL(ETCIN_RMA_AMT,0)) irmA,
                MAX(ISNULL(ETCIN_SEMI_PAID_QTY,0)) ispQ, SUM(ISNULL(ETCIN_SEMI_PAID_AMT,0)) ispA,
                MAX(ISNULL(ETCIN_SEMI_FREE_QTY,0)) isfQ, SUM(ISNULL(ETCIN_SEMI_FREE_AMT,0)) isfA,
                MAX(ISNULL(ETCIN_ETC_QTY,0)) ioQ, SUM(ISNULL(ETCIN_ETC_AMT,0)) ioA,
                MAX(ISNULL(ETCIN_TOTAL_QTY,0)) itQ, SUM(ISNULL(ETCIN_TOTAL_AMT,0)) itA,
                MAX(ISNULL(OUT_SHIP_A_PAID_QTY,0)) saQ, SUM(ISNULL(OUT_SHIP_A_PAID_AMT,0)) saA,
                MAX(ISNULL(OUT_SHIP_A_FREE_QTY,0)) safQ, SUM(ISNULL(OUT_SHIP_A_FREE_AMT,0)) safA,
                MAX(ISNULL(OUT_SHIP_B_QTY,0)) sbQ, SUM(ISNULL(OUT_SHIP_B_AMT,0)) sbA,
                MAX(ISNULL(T_OUTPUT_QTY,0)) toQ, SUM(ISNULL(T_OUTPUT_AMT,0)) toA,
                MAX(ISNULL(ETCOUT_RESORT_QTY,0)) orsQ, SUM(ISNULL(ETCOUT_RESORT_AMT,0)) orsA,
                MAX(ISNULL(ETCOUT_REWORK_QTY,0)) orwQ, SUM(ISNULL(ETCOUT_REWORK_AMT,0)) orwA,
                MAX(ISNULL(ETCOUT_FREESALE_QTY,0)) ofsQ, SUM(ISNULL(ETCOUT_FREESALE_AMT,0)) ofsA,
                MAX(ISNULL(ETCOUT_ETC_QTY,0)) ooQ, SUM(ISNULL(ETCOUT_ETC_AMT,0)) ooA,
                MAX(ISNULL(ETCOUT_TOTAL_QTY,0)) otQ, SUM(ISNULL(ETCOUT_TOTAL_AMT,0)) otA,
                MAX(ISNULL(LOSS_QTY,0)) lQ, SUM(ISNULL(LOSS_AMT,0)) lA,
                MAX(ISNULL(EOH_WH0006_QTY,0)) eQ, SUM(ISNULL(EOH_WH0006_AMT,0)) eA
            FROM DOI_VN_STCO WITH(NOLOCK)
            WHERE SEL_CODE=@SC
              AND ( (@DispMM IS NOT NULL AND YYYYMM=@DispMM)
                 OR (@DispMM IS NULL AND SUBSTRING(YYYYMM,1,4)=@YYYY) )
              AND 도우코드 IS NOT NULL AND LTRIM(RTRIM(도우코드))<>'' AND 도우코드 <> N'TOTAL'
            GROUP BY 도우코드
        ),
        pm AS (   -- 누적 구간 도우코드 × 월 그레인
            SELECT 도우코드, YYYYMM,
                MAX(ISNULL(BOH_QTY,0)) bohQ, SUM(ISNULL(BOH_AMT,0)) bohA,
                MAX(ISNULL(IN_NORMAL_LAST_QTY,0)) flQ, SUM(ISNULL(IN_NORMAL_LAST_AMT,0)) flA,
                MAX(ISNULL(IN_NORMAL_THIS_QTY,0)) ftQ, SUM(ISNULL(IN_NORMAL_THIS_AMT,0)) ftA,
                MAX(ISNULL(IN_RW_BACKSHIP_SORT_QTY,0)) bssQ, SUM(ISNULL(IN_RW_BACKSHIP_SORT_AMT,0)) bssA,
                MAX(ISNULL(IN_RW_BACKSHIP_PFRW_QTY,0)) bspQ, SUM(ISNULL(IN_RW_BACKSHIP_PFRW_AMT,0)) bspA,
                MAX(ISNULL(IN_RW_BACKSHIP_PLRW_QTY,0)) bslQ, SUM(ISNULL(IN_RW_BACKSHIP_PLRW_AMT,0)) bslA,
                MAX(ISNULL(IN_RW_WHRET_SORT_QTY,0)) wrsQ, SUM(ISNULL(IN_RW_WHRET_SORT_AMT,0)) wrsA,
                MAX(ISNULL(IN_RW_WHRET_PFRW_QTY,0)) wrpQ, SUM(ISNULL(IN_RW_WHRET_PFRW_AMT,0)) wrpA,
                MAX(ISNULL(IN_RW_WHRET_PLRW_QTY,0)) wrlQ, SUM(ISNULL(IN_RW_WHRET_PLRW_AMT,0)) wrlA,
                MAX(ISNULL(T_INPUT_QTY,0)) tiQ, SUM(ISNULL(T_INPUT_AMT,0)) tiA,
                MAX(ISNULL(ETCIN_RMA_QTY,0)) irmQ, SUM(ISNULL(ETCIN_RMA_AMT,0)) irmA,
                MAX(ISNULL(ETCIN_SEMI_PAID_QTY,0)) ispQ, SUM(ISNULL(ETCIN_SEMI_PAID_AMT,0)) ispA,
                MAX(ISNULL(ETCIN_SEMI_FREE_QTY,0)) isfQ, SUM(ISNULL(ETCIN_SEMI_FREE_AMT,0)) isfA,
                MAX(ISNULL(ETCIN_ETC_QTY,0)) ioQ, SUM(ISNULL(ETCIN_ETC_AMT,0)) ioA,
                MAX(ISNULL(ETCIN_TOTAL_QTY,0)) itQ, SUM(ISNULL(ETCIN_TOTAL_AMT,0)) itA,
                MAX(ISNULL(OUT_SHIP_A_PAID_QTY,0)) saQ, SUM(ISNULL(OUT_SHIP_A_PAID_AMT,0)) saA,
                MAX(ISNULL(OUT_SHIP_A_FREE_QTY,0)) safQ, SUM(ISNULL(OUT_SHIP_A_FREE_AMT,0)) safA,
                MAX(ISNULL(OUT_SHIP_B_QTY,0)) sbQ, SUM(ISNULL(OUT_SHIP_B_AMT,0)) sbA,
                MAX(ISNULL(T_OUTPUT_QTY,0)) toQ, SUM(ISNULL(T_OUTPUT_AMT,0)) toA,
                MAX(ISNULL(ETCOUT_RESORT_QTY,0)) orsQ, SUM(ISNULL(ETCOUT_RESORT_AMT,0)) orsA,
                MAX(ISNULL(ETCOUT_REWORK_QTY,0)) orwQ, SUM(ISNULL(ETCOUT_REWORK_AMT,0)) orwA,
                MAX(ISNULL(ETCOUT_FREESALE_QTY,0)) ofsQ, SUM(ISNULL(ETCOUT_FREESALE_AMT,0)) ofsA,
                MAX(ISNULL(ETCOUT_ETC_QTY,0)) ooQ, SUM(ISNULL(ETCOUT_ETC_AMT,0)) ooA,
                MAX(ISNULL(ETCOUT_TOTAL_QTY,0)) otQ, SUM(ISNULL(ETCOUT_TOTAL_AMT,0)) otA,
                MAX(ISNULL(LOSS_QTY,0)) lQ, SUM(ISNULL(LOSS_AMT,0)) lA,
                MAX(ISNULL(EOH_WH0006_QTY,0)) eQ, SUM(ISNULL(EOH_WH0006_AMT,0)) eA
            FROM DOI_VN_STCO WITH(NOLOCK)
            WHERE SEL_CODE=@SC
              AND @FirstMM IS NOT NULL AND YYYYMM BETWEEN @FirstMM AND @LastMM
              AND 도우코드 IS NOT NULL AND LTRIM(RTRIM(도우코드))<>'' AND 도우코드 <> N'TOTAL'
            GROUP BY 도우코드, YYYYMM
        ),
        base AS (
            SELECT 1 AS SORTK, 도우코드 AS MODEL, division AS DIVISION,
                bohQ,bohA, flQ,flA, ftQ,ftA, bssQ,bssA, bspQ,bspA, bslQ,bslA, wrsQ,wrsA, wrpQ,wrpA, wrlQ,wrlA, tiQ,tiA,
                irmQ,irmA, ispQ,ispA, isfQ,isfA, ioQ,ioA, itQ,itA,
                saQ,saA, safQ,safA, sbQ,sbA, toQ,toA,
                orsQ,orsA, orwQ,orwA, ofsQ,ofsA, ooQ,ooA, otQ,otA, lQ,lA, eQ,eA
            FROM a
            UNION ALL
            SELECT 2, N'월합계', N'',
                SUM(bohQ),SUM(bohA), SUM(flQ),SUM(flA), SUM(ftQ),SUM(ftA), SUM(bssQ),SUM(bssA), SUM(bspQ),SUM(bspA), SUM(bslQ),SUM(bslA), SUM(wrsQ),SUM(wrsA), SUM(wrpQ),SUM(wrpA), SUM(wrlQ),SUM(wrlA), SUM(tiQ),SUM(tiA),
                SUM(irmQ),SUM(irmA), SUM(ispQ),SUM(ispA), SUM(isfQ),SUM(isfA), SUM(ioQ),SUM(ioA), SUM(itQ),SUM(itA),
                SUM(saQ),SUM(saA), SUM(safQ),SUM(safA), SUM(sbQ),SUM(sbA), SUM(toQ),SUM(toA),
                SUM(orsQ),SUM(orsA), SUM(orwQ),SUM(orwA), SUM(ofsQ),SUM(ofsA), SUM(ooQ),SUM(ooA), SUM(otQ),SUM(otA), SUM(lQ),SUM(lA), SUM(eQ),SUM(eA)
            FROM a
            WHERE @DispMM IS NOT NULL
            HAVING COUNT(*) > 0
            UNION ALL
            SELECT 3, N'총합계', N'',
                SUM(CASE WHEN YYYYMM=@FirstMM THEN bohQ ELSE 0 END),SUM(CASE WHEN YYYYMM=@FirstMM THEN bohA ELSE 0 END),
                SUM(flQ),SUM(flA), SUM(ftQ),SUM(ftA), SUM(bssQ),SUM(bssA), SUM(bspQ),SUM(bspA), SUM(bslQ),SUM(bslA), SUM(wrsQ),SUM(wrsA), SUM(wrpQ),SUM(wrpA), SUM(wrlQ),SUM(wrlA), SUM(tiQ),SUM(tiA),
                SUM(irmQ),SUM(irmA), SUM(ispQ),SUM(ispA), SUM(isfQ),SUM(isfA), SUM(ioQ),SUM(ioA), SUM(itQ),SUM(itA),
                SUM(saQ),SUM(saA), SUM(safQ),SUM(safA), SUM(sbQ),SUM(sbA), SUM(toQ),SUM(toA),
                SUM(orsQ),SUM(orsA), SUM(orwQ),SUM(orwA), SUM(ofsQ),SUM(ofsA), SUM(ooQ),SUM(ooA), SUM(otQ),SUM(otA), SUM(lQ),SUM(lA),
                SUM(CASE WHEN YYYYMM=@LastMM THEN eQ ELSE 0 END),SUM(CASE WHEN YYYYMM=@LastMM THEN eA ELSE 0 END)
            FROM pm
            WHERE @DispMM IS NULL   -- 총합계는 기준월='전체' 조회 시에만
            HAVING COUNT(*) > 0
        )
        SELECT
              MODEL, DIVISION
            , bohQ AS BOH_QTY, bohA AS BOH_AMT
            , flQ AS FG_LAST_MONTH_QTY, flA AS FG_LAST_MONTH_AMT
            , ftQ AS FG_THIS_MONTH_QTY, ftA AS FG_THIS_MONTH_AMT
            , bssQ AS BACK_SHIP_SORTING_QTY, bssA AS BACK_SHIP_SORTING_AMT
            , bspQ AS BACK_SHIP_PF_RW_QTY,   bspA AS BACK_SHIP_PF_RW_AMT
            , bslQ AS BACK_SHIP_PL_RW_QTY,   bslA AS BACK_SHIP_PL_RW_AMT
            , wrsQ AS WH_RETURN_SORTING_QTY, wrsA AS WH_RETURN_SORTING_AMT
            , wrpQ AS WH_RETURN_PF_RW_QTY,   wrpA AS WH_RETURN_PF_RW_AMT
            , wrlQ AS WH_RETURN_PL_RW_QTY,   wrlA AS WH_RETURN_PL_RW_AMT
            , tiQ AS T_INPUT_QTY, tiA AS T_INPUT_AMT
            , irmQ AS IE_RMA_QTY, irmA AS IE_RMA_AMT
            , ispQ AS IE_RETURN_PAID_QTY, ispA AS IE_RETURN_PAID_AMT
            , isfQ AS IE_RETURN_FREE_QTY, isfA AS IE_RETURN_FREE_AMT
            , ioQ AS IE_OTHER_QTY, ioA AS IE_OTHER_AMT
            , itQ AS IE_TOTAL_QTY, itA AS IE_TOTAL_AMT
            , saQ AS SHIP_A_PAID_QTY, saA AS SHIP_A_PAID_AMT
            , safQ AS SHIP_A_FREE_QTY, safA AS SHIP_A_FREE_AMT
            , sbQ AS SHIP_B_PAID_QTY, sbA AS SHIP_B_PAID_AMT
            , toQ AS T_OUTPUT_QTY, toA AS T_OUTPUT_AMT
            , orsQ AS OE_RESORTING_QTY, orsA AS OE_RESORTING_AMT
            , orwQ AS OE_REWORK_QTY,    orwA AS OE_REWORK_AMT
            , ofsQ AS OE_FREE_SALE_QTY, ofsA AS OE_FREE_SALE_AMT
            , ooQ AS OE_OTHER_QTY, ooA AS OE_OTHER_AMT
            , otQ AS OE_TOTAL_QTY, otA AS OE_TOTAL_AMT
            , lQ AS LOSS_QTY, lA AS LOSS_AMT
            , eQ AS EOH_QTY, eA AS EOH_AMT
        FROM base
        ORDER BY SORTK, DIVISION, MODEL;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
