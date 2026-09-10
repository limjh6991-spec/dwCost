/* ============================================================
   DOI_PROD_SUBUL 202608 — SEL_CODE 오타 정정  ★결산 전 필수
   DB : 도우제조원가시스템 (10.100.40.17,14233)
   영향 행수 : 59

   [증상]
     202608 DOI_PROD_SUBUL 59행의 SEL_CODE 가 'ACUTAL' (ACTUAL 오타) 이다.
     202602~202607 은 전부 'ACTUAL'.
     원천인 8월 생산수불 파일(재고수불부/재고금액 시트, 08월 생산수불 CSV)의
     SEL_CODE 열이 'ACUTAL' 로 되어 있어 그대로 적재됐다.

   [영향 — 고치지 않으면 8월 결산이 통째로 틀어진다]
     결산 프로시저가 DOI_PROD_SUBUL 을 SEL_CODE = @SEL_CODE('ACTUAL') 로 거른다.
     참조 프로시저: UP_DOI_EXPEN_MATL / UP_DOI_MAT_COST / UP_DOI_COST /
                    UP_DOI_COST_MAT / UP_DOI_SCOF
     생산수불이 0행으로 읽히면 환산량·배부물량이 전부 0 이 되어
     제조경비·노무비 배부와 재공 원가 계산이 성립하지 않는다.

   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @n INT;
UPDATE DOI_PROD_SUBUL
   SET SEL_CODE = 'ACTUAL'
 WHERE YYYYMM = '202608' AND SITE = 'HQ' AND SEL_CODE = 'ACUTAL';
SET @n = @@ROWCOUNT;

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(1000) = N'';
DECLARE @bad INT = (SELECT COUNT(*) FROM DOI_PROD_SUBUL WHERE YYYYMM='202608' AND SEL_CODE <> 'ACTUAL');
DECLARE @tot INT = (SELECT COUNT(*) FROM DOI_PROD_SUBUL WHERE YYYYMM='202608' AND SITE='HQ' AND SEL_CODE='ACTUAL');
DECLARE @in  INT = (SELECT SUM(IN_MONTH) FROM DOI_PROD_SUBUL WHERE YYYYMM='202608' AND SITE='HQ' AND SEL_CODE='ACTUAL');

IF @n   <> 59 BEGIN SET @ok=0; SET @msg=@msg+N'UPDATE 59행 기대, 실제 '+CAST(@n AS NVARCHAR(10))+N'; '; END
IF @bad <> 0  BEGIN SET @ok=0; SET @msg=@msg+N'ACTUAL 아닌 행이 '+CAST(@bad AS NVARCHAR(10))+N'행 남음; '; END
IF @tot <> 59 BEGIN SET @ok=0; SET @msg=@msg+N'ACTUAL 59행 기대, 실제 '+CAST(@tot AS NVARCHAR(10))+N'; '; END
IF @in  <> 387490 BEGIN SET @ok=0; SET @msg=@msg+N'IN_MONTH 합 387,490 기대, 실제 '+CAST(@in AS NVARCHAR(20))+N'; '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'SEL_CODE 정정 완료' AS 결과, @n AS 변경행수, @tot AS ACTUAL행수, @in AS 입고합계;
  SELECT SEL_CODE, COUNT(*) AS 행수 FROM DOI_PROD_SUBUL WHERE YYYYMM='202608' GROUP BY SEL_CODE;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'검증 실패 - 원상복구' AS 결과, @msg AS 사유;
END
GO
