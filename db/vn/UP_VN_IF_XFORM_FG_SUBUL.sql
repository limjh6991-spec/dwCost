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
       - 반제품(SEMI) 유/무상 입고는 API 미제공 → 0 (추후 필요시 보완) */

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
         0, 0,                                -- ETCIN_SEMI_PAID / SEMI_FREE (API 미제공)
         ISNULL(s.etc_input, 0),              -- ETCIN_ETC
         ISNULL(s.other_input_total, 0),      -- ETCIN_TOTAL
         ISNULL(s.shipped_level_a_paid, 0), ISNULL(s.shipped_level_a_free, 0),
         ISNULL(s.shipped_level_b_paid, 0),   -- OUT_SHIP_B
         ISNULL(s.t_output_3, 0),             -- T_OUTPUT
         ISNULL(s.line_transfer_sorting, 0),  -- ETCOUT_RESORT
         ISNULL(s.line_transfer_rework, 0),   -- ETCOUT_REWORK
         ISNULL(s.shipped_level_b_free, 0),   -- ETCOUT_FREESALE (B급 무상매출)
         ISNULL(s.etc_output, 0),             -- ETCOUT_ETC
         ISNULL(s.other_output_total, 0),     -- ETCOUT_TOTAL
         ISNULL(s.loss_spare, 0),             -- LOSS
         ISNULL(s.eoh_ok_mes, 0),             -- EOH_WH0006
         0,                                   -- VERIFY (검증용, 후속 산식화)
         'IF_API', GETDATE()
    FROM DOI_VN_IF_FG_SUBUL s
    WHERE s.SITE = @site AND s.SEL_CODE = @selCode;

    SELECT @@ROWCOUNT AS loaded;
END
