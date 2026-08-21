
CREATE PROCEDURE UP_VN_STOCK_BOH_NEW
    @YYYYMM varchar(6), @SITE varchar(4)='VN', @SEL_CODE varchar(10)='ACTUAL'
AS
BEGIN
    SET NOCOUNT ON;
    -- [VN 260821] 제품 기초재고 이월(_NEW): 전월 doi_vn_stco 제품 기말(EOH_WH0006 수량/금액) → 당월 DOI_STOCK_BOH 기초.
    --   구 UP_VN_STOCK_BOH 는 DOI_STOCK/DOI_STCO(구테이블,_NEW 미사용)을 읽어 비어있었음.
    --   ★boh(수량): 전월 doi_vn_stco.EOH_WH0006_QTY 는 expen_sel별로 반복(fanned=도우코드 전체수량)되므로
    --     그대로 넣으면 SUM(boh)이 N배 → UP_VN_RSRW 기초단가(=SUM(boh_amt)/SUM(boh))가 1/N로 과소.
    --     → 도우코드+division 당 대표행(rn=1)에만 전체수량, 나머지 0 으로 넣어 SUM(boh)=실제수량 유지.
    --     (boh_amt 는 원가요소별 배분값이라 그대로 SUM; UP_VN_RSRW 는 SUM(boh)/SUM(boh_amt)만 사용)
    DECLARE @PREV varchar(6) = CONVERT(varchar(6), DATEADD(MONTH,-1,CAST(@YYYYMM+'01' AS date)), 112);
    DELETE FROM DOI_STOCK_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
    INSERT INTO DOI_STOCK_BOH
      (YYYYMM,SITE,sel_code,구분,model,model_type,expen_sel,expen_sel명,acct_name,item_name,stock,boh_amt,InEtc_Amt,OutEtc_Amt,조건,inch,boh,input,out,eoh,in_etc,out_etc,out_단가)
    SELECT @YYYYMM,@SITE,@SEL_CODE, 구분, MODEL, 도우코드, EXPEN_SEL, expen_sel명, ACCT_NAME, ISNULL(ITEM_NAME,''),
           N'', CAST(EOH_WH0006_AMT AS numeric(18,2)), 0, 0, N'PREV', NULL,
           CAST(CASE WHEN ROW_NUMBER() OVER (PARTITION BY 도우코드, division ORDER BY EXPEN_SEL) = 1
                     THEN ROUND(EOH_WH0006_QTY,0) ELSE 0 END AS int),
           0, 0, 0, 0, 0, 0
    FROM doi_vn_stco
    WHERE yyyymm=@PREV AND sel_code=@SEL_CODE AND ISNULL(EOH_WH0006_AMT,0)<>0;
    SELECT @@ROWCOUNT AS inserted;
END
