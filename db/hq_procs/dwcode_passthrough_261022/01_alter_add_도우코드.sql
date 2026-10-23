/* ============================================================
   Phase 1 — 도우코드 컬럼 ADD  (운영 도우제조원가시스템, SSMS 수동)
   - NULL 허용 / 기본값 없음  → 기존 명시목록 INSERT 영향 없음
   - ★DOI_SLCO 는 반드시 03(UP_DOI_SALE_COST 위치기반 INSERT 수정)과 동시 배포
   - 재실행 안전(존재 시 skip)
   ============================================================ */
USE [도우제조원가시스템];
GO
-- 매출원가·제품재고
IF COL_LENGTH('dbo.DOI_STCO','도우코드') IS NULL
    ALTER TABLE dbo.DOI_STCO ADD 도우코드 nvarchar(50) NULL;
GO
-- 재료비·제조경비
IF COL_LENGTH('dbo.DOI_COST','도우코드') IS NULL
    ALTER TABLE dbo.DOI_COST ADD 도우코드 varchar(20) NULL;
GO
-- 판관비(매출원가 거래처별)
IF COL_LENGTH('dbo.DOI_SLCO','도우코드') IS NULL
    ALTER TABLE dbo.DOI_SLCO ADD 도우코드 nvarchar(50) NULL;
GO
-- 판관비 집계(배부결과) — 판관비 화면(C0009008/DOI_SalesAdminByModel)이 읽는 테이블
IF COL_LENGTH('dbo.DOI_SMCE_COST','도우코드') IS NULL
    ALTER TABLE dbo.DOI_SMCE_COST ADD 도우코드 nvarchar(50) NULL;
GO
-- 상계 (실효 낮음 — 리포트는 DOI_원장상계[이미 full코드] 사용. 생략 가능)
IF COL_LENGTH('dbo.DOI_SCOF','도우코드') IS NULL
    ALTER TABLE dbo.DOI_SCOF ADD 도우코드 varchar(50) NULL;
GO
-- 확인
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME='도우코드' AND TABLE_NAME IN ('DOI_STCO','DOI_COST','DOI_SLCO','DOI_SMCE_COST','DOI_SCOF')
ORDER BY TABLE_NAME;
GO
