/* ============================================================
   UP_VN_STOCK_COST_NEW fix261102a — 기타입고(RMA) 금액 = 수출Claim 수량 × 판매출고 단가(원천)
   대상 DB: DWCMSTEST (VINA)
   요청: 장시문 프로 2026-11-02 「RE: VN CMS_2026년도 7월 CMS 확인요청의 件」
         첨부 수출Claim품목조회(매출원가 표기) 7월·9월 — '판매출고 단가(원천)' 칸 추가
   현상: RMA 금액 0 고정(716AP 7월 9,441개, 9월 1,980개). RMA 수량은 기말재고에 들어가 원가가 매출원가 잔여에서 빠짐.
   수정: ① doi_vn_exp_claim 에 원천출고단가 칸 추가, ERP API BLPrice 를 적재(UP_VN_IF_XFORM_EXP_CLAIM)
         ② RMA 금액 = Claim 건별 수량 × 원천출고단가 합계, 원가 풀·단가 분모에 RMA 포함
   기존 미적용 수정본 fix260928a(uc×수량)를 대체한다.
   원복: db/vn_procs/bak261102a/ 의 두 정의를 CREATE OR ALTER 로 실행(추가한 칸은 남겨도 무해)
   기준: 운영 정의 2026-08-21 17:41:34
   ============================================================ */
IF COL_LENGTH('doi_vn_exp_claim','원천출고단가') IS NULL
    ALTER TABLE doi_vn_exp_claim ADD 원천출고단가 numeric(18,5) NULL;
GO
/* ============================================================
   [VN 260801 V11-3] 제품 매출원가 → doi_vn_stco (OUTPUT 3분할 + expen_sel)
   소스: doi_vn_stock_resc(수량) + DOI_STOCK_BOH(제품기초금액) + 재공 doi_vn_cost(입고=재공출고·반제품) + DOI_VN_RSRW(R/S·R/W)
   ★단가 수정: R/S·R/W가 빼간 (수량+금액)을 제외한 '나머지'로 uc 산정 → 수량0 라인 phantom 제거.
     uc = (투입금액 + RMA금액 − R/S·R/W금액) / (투입수량 + RMA수량 − R/S·R/W수량)   [2026-11-02a] RMA 포함
   [2026-11-02a] 기타입고(RMA) 금액 = 수출Claim 건별 수량 × 판매출고 단가(원천) 합계 (VINA 장시문 11/2 회신 기준)
     · 모델 합계를 원가요소(EXPEN_SEL)별 기존 단가 비중으로 나누고, 반올림 잔차는 비중 1위 요소에 둔다.
     · 원천 단가가 없으면 기존 제품단가 × RMA수량으로 대신한다.
   규칙: RMA=Claim 원천단가(2026-11-02a) / 반제품=재공출고금액 / R/S·R/W=제품기초단가(DOI_VN_RSRW) / 무상매출·SHIP무상=uc×수량(매출원가만)
         EOH=uc×EOH수량(물리고정), OUTPUT(매출원가)=잔여.
   ============================================================ */
CREATE OR ALTER PROCEDURE UP_VN_STOCK_COST_NEW @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
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
  cl AS (SELECT 품번 도우코드, SUM(CAST(수량 AS float)) cl_qty, SUM(CAST(수량 AS float)*CAST(원천출고단가 AS float)) cl_amt,
                SUM(CASE WHEN 원천출고단가 IS NULL THEN 1 ELSE 0 END) cl_null
         FROM doi_vn_exp_claim WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE AND site=@SITE GROUP BY 품번),   /* [2026-11-02a] */
  esrc AS (SELECT DISTINCT 도우코드,division,EXPEN_SEL FROM bh UNION SELECT DISTINCT 도우코드,division,EXPEN_SEL FROM wo UNION SELECT DISTINCT 도우코드,division,EXPEN_SEL FROM rw),
  keys AS (SELECT s.도우코드, s.division, COALESCE(x.EXPEN_SEL,'*') EXPEN_SEL FROM sr s LEFT JOIN esrc x ON x.도우코드=s.도우코드 AND x.division=s.division),
  base AS (
    SELECT k.도우코드, k.division, k.EXPEN_SEL,
       COALESCE(b.구분,w.구분, CASE WHEN k.division='MP' THEN N'양산' ELSE N'개발' END) 구분,
       COALESCE(NULLIF(b.MODEL,''),NULLIF(w.MODEL,''),CASE WHEN LEN(k.도우코드)>1 THEN LEFT(k.도우코드,LEN(k.도우코드)-1) ELSE k.도우코드 END) MODEL, COALESCE(b.es명,w.es명,'') es명,
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
  c0 AS (SELECT *,
         CASE WHEN (inv_qty - rsrw_qty) > 0 THEN (inv_amt - (rs_amt+rw_amt)) / (inv_qty - rsrw_qty) ELSE 0 END uc0
        FROM base),
  /* [2026-11-02a] RMA 금액: 모델 합계(Claim 수량×원천단가, 없으면 기존 단가×수량)를 원가요소별 uc0 비중으로 배분 */
  c1 AS (SELECT c0.*,
           CASE WHEN ISNULL(c0.ETCIN_RMA,0)=0 THEN 0
                WHEN cl.cl_amt IS NOT NULL AND cl.cl_null=0 THEN ROUND(cl.cl_amt,2)
                ELSE ROUND(SUM(c0.uc0) OVER (PARTITION BY c0.도우코드,c0.division)*c0.ETCIN_RMA,2) END rma_tot,
           SUM(c0.uc0) OVER (PARTITION BY c0.도우코드,c0.division) uc0_sum,
           ROW_NUMBER() OVER (PARTITION BY c0.도우코드,c0.division ORDER BY c0.uc0 DESC, c0.EXPEN_SEL) rn
         FROM c0 LEFT JOIN cl ON cl.도우코드=c0.도우코드),
  c2 AS (SELECT *, CAST(CASE WHEN uc0_sum<>0 THEN ROUND(rma_tot*uc0/uc0_sum,2) ELSE 0 END AS numeric(18,2)) a_rma0 FROM c1),
  c3 AS (SELECT *, CAST(a_rma0 + CASE WHEN rn=1 THEN rma_tot - SUM(a_rma0) OVER (PARTITION BY 도우코드,division) ELSE 0 END AS numeric(18,2)) a_rma FROM c2),
  c AS (SELECT *,
         CASE WHEN (inv_qty + ISNULL(ETCIN_RMA,0) - rsrw_qty) > 0
              THEN (inv_amt + a_rma - (rs_amt+rw_amt)) / (inv_qty + ISNULL(ETCIN_RMA,0) - rsrw_qty) ELSE 0 END uc
        FROM c3),
  r AS (SELECT *,
     ISNULL(ROUND(input_amt*IN_NORMAL_LAST/NULLIF(T_INPUT,0),2),0) a_in_last,
     ISNULL(ROUND(input_amt*IN_RW_BACKSHIP_SORT/NULLIF(T_INPUT,0),2),0) a_bs_sort, ISNULL(ROUND(input_amt*IN_RW_BACKSHIP_PFRW/NULLIF(T_INPUT,0),2),0) a_bs_pfrw,
     ISNULL(ROUND(input_amt*IN_RW_BACKSHIP_PLRW/NULLIF(T_INPUT,0),2),0) a_bs_plrw, ISNULL(ROUND(input_amt*IN_RW_WHRET_SORT/NULLIF(T_INPUT,0),2),0) a_wh_sort,
     ISNULL(ROUND(input_amt*IN_RW_WHRET_PFRW/NULLIF(T_INPUT,0),2),0) a_wh_pfrw, ISNULL(ROUND(input_amt*IN_RW_WHRET_PLRW/NULLIF(T_INPUT,0),2),0) a_wh_plrw,
     CAST(ISNULL(rs_amt,0) AS numeric(18,2)) a_rs, CAST(ISNULL(rw_amt,0) AS numeric(18,2)) a_rw,
     ISNULL(ROUND(uc*ETCOUT_FREESALE,2),0) a_free, ISNULL(ROUND(uc*ETCOUT_ETC,2),0) a_eo_etc, ISNULL(ROUND(uc*LOSS,2),0) a_loss,
     ISNULL(ROUND(uc*EOH_WH0006,2),0) a_eoh
    FROM c),
  r2 AS (SELECT *, (CAST(inv_amt AS numeric(18,2)) + a_rma - (a_rs+a_rw) - a_free - a_eo_etc - a_loss - a_eoh) out_total FROM r),
  r3 AS (SELECT *, ISNULL(ROUND(out_total*OUT_SHIP_A_FREE/NULLIF(T_OUTPUT,0),2),0) a_saf,
                   ISNULL(ROUND(out_total*OUT_SHIP_B/NULLIF(T_OUTPUT,0),2),0) a_sb,
                   CASE WHEN T_OUTPUT=0 THEN 0 ELSE out_total END AS sale_amt,
                   CASE WHEN T_OUTPUT=0 THEN out_total ELSE 0 END AS etc_plug FROM r2)
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
    ETCIN_RMA,a_rma, ETCIN_SEMI_PAID,CAST(sp_amt AS numeric(18,2)), ETCIN_SEMI_FREE,CAST(sf_amt AS numeric(18,2)), ETCIN_ETC,0, ETCIN_TOTAL, CAST(a_rma+sp_amt+sf_amt AS numeric(18,2)),   /* [2026-11-02a] */
    OUT_SHIP_A_PAID, sale_amt - a_saf - a_sb, OUT_SHIP_A_FREE,a_saf, OUT_SHIP_B,a_sb, T_OUTPUT, sale_amt,
    ETCOUT_RESORT,a_rs, ETCOUT_REWORK,a_rw, ETCOUT_FREESALE,a_free, ETCOUT_ETC,a_eo_etc+etc_plug, ETCOUT_TOTAL, a_rs+a_rw+a_free+a_eo_etc+etc_plug,
    LOSS,a_loss, EOH_WH0006, a_eoh,
    (BOH+T_INPUT+ETCIN_RMA+ETCIN_SEMI_PAID+ETCIN_SEMI_FREE+ETCIN_ETC-T_OUTPUT-ETCOUT_TOTAL-LOSS-EOH_WH0006), 'import'   /* [2026-11-02a] 수량 검증식에 RMA 포함 */
  FROM r3;
END

GO
