/* ============================================================================
 * UP_HQ_IF_XFORM_WH_STOCK_SUM  (HQ 제품정보/창고별수불집계 → 운영 DOI_STOCK[HQ])
 *   staging DOI_HQ_IF_WH_STOCK_SUM → DOI_STOCK
 *   그레인: (YYYYMM, SEL_CODE, SITE, MODEL=품명, MODEL_TYPE=도우코드, STOCK=창고)
 *   요약(기초/입고/출고/재고)만 제공 → 상세컬럼(INPUT_ETC/OUT_* 등)은 0.
 *   멱등: 동일 (SITE,YYYYMM,SEL_CODE) 삭제 후 재적재. (스냅샷 — 요청기간이 스코프)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_WH_STOCK_SUM
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode='' SET @selCode='ACTUAL';
    IF @site    IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_STOCK WHERE YYYYMM=@yyyymm AND SEL_CODE=@selCode AND SITE=@site;

    INSERT INTO DOI_STOCK (YYYYMM, SEL_CODE, SITE, MODEL, MODEL_TYPE, STOCK, BOH, INPUT, OUT, EOH)
    SELECT @yyyymm, @selCode, @site,
           LTRIM(RTRIM(s.ItemName)), LTRIM(RTRIM(s.ItemNo)), LTRIM(RTRIM(s.WHName)),
           SUM(TRY_CONVERT(numeric(18,2), s.PrevQty)),
           SUM(TRY_CONVERT(numeric(18,2), s.InQty)),
           SUM(TRY_CONVERT(numeric(18,2), s.OutQty)),
           SUM(TRY_CONVERT(numeric(18,2), s.StockQty))
      FROM DOI_HQ_IF_WH_STOCK_SUM s
     WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'')
       AND s.ItemNo IS NOT NULL AND LTRIM(RTRIM(s.ItemNo))<>''
       AND s.WHName IS NOT NULL AND LTRIM(RTRIM(s.WHName))<>''
     GROUP BY LTRIM(RTRIM(s.ItemName)), LTRIM(RTRIM(s.ItemNo)), LTRIM(RTRIM(s.WHName));

    SELECT @@ROWCOUNT;
END
