/* ============================================================
   UP_VN_IF_XFORM_FG_SUBUL fix261029a — 제품수불 기타입고(반제품)·기타출고(기타) 매핑 오류
   원인: ① API etc_output 은 기타출고 합계인데 ETCOUT_ETC 에 넣어 재검사·재작업·무상매출 수량이 '기타'에 중복
           → 제품원가가 그 수량에 금액을 한 번 더 매겨 매출원가 감소(202608 717CD −5,176.58)
         ② 반제품 유/무상 입고 수량을 0으로 넣어 기타입고 합계와 불일치(716AP 무상 322, 717NTT 유상 50)
   요청: 도우인시스 VINA 장시문 2026-10-29 메일. 202608 기적재분은 db/vn/fix_stock_resc_202608_etc_semi.sql 로 보정.
   원복: bak261029a/
   ============================================================ */
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_FG_SUBUL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10),
    @site    VARCHAR(4) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    /* [VN 인터페이스 변환] MES 재고수불(FG) 스테이징 → 운영 제품재고수불(doi_vn_stock_resc)
       - mat_id = 도우코드 (직접), division = DOI_VN_STCO 조회(없으면 이력/기본값)
       - 컬럼은 정의서 ver1.8 재고수불 응답필드 ↔ doi_vn_stock_resc 1:1 매핑
       - 반제품(SEMI) 유/무상 입고는 API 미제공 → 재공 반제품 출고 수량으로 채움 [261029]
       - API etc_output 은 기타출고 합계(=other_output_total) → ETCOUT_ETC 는 잔여로 산출 [261029] */

    DELETE FROM doi_vn_stock_resc WHERE yyyymm = @yyyymm AND sel_code = @selCode;

    INSERT INTO doi_vn_stock_resc
        (yyyymm, sel_code, 도우코드, division, BOH,
         IN_NORMAL_LAST, IN_NORMAL_THIS,
         IN_RW_BACKSHIP_SORT, IN_RW_BACKSHIP_PFRW, IN_RW_BACKSHIP_PLRW,
         IN_RW_WHRET_SORT, IN_RW_WHRET_PFRW, IN_RW_WHRET_PLRW,
         T_INPUT, ETCIN_RMA, ETCIN_SEMI_PAID, ETCIN_SEMI_FREE, ETCIN_ETC, ETCIN_TOTAL,
         OUT_SHIP_A_PAID, OUT_SHIP_A_FREE, OUT_SHIP_B, T_OUTPUT,
         ETCOUT_RESORT, ETCOUT_REWORK, ETCOUT_FREESALE, ETCOUT_ETC, ETCOUT_TOTAL,
         LOSS, EOH_WH0006, VERIFY, EDIT_USER, EDIT_DT)
    SELECT
         @yyyymm, @selCode, s.mat_id,
         COALESCE(
             (SELECT TOP 1 c.division FROM DOI_VN_STCO c WHERE c.도우코드 = s.mat_id ORDER BY c.yyyymm DESC, c.sel_code),
             (SELECT TOP 1 r.division FROM doi_vn_stock_resc r WHERE r.도우코드 = s.mat_id ORDER BY r.yyyymm DESC),
             'MP') AS division,
         ISNULL(s.boh_ok_mes, 0),
         ISNULL(s.normal_last_month, 0), ISNULL(s.normal_this_month, 0),
         ISNULL(s.backship_sorting, 0), ISNULL(s.backship_pfrw, 0), ISNULL(s.backship_plrw, 0),
         ISNULL(s.wh_rt_sorting, 0), ISNULL(s.wh_rt_pfrw, 0), ISNULL(s.wh_rt_plrw, 0),
         ISNULL(s.total_wh_input, 0),
         ISNULL(s.back_ship_ng_qty, 0),      -- ETCIN_RMA
         ISNULL(sm.paid, 0), ISNULL(sm.free, 0), -- ETCIN_SEMI_PAID / SEMI_FREE: API 미제공 → 재공 반제품 출고(doi_vn_prod_resc) 유/무상 수량 [261029]
         ISNULL(s.etc_input, 0),              -- ETCIN_ETC
         ISNULL(s.other_input_total, 0),      -- ETCIN_TOTAL
         ISNULL(s.shipped_level_a_paid, 0), ISNULL(s.shipped_level_a_free, 0),
         ISNULL(s.shipped_level_b_paid, 0),   -- OUT_SHIP_B
         ISNULL(s.t_output_3, 0),             -- T_OUTPUT
         ISNULL(s.line_transfer_sorting, 0),  -- ETCOUT_RESORT
         ISNULL(s.line_transfer_rework, 0),   -- ETCOUT_REWORK
         ISNULL(s.shipped_level_b_free, 0),   -- ETCOUT_FREESALE (B급 무상매출)
         CASE WHEN ISNULL(s.other_output_total,0)-ISNULL(s.line_transfer_total,0)-ISNULL(s.shipped_level_b_free,0) > 0
              THEN ISNULL(s.other_output_total,0)-ISNULL(s.line_transfer_total,0)-ISNULL(s.shipped_level_b_free,0) ELSE 0 END,
                                              -- ETCOUT_ETC = 기타출고 합계 − 재검사·재작업 − 무상매출 [261029] (API etc_output 은 합계라 쓰지 않음)
         ISNULL(s.other_output_total, 0),     -- ETCOUT_TOTAL
         ISNULL(s.loss_spare, 0),             -- LOSS
         ISNULL(s.eoh_ok_mes, 0),             -- EOH_WH0006
         0,                                   -- VERIFY (검증용, 후속 산식화)
         'IF_API', GETDATE()
    FROM DOI_VN_IF_FG_SUBUL s
    LEFT JOIN (SELECT 도우코드,
                      SUM(ISNULL(ETCOUT_SEMI_PAID_전,0)+ISNULL(ETCOUT_SEMI_PAID_후,0)) paid,
                      SUM(ISNULL(ETCOUT_SEMI_FREE_전,0)+ISNULL(ETCOUT_SEMI_FREE_후,0)) free
               FROM doi_vn_prod_resc WHERE yyyymm = @yyyymm AND sel_code = @selCode GROUP BY 도우코드) sm ON sm.도우코드 = s.mat_id
    WHERE s.SITE = @site AND s.SEL_CODE = @selCode
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.work_date))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS loaded;
END
