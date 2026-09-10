/* ============================================================================
   DOI_BOM_MAST 202608 — 엑셀에만 있던 34행만 추가 (좁은 수정)
   DB : 도우제조원가시스템 (10.100.40.17,14233)

   * API(영림원) 적재분 1,198행은 그대로 두고, 스테이징 DOI_HQ_IF_MATERIAL 응답에
     아예 없던 제품 7종(0352/0354/0380/824W/824X/824Y/824Z)의 BOM 34행만 INSERT.
   * 소요량 0.1667(291행)은 손대지 않는다 — 영림원 원본 MatQty = 1/6 =
     0.1666666666666666666 (MatQtyNum=1, MatQtyDen=6)의 numeric(15,4) 반올림값이며,
     엑셀의 0.1666 은 화면 출력 절사값이다. 또한 배부율은 자재번호 단위로 정규화되어
     상쇄되므로 202608 재료비 배부 금액 차이는 0원이다.
   * 멱등: 이미 들어가 있으면 0행 삽입.
   ============================================================================ */
SET NOCOUNT ON; SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @before INT = (SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM='202608' AND SITE='HQ');

;WITH SRC([YYYYMM],[SITE],[제품명],[제품번호],[품목자산분류],[품목대분류],[품목중분류],[품목소분류],[공정차수],[공정],[공정품명],[공정품번호],[자재명],[자재번호],[자재자산분류],[자재대분류],[자재중분류],[자재소분류],[투입단위],[소요량],[내부Loss율],[외부Loss율],[조립위치],[특이사항],[최초작성일],[최초작성자],[최종수정일],[최종수정자]) AS (
  SELECT * FROM (VALUES
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'적층',NULL,NULL,N'LJ64-07075P(CBG2,42㎛)',N'DW001C2V00',N'원자재',N'원자재',N'CORNING',N'CBG2',N'EA',0.1666,0,0,NULL,NULL,'2026-09-10',N'김용재','2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-10',N'김용재','2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'PFL',NULL,NULL,N'PF FRONT 820(QA01) 0.6V',N'DWD04820F3',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,'2026-09-10',N'김용재','2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'PFL',NULL,NULL,N'PF BACK 820(QA01) 0.6V',N'DWD04820B3',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,'2026-09-10',N'김용재','2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0352',N'0352D',N'제품',N'UTG',N'0352',N'0352D',N'00',N'이물제거',N'0352',N'0352D',N'820(QA01) TRAY 0.3V',N'DWD05820W1',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,'2026-09-10',N'김용재','2026-09-10',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'적층',NULL,NULL,N'(CBG2,50㎛)',N'DMGCBG250',N'수탁자재',N'원자재',N'SDC',N'(CBG2,50㎛)',N'EA',0.1666,0,0,NULL,NULL,'2026-09-03',N'김용재','2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-03',N'김용재','2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'PFL',NULL,NULL,N'PF FRONT 820(QA01) 0.9V',N'DWD04820F5',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,'2026-09-03',N'김용재','2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'PFL',NULL,NULL,N'PF BACK 820(QA01) 0.9V',N'DWD04820B5',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,'2026-09-03',N'김용재','2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0354',N'0354D',N'제품',N'UTG',N'0354',N'0354',N'00',N'이물제거',N'0354',N'0354D',N'820(QA01) TRAY 0.3V',N'DWD05820W1',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,'2026-09-03',N'김용재','2026-09-03',N'김용재'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'적층',NULL,NULL,N'LJ64-07273G(CBG2,50㎛)',N'DW00112001',N'원자재',N'원자재',N'SDC',N'LJ64-07273G (CBG2,50㎛)',N'EA',0.1666,0,0,NULL,NULL,'2026-09-01',N'고현성','2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-01',N'고현성','2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'PFL',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-01',N'고현성','2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'0380',N'0380D',N'제품',N'UTG',N'0380',N'0380D',N'00',N'이물제거',N'0380',N'0380D',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-01',N'고현성','2026-09-01',N'고현성'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'적층',NULL,NULL,N'S640-039776(AS96,60㎛)',N'DWD01SJS00',N'수탁자재',N'원자재',N'SCHOTT',N'AS96',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.3v',N'DWD04824B3',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.3v',N'DWD04824F3',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824W',N'824WD',N'제품',N'UTG',N'824W',N'824WD',N'00',N'이물제거',N'824W',N'824WD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'적층',NULL,NULL,N'S640-039567(AS96,50㎛)',N'DWD01SBS00',N'수탁자재',N'원자재',N'SCHOTT',N'AS96',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.2v',N'DWD04824B2',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.2v',N'DWD04824F2',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824X',N'824XD',N'제품',N'UTG',N'824X',N'824XD',N'00',N'이물제거',N'824X',N'824XD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'적층',NULL,NULL,N'LJ64-041832(AS96 55㎛)',N'DWD01SNS00',N'수탁자재',N'원자재',N'SCHOTT',N'AS96',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.1v',N'DWD04824B1',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.1v',N'DWD04824F1',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Y',N'824YD',N'제품',N'UTG',N'824Y',N'824YD',N'00',N'이물제거',N'824Y',N'824YD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'적층',NULL,NULL,N'S640-041799(XF4, 65㎛)',N'DWD01CCP00',N'수탁자재',N'원자재',N'SCHOTT',N'XF4',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'박리',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'PFL',NULL,NULL,N'PF BACK_824(TW01) 0.0v',N'DWD04824B0',N'원자재',N'부자재',N'필름',N'배면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'PFL',NULL,NULL,N'PF FRONT_824(TW01) 0.0v',N'DWD04824F0',N'원자재',N'부자재',N'필름',N'전면',N'EA',1,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람'),
  (N'202608',N'HQ',N'824Z',N'824ZD',N'제품',N'UTG',N'824Z',N'824ZD',N'00',N'이물제거',N'824Z',N'824ZD',N'824(TW01) 6구 Tray 0.0v',N'DWD05824W0',N'부자재',N'부자재',N'트레이',N'6구',N'EA',0.1666,0,0,NULL,NULL,'2026-09-08',N'이규람','2026-09-08',N'이규람')
  ) V([YYYYMM],[SITE],[제품명],[제품번호],[품목자산분류],[품목대분류],[품목중분류],[품목소분류],[공정차수],[공정],[공정품명],[공정품번호],[자재명],[자재번호],[자재자산분류],[자재대분류],[자재중분류],[자재소분류],[투입단위],[소요량],[내부Loss율],[외부Loss율],[조립위치],[특이사항],[최초작성일],[최초작성자],[최종수정일],[최종수정자])
)
INSERT INTO DOI_BOM_MAST
 ([YYYYMM],[SITE],[제품명],[제품번호],[품목자산분류],[품목대분류],[품목중분류],[품목소분류],[공정차수],[공정],[공정품명],[공정품번호],[자재명],[자재번호],[자재자산분류],[자재대분류],[자재중분류],[자재소분류],[투입단위],[소요량],[내부Loss율],[외부Loss율],[조립위치],[특이사항],[최초작성일],[최초작성자],[최종수정일],[최종수정자])
SELECT s.* FROM SRC s
WHERE NOT EXISTS (
  SELECT 1 FROM DOI_BOM_MAST d
   WHERE d.YYYYMM=s.YYYYMM AND d.SITE=s.SITE AND d.제품명=s.제품명 AND d.제품번호=s.제품번호
     AND d.공정차수=s.공정차수 AND d.공정=s.공정
     AND ISNULL(d.자재번호,N'')=ISNULL(s.자재번호,N''));

DECLARE @ins INT = @@ROWCOUNT;
DECLARE @after INT = (SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM='202608' AND SITE='HQ');

IF @after = 1232
BEGIN
    COMMIT;
    SELECT @before AS 실행전, @ins AS 삽입행, @after AS 실행후, N'OK (1232행)' AS 결과;
END
ELSE
BEGIN
    ROLLBACK;
    SELECT @before AS 실행전, @ins AS 삽입행, @after AS 실행후, N'ROLLBACK: 최종 1232행이 아님' AS 결과;
END
