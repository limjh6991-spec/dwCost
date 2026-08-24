
CREATE PROCEDURE UP_VN_IF_XFORM_STOCK_DETAIL
    @yyyymm  VARCHAR(6), @selCode VARCHAR(10) = N'ACTUAL', @site VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_VN_IF_STOCK_DETAIL(스테이징) -> ① DOI_VN_STOCK_DETAIL(그리드 C0007014_Sch1, 원천/재고조정 UP_VN_STOCK_ADJ 입력) + ② DOI_MATL_RESC(재료비원장)
    --   재고금액상세. 스테이징 데이터-날짜 없음(월말 스냅샷) → 요청월(@yyyymm) 태깅.
    -- ① 그리드/원천 테이블
    DELETE FROM DOI_VN_STOCK_DETAIL WHERE yyyymm=@yyyymm;
    INSERT INTO DOI_VN_STOCK_DETAIL
        (자산처리계정, 품목자산분류, 재고자산종류, 매출원가계정, 대분류, 중분류, 소분류, 품목기타분류, 품명, 품번, 규격, 단위,
         기초수량, 기초금액, 입고수량, 입고금액, 출고수량, 출고금액, 재고수량A, 결산후재고수량B, 차이수량A_B, 재고금액C, 결산후재고금액D, 차이금액C_D,
         최종결산월재고단가, 생산수량, 생산금액, 구매수량, 구매금액, 적송입고수량, 적송입고금액, 기타입고수량, 기타입고금액,
         판매수량, 판매원가, 투입수량, 투입금액, 적송출고수량, 적송출고금액, 기타출고수량, 기타출고금액, yyyymm, edit_user, edit_date)
    SELECT s.AssetAccName, s.AssetName, s.AssetGroupName, TRY_CONVERT(numeric(28,8), LEFT(LTRIM(s.SalesAccName), NULLIF(PATINDEX('%[^0-9]%', LTRIM(s.SalesAccName)+'x')-1,-1))),
        s.UMItemClassLName, s.UMItmeClassMName, s.UMItemClassSName, s.UMItemEtcClassName, s.ItemName, s.ItemNo, s.Spec, s.UnitName,
        CAST(s.PreQty AS numeric(28,8)), CAST(s.PreAmt AS numeric(28,8)), CAST(s.InQty AS numeric(28,8)), CAST(s.InAmt AS numeric(28,8)),
        CAST(s.OutQty AS numeric(28,8)), CAST(s.OutAmt AS numeric(28,8)), CAST(s.StockQty AS numeric(28,8)), CAST(s.StockQty2 AS numeric(28,8)),
        CAST(s.DiffQty AS numeric(28,8)), CAST(s.StockAmt AS numeric(28,8)), CAST(s.StockAmt2 AS numeric(28,8)), CAST(s.DiffAmt AS numeric(28,8)),
        CAST(s.StkPrice AS numeric(28,8)), CAST(s.ProdQty AS numeric(28,8)), CAST(s.ProdAmt AS numeric(28,8)), CAST(s.BuyQty AS numeric(28,8)), CAST(s.BuyAmt AS numeric(28,8)),
        CAST(s.MvInQty AS numeric(28,8)), CAST(s.MvInAmt AS numeric(28,8)), CAST(s.EtcInQty AS numeric(28,8)), CAST(s.EtcInAmt AS numeric(28,8)),
        CAST(s.SalesQty AS numeric(28,8)), CAST(s.SalesAmt AS numeric(28,8)), CAST(s.InputQty AS numeric(28,8)), CAST(s.InputAmt AS numeric(28,8)),
        CAST(s.MvOutQty AS numeric(28,8)), CAST(s.MvOutAmt AS numeric(28,8)), CAST(s.EtcOutQty AS numeric(28,8)), CAST(s.EtcOutAmt AS numeric(28,8)),
        @yyyymm, N'IF-STOCK_DETAIL', GETDATE()
    FROM DOI_VN_IF_STOCK_DETAIL s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');

    -- ② 재료비원장 (기존 유지)
    DELETE FROM DOI_MATL_RESC WHERE [YYYYMM]=@yyyymm AND [SEL_CODE]=@selCode AND [SITE]=@site;
    INSERT INTO DOI_MATL_RESC
        ([YYYYMM],[SEL_CODE],[SITE],[자산처리계정],[품목자산분류],[재고자산종류],[매출원가계정],[대분류],[중분류],[소분류],[품목기타분류],[품명],[품번],[규격],[단위],[기초수량],[기초금액],[입고수량],[입고금액],[출고수량],[출고금액],[재고수량],[결산후재고수량],[차이수량],[재고금액],[결산후재고금액],[차이금액],[최종결산월재고단가],[생산수량],[생산금액],[구매수량],[구매금액],[적송입고수량],[적송입고금액],[기타입고수량],[기타입고금액],[판매수량],[판매원가],[투입수량],[투입금액],[적송출고수량],[적송출고금액],[기타출고수량],[기타출고금액])
    SELECT @yyyymm,@selCode,@site, s.AssetAccName, s.AssetName, s.AssetGroupName, s.SalesAccName,
        s.UMItemClassLName, s.UMItmeClassMName, s.UMItemClassSName, s.UMItemEtcClassName, s.ItemName, s.ItemNo, s.Spec, s.UnitName,
        CAST(s.PreQty AS real), CAST(s.PreAmt AS numeric(15,2)), CAST(s.InQty AS real), CAST(s.InAmt AS numeric(15,2)),
        CAST(s.OutQty AS real), CAST(s.OutAmt AS numeric(15,2)), CAST(s.StockQty AS real), CAST(s.StockQty2 AS real), CAST(s.DiffQty AS real),
        CAST(s.StockAmt AS numeric(15,2)), CAST(s.StockAmt2 AS numeric(15,2)), CAST(s.DiffAmt AS numeric(15,2)), CAST(s.StkPrice AS real),
        CAST(s.ProdQty AS real), CAST(s.ProdAmt AS numeric(15,2)), CAST(s.BuyQty AS real), CAST(s.BuyAmt AS numeric(15,2)),
        CAST(s.MvInQty AS real), CAST(s.MvInAmt AS numeric(15,2)), CAST(s.EtcInQty AS real), CAST(s.EtcInAmt AS numeric(15,2)),
        CAST(s.SalesQty AS real), CAST(s.SalesAmt AS numeric(15,2)), CAST(s.InputQty AS real), CAST(s.InputAmt AS numeric(15,2)),
        CAST(s.MvOutQty AS real), CAST(s.MvOutAmt AS numeric(15,2)), CAST(s.EtcOutQty AS real), CAST(s.EtcOutAmt AS numeric(15,2))
    FROM DOI_VN_IF_STOCK_DETAIL s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');

    SELECT @@ROWCOUNT AS transformed;
END
