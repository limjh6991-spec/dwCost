CREATE OR ALTER PROCEDURE dbo.UP_VN_COST_UNIT @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731] 재공단가 집계 → doi_cost_unit
   소스 = 기존 집계결과: doi_mat_cost.단가(재료), doi_expen_matl.unit_cost(가공)
     단가 = (기초BOH + 투입) / (OUT_QTY + EOHEQ), EOHEQ=PL전×0.5+PL후×0.9  (도우코드 공통 분모)
   그레인 = (구분,도우코드,원가항목=EXPEN_SEL+ACCT_NAME(분류)+ITEM_NAME(항목)), 공정='*' */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 재공단가(doi_cost_unit) 시작';
  BEGIN TRY

  DELETE FROM doi_cost_unit WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  INSERT INTO doi_cost_unit
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,공정,원가구분,EXPEN_SEL,분류,항목,단가)
  -- (1) 재료비 단가
  SELECT @YYYYMM,@SEL_CODE,@SITE, m.구분, m.도우코드, m.도우모델, N'*', N'재료비',
    CASE WHEN m.mat_class=N'원자재' OR m.원가자재분류=N'원장'
           OR m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름'
           OR m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트'
           OR (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1')
           OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액'
         THEN 'MDAX' ELSE 'MIAX' END,
    CASE WHEN m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름' THEN N'PF'
         WHEN m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트' THEN N'카세트'
         WHEN (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1') OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액' THEN N'약액'
         WHEN (m.mat_class+m.자재대분류=N'부자재'+N'트레이' OR m.원가자재분류=N'트레이') THEN N'트레이'
         WHEN m.mat_class=N'원자재' THEN N'원장' ELSE N'기타' END,
    m.자재번호, CAST(m.단가 AS numeric(24,12))
  FROM doi_mat_cost m
  WHERE m.yyyymm=@YYYYMM AND m.site=@SITE AND m.sel_code=@SEL_CODE
  UNION ALL
  -- (2) 가공비 단가 (카세트 제외)
  SELECT @YYYYMM,@SEL_CODE,@SITE, e.구분, e.도우코드, e.model, N'*', N'가공비',
    e.EXPEN_SEL, e.ACCT_NAME, e.SUB_NAME, CAST(e.unit_cost AS numeric(24,12))
  FROM doi_expen_matl e
  WHERE e.yyyymm=@YYYYMM AND e.site=@SITE AND e.sel_code=@SEL_CODE
    AND LEN(e.model)<=5 AND ISNULL(e.SUB_NAME,'')<>N'VINA CST';

  SELECT @cnt=COUNT(*) FROM doi_cost_unit WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재공단가 완료 ('+CAST(@cnt AS varchar(20))+N'행)';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_UNIT','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_UNIT','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
