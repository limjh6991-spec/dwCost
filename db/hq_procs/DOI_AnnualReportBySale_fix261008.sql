/* ============================================================================
   [2026-10-08] DOI_AnnualReportBySale (연간 매출계획대비실적, C0009003 / C0009003_Sch1)
   ----------------------------------------------------------------------------
   변경점:
   1) 참조 테이블 dw_product_mast -> dw_모델기본정보 (Inch 폴백 c 서브쿼리, 대각인치 사용)
   2) SELECT(선두/고정) 컬럼을 요청 순서로 변경: 도우코드, 구분, Inch, SET업체, 고객코드, 제품구조
      (기존 모델명/두께 제거. 매출계획 이후 컬럼은 그대로)
   3) GROUP BY 도 동일 순서로 변경(모델명/두께는 도우코드와 1:1이라 행수 불변)
   주의: 리포트 SELECT 전용 → ALTER만, 재결산/JAR 불필요. 프론트 C0009003.js 고정열 colCount 6 동반.
         그리드는 VN_AnnualReportBySale 와 공용(동일 컬럼명 반환)이라 VN 화면도 신규 6컬럼 레이아웃 적용.
   ============================================================================ */
ALTER Procedure DOI_AnnualReportBySale
(
    @YYYY varchar(4),
    @SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
	SELECT
	    도우코드,구분,Inch,SET업체,고객코드,제품구조,
	    NULL AS 매출계획,
	    COALESCE (SUM(금액),0) AS 계획대비실적,
	    COALESCE(MAX(CASE WHEN 월 = '01' THEN 수량 END),0) AS 'QTY_1',
	    COALESCE(MAX(CASE WHEN 월 = '01' THEN 금액 END),0) AS 'AMT_1',
	    COALESCE(MAX(CASE WHEN 월 = '02' THEN 수량 END),0) AS 'QTY_2',
	    COALESCE(MAX(CASE WHEN 월 = '02' THEN 금액 END),0) AS 'AMT_2',
	    COALESCE(MAX(CASE WHEN 월 = '03' THEN 수량 END),0) AS 'QTY_3',
	    COALESCE(MAX(CASE WHEN 월 = '03' THEN 금액 END),0) AS 'AMT_3',
	    COALESCE(MAX(CASE WHEN 월 = '04' THEN 수량 END),0) AS 'QTY_4',
	    COALESCE(MAX(CASE WHEN 월 = '04' THEN 금액 END),0) AS 'AMT_4',
	    COALESCE(MAX(CASE WHEN 월 = '05' THEN 수량 END),0) AS 'QTY_5',
	    COALESCE(MAX(CASE WHEN 월 = '05' THEN 금액 END),0) AS 'AMT_5',
	    COALESCE(MAX(CASE WHEN 월 = '06' THEN 수량 END),0) AS 'QTY_6',
	    COALESCE(MAX(CASE WHEN 월 = '06' THEN 금액 END),0) AS 'AMT_6',
	    COALESCE(MAX(CASE WHEN 월 = '07' THEN 수량 END),0) AS 'QTY_7',
	    COALESCE(MAX(CASE WHEN 월 = '07' THEN 금액 END),0) AS 'AMT_7',
	    COALESCE(MAX(CASE WHEN 월 = '08' THEN 수량 END),0) AS 'QTY_8',
	    COALESCE(MAX(CASE WHEN 월 = '08' THEN 금액 END),0) AS 'AMT_8',
	    COALESCE(MAX(CASE WHEN 월 = '09' THEN 수량 END),0) AS 'QTY_9',
	    COALESCE(MAX(CASE WHEN 월 = '09' THEN 금액 END),0) AS 'AMT_9',
	    COALESCE(MAX(CASE WHEN 월 = '10' THEN 수량 END),0) AS 'QTY_10',
	    COALESCE(MAX(CASE WHEN 월 = '10' THEN 금액 END),0) AS 'AMT_10',
	    COALESCE(MAX(CASE WHEN 월 = '11' THEN 수량 END),0) AS 'QTY_11',
	    COALESCE(MAX(CASE WHEN 월 = '11' THEN 금액 END),0) AS 'AMT_11',
	    COALESCE(MAX(CASE WHEN 월 = '12' THEN 수량 END),0) AS 'QTY_12',
	    COALESCE(MAX(CASE WHEN 월 = '12' THEN 금액 END),0) AS 'AMT_12'
	FROM (
		select substring(a.YYYYMM,5,2) As  월,
		IIF(RIGHT(a.품번,1)='D','개발','양산') as 구분,
		  b.SDC모델명 as 모델명,
		  b.고객사 as SET업체,
		  IIF(LEFT(a.품명,2)='UV',A.품명,coalesce(b.MODEL_CODE,dbo.Get_DOI_고객코드(a.품명))) as 고객코드,
		  a.품명 as 도우코드,
		  coalesce(nullif(dbo.Get_DOI_Glass_Thick(a.품명),''),b.원장_두께) as 두께,--b.대각인치 Inch,
		  isnull(b.대각인치,c.Inch) as Inch,
		  IIF(LEFT(a.품번,1)='I','ITG',
		  	IIF(LEFT(a.품번,1)='H','HTG',
		  		IIF(LEFT(a.품번,1)='C','Coated',
		  			IIF(LEFT(a.품번,2)='VN','카세트',
		  				IIF(LEFT(a.품번,2)='DW','약액','UTG')
		  			)
		  		)
		  	)
		  ) as 제품구조,
		  sum(수량) as 수량, sum(원화판매금액) 금액
		 from
		 ( SELECT YYYYMM,품번,품명,수량,원화판매금액 FROM DOI_SALE_RESC a where 1=1 and a.YYYYMM like  @YYYY+'%'  and a.SITE	 =  @SITE UNION ALL
		   SELECT YYYYMM,품번,품명,수량,원화판매금액 FROM DOI_INVOICE_RESC a where 1=1 and a.YYYYMM like  @YYYY+'%'  and a.SITE	 =  @SITE
		 )A
		left join (select model,max(고객사) 고객사,max(대각인치) 대각인치,max(MODEL_CODE) MODEL_CODE,max(원장_두께) 원장_두께,max(SDC모델명) SDC모델명
				from dw_모델기본정보 group by model) b on (a.품명=b.model)
		LEFT JOIN (select model,max(대각인치) Inch from  dw_모델기본정보 group by model) c on(a.품명=c.model)
		group by substring(a.YYYYMM,5,2),
		  IIF(RIGHT(a.품번,1)='D','개발','양산'),
		  b.SDC모델명,
		  b.고객사,
		  b.MODEL_CODE,
		  a.품명 ,
		  b.원장_두께,--b.대각인치,
		  isnull(b.대각인치,c.Inch),
		  IIF(LEFT(a.품번,1)='I','ITG',
		  	IIF(LEFT(a.품번,1)='H','HTG',
		  		IIF(LEFT(a.품번,1)='C','Coated',
		  			IIF(LEFT(a.품번,2)='VN','카세트',
		  				IIF(LEFT(a.품번,2)='DW','약액','UTG')
		  			)
		  		)
		  	)
		  )
	)a
	GROUP by 도우코드,구분,Inch,SET업체,고객코드,제품구조
	ORDER by 제품구조 desc,구분 desc,도우코드;

	END TRY

	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	   SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
