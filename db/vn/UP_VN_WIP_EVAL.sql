CREATE OR ALTER PROCEDURE dbo.UP_VN_WIP_EVAL @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-5] 재공평가 → DOI_COST 완전 생성 (구 UP_VN_COST의 VN 조립 대체)
   입력: doi_cost_unit(단가) + doi_expn_matl(투입) + DOI_COST_BOH(기초) + V_DOI_PROD_SUBUL(수량) + DOI_PROD_SUBUL(기타입고/PL) + V_VN_WIP_CONV(EOHEQ)
   생성: 수량(BOH/IN/EOH/OUT/LOSS/ADJ) + 금액(BOH/IN/EOH/OUT/LOSS/BAD/TRANSFER) + out_단가
         + 기타입고 재유입(ETC_IN_DEF_RW=불량RW, RMAIN=기타입고합계) 재공금액 + PL전/후/입고전_AMT
   EOH = 특수케이스(boh_qty+in_qty=eoh_qty 등)면 BOH+IN, 아니면 단가×EOHEQ. (구분,도우코드,원가구분)별 소수2 반올림+rn1 잔차.
   원가보존: BOH+IN = OUT+EOH+LOSS. (BAD/TRANSFER=0 VN) */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int, @boh float, @inn float, @out float, @eoh float, @loss float;
  SET @Message='[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 재공평가(DOI_COST) 시작';
  BEGIN TRY
  DELETE FROM DOI_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  ;WITH
  qty AS (SELECT 구분,도우코드,
      SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty, SUM(CAST(ISNULL(IN_MONTH,0) AS float)) in_qty,
      SUM(CAST(ISNULL(EOH_MONTH,0) AS float)) eoh_qty, SUM(CAST(ISNULL(OUT_MONTH,0) AS float)) out_qty,
      SUM(CAST(ISNULL(LOSS_MONTH,0) AS float)) loss_qty,
      SUM(CAST(ISNULL(IN_MONTH,0)+ISNULL(OUT_MONTH,0)+ISNULL(LOSS_MONTH,0) AS float))/2.0 adj_qty
    FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분,도우코드),
  etc AS (SELECT 구분,도우코드,
      SUM(CAST(ISNULL(기타입고_불량_RW,0) AS float)) def_rw_qty,
      SUM(CAST(ISNULL(기타입고_LOT변환,0)+ISNULL(기타입고_불량_RW,0)+ISNULL(기타입고_RMA_RW,0)+ISNULL(기타입고_전월불량,0)+ISNULL(기타입고_당월불량,0) AS float)) transfer_in_qty
    FROM DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분,도우코드),
  conv AS (SELECT wc_gubun 구분, wc_code 도우코드, EOHEQ FROM V_VN_WIP_CONV WHERE wc_ym=@YYYYMM AND wc_site=@SITE),
  pq AS (SELECT 구분,도우코드,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N''))) PL전_qty,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N''))) PL후_qty,
      SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(입고전,N'0'),N',',N''),N' ',N''))) 입고전_qty
    FROM DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 구분,도우코드),
  inp AS (SELECT 구분,도우코드,MAX(도우모델) 도우모델, MAX(원가구분) 원가구분, MAX(expen_sel명) expen_sel명, EXPEN_SEL,분류,항목, SUM(CAST(투입금액 AS float)) inn
          FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY 구분,도우코드,EXPEN_SEL,분류,항목),
  bh AS (SELECT 구분,도우코드,MAX(MODEL) 도우모델, MAX(expen_sel명) expen_sel명, MAX(ADJ_YN) adj_yn, EXPEN_SEL,ACCT_NAME 분류,ITEM_NAME 항목, SUM(CAST(BOH AS float)) boh
         FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY 구분,도우코드,EXPEN_SEL,ACCT_NAME,ITEM_NAME),
  keys AS (SELECT 구분,도우코드,EXPEN_SEL,분류,항목 FROM inp UNION SELECT 구분,도우코드,EXPEN_SEL,분류,항목 FROM bh),
  item AS (
    SELECT k.구분,k.도우코드, COALESCE(i.도우모델,b.도우모델,'') 도우모델,
       COALESCE(i.원가구분, CASE WHEN LEFT(k.EXPEN_SEL,1)='M' THEN N'재료비' WHEN k.EXPEN_SEL='*' THEN N'가공비' ELSE N'가공비' END) 원가구분,
       COALESCE(i.expen_sel명,b.expen_sel명,'') expen_sel명, ISNULL(b.adj_yn,'N') adj_yn,
       k.EXPEN_SEL,k.분류,k.항목, ISNULL(b.boh,0) boh, ISNULL(i.inn,0) inn, ISNULL(u.단가,0) unit_cost,
       q.boh_qty,q.in_qty,q.eoh_qty,q.out_qty,q.loss_qty,q.adj_qty, ISNULL(cv.EOHEQ,0) EOHEQ,
       ISNULL(e.def_rw_qty,0) def_rw_qty, ISNULL(e.transfer_in_qty,0) transfer_in_qty
    FROM keys k
      LEFT JOIN inp i ON i.구분=k.구분 AND i.도우코드=k.도우코드 AND i.EXPEN_SEL=k.EXPEN_SEL AND i.분류=k.분류 AND i.항목=k.항목
      LEFT JOIN bh  b ON b.구분=k.구분 AND b.도우코드=k.도우코드 AND b.EXPEN_SEL=k.EXPEN_SEL AND b.분류=k.분류 AND b.항목=k.항목
      LEFT JOIN doi_cost_unit u ON u.yyyymm=@YYYYMM AND u.site=@SITE AND u.sel_code=@SEL_CODE AND u.구분=k.구분 AND u.도우코드=k.도우코드 AND u.EXPEN_SEL=k.EXPEN_SEL AND u.분류=k.분류 AND u.항목=k.항목
      LEFT JOIN qty q ON q.구분=k.구분 AND q.도우코드=k.도우코드
      LEFT JOIN etc e ON e.구분=k.구분 AND e.도우코드=k.도우코드
      LEFT JOIN conv cv ON cv.구분=k.구분 AND cv.도우코드=k.도우코드),
  ori AS (SELECT it.*,
      CASE WHEN (boh_qty+in_qty=eoh_qty OR boh_qty+in_qty=eoh_qty+loss_qty OR (out_qty=0 AND loss_qty>0)) AND eoh_qty<>0
           THEN boh+inn ELSE unit_cost*EOHEQ END Ori_eoh
    FROM item it),
  eohc AS (SELECT *, ROUND(Ori_eoh,2) Base_eoh,
      SUM(Ori_eoh) OVER (PARTITION BY 구분,도우코드,원가구분) Sum_Ori,
      SUM(ROUND(Ori_eoh,2)) OVER (PARTITION BY 구분,도우코드,원가구분) Sum_Base,
      ROW_NUMBER() OVER (PARTITION BY 구분,도우코드,원가구분 ORDER BY Ori_eoh DESC, 항목) rn_e FROM ori),
  uc AS (SELECT 구분,도우코드, SUM(unit_cost) uc_tot FROM item GROUP BY 구분,도우코드),
  fin AS (SELECT e.*,
      CAST(e.Base_eoh + CASE WHEN e.rn_e=1 THEN ROUND(e.Sum_Ori,2)-e.Sum_Base ELSE 0 END AS numeric(18,2)) EOH,
      ROW_NUMBER() OVER (PARTITION BY e.구분,e.도우코드 ORDER BY e.inn DESC, e.항목) rn_amt FROM eohc e),
  calc AS (SELECT f.*,
      -- LOSS: 전량손실이면 BOH+IN, 아니면 0(ACTUAL) / ACTLSS면 단가배분
      CAST(CASE WHEN (f.boh_qty+f.in_qty=f.loss_qty) AND f.loss_qty>0 THEN f.boh+f.inn
                WHEN @SEL_CODE<>'ACTLSS' THEN 0
                ELSE CASE WHEN (f.out_qty+CASE WHEN @SEL_CODE='ACTLSS' THEN f.loss_qty ELSE 0 END)>0
                          THEN ROUND((f.boh+f.inn-f.EOH)/(f.out_qty+f.loss_qty)*f.loss_qty,2) ELSE 0 END END AS numeric(18,2)) LOSS_AMT
    FROM fin f)
  INSERT INTO DOI_COST
    (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
     BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,BAD_QTY,TRANSFER_QTY,ADJ_QTY,
     UNIT_COST,BOH,[IN],EOH,OUT_단가,[OUT],LOSS,BAD,TRANSFER,ADJ_YN,UnitCost_YN,
     ETC_IN_DEF_RW_QTY,ETC_IN_DEF_RW_AMT,RMAIN_QTY,RMAIN_AMT,PL전_AMT,PL후_AMT,입고전_AMT)
  SELECT @YYYYMM,@SEL_CODE,@SITE,c.구분,c.도우모델,c.도우코드,c.expen_sel명,c.분류,c.항목,c.EXPEN_SEL,
     CAST(c.boh_qty AS int),CAST(c.in_qty AS int),CAST(c.eoh_qty AS int),CAST(c.out_qty AS int),CAST(c.loss_qty AS int),0,0,CAST(c.adj_qty AS int),
     CAST(c.unit_cost AS numeric(24,12)), CAST(c.boh AS numeric(18,2)), CAST(c.inn AS numeric(18,2)), c.EOH,
     -- out_단가 = OUT금액/OUT수량 (OUT=BOH+IN-EOH-LOSS 로 원가보존)
     CAST(CASE WHEN c.out_qty>0 THEN (c.boh+c.inn-c.EOH-c.LOSS_AMT)/c.out_qty ELSE c.unit_cost END AS numeric(24,12)),
     CAST(c.boh+c.inn-c.EOH-c.LOSS_AMT AS numeric(18,2)),   -- OUT (원가보존)
     c.LOSS_AMT, 0, 0, c.adj_yn, 1,
     CAST(c.def_rw_qty AS int), CAST(ROUND(c.def_rw_qty*c.unit_cost,2) AS numeric(18,2)),
     CAST(c.transfer_in_qty AS int), CAST(ROUND(c.transfer_in_qty*c.unit_cost,2) AS numeric(18,2)),
     CASE WHEN c.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.PL전_qty,0)*0.5,2) ELSE 0 END,
     CASE WHEN c.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.PL후_qty,0)*0.9,2) ELSE 0 END,
     CASE WHEN c.rn_amt=1 THEN ROUND(uc.uc_tot*ISNULL(pq.입고전_qty,0)*1.0,2) ELSE 0 END
  FROM calc c JOIN uc ON uc.구분=c.구분 AND uc.도우코드=c.도우코드
    LEFT JOIN pq ON pq.구분=c.구분 AND pq.도우코드=c.도우코드;

  SELECT @cnt=COUNT(*), @boh=SUM(CAST(BOH AS float)), @inn=SUM(CAST([IN] AS float)),
         @out=SUM(CAST([OUT] AS float)), @eoh=SUM(CAST(EOH AS float)), @loss=SUM(CAST(LOSS AS float))
    FROM DOI_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재공평가(DOI_COST) 완료 ('+CAST(@cnt AS varchar(20))
     +N'행, 투입 BOH+IN '+CONVERT(varchar(30),CAST(@boh+@inn AS money),1)+N' = OUT '+CONVERT(varchar(30),CAST(@out AS money),1)
     +N' + EOH '+CONVERT(varchar(30),CAST(@eoh AS money),1)+N' + LOSS '+CONVERT(varchar(30),CAST(@loss AS money),1)+N')';
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
