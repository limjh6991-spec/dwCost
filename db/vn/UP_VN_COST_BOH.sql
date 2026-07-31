CREATE OR ALTER PROCEDURE dbo.UP_VN_COST_BOH @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-2] 기초금액 → DOI_COST_BOH  (★ doi_mat_cost/doi_expen_matl 미사용)
   정상월: 전월 DOI_COST.EOH 이월(원가항목 그레인)
   초기월(전월 EOH 없음): doi_boh_amt(재료비기초/경비기초, 도우코드) 를 doi_expn_matl 투입비율로 원가항목 분배
     - 투입있는 도우코드: 재료비기초→재료항목, 경비기초→가공항목 (투입금액 비율, rn=1 잔차)
     - 투입없는(환산량=0) 도우코드: 대표 '*' 행에 PRE_EOH_AMT 전액 (재공 유지 → 하류 BOH=EOH). 기초 전액 보존. */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @tot float, @cnt int, @prev varchar(6), @hasPrev int;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 기초금액(DOI_COST_BOH) 시작';
  BEGIN TRY
  SET @prev = FORMAT(DATEADD(MONTH,-1,CONVERT(date,@YYYYMM+'01')),'yyyyMM');
  SELECT @hasPrev = CASE WHEN EXISTS(SELECT 1 FROM DOI_COST WHERE yyyymm=@prev AND site=@SITE AND ISNULL(EOH,0)<>0) THEN 1 ELSE 0 END;

  DELETE FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  IF @hasPrev = 1
  BEGIN
     -- 정상월: 전월 EOH → 당월 기초 (원가항목 그레인)
     INSERT INTO DOI_COST_BOH (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
     SELECT @YYYYMM,@SEL_CODE,@SITE,구분,MODEL,ISNULL(도우코드,''),N'*',expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,EOH_QTY,CAST(EOH AS numeric(18,2))
     FROM DOI_COST WHERE yyyymm=@prev AND site=@SITE AND ISNULL(EOH,0)<>0;
  END
  ELSE
  BEGIN
     -- 초기월: doi_boh_amt 를 투입비율로 분배
     ;WITH boh AS (
        SELECT MODEL_TYPE 도우코드, MAX(MODEL) 도우모델, MAX(구분) 구분,
               SUM(CAST(재료비기초 AS float)) 재료기초, SUM(CAST(경비기초 AS float)) 경비기초, SUM(CAST(PRE_EOH_AMT AS float)) pre
        FROM doi_boh_amt WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY MODEL_TYPE),
     -- 도우코드 기초재공수량 (= 당월 생산수불 BOH_MONTH)
     qty AS (SELECT 도우코드, SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty
             FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드),
     -- 투입 원가항목(재료/가공) + 도우코드별 투입합
     e AS (SELECT 구분,도우코드,도우모델,원가구분,EXPEN_SEL,expen_sel명,분류,항목,CAST(투입금액 AS float) 투입금액,
                  SUM(CAST(투입금액 AS float)) OVER (PARTITION BY 도우코드,원가구분) tot_inp,
                  ROW_NUMBER() OVER (PARTITION BY 도우코드,원가구분 ORDER BY CAST(투입금액 AS float) DESC,항목) rn
           FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE),
     dist AS (
        SELECT e.구분,e.도우코드,e.도우모델,e.원가구분,e.EXPEN_SEL,e.expen_sel명,e.분류,e.항목,e.rn,
               b.재료기초,b.경비기초, ISNULL(q.boh_qty,0) boh_qty,
               CASE WHEN e.원가구분=N'재료비' AND e.tot_inp>0 THEN ROUND(b.재료기초*e.투입금액/e.tot_inp,2)
                    WHEN e.원가구분=N'가공비' AND e.tot_inp>0 THEN ROUND(b.경비기초*e.투입금액/e.tot_inp,2) ELSE 0 END boh_base
        FROM e JOIN boh b ON b.도우코드=e.도우코드 LEFT JOIN qty q ON q.도우코드=e.도우코드),
     dist2 AS (
        SELECT *, SUM(boh_base) OVER (PARTITION BY 도우코드,원가구분) sum_base FROM dist)
     -- (A) 투입있는 도우코드: 원가항목 분배 + rn=1 잔차보정
     INSERT INTO DOI_COST_BOH (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
     SELECT @YYYYMM,@SEL_CODE,@SITE,구분,도우모델,도우코드,N'*',expen_sel명,분류,항목,EXPEN_SEL,'N',CAST(boh_qty AS int),
            CAST(boh_base + CASE WHEN rn=1 THEN (CASE WHEN 원가구분=N'재료비' THEN 재료기초 ELSE 경비기초 END - sum_base) ELSE 0 END AS numeric(18,2))
     FROM dist2
     WHERE ABS(boh_base + CASE WHEN rn=1 THEN (CASE WHEN 원가구분=N'재료비' THEN 재료기초 ELSE 경비기초 END - sum_base) ELSE 0 END) > 0.0000001;

     -- (B) 투입없는(doi_expn_matl 미존재) 도우코드: 대표 '*' 행에 PRE_EOH_AMT 전액
     INSERT INTO DOI_COST_BOH (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
     SELECT @YYYYMM,@SEL_CODE,@SITE, ISNULL(b.구분,N'양산'), b.도우모델, b.MODEL_TYPE, N'*', N'기초이월', N'*', N'*', '*', 'Y',
            CAST(ISNULL(q.boh_qty,0) AS int), CAST(b.pre AS numeric(18,2))
     FROM (SELECT MODEL_TYPE, MAX(MODEL) 도우모델, MAX(구분) 구분, SUM(CAST(PRE_EOH_AMT AS float)) pre
           FROM doi_boh_amt WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY MODEL_TYPE) b
     LEFT JOIN (SELECT 도우코드, SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드) q ON q.도우코드=b.MODEL_TYPE
     WHERE ABS(b.pre) > 0.0000001
       AND NOT EXISTS (SELECT 1 FROM doi_expn_matl e WHERE e.yyyymm=@YYYYMM AND e.site=@SITE AND e.sel_code=@SEL_CODE AND e.도우코드=b.MODEL_TYPE);
  END

  SELECT @tot=SUM(CAST(BOH AS float)), @cnt=COUNT(*) FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 기초금액 완료 ('+CAST(@cnt AS varchar(20))+N'행, 기초합 '+CONVERT(varchar(30),CAST(@tot AS money),1)+N', '+CASE WHEN @hasPrev=1 THEN N'전월EOH이월' ELSE N'초기seed' END+N')';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_BOH','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message=@Message+CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_BOH','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
