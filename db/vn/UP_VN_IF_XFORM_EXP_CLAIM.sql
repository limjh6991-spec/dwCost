
CREATE PROCEDURE UP_VN_IF_XFORM_EXP_CLAIM
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_VN_IF_EXP_CLAIM(스테이징) -> DOI_VN_EXP_CLAIM(운영/조회, 그리드 TAB070016_Sch1)
    --   멱등: 동일 키 삭제 후 재적재. 월 스코프: ClaimDate(YYYYMMDD)의 YYYYMM = @yyyymm.
    DELETE FROM DOI_VN_EXP_CLAIM
    WHERE yyyymm = @yyyymm AND sel_code = @selCode AND site = @site;

    INSERT INTO DOI_VN_EXP_CLAIM
        (yyyymm, sel_code, site, 사업단위, Claim번호, ClaimDate, 반품종류, 반품구분, 담당자, 부서,
         Buyer, Agent, 반품진행, 재수출진행, 통화, 환율, 품명, 품번, 규격, 판매단위, 기준단위,
         기준단위수량, 정가, 판매기준가, 판매단가, 수량, 판매금액, 원화판매금액, 창고, Remarks, edit_user, edit_date)
    SELECT
        @yyyymm, @selCode, @site,
        s.BizUnitName, s.ClaimNo, s.ClaimDate, s.SMExpKindName, s.UMOutKindName, s.EmpName, s.DeptName,
        s.CustName, s.BKCustName, s.SMProgressReturnTypeName, s.SMProgressTypeName, s.CurrName,
        CAST(s.ExRate AS numeric(18,5)), s.ItemName, s.ItemNo, s.Spec, s.UnitName, s.StdUnitName,
        CAST(s.StdQty AS numeric(18,3)), CAST(s.ItemPrice AS numeric(18,5)), CAST(s.CustPrice AS numeric(18,5)),
        CAST(s.Price AS numeric(18,5)), CAST(s.Qty AS numeric(18,3)), CAST(s.CurAmt AS numeric(18,2)),
        CAST(s.DomAmt AS numeric(18,2)), s.WHName, s.RemarkM, N'IF-EXP_CLAIM', GETDATE()
    FROM DOI_VN_IF_EXP_CLAIM s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.ClaimDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
