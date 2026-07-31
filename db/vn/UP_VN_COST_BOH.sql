CREATE OR ALTER PROCEDURE dbo.UP_VN_COST_BOH @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-4] 기초금액 → DOI_COST_BOH  (★ doi_mat_cost/doi_expen_matl 미사용)
   정상월: 전월 DOI_COST.EOH 이월(원가항목 그레인)
   초기월(전월 EOH 없음): 통 기초(doi_boh_amt.PRE_EOH_AMT, 제품별)를 재료/경비 = 실제 투입금액 비율로 배분
     - 투입있는 도우코드: PRE를 원가항목(재료+가공) 투입금액 비율로 직접 배분 → 재료:가공 = 그 도우코드 투입비 (rn=1 잔차)
     - 투입없는 도우코드: 생산수불기초 있음이면 전역 재료율(재료투입/(재료+가공투입))로 재료(MDAX)/경비('*') 대표 2행,
                          생산수불기초 없음이면 전액 가공비('*') 직과
   ※ 기존 경비비율(제조경비AA/(AA+재료))은 AA에 원재료비 포함되어 경비 과대 → 폐기. 실제 투입비 사용. */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @tot float, @cnt int, @prev varchar(6), @hasPrev int;
  DECLARE @재료투입 float, @가공투입 float, @재료율 float;
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
     -- 전역 재료율 = 재료투입 / (재료투입 + 가공투입)  [실제 투입금액 기준]
     SELECT @재료투입 = SUM(CASE WHEN 원가구분=N'재료비' THEN CAST(투입금액 AS float) ELSE 0 END),
            @가공투입 = SUM(CASE WHEN 원가구분=N'가공비' THEN CAST(투입금액 AS float) ELSE 0 END)
       FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
     SET @재료율 = ISNULL(@재료투입,0) / NULLIF(ISNULL(@재료투입,0)+ISNULL(@가공투입,0),0);

     -- 도우코드별 통 기초(PRE) + 기초재공수량
     IF OBJECT_ID('tempdb..#boh') IS NOT NULL DROP TABLE #boh;
     SELECT b.도우코드, b.도우모델, b.구분, b.pre, ISNULL(pb.boh_qty,0) boh_qty
     INTO #boh
     FROM (SELECT MODEL_TYPE 도우코드, MAX(MODEL) 도우모델, MAX(구분) 구분, SUM(CAST(PRE_EOH_AMT AS float)) pre
           FROM doi_boh_amt WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE GROUP BY MODEL_TYPE) b
     LEFT JOIN (SELECT 도우코드, SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드) pb
            ON pb.도우코드=b.도우코드;

     ;WITH
     e AS (SELECT 구분,도우코드,도우모델,원가구분,EXPEN_SEL,expen_sel명,분류,항목,CAST(투입금액 AS float) 투입금액,
                  SUM(CAST(투입금액 AS float)) OVER (PARTITION BY 도우코드) tot_inp,       -- 재료+가공 전체 투입
                  ROW_NUMBER() OVER (PARTITION BY 도우코드 ORDER BY CAST(투입금액 AS float) DESC,항목) rn
           FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE),
     dist AS (
        SELECT e.구분,e.도우코드,e.도우모델,e.원가구분,e.EXPEN_SEL,e.expen_sel명,e.분류,e.항목,e.rn, b.pre,b.boh_qty,
               CASE WHEN e.tot_inp>0 THEN ROUND(b.pre*e.투입금액/e.tot_inp,2) ELSE 0 END boh_base
        FROM e JOIN #boh b ON b.도우코드=e.도우코드),
     dist2 AS (SELECT *, SUM(boh_base) OVER (PARTITION BY 도우코드) sum_base FROM dist)
     -- (A) 투입있는 도우코드: PRE를 원가항목(재료+가공) 투입비율로 배분 + rn=1 잔차보정
     INSERT INTO DOI_COST_BOH (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
     SELECT @YYYYMM,@SEL_CODE,@SITE,구분,도우모델,도우코드,N'*',expen_sel명,분류,항목,EXPEN_SEL,'N',CAST(boh_qty AS int),
            CAST(boh_base + CASE WHEN rn=1 THEN (pre - sum_base) ELSE 0 END AS numeric(18,2))
     FROM dist2
     WHERE ABS(boh_base + CASE WHEN rn=1 THEN (pre - sum_base) ELSE 0 END) > 0.0000001;

     -- (B) 투입없는 도우코드: 생산수불기초 있으면 전역 재료율로 재료(MDAX)/경비('*'), 없으면 전액 경비('*')
     INSERT INTO DOI_COST_BOH (YYYYMM,SEL_CODE,SITE,구분,MODEL,도우코드,공정,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,ADJ_YN,BOH_QTY,BOH)
     SELECT @YYYYMM,@SEL_CODE,@SITE, ISNULL(b.구분,N'양산'), b.도우모델, b.도우코드, N'*', v.명, v.acct, N'기초이월', v.expsel, 'Y',
            CAST(b.boh_qty AS int), CAST(v.boh AS numeric(18,2))
     FROM (SELECT *, CASE WHEN boh_qty<>0 THEN ROUND(pre*@재료율,2) ELSE 0 END 재료기초 FROM #boh) b
     CROSS APPLY (VALUES ('MDAX', N'직접재료비', N'원장', b.재료기초), ('*', N'기초이월', N'*', b.pre - b.재료기초)) v(expsel, 명, acct, boh)
     WHERE ABS(v.boh) > 0.0000001
       AND NOT EXISTS (SELECT 1 FROM doi_expn_matl e WHERE e.yyyymm=@YYYYMM AND e.site=@SITE AND e.sel_code=@SEL_CODE AND e.도우코드=b.도우코드);
  END

  SELECT @tot=SUM(CAST(BOH AS float)), @cnt=COUNT(*) FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 기초금액 완료 ('+CAST(@cnt AS varchar(20))+N'행, 기초합 '+CONVERT(varchar(30),CAST(@tot AS money),1)+N', '+CASE WHEN @hasPrev=1 THEN N'전월EOH이월' ELSE N'초기seed(재료율 '+CONVERT(varchar(20),CAST(ROUND(ISNULL(@재료율,0)*100,2) AS numeric(6,2)))+N'%)' END+N')';
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
