CREATE OR ALTER PROCEDURE dbo.UP_VN_WIP_EVAL @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731] 재공평가 → doi_cost_wip (투입비용 함수에서 분리)
   입력 = doi_cost_unit(단가) + DOI_COST_BOH(기초) + doi_vn_expn_matl(투입) + V_DOI_PROD_SUBUL(수량) + V_VN_WIP_CONV(EOHEQ) + DOI_PROD_SUBUL(PL전/PL후 수량)
   EOH  = 특수케이스면 (기초+투입) 아니면 단가×EOHEQ, (구분,도우코드,원가구분)별 ROUND 합 + rn=1 잔차보정  (UP_VN_COST 동일)
   PL전/PL후/입고전_AMT = SUM(단가) × 해당수량 × 완성률(0.5/0.9/1.0), 도우코드 대표행(rn=1) */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int, @eoh float;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 재공평가(doi_cost_wip) 시작';
  BEGIN TRY

  DELETE FROM doi_cost_wip WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  ;WITH
  -- 도우코드별 생산수불 수량
  qty AS (
    SELECT 구분, 도우코드,
      SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty, SUM(CAST(ISNULL(IN_MONTH,0) AS float)) in_qty,
      SUM(CAST(ISNULL(EOH_MONTH,0) AS float)) eoh_qty, SUM(CAST(ISNULL(OUT_MONTH,0) AS float)) out_qty,
      SUM(CAST(ISNULL(LOSS_MONTH,0) AS float)) loss_qty
    FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분, 도우코드),
  -- 도우코드별 EOHEQ, 완성률 수량(PL전/PL후/입고전)
  conv AS (SELECT wc_gubun 구분, wc_code 도우코드, EOHEQ FROM V_VN_WIP_CONV WHERE wc_ym=@YYYYMM AND wc_site=@SITE),
  pq AS (SELECT 구분, 도우코드,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N''))) PL전_qty,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N''))) PL후_qty,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(입고전,N'0'),N',',N''),N' ',N''))) 입고전_qty
    FROM DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분, 도우코드),
  -- 투입(공정합), 기초, 단가 결합 (원가항목 그레인)
  inp AS (SELECT 구분,도우코드,원가구분,EXPEN_SEL,분류,항목, SUM(CAST(투입금액 AS float)) inn
          FROM doi_vn_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
          GROUP BY 구분,도우코드,원가구분,EXPEN_SEL,분류,항목),
  item AS (
    SELECT u.구분, u.도우코드, u.도우모델, u.원가구분, u.EXPEN_SEL, u.분류, u.항목,
           CAST(u.단가 AS float) unit_cost,
           ISNULL(b.BOH,0) boh, ISNULL(i.inn,0) inn,
           q.boh_qty,q.in_qty,q.eoh_qty,q.out_qty,q.loss_qty, ISNULL(cv.EOHEQ,0) EOHEQ
    FROM doi_cost_unit u
      LEFT JOIN inp i ON i.구분=u.구분 AND i.도우코드=u.도우코드 AND i.원가구분=u.원가구분 AND i.EXPEN_SEL=u.EXPEN_SEL AND i.분류=u.분류 AND i.항목=u.항목
      LEFT JOIN DOI_COST_BOH b ON b.yyyymm=@YYYYMM AND b.site=@SITE AND b.sel_code=@SEL_CODE
            AND b.구분=u.구분 AND b.도우코드=u.도우코드 AND b.EXPEN_SEL=u.EXPEN_SEL AND b.ACCT_NAME=u.분류 AND b.ITEM_NAME=u.항목
      LEFT JOIN qty q ON q.구분=u.구분 AND q.도우코드=u.도우코드
      LEFT JOIN conv cv ON cv.구분=u.구분 AND cv.도우코드=u.도우코드
    WHERE u.yyyymm=@YYYYMM AND u.site=@SITE AND u.sel_code=@SEL_CODE),
  -- Ori_eoh (특수케이스 = 전량 재공/손실 → 기초+투입, else 단가×EOHEQ)
  ori AS (
    SELECT it.*,
      CASE WHEN (boh_qty+in_qty=eoh_qty OR boh_qty+in_qty=eoh_qty+loss_qty OR (out_qty=0 AND loss_qty>0)) AND eoh_qty<>0
           THEN boh+inn ELSE unit_cost*EOHEQ END Ori_eoh
    FROM item it),
  eohc AS (
    SELECT *, ROUND(Ori_eoh,0) Base_eoh,
      SUM(Ori_eoh) OVER (PARTITION BY 구분,도우코드,원가구분) Sum_Ori,
      SUM(ROUND(Ori_eoh,0)) OVER (PARTITION BY 구분,도우코드,원가구분) Sum_Base,
      ROW_NUMBER() OVER (PARTITION BY 구분,도우코드,원가구분 ORDER BY Ori_eoh DESC, 항목) rn_e
    FROM ori),
  -- 도우코드 단가합 (PL전/후 금액용, 재료+가공 전체)
  uc AS (SELECT 구분,도우코드, SUM(unit_cost) uc_tot FROM item GROUP BY 구분,도우코드),
  final AS (
    SELECT e.*,
      CAST(e.Base_eoh + CASE WHEN e.rn_e=1 THEN ROUND(e.Sum_Ori,0)-e.Sum_Base ELSE 0 END AS numeric(18,2)) EOH,
      ROW_NUMBER() OVER (PARTITION BY e.구분,e.도우코드 ORDER BY e.inn DESC, e.항목) rn_amt
    FROM eohc e)
  INSERT INTO doi_cost_wip
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,원가구분,EXPEN_SEL,분류,항목,BOH,[IN],UNIT_COST,EOHEQ,EOH,PL전_AMT,PL후_AMT,입고전_AMT)
  SELECT @YYYYMM,@SEL_CODE,@SITE, f.구분,f.도우코드,f.도우모델,f.원가구분,f.EXPEN_SEL,f.분류,f.항목,
    CAST(f.boh AS numeric(18,2)), CAST(f.inn AS numeric(18,2)), CAST(f.unit_cost AS numeric(24,12)),
    CAST(f.EOHEQ AS numeric(18,4)), f.EOH,
    CASE WHEN f.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.PL전_qty,0)*0.5,2) ELSE 0 END,
    CASE WHEN f.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.PL후_qty,0)*0.9,2) ELSE 0 END,
    CASE WHEN f.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.입고전_qty,0)*1.0,2) ELSE 0 END
  FROM final f
    JOIN uc ON uc.구분=f.구분 AND uc.도우코드=f.도우코드
    LEFT JOIN pq ON pq.구분=f.구분 AND pq.도우코드=f.도우코드;

  -- [스위치 260731] 재공평가 결과를 DOI_COST에 반영(권위 소스). EOH/PL전/PL후/입고전_AMT.
  -- OUT=BOH+IN-EOH는 EOH에 종속이나 값이 동일하므로 정합 유지. UP_VN_COST의 재공평가 블록은 이후 제거(수정스펙).
  UPDATE d SET d.EOH=w.EOH, d.PL전_AMT=w.PL전_AMT, d.PL후_AMT=w.PL후_AMT, d.입고전_AMT=w.입고전_AMT
  FROM DOI_COST d
  JOIN doi_cost_wip w ON w.yyyymm=d.yyyymm AND w.site=d.site AND w.sel_code=d.sel_code
    AND w.구분=d.구분 AND w.도우코드=d.도우코드 AND w.EXPEN_SEL=d.EXPEN_SEL AND w.분류=d.ACCT_NAME AND w.항목=d.ITEM_NAME
  WHERE d.yyyymm=@YYYYMM AND d.site=@SITE AND d.sel_code=@SEL_CODE AND LEN(d.model)<=5;

  SELECT @cnt=COUNT(*), @eoh=SUM(CAST(EOH AS float)) FROM doi_cost_wip WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재공평가 완료 ('+CAST(@cnt AS varchar(20))+N'행, EOH합 '+CONVERT(varchar(30),CAST(@eoh AS money),1)+N')';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_WIP_EVAL','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_WIP_EVAL','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
