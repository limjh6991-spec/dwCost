/* ============================================================
   DOI_VNCST_RATE  <-  202608 카세트 제품별 2차 배부비율
   DB : 도우제조원가시스템 (10.100.40.17,14233)
   행 : 3행

   원천: 08월 카세트팀 원가 배부(260910).xlsx / 시트 '카세트팀 비용 배부기준'
         우측 2차 표 (K30:M34) — 실적시간 기준
           VINA N_OPPO 단면바   42,300  0.066
           VINA N_OPPO 양면바  423,000  0.6601
           VINA N_OPPO 하단틀  175,500  0.2739
           합계               640,800  1
         ※ 시트 라벨 "EX) 카세트팀 11월 월보 기준"은 오타이며 8월 실적시간임(사용자 확인).
           좌측 1차 표(UTG 2,595,920 / VINA 640,800 = 0.802022 / 0.197978)가 이미
           DOI_CST_RATE 202608 에 0.8020 / 0.1980 으로 적재되어 있는 것이 그 방증.

   CST_NO <-> 제품명 매핑 (DOI_BOM_MAST / DOI_MATL_RESC / doi_invoice_resc 3중 일치):
     VN034P1 = VINA N_OPPO 하단틀
     VN034P2 = VINA N_OPPO 양면바
     VN034P3 = VINA N_OPPO 단면바

   RATE  : numeric(15,4). 소비처가 SUM 없이 행별로 곱하므로 3행 합이 정확히 1.0000 이어야 함.
           0.0660 + 0.6601 + 0.2739 = 1.0000
   수량  : 어떤 프로시저에서도 사용하지 않는 참고 컬럼(전 저장소 grep 결과 사용처 0건).
           202607 선례(VN034P2=50, VN034P3=100)가 DOI_STOCK 당월 입고수량과 일치하므로
           같은 기준으로 08월 창고수불 카세트완제품창고 입고수량을 넣는다.
             VN034P1 350 / VN034P2 310 / VN034P3 260

   소비처: UP_DOI_EXPEN_MATL STEP 7 (L479~527)
           sub_raw: SUM(a.Target_Total * d.rate)
           LEFT JOIN doi_vncst_rate d ON (yyyymm, site) — CST_NO 조건이 없어 제품 수만큼 fan-out
           => 이 테이블이 비어 있으면 d.rate 가 NULL 이 되어 카세트 배부액이 NULL 로 들어간다.
              202608 결산 전에 반드시 적재할 것.

   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

/* ---------- 선행 조건 확인 : DOI_CST_RATE 202608 ---------- */
IF NOT EXISTS (SELECT 1 FROM DOI_CST_RATE WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ')
BEGIN
    SELECT N'중단 — DOI_CST_RATE 202608 이 없습니다. 1차 배부비율(UTG 0.8020 / VINA_CST 0.1980)을 먼저 적재하세요.' AS 결과;
    RETURN;
END

BEGIN TRAN;

DECLARE @before INT = (SELECT COUNT(*) FROM [DOI_VNCST_RATE] WHERE [YYYYMM]='202608');
DELETE FROM [DOI_VNCST_RATE] WHERE [YYYYMM]='202608';

INSERT INTO [DOI_VNCST_RATE] ([YYYYMM],[SEL_CODE],[SITE],[CST_NO],[RATE],[수량]) VALUES
  (N'202608',N'ACTUAL',N'HQ',N'VN034P1',0.2739,350),   -- VINA N_OPPO 하단틀  175,500 / 640,800
  (N'202608',N'ACTUAL',N'HQ',N'VN034P2',0.6601,310),   -- VINA N_OPPO 양면바  423,000 / 640,800
  (N'202608',N'ACTUAL',N'HQ',N'VN034P3',0.0660,260);   -- VINA N_OPPO 단면바   42,300 / 640,800

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(2000) = N'';
DECLARE @after INT = (SELECT COUNT(*) FROM [DOI_VNCST_RATE] WHERE [YYYYMM]='202608');
DECLARE @sum NUMERIC(15,4) = (SELECT SUM(RATE) FROM [DOI_VNCST_RATE] WHERE [YYYYMM]='202608');

IF @after <> 3
    BEGIN SET @ok=0; SET @msg=@msg+N'행수 3 기대, 실제 '+CAST(@after AS NVARCHAR(20))+N'; '; END
IF @sum <> 1.0000
    BEGIN SET @ok=0; SET @msg=@msg+N'RATE 합계가 1.0000 이 아님(실제 '+CAST(@sum AS NVARCHAR(20))+N'); '; END
IF EXISTS (SELECT 1 FROM [DOI_VNCST_RATE] r WHERE r.YYYYMM='202608'
           AND NOT EXISTS (SELECT 1 FROM DOI_BOM_MAST b
                           WHERE b.YYYYMM='202608' AND b.제품번호 = r.CST_NO))
    BEGIN SET @ok=0; SET @msg=@msg+N'DOI_BOM_MAST 202608 에 없는 CST_NO 가 있음(BOM 적재 여부 확인); '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'DOI_VNCST_RATE 적재 완료' AS 결과, @before AS 삭제전행수, @after AS 적재행수, @sum AS RATE합계;
  SELECT r.CST_NO, r.RATE, r.수량, b.제품명
  FROM DOI_VNCST_RATE r
  LEFT JOIN (SELECT DISTINCT 제품번호, 제품명 FROM DOI_BOM_MAST WHERE YYYYMM='202608') b ON b.제품번호 = r.CST_NO
  WHERE r.YYYYMM='202608' ORDER BY r.CST_NO;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'DOI_VNCST_RATE 검증 실패 — 원상복구' AS 결과, @msg AS 사유;
END
GO
