/* ============================================================================
   [2026-10-08b] DOI_AnnualReportBySale (연간 매출계획대비실적, C0009003) — 집계산식 스펙 반영
   ----------------------------------------------------------------------------
   fix261008(컬럼순서/모델명·두께제거/dw_모델기본정보) 위에 요구사항 3(데이터 집계) 반영:
     ② 구분 : RIGHT(품번,1)='P' → '양산', 그 외 → '개발'  (기존 'D'→개발 기준에서 변경)
     ③ Inch     : 모델기본정보 대각인치 를 MODEL + 구분 조인으로 취득
     ④ SET업체  : 모델기본정보 고객사  를 MODEL + 구분 조인으로 취득
     ⑤ 고객코드 : 모델기본정보 MODEL_CODE 를 MODEL + 구분 조인으로 취득 (기존 UV분기·Get_DOI_고객코드 폴백 제거)
   유지(요청) :
     ① 도우코드 : a.품명 그대로 (품번 우측텍스트 제외 변환 안 함)
     ⑥ 제품구조 : 품번 접두어 파생(ITG/HTG/Coated/카세트/약액/UTG) 그대로
   ----------------------------------------------------------------------------
   주의: 리포트 SELECT 전용 → ALTER만(SSMS 수동), 재결산/JAR 불필요. 프론트 변경 없음.
   영향(2026 HQ): MODEL+구분 조인으로 모델기본정보에 해당 구분이 없는 품번은 Inch/SET업체/고객코드 공란.
     - 완전 미등록 8품명(기존에도 공란) + F010(품번 F010D→개발 판정이나 모델기본정보엔 F010 양산만 등록) 1건.
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
		  IIF(RIGHT(a.품번,1)='P','양산','개발') as 구분,
		  b.고객사 as SET업체,
		  b.MODEL_CODE as 고객코드,
		  a.품명 as 도우코드,
		  b.대각인치 as Inch,
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
		left join (select model, 구분, max(고객사) 고객사, max(대각인치) 대각인치, max(MODEL_CODE) MODEL_CODE
				from dw_모델기본정보 group by model, 구분) b
		    on  a.품명 = b.model
		    and b.구분 = IIF(RIGHT(a.품번,1)='P','양산','개발')
		group by substring(a.YYYYMM,5,2),
		  IIF(RIGHT(a.품번,1)='P','양산','개발'),
		  b.고객사,
		  b.MODEL_CODE,
		  a.품명 ,
		  b.대각인치,
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
