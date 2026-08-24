
CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_DEPT_COST @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_DEPT_COST WHERE SITE=N'HQ' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_HQ_IF_DEPT_COST (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, CCtrName, DeptSeq, AccNameCost, AccNo, AccName, UMCostTypeName, AccSeq, DrAmt, CrAmt, RAW_JSON)
  SELECT N'HQ', @selCode, GETDATE(), @requestId, j.CCtrName, j.DeptSeq, j.AccNameCost, j.AccNo, j.AccName, j.UMCostTypeName, j.AccSeq, j.DrAmt, j.CrAmt, j.[RAW_JSON]
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
