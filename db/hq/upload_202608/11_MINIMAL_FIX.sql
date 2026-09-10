/* ============================================================
   202608 최소 수정 — 전체 재적재 없이 고칠 수 있는 항목
   DB : 도우제조원가시스템 (10.100.40.17,14233)

   [필수 1] DOI_MATL_RESC.중분류  278행 UPDATE
   [필수 2] DOI_BOM_MAST          누락 34행 INSERT
   [선택 3] DOI_DEPT              불필요 코드 1행 DELETE
   [선택 4] doi_sale_resc         화면 표시용 컬럼 정정
   [선택 5] doi_invoice_resc      화면 표시용 컬럼 정정

   ※ DOI_DEPT_COST 와 DOI_STOCK 은 이 방식으로 고칠 수 없다.
      DOI_DEPT_COST : 코스트센터 귀속 자체가 달라 162키 추가/80키 삭제가 필요 -> 02번 실행
      DOI_STOCK     : breakdown 21컬럼이 107행 전량 NULL + 5행 누락 -> 07번 실행
      DOI_PROD_SUBUL / DOI_원장상계 / DOI_VNCST_RATE 는 원래 0행 -> 06 / 03 / 10번 실행
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

/* ------------------------------------------------------------
   [필수 1] DOI_MATL_RESC.중분류
   API 적재분은 278행 전량 NULL. 원인은 스테이징 INSERT 컬럼명 오타
   (UMItmeClassMName, 정상은 UMItemClassMName) 로 값이 컬럼에 안 들어간 것.
   다만 RAW_JSON 에는 $.UMItemClassMName 이 278/278 살아 있고,
   그 값이 8월 엑셀의 중분류와 278건 전부 일치함을 확인했다(불일치 0).

   중분류는 UP_DOI_MAT_AMT 의 원가자재분류 파생 입력이라 NULL 이면
     WHEN 중분류=N'약액' THEN N'약액' / WHEN 중분류=N'필름' THEN N'필름'
     WHEN 중분류 IN (N'SDC',N'제조기술',N'공정개발') THEN N'원장'
   이 전부 걸리지 않는다. (8월 해당 건수: 필름 81 / 약액 11 / 원장 17)
   ------------------------------------------------------------ */
UPDATE m
   SET m.중분류 = JSON_VALUE(s.RAW_JSON, '$.UMItemClassMName')
  FROM DOI_MATL_RESC m
  JOIN DOI_HQ_IF_STOCK_DETAIL s
    ON s.SITE = N'HQ' AND s.ItemNo = m.품번
 WHERE m.YYYYMM = '202608' AND m.SITE = 'HQ' AND m.SEL_CODE = 'ACTUAL';

/* ------------------------------------------------------------
   [필수 2] DOI_BOM_MAST 누락 34행
   API 적재분에 없고 엑셀에만 있는 행. 제품: 0352D, 0354D, 0380D, 824WD, 824XD, 824YD, 824ZD
   이 중 0380D, 824WD, 824XD, 824YD, 824ZD 는 8월 생산수불에 실적이 있어, BOM 이 없으면 재료비 배부에서 빠진다.
   (0352D / 0354D 는 8월 생산·매출·자재수불이 모두 0이라 무해하나 함께 넣는다)

   ※ 소요량 0.1667 은 고치지 말 것.
     영림원 원본이 0.1666666666666666666 이라 numeric(15,4) 반올림값 0.1667 이 정확하고,
     엑셀의 0.1666 이 화면 절사값이다. 게다가 UP_DOI_MAT_COST 의 배부율은
     자재번호별 정규화(환산량*소요량 / SUM(...) OVER(PARTITION BY 자재번호))이고
     두 값이 섞인 자재번호가 0개라 금액 영향도 정확히 0이다.
   ------------------------------------------------------------ */
INSERT INTO [DOI_BOM_MAST] ([YYYYMM],[SITE],[제품명],[제품번호],[품목자산분류],[품목대분류],[품목중분류],[품목소분류],[공정차수],[공정],[공정품명],[공정품번호],[자재명],[자재번호],[자재자산분류],[자재대분류],[자재중분류],[자재소분류],[투입단위],[소요량],[내부Loss율],[외부Loss율],[조립위치],[특이사항],[최초작성일],[최초작성자],[최종수정일],[최종수정자]) VALUES
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'적층',NULL,NULL,N'LJ64-07075P(CBG2,42㎛)',N'DW001C2V00',N'원자재',N'원자재',N'CORNING',N'CBG2',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-10',N'김용재',N'2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-10',N'김용재',N'2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'PFL',NULL,NULL,N'PF FRONT 820(QA01) 0.6V',N'DWD04820F3',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,N'2026-09-10',N'김용재',N'2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'PFL',NULL,NULL,N'PF BACK 820(QA01) 0.6V',N'DWD04820B3',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,N'2026-09-10',N'김용재',N'2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'이물제거',N'0352',N'0352D',N'820(QA01) TRAY 0.3V',N'DWD05820W1',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-10',N'김용재',N'2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'적층',NULL,NULL,N'(CBG2,50㎛)',N'DMGCBG250',N'수탁자재',N'원자재',N'SDC',N'(CBG2,50㎛)',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-03',N'김용재',N'2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-03',N'김용재',N'2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'PFL',NULL,NULL,N'PF FRONT 820(QA01) 0.9V',N'DWD04820F5',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,N'2026-09-03',N'김용재',N'2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'PFL',NULL,NULL,N'PF BACK 820(QA01) 0.9V',N'DWD04820B5',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,N'2026-09-03',N'김용재',N'2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'이물제거',N'0354',N'0354D',N'820(QA01) TRAY 0.3V',N'DWD05820W1',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-03',N'김용재',N'2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'적층',NULL,NULL,N'LJ64-07273G(CBG2,50㎛)',N'DW00112001',N'원자재',N'원자재',N'SDC',N'LJ64-07273G (CBG2,50㎛)',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-01',N'고현성',N'2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-01',N'고현성',N'2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'PFL',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-01',N'고현성',N'2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'이물제거',N'0380',N'0380D',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-01',N'고현성',N'2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'적층',NULL,NULL,N'S640-039776(AS96,60㎛)',N'DWD01SJS00',N'수탁자재',N'원자재',N'SCHOTT',N'AS96',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.3v',N'DWD04824B3',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.3v',N'DWD04824F3',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'이물제거',N'824W',N'824WD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'적층',NULL,NULL,N'S640-039567(AS96,50㎛)',N'DWD01SBS00',N'수탁자재',N'원자재',N'SCHOTT',N'AS96',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.2v',N'DWD04824B2',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.2v',N'DWD04824F2',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'이물제거',N'824X',N'824XD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'적층',NULL,NULL,N'LJ64-041832(AS96 55㎛)',N'DWD01SNS00',N'수탁자재',N'원자재',N'SCHOTT',N'AS96',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.1v',N'DWD04824B1',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.1v',N'DWD04824F1',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'이물제거',N'824Y',N'824YD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'적층',NULL,NULL,N'S640-041799(XF4, 65㎛)',N'DWD01CCP00',N'수탁자재',N'원자재',N'SCHOTT',N'XF4',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.0v',N'DWD04824B0',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.0v',N'DWD04824F0',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'이물제거',N'824Z',N'824ZD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,N'2026-09-08',N'이규람',N'2026-09-08',N'이규람');

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(2000) = N'';
DECLARE @mid INT = (SELECT COUNT(*) FROM DOI_MATL_RESC WHERE YYYYMM='202608' AND ISNULL(중분류,'')<>'');
DECLARE @bom INT = (SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM='202608');
DECLARE @vc  INT = (SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM='202608' AND 품목중분류=N'VINA CST');
IF @mid <> 278 BEGIN SET @ok=0; SET @msg=@msg+N'중분류 채워진 행 278 기대, 실제 '+CAST(@mid AS NVARCHAR(20))+N'; '; END
IF @bom <> 1232 BEGIN SET @ok=0; SET @msg=@msg+N'DOI_BOM_MAST 1232행 기대, 실제 '+CAST(@bom AS NVARCHAR(20))+N'; '; END
IF @vc <> 40 BEGIN SET @ok=0; SET @msg=@msg+N'VINA CST 40행 기대, 실제 '+CAST(@vc AS NVARCHAR(20))+N'; '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'최소 수정 완료' AS 결과, @mid AS 중분류채움, @bom AS BOM행수, @vc AS VINACST행수;
  SELECT 원가자재분류 = CASE WHEN 중분류=N'약액' THEN N'약액' WHEN 중분류=N'필름' THEN N'필름'
                             WHEN 중분류 IN (N'SDC',N'제조기술',N'공정개발') THEN N'원장' ELSE N'기타' END,
         COUNT(*) AS 행수, SUM(투입금액) AS 투입금액
    FROM DOI_MATL_RESC WHERE YYYYMM='202608' GROUP BY CASE WHEN 중분류=N'약액' THEN N'약액'
         WHEN 중분류=N'필름' THEN N'필름' WHEN 중분류 IN (N'SDC',N'제조기술',N'공정개발') THEN N'원장' ELSE N'기타' END;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'최소 수정 검증 실패 — 원상복구' AS 결과, @msg AS 사유;
END
GO


/* ============================================================
   [선택 3] DOI_DEPT — API 적재분에만 있는 DEPT=472 (설비개발)
   202608 DOI_DEPT_COST / doi_acct_expen 어디에도 쓰이지 않고,
   엑셀에만 있는 코드는 0개, 공통 83건은 이름·구분까지 완전일치다.
   즉 그대로 둬도 결산에 영향이 없다. 엑셀과 똑같이 맞추고 싶을 때만 실행.
   ------------------------------------------------------------
DELETE FROM DOI_DEPT WHERE YYYYMM='202608' AND SEL_CODE='ACTUAL' AND SITE='HQ' AND DEPT='472';
   ============================================================ */

/* ============================================================
   [선택 4] doi_sale_resc — 화면 표시용
   UP_DOI_SALE_COST 와 리포트(DOI_TotalCost_Tree / DOI_PL_ByModel)가 쓰는 컬럼은
   품번·품명·Local구분·판매단위·거래처·수량·원화판매금액 뿐이고 전부 엑셀과 일치한다.
   아래 컬럼은 결산에 쓰이지 않으므로 화면을 맞추려는 경우에만 실행.
   ------------------------------------------------------------
UPDATE doi_sale_resc
   SET 판매기준가 = 판매단가, 판매단가 = 판매기준가
 WHERE YYYYMM='202608' AND SITE='HQ' AND SEL_CODE='ACTUAL';
UPDATE doi_sale_resc
   SET 매출금액계 = 판매금액 + 부가세액, 세금계산서금액계 = 판매금액 + 부가세액
 WHERE YYYYMM='202608' AND SITE='HQ' AND SEL_CODE='ACTUAL' AND 매출금액계 IS NULL;
   ============================================================ */

/* ============================================================
   [선택 5] doi_invoice_resc — 화면 표시용
   결산이 쓰는 컬럼(품번·품명·수출구분·단위·Buyer·수량·원화판매금액)은 모두 일치한다.
   아래는 Invoice_No / Invoice관리번호 전치와 판매단가·매출금액계 결손 정정.
   ------------------------------------------------------------
UPDATE doi_invoice_resc
   SET Invoice_No = Invoice관리번호, Invoice관리번호 = Invoice_No
 WHERE yyyymm='202608' AND site='HQ' AND sel_code='ACTUAL';
UPDATE doi_invoice_resc
   SET 판매단가 = CASE WHEN 수량 <> 0 THEN 판매금액 / 수량 ELSE 0 END,
       매출금액계 = 판매금액
 WHERE yyyymm='202608' AND site='HQ' AND sel_code='ACTUAL';
   ============================================================ */