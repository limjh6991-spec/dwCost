/* ============================================================================
 * UP_HQ_IF_XFORM_MATERIAL  (HQ 자재코드/제품별공정별소요자재 → 운영 DOI_BOM_MAST[HQ])
 *   staging DOI_HQ_IF_MATERIAL(소요자재 66필드) → DOI_BOM_MAST (YYYYMM+SITE)
 *   제품/공정/자재 + 소요량/Loss율 1:1 의미 매핑. 멱등: (YYYYMM,SITE) 삭제 후 재적재.
 *   (마스터 — 요청이 스코프, 데이터-날짜 없음 → @yyyymm 태깅)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_MATERIAL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @site IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_BOM_MAST WHERE YYYYMM=@yyyymm AND SITE=@site;

    INSERT INTO DOI_BOM_MAST
        (YYYYMM, SITE, 제품명, 제품번호, 품목자산분류, 품목대분류, 품목중분류, 품목소분류,
         공정차수, 공정, 공정품명, 공정품번호, 자재명, 자재번호, 자재자산분류,
         자재대분류, 자재중분류, 자재소분류, 투입단위, 소요량, 내부Loss율, 외부Loss율,
         조립위치, 특이사항, 최초작성일, 최초작성자, 최종수정일, 최종수정자)
    SELECT
         @yyyymm, @site, s.ItemName, s.ItemNo, s.AssetName, s.UMItemClassLName, s.UMItemClassMName, s.UMItemClassName,
         s.ProcRev, s.ProcName, s.AssyItemName, s.AssyItemNo, s.MatItemName, s.MatItemNo, s.MatAssetName,
         s.MatUMItemClassLName, s.MatUMItemClassMName, s.MatUMItemClassName, s.MatUnitName,
         TRY_CONVERT(numeric(18,6), s.MatQty), TRY_CONVERT(numeric(18,4), s.InLossRate), TRY_CONVERT(numeric(18,4), s.OutLossRate),
         s.Location, s.Remark, s.RegDate, s.RegEmpName, s.LastDateTime, s.UptEmpName
      FROM DOI_HQ_IF_MATERIAL s
     WHERE s.SITE=@site;

    SELECT @@ROWCOUNT;
END
