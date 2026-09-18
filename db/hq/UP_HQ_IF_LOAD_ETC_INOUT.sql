/* 기타입출고금액조회(통합) HQ 적재 — ERP $.DataBlock1 → DOI_HQ_IF_ETC_INOUT
 *   VN UP_VN_IF_LOAD_ETC_INOUT 미러(SITE=N'HQ'). useSelCode=true → loadWithSel(@json,@selCode,@requestId).
 */
CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_ETC_INOUT @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_ETC_INOUT WHERE SITE=N'HQ' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_HQ_IF_ETC_INOUT (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, InOutDate, InOutName, UMEtcOutKindSource, UMEtcOutKindDetail, AssetName, UMItemClassLName, UMItemClassMName, UMItemClassSName, ItemName, ItemNo, Spec, UnitName, SMAdjustKindName, EtcOutQty, EtcOutAmt, EtcOutPrice, AccName, WHName, DeptName, Remark, ItemRemark, CustName, RAW_JSON)
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.InOutDate, j.InOutName, j.UMEtcOutKindSource, j.UMEtcOutKindDetail, j.AssetName, j.UMItemClassLName, j.UMItemClassMName, j.UMItemClassSName, j.ItemName, j.ItemNo, j.Spec, j.UnitName, j.SMAdjustKindName, j.EtcOutQty, j.EtcOutAmt, j.EtcOutPrice, j.AccName, j.WHName, j.DeptName, j.Remark, j.ItemRemark, j.CustName, j.[RAW_JSON]
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
