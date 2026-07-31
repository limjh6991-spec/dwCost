CREATE OR ALTER PROCEDURE dbo.UP_VN_MAT_COST @YYYYMM varchar(6),@SITE varchar(4),@SEL_CODE varchar(10) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int, @jg float, @gt float, @boh float;
  SET @Message = '[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+'- '+@YYYYMM+' '+CASE WHEN @SITE='HQ' THEN N'본사' ELSE N'VINA' END+N' 재료비 배부(직과/공통, 도우코드) 시작';
  BEGIN TRY

  -- [면적 누락 검증 260731] 환산량>0 도우코드 중 DOI_MODEL_MAST 면적(xy) 누락 시 에러로그 후 중단 (삭제 전 검사 → 기존 데이터 보존)
  DECLARE @missing_cnt int, @missing_list nvarchar(max);
  ;WITH prod_chk AS (
     SELECT 도우코드, SUM(CAST(ISNULL(IN_MONTH,0)+ISNULL(OUT_MONTH,0)+ISNULL(LOSS_MONTH,0) AS float))/2.0 환산량
     FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드
  )
  SELECT @missing_cnt = COUNT(*),
         @missing_list = STRING_AGG(CONVERT(nvarchar(max), p.도우코드), N', ')
  FROM prod_chk p
  LEFT JOIN DOI_MODEL_MAST mm ON mm.yyyymm=@YYYYMM AND mm.site=@SITE AND mm.MODEL=p.도우코드
  WHERE p.환산량>0 AND (mm.MODEL IS NULL OR ISNULL(mm.xy,0)=0);

  IF ISNULL(@missing_cnt,0) > 0
  BEGIN
     SET @Message = @Message + CHAR(10) + '[ERROR] ' + CONVERT(varchar(19),GETDATE(),120) + CHAR(9)
        + N'- 면적정보(DOI_MODEL_MAST) 누락 도우코드 ' + CAST(@missing_cnt AS varchar(10))
        + N'건 → 재료비 배부 중단(면적 등록 후 재실행): ' + ISNULL(@missing_list, N'');
     INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
       VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MAT_COST','FAIL');
     SELECT @Message as retMessage;
     RETURN -1;
  END

  DELETE FROM doi_mat_cost WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  ;WITH
  -- [2안 260731] 집계키=도우코드, 저장은 도우모델(MODEL) + 도우코드 둘 다
  prod_all AS (SELECT 도우코드, MAX(도우모델) 도우모델, MAX(구분) 구분,
      SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty, SUM(CAST(ISNULL(IN_MONTH,0) AS float)) in_qty,
      SUM(CAST(ISNULL(EOH_MONTH,0) AS float)) eoh_qty, SUM(CAST(ISNULL(OUT_MONTH,0) AS float)) out_qty,
      SUM(CAST(ISNULL(LOSS_MONTH,0) AS float)) loss_qty,
      SUM(CAST(ISNULL(IN_MONTH,0)+ISNULL(OUT_MONTH,0)+ISNULL(LOSS_MONTH,0) AS float))/2.0 환산량
    FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드),
  -- [면적 정합 260730] 공통 배부에 제품 면적(xy) 반영 (본사 MAT_COMM_RATE 동일). DOI_MODEL_MAST.MODEL = 도우코드
  prod AS (SELECT pa.*, CAST(ISNULL(mm.xy,0) AS float) 면적
           FROM prod_all pa
           LEFT JOIN DOI_MODEL_MAST mm ON mm.yyyymm=@YYYYMM AND mm.site=@SITE AND mm.MODEL=pa.도우코드
           WHERE pa.환산량>0),
  matcls AS (SELECT 자재번호,
      MAX(CASE WHEN 품목자산분류=N'Raw Material' AND 자재소분류 LIKE N'%Glass%' THEN N'원재료-원장'
               WHEN 품목자산분류=N'Raw Material' AND 자재소분류 LIKE N'PF%' THEN N'원재료-PF'
               WHEN 품목자산분류=N'Raw Material' AND 자재소분류 LIKE N'PL%' THEN N'원재료-PL'
               WHEN 품목자산분류=N'Raw Material' AND UPPER(자재소분류) LIKE N'%CHEMICAL%' THEN N'원재료-약액'
               WHEN 품목자산분류=N'Raw Material' THEN N'원재료-기타'
               WHEN 품목자산분류=N'Sub Material' AND UPPER(자재소분류) LIKE N'%TRAY%' THEN N'부재료-TRAY'
               WHEN 품목자산분류=N'Sub Material' THEN N'부재료-기타' ELSE N'기타' END) 세분류,
      MAX(CASE WHEN 품목자산분류=N'Raw Material' AND UPPER(자재소분류) LIKE N'%CHEMICAL%' THEN N'약액'
               WHEN 품목자산분류=N'Raw Material' THEN N'원재료'
               WHEN 품목자산분류=N'Sub Material' THEN N'부재료' ELSE N'기타' END) grp,
      MAX(CASE WHEN 품목자산분류=N'Raw Material' AND UPPER(자재소분류) LIKE N'%CHEMICAL%' THEN N'약액'
               WHEN 품목자산분류=N'Raw Material' THEN N'원자재'
               WHEN 품목자산분류=N'Sub Material' THEN N'부자재' ELSE N'기타' END) mat_class_hq
    FROM DOI_VN_MATERIAL WHERE yyyymm=@YYYYMM GROUP BY 자재번호),
  comm_src AS (SELECT r.품번 자재번호, MAX(c.mat_class_hq) mat_class_hq, MAX(c.세분류) 세분류,
           SUM(CAST(r.투입금액 AS float)) 금액, MAX(CAST(r.최종결산월재고단가 AS float)) 단가
    FROM DOI_MATL_RESC r JOIN matcls c ON c.자재번호=r.품번
    WHERE r.yyyymm=@YYYYMM AND r.site=@SITE AND ISNULL(r.투입금액,0)<>0 AND c.grp IN (N'약액',N'부재료') GROUP BY r.품번),
  tot_chg AS (SELECT SUM(환산량*면적) s FROM prod),   -- [면적 정합] 환산량 -> 환산량×면적
  -- [신규] 단가 분모: 소비환산수량 = OUT_QTY + EOHEQ(PL전x0.5 + PL후x0.9), 도우코드 기준
  denom AS (SELECT 도우코드,
      SUM(CAST(ISNULL(OUT_MONTH,0) AS float))
    + SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N'')))*0.5
    + SUM(TRY_CONVERT(float,REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N'')))*0.9  AS denom_qty
    FROM DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우코드),
  common_calc AS (SELECT p.구분,p.도우모델,p.도우코드,p.boh_qty,p.in_qty,p.eoh_qty,p.out_qty,p.loss_qty,p.환산량,
           s.자재번호,s.mat_class_hq,s.세분류,s.금액 in_amt,ISNULL(s.단가,0) 단가,
           CAST(p.환산량*p.면적/NULLIF(t.s,0) AS numeric(24,12)) 배부율, ROUND(s.금액*(p.환산량*p.면적/NULLIF(t.s,0)),2) 배부금액,
           ROW_NUMBER() OVER (PARTITION BY s.자재번호 ORDER BY p.환산량*p.면적 DESC,p.도우코드) rn,
           SUM(ROUND(s.금액*(p.환산량*p.면적/NULLIF(t.s,0)),2)) OVER (PARTITION BY s.자재번호) sum_배부
    FROM comm_src s CROSS JOIN prod p CROSS JOIN tot_chg t),
  -- 직과 + 공통 통합 (BOH 분배 전)
  mat_rows AS (
    SELECT p.구분, p.도우모델, mi.제품번호 도우코드, mi.자재번호,
           c.mat_class_hq mat_gubun, c.mat_class_hq mat_class, c.세분류 자재대분류,
           p.boh_qty,p.in_qty,p.eoh_qty,p.out_qty,p.loss_qty,p.환산량,
           CAST(SUM(CAST(mi.투입금액 AS float)) AS float) in_amt,
           CAST(1 AS numeric(24,12)) 배부율,
           CAST(SUM(CAST(mi.투입금액 AS float))/NULLIF(SUM(CAST(mi.투입수량 AS float)),0) AS float) 단가,
           CAST(SUM(CAST(mi.투입금액 AS float)) AS float) 배부금액,
           N'직과' 배부방식
    FROM DOI_VN_MAT_INPUT mi
      JOIN matcls c ON c.자재번호=mi.자재번호
      JOIN prod_all p ON p.도우코드 = mi.제품번호      -- [변경] 제품번호=도우코드 직접 매핑
    WHERE mi.yyyymm=@YYYYMM AND c.grp=N'원재료'
    GROUP BY p.구분, p.도우모델, mi.제품번호, mi.자재번호, c.mat_class_hq, c.세분류,
             p.boh_qty,p.in_qty,p.eoh_qty,p.out_qty,p.loss_qty,p.환산량
    UNION ALL
    SELECT 구분, 도우모델, 도우코드, 자재번호, mat_class_hq, mat_class_hq, 세분류,
           boh_qty,in_qty,eoh_qty,out_qty,loss_qty,환산량,
           CAST(in_amt AS float), 배부율, CAST(단가 AS float),
           CAST(배부금액 + CASE WHEN rn=1 THEN (in_amt-sum_배부) ELSE 0 END AS float), N'공통'
    FROM common_calc
  ),
  -- [신규] 기초금액: DOI_BOH_AMT.재료비기초 (도우코드=MODEL_TYPE)
  boh AS (SELECT MODEL_TYPE, CAST(ISNULL(재료비기초,0) AS float) 재료비기초
          FROM DOI_BOH_AMT WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE),
  with_boh AS (
    SELECT r.*,
       SUM(r.배부금액) OVER (PARTITION BY r.도우코드) tot_배부,
       ISNULL(b.재료비기초,0) 재료비기초,
       ROW_NUMBER() OVER (PARTITION BY r.도우코드 ORDER BY r.배부금액 DESC, r.자재번호) rn_boh
    FROM mat_rows r LEFT JOIN boh b ON b.MODEL_TYPE = r.도우코드
  ),
  boh_dist AS (
    SELECT *,
       ROUND(CASE WHEN tot_배부>0 THEN 재료비기초 * 배부금액 / tot_배부 ELSE 0 END, 2) boh_base,
       SUM(ROUND(CASE WHEN tot_배부>0 THEN 재료비기초 * 배부금액 / tot_배부 ELSE 0 END, 2)) OVER (PARTITION BY 도우코드) boh_sum
    FROM with_boh
  ),
  boh_final AS (
    SELECT bd.*,
       CAST(bd.boh_base + CASE WHEN bd.rn_boh=1 THEN (bd.재료비기초 - bd.boh_sum) ELSE 0 END AS float) boh_amt_final
    FROM boh_dist bd
  )
  INSERT INTO doi_mat_cost
    (yyyymm,sel_code,site,구분,도우모델,도우코드,자재번호,mat_gubun,mat_class,자재대분류,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,환산량,in_amt,배부율,BOH_AMT,단가,배부금액,배부방식,ADJ_YN)
  SELECT @YYYYMM,@SEL_CODE,@SITE,bf.구분,bf.도우모델,bf.도우코드,bf.자재번호,bf.mat_gubun,bf.mat_class,bf.자재대분류,
         CAST(bf.boh_qty AS int),CAST(bf.in_qty AS int),CAST(bf.eoh_qty AS int),CAST(bf.out_qty AS int),CAST(bf.loss_qty AS int),
         CAST(bf.환산량 AS numeric(7,1)),CAST(bf.in_amt AS numeric(15,2)),bf.배부율,
         CAST(bf.boh_amt_final AS numeric(17,2)),  -- [신규] BOH_AMT: 배부금액비율 분배(A)+잔차보정
         -- [신규] 단가 = (BOH_AMT + 배부금액) / 소비환산수량(OUT+EOHEQ), 자재 공통 분모 → 단가합 왜곡 제거
         CAST(CASE WHEN ISNULL(d.denom_qty,0)>0 THEN (bf.boh_amt_final + bf.배부금액) / d.denom_qty ELSE 0 END AS numeric(24,12)),
         CAST(bf.배부금액 AS numeric(17,2)),
         bf.배부방식,'N'
  FROM boh_final bf LEFT JOIN denom d ON d.도우코드 = bf.도우코드;

    SELECT @jg=SUM(CASE WHEN 배부방식=N'직과' THEN CAST(배부금액 AS float) ELSE 0 END),
           @gt=SUM(CASE WHEN 배부방식=N'공통' THEN CAST(배부금액 AS float) ELSE 0 END),
           @boh=SUM(CAST(BOH_AMT AS float)),
           @cnt=COUNT(*) FROM doi_mat_cost WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
    SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재료비 배부(도우코드) 완료 ('+CAST(@cnt AS varchar(20))+N'행, 직과 '+CONVERT(varchar(30),CAST(@jg AS money),1)+N' + 공통 '+CONVERT(varchar(30),CAST(@gt AS money),1)+N', 기초 '+CONVERT(varchar(30),CAST(@boh AS money),1)+N')';
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MAT_COST','SUCCESS');
    SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
     VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_MAT_COST','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
