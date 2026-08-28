-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_ETC_INOUT (스테이징) -> doi_vn_etc_inout (운영)
--   기타입출고금액 (수량/금액/단가는 NVARCHAR->TRY_CONVERT)
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_ETC_INOUT
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_vn_etc_inout
    WHERE [yyyymm] = @yyyymm;

    INSERT INTO doi_vn_etc_inout
        ([회계단위], [일자], [입출고구분], [원천구분], [기타입출고구분], [품목자산분류], [대분류], [중분류], [소분류], [품명], [품번], [규격], [단위], [단수보정구분], [수량], [금액], [단가], [계정과목], [창고], [사용부서], [거래처], [특이사항], [품목특이사항], [yyyymm], [edit_user], [edit_date])
    SELECT
        ISNULL(JSON_VALUE(s.RAW_JSON, N'$.PriceUnitName'), N'DOWOO VINA'),  -- 회계단위 (ERP 가격단위=회계단위=DOWOO VINA, 공란시 상수)
        s.InOutDate,  -- 일자
        s.InOutName,  -- 입출고구분
        s.UMEtcOutKindSource,  -- 원천구분
        s.UMEtcOutKindDetail,  -- 기타입출고구분
        s.AssetName,  -- 품목자산분류
        s.UMItemClassLName,  -- 대분류
        s.UMItemClassMName,  -- 중분류
        s.UMItemClassSName,  -- 소분류
        s.ItemName,  -- 품명
        s.ItemNo,  -- 품번
        s.Spec,  -- 규격
        s.UnitName,  -- 단위
        s.SMAdjustKindName,  -- 단수보정구분
        TRY_CONVERT(numeric(28,8), s.EtcOutQty),  -- 수량
        TRY_CONVERT(numeric(28,8), s.EtcOutAmt),  -- 금액
        TRY_CONVERT(numeric(28,8), s.EtcOutPrice),  -- 단가
        s.AccName,  -- 계정과목
        s.WHName,  -- 창고
        s.DeptName,  -- 사용부서
        s.CustName,  -- 거래처
        s.Remark,  -- 특이사항
        s.ItemRemark,  -- 품목특이사항
        @yyyymm,  -- yyyymm
        N'IF',  -- edit_user
        GETDATE()   -- edit_date
    FROM DOI_VN_IF_ETC_INOUT s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InOutDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
