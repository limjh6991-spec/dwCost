/* [VN 260801] doi_vn_cost 재설계: DOI_COST 구조(원가항목 grain) + BOH/EOH 포지션 금액. 데이터는 신규 재공평가 로직으로 채움 */
-- 구조: SELECT TOP 0 * INTO doi_vn_cost FROM DOI_COST;
-- ALTER TABLE doi_vn_cost ADD (포지션 금액 16):
ALTER TABLE doi_vn_cost ADD
  [BOH_LINE_WIP_전_AMT] numeric(18,2) NULL,
  [BOH_LINE_WIP_후_AMT] numeric(18,2) NULL,
  [BOH_LINE_FGS_전_AMT] numeric(18,2) NULL,
  [BOH_LINE_FGS_후_AMT] numeric(18,2) NULL,
  [BOH_B_WIP_전_AMT] numeric(18,2) NULL,
  [BOH_B_WIP_후_AMT] numeric(18,2) NULL,
  [BOH_B_FGS_전_AMT] numeric(18,2) NULL,
  [BOH_B_FGS_후_AMT] numeric(18,2) NULL,
  [EOH_LINE_WIP_전_AMT] numeric(18,2) NULL,
  [EOH_LINE_WIP_후_AMT] numeric(18,2) NULL,
  [EOH_LINE_FGS_전_AMT] numeric(18,2) NULL,
  [EOH_LINE_FGS_후_AMT] numeric(18,2) NULL,
  [EOH_B_WIP_전_AMT] numeric(18,2) NULL,
  [EOH_B_WIP_후_AMT] numeric(18,2) NULL,
  [EOH_B_FGS_전_AMT] numeric(18,2) NULL,
  [EOH_B_FGS_후_AMT] numeric(18,2) NULL;
