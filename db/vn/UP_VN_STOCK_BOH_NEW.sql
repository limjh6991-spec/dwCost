
CREATE PROCEDURE UP_VN_STOCK_BOH_NEW
    @YYYYMM varchar(6), @SITE varchar(4)='VN', @SEL_CODE varchar(10)='ACTUAL'
AS
BEGIN
    SET NOCOUNT ON;
    -- [VN 260821] 제품 기초재고 이월(_NEW): 전월 doi_vn_stco 제품 기말(EOH_WH0006 수량/금액) → 당월 DOI_STOCK_BOH 기초.
    --   구 UP_VN_STOCK_BOH 는 DOI_STOCK/DOI_STCO(구테이블,_NEW 미사용)을 읽어 비어있었음.
    DECLARE @PREV varchar(6) = CONVERT(varchar(6), DATEADD(MONTH,-1,CAST(@YYYYMM+'01' AS date)), 112);
    DELETE FROM DOI_STOCK_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
    INSERT INTO DOI_STOCK_BOH
      (YYYYMM,SITE,sel_code,구분,model,model_type,expen_sel,expen_sel명,acct_name,item_name,stock,boh_amt,InEtc_Amt,OutEtc_Amt,조건,inch,boh,input,out,eoh,in_etc,out_etc,out_단가)
    SELECT @YYYYMM,@SITE,@SEL_CODE, 구분, MODEL, 도우코드, EXPEN_SEL, expen_sel명, ACCT_NAME, ISNULL(ITEM_NAME,''),
           N'', CAST(EOH_WH0006_AMT AS numeric(18,2)), 0, 0, N'PREV', NULL,
           CAST(ROUND(EOH_WH0006_QTY,0) AS int), 0, 0, 0, 0, 0, 0
    FROM doi_vn_stco
    WHERE yyyymm=@PREV AND sel_code=@SEL_CODE AND ISNULL(EOH_WH0006_AMT,0)<>0;
    SELECT @@ROWCOUNT AS inserted;
END
