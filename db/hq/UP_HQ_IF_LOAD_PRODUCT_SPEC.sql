/* 면적기준(모델별 기본정보) HQ 적재 — MES product-spec 응답(top-level 배열) → DOI_HQ_IF_PRODUCT_SPEC
 *   응답이 배열 자체 [{...}] 이므로 OPENJSON(@json) (경로 미지정 = 루트 배열).
 *   마스터(useSelCode=false) → loadMaster(@json,@requestId). ※시그니처 2인자 필수(EXEC proc @json,@requestId).
 */
CREATE OR ALTER PROCEDURE UP_HQ_IF_LOAD_PRODUCT_SPEC @json NVARCHAR(MAX), @requestId NVARCHAR(50)=NULL
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM DOI_HQ_IF_PRODUCT_SPEC WHERE SITE=N'HQ';
  INSERT INTO DOI_HQ_IF_PRODUCT_SPEC (SITE, LOAD_DTTM, REQUEST_ID, area, Model, width, Spec, Prod_code, height, RAW_JSON)
  SELECT N'HQ', GETDATE(), @requestId, j.area, j.Model, j.width, j.Spec, j.Prod_code, j.height, j.[RAW_JSON]
  FROM OPENJSON(@json)          -- top-level 배열 (경로 미지정 = 루트)
  WITH (
    area      DECIMAL(19,5) '$."area"',
    Model     NVARCHAR(50)  '$."Model"',
    width     DECIMAL(19,5) '$."width"',
    Spec      NVARCHAR(200) '$."Spec"',
    Prod_code NVARCHAR(100) '$."Prod_code"',
    height    DECIMAL(19,5) '$."height"',
    [RAW_JSON] NVARCHAR(MAX) '$' AS JSON
  ) j;
  SELECT @@ROWCOUNT AS loaded;
END;
