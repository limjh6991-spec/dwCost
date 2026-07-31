CREATE OR ALTER PROCEDURE dbo.UP_VN_WIP_EVAL @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-2] 재공평가 → doi_cost_wip  (★ doi_mat_cost/doi_expen_matl 미사용)
   입력: doi_cost_unit(단가) + doi_expn_matl(투입) + DOI_COST_BOH(기초) + V_DOI_PROD_SUBUL(수량) + V_VN_WIP_CONV(EOHEQ)
   EOH = 특수케이스(전량재공/손실: boh_qty+in_qty=eoh_qty 등)면 BOH+IN, 아니면 단가×EOHEQ. (구분,도우코드,원가구분)별 ROUND합+rn1 잔차.
   기초만 있는 대표행('*',생산없음)은 특수케이스로 BOH=EOH(재공 유지).
   PL전/후/입고전_AMT = SUM(단가)×해당수량×완성률(0.5/0.9/1.0), 도우코드 대표행. */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int, @eoh float, @boh float, @inn float;
  SET @Message='[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 재공평가(doi_cost_wip) 시작';
  BEGIN TRY
  DELETE FROM doi_cost_wip WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  ;WITH
  qty AS (SELECT 구분,도우코드,
      SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty, SUM(CAST(ISNULL(IN_MONTH,0) AS float)) in_qty,
      SUM(CAST(ISNULL(EOH_MONTH,0) AS float)) eoh_qty, SUM(CAST(ISNULL(OUT_MONTH,0) AS float)) out_qty,
      SUM(CAST(ISNULL(LOSS_MONTH,0) AS float)) loss_qty
    FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분,도우코드),
  conv AS (SELECT wc_gubun 구분, wc_code 도우코드, EOHEQ FROM V_VN_WIP_CONV WHERE wc_ym=@YYYYMM AND wc_site=@SITE),
  pq AS (SELECT 구분,도우코드,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N''))) PL전_qty,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N''))) PL후_qty,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(입고전,N'0'),N',',N''),N' ',N''))) 입고전_qty
    FROM DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분,도우코드),
  inp AS (SELECT 구분,도우코드,MAX(도우모델) 도우모델, MAX(원가구분) 원가구분, EXPEN_SEL,분류,항목, SUM(CAST(투입금액 AS float)) inn
          FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY 구분,도우코드,EXPEN_SEL,분류,항목),
  bh AS (SELECT 구분,도우코드,MAX(MODEL) 도우모델, EXPEN_SEL,ACCT_NAME 분류,ITEM_NAME 항목, SUM(CAST(BOH AS float)) boh
         FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY 구분,도우코드,EXPEN_SEL,ACCT_NAME,ITEM_NAME),
  keys AS (SELECT 구분,도우코드,EXPEN_SEL,분류,항목 FROM inp UNION SELECT 구분,도우코드,EXPEN_SEL,분류,항목 FROM bh),
  item AS (
    SELECT k.구분,k.도우코드, COALESCE(i.도우모델,b.도우모델,'') 도우모델,
       COALESCE(i.원가구분, CASE WHEN LEFT(k.EXPEN_SEL,1)='M' THEN N'재료비' WHEN k.EXPEN_SEL='*' THEN N'기초' ELSE N'가공비' END) 원가구분,
       k.EXPEN_SEL,k.분류,k.항목, ISNULL(b.boh,0) boh, ISNULL(i.inn,0) inn, ISNULL(u.단가,0) unit_cost,
       q.boh_qty,q.in_qty,q.eoh_qty,q.out_qty,q.loss_qty, ISNULL(cv.EOHEQ,0) EOHEQ
    FROM keys k
      LEFT JOIN inp i ON i.구분=k.구분 AND i.도우코드=k.도우코드 AND i.EXPEN_SEL=k.EXPEN_SEL AND i.분류=k.분류 AND i.항목=k.항목
      LEFT JOIN bh  b ON b.구분=k.구분 AND b.도우코드=k.도우코드 AND b.EXPEN_SEL=k.EXPEN_SEL AND b.분류=k.분류 AND b.항목=k.항목
      LEFT JOIN doi_cost_unit u ON u.yyyymm=@YYYYMM AND u.site=@SITE AND u.sel_code=@SEL_CODE AND u.구분=k.구분 AND u.도우코드=k.도우코드 AND u.EXPEN_SEL=k.EXPEN_SEL AND u.분류=k.분류 AND u.항목=k.항목
      LEFT JOIN qty q ON q.구분=k.구분 AND q.도우코드=k.도우코드
      LEFT JOIN conv cv ON cv.구분=k.구분 AND cv.도우코드=k.도우코드),
  ori AS (SELECT it.*,
      CASE WHEN (boh_qty+in_qty=eoh_qty OR boh_qty+in_qty=eoh_qty+loss_qty OR (out_qty=0 AND loss_qty>0)) AND eoh_qty<>0
           THEN boh+inn ELSE unit_cost*EOHEQ END Ori_eoh
    FROM item it),
  eohc AS (SELECT *, ROUND(Ori_eoh,0) Base_eoh,
      SUM(Ori_eoh) OVER (PARTITION BY 구분,도우코드,원가구분) Sum_Ori,
      SUM(ROUND(Ori_eoh,0)) OVER (PARTITION BY 구분,도우코드,원가구분) Sum_Base,
      ROW_NUMBER() OVER (PARTITION BY 구분,도우코드,원가구분 ORDER BY Ori_eoh DESC, 항목) rn_e FROM ori),
  uc AS (SELECT 구분,도우코드, SUM(unit_cost) uc_tot FROM item GROUP BY 구분,도우코드),
  fin AS (SELECT e.*,
      CAST(e.Base_eoh + CASE WHEN e.rn_e=1 THEN ROUND(e.Sum_Ori,0)-e.Sum_Base ELSE 0 END AS numeric(18,2)) EOH,
      ROW_NUMBER() OVER (PARTITION BY e.구분,e.도우코드 ORDER BY e.inn DESC, e.항목) rn_amt FROM eohc e)
  INSERT INTO doi_cost_wip
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,원가구분,EXPEN_SEL,분류,항목,BOH,[IN],UNIT_COST,EOHEQ,EOH,[OUT],LOSS,PL전_AMT,PL후_AMT,입고전_AMT)
  SELECT @YYYYMM,@SEL_CODE,@SITE,f.구분,f.도우코드,f.도우모델,f.원가구분,f.EXPEN_SEL,f.분류,f.항목,
    CAST(f.boh AS numeric(18,2)), CAST(f.inn AS numeric(18,2)), CAST(f.unit_cost AS numeric(24,12)),
    CAST(f.EOHEQ AS numeric(18,4)), f.EOH,
    -- OUT = 투입-재공-손실(원가보존), LOSS = 전량손실이면 BOH+IN 아니면 0(ACTUAL)
    CAST(f.boh+f.inn - f.EOH - CASE WHEN (f.boh_qty+f.in_qty=f.loss_qty) AND f.loss_qty>0 THEN f.boh+f.inn ELSE 0 END AS numeric(18,2)),
    CAST(CASE WHEN (f.boh_qty+f.in_qty=f.loss_qty) AND f.loss_qty>0 THEN f.boh+f.inn ELSE 0 END AS numeric(18,2)),
    CASE WHEN f.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.PL전_qty,0)*0.5,2) ELSE 0 END,
    CASE WHEN f.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.PL후_qty,0)*0.9,2) ELSE 0 END,
    CASE WHEN f.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.입고전_qty,0)*1.0,2) ELSE 0 END
  FROM fin f JOIN uc ON uc.구분=f.구분 AND uc.도우코드=f.도우코드
    LEFT JOIN pq ON pq.구분=f.구분 AND pq.도우코드=f.도우코드;

  SELECT @cnt=COUNT(*), @eoh=SUM(CAST(EOH AS float)), @boh=SUM(CAST(BOH AS float)), @inn=SUM(CAST([IN] AS float))
    FROM doi_cost_wip WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재공평가 완료 ('+CAST(@cnt AS varchar(20))+N'행, BOH '+CONVERT(varchar(30),CAST(@boh AS money),1)+N' + IN '+CONVERT(varchar(30),CAST(@inn AS money),1)+N' → EOH '+CONVERT(varchar(30),CAST(@eoh AS money),1)+N')';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_WIP_EVAL','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message=@Message+CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_WIP_EVAL','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
