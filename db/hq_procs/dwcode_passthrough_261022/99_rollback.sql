/* ============================================================
   롤백 — 역순 (운영, SSMS 수동). 도우코드는 라벨 전용이라 결산 수치 영향 없음.
   ============================================================ */
USE [도우제조원가시스템];
GO
-- 1) 10월~ 인라인/연결 해제:
--    (a) UP_DOI_COST, UP_DOI_STOCK_COST 를 Phase 0 백업본(인라인 주입 전 OBJECT_DEFINITION)으로 ALTER 복원
--    (b) 결산 스크립트에서 EXEC UP_DOI_FILL_DWCODE 호출 제거(또는 UP_DOI_SALE_COST 임베드 1줄 제거)

-- 2) 리포트 프로시저: Phase 0 백업본으로 ALTER 복원 (COALESCE(NULLIF(도우코드,''),도우모델) 표기 되돌리기)

-- 3) 백필 되돌리기 (값 영향 없음 — 도우코드만)
UPDATE dbo.DOI_COST      SET 도우코드=NULL WHERE YYYYMM LIKE '2026%' AND SITE='HQ';
UPDATE dbo.DOI_STCO      SET 도우코드=NULL WHERE YYYYMM LIKE '2026%' AND SITE='HQ';
UPDATE dbo.DOI_SLCO      SET 도우코드=NULL WHERE YYYYMM LIKE '2026%' AND SITE='HQ';
UPDATE dbo.DOI_SMCE_COST SET 도우코드=NULL WHERE YYYYMM LIKE '2026%' AND SITE='HQ';
GO

-- 4) fill 프로시저 제거
IF OBJECT_ID('dbo.UP_DOI_FILL_DWCODE') IS NOT NULL DROP PROCEDURE dbo.UP_DOI_FILL_DWCODE;
GO

-- 5) 컬럼 DROP (리포트/프로시저 복원 후)
IF COL_LENGTH('dbo.DOI_SCOF','도우코드')      IS NOT NULL ALTER TABLE dbo.DOI_SCOF      DROP COLUMN 도우코드;
IF COL_LENGTH('dbo.DOI_SMCE_COST','도우코드') IS NOT NULL ALTER TABLE dbo.DOI_SMCE_COST DROP COLUMN 도우코드;
IF COL_LENGTH('dbo.DOI_SLCO','도우코드')      IS NOT NULL ALTER TABLE dbo.DOI_SLCO      DROP COLUMN 도우코드;
IF COL_LENGTH('dbo.DOI_STCO','도우코드')      IS NOT NULL ALTER TABLE dbo.DOI_STCO      DROP COLUMN 도우코드;
IF COL_LENGTH('dbo.DOI_COST','도우코드')      IS NOT NULL ALTER TABLE dbo.DOI_COST      DROP COLUMN 도우코드;
GO
