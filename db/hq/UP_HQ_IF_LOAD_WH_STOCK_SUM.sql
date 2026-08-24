
CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_WH_STOCK_SUM @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_WH_STOCK_SUM WHERE SITE=N'HQ' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_HQ_IF_WH_STOCK_SUM (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, SMAssetGrpName, WHName, SMWHKindName, AssetName, ItemClassLName, ItemClassMName, ItemClassSName, ItemName, ItemNo, Spec, UnitName, SMStatusName, PrevQty, InQty, OutQty, StockQty, ItemSeq, UnitSeq, WHSeq, SMWHKind, Location, SafetyQty, CostWHName, IsLot, RAW_JSON)
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.SMAssetGrpName, j.WHName, j.SMWHKindName, j.AssetName, j.ItemClassLName, j.ItemClassMName, j.ItemClassSName, j.ItemName, j.ItemNo, j.Spec, j.UnitName, j.SMStatusName, j.PrevQty, j.InQty, j.OutQty, j.StockQty, j.ItemSeq, j.UnitSeq, j.WHSeq, j.SMWHKind, j.Location, j.SafetyQty, j.CostWHName, j.IsLot, j.[RAW_JSON]
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
