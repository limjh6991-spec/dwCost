/* ============================================================
   fix261029a 원복 — 2026-10-29 21:05 적용 직전 상태로 되돌린다. (DWCMSTEST)
   적용 내용:
     ① UP_VN_WIP_EVAL_NEW      : 전량 LOSS 시 수량 0인 LOSS 칸 금액 → 다른 쪽으로
     ② UP_VN_IF_XFORM_FG_SUBUL : ETCOUT_ETC = 합계 − 재검사·재작업·무상매출, 반제품 유/무상 = 재공 반제품 출고 수량
     ③ db/vn/fix_stock_resc_202608_etc_semi.sql 로 202608 doi_vn_stock_resc 보정
     ④ 202608 VN ACTUAL 재실행: UP_VN_WIP_EVAL_NEW → UP_VN_STOCK_COST_NEW → UP_VN_SALE_COST_NEW
   결과: 제품 매출원가 7,428,394.27 → 7,923,602.86, 기말 1,525,933.16 → 1,525,599.12,
         716ETT/818NTT LOSS_후 금액 → LOSS_전, 717CD 매출원가 −5,176.58 → 219.15.
   데이터 스냅샷: doi_vn_stock_resc / doi_vn_cost / doi_vn_stco / doi_slco _bak261029a (202608 행만)
   ============================================================ */

-- ① 프로시저 정의 원복: 이 폴더의 UP_VN_WIP_EVAL_NEW.sql, UP_VN_IF_XFORM_FG_SUBUL.sql 실행

-- ② 데이터 원복 (스냅샷 → 원 테이블)
BEGIN TRAN;
DELETE FROM doi_vn_stock_resc WHERE yyyymm='202608' AND sel_code='ACTUAL';
INSERT INTO doi_vn_stock_resc SELECT * FROM doi_vn_stock_resc_bak261029a;
DELETE FROM doi_vn_cost WHERE yyyymm='202608' AND site='VN' AND sel_code='ACTUAL';
INSERT INTO doi_vn_cost SELECT * FROM doi_vn_cost_bak261029a;
DELETE FROM doi_vn_stco WHERE yyyymm='202608' AND sel_code='ACTUAL';
INSERT INTO doi_vn_stco SELECT * FROM doi_vn_stco_bak261029a;
DELETE FROM doi_slco WHERE yyyymm='202608' AND site='VN' AND sel_code='ACTUAL';
INSERT INTO doi_slco SELECT * FROM doi_slco_bak261029a;
COMMIT;
