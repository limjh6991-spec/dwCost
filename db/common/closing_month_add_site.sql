/* ============================================================================
 * DOI_CLOSING_MONTH 사업장(SITE) 분리 (2026-08-25)
 *   배경: 마감 체크가 YYYYMM만 봐서 HQ가 202607을 마감하면 VN 202607도 차단됨.
 *   변경: SITE 컬럼 추가 + PK (YYYYMM) → (YYYYMM, SITE) → 같은 월을 HQ/VN 각각 마감.
 *   백필: 기존 행은 그 DB의 주 사업장으로 태깅 — @defaultSite 를 DB에 맞게 지정.
 *     - DWCMSTEST(개발, VN 결산 이력)      → N'VN'
 *     - 도우제조원가시스템(운영, HQ 결산)  → N'HQ'
 *   ⚠️운영 적용 순서: 이 스크립트 먼저 → 새 jar 배포. (새 프론트가 site를 보내는데
 *     SITE 컬럼이 없으면 체크 API가 SQL 오류)
 *   멱등: SITE 컬럼이 이미 있으면 전체 스킵.
 * ========================================================================== */
SET NOCOUNT ON;

-- ※배치 분리 필수(같은 배치에서 ADD 직후 SITE 참조 시 컴파일 오류) — SSMS에서 GO 단위 실행.

IF COL_LENGTH('DOI_CLOSING_MONTH', 'SITE') IS NULL
    ALTER TABLE DOI_CLOSING_MONTH ADD SITE VARCHAR(4) NULL;
GO

-- ★DB별 백필: DWCMSTEST(개발)='VN' / 도우제조원가시스템(운영 HQ)='HQ'
UPDATE DOI_CLOSING_MONTH SET SITE = N'VN' WHERE SITE IS NULL;
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('DOI_CLOSING_MONTH') AND name='SITE' AND is_nullable=1)
BEGIN
    ALTER TABLE DOI_CLOSING_MONTH ALTER COLUMN SITE VARCHAR(4) NOT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
                 ON c.object_id=ic.object_id AND c.column_id=ic.column_id
               WHERE ic.object_id=OBJECT_ID('DOI_CLOSING_MONTH') AND c.name='SITE')
BEGIN
    ALTER TABLE DOI_CLOSING_MONTH DROP CONSTRAINT PK_DOI_CLOSING_MONTH;
    ALTER TABLE DOI_CLOSING_MONTH ADD CONSTRAINT PK_DOI_CLOSING_MONTH
        PRIMARY KEY (YYYYMM, SITE);
END
GO

SELECT YYYYMM, SITE, IS_CLOSED, CLOSED_AT, CLOSED_BY FROM DOI_CLOSING_MONTH ORDER BY YYYYMM, SITE;
