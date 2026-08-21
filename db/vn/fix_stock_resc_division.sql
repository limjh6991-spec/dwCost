/* ============================================================
   [VN 260821] doi_vn_stock_resc.division 오분류 교정 (월 업로드 후 결산 전)
   문제: 창고수불(FGS) division 파생이 개발(R&D) 도우코드 일부를 'MP'(양산)로
         오분류 → STOCK_COST_NEW 재공→제품 조인키(도우코드+division+EXPEN_SEL)
         불일치 → 재공 제품출고금액(OUTPUT_A_AMT)이 제품 입고(T_INPUT_AMT)로
         넘어가지 않음(202607: 9개 개발모델 190,830.97 누락, 717CD/717DD/817ED 등
         매출원가 0=매출총이익 100% 현상).
   진단: 재공(doi_vn_cost).division='R&D' vs 창고(doi_vn_stock_resc).division='MP'.
         division 은 WIP 파일 파생인 재공이 authoritative, 창고는 로더 기본값 'MP'가 오류.
   해법: 창고 division 을 재공에 정렬(없으면 도우코드 접미 규칙 P→MP/else→R&D)
         후 STOCK_BOH_NEW→STOCK_COST_NEW→SALE_COST_NEW→SMCE_COST_NEW 재실행.
   검증: 재공 OUTPUT_A_AMT == 제품 T_INPUT_AMT (202607: 7,820,876.22 완전일치).
   ★근본대책: FGS 업로드 로더(division 파생)에서 접미/ WIP division 기준 분류.
   ============================================================ */
DECLARE @YYYYMM varchar(6) = '202607';

IF OBJECT_ID('doi_vn_stock_resc_bak_division','U') IS NOT NULL DROP TABLE doi_vn_stock_resc_bak_division;
SELECT * INTO doi_vn_stock_resc_bak_division FROM doi_vn_stock_resc WHERE yyyymm=@YYYYMM;

UPDATE s SET s.division = COALESCE(w.division, CASE WHEN RIGHT(s.도우코드,1)='P' THEN 'MP' ELSE 'R&D' END)
FROM doi_vn_stock_resc s
LEFT JOIN (SELECT 도우코드, MAX(division) division FROM doi_vn_cost WHERE yyyymm=@YYYYMM GROUP BY 도우코드) w
  ON w.도우코드 = s.도우코드
WHERE s.yyyymm=@YYYYMM
  AND s.division <> COALESCE(w.division, CASE WHEN RIGHT(s.도우코드,1)='P' THEN 'MP' ELSE 'R&D' END);

-- 검증(공통 도우코드 division 불일치 0 이어야 함)
SELECT COUNT(*) AS 재공창고_division_불일치
FROM (SELECT 도우코드, MAX(division) d FROM doi_vn_cost        WHERE yyyymm=@YYYYMM GROUP BY 도우코드) w
JOIN (SELECT 도우코드, MAX(division) d FROM doi_vn_stock_resc WHERE yyyymm=@YYYYMM GROUP BY 도우코드) s ON s.도우코드=w.도우코드
WHERE w.d <> s.d;
