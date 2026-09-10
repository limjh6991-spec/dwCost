/* ============================================================
   DOI_STOCK 202608 — 카세트 3행의 MODEL 값 정정
   DB : 도우제조원가시스템 (10.100.40.17,14233)
   영향 행수 : 3

   [증상]
     202608 DOI_STOCK 의 카세트완제품창고 3행이 MODEL 에 품명이 들어가 있다.
       현재  MODEL='VINA N_OPPO 단면바' / '양면바' / '하단틀'   (MODEL_TYPE=VN034P3/P2/P1)
       선례  202607 은 MODEL = MODEL_TYPE = 'VN034P2' / 'VN034P3'
     (07_DOI_STOCK.sql 은 MODEL=품번으로 만들어져 있으므로, 이 3행은 그 스크립트가 아닌
      다른 경로로 들어간 것으로 보인다. 나머지 109행과 breakdown 값은 정상이다.)

   [영향 — 고치지 않으면 8월 결산이 틀어진다]
     1) UP_DOI_STOCK_COST L437/440/444 : ON a.model = d.model AND a.구분 = d.구분
        DOI_COST 의 카세트 MODEL 은 'VN034P1/P2/P3' 이므로 조인이 실패해
        카세트 3제품에 원가가 붙지 않는다.
     2) UP_DOI_STOCK_COST L533/544/554 : CASE WHEN model like 'VINA%' THEN '카세트' else 구분 end
        202607 은 MODEL='VN034P2' 라 'VINA%' 에 걸리지 않아 구분='양산' 으로 갔다
        (202607 doi_stco 실적: VN034P2/VN034P3 모두 구분='양산').
        지금 값은 'VINA N_OPPO...' 라 'VINA%' 에 걸려 구분이 '카세트' 로 바뀐다 → 전월과 분류 불일치.
     3) UP_DOI_STOCK_BOH 의 PREV_EOH MERGE 가 MODEL 로 매칭하므로
        202607 EOH_AMT 5,740,787 (VN034P2 3,320,989 + VN034P3 2,419,798) 이 8월 기초로 이월되지 않는다.

   [참고] OUT_RETURN 이 112행 전량 NULL 인 것은 무해하다.
          HQ 결산 프로시저는 OUT_RETURN 을 읽지 않는다(UP_VN_STOCK_COST 전용).

   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @n INT;

UPDATE DOI_STOCK
   SET MODEL = MODEL_TYPE
 WHERE YYYYMM = '202608' AND SITE = 'HQ' AND SEL_CODE = 'ACTUAL'
   AND STOCK = N'카세트완제품창고'
   AND MODEL <> MODEL_TYPE;
SET @n = @@ROWCOUNT;

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(1000) = N'';
DECLARE @bad INT = (SELECT COUNT(*) FROM DOI_STOCK
                     WHERE YYYYMM='202608' AND STOCK=N'카세트완제품창고' AND MODEL <> MODEL_TYPE);
DECLARE @cst INT = (SELECT COUNT(*) FROM DOI_STOCK
                     WHERE YYYYMM='202608' AND MODEL IN ('VN034P1','VN034P2','VN034P3'));
DECLARE @tot INT = (SELECT COUNT(*) FROM DOI_STOCK WHERE YYYYMM='202608');

IF @bad <> 0   BEGIN SET @ok=0; SET @msg=@msg+N'MODEL<>MODEL_TYPE 행이 남음('+CAST(@bad AS NVARCHAR(10))+N'); '; END
IF @cst <> 3   BEGIN SET @ok=0; SET @msg=@msg+N'VN034P* MODEL 3행 기대, 실제 '+CAST(@cst AS NVARCHAR(10))+N'; '; END
IF @tot <> 112 BEGIN SET @ok=0; SET @msg=@msg+N'전체 112행 기대, 실제 '+CAST(@tot AS NVARCHAR(10))+N'; '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'카세트 MODEL 정정 완료' AS 결과, @n AS 변경행수, @cst AS VN034P행수, @tot AS 전체행수;
  SELECT MODEL, MODEL_TYPE, STOCK, BOH, [INPUT], [OUT], EOH
    FROM DOI_STOCK WHERE YYYYMM='202608' AND STOCK=N'카세트완제품창고' ORDER BY MODEL;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'검증 실패 — 원상복구' AS 결과, @msg AS 사유;
END
GO


/* ============================================================
   [내일] RMA_AMT 반영 — 202601 과 동일한 방식
   8월 반품 95,257,838 을 R 모델 행의 RMA_AMT 에 기입한다.
   UP_DOI_STOCK_BOH STEP6 이 이를 읽어 doi_stco 양산행 OUTETC_AMT 로 넘긴다.
   ------------------------------------------------------------ */
BEGIN TRAN;
DECLARE @r INT = 0;
UPDATE DOI_STOCK SET RMA_AMT= 3565861 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'7073R' AND [INPUT]=71;   SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT= 1006207 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'7110R' AND [INPUT]=97;   SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT=   54984 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'8085R' AND [INPUT]=10;   SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT= 4685636 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'810PR' AND [INPUT]=58;   SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT= 5417098 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'8122R' AND [INPUT]=148;  SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT= 8189758 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'8136R' AND [INPUT]=1473; SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT=    9100 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'8140R' AND [INPUT]=2;    SET @r=@r+@@ROWCOUNT;
UPDATE DOI_STOCK SET RMA_AMT=72329194 WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND MODEL_TYPE=N'902KR' AND [INPUT]=863;  SET @r=@r+@@ROWCOUNT;

DECLARE @sum NUMERIC(20,2) = (SELECT SUM(ISNULL(RMA_AMT,0)) FROM DOI_STOCK WHERE YYYYMM='202608');
IF @r = 8 AND @sum = 95257838
BEGIN
  COMMIT;
  SELECT N'RMA_AMT 반영 완료' AS 결과, @r AS 적중행수, @sum AS RMA합계;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'RMA_AMT 검증 실패 — 원상복구' AS 결과, @r AS 적중행수, @sum AS RMA합계;
END
GO
