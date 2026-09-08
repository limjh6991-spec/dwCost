/* =====================================================================
 * [VN 인터페이스] 언어별계정항목 — 6개 언어 명칭(DataBlock4) 적재
 *   ① DOI_VN_IF_ACCLANG_LANG 생성  ② UP_VN_IF_LOAD_ACCLANG: 계정행 위치(RowIDX) + DataBlock4 언어별 명칭 적재, @@ROWCOUNT 정상
 *   실행: DWCMSTEST (SSMS). 실행 후 [언어별계정항목 API 호출] → 그리드에 한국어/영어/일본어/简体中文/繁體中文/Tiếng việt 표시
 * ===================================================================== */
IF OBJECT_ID(N'DOI_VN_IF_ACCLANG_LANG', N'U') IS NULL
CREATE TABLE DOI_VN_IF_ACCLANG_LANG (
    SITE          NVARCHAR(4)   NOT NULL DEFAULT N'VN',
    LOAD_DTTM     DATETIME      NOT NULL DEFAULT GETDATE(),
    RowIDX        INT           NULL,   -- DataBlock3 계정행 위치(0-based)
    ColIDX        INT           NULL,   -- 언어 열(0=한국어,1=영어,2=일본어,3=简体中文,4=繁體中文,5=Tiếng việt)
    FSItemForName NVARCHAR(200) NULL,   -- 해당 언어 명칭
    RAW_JSON      NVARCHAR(MAX) NULL
);
GO
CREATE OR ALTER PROCEDURE UP_VN_IF_LOAD_ACCLANG @json NVARCHAR(MAX), @selCode NVARCHAR(10)=NULL, @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  -- 언어별계정항목 응답: DataBlock2=언어정의(TitleSeq 1~6: 한국어/English/日本語/简体中文/繁體中文/Tiếng việt),
  --   DataBlock3=계정행(FSItemNo/FSItemName/FSItemSeq), DataBlock4=언어별 명칭 {RowIDX(0-based=DataBlock3 배열위치), ColIDX(0..5=언어), FSItemForName}
  DELETE FROM DOI_VN_IF_ACCLANG WHERE SITE=N'VN' AND ISNULL(SEL_CODE,N'')=ISNULL(@selCode,N'');
  INSERT INTO DOI_VN_IF_ACCLANG (SITE, SEL_CODE, LOAD_DTTM, REQUEST_ID, FSItemNo, FSItemName, RowIDX, RAW_JSON)
  SELECT N'VN', @selCode, GETDATE(), @requestId,
         JSON_VALUE(a.value,'$.FSItemNo'), JSON_VALUE(a.value,'$.FSItemName'), CAST(a.[key] AS INT), a.value
  FROM OPENJSON(@json, '$.DataBlock3') a;   -- [key]=배열위치(0-based) = DataBlock4.RowIDX 조인키
  DECLARE @loaded INT = @@ROWCOUNT;          -- 마스터 적재건수 선보관(뒤 INSERT에 덮이지 않게)
  DELETE FROM DOI_VN_IF_ACCLANG_LANG WHERE SITE=N'VN';
  INSERT INTO DOI_VN_IF_ACCLANG_LANG (SITE, RowIDX, ColIDX, FSItemForName, RAW_JSON)
  SELECT N'VN', j.RowIDX, j.ColIDX, j.FSItemForName, j.[RAW_JSON]
  FROM OPENJSON(@json, '$.DataBlock4')
  WITH (RowIDX INT '$."RowIDX"', ColIDX INT '$."ColIDX"', FSItemForName NVARCHAR(200) '$."FSItemForName"', [RAW_JSON] NVARCHAR(MAX) '$' AS JSON) j;
  SELECT @loaded AS loaded;
END;
GO
