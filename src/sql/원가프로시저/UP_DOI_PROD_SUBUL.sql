
CREATE       procedure UP_DOI_PROD_SUBUL
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(2)  --사업장코드 (본사 : HQ, 베트남 : VN)
)
AS
BEGIN
	BEGIN TRY
	SET NOCOUNT ON;
    SET LOCK_TIMEOUT 10000; -- 10초로 증가
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- 격리 수준 변경
    DECLARE  @Message  NVARCHAR(MAX)='';
   	DECLARE @CNT INT = 0,
   		    @CHECK BIT = 0;

	BEGIN TRANSACTION;
	--데이타 체크
	SELECT @CNT = count(*)
		from dw_일별_공정별_생산집계_base
		where 1=1
		and 
		집계일자 between  @YYYYMM +'01' 
				and REPLACE(EOMONTH(DATEFROMPARTS(substring(@YYYYMM,1,4), substring(@YYYYMM,5,2), 1)),'-','')
	
	IF @CNT = 0 BEGIN
		SET @Message =  '[ERROR] '+ char(9)+'- 일별집계(dw_일별_공정별_생산집계_base) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	IF @CHECK = 1 BEGIN 
       ROLLBACK TRANSACTION;
		SELECT @Message as retMessage;
		RETURN -1;
	END

	SET  @Message =  @Message + char(10) +  '[START]  ' + char(9)+'- 생산수불(DOI_PROD_SUBUL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '생산수불 데이타 집계를 시작합니다';
		
    --삭제
  	DELETE   DOI_PROD_SUBUL WHERE YYYYMM=@YYYYMM AND SITE=@SITE;
	SET  @Message =  @Message + char(10) + ' [INFO]  ' + char(9)+'- 생산수불(DOI_PROD_SUBUL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '생산수불 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';
    
	INSERT INTO DOI_PROD_SUBUL
	(YYYYMM, SEL_CODE, SITE, 구분, 구분_ord, 도우코드, 도우모델, 작업구분, org작업구분, model, Inch, DW_Site, BOH_MONTH, IN_MONTH, BONUS_MONTH, EOH_MONTH, OUT_MONTH, LOSS_MONTH, NG_MONTH, 수율제외_MONTH, REWORK진행_MONTH, SHIPPING_PLAN_MONTH, SHIPPING_ACTUAL_MONTH, material_loss)
		select
		cast(@YYYYMM as varchar(6)) as YYYYMM,
		cast('ACTUAL' as varchar(10)) as SEL_CODE,
		CAST(@SITE as varchar(5)) as SITE,
		구분,
		구분_ord,
		도우코드,
--		CASE WHEN org작업구분='-' then 도우코드 else 도우모델+org작업구분 end as MODEL_N_TYPE,
		도우모델,
		작업구분,
		org작업구분,
		model,
		Inch,
		Site as dw_site,
		BOH_MONTH,
		IN_MONTH,
		BONUS_MONTH,
		EOH_MONTH,
		OUT_MONTH,
		LOSS_MONTH,
		NG_MONTH,
		수율제외_MONTH,
		REWORK진행_MONTH,
		SHIPPING_PLAN_MONTH,
		SHIPPING_ACTUAL_MONTH,
		material_loss
		--INTO DOI_PROD_SUBUL
	from
		Get_모델별_생산일보_MONTH_WITH_MATERIAL_LOSS
	 	(REPLACE(EOMONTH(DATEFROMPARTS(substring(@YYYYMM,1,4), substring(@YYYYMM,5,2), 1)),'-',''));

	  SET  @Message =  @Message + char(10) + ' [INFO]  ' + char(9)+'- 생산수불(DOI_PROD_SUBUL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '생산수불집계 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
      SET  @Message =  @Message + char(10) + '[FINISH] ' + char(9)+'- 생산수불(DOI_PROD_SUBUL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '생산수불 데이타 입력 완료했습니다';
      COMMIT TRANSACTION; 
      SELECT @Message as retMessage;
      RETURN 0;
      END TRY
   
   BEGIN CATCH
       ROLLBACK TRANSACTION;
       SET  @Message =  @Message + char(10) + '[ERROR] '+ char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   		SELECT @Message as retMessage;
   END CATCH;
END;		

