/* ============================================================
   [VN _NEW 결산 실행 순서 런북]  EXEC 파라미터: @YYYYMM,'VN','ACTUAL'
   ★순서 중요: UP_VN_RSRW(R/S·R/W 재분류·재작업 원가) 가
     - STOCK_BOH_NEW 뒤(제품 기초단가 DOI_STOCK_BOH 필요)
     - WIP_EVAL_NEW 앞(재공이 rs/rw 금액을 DOI_VN_RSRW 에서 읽어 ETCIN_RESORT/REWORK_AMT 산정)
     - STOCK_COST_NEW 앞(창고가 R/S 출고금액을 DOI_VN_RSRW 에서 읽음)
     에 있어야 함. 누락/순서오류 시 재공 기타입고(ETCIN_RESORT/REWORK) 금액=0,
     창고 R/S 출고가 매출원가로 plug (2026-08-21 발견·수정).
   검증: 창고 R/S+R/W out == 재공 R/S+R/W in (202607: 758,678.99 일치),
        재공 투입=산출, 제품 좌=우, 재공OUT=제품IN.
   ⚠️업로드 후 선행: normalize_dept_cost_acctname.sql(계정과목 정규화),
     fix_stock_resc_division.sql(창고 division 정렬).
   ============================================================ */
DECLARE @YM varchar(6)='202607', @ST varchar(4)='VN', @SC varchar(10)='ACTUAL';

EXEC UP_VN_STOCK_ADJ      @YM,@ST,@SC;   -- 1. 재고조정(6272)
EXEC UP_VN_MATL_RESC      @YM,@ST,@SC;   -- 2. 재료비 원장
EXEC UP_VN_MAT_AMT        @YM,@ST,@SC;   -- 3. 재료비 집계
EXEC UP_VN_ACCT_EXPEN     @YM,@ST,@SC;   -- 4. 계정별 비용(doi_acct_expen)
EXEC UP_VN_EXPN_INPUT     @YM,@ST,@SC;   -- 5. 제조경비 투입(doi_expn_matl)
EXEC UP_VN_MAT_COST_NEW   @YM,@ST,@SC;   -- 6. 재료비 배부(doi_mat_cost)
EXEC UP_VN_COST_BOH       @YM,@ST,@SC;   -- 7. 재공 기초(DOI_COST_BOH)
EXEC UP_VN_COST_UNIT      @YM,@ST,@SC;   -- 8. 원가단위
EXEC UP_VN_STOCK_BOH_NEW  @YM,@ST,@SC;   -- 9. 제품 기초 이월(DOI_STOCK_BOH, 전월 doi_vn_stco EOH)
EXEC UP_VN_RSRW           @YM,@ST,@SC;   -- 10.★R/S·R/W 재분류원가(DOI_VN_RSRW) — WIP_EVAL 앞!
EXEC UP_VN_WIP_EVAL_NEW   @YM,@ST,@SC;   -- 11. 재공 평가(doi_vn_cost), rs/rw 반영
EXEC UP_VN_STOCK_COST_NEW @YM,@ST,@SC;   -- 12. 제품 매출원가(doi_vn_stco)
EXEC UP_VN_SALE_COST_NEW  @YM,@ST,@SC;   -- 13. 매출원가 원장(doi_slco)
EXEC UP_VN_SMCE_COST_NEW  @YM,@ST,@SC;   -- 14. 판관비 배부(doi_smce_cost)
