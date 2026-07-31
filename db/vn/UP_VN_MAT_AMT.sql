CREATE OR ALTER PROCEDURE dbo.UP_VN_MAT_AMT @YYYYMM varchar(6),@SITE varchar(4),@SEL_CODE varchar(10) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+'- '+@YYYYMM+' '+CASE WHEN @SITE='HQ' THEN N'본사' ELSE N'VINA' END+N' 재료비 집계 시작';
  BEGIN TRY


  DELETE FROM dbo.doi_mat_amt WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  INSERT INTO dbo.doi_mat_amt (yyyymm,sel_code,site,mat_code,in_qty,mat_unit_cost,in_amt,cost_gubun,mat_gubun,mat_class,자재대분류,소요량,원가자재분류)
  SELECT a.YYYYMM,@SEL_CODE,a.SITE, a.품번,
    SUM(CAST(a.투입수량 AS numeric(28,4))), AVG(CAST(a.최종결산월재고단가 AS numeric(28,8))), SUM(CAST(a.투입금액 AS numeric(28,4))),
    MAX(a.자산처리계정), MAX(a.품목자산분류), MAX(a.재고자산종류), MAX(a.대분류), NULL,
    MAX(CASE WHEN m.품목자산분류=N'Raw Material' AND m.자재소분류 LIKE N'%Glass%' THEN N'원장'
             WHEN m.품목자산분류=N'Raw Material' AND m.자재소분류 LIKE N'PF%' THEN N'PF'
             WHEN m.품목자산분류=N'Raw Material' AND m.자재소분류 LIKE N'PL%' THEN N'PL'
             WHEN m.품목자산분류=N'Raw Material' AND UPPER(m.자재소분류) LIKE N'%CHEMICAL%' THEN N'약액'
             WHEN m.품목자산분류=N'Sub Material' AND UPPER(m.자재소분류) LIKE N'%TRAY%' THEN N'트레이'
             WHEN m.품목자산분류=N'Sub Material' THEN N'부재료' ELSE N'기타' END)
  FROM dbo.doi_matl_resc a
  LEFT JOIN dbo.DOI_VN_MATERIAL m ON m.자재번호=a.품번 AND m.yyyymm=a.YYYYMM
  WHERE a.YYYYMM=@YYYYMM AND a.SITE=@SITE AND a.SEL_CODE=@SEL_CODE AND ISNULL(a.투입금액,0)<>0
  GROUP BY a.YYYYMM, a.SITE, a.품번;


    SELECT @cnt=COUNT(*) FROM dbo.doi_mat_amt WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
    SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재료비 집계 완료 ('+CAST(@cnt AS varchar(20))+N'행)';
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MAT_AMT','SUCCESS');
    SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MAT_AMT','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END