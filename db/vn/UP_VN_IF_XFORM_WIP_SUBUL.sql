/* ============================================================================
 * UP_VN_IF_XFORM_WIP_SUBUL  (MES 생산수불 → 운영 재공수불 doi_vn_prod_resc)
 *   staging DOI_VN_IF_WIP_SUBUL (mat_id 그레인, PL전50%=before_pfl_50 / 후90%=after_pfl_90 int)
 *   → doi_vn_prod_resc (도우코드 그레인, 전/후 numeric, 포지션 LINE·B_LEVEL × WIP·FGS)
 *
 *   ★매핑 근거(2026-08-24, staging 62행 전수 내부합계 검증 PASS):
 *     - mat_id = 도우코드 (직접, 중복 0 → 집계 불필요; FG_SUBUL과 동일)
 *     - division = DOI_VN_STCO 조회(MASS→MP 정규화), 없으면 접미 P→MP/else→R&D
 *     - 전 = before_pfl_50 / pfl_50, 후 = after_pfl_90 / pfl_90  (완성률 가중은 하류 재공평가 단계)
 *     - 검증: A_SUB=LINE_WIP+LINE_FGS, B_SUB=B_WIP+B_FGS, T_BOH=A+B, EOH_WIP=line+b,
 *             TOTAL_EOH=WIP+FGS, total_input_to_line=기타입고4합, total_output=A급+B급,
 *             out_b=반제품유상+무상, 코드변경/기타출고=전량0  (전부 62/62)
 *     - OUTPUT_A = total_out_a_level(A급 정상완성), 반제품(B급)=ETCOUT_SEMI 유/무상
 *     - ETCIN_SEMI(반제품입고)·T_EOH_FGS(합)는 MES 직접컬럼 없음 → 0 / 합산 산출
 *   시그니처: (@yyyymm, @selCode, @site) / 반환: 적재 건수(int)
 *   ⚠️doi_vn_prod_resc 는 _NEW 결산 입력. DELETE+INSERT(yyyymm+sel_code) 멱등.
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_VN_IF_XFORM_WIP_SUBUL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10),
    @site    VARCHAR(4) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode = '' SET @selCode = 'ACTUAL';
    IF @site    IS NULL OR @site    = '' SET @site    = 'VN';

    DELETE FROM doi_vn_prod_resc WHERE yyyymm = @yyyymm AND sel_code = @selCode;

    INSERT INTO doi_vn_prod_resc
        (yyyymm, sel_code, 도우코드, division,
         BOH_LINE_WIP_전, BOH_LINE_WIP_후, BOH_LINE_FGS_전, BOH_LINE_FGS_후,
         BOH_A_SUB_전, BOH_A_SUB_후, BOH_B_WIP_전, BOH_B_WIP_후, BOH_B_FGS_전, BOH_B_FGS_후,
         BOH_B_SUB_전, BOH_B_SUB_후, T_BOH_전, T_BOH_후,
         USC_INPUT, ETCIN_CODE, ETCIN_RESORT, ETCIN_REWORK, ETCIN_SEMI, ETCIN_ETC, ETCIN_TOTAL,
         OUTPUT_A,
         ETCOUT_CODE_전, ETCOUT_CODE_후, ETCOUT_SEMI_PAID_전, ETCOUT_SEMI_PAID_후,
         ETCOUT_SEMI_FREE_전, ETCOUT_SEMI_FREE_후, ETCOUT_ETC_전, ETCOUT_ETC_후,
         ETCOUT_TOTAL_전, ETCOUT_TOTAL_후, LOSS_전, LOSS_후,
         EOH_LINE_WIP_전, EOH_LINE_WIP_후, EOH_LINE_FGS_전, EOH_LINE_FGS_후,
         EOH_B_WIP_전, EOH_B_WIP_후, EOH_B_FGS_전, EOH_B_FGS_후,
         T_EOH_WIP_전, T_EOH_WIP_후, T_EOH_FGS_전, T_EOH_FGS_후, TOTAL_EOH_전, TOTAL_EOH_후,
         EDIT_USER, EDIT_DT)
    SELECT
         @yyyymm, @selCode, LTRIM(RTRIM(s.mat_id)),
         COALESCE(
             (SELECT TOP 1 CASE WHEN c.division IN ('MASS','MP') THEN 'MP' ELSE 'R&D' END
                FROM DOI_VN_STCO c WHERE c.도우코드 = LTRIM(RTRIM(s.mat_id)) ORDER BY c.yyyymm DESC, c.sel_code),
             CASE WHEN RIGHT(RTRIM(s.mat_id),1) = 'P' THEN 'MP' ELSE 'R&D' END) AS division,
         -- BOH (전=before_pfl_50, 후=after_pfl_90)
         ISNULL(s.boh_a_wip_before_pfl_50,0), ISNULL(s.boh_a_wip_after_pfl_90,0),
         ISNULL(s.boh_a_fgs_before_pfl_50,0), ISNULL(s.boh_a_fgs_after_pfl_90,0),
         ISNULL(s.boh_a_before_pfl_50,0),     ISNULL(s.boh_a_after_pfl_90,0),
         ISNULL(s.boh_b_wip_before_pfl_50,0), ISNULL(s.boh_b_wip_after_pfl_90,0),
         ISNULL(s.boh_b_fgs_before_pfl_50,0), ISNULL(s.boh_b_fgs_after_pfl_90,0),
         ISNULL(s.boh_b_before_pfl_50,0),     ISNULL(s.boh_b_after_pfl_90,0),
         ISNULL(s.t_boh_before_pfl_50,0),     ISNULL(s.t_boh_after_pfl_90,0),
         -- INPUT / 기타입고 (SEMI=API미제공→0, TOTAL=라인총투입=기타입고4합)
         ISNULL(s.input_usc_cutting_qty,0),
         ISNULL(s.change_code_qty,0), ISNULL(s.input_re_sorting_qty,0), ISNULL(s.input_rework_qty,0),
         0, ISNULL(s.wip_etc_input,0), ISNULL(s.total_input_to_line,0),
         -- OUTPUT_A (A급 정상완성)
         ISNULL(s.total_out_a_level,0),
         -- 기타출고 (전/후): CODE=0, 반제품(B급) 유/무상, ETC=0
         ISNULL(s.output_code_change_50,0),  ISNULL(s.output_code_change_90,0),
         ISNULL(s.b_level_ship_paid_50,0),   ISNULL(s.b_level_ship_paid_90,0),
         ISNULL(s.b_level_ship_free_50,0),   ISNULL(s.b_level_ship_free_90,0),
         ISNULL(s.output_other_50,0),        ISNULL(s.output_other_90,0),
         ISNULL(s.output_code_change_50,0)+ISNULL(s.b_level_ship_paid_50,0)+ISNULL(s.b_level_ship_free_50,0)+ISNULL(s.output_other_50,0),
         ISNULL(s.output_code_change_90,0)+ISNULL(s.b_level_ship_paid_90,0)+ISNULL(s.b_level_ship_free_90,0)+ISNULL(s.output_other_90,0),
         -- LOSS (SCRAP)
         ISNULL(s.scrap_before_pfl,0), ISNULL(s.scrap_after_pfl,0),
         -- EOH (전/후)
         ISNULL(s.eoh_line_wip_pfl_50,0), ISNULL(s.eoh_line_wip_pfl_90,0),
         ISNULL(s.eoh_line_fgs_pfl_50,0), ISNULL(s.eoh_line_fgs_pfl_90,0),
         ISNULL(s.eoh_b_wip_pfl_50,0),    ISNULL(s.eoh_b_wip_pfl_90,0),
         ISNULL(s.eoh_b_fgs_pfl_50,0),    ISNULL(s.eoh_b_fgs_pfl_90,0),
         ISNULL(s.t_eoh_wip_pfl_50,0),    ISNULL(s.t_eoh_wip_pfl_90,0),
         ISNULL(s.eoh_line_fgs_pfl_50,0)+ISNULL(s.eoh_b_fgs_pfl_50,0),   -- T_EOH_FGS_전 (합산)
         ISNULL(s.eoh_line_fgs_pfl_90,0)+ISNULL(s.eoh_b_fgs_pfl_90,0),   -- T_EOH_FGS_후 (합산)
         ISNULL(s.t_eoh_mes_pfl_50,0),    ISNULL(s.t_eoh_mes_pfl_90,0),
         'IF_API', GETDATE()
    FROM DOI_VN_IF_WIP_SUBUL s
    WHERE s.SITE = @site AND s.SEL_CODE = @selCode
      AND s.mat_id IS NOT NULL AND LTRIM(RTRIM(s.mat_id)) <> ''
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.work_date))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT;
END
