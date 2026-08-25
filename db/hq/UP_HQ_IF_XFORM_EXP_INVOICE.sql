/* ============================================================================
 * UP_HQ_IF_XFORM_EXP_INVOICE  (HQ 수출Invoice → 운영 DOI_INVOICE_RESC[HQ])
 *   staging DOI_HQ_IF_EXP_INVOICE → DOI_INVOICE_RESC (VN doi_invoice_resc와 동일 37컬럼)
 *   VN UP_VN_IF_XFORM_EXP_SALES 매핑 미러 + HQ 수출Invoice 응답필드명 반영.
 *   멱등: 동일 (site, yyyymm, sel_code) 삭제 후 재적재. 월필터=InvoiceDate.
 *   ※국내(거래명세서 SALES_HQ)는 별도 테이블 — 본 변환과 분리(충돌 없음).
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_EXP_INVOICE
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode='' SET @selCode='ACTUAL';
    IF @site    IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_INVOICE_RESC
     WHERE site=@site AND yyyymm=@yyyymm AND sel_code=@selCode;

    INSERT INTO DOI_INVOICE_RESC
        (yyyymm, sel_code, site, 사업단위, Invoice_No, Invoice_Date, 수출구분, 출고구분, 가격조건,
         부서, 담당자, Buyer, Agent, 통화, 환율, 품명, 품번, 규격, 단위,
         판매기준가, 판매단가, 수량, 판매금액, 원화판매금액, 창고, 진행상태, Remarks, 특이사항)
    SELECT
         @yyyymm, @selCode, @site,
         s.BizUnitName, s.InvoiceNo, s.InvoiceDate, s.SMExpKindName, s.UMOutKindName, s.UMPriceTermName,
         s.DeptName, s.EmpName, s.CustName, s.BKCustName, s.CurrName,
         TRY_CONVERT(numeric(18,2), s.ExRate), s.ItemName, s.ItemNo, s.Spec, s.UnitName,
         TRY_CONVERT(numeric(18,0), s.ItemPrice), TRY_CONVERT(numeric(18,2), s.CustPrice),
         TRY_CONVERT(bigint, s.Qty), TRY_CONVERT(numeric(15,2), s.CurAmt), TRY_CONVERT(numeric(15,2), s.DomAmt),
         s.WHName, s.SMProgressTypeName, s.Remark, s.RemarkM
      FROM DOI_HQ_IF_EXP_INVOICE s
     WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'')
       AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT;
END
