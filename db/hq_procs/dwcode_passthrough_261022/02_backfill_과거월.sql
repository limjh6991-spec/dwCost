/* ============================================================
   Phase 2 — 과거월(1~9월, 마감분) 도우코드 백필  (운영, SSMS 수동)
   - UP_DOI_FILL_DWCODE 를 월별 1회 실행(= 도우코드 컬럼만 UPDATE, 결산 수치 불변).
   - 마감월도 안전(재결산 아님). 10월~ 는 결산 체인에서 자동 호출(03 참조) 하므로 백필 불필요.
   - 선행: 01_alter(도우코드 컬럼 ADD) + UP_DOI_FILL_DWCODE.sql(프로시저 생성).
   ============================================================ */
USE [도우제조원가시스템];
GO
DECLARE @ym varchar(6), @y int = 2026, @m int = 1;
WHILE @m <= 9   -- 결산 완료된 1~9월
BEGIN
    SET @ym = CAST(@y AS varchar(4)) + RIGHT('0'+CAST(@m AS varchar(2)),2);
    EXEC dbo.UP_DOI_FILL_DWCODE @YYYYMM=@ym, @SITE='HQ', @SEL_CODE='ACTUAL';
    PRINT @ym + ' 도우코드 백필 완료';
    SET @m += 1;
END
GO

/* ---------- 검증: 채움률 + (원가값 불변은 도우코드만 UPDATE라 구조적 보장) ---------- */
SELECT 'DOI_COST' t, YYYYMM, COUNT(*) 행, SUM(CASE WHEN 도우코드 IS NOT NULL AND 도우코드<>'' THEN 1 ELSE 0 END) 채움
FROM dbo.DOI_COST WHERE YYYYMM LIKE '2026%' AND SITE='HQ' GROUP BY YYYYMM
UNION ALL SELECT 'DOI_STCO', YYYYMM, COUNT(*), SUM(CASE WHEN 도우코드 IS NOT NULL AND 도우코드<>'' THEN 1 ELSE 0 END)
FROM dbo.DOI_STCO WHERE YYYYMM LIKE '2026%' AND SITE='HQ' GROUP BY YYYYMM
UNION ALL SELECT 'DOI_SLCO', YYYYMM, COUNT(*), SUM(CASE WHEN 도우코드 IS NOT NULL AND 도우코드<>'' THEN 1 ELSE 0 END)
FROM dbo.DOI_SLCO WHERE YYYYMM LIKE '2026%' AND SITE='HQ' GROUP BY YYYYMM
UNION ALL SELECT 'DOI_SMCE_COST', YYYYMM, COUNT(*), SUM(CASE WHEN 도우코드 IS NOT NULL AND 도우코드<>'' THEN 1 ELSE 0 END)
FROM dbo.DOI_SMCE_COST WHERE YYYYMM LIKE '2026%' AND SITE='HQ' GROUP BY YYYYMM
ORDER BY t, YYYYMM;
GO
/* 미채움(카세트재료비/EXTRA/전량LOSS·생산이력 없는 모델)은 '' → 리포트 COALESCE(NULLIF(도우코드,''),도우모델) 폴백 */
