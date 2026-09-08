/* =====================================================================
 * [VN 인터페이스] 품목 → 면적기준정보(DOI_MODEL_MAST) 자동 반영
 *   ① 스테이징 컬럼 추가: DOI_VN_IF_ITEM.IDX_NO(조인키), DOI_VN_IF_ITEM_CMF.AddInfoName(장변/단변 값)
 *   ② 로더 UP_VN_IF_LOAD_ITEM: IDX_NO 적재 + DataBlock4(장변/단변) 적재 + @@ROWCOUNT 정상화
 *   ③ 변환 UP_VN_IF_XFORM_ITEM: 장변×단변 → DOI_MODEL_MAST (누락 INSERT / XY=0 행 채움, 기존값 보존)
 *   실행: DWCMSTEST (SSMS). 실행 후 [품목 API 호출] → 적재→변환 자동. (jar에 xform 배선 포함)
 * ===================================================================== */
IF OBJECT_ID(N'DOI_VN_IF_ITEM_CMF', N'U') IS NULL
CREATE TABLE DOI_VN_IF_ITEM_CMF (
    SITE NVARCHAR(4) NOT NULL DEFAULT N'VN', LOAD_DTTM DATETIME NOT NULL DEFAULT GETDATE(),
    RowIDX INT NULL, ColIDX INT NULL, AddInfoName NVARCHAR(100) NULL, RAW_JSON NVARCHAR(MAX) NULL);
IF COL_LENGTH('DOI_VN_IF_ITEM','IDX_NO') IS NULL          ALTER TABLE DOI_VN_IF_ITEM     ADD IDX_NO INT NULL;
IF COL_LENGTH('DOI_VN_IF_ITEM_CMF','AddInfoName') IS NULL ALTER TABLE DOI_VN_IF_ITEM_CMF ADD AddInfoName NVARCHAR(100) NULL;
GO
CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ITEM @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ITEM WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_ITEM (SITE, LOAD_DTTM, REQUEST_ID, IDX_NO, ItemSeq, ItemName, ItemNo, Spec, TrunName, AssetName, AssetSeq, UnitName, UnitSeq, SMABC, SMABCName, SMStatus, SMStatusName, SMInOutKind, SMInOutKindName, DeptName, DeptSeq, EmpName, EmpSeq, STDItemName, STDItemSeq, ItemEngName, ItemClassLName, ItemClassMName, ItemClassSName, UMItemClass, RegUser, LastUser, RegDate, LastDate, IsSTDItem, IsOption, IsSet, IsQC, SMOutKindName, IsBOMReg, IsProcReg, IsProcMat, SMLimitTermKindName, SMLimitTermKind, IsLotMng, IsSerialMng, SMAssetGrp, PurCustName, TrustCustName, Remark, SMVatKindName, PriceInVat, IsFileCheck, IsImangeCheck, StdItemNo, STDItemSpec, MKCustName, IsPrice, URL, SMPurKind, PurKind, UMProperty, UMPropertyName, RowIDX, ColIDX, AddInfoName, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.IDX_NO, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.TrunName, j.AssetName, j.AssetSeq, j.UnitName, j.UnitSeq, j.SMABC, j.SMABCName, j.SMStatus, j.SMStatusName, j.SMInOutKind, j.SMInOutKindName, j.DeptName, j.DeptSeq, j.EmpName, j.EmpSeq, j.STDItemName, j.STDItemSeq, j.ItemEngName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.UMItemClass, j.RegUser, j.LastUser, j.RegDate, j.LastDate, j.IsSTDItem, j.IsOption, j.IsSet, j.IsQC, j.SMOutKindName, j.IsBOMReg, j.IsProcReg, j.IsProcMat, j.SMLimitTermKindName, j.SMLimitTermKind, j.IsLotMng, j.IsSerialMng, j.SMAssetGrp, j.PurCustName, j.TrustCustName, j.Remark, j.SMVatKindName, j.PriceInVat, j.IsFileCheck, j.IsImangeCheck, j.StdItemNo, j.STDItemSpec, j.MKCustName, j.IsPrice, j.URL, j.SMPurKind, j.PurKind, j.UMProperty, j.UMPropertyName, j.RowIDX, j.ColIDX, j.AddInfoName, j.[RAW_JSON]
  -- 품목 응답 메인행은 DataBlock3 (부가정의 장변/단변=DataBlock2, 부가값=DataBlock4). DataBlock1로는 0건이던 버그
  FROM OPENJSON(@json, '$.DataBlock3')
  WITH (
    IDX_NO INT '$."IDX_NO"',
    ItemSeq INT '$."ItemSeq"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemNo NVARCHAR(100) '$."ItemNo"',
    Spec NVARCHAR(100) '$."Spec"',
    TrunName NVARCHAR(100) '$."TrunName"',
    AssetName NVARCHAR(100) '$."AssetName"',
    AssetSeq INT '$."AssetSeq"',
    UnitName NVARCHAR(100) '$."UnitName"',
    UnitSeq INT '$."UnitSeq"',
    SMABC INT '$."SMABC"',
    SMABCName NVARCHAR(100) '$."SMABCName"',
    SMStatus INT '$."SMStatus"',
    SMStatusName NVARCHAR(100) '$."SMStatusName"',
    SMInOutKind INT '$."SMInOutKind"',
    SMInOutKindName NVARCHAR(100) '$."SMInOutKindName"',
    DeptName NVARCHAR(100) '$."DeptName"',
    DeptSeq INT '$."DeptSeq"',
    EmpName NVARCHAR(100) '$."EmpName"',
    EmpSeq INT '$."EmpSeq"',
    STDItemName NVARCHAR(100) '$."STDItemName"',
    STDItemSeq INT '$."STDItemSeq"',
    ItemEngName NVARCHAR(100) '$."ItemEngName"',
    ItemClassLName NVARCHAR(100) '$."ItemClassLName"',
    ItemClassMName NVARCHAR(100) '$."ItemClassMName"',
    ItemClassSName NVARCHAR(100) '$."ItemClassSName"',
    UMItemClass INT '$."UMItemClass"',
    RegUser NVARCHAR(100) '$."RegUser"',
    LastUser NVARCHAR(100) '$."LastUser"',
    RegDate NCHAR(8) '$."RegDate"',
    LastDate NCHAR(8) '$."LastDate"',
    IsSTDItem NCHAR(1) '$."IsSTDItem"',
    IsOption NCHAR(1) '$."IsOption"',
    IsSet NCHAR(1) '$."IsSet"',
    IsQC NCHAR(1) '$."IsQC"',
    SMOutKindName NVARCHAR(100) '$."SMOutKindName"',
    IsBOMReg NCHAR(1) '$."IsBOMReg"',
    IsProcReg NCHAR(1) '$."IsProcReg"',
    IsProcMat NCHAR(1) '$."IsProcMat"',
    SMLimitTermKindName NVARCHAR(100) '$."SMLimitTermKindName"',
    SMLimitTermKind INT '$."SMLimitTermKind"',
    IsLotMng INT '$."IsLotMng"',
    IsSerialMng INT '$."IsSerialMng"',
    SMAssetGrp INT '$."SMAssetGrp"',
    PurCustName NVARCHAR(100) '$."PurCustName"',
    TrustCustName NVARCHAR(100) '$."TrustCustName"',
    Remark NVARCHAR(100) '$."Remark"',
    SMVatKindName NVARCHAR(100) '$."SMVatKindName"',
    PriceInVat INT '$."PriceInVat"',
    IsFileCheck NCHAR(1) '$."IsFileCheck"',
    IsImangeCheck NCHAR(1) '$."IsImangeCheck"',
    StdItemNo NVARCHAR(100) '$."StdItemNo"',
    STDItemSpec NVARCHAR(100) '$."STDItemSpec"',
    MKCustName NVARCHAR(100) '$."MKCustName"',
    IsPrice NCHAR(1) '$."IsPrice"',
    URL NVARCHAR(100) '$."URL"',
    SMPurKind NVARCHAR(100) '$."SMPurKind"',
    PurKind NVARCHAR(100) '$."PurKind"',
    UMProperty INT '$."UMProperty"',
    UMPropertyName NVARCHAR(100) '$."UMPropertyName"',
    RowIDX INT '$."RowIDX"',
    ColIDX INT '$."ColIDX"',
    AddInfoName NVARCHAR(200) '$."AddInfoName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  DECLARE @loaded INT = @@ROWCOUNT;   -- 마스터 적재건수 (뒤 INSERT에 덮이지 않도록 먼저 보관)
  -- 장변/단변 부가정보(CMF): DataBlock4 {RowIDX(0-based=IDX_NO-1), ColIDX 0=ITEM_CMF_11 장변 / 1=ITEM_CMF_12 단변, AddInfoName=값}
  DELETE FROM DOI_VN_IF_ITEM_CMF WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_ITEM_CMF (SITE, RowIDX, ColIDX, AddInfoName, RAW_JSON)
  SELECT N'VN', j2.RowIDX, j2.ColIDX, j2.AddInfoName, j2.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock4')
  WITH (RowIDX INT '$."RowIDX"', ColIDX INT '$."ColIDX"', AddInfoName NVARCHAR(100) '$."AddInfoName"', [RAW_JSON] NVARCHAR(MAX) '$' AS JSON) j2;
  SELECT @loaded AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE dbo.UP_VN_IF_XFORM_ITEM
  @yyyymm  NVARCHAR(6),
  @selCode NVARCHAR(10) = N'ACTUAL',
  @site    NVARCHAR(4)  = N'VN'
AS
/* 품목(ITEM) 스테이징 → 면적기준정보 DOI_MODEL_MAST[VN]
 *  X=장변(ITEM_CMF_11), Y=단변(ITEM_CMF_12), XY=X×Y, MODEL=품번(ItemNo=도우코드), SPEC='X*Y'
 *  장변/단변은 DataBlock4 부가정보 {RowIDX(0-based), ColIDX 0/1, AddInfoName}를 피벗, 마스터 IDX_NO=RowIDX+1로 조인.
 *  규칙(기존 면적보정과 동일): 기존 행 보존 — 누락 모델은 INSERT, XY가 0/NULL인 행만 채움(수동 보정값 덮지 않음).
 *  INCH/GLASS_THICK/SHEET/BLOCK/CELL/RUN_SIZE 는 API 원천 없음 → NULL(기존값 유지). */
BEGIN
  SET NOCOUNT ON;
  IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;

  ;WITH cmf AS (
    SELECT c.RowIDX,
           MAX(CASE WHEN c.ColIDX=0 THEN TRY_CONVERT(real, c.AddInfoName) END) AS X,
           MAX(CASE WHEN c.ColIDX=1 THEN TRY_CONVERT(real, c.AddInfoName) END) AS Y
    FROM DOI_VN_IF_ITEM_CMF c
    WHERE c.SITE=@site
    GROUP BY c.RowIDX)
  SELECT i.ItemNo AS MODEL, cmf.X, cmf.Y
  INTO #src
  FROM DOI_VN_IF_ITEM i
  JOIN cmf ON cmf.RowIDX + 1 = i.IDX_NO
  WHERE i.SITE=@site AND ISNULL(i.ItemNo,'')<>''
    AND cmf.X IS NOT NULL AND cmf.Y IS NOT NULL AND cmf.X>0 AND cmf.Y>0;

  /* (1) 기존 행 중 XY 미설정(0/NULL)만 채움 — 수동 보정값 보존 */
  UPDATE m
     SET m.X=s.X, m.Y=s.Y, m.XY=CAST(s.X AS real)*CAST(s.Y AS real),
         m.SPEC=CONCAT(CAST(s.X AS varchar(20)),'*',CAST(s.Y AS varchar(20)))
  FROM DOI_MODEL_MAST m JOIN #src s ON s.MODEL=m.MODEL
  WHERE m.YYYYMM=@yyyymm AND m.SITE=@site AND m.SEL_CODE=@selCode AND ISNULL(m.XY,0)=0;
  DECLARE @upd INT = @@ROWCOUNT;

  /* (2) 누락 모델 INSERT — 기존 행 보존(NOT EXISTS) */
  INSERT INTO DOI_MODEL_MAST (YYYYMM,SEL_CODE,SITE,MODEL,SPEC,INCH,GLASS_THICK,SHEET,BLOCK,CELL,RUN_SIZE,X,Y,XY)
  SELECT @yyyymm,@selCode,@site, s.MODEL,
         CONCAT(CAST(s.X AS varchar(20)),'*',CAST(s.Y AS varchar(20))),
         NULL,NULL,NULL,NULL,NULL,NULL, s.X, s.Y, CAST(s.X AS real)*CAST(s.Y AS real)
  FROM #src s
  WHERE NOT EXISTS (SELECT 1 FROM DOI_MODEL_MAST m
                    WHERE m.YYYYMM=@yyyymm AND m.SITE=@site AND m.SEL_CODE=@selCode AND m.MODEL=s.MODEL);
  SELECT @upd + @@ROWCOUNT AS applied;
END;
GO
