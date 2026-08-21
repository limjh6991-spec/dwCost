-- VN IF 마스터 적재 프로시저 (OPENJSON). ERP 응답 루트=$.DataBlock1. 마스터=전체 삭제후 재적재
-- @json: API 응답 원문 / @requestId: 요청ID. RAW_JSON에 행 원본 보관

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ACCOUNT @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ACCOUNT WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_ACCOUNT (SITE, LOAD_DTTM, REQUEST_ID, SMAccKind, AccSeq, AccNo, DualAccNo, AccName, SMAccKindName, AccLevel, UpperAccName, UpperAccSeq, TreeSort, AccSort, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.SMAccKind, j.AccSeq, j.AccNo, j.DualAccNo, j.AccName, j.SMAccKindName, j.AccLevel, j.UpperAccName, j.UpperAccSeq, j.TreeSort, j.AccSort, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    SMAccKind NVARCHAR(100) '$."SMAccKind"',
    AccSeq INT '$."AccSeq"',
    AccNo NVARCHAR(100) '$."AccNo"',
    DualAccNo NVARCHAR(100) '$."DualAccNo"',
    AccName NVARCHAR(100) '$."AccName"',
    SMAccKindName NVARCHAR(100) '$."SMAccKindName"',
    AccLevel INT '$."AccLevel"',
    UpperAccName NVARCHAR(100) '$."UpperAccName"',
    UpperAccSeq INT '$."UpperAccSeq"',
    TreeSort INT '$."TreeSort"',
    AccSort INT '$."AccSort"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_DEPT @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_DEPT WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_DEPT (SITE, LOAD_DTTM, REQUEST_ID, DeptName, EngDeptName, BegDate, EndDate, BizUnit, FactUnit, Remark, IsUse, CCtrName, UMDeptAttrName, Email, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.DeptName, j.EngDeptName, j.BegDate, j.EndDate, j.BizUnit, j.FactUnit, j.Remark, j.IsUse, j.CCtrName, j.UMDeptAttrName, j.Email, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    DeptName NVARCHAR(100) '$."DeptName"',
    EngDeptName NVARCHAR(100) '$."EngDeptName"',
    BegDate NCHAR(8) '$."BegDate"',
    EndDate NCHAR(8) '$."EndDate"',
    BizUnit NCHAR(1) '$."BizUnit"',
    FactUnit NCHAR(1) '$."FactUnit"',
    Remark NVARCHAR(1000) '$."Remark"',
    IsUse NCHAR(1) '$."IsUse"',
    CCtrName NVARCHAR(100) '$."CCtrName"',
    UMDeptAttrName NVARCHAR(100) '$."UMDeptAttrName"',
    Email NVARCHAR(100) '$."Email"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_MATERIAL @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_MATERIAL WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_MATERIAL (SITE, LOAD_DTTM, REQUEST_ID, ItemSeq, ItemName, ItemNo, Spec, AssetName, UnitName, SMABCName, SMStatusName, SMInOutKindName, DeptName, EmpName, STDItemName, ItemEngName, ItemClassLName, ItemClassMName, ItemClassSName, RegUserSeq, LastUserSeq, RegDate, LastDate, IsSTDItem, IsSet, IsQC, SMOutKindName, IsBOMReg, IsProcMat, SMLimitTermKindName, SMLimitTermKind, IsLotMng, IsSerialMng, SMAssetGrp, PurCustName, TrustCustName, Remark, SMVatKindName, PriceInVat, IsFileCheck, IsImageCheck, STDItemNo, STDItemSpec, MKCustName, IsPrice, URL, UMProperty, UMPropertyName, MAT_GRP_1, MAT_GRP_2, MAT_GRP_4, MAT_GRP_5, MAT_GRP_6, MAT_GRP_7, MAT_GRP_8, MAT_GRP_9, MAT_GRP_10, MAT_CMF_1, MAT_CMF_2, MAT_CMF_3, MAT_CMF_4, MAT_CMF_5, MAT_CMF_6, MAT_CMF_7, MAT_CMF_8, MAT_CMF_9, MAT_CMF_10, MAT_CMF_11, MAT_CMF_12, MAT_CMF_13, MAT_CMF_14, MAT_CMF_15, MAT_CMF_16, MAT_CMF_17, MAT_CMF_18, MAT_CMF_19, MAT_CMF_20, FIRST_FLOW, FIRST_FLOW_SEQ_NUM, LAST_FLOW, LAST_FLOW_SEQ_NUM, MFG_DEVISION, SUBCONTRACT_FLAG, BASE_MAT_ID, VENDOR_ID, VENDOR_MAT_ID, CUSTOMER_ID, CUSTOMER_MAT_ID, BOM_SET_ID, APPLY_START_TIME, APPLY_END_TIME, APPROVAL_FLAG, APPROVAL_USER_ID, APPROVAL_TIME, RELEASE_FLAG, RELEASE_USER_ID, RELEASE_TIME, DEACTIVE_FLAG, DEACTIVE_USER_ID, DEACTIVE_TIME, MAT_SHORT_DESC, IQC_YN, VENDOR, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.AssetName, j.UnitName, j.SMABCName, j.SMStatusName, j.SMInOutKindName, j.DeptName, j.EmpName, j.STDItemName, j.ItemEngName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.RegUserSeq, j.LastUserSeq, j.RegDate, j.LastDate, j.IsSTDItem, j.IsSet, j.IsQC, j.SMOutKindName, j.IsBOMReg, j.IsProcMat, j.SMLimitTermKindName, j.SMLimitTermKind, j.IsLotMng, j.IsSerialMng, j.SMAssetGrp, j.PurCustName, j.TrustCustName, j.Remark, j.SMVatKindName, j.PriceInVat, j.IsFileCheck, j.IsImageCheck, j.STDItemNo, j.STDItemSpec, j.MKCustName, j.IsPrice, j.URL, j.UMProperty, j.UMPropertyName, j.MAT_GRP_1, j.MAT_GRP_2, j.MAT_GRP_4, j.MAT_GRP_5, j.MAT_GRP_6, j.MAT_GRP_7, j.MAT_GRP_8, j.MAT_GRP_9, j.MAT_GRP_10, j.MAT_CMF_1, j.MAT_CMF_2, j.MAT_CMF_3, j.MAT_CMF_4, j.MAT_CMF_5, j.MAT_CMF_6, j.MAT_CMF_7, j.MAT_CMF_8, j.MAT_CMF_9, j.MAT_CMF_10, j.MAT_CMF_11, j.MAT_CMF_12, j.MAT_CMF_13, j.MAT_CMF_14, j.MAT_CMF_15, j.MAT_CMF_16, j.MAT_CMF_17, j.MAT_CMF_18, j.MAT_CMF_19, j.MAT_CMF_20, j.FIRST_FLOW, j.FIRST_FLOW_SEQ_NUM, j.LAST_FLOW, j.LAST_FLOW_SEQ_NUM, j.MFG_DEVISION, j.SUBCONTRACT_FLAG, j.BASE_MAT_ID, j.VENDOR_ID, j.VENDOR_MAT_ID, j.CUSTOMER_ID, j.CUSTOMER_MAT_ID, j.BOM_SET_ID, j.APPLY_START_TIME, j.APPLY_END_TIME, j.APPROVAL_FLAG, j.APPROVAL_USER_ID, j.APPROVAL_TIME, j.RELEASE_FLAG, j.RELEASE_USER_ID, j.RELEASE_TIME, j.DEACTIVE_FLAG, j.DEACTIVE_USER_ID, j.DEACTIVE_TIME, j.MAT_SHORT_DESC, j.IQC_YN, j.VENDOR, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock3')   -- ⭐ 자재/품목 응답은 DataBlock3에 데이터(DataBlock2=CMF메타). 2026-08-21
  WITH (
    ItemSeq INT '$."ItemSeq"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemNo NVARCHAR(100) '$."ItemNo"',
    Spec NVARCHAR(100) '$."Spec"',
    AssetName NVARCHAR(100) '$."AssetName"',
    UnitName NVARCHAR(100) '$."UnitName"',
    SMABCName NVARCHAR(100) '$."SMABCName"',
    SMStatusName NVARCHAR(100) '$."SMStatusName"',
    SMInOutKindName NVARCHAR(100) '$."SMInOutKindName"',
    DeptName NVARCHAR(100) '$."DeptName"',
    EmpName NVARCHAR(100) '$."EmpName"',
    STDItemName NVARCHAR(100) '$."STDItemName"',
    ItemEngName NVARCHAR(100) '$."ItemEngName"',
    ItemClassLName NVARCHAR(100) '$."ItemClassLName"',
    ItemClassMName NVARCHAR(100) '$."ItemClassMName"',
    ItemClassSName NVARCHAR(100) '$."ItemClassSName"',
    RegUserSeq INT '$."RegUserSeq"',
    LastUserSeq INT '$."LastUserSeq"',
    RegDate NCHAR(8) '$."RegDate"',
    LastDate NCHAR(8) '$."LastDate"',
    IsSTDItem NVARCHAR(100) '$."IsSTDItem"',
    IsSet NCHAR(1) '$."IsSet"',
    IsQC NCHAR(1) '$."IsQC"',
    SMOutKindName NVARCHAR(100) '$."SMOutKindName"',
    IsBOMReg NCHAR(1) '$."IsBOMReg"',
    IsProcMat NCHAR(1) '$."IsProcMat"',
    SMLimitTermKindName NVARCHAR(100) '$."SMLimitTermKindName"',
    SMLimitTermKind NVARCHAR(100) '$."SMLimitTermKind"',
    IsLotMng NCHAR(1) '$."IsLotMng"',
    IsSerialMng NCHAR(1) '$."IsSerialMng"',
    SMAssetGrp NCHAR(1) '$."SMAssetGrp"',
    PurCustName NVARCHAR(100) '$."PurCustName"',
    TrustCustName NVARCHAR(100) '$."TrustCustName"',
    Remark NVARCHAR(100) '$."Remark"',
    SMVatKindName NVARCHAR(100) '$."SMVatKindName"',
    PriceInVat NCHAR(1) '$."PriceInVat"',
    IsFileCheck NCHAR(1) '$."IsFileCheck"',
    IsImageCheck NCHAR(1) '$."IsImageCheck"',
    STDItemNo NVARCHAR(100) '$."STDItemNo"',
    STDItemSpec NVARCHAR(100) '$."STDItemSpec"',
    MKCustName NVARCHAR(100) '$."MKCustName"',
    IsPrice NCHAR(1) '$."IsPrice"',
    URL NVARCHAR(100) '$."URL"',
    UMProperty INT '$."UMProperty"',
    UMPropertyName NVARCHAR(100) '$."UMPropertyName"',
    MAT_GRP_1 NVARCHAR(20) '$."MAT_GRP_1"',
    MAT_GRP_2 NVARCHAR(50) '$."MAT_GRP_2"',
    MAT_GRP_4 NVARCHAR(20) '$."MAT_GRP_4"',
    MAT_GRP_5 NVARCHAR(20) '$."MAT_GRP_5"',
    MAT_GRP_6 NVARCHAR(20) '$."MAT_GRP_6"',
    MAT_GRP_7 NVARCHAR(20) '$."MAT_GRP_7"',
    MAT_GRP_8 NVARCHAR(20) '$."MAT_GRP_8"',
    MAT_GRP_9 NVARCHAR(20) '$."MAT_GRP_9"',
    MAT_GRP_10 NVARCHAR(20) '$."MAT_GRP_10"',
    MAT_CMF_1 NVARCHAR(20) '$."MAT_CMF_1"',
    MAT_CMF_2 NVARCHAR(20) '$."MAT_CMF_2"',
    MAT_CMF_3 NVARCHAR(20) '$."MAT_CMF_3"',
    MAT_CMF_4 NVARCHAR(20) '$."MAT_CMF_4"',
    MAT_CMF_5 NVARCHAR(20) '$."MAT_CMF_5"',
    MAT_CMF_6 NVARCHAR(20) '$."MAT_CMF_6"',
    MAT_CMF_7 NVARCHAR(20) '$."MAT_CMF_7"',
    MAT_CMF_8 NVARCHAR(20) '$."MAT_CMF_8"',
    MAT_CMF_9 NVARCHAR(20) '$."MAT_CMF_9"',
    MAT_CMF_10 NVARCHAR(20) '$."MAT_CMF_10"',
    MAT_CMF_11 NVARCHAR(20) '$."MAT_CMF_11"',
    MAT_CMF_12 NVARCHAR(20) '$."MAT_CMF_12"',
    MAT_CMF_13 NVARCHAR(20) '$."MAT_CMF_13"',
    MAT_CMF_14 NVARCHAR(20) '$."MAT_CMF_14"',
    MAT_CMF_15 NVARCHAR(20) '$."MAT_CMF_15"',
    MAT_CMF_16 NVARCHAR(50) '$."MAT_CMF_16"',
    MAT_CMF_17 NVARCHAR(20) '$."MAT_CMF_17"',
    MAT_CMF_18 NVARCHAR(20) '$."MAT_CMF_18"',
    MAT_CMF_19 NVARCHAR(20) '$."MAT_CMF_19"',
    MAT_CMF_20 NVARCHAR(20) '$."MAT_CMF_20"',
    FIRST_FLOW NVARCHAR(20) '$."FIRST_FLOW"',
    FIRST_FLOW_SEQ_NUM INT '$."FIRST_FLOW_SEQ_NUM"',
    LAST_FLOW NVARCHAR(20) '$."LAST_FLOW"',
    LAST_FLOW_SEQ_NUM INT '$."LAST_FLOW_SEQ_NUM"',
    MFG_DEVISION NVARCHAR(20) '$."MFG_DEVISION"',
    SUBCONTRACT_FLAG NVARCHAR(20) '$."SUBCONTRACT_FLAG"',
    BASE_MAT_ID NVARCHAR(20) '$."BASE_MAT_ID"',
    VENDOR_ID NVARCHAR(20) '$."VENDOR_ID"',
    VENDOR_MAT_ID NVARCHAR(20) '$."VENDOR_MAT_ID"',
    CUSTOMER_ID NVARCHAR(20) '$."CUSTOMER_ID"',
    CUSTOMER_MAT_ID NVARCHAR(20) '$."CUSTOMER_MAT_ID"',
    BOM_SET_ID NVARCHAR(20) '$."BOM_SET_ID"',
    APPLY_START_TIME NVARCHAR(20) '$."APPLY_START_TIME"',
    APPLY_END_TIME NVARCHAR(20) '$."APPLY_END_TIME"',
    APPROVAL_FLAG NVARCHAR(20) '$."APPROVAL_FLAG"',
    APPROVAL_USER_ID NVARCHAR(20) '$."APPROVAL_USER_ID"',
    APPROVAL_TIME NVARCHAR(20) '$."APPROVAL_TIME"',
    RELEASE_FLAG NVARCHAR(20) '$."RELEASE_FLAG"',
    RELEASE_USER_ID NVARCHAR(20) '$."RELEASE_USER_ID"',
    RELEASE_TIME NVARCHAR(20) '$."RELEASE_TIME"',
    DEACTIVE_FLAG NVARCHAR(20) '$."DEACTIVE_FLAG"',
    DEACTIVE_USER_ID NVARCHAR(20) '$."DEACTIVE_USER_ID"',
    DEACTIVE_TIME NVARCHAR(20) '$."DEACTIVE_TIME"',
    MAT_SHORT_DESC NVARCHAR(20) '$."MAT_SHORT_DESC"',
    IQC_YN NVARCHAR(200) '$."IQC YN"',
    VENDOR NVARCHAR(50) '$."VENDOR"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ITEM @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ITEM WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_ITEM (SITE, LOAD_DTTM, REQUEST_ID, ItemSeq, ItemName, ItemNo, Spec, TrunName, AssetName, AssetSeq, UnitName, UnitSeq, SMABC, SMABCName, SMStatus, SMStatusName, SMInOutKind, SMInOutKindName, DeptName, DeptSeq, EmpName, EmpSeq, STDItemName, STDItemSeq, ItemEngName, ItemClassLName, ItemClassMName, ItemClassSName, UMItemClass, RegUser, LastUser, RegDate, LastDate, IsSTDItem, IsOption, IsSet, IsQC, SMOutKindName, IsBOMReg, IsProcReg, IsProcMat, SMLimitTermKindName, SMLimitTermKind, IsLotMng, IsSerialMng, SMAssetGrp, PurCustName, TrustCustName, Remark, SMVatKindName, PriceInVat, IsFileCheck, IsImangeCheck, StdItemNo, STDItemSpec, MKCustName, IsPrice, URL, SMPurKind, PurKind, UMProperty, UMPropertyName, RowIDX, ColIDX, AddInfoName, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.TrunName, j.AssetName, j.AssetSeq, j.UnitName, j.UnitSeq, j.SMABC, j.SMABCName, j.SMStatus, j.SMStatusName, j.SMInOutKind, j.SMInOutKindName, j.DeptName, j.DeptSeq, j.EmpName, j.EmpSeq, j.STDItemName, j.STDItemSeq, j.ItemEngName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.UMItemClass, j.RegUser, j.LastUser, j.RegDate, j.LastDate, j.IsSTDItem, j.IsOption, j.IsSet, j.IsQC, j.SMOutKindName, j.IsBOMReg, j.IsProcReg, j.IsProcMat, j.SMLimitTermKindName, j.SMLimitTermKind, j.IsLotMng, j.IsSerialMng, j.SMAssetGrp, j.PurCustName, j.TrustCustName, j.Remark, j.SMVatKindName, j.PriceInVat, j.IsFileCheck, j.IsImangeCheck, j.StdItemNo, j.STDItemSpec, j.MKCustName, j.IsPrice, j.URL, j.SMPurKind, j.PurKind, j.UMProperty, j.UMPropertyName, j.RowIDX, j.ColIDX, j.AddInfoName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
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

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_PROCESS @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_PROCESS WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_PROCESS (SITE, LOAD_DTTM, REQUEST_ID, BizUnit, ProcSeq, ProcName, Remark, IsProcQC, RAW_JSON)
  SELECT N'VN', GETDATE(), @requestId, j.BizUnit, j.ProcSeq, j.ProcName, j.Remark, j.IsProcQC, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    BizUnit INT '$."BizUnit"',
    ProcSeq INT '$."ProcSeq"',
    ProcName NVARCHAR(100) '$."ProcName"',
    Remark NVARCHAR(100) '$."Remark"',
    IsProcQC INT '$."IsProcQC"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
