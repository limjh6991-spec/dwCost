/* ============================================================
   DOI_원장상계  ←  202608 엑셀 적재
   DB : 도우제조원가시스템 (10.100.40.17,14233)
   행 : 12행
   엑셀: 08월 유상사급 모델별 상계 (260910).xlsx / 시트 '8월' R3~R14 (R15 TOTAL 제외)
   구분: 원장매칭 공백 -> '회계', 그 외 -> '양산'
   ★ 원장사용량(F열)이 8월 파일은 분수값(31.625 등)이라 FLOOR 적용 (202606/202607 선례와 동일)
      음수 행도 FLOOR 방향(내림)으로 처리 — 0방향 절사(CAST)와 다름에 주의
   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @before INT = (SELECT COUNT(*) FROM [DOI_원장상계] WHERE [yyyymm]='202608' AND [site]='HQ' AND [sel_code]='ACTUAL');
DELETE FROM [DOI_원장상계] WHERE [yyyymm]='202608' AND [site]='HQ' AND [sel_code]='ACTUAL';

INSERT INTO [DOI_원장상계] ([yyyymm],[site],[sel_code],[구분],[모델],[원장매칭],[소요량],[배율],[출하기여수량],[원장사용량],[원장단가],[매출상계]) VALUES
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'7073P',N'DW00105000',0.125,8,253,31,NULL,1017175),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'7102P',N'DW00105000',0.1666,6,29,4,NULL,155457),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'7110P',N'DW00105000',0.1666,6,-140,-24,NULL,-750486),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'7130P',N'DW00105000',0.125,8,0,0,NULL,0),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'8085P',N'DW00105000',0.1666,6,6020,1003,NULL,32270883),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'8122P',N'DW00105000',0.1666,6,52,8,NULL,278751),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'8176P',N'DW00105000',0.1666,6,-8,-2,NULL,-42885),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'8136P',N'DW00112001',0.1666,6,484,80,NULL,12459450),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'902KP',N'DW00113000',0.25,4,0,0,NULL,1498483),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'818VP',N'DW001C0V02',0.1666,6,315149,52524,NULL,1798467332),
  (N'202608',N'HQ',N'ACTUAL',N'양산',N'8166P',N'DW001C2V00',0.1666,6,56134,9355,NULL,341186161),
  (N'202608',N'HQ',N'ACTUAL',N'회계',N'회계-조정',NULL,NULL,NULL,0,NULL,NULL,63481879);

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(2000) = N'';
DECLARE @after INT = (SELECT COUNT(*) FROM [DOI_원장상계] WHERE [yyyymm]='202608' AND [site]='HQ' AND [sel_code]='ACTUAL');
IF @after <> 12 BEGIN SET @ok=0; SET @msg=@msg+N'행수 12 기대, 실제 '+CAST(@after AS NVARCHAR(20))+N'; '; END
IF ABS(ISNULL((SELECT SUM(매출상계) FROM DOI_원장상계 WHERE yyyymm='202608'),0) - 2250022200) > 0 BEGIN SET @ok=0; SET @msg=@msg+N'매출상계합계 불일치(기대 2250022200, 실제 '+CAST(ISNULL((SELECT SUM(매출상계) FROM DOI_원장상계 WHERE yyyymm='202608'),0) AS NVARCHAR(40))+N'); '; END
IF ABS(ISNULL((SELECT SUM(출하기여수량) FROM DOI_원장상계 WHERE yyyymm='202608'),0) - 377973) > 0 BEGIN SET @ok=0; SET @msg=@msg+N'출하기여수량 불일치(기대 377973, 실제 '+CAST(ISNULL((SELECT SUM(출하기여수량) FROM DOI_원장상계 WHERE yyyymm='202608'),0) AS NVARCHAR(40))+N'); '; END
IF ABS(ISNULL((SELECT COUNT(*) FROM DOI_원장상계 WHERE yyyymm='202608' AND 구분=N'회계'),0) - 1) > 0 BEGIN SET @ok=0; SET @msg=@msg+N'회계구분행수 불일치(기대 1, 실제 '+CAST(ISNULL((SELECT COUNT(*) FROM DOI_원장상계 WHERE yyyymm='202608' AND 구분=N'회계'),0) AS NVARCHAR(40))+N'); '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'DOI_원장상계 적재 완료' AS 결과, @before AS 삭제전행수, @after AS 적재행수;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'DOI_원장상계 검증 실패 — 원상복구' AS 결과, @msg AS 사유;
END
GO