CREATE OR ALTER PROCEDURE dbo.UP_VN_COST_BOH @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731] 기초금액(재공BOH) 집계 → DOI_COST_BOH
   소스 = 기존 집계결과: doi_mat_cost.BOH_AMT(재료 기초), doi_expen_matl.boh(가공 기초)
   그레인 = (구분,도우모델=MODEL,도우코드,원가항목=EXPEN_SEL+ACCT_NAME+ITEM_NAME), 공정='*'(전체)
   ※ EXPEN_SEL/ACCT_NAME/ITEM_NAME 매핑은 UP_VN_COST의 DOI_COST 조립과 동일 */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @mat float, @exp float, @cnt int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 기초금액(DOI_COST_BOH) 시작';
  BEGIN TRY

  DELETE FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  INSERT INTO DOI_COST_BOH
    (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
  -- (1) 재료비 기초: doi_mat_cost.BOH_AMT
  SELECT @YYYYMM,@SEL_CODE,@SITE, m.구분, m.도우모델, m.도우코드, N'*',
    CASE WHEN m.mat_class=N'원자재' OR m.원가자재분류=N'원장'
           OR m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름'
           OR m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트'
           OR (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1')
           OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액'
         THEN N'직접재료비' ELSE N'간접재료비' END,
    CASE WHEN m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름' THEN N'PF'
         WHEN m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트' THEN N'카세트'
         WHEN (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1') OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액' THEN N'약액'
         WHEN (m.mat_class+m.자재대분류=N'부자재'+N'트레이' OR m.원가자재분류=N'트레이') THEN N'트레이'
         WHEN m.mat_class=N'원자재' THEN N'원장' ELSE N'기타' END,
    m.자재번호,
    CASE WHEN m.mat_class=N'원자재' OR m.원가자재분류=N'원장'
           OR m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름'
           OR m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트'
           OR (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1')
           OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액'
         THEN 'MDAX' ELSE 'MIAX' END,
    ISNULL(m.ADJ_YN,'N'), CAST(m.boh_qty AS int), CAST(m.BOH_AMT AS numeric(18,2))
  FROM doi_mat_cost m
  WHERE m.yyyymm=@YYYYMM AND m.site=@SITE AND m.sel_code=@SEL_CODE
  UNION ALL
  -- (2) 가공비 기초: doi_expen_matl.boh (카세트 제외)
  SELECT @YYYYMM,@SEL_CODE,@SITE, e.구분, e.model, e.도우코드, N'*',
    e.EXPEN_SEL명, e.ACCT_NAME, e.SUB_NAME, e.EXPEN_SEL,
    ISNULL(e.ADJ_YN,'N'), CAST(e.boh_qty AS int), CAST(e.boh AS numeric(18,2))
  FROM doi_expen_matl e
  WHERE e.yyyymm=@YYYYMM AND e.site=@SITE AND e.sel_code=@SEL_CODE
    AND LEN(e.model)<=5 AND ISNULL(e.SUB_NAME,'')<>N'VINA CST';

  SELECT @mat=SUM(CASE WHEN LEFT(EXPEN_SEL,1)='M' THEN CAST(BOH AS float) ELSE 0 END),
         @exp=SUM(CASE WHEN LEFT(EXPEN_SEL,1)<>'M' THEN CAST(BOH AS float) ELSE 0 END),
         @cnt=COUNT(*) FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)
     +N'- 기초금액 완료 ('+CAST(@cnt AS varchar(20))+N'행, 재료비기초 '+CONVERT(varchar(30),CAST(@mat AS money),1)
     +N' + 가공비기초 '+CONVERT(varchar(30),CAST(@exp AS money),1)+N')';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_BOH','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_BOH','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
