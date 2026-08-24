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

