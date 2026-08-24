
CREATE PROCEDURE UP_VN_IF_XFORM_ITEM_INPUT
    @yyyymm VARCHAR(6), @selCode VARCHAR(10)=N'ACTUAL', @site VARCHAR(4)=N'VN'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_VN_IF_ITEM_INPUT(스테이징) -> DOI_VN_MAT_INPUT(그리드 C0007012_VN_Sch1)
    --   품목별투입조회. 스테이징에 데이터-날짜 없음 → 요청월(@yyyymm)로 태깅(요청이 월 스코프).
    DELETE FROM DOI_VN_MAT_INPUT WHERE yyyymm=@yyyymm;
    INSERT INTO DOI_VN_MAT_INPUT
        (제품명, 제품번호, 제품규격, 자재명, 자재번호, 자재규격, 투입수량, 단가, 투입금액,
         생산투입비용계정, 제품품목자산분류, 자재품목자산분류, yyyymm, edit_user, edit_date)
    SELECT s.ItemName, s.ItemNo, s.ItemSpec, s.MatName, s.MatNo, s.Spec,
        CAST(s.InputQty AS numeric(28,8)), CAST(s.Price AS numeric(28,8)), CAST(s.Amt AS numeric(28,8)),
        s.InputCost, s.AssetName, s.MatAssetName, @yyyymm, N'IF-ITEM_INPUT', GETDATE()
    FROM DOI_VN_IF_ITEM_INPUT s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');
    SELECT @@ROWCOUNT AS transformed;
END
