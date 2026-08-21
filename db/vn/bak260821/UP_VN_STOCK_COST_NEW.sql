/* ============================================================
   [VN 260801 V11-3] 제품 매출원가 → doi_vn_stco (OUTPUT 3분할 + expen_sel)
   소스: doi_vn_stock_resc(수량) + DOI_STOCK_BOH(제품기초금액) + 재공 doi_vn_cost(입고=재공출고·반제품) + DOI_VN_RSRW(R/S·R/W)
   ★단가 수정: R/S·R/W가 빼간 (수량+금액)을 제외한 '나머지'로 uc 산정 → 수량0 라인 phantom 제거.
     uc = (투입금액 − R/S·R/W금액) / (투입수량 − R/S·R/W수량)      (RMA 제외)
   규칙: RMA무시 / 반제품=재공출고금액 / R/S·R/W=제품기초단가(DOI_VN_RSRW) / 무상매출·SHIP무상=uc×수량(매출원가만)
         EOH=uc×EOH수량(물리고정), OUTPUT(매출원가)=잔여.
   ============================================================ */
CREATE   PROCEDURE UP_VN_STOCK_COST_NEW @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM doi_vn_stco WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE;
  ;WITH
  sr AS (SELECT * FROM doi_vn_stock_resc WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE),
  srd AS (SELECT DISTINCT 도우코드, division FROM doi_vn_stock_resc WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE),  -- 제품수불 기준 division
  bh AS (SELECT srd.도우코드, srd.division, CASE WHEN srd.division='MP' THEN N'양산' ELSE N'개발' END 구분, sb.expen_sel EXPEN_SEL,
            MAX(sb.model) MODEL, MAX(sb.expen_sel명) es명, MAX(sb.acct_name) an, MAX(sb.item_name) it, SUM(CAST(sb.boh_amt AS float)) boh_amt
         FROM DOI_STOCK_BOH sb JOIN srd ON srd.도우코드=sb.model_type   -- 기초금액 division을 stock_resc 기준으로 정렬(815AP 등 오분류 보정)
         WHERE sb.yyyymm=@YYYYMM AND sb.site=@SITE GROUP BY srd.도우코드, srd.division, sb.expen_sel),
  wo AS (SELECT 도우코드, division, MAX(구분) 구분, EXPEN_SEL, MAX(MODEL) MODEL, MAX(expen_sel명) es명, MAX(ACCT_NAME) an, MAX(ITEM_NAME) it,
            SUM([OUTPUT_A_AMT]) input_amt, SUM([ETCOUT_SEMI_PAID_전_AMT]+[ETCOUT_SEMI_PAID_후_AMT]) sp_amt, SUM([ETCOUT_SEMI_FREE_전_AMT]+[ETCOUT_SEMI_FREE_후_AMT]) sf_amt
         FROM doi_vn_cost WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드, division, EXPEN_SEL),
  rw AS (SELECT 도우코드, 구분 division, EXPEN_SEL, SUM(CAST(rs_amt AS float)) rs_amt, SUM(CAST(rw_amt AS float)) rw_amt
         FROM DOI_VN_RSRW WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE GROUP BY 도우코드, 구분, EXPEN_SEL),
  esrc AS (SELECT DISTINCT 도우코드,division,EXPEN_SEL FROM bh UNION SELECT DISTINCT 도우코드,division,EXPEN_SEL FROM wo UNION SELECT DISTINCT 도우코드,division,EXPEN_SEL FROM rw),
  keys AS (SELECT s.도우코드, s.division, COALESCE(x.EXPEN_SEL,'*') EXPEN_SEL FROM sr s LEFT JOIN esrc x ON x.도우코드=s.도우코드 AND x.division=s.division),
  base AS (
    SELECT k.도우코드, k.division, k.EXPEN_SEL,
       COALESCE(b.구분,w.구분, CASE WHEN k.division='MP' THEN N'양산' ELSE N'개발' END) 구분,
       COALESCE(b.MODEL,w.MODEL,'') MODEL, COALESCE(b.es명,w.es명,'') es명,
       COALESCE(b.an,w.an, CASE WHEN LEFT(k.EXPEN_SEL,1)='M' THEN N'재료비' ELSE N'가공비' END) an, COALESCE(b.it,w.it,'') it,
       ISNULL(b.boh_amt,0) boh_amt, ISNULL(w.input_amt,0) input_amt, ISNULL(w.sp_amt,0) sp_amt, ISNULL(w.sf_amt,0) sf_amt, ISNULL(rr.rs_amt,0) rs_amt, ISNULL(rr.rw_amt,0) rw_amt,
       sr.BOH,sr.IN_NORMAL_LAST,sr.IN_NORMAL_THIS,sr.IN_RW_BACKSHIP_SORT,sr.IN_RW_BACKSHIP_PFRW,sr.IN_RW_BACKSHIP_PLRW,
       sr.IN_RW_WHRET_SORT,sr.IN_RW_WHRET_PFRW,sr.IN_RW_WHRET_PLRW,sr.T_INPUT,sr.ETCIN_RMA,sr.ETCIN_SEMI_PAID,sr.ETCIN_SEMI_FREE,sr.ETCIN_ETC,sr.ETCIN_TOTAL,
       sr.OUT_SHIP_A_PAID,sr.OUT_SHIP_A_FREE,sr.OUT_SHIP_B,sr.T_OUTPUT,sr.ETCOUT_RESORT,sr.ETCOUT_REWORK,sr.ETCOUT_FREESALE,sr.ETCOUT_ETC,sr.ETCOUT_TOTAL,sr.LOSS,sr.EOH_WH0006,
       (ISNULL(b.boh_amt,0)+ISNULL(w.input_amt,0)+ISNULL(w.sp_amt,0)+ISNULL(w.sf_amt,0)) inv_amt,
       (sr.BOH+sr.T_INPUT+sr.ETCIN_SEMI_PAID+sr.ETCIN_SEMI_FREE) inv_qty,
       (sr.ETCOUT_RESORT+sr.ETCOUT_REWORK) rsrw_qty
    FROM keys k
      LEFT JOIN bh b ON b.도우코드=k.도우코드 AND b.division=k.division AND b.EXPEN_SEL=k.EXPEN_SEL
      LEFT JOIN wo w ON w.도우코드=k.도우코드 AND w.division=k.division AND w.EXPEN_SEL=k.EXPEN_SEL
      LEFT JOIN rw rr ON rr.도우코드=k.도우코드 AND rr.division=k.division AND rr.EXPEN_SEL=k.EXPEN_SEL
      LEFT JOIN sr ON sr.도우코드=k.도우코드 AND sr.division=k.division),
  c AS (SELECT *,
         CASE WHEN (inv_qty - rsrw_qty) > 0 THEN (inv_amt - (rs_amt+rw_amt)) / (inv_qty - rsrw_qty) ELSE 0 END uc
        FROM base),
  r AS (SELECT *,
     ISNULL(ROUND(input_amt*IN_NORMAL_LAST/NULLIF(T_INPUT,0),2),0) a_in_last,
     ISNULL(ROUND(input_amt*IN_RW_BACKSHIP_SORT/NULLIF(T_INPUT,0),2),0) a_bs_sort, ISNULL(ROUND(input_amt*IN_RW_BACKSHIP_PFRW/NULLIF(T_INPUT,0),2),0) a_bs_pfrw,
     ISNULL(ROUND(input_amt*IN_RW_BACKSHIP_PLRW/NULLIF(T_INPUT,0),2),0) a_bs_plrw, ISNULL(ROUND(input_amt*IN_RW_WHRET_SORT/NULLIF(T_INPUT,0),2),0) a_wh_sort,
     ISNULL(ROUND(input_amt*IN_RW_WHRET_PFRW/NULLIF(T_INPUT,0),2),0) a_wh_pfrw, ISNULL(ROUND(input_amt*IN_RW_WHRET_PLRW/NULLIF(T_INPUT,0),2),0) a_wh_plrw,
     CAST(ISNULL(rs_amt,0) AS numeric(18,2)) a_rs, CAST(ISNULL(rw_amt,0) AS numeric(18,2)) a_rw,
     ISNULL(ROUND(uc*ETCOUT_FREESALE,2),0) a_free, ISNULL(ROUND(uc*ETCOUT_ETC,2),0) a_eo_etc, ISNULL(ROUND(uc*LOSS,2),0) a_loss,
     ISNULL(ROUND(uc*EOH_WH0006,2),0) a_eoh
    FROM c),
  r2 AS (SELECT *, (CAST(inv_amt AS numeric(18,2)) - (a_rs+a_rw) - a_free - a_eo_etc - a_loss - a_eoh) out_total FROM r),
  r3 AS (SELECT *, ISNULL(ROUND(out_total*OUT_SHIP_A_FREE/NULLIF(T_OUTPUT,0),2),0) a_saf,
                   ISNULL(ROUND(out_total*OUT_SHIP_B/NULLIF(T_OUTPUT,0),2),0) a_sb FROM r2)
  INSERT INTO doi_vn_stco
   (yyyymm, sel_code, 도우코드, division, EXPEN_SEL, 구분, MODEL, expen_sel명, ACCT_NAME, ITEM_NAME, UNIT_COST,
    BOH_QTY,BOH_AMT, IN_NORMAL_LAST_QTY,IN_NORMAL_LAST_AMT, IN_NORMAL_THIS_QTY,IN_NORMAL_THIS_AMT,
    IN_RW_BACKSHIP_SORT_QTY,IN_RW_BACKSHIP_SORT_AMT, IN_RW_BACKSHIP_PFRW_QTY,IN_RW_BACKSHIP_PFRW_AMT, IN_RW_BACKSHIP_PLRW_QTY,IN_RW_BACKSHIP_PLRW_AMT,
    IN_RW_WHRET_SORT_QTY,IN_RW_WHRET_SORT_AMT, IN_RW_WHRET_PFRW_QTY,IN_RW_WHRET_PFRW_AMT, IN_RW_WHRET_PLRW_QTY,IN_RW_WHRET_PLRW_AMT,
    T_INPUT_QTY,T_INPUT_AMT, ETCIN_RMA_QTY,ETCIN_RMA_AMT, ETCIN_SEMI_PAID_QTY,ETCIN_SEMI_PAID_AMT, ETCIN_SEMI_FREE_QTY,ETCIN_SEMI_FREE_AMT,
    ETCIN_ETC_QTY,ETCIN_ETC_AMT, ETCIN_TOTAL_QTY,ETCIN_TOTAL_AMT,
    OUT_SHIP_A_PAID_QTY,OUT_SHIP_A_PAID_AMT, OUT_SHIP_A_FREE_QTY,OUT_SHIP_A_FREE_AMT, OUT_SHIP_B_QTY,OUT_SHIP_B_AMT, T_OUTPUT_QTY,T_OUTPUT_AMT,
    ETCOUT_RESORT_QTY,ETCOUT_RESORT_AMT, ETCOUT_REWORK_QTY,ETCOUT_REWORK_AMT, ETCOUT_FREESALE_QTY,ETCOUT_FREESALE_AMT, ETCOUT_ETC_QTY,ETCOUT_ETC_AMT, ETCOUT_TOTAL_QTY,ETCOUT_TOTAL_AMT,
    LOSS_QTY,LOSS_AMT, EOH_WH0006_QTY,EOH_WH0006_AMT, VERIFY, EDIT_USER)
  SELECT @YYYYMM,@SEL_CODE,도우코드,division,EXPEN_SEL,구분,MODEL,es명,an,it, CAST(uc AS numeric(24,12)),
    BOH,CAST(boh_amt AS numeric(18,2)), IN_NORMAL_LAST,a_in_last,
    IN_NORMAL_THIS, CAST(input_amt AS numeric(18,2)) - (a_in_last+a_bs_sort+a_bs_pfrw+a_bs_plrw+a_wh_sort+a_wh_pfrw+a_wh_plrw),
    IN_RW_BACKSHIP_SORT,a_bs_sort, IN_RW_BACKSHIP_PFRW,a_bs_pfrw, IN_RW_BACKSHIP_PLRW,a_bs_plrw,
    IN_RW_WHRET_SORT,a_wh_sort, IN_RW_WHRET_PFRW,a_wh_pfrw, IN_RW_WHRET_PLRW,a_wh_plrw,
    T_INPUT, CAST(input_amt AS numeric(18,2)),
    ETCIN_RMA,0, ETCIN_SEMI_PAID,CAST(sp_amt AS numeric(18,2)), ETCIN_SEMI_FREE,CAST(sf_amt AS numeric(18,2)), ETCIN_ETC,0, ETCIN_TOTAL, CAST(sp_amt+sf_amt AS numeric(18,2)),
    OUT_SHIP_A_PAID, out_total - a_saf - a_sb, OUT_SHIP_A_FREE,a_saf, OUT_SHIP_B,a_sb, T_OUTPUT, out_total,
    ETCOUT_RESORT,a_rs, ETCOUT_REWORK,a_rw, ETCOUT_FREESALE,a_free, ETCOUT_ETC,a_eo_etc, ETCOUT_TOTAL, a_rs+a_rw+a_free+a_eo_etc,
    LOSS,a_loss, EOH_WH0006, a_eoh,
    (BOH+T_INPUT+ETCIN_SEMI_PAID+ETCIN_SEMI_FREE+ETCIN_ETC-T_OUTPUT-ETCOUT_TOTAL-LOSS-EOH_WH0006), 'import'
  FROM r3;
END
