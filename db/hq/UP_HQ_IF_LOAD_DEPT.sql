/* 부서코드 → DOI_HQ_IF_DEPT (HQ 신규, txn=False) */
IF OBJECT_ID('DOI_HQ_IF_DEPT') IS NOT NULL DROP TABLE DOI_HQ_IF_DEPT;
CREATE TABLE DOI_HQ_IF_DEPT (
  [SITE] NVARCHAR(4),
  [LOAD_DTTM] DATETIME,
  [REQUEST_ID] NVARCHAR(50),
  [CCtrName] NVARCHAR(200),
  [UMCCtrKindName] NVARCHAR(200),
  [EmpName] NVARCHAR(200),
  [DeptName] NVARCHAR(200),
  [UMCostTypeName] NVARCHAR(200),
  [Remark] NVARCHAR(200),
  [BizUnitName] NVARCHAR(200),
  [AccUnitName] NVARCHAR(200),
  [SMCourceTypeName] NVARCHAR(200),
  [RegDate] NVARCHAR(200),
  [RegUserName] NVARCHAR(200),
  [IsNotUse] NVARCHAR(200),
  [IsNotUseDate] NVARCHAR(200),
  [DispSeq] NVARCHAR(200),
  [DeptSeq] NVARCHAR(200),
  [CCtrSeq] NVARCHAR(200),
  [UMCostType] NVARCHAR(200),
  [RegUserSeq] NVARCHAR(200),
  [BizUnit] NVARCHAR(200),
  [AccUnit] NVARCHAR(200),
  [SMCourceType] NVARCHAR(200),
  [UMCCtrKind] NVARCHAR(200),
  [EmpSeq] NVARCHAR(200),
  [IsTemp] NVARCHAR(200),
  [LastUserName] NVARCHAR(200),
  [LastDateTime] NVARCHAR(200),
  [Dummy1] NVARCHAR(200),
  [Dummy2] NVARCHAR(200),
  [Dummy3] NVARCHAR(200),
  [Dummy4] NVARCHAR(200),
  [Dummy5] NVARCHAR(200),
  [Dummy6] NVARCHAR(200),
  [Dummy7] NVARCHAR(200),
  [Dummy8] NVARCHAR(200),
  [Dummy9] NVARCHAR(200),
  [Dummy10] NVARCHAR(200),
  [RAW_JSON] NVARCHAR(MAX)
);

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