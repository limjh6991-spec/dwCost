CREATE OR ALTER PROCEDURE dbo.UP_VN_COST_UNIT @YYYYMM varchar(6), @SITE varchar(4), @SEL_CODE varchar(10) AS
/* [VN 리팩토링 260731-2] 재공단가 → doi_cost_unit  (★ doi_mat_cost/doi_expen_matl 미사용)
   단가 = (기초BOH + 투입) / (OUT_QTY + EOHEQ)   [도우코드 공통 분모, 원가항목별 분자]
   입력: doi_expn_matl(투입) + DOI_COST_BOH(기초) + V_DOI_PROD_SUBUL(OUT) + V_VN_WIP_CONV(EOHEQ=PL전×0.5+PL후×0.9)
   공정은 EOHEQ에 반영. 대표행('*',투입없음)은 단가 생성 제외(하류 BOH=EOH 특수케이스). */
BEGIN
  SET NOCOUNT ON;
  DECLARE @Message nvarchar(max), @cnt int;
  SET @Message='[START] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- '+@YYYYMM+N' VINA 재공단가(doi_cost_unit) 시작';
  BEGIN TRY
  DELETE FROM doi_cost_unit WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;

  ;WITH
  den AS (SELECT p.도우코드, SUM(CAST(ISNULL(p.OUT_MONTH,0) AS float)) + ISNULL(cv.EOHEQ,0) denom
          FROM V_DOI_PROD_SUBUL p
          LEFT JOIN V_VN_WIP_CONV cv ON cv.wc_ym=@YYYYMM AND cv.wc_site=@SITE AND cv.wc_gubun=p.구분 AND cv.wc_code=p.도우코드
          WHERE p.yyyymm=@YYYYMM AND p.site=@SITE GROUP BY p.도우코드, cv.EOHEQ),
  inp AS (SELECT 구분,도우코드,도우모델,원가구분,EXPEN_SEL,분류,항목, SUM(CAST(투입금액 AS float)) inn
          FROM doi_expn_matl WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
          GROUP BY 구분,도우코드,도우모델,원가구분,EXPEN_SEL,분류,항목),
  bh AS (SELECT 구분,도우코드,EXPEN_SEL,ACCT_NAME,ITEM_NAME, SUM(CAST(BOH AS float)) boh
         FROM DOI_COST_BOH WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE AND EXPEN_SEL<>'*'
         GROUP BY 구분,도우코드,EXPEN_SEL,ACCT_NAME,ITEM_NAME)
  INSERT INTO doi_cost_unit (YYYYMM,SEL_CODE,SITE,구분,도우코드,도우모델,원가구분,EXPEN_SEL,분류,항목,단가)
  SELECT @YYYYMM,@SEL_CODE,@SITE, i.구분,i.도우코드,i.도우모델,i.원가구분,i.EXPEN_SEL,i.분류,i.항목,
         CAST(CASE WHEN ISNULL(d.denom,0)>0 THEN (ISNULL(b.boh,0)+i.inn)/d.denom ELSE 0 END AS numeric(24,12))
  FROM inp i
    LEFT JOIN bh b ON b.구분=i.구분 AND b.도우코드=i.도우코드 AND b.EXPEN_SEL=i.EXPEN_SEL AND b.ACCT_NAME=i.분류 AND b.ITEM_NAME=i.항목
    LEFT JOIN den d ON d.도우코드=i.도우코드;

  SELECT @cnt=COUNT(*) FROM doi_cost_unit WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
  SET @Message=@Message+CHAR(10)+'[FINISH] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+N'- 재공단가 완료 ('+CAST(@cnt AS varchar(20))+N'행)';
  INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
    VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_UNIT','SUCCESS');
  SELECT @Message as retMessage;
  END TRY
  BEGIN CATCH
    SET @Message=@Message+CHAR(10)+'[ERROR] '+CONVERT(varchar(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_COST_UNIT','FAIL');
    SELECT @Message as retMessage;
  END CATCH
END
