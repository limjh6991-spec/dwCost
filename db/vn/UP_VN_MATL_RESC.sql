CREATE OR ALTER PROCEDURE dbo.UP_VN_MATL_RESC @YYYYMM varchar(6),@SITE varchar(4),@SEL_CODE varchar(10) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+'- '+@YYYYMM+' '+CASE WHEN @SITE='HQ' THEN N'본사' ELSE N'VINA' END+N' 재료비 원장 시작';
  BEGIN TRY


  DELETE FROM dbo.doi_matl_resc WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE;
  INSERT INTO dbo.doi_matl_resc ([YYYYMM], [SEL_CODE], [SITE], [자산처리계정], [품목자산분류], [재고자산종류], [매출원가계정], [대분류], [중분류], [소분류], [품목기타분류], [품명], [품번], [규격], [단위], [기초수량], [기초금액], [입고수량], [입고금액], [출고수량], [출고금액], [재고수량], [결산후재고수량], [차이수량], [재고금액], [결산후재고금액], [차이금액], [최종결산월재고단가], [생산수량], [생산금액], [구매수량], [구매금액], [적송입고수량], [적송입고금액], [기타입고수량], [기타입고금액], [판매수량], [판매원가], [투입수량], [투입금액], [적송출고수량], [적송출고금액], [기타출고수량], [기타출고금액])
  SELECT @YYYYMM, @SEL_CODE, @SITE, a.[자산처리계정], a.[품목자산분류], a.[재고자산종류], a.[매출원가계정], a.[대분류], a.[중분류], a.[소분류], a.[품목기타분류], a.[품명], a.[품번], a.[규격], a.[단위], a.[기초수량], a.[기초금액], a.[입고수량], a.[입고금액], a.[출고수량], a.[출고금액], a.[재고수량A], a.[결산후재고수량B], a.[차이수량A_B], a.[재고금액C], a.[결산후재고금액D], a.[차이금액C_D], a.[최종결산월재고단가], a.[생산수량], a.[생산금액], a.[구매수량], a.[구매금액], a.[적송입고수량], a.[적송입고금액], a.[기타입고수량], a.[기타입고금액], a.[판매수량], a.[판매원가], a.[조정후투입수량], a.[조정후투입금액], a.[적송출고수량], a.[적송출고금액], a.[조정후기타출고수량], a.[조정후기타출고금액] FROM dbo.DOI_VN_STOCK_ADJ a WHERE a.yyyymm=@YYYYMM;


    SELECT @cnt=COUNT(*) FROM dbo.doi_matl_resc WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE;
    SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재료비 원장 완료 ('+CAST(@cnt AS varchar(20))+N'행)';
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MATL_RESC','SUCCESS');
    SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MATL_RESC','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END