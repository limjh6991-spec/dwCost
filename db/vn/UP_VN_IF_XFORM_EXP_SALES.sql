-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_EXP_SALES (스테이징) -> doi_invoice_resc (운영)
--   수출매출품목
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE   PROCEDURE UP_VN_IF_XFORM_EXP_SALES
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_invoice_resc
    WHERE [yyyymm] = @yyyymm AND [sel_code] = @selCode AND [site] = @site;

    INSERT INTO doi_invoice_resc
        ([yyyymm], [sel_code], [site], [사업단위], [Invoice_No], [Invoice_Date], [수출구분], [출고구분], [가격조건], [부서], [담당자], [Buyer], [통화], [환율], [품명], [품번], [규격], [단위], [판매기준가], [판매단가], [수량], [판매금액], [원화판매금액], [창고], [Remarks], [특이사항])
    SELECT
        @yyyymm,  -- yyyymm
        @selCode,  -- sel_code
        @site,  -- site
        s.BizUnitName,  -- 사업단위
        s.InvoiceRefNo,  -- Invoice_No
        s.InvoiceDate,  -- Invoice_Date
        s.SMExpKindName,  -- 수출구분
        s.UMChannelName,  -- 출고구분
        s.UMPriceTermsName,  -- 가격조건
        s.DeptName,  -- 부서
        s.EmpName,  -- 담당자
        s.CustName,  -- Buyer
        s.CurrName,  -- 통화
        CAST(s.ExRate AS numeric(18,2)),  -- 환율
        s.ItemName,  -- 품명
        s.ItemNo,  -- 품번
        s.Spec,  -- 규격
        s.UnitName,  -- 단위
        CAST(s.ItemPrice AS numeric(18,0)),  -- 판매기준가
        CAST(s.CustPrice AS numeric(18,2)),  -- 판매단가
        CAST(s.Qty AS bigint),  -- 수량
        CAST(s.CurAmt AS numeric(15,2)),  -- 판매금액
        CAST(s.DomAmt AS numeric(15,2)),  -- 원화판매금액
        s.WHName,  -- 창고
        s.RemarkI,  -- Remarks
        s.RemarkM   -- 특이사항
    FROM DOI_VN_IF_EXP_SALES s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
