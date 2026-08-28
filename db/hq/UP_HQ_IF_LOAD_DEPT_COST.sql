/* ============================================================================
 * DOI_HQ_IF_DEPT_COST 원천필드 보강 + UP_HQ_IF_LOAD_DEPT_COST
 *   staging(VN 클론)에 코스트센터분류/유형/회계단위 응답필드가 없어 미적재였음.
 *   UMCCtrKindName(코스트센터분류)·SMSourceTypeName(코스트센터유형)·
 *   CCtrAccUnitName(회계단위) 컬럼 추가 + OPENJSON 캡처.
 * ========================================================================== */
IF COL_LENGTH('DOI_HQ_IF_DEPT_COST','UMCCtrKindName')   IS NULL ALTER TABLE DOI_HQ_IF_DEPT_COST ADD UMCCtrKindName   NVARCHAR(200) NULL;
GO
IF COL_LENGTH('DOI_HQ_IF_DEPT_COST','SMSourceTypeName') IS NULL ALTER TABLE DOI_HQ_IF_DEPT_COST ADD SMSourceTypeName NVARCHAR(200) NULL;
GO
IF COL_LENGTH('DOI_HQ_IF_DEPT_COST','CCtrAccUnitName')  IS NULL ALTER TABLE DOI_HQ_IF_DEPT_COST ADD CCtrAccUnitName  NVARCHAR(200) NULL;
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
