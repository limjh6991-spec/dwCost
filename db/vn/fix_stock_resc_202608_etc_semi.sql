/* ============================================================
   202608 제품수불(doi_vn_stock_resc) 기적재분 보정 — UP_VN_IF_XFORM_FG_SUBUL fix261029a 와 같은 식
   - ETCOUT_ETC      = 기타출고 합계 − 재검사·재작업 − 무상매출 (202608 은 전 모델 0)
   - ETCIN_SEMI_PAID/FREE = 재공 반제품 출고(doi_vn_prod_resc) 유/무상 수량
   변환 프로시저를 다시 돌리지 않는 이유: 적재 후 division 정렬(fix_stock_resc_division.sql) 등
   수기 보정이 있어 DELETE+INSERT 하면 지워진다. 해당 컬럼만 UPDATE 한다.
   이후 UP_VN_WIP_EVAL_NEW → UP_VN_STOCK_COST_NEW → UP_VN_SALE_COST_NEW 재실행.
   ============================================================ */
DECLARE @YM varchar(6) = '202608', @SC varchar(10) = 'ACTUAL';

UPDATE r SET
    ETCOUT_ETC      = CASE WHEN r.ETCOUT_TOTAL - r.ETCOUT_RESORT - r.ETCOUT_REWORK - r.ETCOUT_FREESALE > 0
                           THEN r.ETCOUT_TOTAL - r.ETCOUT_RESORT - r.ETCOUT_REWORK - r.ETCOUT_FREESALE ELSE 0 END,
    ETCIN_SEMI_PAID = ISNULL(sm.paid, 0),
    ETCIN_SEMI_FREE = ISNULL(sm.free, 0)
FROM doi_vn_stock_resc r
LEFT JOIN (SELECT 도우코드,
                  SUM(ISNULL(ETCOUT_SEMI_PAID_전,0)+ISNULL(ETCOUT_SEMI_PAID_후,0)) paid,
                  SUM(ISNULL(ETCOUT_SEMI_FREE_전,0)+ISNULL(ETCOUT_SEMI_FREE_후,0)) free
           FROM doi_vn_prod_resc WHERE yyyymm = @YM AND sel_code = @SC GROUP BY 도우코드) sm ON sm.도우코드 = r.도우코드
WHERE r.yyyymm = @YM AND r.sel_code = @SC;
