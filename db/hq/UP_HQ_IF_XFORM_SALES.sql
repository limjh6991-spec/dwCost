/* ============================================================================
 * UP_HQ_IF_XFORM_SALES  (HQ 국내 거래명세서 → 운영 DOI_SALE_RESC[HQ])
 *   staging DOI_HQ_IF_SALES(84필드) → DOI_SALE_RESC(64컬럼, 국내매출)
 *   ※수출(EXP_INVOICE_HQ→DOI_INVOICE_RESC)과 별도 테이블(사용자 확정).
 *   멱등: 동일 (SITE,YYYYMM,SEL_CODE) 삭제 후 재적재. 월필터=InvoiceDate(거래명세서일).
 *   ⚠️필드 매핑은 정의서 응답필드 기반 best-effort — 실데이터로 검증 필요.
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_SALES
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode='' SET @selCode='ACTUAL';
    IF @site    IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_SALE_RESC
     WHERE SITE=@site AND YYYYMM=@yyyymm AND SEL_CODE=@selCode;

    INSERT INTO DOI_SALE_RESC
        (YYYYMM, SEL_CODE, SITE, 사업단위, 거래명세서번호, 거래명세서일, Local구분, 출고구분,
         부서, 담당자, 청구처, 거래처, 거래처번호, 중개인, 납품장소, 인도조건,
         품명, 품번, 규격, 판매단위, 판매기준가, 수량, 부가세포함, 통화, 환율,
         판매단가, 판매금액, 부가세액, 판매금액계, 원화판매금액, 원화부가세액, 원화판매금액계,
         창고, 보관위치, Lot_No, 세금계산서_진행상태, 배송상태, 매출수량, 반품,
         기타출고구분, 품목자산분류, PO_No, SEQ_NO)
    SELECT
         @yyyymm, @selCode, @site,
         s.BizUnitName, s.InvoiceNo, s.InvoiceDate, s.SMExpKindName, s.UMOutKindName,
         s.DeptName, s.EmpName, s.BillCustName, s.CustName, s.CustNo, s.BKCustName, s.DVPlaceName, s.DVCondition,
         s.ItemName, s.ItemNo, s.Spec, s.UnitName,
         TRY_CONVERT(numeric(18,2), s.Price), TRY_CONVERT(int, TRY_CONVERT(numeric(38,6), s.Qty)), s.IsInclusedVAT, s.CurrName,   -- 수량: numeric 경유(직접 int 변환은 소수문자열→NULL)
         TRY_CONVERT(numeric(18,2), s.ExRate),
         TRY_CONVERT(numeric(18,2), s.CustPrice), TRY_CONVERT(numeric(18,2), s.CurAmt),
         TRY_CONVERT(numeric(18,2), s.CurVAT), TRY_CONVERT(numeric(18,2), s.TotCurAmt),
         TRY_CONVERT(numeric(18,2), s.DomAmt), TRY_CONVERT(numeric(18,2), s.DomVAT),
         TRY_CONVERT(numeric(18,2), s.TotDomAmt),
         s.WHName, s.Location, s.LotNo, s.SMProgressTypeName, s.SMTransStatusName,
         TRY_CONVERT(int, TRY_CONVERT(numeric(38,6), s.SalesQty)), s.IsReturn, s.UMEtcOutKindName, s.AssetName, s.PONo,   -- 매출수량: numeric 경유
         ROW_NUMBER() OVER (ORDER BY s.InvoiceNo, s.ItemNo, s.InvoiceDate)   -- SEQ_NO (PK, 행 고유번호)
      FROM DOI_HQ_IF_SALES s
     WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'')
       AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT;
END
