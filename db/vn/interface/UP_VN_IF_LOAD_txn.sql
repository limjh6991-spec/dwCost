-- VN IF 트랜잭션/조회 적재 프로시저 13종 (OPENJSON). ERP=$.DataBlock1 / MES=$.data.rows
-- @json 응답 / @selCode 결산코드 / @requestId. SEL_CODE 단위 삭제후 재적재

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
