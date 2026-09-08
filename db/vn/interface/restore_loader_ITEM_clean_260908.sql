/* =====================================================================
 * [VN 인터페이스] 품목 로더 정상 복구 — DataBlock4 캡처 제거 + @@ROWCOUNT 정상화
 *   capture_ITEM_DataBlock4 스크립트가 마스터 INSERT 뒤에 캡처 INSERT(항상 0건)를 두어
 *   SELECT @@ROWCOUNT 가 0으로 잘못 보고되던 것을, 캡처 없는 깨끗한 DataBlock3 로더로 되돌림.
 *   (DataBlock4는 장변/단변 값이 오지 않아 캡처 불필요 확정)
 *   실행: DWCMSTEST (SSMS). 실행 후 [품목 API 호출] → 4,908건 정상 표시.
 * ===================================================================== */
GO
CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ITEM @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ITEM WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_ITEM (SITE, LOAD_DTTM, REQUEST_ID, ItemSeq, ItemName, ItemNo, Spec, TrunName, AssetName, AssetSeq, UnitName, UnitSeq, SMABC, SMABCName, SMStatus, SMStatusName, SMInOutKind, SMInOutKindName, DeptName, DeptSeq, EmpName, EmpSeq, STDItemName, STDItemSeq, ItemEngName, ItemClassLName, ItemClassMName, ItemClassSName, UMItemClass, RegUser, LastUser, RegDate, LastDate, IsSTDItem, IsOption, IsSet, IsQC, SMOutKindName, IsBOMReg, IsProcReg, IsProcMat, SMLimitTermKindName, SMLimitTermKind, IsLotMng, IsSerialMng, SMAssetGrp, PurCustName, TrustCustName, Remark, SMVatKindName, PriceInVat, IsFileCheck, IsImangeCheck, StdItemNo, STDItemSpec, MKCustName, IsPrice, URL, SMPurKind, PurKind, UMProperty, UMPropertyName, RowIDX, ColIDX, AddInfoName, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.TrunName, j.AssetName, j.AssetSeq, j.UnitName, j.UnitSeq, j.SMABC, j.SMABCName, j.SMStatus, j.SMStatusName, j.SMInOutKind, j.SMInOutKindName, j.DeptName, j.DeptSeq, j.EmpName, j.EmpSeq, j.STDItemName, j.STDItemSeq, j.ItemEngName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.UMItemClass, j.RegUser, j.LastUser, j.RegDate, j.LastDate, j.IsSTDItem, j.IsOption, j.IsSet, j.IsQC, j.SMOutKindName, j.IsBOMReg, j.IsProcReg, j.IsProcMat, j.SMLimitTermKindName, j.SMLimitTermKind, j.IsLotMng, j.IsSerialMng, j.SMAssetGrp, j.PurCustName, j.TrustCustName, j.Remark, j.SMVatKindName, j.PriceInVat, j.IsFileCheck, j.IsImangeCheck, j.StdItemNo, j.STDItemSpec, j.MKCustName, j.IsPrice, j.URL, j.SMPurKind, j.PurKind, j.UMProperty, j.UMPropertyName, j.RowIDX, j.ColIDX, j.AddInfoName, j.[RAW_JSON]
  -- 품목 응답 메인행은 DataBlock3 (부가정의 장변/단변=DataBlock2, 부가값=DataBlock4). DataBlock1로는 0건이던 버그
  FROM OPENJSON(@json, '$.DataBlock3')
  WITH (
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
  SELECT @@ROWCOUNT AS loaded;
END;
GO
