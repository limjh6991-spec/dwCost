CREATE OR ALTER PROCEDURE dbo.UP_VN_EXPN_INPUT @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-2] 제품별(도우코드) 투입 배부 → doi_expn_matl  (재료+가공, 투입금액+투입수량만)
   ★ doi_mat_cost / doi_expen_matl 미사용. 원천에서 직접 배부.
   재료: 직과=DOI_VN_MAT_INPUT, 공통=DOI_MATL_RESC(환산량×면적 배부)  [UP_VN_MAT_COST 로직]
   가공: doi_acct_expen(물량×면적 배부, 카세트 dept 400/448 제외)     [UP_VN_EXPEN_MATL 로직]
   투입수량 = 도우코드별 SUM(IN_MONTH) (원가항목 행마다 반복). 공정/기초/단가는 하류 함수. */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @mat float, @exp float, @cnt int, @missing_cnt int, @missing_list nvarchar(max);
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 투입배부(doi_expn_matl) 시작';
  BEGIN TRY

  -- 면적 누락 검증 (환산량>0 도우코드 중 DOI_MODEL_MAST 면적 없으면 중단)
  -- [VN 260801] 배부 생산환산량 = OUTPUT_A + TOTAL_EOH_전×0.5+후×0.9 (doi_vn_prod_resc). 면적검증은 OUTPUT>0 모델만(기말재공만 있는 모델은 적수=0).
  ;WITH prod_chk AS (
     SELECT 도우코드, SUM(ISNULL(OUTPUT_A,0)) outq
     FROM doi_vn_prod_resc WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE GROUP BY 도우코드)
  SELECT @missing_cnt=COUNT(*), @missing_list=STRING_AGG(CONVERT(nvarchar(max),p.도우코드),N', ')
  FROM prod_chk p LEFT JOIN DOI_MODEL_MAST mm ON mm.yyyymm=@YYYYMM AND mm.site=@SITE AND mm.MODEL=p.도우코드
  WHERE p.outq>0 AND (mm.MODEL IS NULL OR ISNULL(mm.xy,0)=0);
  IF ISNULL(@missing_cnt,0)>0
  BEGIN
     SET @Message=@Message+CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 면적(DOI_MODEL_MAST) 누락 도우코드 '+CAST(@missing_cnt AS varchar(10))+N'건 → 배부 중단: '+ISNULL(@missing_list,N'');
     INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
       VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_EXPN_INPUT','FAIL');
     SELECT @Message as retMessage; RETURN -1;
  END

  DELETE FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  -- 공유: 도우코드별 수량/면적/도우모델
  IF OBJECT_ID('tempdb..#prod') IS NOT NULL DROP TABLE #prod;
  SELECT pa.도우코드, pa.도우모델, pa.구분, pa.in_qty, pa.환산량, CAST(ISNULL(mm.xy,0) AS float) 면적
  INTO #prod
  FROM (SELECT 도우코드, LEFT(도우코드,LEN(도우코드)-1) 도우모델,
           CASE WHEN division='MP' THEN N'양산' ELSE N'개발' END 구분,
           SUM(CAST(ISNULL(USC_INPUT,0) AS float)) in_qty,
           SUM(ISNULL(OUTPUT_A,0)+ISNULL(TOTAL_EOH_전,0)*0.5+ISNULL(TOTAL_EOH_후,0)*0.9) 환산량   -- [VN 260801] 신 생산환산량
        FROM doi_vn_prod_resc WHERE yyyymm=@YYYYMM AND sel_code=@SEL_CODE GROUP BY 도우코드, division) pa
  LEFT JOIN DOI_MODEL_MAST mm ON mm.yyyymm=@YYYYMM AND mm.site=@SITE AND mm.MODEL=pa.도우코드
  WHERE pa.환산량>0 OR EXISTS(SELECT 1 FROM DOI_VN_MAT_INPUT mi WHERE mi.yyyymm=@YYYYMM AND mi.제품번호=pa.도우코드);  -- [VN 260801] 직과 재료 보존(전량손실 모델 포함, 공통/가공은 적수0)

  ---------------- (1) 재료비 배부 ----------------
  ;WITH
  matcls AS (SELECT 자재번호,
      MAX(CASE WHEN 품목자산분류=N'Raw Material' AND UPPER(자재소분류) LIKE N'%CHEMICAL%' THEN N'약액'
               WHEN 품목자산분류=N'Raw Material' THEN N'원재료'
               WHEN 품목자산분류=N'Sub Material' THEN N'부재료' ELSE N'기타' END) grp,
      MAX(CASE WHEN 품목자산분류=N'Raw Material' AND UPPER(자재소분류) LIKE N'%CHEMICAL%' THEN N'약액'
               WHEN 품목자산분류=N'Raw Material' THEN N'원자재'
               WHEN 품목자산분류=N'Sub Material' THEN N'부자재' ELSE N'기타' END) mat_class_hq
    FROM DOI_VN_MATERIAL WHERE yyyymm=@YYYYMM GROUP BY 자재번호),
  comm_src AS (SELECT r.품번 자재번호, SUM(CAST(r.투입금액 AS float)) 금액
    FROM DOI_MATL_RESC r JOIN matcls c ON c.자재번호=r.품번
    WHERE r.yyyymm=@YYYYMM AND r.site=@SITE AND ISNULL(r.투입금액,0)<>0 AND c.grp IN (N'약액',N'부재료') GROUP BY r.품번),
  tot_chg AS (SELECT SUM(환산량*면적) s FROM #prod),
  common_calc AS (SELECT p.구분,p.도우모델,p.도우코드,p.in_qty, s.자재번호,
      ROUND(s.금액*(p.환산량*p.면적/NULLIF(t.s,0)),2) 배부금액,
      ROW_NUMBER() OVER (PARTITION BY s.자재번호 ORDER BY p.환산량*p.면적 DESC,p.도우코드) rn,
      SUM(ROUND(s.금액*(p.환산량*p.면적/NULLIF(t.s,0)),2)) OVER (PARTITION BY s.자재번호) sum_배부, s.금액 in_amt
    FROM comm_src s CROSS JOIN #prod p CROSS JOIN tot_chg t),
  mat_rows AS (
    -- 직과
    SELECT p.구분,p.도우모델,mi.제품번호 도우코드, mi.자재번호, N'직과' 배부방식, p.in_qty,
           CAST(SUM(CAST(mi.투입금액 AS float)) AS float) 배부금액
    FROM DOI_VN_MAT_INPUT mi JOIN matcls c ON c.자재번호=mi.자재번호 JOIN #prod p ON p.도우코드=mi.제품번호
    WHERE mi.yyyymm=@YYYYMM AND c.grp=N'원재료'
    GROUP BY p.구분,p.도우모델,mi.제품번호,mi.자재번호,p.in_qty
    UNION ALL
    -- 공통 (잔차 rn=1 보정)
    SELECT 구분,도우모델,도우코드,자재번호, N'공통', in_qty,
           CAST(배부금액 + CASE WHEN rn=1 THEN (in_amt-sum_배부) ELSE 0 END AS float)
    FROM common_calc)
  INSERT INTO doi_expn_matl
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,원가구분,EXPEN_SEL,expen_sel명,분류,항목,배부방식,투입수량,투입금액)
  SELECT @YYYYMM,@SEL_CODE,@SITE, r.구분, r.도우코드, r.도우모델, N'재료비',
    CASE WHEN r.배부방식=N'직과' THEN 'MDAX' ELSE 'MIAX' END,
    CASE WHEN r.배부방식=N'직과' THEN N'직접재료비' ELSE N'간접재료비' END,
    CASE WHEN r.배부방식=N'직과' THEN N'원장' ELSE N'기타' END,
    r.자재번호, r.배부방식, CAST(r.in_qty AS numeric(18,2)), CAST(r.배부금액 AS numeric(18,2))
  FROM mat_rows r
  WHERE ABS(r.배부금액)>0.0000001;

  ---------------- (2) 가공비 배부 (UTG, 카세트 제외) ----------------
  ;WITH
  MODEL_RATE AS (
    SELECT 구분, 도우코드, 도우모델, in_qty,
      CAST(CAST(환산량*면적 AS numeric(38,25))/NULLIF(SUM(환산량*면적) OVER(),0) AS numeric(38,25)) dist_rate
    FROM #prod),
  sum_expen AS (
    SELECT EXPEN_SEL, MAX(EXPEN_SEL명) EXPEN_SEL명, ACCT_NAME, DISP_SEQ, SUM(CAST(ACCT_AMT AS float)) total
    FROM doi_acct_expen a
    WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND a.sel_code=@SEL_CODE
      AND a.acct LIKE '62%' AND a.acct NOT LIKE '621%' AND a.acct NOT LIKE '6272%'
      AND ISNULL(a.expen_sel,'')<>'' AND ISNULL(a.dept,'') NOT IN ('400','448')
    GROUP BY EXPEN_SEL, ACCT_NAME, DISP_SEQ),
  calc AS (
    SELECT a.EXPEN_SEL, a.EXPEN_SEL명, a.ACCT_NAME, a.DISP_SEQ, b.구분, b.도우코드, b.도우모델, b.in_qty,
      a.total Original_Total, ROUND(a.total*b.dist_rate,2) Base_IN,
      SUM(ROUND(a.total*b.dist_rate,2)) OVER (PARTITION BY a.EXPEN_SEL,a.ACCT_NAME,a.DISP_SEQ) Sum_Base_IN,
      ROW_NUMBER() OVER (PARTITION BY a.EXPEN_SEL,a.ACCT_NAME,a.DISP_SEQ ORDER BY b.dist_rate DESC, b.도우코드) rn
    FROM sum_expen a INNER JOIN MODEL_RATE b ON 1=1)
  INSERT INTO doi_expn_matl
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,원가구분,EXPEN_SEL,expen_sel명,분류,항목,배부방식,투입수량,투입금액)
  SELECT @YYYYMM,@SEL_CODE,@SITE, c.구분, c.도우코드, c.도우모델, N'가공비',
    c.EXPEN_SEL, c.EXPEN_SEL명, c.ACCT_NAME, N'UTG', N'-',
    CAST(c.in_qty AS numeric(18,2)),
    CAST(c.Base_IN + CASE WHEN c.rn=1 THEN (c.Original_Total - c.Sum_Base_IN) ELSE 0 END AS numeric(18,2))
  FROM calc c
  WHERE ABS(c.Base_IN + CASE WHEN c.rn=1 THEN (c.Original_Total - c.Sum_Base_IN) ELSE 0 END)>0.0000001;

  SELECT @mat=SUM(CASE WHEN 원가구분=N'재료비' THEN CAST(투입금액 AS float) ELSE 0 END),
         @exp=SUM(CASE WHEN 원가구분=N'가공비' THEN CAST(투입금액 AS float) ELSE 0 END),
         @cnt=COUNT(*) FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 투입배부 완료 ('+CAST(@cnt AS varchar(20))+N'행, 재료 '+CONVERT(varchar(30),CAST(@mat AS money),1)+N' + 가공 '+CONVERT(varchar(30),CAST(@exp AS money),1)+N')';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_EXPN_INPUT','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message=@Message+CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_EXPN_INPUT','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
