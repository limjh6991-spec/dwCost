-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_STOCK_DETAIL (스테이징) -> DOI_MATL_RESC (운영)
--   재고금액상세
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_STOCK_DETAIL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM DOI_MATL_RESC
    WHERE [YYYYMM] = @yyyymm AND [SEL_CODE] = @selCode AND [SITE] = @site;

    INSERT INTO DOI_MATL_RESC
        ([YYYYMM], [SEL_CODE], [SITE], [자산처리계정], [품목자산분류], [재고자산종류], [매출원가계정], [대분류], [중분류], [소분류], [품목기타분류], [품명], [품번], [규격], [단위], [기초수량], [기초금액], [입고수량], [입고금액], [출고수량], [출고금액], [재고수량], [결산후재고수량], [차이수량], [재고금액], [결산후재고금액], [차이금액], [최종결산월재고단가], [생산수량], [생산금액], [구매수량], [구매금액], [적송입고수량], [적송입고금액], [기타입고수량], [기타입고금액], [판매수량], [판매원가], [투입수량], [투입금액], [적송출고수량], [적송출고금액], [기타출고수량], [기타출고금액])
    SELECT
        @yyyymm,  -- YYYYMM
        @selCode,  -- SEL_CODE
        @site,  -- SITE
        s.AssetAccName,  -- 자산처리계정
        s.AssetName,  -- 품목자산분류
        s.AssetGroupName,  -- 재고자산종류
        s.SalesAccName,  -- 매출원가계정
        s.UMItemClassLName,  -- 대분류
        s.UMItmeClassMName,  -- 중분류
        s.UMItemClassSName,  -- 소분류
        s.UMItemEtcClassName,  -- 품목기타분류
        s.ItemName,  -- 품명
        s.ItemNo,  -- 품번
        s.Spec,  -- 규격
        s.UnitName,  -- 단위
        CAST(s.PreQty AS real),  -- 기초수량
        CAST(s.PreAmt AS numeric(15,2)),  -- 기초금액
        CAST(s.InQty AS real),  -- 입고수량
        CAST(s.InAmt AS numeric(15,2)),  -- 입고금액
        CAST(s.OutQty AS real),  -- 출고수량
        CAST(s.OutAmt AS numeric(15,2)),  -- 출고금액
        CAST(s.StockQty AS real),  -- 재고수량
        CAST(s.StockQty2 AS real),  -- 결산후재고수량
        CAST(s.DiffQty AS real),  -- 차이수량
        CAST(s.StockAmt AS numeric(15,2)),  -- 재고금액
        CAST(s.StockAmt2 AS numeric(15,2)),  -- 결산후재고금액
        CAST(s.DiffAmt AS numeric(15,2)),  -- 차이금액
        CAST(s.StkPrice AS real),  -- 최종결산월재고단가
        CAST(s.ProdQty AS real),  -- 생산수량
        CAST(s.ProdAmt AS numeric(15,2)),  -- 생산금액
        CAST(s.BuyQty AS real),  -- 구매수량
        CAST(s.BuyAmt AS numeric(15,2)),  -- 구매금액
        CAST(s.MvInQty AS real),  -- 적송입고수량
        CAST(s.MvInAmt AS numeric(15,2)),  -- 적송입고금액
        CAST(s.EtcInQty AS real),  -- 기타입고수량
        CAST(s.EtcInAmt AS numeric(15,2)),  -- 기타입고금액
        CAST(s.SalesQty AS real),  -- 판매수량
        CAST(s.SalesAmt AS numeric(15,2)),  -- 판매원가
        CAST(s.InputQty AS real),  -- 투입수량
        CAST(s.InputAmt AS numeric(15,2)),  -- 투입금액
        CAST(s.MvOutQty AS real),  -- 적송출고수량
        CAST(s.MvOutAmt AS numeric(15,2)),  -- 적송출고금액
        CAST(s.EtcOutQty AS real),  -- 기타출고수량
        CAST(s.EtcOutAmt AS numeric(15,2))   -- 기타출고금액
    FROM DOI_VN_IF_STOCK_DETAIL s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'');

    SELECT @@ROWCOUNT AS transformed;
END;
