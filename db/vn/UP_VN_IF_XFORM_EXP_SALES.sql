-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_EXP_SALES (스테이징) -> doi_invoice_resc (운영)
--   수출매출품목
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_EXP_SALES
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_invoice_resc
    WHERE [yyyymm] = @yyyymm AND [sel_code] = @selCode AND [site] = @site;

    INSERT INTO doi_invoice_resc
        ([yyyymm], [sel_code], [site], [선택], [출고처리], [사업단위], [Invoice_No], [Invoice관리번호], [Invoice_Date], [수출구분], [출고구분], [가격조건], [부서], [담당자], [Buyer], [통화], [환율], [품명], [품번], [규격], [단위], [판매기준가], [판매단가], [수량], [판매금액], [원화판매금액], [매출금액계], [미매출금액], [매출대상], [진행상태], [매출진행상태], [창고], [Remarks], [특이사항])
    SELECT
        @yyyymm,  -- yyyymm
        @selCode,  -- sel_code
        @site,  -- site
        0,  -- 선택 (큐레이션 기본값)
        1,  -- 출고처리 (큐레이션 기본값)
        s.BizUnitName,  -- 사업단위
        s.InvoiceRefNo,  -- Invoice_No (외부 인보이스 참조번호)
        JSON_VALUE(s.RAW_JSON, N'$.BillNo'),  -- Invoice관리번호 (ERP 전표관리번호, 매핑누락 정정)
        s.InvoiceDate,  -- Invoice_Date
        s.SMExpKindName,  -- 수출구분
        CASE WHEN NULLIF(LTRIM(RTRIM(s.UMChannelName)), N'') IS NULL THEN N'정상판매' ELSE s.UMChannelName END,  -- 출고구분 (ERP 공란→큐레이션 기본값)
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
        CAST(s.CurAmt AS numeric(15,2)),  -- 매출금액계 (=판매금액)
        0,  -- 미매출금액 (큐레이션 기본값)
        0,  -- 매출대상 (큐레이션 기본값)
        N'완료',  -- 진행상태 (ERP 미제공→큐레이션 기본값)
        N'완료',  -- 매출진행상태 (큐레이션 기본값)
        s.WHName,  -- 창고
        s.RemarkI,  -- Remarks
        s.RemarkM   -- 특이사항
    FROM DOI_VN_IF_EXP_SALES s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
