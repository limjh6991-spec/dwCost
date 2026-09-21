-- =============================================================================
-- DOI_재고자산평가: 컬럼명 오타 정정 [충담금잔액] → [충당금잔액] (2026-09-21)
--   ※ 충당금기설정액/조정금액은 '충당금'(당)인데 잔액만 '충담금'(담) 오타 → 통일.
--   ★ 이 rename 은 C0009000.xml C0009015_Sch1 SELECT([충당금잔액])·프론트 필드명과 lockstep.
--      jar/프론트 배포 전(또는 동시)에 SSMS 에서 실행할 것. 미적용 시 SELECT 가
--      'Invalid column name 충당금잔액' 로 실패함.
--   운영 DB(도우제조원가시스템) 및 개발 DWCMSTEST 동일 적용.
-- =============================================================================
IF  EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'DOI_재고자산평가') AND name = N'충담금잔액')
AND NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'DOI_재고자산평가') AND name = N'충당금잔액')
BEGIN
    EXEC sp_rename N'DOI_재고자산평가.충담금잔액', N'충당금잔액', N'COLUMN';
    PRINT '[OK] DOI_재고자산평가.충담금잔액 → 충당금잔액 rename 완료';
END
ELSE
    PRINT '[SKIP] 이미 충당금잔액 이거나 충담금잔액 컬럼 없음 — 변경 없음';
GO
