CREATE OR ALTER PROCEDURE dbo.UP_VN_STOCK_ADJ @YYYYMM varchar(6),@SITE varchar(4),@SEL_CODE varchar(10) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+'- '+@YYYYMM+' '+CASE WHEN @SITE='HQ' THEN N'본사' ELSE N'VINA' END+N' 재고조정(6272) 시작';
  BEGIN TRY


  DELETE FROM dbo.DOI_VN_ETC_INOUT WHERE yyyymm=@YYYYMM AND (원천구분='TOTAL' OR 입출고구분='TOTAL' OR 품번='TOTAL');
  DELETE FROM dbo.DOI_VN_STOCK_ADJ WHERE yyyymm=@YYYYMM;
  ;WITH etc6272 AS (
    SELECT [품번],
       CAST(SUM(CAST([수량] AS numeric(28,8))) AS numeric(28,8)) AS ETC6272수량,
       CAST(SUM(CAST([금액] AS numeric(28,8))) AS numeric(28,8)) AS ETC6272금액,
       MAX([기타입출고구분]) AS 출고구분_6272, MAX([계정과목]) AS 계정과목_6272
    FROM dbo.DOI_VN_ETC_INOUT
    WHERE yyyymm=@YYYYMM AND [입출고구분]=N'출고' AND LEFT(LTRIM([기타입출고구분]),4)=N'6272'
      AND SUBSTRING(LTRIM([기타입출고구분]),5,1) IN (N' ',N'-')
    GROUP BY [품번])
  INSERT INTO dbo.DOI_VN_STOCK_ADJ
    ([자산처리계정], [품목자산분류], [재고자산종류], [매출원가계정], [대분류], [중분류], [소분류], [품목기타분류], [품명], [품번], [규격], [단위], [기초수량], [기초금액], [입고수량], [입고금액], [출고수량], [출고금액], [재고수량A], [결산후재고수량B], [차이수량A_B], [재고금액C], [결산후재고금액D], [차이금액C_D], [최종결산월재고단가], [생산수량], [생산금액], [구매수량], [구매금액], [적송입고수량], [적송입고금액], [기타입고수량], [기타입고금액], [판매수량], [판매원가], [투입수량], [투입금액], [적송출고수량], [적송출고금액], [기타출고수량], [기타출고금액], [부재료비간주YN],[ETC6272수량],[ETC6272금액],[이동수량],[이동금액],
     [조정후투입수량],[조정후투입금액],[조정후기타출고수량],[조정후기타출고금액],[출고구분_6272],[계정과목_6272],[yyyymm])
  SELECT s.[자산처리계정], s.[품목자산분류], s.[재고자산종류], s.[매출원가계정], s.[대분류], s.[중분류], s.[소분류], s.[품목기타분류], s.[품명], s.[품번], s.[규격], s.[단위], s.[기초수량], s.[기초금액], s.[입고수량], s.[입고금액], s.[출고수량], s.[출고금액], s.[재고수량A], s.[결산후재고수량B], s.[차이수량A_B], s.[재고금액C], s.[결산후재고금액D], s.[차이금액C_D], s.[최종결산월재고단가], s.[생산수량], s.[생산금액], s.[구매수량], s.[구매금액], s.[적송입고수량], s.[적송입고금액], s.[기타입고수량], s.[기타입고금액], s.[판매수량], s.[판매원가], s.[투입수량], s.[투입금액], s.[적송출고수량], s.[적송출고금액], s.[기타출고수량], s.[기타출고금액],
    CAST(CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN 'Y' ELSE 'N' END AS char(1)),
    e.[ETC6272수량], e.[ETC6272금액],
    CAST(CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN ISNULL(e.[ETC6272수량],0) ELSE 0 END AS numeric(28,8)),
    CAST(CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN ISNULL(e.[ETC6272금액],0) ELSE 0 END AS numeric(28,8)),
    CAST(ISNULL(s.[투입수량],0)   + CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN ISNULL(e.[ETC6272수량],0) ELSE 0 END AS numeric(28,8)),
    CAST(ISNULL(s.[투입금액],0)   + CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN ISNULL(e.[ETC6272금액],0) ELSE 0 END AS numeric(28,8)),
    CAST(ISNULL(s.[기타출고수량],0) - CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN ISNULL(e.[ETC6272수량],0) ELSE 0 END AS numeric(28,8)),
    CAST(ISNULL(s.[기타출고금액],0) - CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN ISNULL(e.[ETC6272금액],0) ELSE 0 END AS numeric(28,8)),
    CAST(CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN e.[출고구분_6272] ELSE NULL END AS nvarchar(300)),
    CAST(CASE WHEN (s.[품목자산분류]=N'Sub Material' AND e.[품번] IS NOT NULL) THEN e.[계정과목_6272] ELSE NULL END AS nvarchar(300)),
    @YYYYMM
  FROM dbo.DOI_VN_STOCK_DETAIL s LEFT JOIN etc6272 e ON e.[품번]=s.[품번]
  WHERE s.yyyymm=@YYYYMM;


    SELECT @cnt=COUNT(*) FROM dbo.DOI_VN_STOCK_ADJ WHERE yyyymm=@YYYYMM;
    SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재고조정(6272) 완료 ('+CAST(@cnt AS varchar(20))+N'행)';
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_STOCK_ADJ','SUCCESS');
    SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_STOCK_ADJ','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END