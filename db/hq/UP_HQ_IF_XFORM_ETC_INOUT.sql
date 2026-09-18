/* 기타입출고금액조회(통합) HQ 변환 — DOI_HQ_IF_ETC_INOUT(스테이징) → DOI_ETC_INOUT(HQ 운영, C0007017 소비)
 *   VN UP_VN_IF_XFORM_ETC_INOUT 미러. 차이: 적재대상 doi_vn_etc_inout→DOI_ETC_INOUT, 회계단위 상수 '본사',
 *   @site 기본 'HQ'. DOI_ETC_INOUT 텍스트폭이 좁아(예: 거래처 nvarchar(20)) 적재실패 방지 위해 LEFT() 방어절단.
 *   월필터 = InOutDate(데이터 일자) 앞 6자리(전월 뭉침 방지). 멱등: yyyymm 단위 전삭제 후 재적재.
 */
CREATE OR ALTER PROCEDURE UP_HQ_IF_XFORM_ETC_INOUT
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM DOI_ETC_INOUT WHERE [yyyymm] = @yyyymm;

    INSERT INTO DOI_ETC_INOUT
        ([회계단위], [일자], [입출고구분], [원천구분], [기타입출고구분], [품목자산분류], [대분류], [중분류], [소분류], [품명], [품번], [규격], [단위], [단수보정구분], [수량], [금액], [단가], [계정과목], [창고], [사용부서], [거래처], [특이사항], [품목특이사항], [yyyymm], [edit_user], [edit_date])
    SELECT
        LEFT(ISNULL(JSON_VALUE(s.RAW_JSON, N'$.PriceUnitName'), N'본사'), 20),  -- 회계단위 (ERP 가격단위=회계단위, 공란시 '본사'; DDL 20자 방어절단)
        LEFT(s.InOutDate, 20),            -- 일자
        LEFT(s.InOutName, 20),            -- 입출고구분
        LEFT(s.UMEtcOutKindSource, 20),   -- 원천구분
        LEFT(s.UMEtcOutKindDetail, 100),  -- 기타입출고구분
        LEFT(s.AssetName, 20),            -- 품목자산분류
        LEFT(s.UMItemClassLName, 50),     -- 대분류
        LEFT(s.UMItemClassMName, 50),     -- 중분류
        LEFT(s.UMItemClassSName, 50),     -- 소분류
        LEFT(s.ItemName, 200),            -- 품명
        LEFT(s.ItemNo, 20),               -- 품번
        LEFT(s.Spec, 50),                 -- 규격
        LEFT(s.UnitName, 20),             -- 단위
        LEFT(s.SMAdjustKindName, 20),     -- 단수보정구분
        TRY_CONVERT(numeric(28,8), s.EtcOutQty),    -- 수량
        TRY_CONVERT(numeric(28,8), s.EtcOutAmt),    -- 금액
        TRY_CONVERT(numeric(28,8), s.EtcOutPrice),  -- 단가
        LEFT(s.AccName, 100),             -- 계정과목
        LEFT(s.WHName, 50),               -- 창고
        LEFT(s.DeptName, 20),             -- 사용부서
        LEFT(s.CustName, 20),             -- 거래처
        LEFT(s.Remark, 200),              -- 특이사항
        LEFT(s.ItemRemark, 254),          -- 품목특이사항
        @yyyymm,                          -- yyyymm
        N'IF',                            -- edit_user
        GETDATE()                         -- edit_date
    FROM DOI_HQ_IF_ETC_INOUT s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InOutDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
