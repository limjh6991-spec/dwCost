/* ============================================================
   doi_invoice_resc  ←  202608 엑셀 적재
   DB : 도우제조원가시스템 (10.100.40.17,14233)
   행 : 7행
   엑셀: 08월 매출품목 정보(260910).xlsx / 시트 '수출신고필증' R4~R10 (R3 TOTAL 제외)
   엑셀 앞 34개 컬럼 -> DB 선택~특이사항 (35열 이후는 DB 컬럼 없음)
   * API 적재분은 금액/수량이 일치했으나 Invoice_No와 Invoice관리번호가 서로 뒤바뀌어 있었고
     판매단가 0, 매출금액계 전량 NULL 이었음
   * 화면 업로드(C0007005_InsertExcel2)는 Invoice관리번호로 중복을 거르는데 DB/엑셀 값이
     서로 달라 그대로 올리면 7행이 추가되어 수출매출이 2배가 됨 -> 반드시 이 스크립트로 교체
   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @before INT = (SELECT COUNT(*) FROM [doi_invoice_resc] WHERE [yyyymm]='202608' AND [site]='HQ' AND [sel_code]='ACTUAL');
DELETE FROM [doi_invoice_resc] WHERE [yyyymm]='202608' AND [site]='HQ' AND [sel_code]='ACTUAL';

INSERT INTO [doi_invoice_resc] ([yyyymm],[sel_code],[site],[선택],[출고처리],[사업단위],[Invoice_No],[Invoice관리번호],[Invoice_Date],[수출구분],[출고구분],[가격조건],[부서],[담당자],[Buyer],[Agent],[통화],[환율],[품명],[품번],[규격],[단위],[판매기준가],[판매단가],[수량],[판매금액],[원화판매금액],[창고],[납기일],[기타출고구분],[진행상태],[매출진행상태],[매출대상],[매출금액계],[미매출금액],[Remarks],[특이사항]) VALUES
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWV-260820-001',N'202608200001',N'2026-08-20',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'도우VINA',NULL,N'KRW',1,N'VINA N_OPPO 단면바',N'VN034P3',NULL,N'EA',0,104558.64,360,37641112,37641112,N'카세트완제품창고',NULL,NULL,N'완료',N'완료',0,37641112,0,N'0',NULL),
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWV-260820-001',N'202608200001',N'2026-08-20',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'도우VINA',NULL,N'KRW',1,N'VINA N_OPPO 양면바',N'VN034P2',NULL,N'EA',0,193921.05,360,69811577,69811577,N'카세트완제품창고',NULL,NULL,N'완료',N'완료',0,69811577,0,N'0',NULL),
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWV-260820-001',N'202608200001',N'2026-08-20',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'도우VINA',NULL,N'KRW',1,N'VINA N_OPPO 하단틀',N'VN034P1',NULL,N'EA',0,93700.61,342,32045610,32045610,N'카세트완제품창고',NULL,NULL,N'완료',N'완료',0,32045610,0,N'0',NULL),
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWE-260821-005',N'202609070001',N'2026-08-21',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'SAMSUNG DISPLAY VIETNAM',NULL,N'USD',1393,N'8195',N'8195D',NULL,N'Cell',0,49.98,2500,124950,174055350,N'완제품 창고',NULL,NULL,N'완료',N'완료',0,124950,0,N'0',NULL),
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWE-260824-001',N'202608240001',N'2026-08-24',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'SAMSUNG DISPLAY VIETNAM',NULL,N'USD',1383.6,N'8195',N'8195D',NULL,N'Cell',0,49.98,3600,179928,248948380,N'완제품 창고',NULL,NULL,N'완료',N'완료',0,179928,0,N'0',NULL),
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWE-260827-005',N'202608270001',N'2026-08-27',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'SAMSUNG DISPLAY VIETNAM',NULL,N'USD',1384.6,N'8195',N'8195D',NULL,N'Cell',0,49.98,5085,254148.3,351893736,N'완제품 창고',NULL,NULL,N'완료',N'완료',0,254148.3,0,N'0',NULL),
  (N'202608',N'ACTUAL',N'HQ',0,1,N'본사',N'DWE-260828-002',N'202608280001',N'2026-08-28',N'일반수출',N'정상판매',N'FOB',N'영업그룹',N'한주환',N'SAMSUNG DISPLAY VIETNAM',NULL,N'USD',1380.3,N'8209',N'8209D',NULL,N'Cell',0,50.21,1867,93742.07,129392179,N'완제품 창고',NULL,NULL,N'완료',N'완료',0,93742.07,0,N'0',NULL);

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(2000) = N'';
DECLARE @after INT = (SELECT COUNT(*) FROM [doi_invoice_resc] WHERE [yyyymm]='202608' AND [site]='HQ' AND [sel_code]='ACTUAL');
IF @after <> 7 BEGIN SET @ok=0; SET @msg=@msg+N'행수 7 기대, 실제 '+CAST(@after AS NVARCHAR(20))+N'; '; END
IF ABS(ISNULL((SELECT SUM(수량) FROM doi_invoice_resc WHERE yyyymm='202608'),0) - 14114) > 0 BEGIN SET @ok=0; SET @msg=@msg+N'수량합계 불일치(기대 14114, 실제 '+CAST(ISNULL((SELECT SUM(수량) FROM doi_invoice_resc WHERE yyyymm='202608'),0) AS NVARCHAR(40))+N'); '; END
IF ABS(ISNULL((SELECT SUM(원화판매금액) FROM doi_invoice_resc WHERE yyyymm='202608'),0) - 1043787944) > 1 BEGIN SET @ok=0; SET @msg=@msg+N'원화판매금액 불일치(기대 1043787944, 실제 '+CAST(ISNULL((SELECT SUM(원화판매금액) FROM doi_invoice_resc WHERE yyyymm='202608'),0) AS NVARCHAR(40))+N'); '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'doi_invoice_resc 적재 완료' AS 결과, @before AS 삭제전행수, @after AS 적재행수;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'doi_invoice_resc 검증 실패 — 원상복구' AS 결과, @msg AS 사유;
END
GO