
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
