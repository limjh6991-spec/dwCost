
CREATE   PROCEDURE UP_VN_MAT_COST_NEW @YYYYMM varchar(6), @SITE varchar(2), @SEL_CODE varchar(10)
AS BEGIN
  SET NOCOUNT ON;
  DELETE FROM doi_mat_cost WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  ;WITH
  prod_all AS (SELECT 도우모델, MAX(구분) 구분,
      SUM(CAST(ISNULL(BOH_MONTH,0) AS float)) boh_qty, SUM(CAST(ISNULL(IN_MONTH,0) AS float)) in_qty,
      SUM(CAST(ISNULL(EOH_MONTH,0) AS float)) eoh_qty, SUM(CAST(ISNULL(OUT_MONTH,0) AS float)) out_qty,
      SUM(CAST(ISNULL(LOSS_MONTH,0) AS float)) loss_qty,
      SUM(CAST(ISNULL(IN_MONTH,0)+ISNULL(OUT_MONTH,0)+ISNULL(LOSS_MONTH,0) AS float))/2.0 환산량
    FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE GROUP BY 도우모델),
  prod AS (SELECT * FROM prod_all WHERE 환산량>0),
  mmap AS (SELECT 제품번호,(SELECT TOP 1 p.도우모델 FROM prod_all p WHERE mi.제품번호 LIKE p.도우모델+'%' ORDER BY LEN(p.도우모델) DESC) 도우모델
           FROM (SELECT DISTINCT 제품번호 FROM DOI_VN_MAT_INPUT WHERE yyyymm=@YYYYMM) mi),
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
  tot_chg AS (SELECT SUM(환산량) s FROM prod),
  common_calc AS (SELECT p.구분,p.도우모델,p.boh_qty,p.in_qty,p.eoh_qty,p.out_qty,p.loss_qty,p.환산량,
           s.자재번호,s.mat_class_hq,s.세분류,s.금액 in_amt,ISNULL(s.단가,0) 단가,
           CAST(p.환산량/t.s AS numeric(24,12)) 배부율, ROUND(s.금액*(p.환산량/t.s),2) 배부금액,
           ROW_NUMBER() OVER (PARTITION BY s.자재번호 ORDER BY p.환산량 DESC,p.도우모델) rn,
           SUM(ROUND(s.금액*(p.환산량/t.s),2)) OVER (PARTITION BY s.자재번호) sum_배부
    FROM comm_src s CROSS JOIN prod p CROSS JOIN tot_chg t)
  INSERT INTO doi_mat_cost
    (yyyymm,sel_code,site,구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,환산량,in_amt,배부율,BOH_AMT,단가,배부금액,배부방식,ADJ_YN)
  SELECT @YYYYMM,@SEL_CODE,@SITE,p.구분,m.도우모델,mi.자재번호,c.mat_class_hq,c.mat_class_hq,c.세분류,
         CAST(p.boh_qty AS int),CAST(p.in_qty AS int),CAST(p.eoh_qty AS int),CAST(p.out_qty AS int),CAST(p.loss_qty AS int),
         CAST(p.환산량 AS numeric(7,1)),CAST(SUM(CAST(mi.투입금액 AS float)) AS numeric(15,2)),CAST(1 AS numeric(24,12)),0,
         CAST(SUM(CAST(mi.투입금액 AS float))/NULLIF(SUM(CAST(mi.투입수량 AS float)),0) AS numeric(24,12)),
         CAST(SUM(CAST(mi.투입금액 AS float)) AS numeric(17,2)),N'직과','N'
  FROM DOI_VN_MAT_INPUT mi JOIN matcls c ON c.자재번호=mi.자재번호 JOIN mmap m ON m.제품번호=mi.제품번호 JOIN prod_all p ON p.도우모델=m.도우모델
  WHERE mi.yyyymm=@YYYYMM AND c.grp=N'원재료'
  GROUP BY p.구분,m.도우모델,mi.자재번호,c.mat_class_hq,c.세분류,p.boh_qty,p.in_qty,p.eoh_qty,p.out_qty,p.loss_qty,p.환산량
  UNION ALL
  SELECT @YYYYMM,@SEL_CODE,@SITE,구분,도우모델,자재번호,mat_class_hq,mat_class_hq,세분류,
         CAST(boh_qty AS int),CAST(in_qty AS int),CAST(eoh_qty AS int),CAST(out_qty AS int),CAST(loss_qty AS int),
         CAST(환산량 AS numeric(7,1)),CAST(in_amt AS numeric(15,2)),배부율,0,CAST(단가 AS numeric(24,12)),
         CAST(배부금액 + CASE WHEN rn=1 THEN (in_amt-sum_배부) ELSE 0 END AS numeric(17,2)),N'공통','N'
  FROM common_calc;
END
