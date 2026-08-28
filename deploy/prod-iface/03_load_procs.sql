-- ⚠️운영(도우제조원가시스템) 배포용. dev(DWCMSTEST) 라이브 정의에서 추출(2026-08-28).
-- 검토 후 운영에서 실행. 멱등(존재시 스킵/ALTER).

-- 적재 프로시저 26종

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_ACCOUNT @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_ACCOUNT WHERE SITE=N'HQ';
  INSERT INTO DOI_HQ_IF_ACCOUNT (SITE, LOAD_DTTM, REQUEST_ID, SMAccKind, AccSeq, AccNo, DualAccNo, AccName, SMAccKindName, AccLevel, UpperAccName, UpperAccSeq, TreeSort, AccSort, RAW_JSON)
  SELECT N'HQ', GETDATE(), @requestId, j.SMAccKind, j.AccSeq, j.AccNo, j.DualAccNo, j.AccName, j.SMAccKindName, j.AccLevel, j.UpperAccName, j.UpperAccSeq, j.TreeSort, j.AccSort, j.[RAW_JSON]
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
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_DEPT @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_DEPT WHERE SITE=N'HQ';
  INSERT INTO DOI_HQ_IF_DEPT ([SITE], [LOAD_DTTM], [REQUEST_ID], [CCtrName], [UMCCtrKindName], [EmpName], [DeptName], [UMCostTypeName], [Remark], [BizUnitName], [AccUnitName], [SMCourceTypeName], [RegDate], [RegUserName], [IsNotUse], [IsNotUseDate], [DispSeq], [DeptSeq], [CCtrSeq], [UMCostType], [RegUserSeq], [BizUnit], [AccUnit], [SMCourceType], [UMCCtrKind], [EmpSeq], [IsTemp], [LastUserName], [LastDateTime], [Dummy1], [Dummy2], [Dummy3], [Dummy4], [Dummy5], [Dummy6], [Dummy7], [Dummy8], [Dummy9], [Dummy10], [RAW_JSON])
  SELECT N'HQ', GETDATE(), @requestId, j.[CCtrName], j.[UMCCtrKindName], j.[EmpName], j.[DeptName], j.[UMCostTypeName], j.[Remark], j.[BizUnitName], j.[AccUnitName], j.[SMCourceTypeName], j.[RegDate], j.[RegUserName], j.[IsNotUse], j.[IsNotUseDate], j.[DispSeq], j.[DeptSeq], j.[CCtrSeq], j.[UMCostType], j.[RegUserSeq], j.[BizUnit], j.[AccUnit], j.[SMCourceType], j.[UMCCtrKind], j.[EmpSeq], j.[IsTemp], j.[LastUserName], j.[LastDateTime], j.[Dummy1], j.[Dummy2], j.[Dummy3], j.[Dummy4], j.[Dummy5], j.[Dummy6], j.[Dummy7], j.[Dummy8], j.[Dummy9], j.[Dummy10], j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    [CCtrName] NVARCHAR(200) '$."CCtrName"',
    [UMCCtrKindName] NVARCHAR(200) '$."UMCCtrKindName"',
    [EmpName] NVARCHAR(200) '$."EmpName"',
    [DeptName] NVARCHAR(200) '$."DeptName"',
    [UMCostTypeName] NVARCHAR(200) '$."UMCostTypeName"',
    [Remark] NVARCHAR(200) '$."Remark"',
    [BizUnitName] NVARCHAR(200) '$."BizUnitName"',
    [AccUnitName] NVARCHAR(200) '$."AccUnitName"',
    [SMCourceTypeName] NVARCHAR(200) '$."SMCourceTypeName"',
    [RegDate] NVARCHAR(200) '$."RegDate"',
    [RegUserName] NVARCHAR(200) '$."RegUserName"',
    [IsNotUse] NVARCHAR(200) '$."IsNotUse"',
    [IsNotUseDate] NVARCHAR(200) '$."IsNotUseDate"',
    [DispSeq] NVARCHAR(200) '$."DispSeq"',
    [DeptSeq] NVARCHAR(200) '$."DeptSeq"',
    [CCtrSeq] NVARCHAR(200) '$."CCtrSeq"',
    [UMCostType] NVARCHAR(200) '$."UMCostType"',
    [RegUserSeq] NVARCHAR(200) '$."RegUserSeq"',
    [BizUnit] NVARCHAR(200) '$."BizUnit"',
    [AccUnit] NVARCHAR(200) '$."AccUnit"',
    [SMCourceType] NVARCHAR(200) '$."SMCourceType"',
    [UMCCtrKind] NVARCHAR(200) '$."UMCCtrKind"',
    [EmpSeq] NVARCHAR(200) '$."EmpSeq"',
    [IsTemp] NVARCHAR(200) '$."IsTemp"',
    [LastUserName] NVARCHAR(200) '$."LastUserName"',
    [LastDateTime] NVARCHAR(200) '$."LastDateTime"',
    [Dummy1] NVARCHAR(200) '$."Dummy1"',
    [Dummy2] NVARCHAR(200) '$."Dummy2"',
    [Dummy3] NVARCHAR(200) '$."Dummy3"',
    [Dummy4] NVARCHAR(200) '$."Dummy4"',
    [Dummy5] NVARCHAR(200) '$."Dummy5"',
    [Dummy6] NVARCHAR(200) '$."Dummy6"',
    [Dummy7] NVARCHAR(200) '$."Dummy7"',
    [Dummy8] NVARCHAR(200) '$."Dummy8"',
    [Dummy9] NVARCHAR(200) '$."Dummy9"',
    [Dummy10] NVARCHAR(200) '$."Dummy10"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_DEPT_COST @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_DEPT_COST WHERE SITE=N'HQ' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_HQ_IF_DEPT_COST
    (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, CCtrName, DeptSeq, AccNameCost, AccNo, AccName,
     UMCostTypeName, AccSeq, DrAmt, CrAmt, UMCCtrKindName, SMSourceTypeName, CCtrAccUnitName, RAW_JSON)
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.CCtrName, j.DeptSeq, j.AccNameCost, j.AccNo, j.AccName,
     j.UMCostTypeName, j.AccSeq, j.DrAmt, j.CrAmt, j.UMCCtrKindName, j.SMSourceTypeName, j.CCtrAccUnitName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    CCtrName NVARCHAR(100) '$."CCtrName"',
    DeptSeq INT '$."DeptSeq"',
    AccNameCost NVARCHAR(100) '$."AccNameCost"',
    AccNo NVARCHAR(100) '$."AccNo"',
    AccName NVARCHAR(100) '$."AccName"',
    UMCostTypeName NVARCHAR(100) '$."UMCostTypeName"',
    AccSeq INT '$."AccSeq"',
    DrAmt DECIMAL(19,5) '$."DrAmt"',
    CrAmt DECIMAL(19,5) '$."CrAmt"',
    UMCCtrKindName NVARCHAR(100) '$."UMCCtrKindName"',
    SMSourceTypeName NVARCHAR(100) '$."SMSourceTypeName"',
    CCtrAccUnitName NVARCHAR(100) '$."CCtrAccUnitName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_EXP_INVOICE @json NVARCHAR(MAX), @selCode NVARCHAR(10)=N'ACTUAL', @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_EXP_INVOICE WHERE SITE=N'HQ' AND SEL_CODE=@selCode;
  INSERT INTO DOI_HQ_IF_EXP_INVOICE ([SITE], [SEL_CODE], [LOAD_DTTM], [REQUEST_ID], [InvoiceSeq], [InvoiceSerl], [IsDelvCfm], [BizUnit], [BizUnitName], [InvoiceDate], [InvoiceNo], [InvoiceRefNo], [SMExpKind], [UMOutKind], [UMOutKindName], [SMExpKindName], [CustSeq], [CustName], [CurrSeq], [CurrName], [UMPriceTerm], [UMPriceTermName], [DeptSeq], [DeptName], [EmpSeq], [ExRate], [EmpName], [ItemSeq], [ItemName], [ItemNo], [Spec], [UnitSeq], [UnitName], [Qty], [Price], [ItemPrice], [CustPrice], [VATRate], [CurAmt], [CurVAT], [DomAmt], [DomVAT], [TotDomAmt], [RemarkM], [Remark], [StdUnitSeq], [StdUnitName], [StdQty], [WHName], [DVPlaceSeq], [DVPlaceName], [SMProgressTypeName], [IsStockSales], [IsSalesProc], [IsReturn], [IsWithSalesVat], [UMEtcOutKind], [UMEtcOutKindName], [LotNo], [GrossWeight], [NetWeight], [Volume], [Capacity], [ContainerNo], [CottonNo], [SerialNo], [SalesPrice], [ItemClassSSeq], [ItemClassSName], [ItemClassMSeq], [ItemClassMName], [ItemClassLSeq], [ItemClassLName], [PONo], [SourceRefNo], [SourceNo], [Dummy1], [Dummy2], [Dummy3], [Dummy4], [Dummy5], [Dummy6], [Dummy7], [Dummy8], [Dummy9], [Dummy10], [CustItemName], [CustItemNo], [CustItemSpec], [ItemEngName], [AddInfo], [AssetName], [ItemDVDate], [SMSalesProgTypeName], [WHSeq], [CustNo], [EndUser], [EndUserText], [EndUserName], [HSCode], [BKCustName], [NonSalesAmt], [NonSalesQty], [RAW_JSON])
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.[InvoiceSeq], j.[InvoiceSerl], j.[IsDelvCfm], j.[BizUnit], j.[BizUnitName], j.[InvoiceDate], j.[InvoiceNo], j.[InvoiceRefNo], j.[SMExpKind], j.[UMOutKind], j.[UMOutKindName], j.[SMExpKindName], j.[CustSeq], j.[CustName], j.[CurrSeq], j.[CurrName], j.[UMPriceTerm], j.[UMPriceTermName], j.[DeptSeq], j.[DeptName], j.[EmpSeq], j.[ExRate], j.[EmpName], j.[ItemSeq], j.[ItemName], j.[ItemNo], j.[Spec], j.[UnitSeq], j.[UnitName], j.[Qty], j.[Price], j.[ItemPrice], j.[CustPrice], j.[VATRate], j.[CurAmt], j.[CurVAT], j.[DomAmt], j.[DomVAT], j.[TotDomAmt], j.[RemarkM], j.[Remark], j.[StdUnitSeq], j.[StdUnitName], j.[StdQty], j.[WHName], j.[DVPlaceSeq], j.[DVPlaceName], j.[SMProgressTypeName], j.[IsStockSales], j.[IsSalesProc], j.[IsReturn], j.[IsWithSalesVat], j.[UMEtcOutKind], j.[UMEtcOutKindName], j.[LotNo], j.[GrossWeight], j.[NetWeight], j.[Volume], j.[Capacity], j.[ContainerNo], j.[CottonNo], j.[SerialNo], j.[SalesPrice], j.[ItemClassSSeq], j.[ItemClassSName], j.[ItemClassMSeq], j.[ItemClassMName], j.[ItemClassLSeq], j.[ItemClassLName], j.[PONo], j.[SourceRefNo], j.[SourceNo], j.[Dummy1], j.[Dummy2], j.[Dummy3], j.[Dummy4], j.[Dummy5], j.[Dummy6], j.[Dummy7], j.[Dummy8], j.[Dummy9], j.[Dummy10], j.[CustItemName], j.[CustItemNo], j.[CustItemSpec], j.[ItemEngName], j.[AddInfo], j.[AssetName], j.[ItemDVDate], j.[SMSalesProgTypeName], j.[WHSeq], j.[CustNo], j.[EndUser], j.[EndUserText], j.[EndUserName], j.[HSCode], j.[BKCustName], j.[NonSalesAmt], j.[NonSalesQty], j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    [InvoiceSeq] NVARCHAR(200) '$."InvoiceSeq"',
    [InvoiceSerl] NVARCHAR(200) '$."InvoiceSerl"',
    [IsDelvCfm] NVARCHAR(200) '$."IsDelvCfm"',
    [BizUnit] NVARCHAR(200) '$."BizUnit"',
    [BizUnitName] NVARCHAR(200) '$."BizUnitName"',
    [InvoiceDate] NVARCHAR(200) '$."InvoiceDate"',
    [InvoiceNo] NVARCHAR(200) '$."InvoiceNo"',
    [InvoiceRefNo] NVARCHAR(200) '$."InvoiceRefNo"',
    [SMExpKind] NVARCHAR(200) '$."SMExpKind"',
    [UMOutKind] NVARCHAR(200) '$."UMOutKind"',
    [UMOutKindName] NVARCHAR(200) '$."UMOutKindName"',
    [SMExpKindName] NVARCHAR(200) '$."SMExpKindName"',
    [CustSeq] NVARCHAR(200) '$."CustSeq"',
    [CustName] NVARCHAR(200) '$."CustName"',
    [CurrSeq] NVARCHAR(200) '$."CurrSeq"',
    [CurrName] NVARCHAR(200) '$."CurrName"',
    [UMPriceTerm] NVARCHAR(200) '$."UMPriceTerm"',
    [UMPriceTermName] NVARCHAR(200) '$."UMPriceTermName"',
    [DeptSeq] NVARCHAR(200) '$."DeptSeq"',
    [DeptName] NVARCHAR(200) '$."DeptName"',
    [EmpSeq] NVARCHAR(200) '$."EmpSeq"',
    [ExRate] NVARCHAR(200) '$."ExRate"',
    [EmpName] NVARCHAR(200) '$."EmpName"',
    [ItemSeq] NVARCHAR(200) '$."ItemSeq"',
    [ItemName] NVARCHAR(200) '$."ItemName"',
    [ItemNo] NVARCHAR(200) '$."ItemNo"',
    [Spec] NVARCHAR(200) '$."Spec"',
    [UnitSeq] NVARCHAR(200) '$."UnitSeq"',
    [UnitName] NVARCHAR(200) '$."UnitName"',
    [Qty] NVARCHAR(200) '$."Qty"',
    [Price] NVARCHAR(200) '$."Price"',
    [ItemPrice] NVARCHAR(200) '$."ItemPrice"',
    [CustPrice] NVARCHAR(200) '$."CustPrice"',
    [VATRate] NVARCHAR(200) '$."VATRate"',
    [CurAmt] NVARCHAR(200) '$."CurAmt"',
    [CurVAT] NVARCHAR(200) '$."CurVAT"',
    [DomAmt] NVARCHAR(200) '$."DomAmt"',
    [DomVAT] NVARCHAR(200) '$."DomVAT"',
    [TotDomAmt] NVARCHAR(200) '$."TotDomAmt"',
    [RemarkM] NVARCHAR(200) '$."RemarkM"',
    [Remark] NVARCHAR(200) '$."Remark"',
    [StdUnitSeq] NVARCHAR(200) '$."StdUnitSeq"',
    [StdUnitName] NVARCHAR(200) '$."StdUnitName"',
    [StdQty] NVARCHAR(200) '$."StdQty"',
    [WHName] NVARCHAR(200) '$."WHName"',
    [DVPlaceSeq] NVARCHAR(200) '$."DVPlaceSeq"',
    [DVPlaceName] NVARCHAR(200) '$."DVPlaceName"',
    [SMProgressTypeName] NVARCHAR(200) '$."SMProgressTypeName"',
    [IsStockSales] NVARCHAR(200) '$."IsStockSales"',
    [IsSalesProc] NVARCHAR(200) '$."IsSalesProc"',
    [IsReturn] NVARCHAR(200) '$."IsReturn"',
    [IsWithSalesVat] NVARCHAR(200) '$."IsWithSalesVat"',
    [UMEtcOutKind] NVARCHAR(200) '$."UMEtcOutKind"',
    [UMEtcOutKindName] NVARCHAR(200) '$."UMEtcOutKindName"',
    [LotNo] NVARCHAR(200) '$."LotNo"',
    [GrossWeight] NVARCHAR(200) '$."GrossWeight"',
    [NetWeight] NVARCHAR(200) '$."NetWeight"',
    [Volume] NVARCHAR(200) '$."Volume"',
    [Capacity] NVARCHAR(200) '$."Capacity"',
    [ContainerNo] NVARCHAR(200) '$."ContainerNo"',
    [CottonNo] NVARCHAR(200) '$."CottonNo"',
    [SerialNo] NVARCHAR(200) '$."SerialNo"',
    [SalesPrice] NVARCHAR(200) '$."SalesPrice"',
    [ItemClassSSeq] NVARCHAR(200) '$."ItemClassSSeq"',
    [ItemClassSName] NVARCHAR(200) '$."ItemClassSName"',
    [ItemClassMSeq] NVARCHAR(200) '$."ItemClassMSeq"',
    [ItemClassMName] NVARCHAR(200) '$."ItemClassMName"',
    [ItemClassLSeq] NVARCHAR(200) '$."ItemClassLSeq"',
    [ItemClassLName] NVARCHAR(200) '$."ItemClassLName"',
    [PONo] NVARCHAR(200) '$."PONo"',
    [SourceRefNo] NVARCHAR(200) '$."SourceRefNo"',
    [SourceNo] NVARCHAR(200) '$."SourceNo"',
    [Dummy1] NVARCHAR(200) '$."Dummy1"',
    [Dummy2] NVARCHAR(200) '$."Dummy2"',
    [Dummy3] NVARCHAR(200) '$."Dummy3"',
    [Dummy4] NVARCHAR(200) '$."Dummy4"',
    [Dummy5] NVARCHAR(200) '$."Dummy5"',
    [Dummy6] NVARCHAR(200) '$."Dummy6"',
    [Dummy7] NVARCHAR(200) '$."Dummy7"',
    [Dummy8] NVARCHAR(200) '$."Dummy8"',
    [Dummy9] NVARCHAR(200) '$."Dummy9"',
    [Dummy10] NVARCHAR(200) '$."Dummy10"',
    [CustItemName] NVARCHAR(200) '$."CustItemName"',
    [CustItemNo] NVARCHAR(200) '$."CustItemNo"',
    [CustItemSpec] NVARCHAR(200) '$."CustItemSpec"',
    [ItemEngName] NVARCHAR(200) '$."ItemEngName"',
    [AddInfo] NVARCHAR(200) '$."AddInfo"',
    [AssetName] NVARCHAR(200) '$."AssetName"',
    [ItemDVDate] NVARCHAR(200) '$."ItemDVDate"',
    [SMSalesProgTypeName] NVARCHAR(200) '$."SMSalesProgTypeName"',
    [WHSeq] NVARCHAR(200) '$."WHSeq"',
    [CustNo] NVARCHAR(200) '$."CustNo"',
    [EndUser] NVARCHAR(200) '$."EndUser"',
    [EndUserText] NVARCHAR(200) '$."EndUserText"',
    [EndUserName] NVARCHAR(200) '$."EndUserName"',
    [HSCode] NVARCHAR(200) '$."HSCode"',
    [BKCustName] NVARCHAR(200) '$."BKCustName"',
    [NonSalesAmt] NVARCHAR(200) '$."NonSalesAmt"',
    [NonSalesQty] NVARCHAR(200) '$."NonSalesQty"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_MATERIAL @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_MATERIAL WHERE SITE=N'HQ';
  INSERT INTO DOI_HQ_IF_MATERIAL ([SITE], [LOAD_DTTM], [REQUEST_ID], [ItemSeq], [ItemName], [ItemNo], [Spec], [UnitSeq], [UnitName], [ProcRev], [ProcSeq], [ProcName], [AssyItemSeq], [AssyItemName], [AssyItemNo], [AssySpec], [AssyUnitSeq], [AssyUnitName], [AssyQtyNumerator], [AssyQtyDenominator], [AssyQty], [MatItemSeq], [MatItemName], [MatItemNo], [MatSpec], [MatUnitSeq], [MatUnitName], [STDUnitSeq], [StdUnitName], [MatQtyNum], [MatQtyDen], [MatQty], [STDQty], [InLossRate], [InLossMatQty], [OutLossRate], [OutLossMatQty], [LastUserSeq], [LastDateTime], [Remark], [Memo1], [Memo2], [Memo3], [SMDelvType], [SMDelvTypeName], [BizUnit], [BizUnitName], [UptEmpSeq], [UptEmpName], [UptDate], [Location], [MasterRemark], [SubItemProcRev], [UserNo], [ItemSerl], [RegEmpName], [RegDate], [AssetName], [UMItemClassLName], [UMItemClassMName], [UMItemClassName], [MatAssetName], [MatUMItemClassLName], [MatUMItemClassMName], [MatUMItemClassName], [TimeUnitName], [WorkHour], [MESProcSeq], [MESProcName], [RAW_JSON])
  SELECT N'HQ', GETDATE(), @requestId, j.[ItemSeq], j.[ItemName], j.[ItemNo], j.[Spec], j.[UnitSeq], j.[UnitName], j.[ProcRev], j.[ProcSeq], j.[ProcName], j.[AssyItemSeq], j.[AssyItemName], j.[AssyItemNo], j.[AssySpec], j.[AssyUnitSeq], j.[AssyUnitName], j.[AssyQtyNumerator], j.[AssyQtyDenominator], j.[AssyQty], j.[MatItemSeq], j.[MatItemName], j.[MatItemNo], j.[MatSpec], j.[MatUnitSeq], j.[MatUnitName], j.[STDUnitSeq], j.[StdUnitName], j.[MatQtyNum], j.[MatQtyDen], j.[MatQty], j.[STDQty], j.[InLossRate], j.[InLossMatQty], j.[OutLossRate], j.[OutLossMatQty], j.[LastUserSeq], j.[LastDateTime], j.[Remark], j.[Memo1], j.[Memo2], j.[Memo3], j.[SMDelvType], j.[SMDelvTypeName], j.[BizUnit], j.[BizUnitName], j.[UptEmpSeq], j.[UptEmpName], j.[UptDate], j.[Location], j.[MasterRemark], j.[SubItemProcRev], j.[UserNo], j.[ItemSerl], j.[RegEmpName], j.[RegDate], j.[AssetName], j.[UMItemClassLName], j.[UMItemClassMName], j.[UMItemClassName], j.[MatAssetName], j.[MatUMItemClassLName], j.[MatUMItemClassMName], j.[MatUMItemClassName], j.[TimeUnitName], j.[WorkHour], j.[MESProcSeq], j.[MESProcName], j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    [ItemSeq] NVARCHAR(200) '$."ItemSeq"',
    [ItemName] NVARCHAR(200) '$."ItemName"',
    [ItemNo] NVARCHAR(200) '$."ItemNo"',
    [Spec] NVARCHAR(200) '$."Spec"',
    [UnitSeq] NVARCHAR(200) '$."UnitSeq"',
    [UnitName] NVARCHAR(200) '$."UnitName"',
    [ProcRev] NVARCHAR(200) '$."ProcRev"',
    [ProcSeq] NVARCHAR(200) '$."ProcSeq"',
    [ProcName] NVARCHAR(200) '$."ProcName"',
    [AssyItemSeq] NVARCHAR(200) '$."AssyItemSeq"',
    [AssyItemName] NVARCHAR(200) '$."AssyItemName"',
    [AssyItemNo] NVARCHAR(200) '$."AssyItemNo"',
    [AssySpec] NVARCHAR(200) '$."AssySpec"',
    [AssyUnitSeq] NVARCHAR(200) '$."AssyUnitSeq"',
    [AssyUnitName] NVARCHAR(200) '$."AssyUnitName"',
    [AssyQtyNumerator] NVARCHAR(200) '$."AssyQtyNumerator"',
    [AssyQtyDenominator] NVARCHAR(200) '$."AssyQtyDenominator"',
    [AssyQty] NVARCHAR(200) '$."AssyQty"',
    [MatItemSeq] NVARCHAR(200) '$."MatItemSeq"',
    [MatItemName] NVARCHAR(200) '$."MatItemName"',
    [MatItemNo] NVARCHAR(200) '$."MatItemNo"',
    [MatSpec] NVARCHAR(200) '$."MatSpec"',
    [MatUnitSeq] NVARCHAR(200) '$."MatUnitSeq"',
    [MatUnitName] NVARCHAR(200) '$."MatUnitName"',
    [STDUnitSeq] NVARCHAR(200) '$."STDUnitSeq"',
    [StdUnitName] NVARCHAR(200) '$."StdUnitName"',
    [MatQtyNum] NVARCHAR(200) '$."MatQtyNum"',
    [MatQtyDen] NVARCHAR(200) '$."MatQtyDen"',
    [MatQty] NVARCHAR(200) '$."MatQty"',
    [STDQty] NVARCHAR(200) '$."STDQty"',
    [InLossRate] NVARCHAR(200) '$."InLossRate"',
    [InLossMatQty] NVARCHAR(200) '$."InLossMatQty"',
    [OutLossRate] NVARCHAR(200) '$."OutLossRate"',
    [OutLossMatQty] NVARCHAR(200) '$."OutLossMatQty"',
    [LastUserSeq] NVARCHAR(200) '$."LastUserSeq"',
    [LastDateTime] NVARCHAR(200) '$."LastDateTime"',
    [Remark] NVARCHAR(200) '$."Remark"',
    [Memo1] NVARCHAR(200) '$."Memo1"',
    [Memo2] NVARCHAR(200) '$."Memo2"',
    [Memo3] NVARCHAR(200) '$."Memo3"',
    [SMDelvType] NVARCHAR(200) '$."SMDelvType"',
    [SMDelvTypeName] NVARCHAR(200) '$."SMDelvTypeName"',
    [BizUnit] NVARCHAR(200) '$."BizUnit"',
    [BizUnitName] NVARCHAR(200) '$."BizUnitName"',
    [UptEmpSeq] NVARCHAR(200) '$."UptEmpSeq"',
    [UptEmpName] NVARCHAR(200) '$."UptEmpName"',
    [UptDate] NVARCHAR(200) '$."UptDate"',
    [Location] NVARCHAR(200) '$."Location"',
    [MasterRemark] NVARCHAR(200) '$."MasterRemark"',
    [SubItemProcRev] NVARCHAR(200) '$."SubItemProcRev"',
    [UserNo] NVARCHAR(200) '$."UserNo"',
    [ItemSerl] NVARCHAR(200) '$."ItemSerl"',
    [RegEmpName] NVARCHAR(200) '$."RegEmpName"',
    [RegDate] NVARCHAR(200) '$."RegDate"',
    [AssetName] NVARCHAR(200) '$."AssetName"',
    [UMItemClassLName] NVARCHAR(200) '$."UMItemClassLName"',
    [UMItemClassMName] NVARCHAR(200) '$."UMItemClassMName"',
    [UMItemClassName] NVARCHAR(200) '$."UMItemClassName"',
    [MatAssetName] NVARCHAR(200) '$."MatAssetName"',
    [MatUMItemClassLName] NVARCHAR(200) '$."MatUMItemClassLName"',
    [MatUMItemClassMName] NVARCHAR(200) '$."MatUMItemClassMName"',
    [MatUMItemClassName] NVARCHAR(200) '$."MatUMItemClassName"',
    [TimeUnitName] NVARCHAR(200) '$."TimeUnitName"',
    [WorkHour] NVARCHAR(200) '$."WorkHour"',
    [MESProcSeq] NVARCHAR(200) '$."MESProcSeq"',
    [MESProcName] NVARCHAR(200) '$."MESProcName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_SALES @json NVARCHAR(MAX), @selCode NVARCHAR(10)=N'ACTUAL', @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_SALES WHERE SITE=N'HQ' AND SEL_CODE=@selCode;
  INSERT INTO DOI_HQ_IF_SALES ([SITE], [SEL_CODE], [LOAD_DTTM], [REQUEST_ID], [BizUnitName], [InvoiceSeq], [InvoiceDate], [InvoiceSerl], [InvoiceNo], [SMExpKind], [SMExpKindName], [UMOutKindName], [DeptName], [EmpName], [CustName], [CustNo], [CustSeq], [IsStockSales], [IsConsign], [ItemName], [ItemNo], [Spec], [UnitName], [CustPrice], [Qty], [IsInclusedVAT], [VATRate], [CurrSeq], [CurrName], [ExRate], [Price], [CurAmt], [CurVAT], [TotCurAmt], [DomAmt], [DomVAT], [TotDomAmt], [STDUnitName], [STDQty], [WHName], [RemarkM], [RemarkI], [SMProgressTypeName], [IsDelvCfm], [SMSalesCrtKind], [SMSalesCrtKindName], [BillCustSeq], [BillCustName], [SourceNo], [SourceRefNo], [IsReturn], [SalesQty], [SalesPrice], [CustItemName], [CustItemNo], [CustItemSpec], [UMEtcOutKind], [UMEtcOutKindName], [LotNo], [AssetName], [DVCondition], [DVPlace], [DVPlaceName], [BillAmt], [SMTransStatusName], [ItemClassSName], [ItemClassMName], [ItemClassLName], [BKCustName], [Dummy1], [Dummy2], [Dummy3], [Dummy4], [Dummy5], [Dummy6], [Dummy7], [Dummy8], [Dummy9], [Dummy10], [IsRetroactivity], [RetroactivityQty], [ChannelName], [Location], [PONo], [BizAddr], [SetInOutNo], [BizNo], [ItemDvDate], [RAW_JSON])
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.[BizUnitName], j.[InvoiceSeq], j.[InvoiceDate], j.[InvoiceSerl], j.[InvoiceNo], j.[SMExpKind], j.[SMExpKindName], j.[UMOutKindName], j.[DeptName], j.[EmpName], j.[CustName], j.[CustNo], j.[CustSeq], j.[IsStockSales], j.[IsConsign], j.[ItemName], j.[ItemNo], j.[Spec], j.[UnitName], j.[CustPrice], j.[Qty], j.[IsInclusedVAT], j.[VATRate], j.[CurrSeq], j.[CurrName], j.[ExRate], j.[Price], j.[CurAmt], j.[CurVAT], j.[TotCurAmt], j.[DomAmt], j.[DomVAT], j.[TotDomAmt], j.[STDUnitName], j.[STDQty], j.[WHName], j.[RemarkM], j.[RemarkI], j.[SMProgressTypeName], j.[IsDelvCfm], j.[SMSalesCrtKind], j.[SMSalesCrtKindName], j.[BillCustSeq], j.[BillCustName], j.[SourceNo], j.[SourceRefNo], j.[IsReturn], j.[SalesQty], j.[SalesPrice], j.[CustItemName], j.[CustItemNo], j.[CustItemSpec], j.[UMEtcOutKind], j.[UMEtcOutKindName], j.[LotNo], j.[AssetName], j.[DVCondition], j.[DVPlace], j.[DVPlaceName], j.[BillAmt], j.[SMTransStatusName], j.[ItemClassSName], j.[ItemClassMName], j.[ItemClassLName], j.[BKCustName], j.[Dummy1], j.[Dummy2], j.[Dummy3], j.[Dummy4], j.[Dummy5], j.[Dummy6], j.[Dummy7], j.[Dummy8], j.[Dummy9], j.[Dummy10], j.[IsRetroactivity], j.[RetroactivityQty], j.[ChannelName], j.[Location], j.[PONo], j.[BizAddr], j.[SetInOutNo], j.[BizNo], j.[ItemDvDate], j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    [BizUnitName] NVARCHAR(200) '$."BizUnitName"',
    [InvoiceSeq] NVARCHAR(200) '$."InvoiceSeq"',
    [InvoiceDate] NVARCHAR(200) '$."InvoiceDate"',
    [InvoiceSerl] NVARCHAR(200) '$."InvoiceSerl"',
    [InvoiceNo] NVARCHAR(200) '$."InvoiceNo"',
    [SMExpKind] NVARCHAR(200) '$."SMExpKind"',
    [SMExpKindName] NVARCHAR(200) '$."SMExpKindName"',
    [UMOutKindName] NVARCHAR(200) '$."UMOutKindName"',
    [DeptName] NVARCHAR(200) '$."DeptName"',
    [EmpName] NVARCHAR(200) '$."EmpName"',
    [CustName] NVARCHAR(200) '$."CustName"',
    [CustNo] NVARCHAR(200) '$."CustNo"',
    [CustSeq] NVARCHAR(200) '$."CustSeq"',
    [IsStockSales] NVARCHAR(200) '$."IsStockSales"',
    [IsConsign] NVARCHAR(200) '$."IsConsign"',
    [ItemName] NVARCHAR(200) '$."ItemName"',
    [ItemNo] NVARCHAR(200) '$."ItemNo"',
    [Spec] NVARCHAR(200) '$."Spec"',
    [UnitName] NVARCHAR(200) '$."UnitName"',
    [CustPrice] NVARCHAR(200) '$."CustPrice"',
    [Qty] NVARCHAR(200) '$."Qty"',
    [IsInclusedVAT] NVARCHAR(200) '$."IsInclusedVAT"',
    [VATRate] NVARCHAR(200) '$."VATRate"',
    [CurrSeq] NVARCHAR(200) '$."CurrSeq"',
    [CurrName] NVARCHAR(200) '$."CurrName"',
    [ExRate] NVARCHAR(200) '$."ExRate"',
    [Price] NVARCHAR(200) '$."Price"',
    [CurAmt] NVARCHAR(200) '$."CurAmt"',
    [CurVAT] NVARCHAR(200) '$."CurVAT"',
    [TotCurAmt] NVARCHAR(200) '$."TotCurAmt"',
    [DomAmt] NVARCHAR(200) '$."DomAmt"',
    [DomVAT] NVARCHAR(200) '$."DomVAT"',
    [TotDomAmt] NVARCHAR(200) '$."TotDomAmt"',
    [STDUnitName] NVARCHAR(200) '$."STDUnitName"',
    [STDQty] NVARCHAR(200) '$."STDQty"',
    [WHName] NVARCHAR(200) '$."WHName"',
    [RemarkM] NVARCHAR(200) '$."RemarkM"',
    [RemarkI] NVARCHAR(200) '$."RemarkI"',
    [SMProgressTypeName] NVARCHAR(200) '$."SMProgressTypeName"',
    [IsDelvCfm] NVARCHAR(200) '$."IsDelvCfm"',
    [SMSalesCrtKind] NVARCHAR(200) '$."SMSalesCrtKind"',
    [SMSalesCrtKindName] NVARCHAR(200) '$."SMSalesCrtKindName"',
    [BillCustSeq] NVARCHAR(200) '$."BillCustSeq"',
    [BillCustName] NVARCHAR(200) '$."BillCustName"',
    [SourceNo] NVARCHAR(200) '$."SourceNo"',
    [SourceRefNo] NVARCHAR(200) '$."SourceRefNo"',
    [IsReturn] NVARCHAR(200) '$."IsReturn"',
    [SalesQty] NVARCHAR(200) '$."SalesQty"',
    [SalesPrice] NVARCHAR(200) '$."SalesPrice"',
    [CustItemName] NVARCHAR(200) '$."CustItemName"',
    [CustItemNo] NVARCHAR(200) '$."CustItemNo"',
    [CustItemSpec] NVARCHAR(200) '$."CustItemSpec"',
    [UMEtcOutKind] NVARCHAR(200) '$."UMEtcOutKind"',
    [UMEtcOutKindName] NVARCHAR(200) '$."UMEtcOutKindName"',
    [LotNo] NVARCHAR(200) '$."LotNo"',
    [AssetName] NVARCHAR(200) '$."AssetName"',
    [DVCondition] NVARCHAR(200) '$."DVCondition"',
    [DVPlace] NVARCHAR(200) '$."DVPlace"',
    [DVPlaceName] NVARCHAR(200) '$."DVPlaceName"',
    [BillAmt] NVARCHAR(200) '$."BillAmt"',
    [SMTransStatusName] NVARCHAR(200) '$."SMTransStatusName"',
    [ItemClassSName] NVARCHAR(200) '$."ItemClassSName"',
    [ItemClassMName] NVARCHAR(200) '$."ItemClassMName"',
    [ItemClassLName] NVARCHAR(200) '$."ItemClassLName"',
    [BKCustName] NVARCHAR(200) '$."BKCustName"',
    [Dummy1] NVARCHAR(200) '$."Dummy1"',
    [Dummy2] NVARCHAR(200) '$."Dummy2"',
    [Dummy3] NVARCHAR(200) '$."Dummy3"',
    [Dummy4] NVARCHAR(200) '$."Dummy4"',
    [Dummy5] NVARCHAR(200) '$."Dummy5"',
    [Dummy6] NVARCHAR(200) '$."Dummy6"',
    [Dummy7] NVARCHAR(200) '$."Dummy7"',
    [Dummy8] NVARCHAR(200) '$."Dummy8"',
    [Dummy9] NVARCHAR(200) '$."Dummy9"',
    [Dummy10] NVARCHAR(200) '$."Dummy10"',
    [IsRetroactivity] NVARCHAR(200) '$."IsRetroactivity"',
    [RetroactivityQty] NVARCHAR(200) '$."RetroactivityQty"',
    [ChannelName] NVARCHAR(200) '$."ChannelName"',
    [Location] NVARCHAR(200) '$."Location"',
    [PONo] NVARCHAR(200) '$."PONo"',
    [BizAddr] NVARCHAR(200) '$."BizAddr"',
    [SetInOutNo] NVARCHAR(200) '$."SetInOutNo"',
    [BizNo] NVARCHAR(200) '$."BizNo"',
    [ItemDvDate] NVARCHAR(200) '$."ItemDvDate"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_STOCK_DETAIL @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_STOCK_DETAIL WHERE SITE=N'HQ' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_HQ_IF_STOCK_DETAIL (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, ItemNo, ItemName, Spec, UMItemClassSSeq, UMItemClassMSeq, UMItemClassLSeq, UMItemClassSName, UMItmeClassMName, UMItemClassLName, UMItemEtcClassSeq, UMItemEtcClassName, UnitName, ItemSeq, AssetName, PreQty, PreAmt, ProdQty, ProdAmt, BuyQty, BuyAmt, MvInQty, MvInAmt, EtcInQty, EtcInAmt, ExchangeInQty, ExchangeInAmt, SalesQty, SalesAmt, InputQty, InputAmt, PJTOutQty, PJTOutAmt, MvOutQty, MvOutAmt, EtcOutQty, EtcOutAmt, ExchangeOutQty, ExchangeOutAmt, InQty, OutAmt, InAmt, StockQty, OutQty, StockAmt, StockQty2, StockAmt2, DiffQty, DiffAmt, DivPrice, StkPrice, InputAccName, SalesAccName, AssetGroupName, AssetAccName, RAW_JSON)
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.ItemNo, j.ItemName, j.Spec, j.UMItemClassSSeq, j.UMItemClassMSeq, j.UMItemClassLSeq, j.UMItemClassSName, j.UMItmeClassMName, j.UMItemClassLName, j.UMItemEtcClassSeq, j.UMItemEtcClassName, j.UnitName, j.ItemSeq, j.AssetName, j.PreQty, j.PreAmt, j.ProdQty, j.ProdAmt, j.BuyQty, j.BuyAmt, j.MvInQty, j.MvInAmt, j.EtcInQty, j.EtcInAmt, j.ExchangeInQty, j.ExchangeInAmt, j.SalesQty, j.SalesAmt, j.InputQty, j.InputAmt, j.PJTOutQty, j.PJTOutAmt, j.MvOutQty, j.MvOutAmt, j.EtcOutQty, j.EtcOutAmt, j.ExchangeOutQty, j.ExchangeOutAmt, j.InQty, j.OutAmt, j.InAmt, j.StockQty, j.OutQty, j.StockAmt, j.StockQty2, j.StockAmt2, j.DiffQty, j.DiffAmt, j.DivPrice, j.StkPrice, j.InputAccName, j.SalesAccName, j.AssetGroupName, j.AssetAccName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    ItemNo NVARCHAR(100) '$."ItemNo"',
    ItemName NVARCHAR(100) '$."ItemName"',
    Spec NVARCHAR(100) '$."Spec"',
    UMItemClassSSeq INT '$."UMItemClassSSeq"',
    UMItemClassMSeq INT '$."UMItemClassMSeq"',
    UMItemClassLSeq INT '$."UMItemClassLSeq"',
    UMItemClassSName NVARCHAR(100) '$."UMItemClassSName"',
    UMItmeClassMName NVARCHAR(100) '$."UMItmeClassMName"',
    UMItemClassLName NVARCHAR(100) '$."UMItemClassLName"',
    UMItemEtcClassSeq INT '$."UMItemEtcClassSeq"',
    UMItemEtcClassName NVARCHAR(100) '$."UMItemEtcClassName"',
    UnitName NVARCHAR(100) '$."UnitName"',
    ItemSeq INT '$."ItemSeq"',
    AssetName NVARCHAR(100) '$."AssetName"',
    PreQty DECIMAL(19,5) '$."PreQty"',
    PreAmt DECIMAL(19,5) '$."PreAmt"',
    ProdQty DECIMAL(19,5) '$."ProdQty"',
    ProdAmt DECIMAL(19,5) '$."ProdAmt"',
    BuyQty DECIMAL(19,5) '$."BuyQty"',
    BuyAmt DECIMAL(19,5) '$."BuyAmt"',
    MvInQty DECIMAL(19,5) '$."MvInQty"',
    MvInAmt DECIMAL(19,5) '$."MvInAmt"',
    EtcInQty DECIMAL(19,5) '$."EtcInQty"',
    EtcInAmt DECIMAL(19,5) '$."EtcInAmt"',
    ExchangeInQty DECIMAL(19,5) '$."ExchangeInQty"',
    ExchangeInAmt DECIMAL(19,5) '$."ExchangeInAmt"',
    SalesQty DECIMAL(19,5) '$."SalesQty"',
    SalesAmt DECIMAL(19,5) '$."SalesAmt"',
    InputQty DECIMAL(19,5) '$."InputQty"',
    InputAmt DECIMAL(19,5) '$."InputAmt"',
    PJTOutQty DECIMAL(19,5) '$."PJTOutQty"',
    PJTOutAmt DECIMAL(19,5) '$."PJTOutAmt"',
    MvOutQty DECIMAL(19,5) '$."MvOutQty"',
    MvOutAmt DECIMAL(19,5) '$."MvOutAmt"',
    EtcOutQty DECIMAL(19,5) '$."EtcOutQty"',
    EtcOutAmt DECIMAL(19,5) '$."EtcOutAmt"',
    ExchangeOutQty DECIMAL(19,5) '$."ExchangeOutQty"',
    ExchangeOutAmt DECIMAL(19,5) '$."ExchangeOutAmt"',
    InQty DECIMAL(19,5) '$."InQty"',
    OutAmt DECIMAL(19,5) '$."OutAmt"',
    InAmt DECIMAL(19,5) '$."InAmt"',
    StockQty DECIMAL(19,5) '$."StockQty"',
    OutQty DECIMAL(19,5) '$."OutQty"',
    StockAmt DECIMAL(19,5) '$."StockAmt"',
    StockQty2 DECIMAL(19,5) '$."StockQty2"',
    StockAmt2 DECIMAL(19,5) '$."StockAmt2"',
    DiffQty DECIMAL(19,5) '$."DiffQty"',
    DiffAmt DECIMAL(19,5) '$."DiffAmt"',
    DivPrice DECIMAL(19,5) '$."DivPrice"',
    StkPrice DECIMAL(19,5) '$."StkPrice"',
    InputAccName NVARCHAR(100) '$."InputAccName"',
    SalesAccName NVARCHAR(100) '$."SalesAccName"',
    AssetGroupName NVARCHAR(100) '$."AssetGroupName"',
    AssetAccName NVARCHAR(100) '$."AssetAccName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_WH_STOCK_SUM @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_WH_STOCK_SUM WHERE SITE=N'HQ' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_HQ_IF_WH_STOCK_SUM (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, SMAssetGrpName, WHName, SMWHKindName, AssetName, ItemClassLName, ItemClassMName, ItemClassSName, ItemName, ItemNo, Spec, UnitName, SMStatusName, PrevQty, InQty, OutQty, StockQty, ItemSeq, UnitSeq, WHSeq, SMWHKind, Location, SafetyQty, CostWHName, IsLot, RAW_JSON)
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.SMAssetGrpName, j.WHName, j.SMWHKindName, j.AssetName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.ItemName, j.ItemNo, j.Spec, j.UnitName, j.SMStatusName, j.PrevQty, j.InQty, j.OutQty, j.StockQty, j.ItemSeq, j.UnitSeq, j.WHSeq, j.SMWHKind, j.Location, j.SafetyQty, j.CostWHName, j.IsLot, j.[RAW_JSON]
  -- ⚠️제품정보(창고별수불집계) 응답만 다블록: DataBlock2=Title메타, DataBlock3=품목수불 행.
  --   (나머지 8개 HQ 엔드포인트는 DataBlock1. 정의서_HQ '제품정보' 1.3/1.4 응답 샘플 기준)
  FROM OPENJSON(@json, '$.DataBlock3')
  WITH (
    SMAssetGrpName NVARCHAR(200) '$."SMAssetGrpName"',
    WHName NVARCHAR(200) '$."WHName"',
    SMWHKindName NVARCHAR(200) '$."SMWHKindName"',
    AssetName NVARCHAR(200) '$."AssetName"',
    ItemClassLName NVARCHAR(200) '$."ItemClassLName"',
    ItemClassMName NVARCHAR(200) '$."ItemClassMName"',
    ItemClassSName NVARCHAR(200) '$."ItemClassSName"',
    ItemName NVARCHAR(200) '$."ItemName"',
    ItemNo NVARCHAR(200) '$."ItemNo"',
    Spec NVARCHAR(200) '$."Spec"',
    UnitName NVARCHAR(200) '$."UnitName"',
    SMStatusName NVARCHAR(200) '$."SMStatusName"',
    PrevQty NVARCHAR(200) '$."PrevQty"',
    InQty NVARCHAR(200) '$."InQty"',
    OutQty NVARCHAR(200) '$."OutQty"',
    StockQty NVARCHAR(200) '$."StockQty"',
    ItemSeq NVARCHAR(200) '$."ItemSeq"',
    UnitSeq NVARCHAR(200) '$."UnitSeq"',
    WHSeq NVARCHAR(200) '$."WHSeq"',
    SMWHKind NVARCHAR(200) '$."SMWHKind"',
    Location NVARCHAR(200) '$."Location"',
    SafetyQty NVARCHAR(200) '$."SafetyQty"',
    CostWHName NVARCHAR(200) '$."CostWHName"',
    IsLot NVARCHAR(200) '$."IsLot"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ACCLANG @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ACCLANG WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_ACCLANG (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, FSItemNo, FSItemName, RowIDX, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.FSItemNo, j.FSItemName, j.RowIDX, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    FSItemNo NVARCHAR(100) '$."FSItemNo"',
    FSItemName NVARCHAR(100) '$."FSItemName"',
    RowIDX INT '$."RowIDX"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

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
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_BIZ_STOCK_SUM @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_BIZ_STOCK_SUM WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_BIZ_STOCK_SUM (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, Title, TitleSeq, Title2, TitleSeq2, BizUnit, BizUnitName, AssetName, SMAssetGrpName, ItemClassLName, ItemClassMName, ItemClassSName, ItemName, ItemNo, Spec, UnitName, SMStatusName, ItemSeq, UnitSeq, PrevQty, InQty, OutQty, StockQty, RowIDX, ColIDX, Qty, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.Title, j.TitleSeq, j.Title2, j.TitleSeq2, j.BizUnit, j.BizUnitName, j.AssetName, j.SMAssetGrpName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.ItemName, j.ItemNo, j.Spec, j.UnitName, j.SMStatusName, j.ItemSeq, j.UnitSeq, j.PrevQty, j.InQty, j.OutQty, j.StockQty, j.RowIDX, j.ColIDX, j.Qty, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    Title NVARCHAR(100) '$."Title"',
    TitleSeq INT '$."TitleSeq"',
    Title2 NVARCHAR(100) '$."Title2"',
    TitleSeq2 INT '$."TitleSeq2"',
    BizUnit INT '$."BizUnit"',
    BizUnitName NVARCHAR(100) '$."BizUnitName"',
    AssetName NVARCHAR(100) '$."AssetName"',
    SMAssetGrpName NVARCHAR(100) '$."SMAssetGrpName"',
    ItemClassLName NVARCHAR(100) '$."ItemClassLName"',
    ItemClassMName NVARCHAR(100) '$."ItemClassMName"',
    ItemClassSName NVARCHAR(100) '$."ItemClassSName"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemNo NVARCHAR(100) '$."ItemNo"',
    Spec NVARCHAR(100) '$."Spec"',
    UnitName NVARCHAR(100) '$."UnitName"',
    SMStatusName NVARCHAR(100) '$."SMStatusName"',
    ItemSeq INT '$."ItemSeq"',
    UnitSeq INT '$."UnitSeq"',
    PrevQty DECIMAL(19,5) '$."PrevQty"',
    InQty DECIMAL(19,5) '$."InQty"',
    OutQty DECIMAL(19,5) '$."OutQty"',
    StockQty DECIMAL(19,5) '$."StockQty"',
    RowIDX INT '$."RowIDX"',
    ColIDX INT '$."ColIDX"',
    Qty DECIMAL(19,5) '$."Qty"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

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
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_DEPT_COST @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_DEPT_COST WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_DEPT_COST (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, CCtrName, DeptSeq, AccNameCost, AccNo, AccName, UMCostTypeName, AccSeq, DrAmt, CrAmt, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.CCtrName, j.DeptSeq, j.AccNameCost, j.AccNo, j.AccName, j.UMCostTypeName, j.AccSeq, j.DrAmt, j.CrAmt, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    CCtrName NVARCHAR(100) '$."CCtrName"',
    DeptSeq INT '$."DeptSeq"',
    AccNameCost NVARCHAR(100) '$."AccNameCost"',
    AccNo NVARCHAR(100) '$."AccNo"',
    AccName NVARCHAR(100) '$."AccName"',
    UMCostTypeName NVARCHAR(100) '$."UMCostTypeName"',
    AccSeq INT '$."AccSeq"',
    DrAmt DECIMAL(19,5) '$."DrAmt"',
    CrAmt DECIMAL(19,5) '$."CrAmt"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ETC_INOUT @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ETC_INOUT WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_ETC_INOUT (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, InOutDate, InOutName, UMEtcOutKindSource, UMEtcOutKindDetail, AssetName, UMItemClassLName, UMItemClassMName, UMItemClassSName, ItemName, ItemNo, Spec, UnitName, SMAdjustKindName, EtcOutQty, EtcOutAmt, EtcOutPrice, AccName, WHName, DeptName, Remark, ItemRemark, CustName, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.InOutDate, j.InOutName, j.UMEtcOutKindSource, j.UMEtcOutKindDetail, j.AssetName, j.UMItemClassLName, j.UMItemClassMName, j.UMItemClassSName, j.ItemName, j.ItemNo, j.Spec, j.UnitName, j.SMAdjustKindName, j.EtcOutQty, j.EtcOutAmt, j.EtcOutPrice, j.AccName, j.WHName, j.DeptName, j.Remark, j.ItemRemark, j.CustName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    InOutDate NVARCHAR(200) '$."InOutDate"',
    InOutName NVARCHAR(200) '$."InOutName"',
    UMEtcOutKindSource NVARCHAR(200) '$."UMEtcOutKindSource"',
    UMEtcOutKindDetail NVARCHAR(200) '$."UMEtcOutKindDetail"',
    AssetName NVARCHAR(200) '$."AssetName"',
    UMItemClassLName NVARCHAR(200) '$."UMItemClassLName"',
    UMItemClassMName NVARCHAR(200) '$."UMItemClassMName"',
    UMItemClassSName NVARCHAR(200) '$."UMItemClassSName"',
    ItemName NVARCHAR(200) '$."ItemName"',
    ItemNo NVARCHAR(200) '$."ItemNo"',
    Spec NVARCHAR(200) '$."Spec"',
    UnitName NVARCHAR(200) '$."UnitName"',
    SMAdjustKindName NVARCHAR(200) '$."SMAdjustKindName"',
    EtcOutQty NVARCHAR(200) '$."EtcOutQty"',
    EtcOutAmt NVARCHAR(200) '$."EtcOutAmt"',
    EtcOutPrice NVARCHAR(200) '$."EtcOutPrice"',
    AccName NVARCHAR(200) '$."AccName"',
    WHName NVARCHAR(200) '$."WHName"',
    DeptName NVARCHAR(200) '$."DeptName"',
    Remark NVARCHAR(200) '$."Remark"',
    ItemRemark NVARCHAR(200) '$."ItemRemark"',
    CustName NVARCHAR(200) '$."CustName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_EXP_CLAIM @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_EXP_CLAIM WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_EXP_CLAIM (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, BizUnitName, BizUnit, ClaimNo, ClaimSeq, ClaimSerl, ClaimDate, SMExpKindName, UMOutKindName, SMConsignKind, SMConsignKindName, DeptName, EmpName, CustName, CustSeq, CustNo, CurrSeq, CurrName, ExRate, ItemSeq, ItemName, ItemNo, Spec, UnitSeq, UnitName, Qty, Price, ItemPrice, CustPrice, VATRate, CurAmt, CurVAT, DomAmt, DomVAT, StdUnitSeq, StdUnitName, StdQty, BKCustName, DVDateM, Remark, BLDate, BLNo, BLRefNo, PermitDate, PermitNo, PermitRefNo, SalesNo, SlipID, SMProgressReturnTypeName, SMProgressTypeName, SMExpKind, SlipSeq, SourceNo, SourceRefNo, ISPJT, LotNo, RemarkM, Memo, LastUserName, LastDateTime, WHName, BLPrice, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.BizUnitName, j.BizUnit, j.ClaimNo, j.ClaimSeq, j.ClaimSerl, j.ClaimDate, j.SMExpKindName, j.UMOutKindName, j.SMConsignKind, j.SMConsignKindName, j.DeptName, j.EmpName, j.CustName, j.CustSeq, j.CustNo, j.CurrSeq, j.CurrName, j.ExRate, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.UnitSeq, j.UnitName, j.Qty, j.Price, j.ItemPrice, j.CustPrice, j.VATRate, j.CurAmt, j.CurVAT, j.DomAmt, j.DomVAT, j.StdUnitSeq, j.StdUnitName, j.StdQty, j.BKCustName, j.DVDateM, j.Remark, j.BLDate, j.BLNo, j.BLRefNo, j.PermitDate, j.PermitNo, j.PermitRefNo, j.SalesNo, j.SlipID, j.SMProgressReturnTypeName, j.SMProgressTypeName, j.SMExpKind, j.SlipSeq, j.SourceNo, j.SourceRefNo, j.ISPJT, j.LotNo, j.RemarkM, j.Memo, j.LastUserName, j.LastDateTime, j.WHName, j.BLPrice, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    BizUnitName NVARCHAR(100) '$."BizUnitName"',
    BizUnit INT '$."BizUnit"',
    ClaimNo NVARCHAR(100) '$."ClaimNo"',
    ClaimSeq INT '$."ClaimSeq"',
    ClaimSerl INT '$."ClaimSerl"',
    ClaimDate NCHAR(8) '$."ClaimDate"',
    SMExpKindName NVARCHAR(100) '$."SMExpKindName"',
    UMOutKindName NVARCHAR(100) '$."UMOutKindName"',
    SMConsignKind INT '$."SMConsignKind"',
    SMConsignKindName NVARCHAR(100) '$."SMConsignKindName"',
    DeptName NVARCHAR(100) '$."DeptName"',
    EmpName NVARCHAR(100) '$."EmpName"',
    CustName NVARCHAR(100) '$."CustName"',
    CustSeq INT '$."CustSeq"',
    CustNo NVARCHAR(100) '$."CustNo"',
    CurrSeq INT '$."CurrSeq"',
    CurrName NVARCHAR(100) '$."CurrName"',
    ExRate DECIMAL(19,5) '$."ExRate"',
    ItemSeq INT '$."ItemSeq"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemNo NVARCHAR(100) '$."ItemNo"',
    Spec NVARCHAR(100) '$."Spec"',
    UnitSeq INT '$."UnitSeq"',
    UnitName NVARCHAR(100) '$."UnitName"',
    Qty DECIMAL(19,5) '$."Qty"',
    Price DECIMAL(19,5) '$."Price"',
    ItemPrice DECIMAL(19,5) '$."ItemPrice"',
    CustPrice DECIMAL(19,5) '$."CustPrice"',
    VATRate DECIMAL(19,5) '$."VATRate"',
    CurAmt DECIMAL(19,5) '$."CurAmt"',
    CurVAT DECIMAL(19,5) '$."CurVAT"',
    DomAmt DECIMAL(19,5) '$."DomAmt"',
    DomVAT DECIMAL(19,5) '$."DomVAT"',
    StdUnitSeq INT '$."StdUnitSeq"',
    StdUnitName NVARCHAR(100) '$."StdUnitName"',
    StdQty DECIMAL(19,5) '$."StdQty"',
    BKCustName NVARCHAR(100) '$."BKCustName"',
    DVDateM NVARCHAR(100) '$."DVDateM"',
    Remark NVARCHAR(100) '$."Remark"',
    BLDate NCHAR(8) '$."BLDate"',
    BLNo NVARCHAR(100) '$."BLNo"',
    BLRefNo NVARCHAR(100) '$."BLRefNo"',
    PermitDate NCHAR(8) '$."PermitDate"',
    PermitNo NVARCHAR(100) '$."PermitNo"',
    PermitRefNo NVARCHAR(100) '$."PermitRefNo"',
    SalesNo NVARCHAR(100) '$."SalesNo"',
    SlipID NVARCHAR(100) '$."SlipID"',
    SMProgressReturnTypeName NVARCHAR(100) '$."SMProgressReturnTypeName"',
    SMProgressTypeName NVARCHAR(100) '$."SMProgressTypeName"',
    SMExpKind INT '$."SMExpKind"',
    SlipSeq INT '$."SlipSeq"',
    SourceNo NVARCHAR(100) '$."SourceNo"',
    SourceRefNo NVARCHAR(100) '$."SourceRefNo"',
    ISPJT NCHAR(1) '$."ISPJT"',
    LotNo NVARCHAR(100) '$."LotNo"',
    RemarkM NVARCHAR(100) '$."RemarkM"',
    Memo NVARCHAR(100) '$."Memo"',
    LastUserName NVARCHAR(100) '$."LastUserName"',
    LastDateTime NVARCHAR(200) '$."LastDateTime"',
    WHName NVARCHAR(100) '$."WHName"',
    BLPrice DECIMAL(19,5) '$."BLPrice"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_EXP_PERMIT @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_EXP_PERMIT WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_EXP_PERMIT (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, BizUnit, BizUnitName, PermitDate, PermitNo, PermitRefNo, SMExpKind, SMExpKindName, CustSeq, CustName, CustNo, CurrSeq, CurrName, UMPriceTerms, UMPriceTermsName, DeptSeq, DeptName, PermitType, PermitTypeName, EmpSeq, ExRate, EmpName, ItemSeq, ItemName, ItemNo, Spec, UnitSeq, UnitName, Qty, FOBPrice, DomPrice, CurAmt, DomAmt, FOBDomAmt, Remark, RemarkI, UMEtcOutkind, UMEtcOutkindName, SMProgressTypeName, SalesAmt, InvoiceRefNo, SourceNo, SourceRefNo, SMSalesProgTypeName, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.BizUnit, j.BizUnitName, j.PermitDate, j.PermitNo, j.PermitRefNo, j.SMExpKind, j.SMExpKindName, j.CustSeq, j.CustName, j.CustNo, j.CurrSeq, j.CurrName, j.UMPriceTerms, j.UMPriceTermsName, j.DeptSeq, j.DeptName, j.PermitType, j.PermitTypeName, j.EmpSeq, j.ExRate, j.EmpName, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.UnitSeq, j.UnitName, j.Qty, j.FOBPrice, j.DomPrice, j.CurAmt, j.DomAmt, j.FOBDomAmt, j.Remark, j.RemarkI, j.UMEtcOutkind, j.UMEtcOutkindName, j.SMProgressTypeName, j.SalesAmt, j.InvoiceRefNo, j.SourceNo, j.SourceRefNo, j.SMSalesProgTypeName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    BizUnit NVARCHAR(200) '$."BizUnit"',
    BizUnitName NVARCHAR(200) '$."BizUnitName"',
    PermitDate NVARCHAR(200) '$."PermitDate"',
    PermitNo NVARCHAR(200) '$."PermitNo"',
    PermitRefNo NVARCHAR(200) '$."PermitRefNo"',
    SMExpKind NVARCHAR(200) '$."SMExpKind"',
    SMExpKindName NVARCHAR(200) '$."SMExpKindName"',
    CustSeq NVARCHAR(200) '$."CustSeq"',
    CustName NVARCHAR(200) '$."CustName"',
    CustNo NVARCHAR(200) '$."CustNo"',
    CurrSeq NVARCHAR(200) '$."CurrSeq"',
    CurrName NVARCHAR(200) '$."CurrName"',
    UMPriceTerms NVARCHAR(200) '$."UMPriceTerms"',
    UMPriceTermsName NVARCHAR(200) '$."UMPriceTermsName"',
    DeptSeq NVARCHAR(200) '$."DeptSeq"',
    DeptName NVARCHAR(200) '$."DeptName"',
    PermitType NVARCHAR(200) '$."PermitType"',
    PermitTypeName NVARCHAR(200) '$."PermitTypeName"',
    EmpSeq NVARCHAR(200) '$."EmpSeq"',
    ExRate NVARCHAR(200) '$."ExRate"',
    EmpName NVARCHAR(200) '$."EmpName"',
    ItemSeq NVARCHAR(200) '$."ItemSeq"',
    ItemName NVARCHAR(200) '$."ItemName"',
    ItemNo NVARCHAR(200) '$."ItemNo"',
    Spec NVARCHAR(200) '$."Spec"',
    UnitSeq NVARCHAR(200) '$."UnitSeq"',
    UnitName NVARCHAR(200) '$."UnitName"',
    Qty NVARCHAR(200) '$."Qty"',
    FOBPrice NVARCHAR(200) '$."FOBPrice"',
    DomPrice NVARCHAR(200) '$."DomPrice"',
    CurAmt NVARCHAR(200) '$."CurAmt"',
    DomAmt NVARCHAR(200) '$."DomAmt"',
    FOBDomAmt NVARCHAR(200) '$."FOBDomAmt"',
    Remark NVARCHAR(200) '$."Remark"',
    RemarkI NVARCHAR(200) '$."RemarkI"',
    UMEtcOutkind NVARCHAR(200) '$."UMEtcOutkind"',
    UMEtcOutkindName NVARCHAR(200) '$."UMEtcOutkindName"',
    SMProgressTypeName NVARCHAR(200) '$."SMProgressTypeName"',
    SalesAmt NVARCHAR(200) '$."SalesAmt"',
    InvoiceRefNo NVARCHAR(200) '$."InvoiceRefNo"',
    SourceNo NVARCHAR(200) '$."SourceNo"',
    SourceRefNo NVARCHAR(200) '$."SourceRefNo"',
    SMSalesProgTypeName NVARCHAR(200) '$."SMSalesProgTypeName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_EXP_SALES @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_EXP_SALES WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_EXP_SALES (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, BizUnit, BizUnitName, SMExpKind, SMExpKindName, DeptSeq, DeptName, EmpSeq, EmpName, CustSeq, CustName, ItemSeq, ItemName, ItemNo, Spec, UnitSeq, UnitName, ItemPrice, CustPrice, Qty, Price, CurAmt, DomAmt, WHSeq, WHName, RemarkM, AccSeq, AccName, UMPriceTerms, UMPriceTermsName, CurrName, ExRate, RemarkI, InvoiceRefNo, UMChannelName, InvoiceDate, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.BizUnit, j.BizUnitName, j.SMExpKind, j.SMExpKindName, j.DeptSeq, j.DeptName, j.EmpSeq, j.EmpName, j.CustSeq, j.CustName, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.UnitSeq, j.UnitName, j.ItemPrice, j.CustPrice, j.Qty, j.Price, j.CurAmt, j.DomAmt, j.WHSeq, j.WHName, j.RemarkM, j.AccSeq, j.AccName, j.UMPriceTerms, j.UMPriceTermsName, j.CurrName, j.ExRate, j.RemarkI, j.InvoiceRefNo, j.UMChannelName, j.InvoiceDate, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    BizUnit INT '$."BizUnit"',
    BizUnitName NVARCHAR(100) '$."BizUnitName"',
    SMExpKind INT '$."SMExpKind"',
    SMExpKindName NVARCHAR(100) '$."SMExpKindName"',
    DeptSeq INT '$."DeptSeq"',
    DeptName NVARCHAR(100) '$."DeptName"',
    EmpSeq INT '$."EmpSeq"',
    EmpName NVARCHAR(100) '$."EmpName"',
    CustSeq INT '$."CustSeq"',
    CustName NVARCHAR(100) '$."CustName"',
    ItemSeq INT '$."ItemSeq"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemNo NVARCHAR(100) '$."ItemNo"',
    Spec NVARCHAR(100) '$."Spec"',
    UnitSeq INT '$."UnitSeq"',
    UnitName NVARCHAR(100) '$."UnitName"',
    ItemPrice DECIMAL(19,5) '$."ItemPrice"',
    CustPrice DECIMAL(19,5) '$."CustPrice"',
    Qty DECIMAL(19,5) '$."Qty"',
    Price DECIMAL(19,5) '$."Price"',
    CurAmt DECIMAL(19,5) '$."CurAmt"',
    DomAmt DECIMAL(19,5) '$."DomAmt"',
    WHSeq INT '$."WHSeq"',
    WHName NVARCHAR(100) '$."WHName"',
    RemarkM NVARCHAR(100) '$."RemarkM"',
    AccSeq INT '$."AccSeq"',
    AccName NVARCHAR(100) '$."AccName"',
    UMPriceTerms NVARCHAR(100) '$."UMPriceTerms"',
    UMPriceTermsName NVARCHAR(100) '$."UMPriceTermsName"',
    CurrName NVARCHAR(100) '$."CurrName"',
    ExRate DECIMAL(19,5) '$."ExRate"',
    RemarkI NVARCHAR(100) '$."RemarkI"',
    InvoiceRefNo NVARCHAR(100) '$."InvoiceRefNo"',
    UMChannelName NVARCHAR(100) '$."UMChannelName"',
    InvoiceDate NCHAR(8) '$."InvoiceDate"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_FG_SUBUL @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_FG_SUBUL WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_FG_SUBUL (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, factory, work_date, mat_id, boh_ok_mes, normal_last_month, normal_this_month, backship_sorting, backship_pfrw, backship_plrw, wh_rt_sorting, wh_rt_pfrw, wh_rt_plrw, etc_input, back_ship_ng_qty, total_wh_input, other_input_total, shipped_level_a_paid, shipped_level_a_free, shipped_level_b_paid, shipped_level_b_free, t_output_3, line_transfer_total, etc_output, line_transfer_rework, line_transfer_sorting, other_output_total, total_out_qty, eoh_ok_mes, loss_spare, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.factory, j.work_date, j.mat_id, j.boh_ok_mes, j.normal_last_month, j.normal_this_month, j.backship_sorting, j.backship_pfrw, j.backship_plrw, j.wh_rt_sorting, j.wh_rt_pfrw, j.wh_rt_plrw, j.etc_input, j.back_ship_ng_qty, j.total_wh_input, j.other_input_total, j.shipped_level_a_paid, j.shipped_level_a_free, j.shipped_level_b_paid, j.shipped_level_b_free, j.t_output_3, j.line_transfer_total, j.etc_output, j.line_transfer_rework, j.line_transfer_sorting, j.other_output_total, j.total_out_qty, j.eoh_ok_mes, j.loss_spare, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.data.rows')
  WITH (
    factory VARCHAR(10) '$."factory"',
    work_date VARCHAR(8) '$."work_date"',
    mat_id VARCHAR(30) '$."mat_id"',
    boh_ok_mes INT '$."boh_ok_mes"',
    normal_last_month INT '$."normal_last_month"',
    normal_this_month INT '$."normal_this_month"',
    backship_sorting INT '$."backship_sorting"',
    backship_pfrw INT '$."backship_pfrw"',
    backship_plrw INT '$."backship_plrw"',
    wh_rt_sorting INT '$."wh_rt_sorting"',
    wh_rt_pfrw INT '$."wh_rt_pfrw"',
    wh_rt_plrw INT '$."wh_rt_plrw"',
    etc_input INT '$."etc_input"',
    back_ship_ng_qty INT '$."back_ship_ng_qty"',
    total_wh_input INT '$."total_wh_input"',
    other_input_total INT '$."other_input_total"',
    shipped_level_a_paid INT '$."shipped_level_a_paid"',
    shipped_level_a_free INT '$."shipped_level_a_free"',
    shipped_level_b_paid INT '$."shipped_level_b_paid"',
    shipped_level_b_free INT '$."shipped_level_b_free"',
    t_output_3 INT '$."t_output_3"',
    line_transfer_total INT '$."line_transfer_total"',
    etc_output INT '$."etc_output"',
    line_transfer_rework INT '$."line_transfer_rework"',
    line_transfer_sorting INT '$."line_transfer_sorting"',
    other_output_total INT '$."other_output_total"',
    total_out_qty INT '$."total_out_qty"',
    eoh_ok_mes INT '$."eoh_ok_mes"',
    loss_spare INT '$."loss_spare"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

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
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ITEM_INPUT @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ITEM_INPUT WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_ITEM_INPUT (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, ItemNo, ItemName, ItemSpec, ProcName, MatNo, MatName, Spec, InputQty, WorkOrderSeq, WorkOrderNo, Price, Amt, InputAcc, InputCost, AssetName, MatAssetName, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.ItemNo, j.ItemName, j.ItemSpec, j.ProcName, j.MatNo, j.MatName, j.Spec, j.InputQty, j.WorkOrderSeq, j.WorkOrderNo, j.Price, j.Amt, j.InputAcc, j.InputCost, j.AssetName, j.MatAssetName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    ItemNo NVARCHAR(100) '$."ItemNo"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemSpec NVARCHAR(100) '$."ItemSpec"',
    ProcName NVARCHAR(100) '$."ProcName"',
    MatNo NVARCHAR(100) '$."MatNo"',
    MatName NVARCHAR(100) '$."MatName"',
    Spec NVARCHAR(100) '$."Spec"',
    InputQty DECIMAL(19,5) '$."InputQty"',
    WorkOrderSeq INT '$."WorkOrderSeq"',
    WorkOrderNo NVARCHAR(100) '$."WorkOrderNo"',
    Price DECIMAL(19,5) '$."Price"',
    Amt DECIMAL(19,5) '$."Amt"',
    InputAcc NVARCHAR(100) '$."InputAcc"',
    InputCost NVARCHAR(100) '$."InputCost"',
    AssetName NVARCHAR(100) '$."AssetName"',
    MatAssetName NVARCHAR(100) '$."MatAssetName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ITEM_PROC_MAT @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_ITEM_PROC_MAT WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_ITEM_PROC_MAT (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, ItemSeq, ItemName, ItemNo, Spec, UnitSeq, UnitName, ProcRev, ProcSeq, ProcName, AssyItemSeq, AssyItemName, AssyItemNo, AssySpec, AssyUnitSeq, AssyUnitName, AssyQty, MatItemSeq, MatItemName, MatItemNo, MatSpec, MatUnitSeq, MatUnitName, STDUnitSeq, STDUnitName, MatQtyNum, MatQtyDen, MatQty, STDQty, InLossRate, InLossMatQty, OutLossRate, OutLossMatQty, LastDateTime, Remark, Memo1, Memo2, Memo3, SMDelvType, SMDelvTypeName, BizUnit, BizUnitName, UptEmpSeq, UptEmpName, UptDate, Location, MasterRemark, SubItemProcRev, UserNo, ItemSerl, RegEmpName, RegDate, AssetName, UMItemClassLName, UMItemClassMName, UMItemClassName, MatAssetName, MatUMItemClassLName, MatUMItemClassMName, MatUMItemClassName, TimeUnitName, WorkHour, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.ItemSeq, j.ItemName, j.ItemNo, j.Spec, j.UnitSeq, j.UnitName, j.ProcRev, j.ProcSeq, j.ProcName, j.AssyItemSeq, j.AssyItemName, j.AssyItemNo, j.AssySpec, j.AssyUnitSeq, j.AssyUnitName, j.AssyQty, j.MatItemSeq, j.MatItemName, j.MatItemNo, j.MatSpec, j.MatUnitSeq, j.MatUnitName, j.STDUnitSeq, j.STDUnitName, j.MatQtyNum, j.MatQtyDen, j.MatQty, j.STDQty, j.InLossRate, j.InLossMatQty, j.OutLossRate, j.OutLossMatQty, j.LastDateTime, j.Remark, j.Memo1, j.Memo2, j.Memo3, j.SMDelvType, j.SMDelvTypeName, j.BizUnit, j.BizUnitName, j.UptEmpSeq, j.UptEmpName, j.UptDate, j.Location, j.MasterRemark, j.SubItemProcRev, j.UserNo, j.ItemSerl, j.RegEmpName, j.RegDate, j.AssetName, j.UMItemClassLName, j.UMItemClassMName, j.UMItemClassName, j.MatAssetName, j.MatUMItemClassLName, j.MatUMItemClassMName, j.MatUMItemClassName, j.TimeUnitName, j.WorkHour, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    ItemSeq INT '$."ItemSeq"',
    ItemName NVARCHAR(100) '$."ItemName"',
    ItemNo NVARCHAR(100) '$."ItemNo"',
    Spec NVARCHAR(100) '$."Spec"',
    UnitSeq INT '$."UnitSeq"',
    UnitName NVARCHAR(100) '$."UnitName"',
    ProcRev NVARCHAR(100) '$."ProcRev"',
    ProcSeq INT '$."ProcSeq"',
    ProcName NVARCHAR(100) '$."ProcName"',
    AssyItemSeq INT '$."AssyItemSeq"',
    AssyItemName NVARCHAR(100) '$."AssyItemName"',
    AssyItemNo NVARCHAR(100) '$."AssyItemNo"',
    AssySpec NVARCHAR(100) '$."AssySpec"',
    AssyUnitSeq INT '$."AssyUnitSeq"',
    AssyUnitName NVARCHAR(100) '$."AssyUnitName"',
    AssyQty NVARCHAR(200) '$."AssyQty"',
    MatItemSeq INT '$."MatItemSeq"',
    MatItemName NVARCHAR(100) '$."MatItemName"',
    MatItemNo NVARCHAR(100) '$."MatItemNo"',
    MatSpec NVARCHAR(100) '$."MatSpec"',
    MatUnitSeq INT '$."MatUnitSeq"',
    MatUnitName NVARCHAR(100) '$."MatUnitName"',
    STDUnitSeq INT '$."STDUnitSeq"',
    STDUnitName NVARCHAR(100) '$."STDUnitName"',
    MatQtyNum NVARCHAR(200) '$."MatQtyNum"',
    MatQtyDen NVARCHAR(200) '$."MatQtyDen"',
    MatQty NVARCHAR(200) '$."MatQty"',
    STDQty NVARCHAR(200) '$."STDQty"',
    InLossRate NVARCHAR(200) '$."InLossRate"',
    InLossMatQty NVARCHAR(200) '$."InLossMatQty"',
    OutLossRate NVARCHAR(200) '$."OutLossRate"',
    OutLossMatQty NVARCHAR(200) '$."OutLossMatQty"',
    LastDateTime NVARCHAR(200) '$."LastDateTime"',
    Remark NVARCHAR(100) '$."Remark"',
    Memo1 NVARCHAR(100) '$."Memo1"',
    Memo2 NVARCHAR(100) '$."Memo2"',
    Memo3 NVARCHAR(100) '$."Memo3"',
    SMDelvType INT '$."SMDelvType"',
    SMDelvTypeName NVARCHAR(100) '$."SMDelvTypeName"',
    BizUnit INT '$."BizUnit"',
    BizUnitName NVARCHAR(100) '$."BizUnitName"',
    UptEmpSeq INT '$."UptEmpSeq"',
    UptEmpName NVARCHAR(100) '$."UptEmpName"',
    UptDate NCHAR(1) '$."UptDate"',
    Location NVARCHAR(100) '$."Location"',
    MasterRemark NVARCHAR(100) '$."MasterRemark"',
    SubItemProcRev NVARCHAR(100) '$."SubItemProcRev"',
    UserNo NVARCHAR(100) '$."UserNo"',
    ItemSerl NVARCHAR(200) '$."ItemSerl"',
    RegEmpName NVARCHAR(100) '$."RegEmpName"',
    RegDate NCHAR(8) '$."RegDate"',
    AssetName NVARCHAR(100) '$."AssetName"',
    UMItemClassLName NVARCHAR(100) '$."UMItemClassLName"',
    UMItemClassMName NVARCHAR(100) '$."UMItemClassMName"',
    UMItemClassName NVARCHAR(100) '$."UMItemClassName"',
    MatAssetName NVARCHAR(100) '$."MatAssetName"',
    MatUMItemClassLName NVARCHAR(100) '$."MatUMItemClassLName"',
    MatUMItemClassMName NVARCHAR(100) '$."MatUMItemClassMName"',
    MatUMItemClassName NVARCHAR(100) '$."MatUMItemClassName"',
    TimeUnitName NVARCHAR(100) '$."TimeUnitName"',
    WorkHour NVARCHAR(100) '$."WorkHour"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

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
GO

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
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_STOCK_DETAIL @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_STOCK_DETAIL WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_STOCK_DETAIL (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, ItemNo, ItemName, Spec, UMItemClassSSeq, UMItemClassMSeq, UMItemClassLSeq, UMItemClassSName, UMItmeClassMName, UMItemClassLName, UMItemEtcClassSeq, UMItemEtcClassName, UnitName, ItemSeq, AssetName, PreQty, PreAmt, ProdQty, ProdAmt, BuyQty, BuyAmt, MvInQty, MvInAmt, EtcInQty, EtcInAmt, ExchangeInQty, ExchangeInAmt, SalesQty, SalesAmt, InputQty, InputAmt, PJTOutQty, PJTOutAmt, MvOutQty, MvOutAmt, EtcOutQty, EtcOutAmt, ExchangeOutQty, ExchangeOutAmt, InQty, OutAmt, InAmt, StockQty, OutQty, StockAmt, StockQty2, StockAmt2, DiffQty, DiffAmt, DivPrice, StkPrice, InputAccName, SalesAccName, AssetGroupName, AssetAccName, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.ItemNo, j.ItemName, j.Spec, j.UMItemClassSSeq, j.UMItemClassMSeq, j.UMItemClassLSeq, j.UMItemClassSName, j.UMItmeClassMName, j.UMItemClassLName, j.UMItemEtcClassSeq, j.UMItemEtcClassName, j.UnitName, j.ItemSeq, j.AssetName, j.PreQty, j.PreAmt, j.ProdQty, j.ProdAmt, j.BuyQty, j.BuyAmt, j.MvInQty, j.MvInAmt, j.EtcInQty, j.EtcInAmt, j.ExchangeInQty, j.ExchangeInAmt, j.SalesQty, j.SalesAmt, j.InputQty, j.InputAmt, j.PJTOutQty, j.PJTOutAmt, j.MvOutQty, j.MvOutAmt, j.EtcOutQty, j.EtcOutAmt, j.ExchangeOutQty, j.ExchangeOutAmt, j.InQty, j.OutAmt, j.InAmt, j.StockQty, j.OutQty, j.StockAmt, j.StockQty2, j.StockAmt2, j.DiffQty, j.DiffAmt, j.DivPrice, j.StkPrice, j.InputAccName, j.SalesAccName, j.AssetGroupName, j.AssetAccName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    ItemNo NVARCHAR(100) '$."ItemNo"',
    ItemName NVARCHAR(100) '$."ItemName"',
    Spec NVARCHAR(100) '$."Spec"',
    UMItemClassSSeq INT '$."UMItemClassSSeq"',
    UMItemClassMSeq INT '$."UMItemClassMSeq"',
    UMItemClassLSeq INT '$."UMItemClassLSeq"',
    UMItemClassSName NVARCHAR(100) '$."UMItemClassSName"',
    UMItmeClassMName NVARCHAR(100) '$."UMItmeClassMName"',
    UMItemClassLName NVARCHAR(100) '$."UMItemClassLName"',
    UMItemEtcClassSeq INT '$."UMItemEtcClassSeq"',
    UMItemEtcClassName NVARCHAR(100) '$."UMItemEtcClassName"',
    UnitName NVARCHAR(100) '$."UnitName"',
    ItemSeq INT '$."ItemSeq"',
    AssetName NVARCHAR(100) '$."AssetName"',
    PreQty DECIMAL(19,5) '$."PreQty"',
    PreAmt DECIMAL(19,5) '$."PreAmt"',
    ProdQty DECIMAL(19,5) '$."ProdQty"',
    ProdAmt DECIMAL(19,5) '$."ProdAmt"',
    BuyQty DECIMAL(19,5) '$."BuyQty"',
    BuyAmt DECIMAL(19,5) '$."BuyAmt"',
    MvInQty DECIMAL(19,5) '$."MvInQty"',
    MvInAmt DECIMAL(19,5) '$."MvInAmt"',
    EtcInQty DECIMAL(19,5) '$."EtcInQty"',
    EtcInAmt DECIMAL(19,5) '$."EtcInAmt"',
    ExchangeInQty DECIMAL(19,5) '$."ExchangeInQty"',
    ExchangeInAmt DECIMAL(19,5) '$."ExchangeInAmt"',
    SalesQty DECIMAL(19,5) '$."SalesQty"',
    SalesAmt DECIMAL(19,5) '$."SalesAmt"',
    InputQty DECIMAL(19,5) '$."InputQty"',
    InputAmt DECIMAL(19,5) '$."InputAmt"',
    PJTOutQty DECIMAL(19,5) '$."PJTOutQty"',
    PJTOutAmt DECIMAL(19,5) '$."PJTOutAmt"',
    MvOutQty DECIMAL(19,5) '$."MvOutQty"',
    MvOutAmt DECIMAL(19,5) '$."MvOutAmt"',
    EtcOutQty DECIMAL(19,5) '$."EtcOutQty"',
    EtcOutAmt DECIMAL(19,5) '$."EtcOutAmt"',
    ExchangeOutQty DECIMAL(19,5) '$."ExchangeOutQty"',
    ExchangeOutAmt DECIMAL(19,5) '$."ExchangeOutAmt"',
    InQty DECIMAL(19,5) '$."InQty"',
    OutAmt DECIMAL(19,5) '$."OutAmt"',
    InAmt DECIMAL(19,5) '$."InAmt"',
    StockQty DECIMAL(19,5) '$."StockQty"',
    OutQty DECIMAL(19,5) '$."OutQty"',
    StockAmt DECIMAL(19,5) '$."StockAmt"',
    StockQty2 DECIMAL(19,5) '$."StockQty2"',
    StockAmt2 DECIMAL(19,5) '$."StockAmt2"',
    DiffQty DECIMAL(19,5) '$."DiffQty"',
    DiffAmt DECIMAL(19,5) '$."DiffAmt"',
    DivPrice DECIMAL(19,5) '$."DivPrice"',
    StkPrice DECIMAL(19,5) '$."StkPrice"',
    InputAccName NVARCHAR(100) '$."InputAccName"',
    SalesAccName NVARCHAR(100) '$."SalesAccName"',
    AssetGroupName NVARCHAR(100) '$."AssetGroupName"',
    AssetAccName NVARCHAR(100) '$."AssetAccName"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_WH_STOCK_SUM @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_WH_STOCK_SUM WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_WH_STOCK_SUM (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, SMAssetGrpName, WHName, SMWHKindName, AssetName, ItemClassLName, ItemClassMName, ItemClassSName, ItemName, ItemNo, Spec, UnitName, SMStatusName, PrevQty, InQty, OutQty, StockQty, ItemSeq, UnitSeq, WHSeq, SMWHKind, Location, SafetyQty, CostWHName, IsLot, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.SMAssetGrpName, j.WHName, j.SMWHKindName, j.AssetName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.ItemName, j.ItemNo, j.Spec, j.UnitName, j.SMStatusName, j.PrevQty, j.InQty, j.OutQty, j.StockQty, j.ItemSeq, j.UnitSeq, j.WHSeq, j.SMWHKind, j.Location, j.SafetyQty, j.CostWHName, j.IsLot, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock1')
  WITH (
    SMAssetGrpName NVARCHAR(200) '$."SMAssetGrpName"',
    WHName NVARCHAR(200) '$."WHName"',
    SMWHKindName NVARCHAR(200) '$."SMWHKindName"',
    AssetName NVARCHAR(200) '$."AssetName"',
    ItemClassLName NVARCHAR(200) '$."ItemClassLName"',
    ItemClassMName NVARCHAR(200) '$."ItemClassMName"',
    ItemClassSName NVARCHAR(200) '$."ItemClassSName"',
    ItemName NVARCHAR(200) '$."ItemName"',
    ItemNo NVARCHAR(200) '$."ItemNo"',
    Spec NVARCHAR(200) '$."Spec"',
    UnitName NVARCHAR(200) '$."UnitName"',
    SMStatusName NVARCHAR(200) '$."SMStatusName"',
    PrevQty NVARCHAR(200) '$."PrevQty"',
    InQty NVARCHAR(200) '$."InQty"',
    OutQty NVARCHAR(200) '$."OutQty"',
    StockQty NVARCHAR(200) '$."StockQty"',
    ItemSeq NVARCHAR(200) '$."ItemSeq"',
    UnitSeq NVARCHAR(200) '$."UnitSeq"',
    WHSeq NVARCHAR(200) '$."WHSeq"',
    SMWHKind NVARCHAR(200) '$."SMWHKind"',
    Location NVARCHAR(200) '$."Location"',
    SafetyQty NVARCHAR(200) '$."SafetyQty"',
    CostWHName NVARCHAR(200) '$."CostWHName"',
    IsLot NVARCHAR(200) '$."IsLot"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_WIP_SUBUL @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_VN_IF_WIP_SUBUL WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_WIP_SUBUL (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, factory, mat_id, mat_grp_1, work_date, boh_a_wip_before_pfl_50, boh_a_wip_after_pfl_90, boh_a_fgs_before_pfl_50, boh_a_fgs_after_pfl_90, boh_a_before_pfl_50, boh_a_after_pfl_90, boh_b_wip_before_pfl_50, boh_b_wip_after_pfl_90, boh_b_fgs_before_pfl_50, boh_b_fgs_after_pfl_90, boh_b_before_pfl_50, boh_b_after_pfl_90, t_boh_before_pfl_50, t_boh_after_pfl_90, input_usc_cutting_qty, change_code_qty, input_re_sorting_qty, input_rework_qty, wip_etc_input, total_input_to_line, total_input, normal_last_month, normal_this_month, wh_rt_sorting, wh_rt_pfrw, wh_rt_plrw, backship_sorting, backship_pfrw, backship_plrw, total_out_a_level, output_code_change_50, output_code_change_90, output_other_50, output_other_90, b_level_ship_paid_50, b_level_ship_paid_90, b_level_ship_paid, b_level_ship_free_50, b_level_ship_free_90, b_level_ship_free, b_level_ship_50, b_level_ship_90, total_out_b_level, total_output, scrap_before_pfl, scrap_after_pfl, scrap_total_qty, eoh_line_wip_pfl_50, eoh_line_wip_pfl_90, eoh_line_fgs_pfl_50, eoh_line_fgs_pfl_90, eoh_b_wip_pfl_50, eoh_b_wip_pfl_90, eoh_b_fgs_pfl_50, eoh_b_fgs_pfl_90, t_eoh_wip_pfl_50, t_eoh_wip_pfl_90, t_eoh_b_pfl_50, t_eoh_b_pfl_90, t_eoh_mes_pfl_50, t_eoh_mes_pfl_90, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId, j.factory, j.mat_id, j.mat_grp_1, j.work_date, j.boh_a_wip_before_pfl_50, j.boh_a_wip_after_pfl_90, j.boh_a_fgs_before_pfl_50, j.boh_a_fgs_after_pfl_90, j.boh_a_before_pfl_50, j.boh_a_after_pfl_90, j.boh_b_wip_before_pfl_50, j.boh_b_wip_after_pfl_90, j.boh_b_fgs_before_pfl_50, j.boh_b_fgs_after_pfl_90, j.boh_b_before_pfl_50, j.boh_b_after_pfl_90, j.t_boh_before_pfl_50, j.t_boh_after_pfl_90, j.input_usc_cutting_qty, j.change_code_qty, j.input_re_sorting_qty, j.input_rework_qty, j.wip_etc_input, j.total_input_to_line, j.total_input, j.normal_last_month, j.normal_this_month, j.wh_rt_sorting, j.wh_rt_pfrw, j.wh_rt_plrw, j.backship_sorting, j.backship_pfrw, j.backship_plrw, j.total_out_a_level, j.output_code_change_50, j.output_code_change_90, j.output_other_50, j.output_other_90, j.b_level_ship_paid_50, j.b_level_ship_paid_90, j.b_level_ship_paid, j.b_level_ship_free_50, j.b_level_ship_free_90, j.b_level_ship_free, j.b_level_ship_50, j.b_level_ship_90, j.total_out_b_level, j.total_output, j.scrap_before_pfl, j.scrap_after_pfl, j.scrap_total_qty, j.eoh_line_wip_pfl_50, j.eoh_line_wip_pfl_90, j.eoh_line_fgs_pfl_50, j.eoh_line_fgs_pfl_90, j.eoh_b_wip_pfl_50, j.eoh_b_wip_pfl_90, j.eoh_b_fgs_pfl_50, j.eoh_b_fgs_pfl_90, j.t_eoh_wip_pfl_50, j.t_eoh_wip_pfl_90, j.t_eoh_b_pfl_50, j.t_eoh_b_pfl_90, j.t_eoh_mes_pfl_50, j.t_eoh_mes_pfl_90, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.data.rows')
  WITH (
    factory VARCHAR(10) '$."factory"',
    mat_id VARCHAR(50) '$."mat_id"',
    mat_grp_1 VARCHAR(50) '$."mat_grp_1"',
    work_date VARCHAR(8) '$."work_date"',
    boh_a_wip_before_pfl_50 INT '$."boh_a_wip_before_pfl_50"',
    boh_a_wip_after_pfl_90 INT '$."boh_a_wip_after_pfl_90"',
    boh_a_fgs_before_pfl_50 INT '$."boh_a_fgs_before_pfl_50"',
    boh_a_fgs_after_pfl_90 INT '$."boh_a_fgs_after_pfl_90"',
    boh_a_before_pfl_50 INT '$."boh_a_before_pfl_50"',
    boh_a_after_pfl_90 INT '$."boh_a_after_pfl_90"',
    boh_b_wip_before_pfl_50 INT '$."boh_b_wip_before_pfl_50"',
    boh_b_wip_after_pfl_90 INT '$."boh_b_wip_after_pfl_90"',
    boh_b_fgs_before_pfl_50 INT '$."boh_b_fgs_before_pfl_50"',
    boh_b_fgs_after_pfl_90 INT '$."boh_b_fgs_after_pfl_90"',
    boh_b_before_pfl_50 INT '$."boh_b_before_pfl_50"',
    boh_b_after_pfl_90 INT '$."boh_b_after_pfl_90"',
    t_boh_before_pfl_50 INT '$."t_boh_before_pfl_50"',
    t_boh_after_pfl_90 INT '$."t_boh_after_pfl_90"',
    input_usc_cutting_qty INT '$."input_usc_cutting_qty"',
    change_code_qty INT '$."change_code_qty"',
    input_re_sorting_qty INT '$."input_re_sorting_qty"',
    input_rework_qty INT '$."input_rework_qty"',
    wip_etc_input INT '$."wip_etc_input"',
    total_input_to_line INT '$."total_input_to_line"',
    total_input INT '$."total_input"',
    normal_last_month INT '$."normal_last_month"',
    normal_this_month INT '$."normal_this_month"',
    wh_rt_sorting INT '$."wh_rt_sorting"',
    wh_rt_pfrw INT '$."wh_rt_pfrw"',
    wh_rt_plrw INT '$."wh_rt_plrw"',
    backship_sorting INT '$."backship_sorting"',
    backship_pfrw INT '$."backship_pfrw"',
    backship_plrw INT '$."backship_plrw"',
    total_out_a_level INT '$."total_out_a_level"',
    output_code_change_50 INT '$."output_code_change_50"',
    output_code_change_90 INT '$."output_code_change_90"',
    output_other_50 INT '$."output_other_50"',
    output_other_90 INT '$."output_other_90"',
    b_level_ship_paid_50 INT '$."b_level_ship_paid_50"',
    b_level_ship_paid_90 INT '$."b_level_ship_paid_90"',
    b_level_ship_paid INT '$."b_level_ship_paid"',
    b_level_ship_free_50 INT '$."b_level_ship_free_50"',
    b_level_ship_free_90 INT '$."b_level_ship_free_90"',
    b_level_ship_free INT '$."b_level_ship_free"',
    b_level_ship_50 INT '$."b_level_ship_50"',
    b_level_ship_90 INT '$."b_level_ship_90"',
    total_out_b_level INT '$."total_out_b_level"',
    total_output INT '$."total_output"',
    scrap_before_pfl INT '$."scrap_before_pfl"',
    scrap_after_pfl INT '$."scrap_after_pfl"',
    scrap_total_qty INT '$."scrap_total_qty"',
    eoh_line_wip_pfl_50 INT '$."eoh_line_wip_pfl_50"',
    eoh_line_wip_pfl_90 INT '$."eoh_line_wip_pfl_90"',
    eoh_line_fgs_pfl_50 INT '$."eoh_line_fgs_pfl_50"',
    eoh_line_fgs_pfl_90 INT '$."eoh_line_fgs_pfl_90"',
    eoh_b_wip_pfl_50 INT '$."eoh_b_wip_pfl_50"',
    eoh_b_wip_pfl_90 INT '$."eoh_b_wip_pfl_90"',
    eoh_b_fgs_pfl_50 INT '$."eoh_b_fgs_pfl_50"',
    eoh_b_fgs_pfl_90 INT '$."eoh_b_fgs_pfl_90"',
    t_eoh_wip_pfl_50 INT '$."t_eoh_wip_pfl_50"',
    t_eoh_wip_pfl_90 INT '$."t_eoh_wip_pfl_90"',
    t_eoh_b_pfl_50 INT '$."t_eoh_b_pfl_50"',
    t_eoh_b_pfl_90 INT '$."t_eoh_b_pfl_90"',
    t_eoh_mes_pfl_50 INT '$."t_eoh_mes_pfl_50"',
    t_eoh_mes_pfl_90 INT '$."t_eoh_mes_pfl_90"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
GO

