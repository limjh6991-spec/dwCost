-- ======================================================================
-- [2026-11-12] DOI_STOCK H818VT MODEL 교정 (제품수불) — 202610 HQ
-- ----------------------------------------------------------------------
-- 문제: 제품수불(창고수불 엑셀) 품명이 'H'를 뺀 값으로 와서(품번 H818VT → 품명 '818V')
--       DOI_STOCK.MODEL='818V' 로 적재됨. 재공(DOI_COST)은 'H818V'(BOM HTG 교정 반영)라 불일치.
-- 증상: ① 제품(DOI_STCO)에서 818VD+H818VT가 MODEL='818V'/개발로 병합 → 도우코드 NULL
--       ② H818VT 재공 제조원가 27,555,897 이 제품으로 안 흘러 '고아'(제품 재고자산 과소계상)
--       ③ 다른 개발자(KYH)의 도우코드 그레인 변경(MODEL_TYPE를 GROUP BY 추가) 시 (개발,818V)에
--          818VD·H818VT 두 행이 같은 PK(…,구분,MODEL,EXPEN_SEL,ACCT_NAME)로 생성 → pk_doi_stco 위반 →
--          UP_DOI_STOCK_COST ROLLBACK → (UP_DOI_STOCK_BOH가 내부 EXEC) 전체 결산 체인 중단.
-- 교정: H818VT의 MODEL을 재공과 동일한 'H818V'로. (전월 202609 DOI_STCO엔 이미 개발/H818V 분리 존재,
--       EOH=0 이라 BOH 오염 없음 — 교차월 수정 불필요. 202609는 마감(IS_CLOSED=Y).)
-- 결과(재결산 후): 개발/818V(도우코드 818VD)·개발/H818V(도우코드 H818VT) 분리, 도우코드 NULL 0건,
--       H818V IN=EOH=27,555,897 제품 유입(재고자산 교정 +27,555,897), OUT Δ=0 → 영업이익 189,556,238 불변.
-- durability: hq_settlement.py load_stock 에 HTG 교정 내장(품번 H접두 & 품명 non-H → 'H' 복원).
--             → 미래 월 자동 교정, PK중복 재발 예방.
-- ======================================================================
UPDATE DOI_STOCK
   SET MODEL = 'H818V'
 WHERE YYYYMM = '202610' AND SITE = 'HQ' AND SEL_CODE = 'ACTUAL'
   AND MODEL_TYPE = 'H818VT' AND MODEL = '818V';
-- (1행 적용 완료 2026-11-12. 이후 EXPEN_MATL→…→FILL 전체 재결산 필요.)
