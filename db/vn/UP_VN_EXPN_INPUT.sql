CREATE OR ALTER PROCEDURE dbo.UP_VN_EXPN_INPUT @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731] 투입(재료비+가공비) 집계 → doi_vn_expn_matl (수량/금액)
   소스 = 기존 집계결과: doi_mat_cost.배부금액(재료), doi_expen_matl.[in](가공)
   공정(PL전/PL후) = V_VN_PROCESS_RATE 비율로 투입금액/수량 분할(잔차는 PL전에 보정 → 총액 보존)
   투입수량: 직과재료 = DOI_VN_MAT_INPUT 원천 투입수량(도우코드×자재). 공통재료/가공 = 0(수량개념 없음/면적배부)
   카세트(VINA CST, len(model)>5) 제외: VN은 doi_vncst_rate 미사용으로 데이터 없음
   ※ EXPEN_SEL/ACCT_NAME(분류) 매핑은 UP_VN_COST의 DOI_COST 조립과 동일 → 하류 재구성 정합 */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @mat float, @exp float, @cnt int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+' VINA 투입집계(doi_vn_expn_matl) 시작';
  BEGIN TRY

  DELETE FROM doi_vn_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  -- 도우코드별 PL전 비율(단일값). 잔차 보정에 사용
  ;WITH pr AS (
    SELECT yyyymm, site, 구분, 도우코드,
           MAX(CASE WHEN 공정=N'PL전' THEN 비율 END) rate_pl전
    FROM V_VN_PROCESS_RATE WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY yyyymm, site, 구분, 도우코드
  ),
  -- 직과재료 원천 투입수량 (도우코드×자재)
  mi AS (SELECT 제품번호 도우코드, 자재번호, SUM(CAST(투입수량 AS float)) qty
         FROM DOI_VN_MAT_INPUT WHERE yyyymm=@YYYYMM GROUP BY 제품번호, 자재번호),
  -- (1) 재료비: doi_mat_cost → EXPEN_SEL/ACCT_NAME 매핑(UP_VN_COST 동일)
  mat AS (
    SELECT m.구분, m.도우코드, m.도우모델,
      N'재료비' 원가구분,
      CASE WHEN m.mat_class=N'원자재' OR m.원가자재분류=N'원장'
             OR m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름'
             OR m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트'
             OR (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1')
             OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액'
           THEN 'MDAX' ELSE 'MIAX' END EXPEN_SEL,
      m.자재번호 항목,
      CASE WHEN m.mat_class+m.자재대분류=N'부자재'+N'필름' OR m.원가자재분류=N'필름' THEN N'PF'
           WHEN m.mat_class+m.자재대분류=N'원자재'+N'카세트' OR m.원가자재분류=N'카세트' THEN N'카세트'
           WHEN (m.mat_class+COALESCE(m.자재대분류,N'1')=N'약액'+N'1') OR (m.mat_class+m.자재대분류=N'부자재'+N'약액') OR m.원가자재분류=N'약액' THEN N'약액'
           WHEN (m.mat_class+m.자재대분류=N'부자재'+N'트레이' OR m.원가자재분류=N'트레이') THEN N'트레이'
           WHEN m.mat_class=N'원자재' THEN N'원장' ELSE N'기타' END 분류,
      CAST(m.배부금액 AS float) 투입금액,
      ISNULL(mi.qty,0) 투입수량        -- 직과재료(배부방식=직과)만 원천 투입수량, 공통은 0
    FROM doi_mat_cost m
    LEFT JOIN mi ON mi.도우코드=m.도우코드 AND mi.자재번호=m.자재번호 AND m.배부방식=N'직과'
    WHERE m.yyyymm=@YYYYMM AND m.site=@SITE AND m.sel_code=@SEL_CODE
  ),
  -- (2) 가공비: doi_expen_matl([in]) — 카세트(VINA CST, len>5) 제외
  exp AS (
    SELECT e.구분, e.도우코드, e.model 도우모델,
      N'가공비' 원가구분, e.EXPEN_SEL, e.SUB_NAME 항목, e.ACCT_NAME 분류,
      CAST(e.[in] AS float) 투입금액, CAST(0 AS float) 투입수량
    FROM doi_expen_matl e
    WHERE e.yyyymm=@YYYYMM AND e.site=@SITE AND e.sel_code=@SEL_CODE
      AND LEN(e.model)<=5 AND ISNULL(e.SUB_NAME,'')<>N'VINA CST'
  ),
  src AS (SELECT * FROM mat UNION ALL SELECT * FROM exp)
  INSERT INTO doi_vn_expn_matl
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,공정,원가구분,EXPEN_SEL,항목,분류,투입수량,투입금액)
  SELECT @YYYYMM,@SEL_CODE,@SITE, s.구분, s.도우코드, s.도우모델, v.공정, s.원가구분, s.EXPEN_SEL, s.항목, s.분류,
         CAST(v.투입수량 AS numeric(18,2)), CAST(v.투입금액 AS numeric(18,2))
  FROM src s
  LEFT JOIN pr ON pr.구분=s.구분 AND pr.도우코드=s.도우코드
  CROSS APPLY (VALUES
      (N'PL전', ROUND(s.투입금액 * ISNULL(pr.rate_pl전,0), 2), ROUND(s.투입수량 * ISNULL(pr.rate_pl전,0), 2)),
      (N'PL후', s.투입금액 - ROUND(s.투입금액 * ISNULL(pr.rate_pl전,0), 2), s.투입수량 - ROUND(s.투입수량 * ISNULL(pr.rate_pl전,0), 2))
  ) v(공정, 투입금액, 투입수량)
  WHERE ABS(v.투입금액) > 0.0000001 OR ABS(v.투입수량) > 0.0000001;   -- 0 배분 행 제외

  SELECT @mat=SUM(CASE WHEN 원가구분=N'재료비' THEN CAST(투입금액 AS float) ELSE 0 END),
         @exp=SUM(CASE WHEN 원가구분=N'가공비' THEN CAST(투입금액 AS float) ELSE 0 END),
         @cnt=COUNT(*) FROM doi_vn_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)
     +N'- 투입집계 완료 ('+CAST(@cnt AS varchar(20))+N'행, 재료비 '+CONVERT(varchar(30),CAST(@mat AS money),1)
     +N' + 가공비 '+CONVERT(varchar(30),CAST(@exp AS money),1)+N')';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_EXPN_INPUT','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_EXPN_INPUT','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
