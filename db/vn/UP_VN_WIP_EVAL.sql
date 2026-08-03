CREATE OR ALTER PROCEDURE dbo.UP_VN_WIP_EVAL @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-6] 재공평가 → DOI_COST : 3단계 분리(가독성·중간검증)
   [1] 재공평가  → TMP_VN_COST_EOH : 원가항목별 BOH/IN/단가/EOHEQ/EOH + 수량 (재공 가치 확정)
   [2] 원가조립  → TMP_VN_COST     : EOH 기준 OUT/LOSS/out_단가 + 기타입고 재유입(RMAIN/ETC_IN_DEF_RW) + PL금액
   [3] 최종      → DOI_COST        : TMP_VN_COST 그대로 입력
   각 단계 후 검증(EOH 대사 / 원가보존 BOH+IN=OUT+EOH+LOSS)을 로그에 기록.
   * 카세트 등 별도 그룹 확장 시 [3]에서 UNION ALL 지점 사용. */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int, @boh float, @inn float, @out float, @eoh float, @loss float, @src float, @dst float;
  SET @Message='[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 재공평가(3단계) 시작';
  BEGIN TRY

  /* ============ [1] 재공평가 → TMP_VN_COST_EOH  (EOH 확정 + 공정별 재공금액 PL전/후_AMT) ============ */
  DELETE FROM TMP_VN_COST_EOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
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
  -- 공정별 재공수량 (PL전/PL후/입고전) : 재공금액 분해용
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
       COALESCE(i.원가구분, CASE WHEN LEFT(k.EXPEN_SEL,1)='M' THEN N'재료비' ELSE N'가공비' END) 원가구분,
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
      ROW_NUMBER() OVER (PARTITION BY 구분,도우코드,원가구분 ORDER BY Ori_eoh DESC, 항목) rn_e,
      SUM(unit_cost) OVER (PARTITION BY 구분,도우코드) uc_tot,          -- 도우코드 단가합(공정별 재공금액용)
      ROW_NUMBER() OVER (PARTITION BY 구분,도우코드 ORDER BY inn DESC, 항목) rn_amt FROM ori)
  INSERT INTO TMP_VN_COST_EOH
    (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,원가구분,EXPEN_SEL,expen_sel명,분류,항목,ADJ_YN,
     BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,ADJ_QTY,DEF_RW_QTY,TRANSFER_IN_QTY,BOH,[IN],UNIT_COST,EOHEQ,EOH,PL전_AMT,PL후_AMT,입고전_AMT)
  SELECT @YYYYMM,@SEL_CODE,@SITE,e.구분,e.도우코드,e.도우모델,e.원가구분,e.EXPEN_SEL,e.expen_sel명,e.분류,e.항목,e.adj_yn,
     CAST(e.boh_qty AS int),CAST(e.in_qty AS int),CAST(e.eoh_qty AS int),CAST(e.out_qty AS int),CAST(e.loss_qty AS int),CAST(e.adj_qty AS int),CAST(e.def_rw_qty AS int),CAST(e.transfer_in_qty AS int),
     CAST(e.boh AS numeric(18,2)),CAST(e.inn AS numeric(18,2)),CAST(e.unit_cost AS numeric(24,12)),CAST(e.EOHEQ AS numeric(18,4)),
     CAST(e.Base_eoh + CASE WHEN e.rn_e=1 THEN ROUND(e.Sum_Ori,2)-e.Sum_Base ELSE 0 END AS numeric(18,2)),
     -- 공정별 재공금액 = 도우코드 단가합 × 공정수량 × 완성률 (대표행). EOH = PL전_AMT + PL후_AMT (정상생산)
     CASE WHEN e.rn_amt=1 THEN ROUND(e.uc_tot*ISNULL(pq.PL전_qty,0)*0.5,2) ELSE 0 END,
     CASE WHEN e.rn_amt=1 THEN ROUND(e.uc_tot*ISNULL(pq.PL후_qty,0)*0.9,2) ELSE 0 END,
     CASE WHEN e.rn_amt=1 THEN ROUND(e.uc_tot*ISNULL(pq.입고전_qty,0)*1.0,2) ELSE 0 END
  FROM eohc e LEFT JOIN pq ON pq.구분=e.구분 AND pq.도우코드=e.도우코드;
  -- 검증 [1]: EOH 대사
  SELECT @cnt=COUNT(*), @boh=SUM(CAST(BOH AS float)), @inn=SUM(CAST([IN] AS float)), @eoh=SUM(CAST(EOH AS float))
    FROM TMP_VN_COST_EOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[1.재공평가] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- TMP_VN_COST_EOH '+CAST(@cnt AS varchar(20))+N'행, BOH '+CONVERT(varchar(30),CAST(@boh AS money),1)+N' + IN '+CONVERT(varchar(30),CAST(@inn AS money),1)+N' → EOH '+CONVERT(varchar(30),CAST(@eoh AS money),1);

  /* ============ [2] 원가조립 → TMP_VN_COST  (OUT/LOSS/out_단가/기타입고 재유입). PL전/후_AMT는 [1]에서 이어받음 ============ */
  DELETE FROM TMP_VN_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  ;WITH base AS (
    SELECT t.*,
       -- LOSS: 전량손실이면 BOH+IN 아니면 0 (ACTUAL)
       CAST(CASE WHEN (t.BOH_QTY+t.IN_QTY=t.LOSS_QTY) AND t.LOSS_QTY>0 THEN t.BOH+t.[IN] ELSE 0 END AS numeric(18,2)) LOSS_AMT
    FROM TMP_VN_COST_EOH t WHERE t.yyyymm=@YYYYMM AND t.site=@SITE AND t.sel_code=@SEL_CODE)
  INSERT INTO TMP_VN_COST
    (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
     BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,BAD_QTY,TRANSFER_QTY,ADJ_QTY,UNIT_COST,BOH,[IN],EOH,OUT_단가,[OUT],LOSS,BAD,TRANSFER,ADJ_YN,UnitCost_YN,
     ETC_IN_DEF_RW_QTY,ETC_IN_DEF_RW_AMT,RMAIN_QTY,RMAIN_AMT,PL전_AMT,PL후_AMT,입고전_AMT)
  SELECT @YYYYMM,@SEL_CODE,@SITE,b.구분,b.도우모델,b.도우코드,b.expen_sel명,b.분류,b.항목,b.EXPEN_SEL,
     b.BOH_QTY,b.IN_QTY,b.EOH_QTY,b.OUT_QTY,b.LOSS_QTY,0,0,b.ADJ_QTY,b.UNIT_COST,b.BOH,b.[IN],b.EOH,
     CAST(CASE WHEN b.OUT_QTY>0 THEN (b.BOH+b.[IN]-b.EOH-b.LOSS_AMT)/b.OUT_QTY ELSE b.UNIT_COST END AS numeric(24,12)),
     CAST(b.BOH+b.[IN]-b.EOH-b.LOSS_AMT AS numeric(18,2)),   -- OUT (원가보존)
     b.LOSS_AMT, 0, 0, b.ADJ_YN, 1,
     -- [VN 260801] 재유입(불량RW) 금액 미반영: 당월 재작업이라 원가가 이미 투입에 포함 → 별도 가치 계상 시 이중계상. 수량만 보조표기(금액 0).
     b.DEF_RW_QTY, CAST(0 AS numeric(18,2)),
     b.TRANSFER_IN_QTY, CAST(0 AS numeric(18,2)),
     b.PL전_AMT, b.PL후_AMT, b.입고전_AMT   -- [1] 재공평가에서 확정된 공정별 재공금액 이어받기
  FROM base b;
  -- 검증 [2]: 원가보존 BOH+IN = OUT+EOH+LOSS
  SELECT @src=SUM(CAST(BOH AS float)+CAST([IN] AS float)), @dst=SUM(CAST([OUT] AS float)+CAST(EOH AS float)+CAST(LOSS AS float)),
         @out=SUM(CAST([OUT] AS float)), @loss=SUM(CAST(LOSS AS float))
    FROM TMP_VN_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[2.원가조립] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- TMP_VN_COST 원가보존 투입 '+CONVERT(varchar(30),CAST(@src AS money),1)+N' = OUT '+CONVERT(varchar(30),CAST(@out AS money),1)+N'+EOH '+CONVERT(varchar(30),CAST(@eoh AS money),1)+N'+LOSS '+CONVERT(varchar(30),CAST(@loss AS money),1)+N' (차 '+CONVERT(varchar(30),CAST(@src-@dst AS money),1)+N')';

  /* ============ [3] 최종 → DOI_COST ============ */
  DELETE FROM DOI_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  INSERT INTO DOI_COST
    (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
     BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,BAD_QTY,TRANSFER_QTY,ADJ_QTY,UNIT_COST,BOH,[IN],EOH,OUT_단가,[OUT],LOSS,BAD,TRANSFER,ADJ_YN,UnitCost_YN,
     ETC_IN_DEF_RW_QTY,ETC_IN_DEF_RW_AMT,RMAIN_QTY,RMAIN_AMT,PL전_AMT,PL후_AMT,입고전_AMT)
  SELECT YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
     BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,BAD_QTY,TRANSFER_QTY,ADJ_QTY,UNIT_COST,BOH,[IN],EOH,OUT_단가,[OUT],LOSS,BAD,TRANSFER,ADJ_YN,UnitCost_YN,
     ETC_IN_DEF_RW_QTY,ETC_IN_DEF_RW_AMT,RMAIN_QTY,RMAIN_AMT,PL전_AMT,PL후_AMT,입고전_AMT
  FROM TMP_VN_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  -- (카세트 등 별도 그룹은 여기서 UNION ALL로 추가)

  SELECT @cnt=COUNT(*) FROM DOI_COST WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[3.DOI_COST] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- DOI_COST '+CAST(@cnt AS varchar(20))+N'행 입력 완료';
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
