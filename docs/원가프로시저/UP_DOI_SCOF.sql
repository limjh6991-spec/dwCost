CREATE         procedure UP_DOI_SCOF -- Sales Contra Offset
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(2),  --사업장코드 (본사 : HQ, 베트남 : VN)
    @SEL_CODE varchar(10)
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
    
	 SET  @Message =  '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 매출상계(DOI_SCOF) 테이블에 '
			+ @YYYYMM + '월 '+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '매출상계 집계를 시작합니다'; 
   
   --데이타 체크
    IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('DOI_MIOS') AND type in ('U')) -- 테이블 존재 여부 확인
    BEGIN
		SELECT @CNT = count(*)
		FROM DOI_MIOS
		      WHERE yyyymm=@YYYYMM
		        and site  =@SITE;
		IF @CNT = 0 BEGIN
		SET  @Message =  @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 자재기타출고((DOI_MIOS) 테이블에 '
		+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
		END
		ELSE
		BEGIN
		SET  @Message =  @Message + char(10) + '[CHECK]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 자재기타출고((DOI_MIOS) 테이블에 '
		+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 '+CAST(@CNT AS VARCHAR)+'건 정상입니다'
		END
	END
    ELSE
    BEGIN
        SET  @Message =  @Message + char(10) + '[ERROR] ' +  '자재기타출고(DOI_MIOS) 테이블이 존재하지 않습니다.';
        SET @CHECK = 1;
    END

    -- 1초 대기
	-- WAITFOR DELAY '00:00:01';
    
	SELECT @CNT = count(*)
	FROM DOI_IVDD
	      WHERE yyyymm=@YYYYMM
	        and site  =@SITE;
	IF @CNT = 0 BEGIN
	SET  @Message =  @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재고금액상세(DOI_IVDD) 테이블에 '
	+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
	SET @CHECK = 1;
	END
	ELSE
	BEGIN
	SET  @Message =  @Message + char(10) + '[CHECK]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재고금액상세(DOI_IVDD) 테이블에 '
	+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 '+CAST(@CNT AS VARCHAR)+'건 정상입니다'
	END
	
	IF @CHECK = 1 BEGIN
		SELECT @Message as retMessage;	
		RETURN -1;
	END

	BEGIN TRANSACTION;
	
	DELETE FROM DOI_SCOF 
	WHERE YYYYMM	= @YYYYMM
	  AND SITE		= @SITE
	  AND SEL_CODE  = @SEL_CODE;	
	
	SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 매출상계(DOI_SCOF) 테이블에 '+@YYYYMM + '월 '
	+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '매출상계 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';
	
	-- 창고입고는 있지만 생산수불에 없는 모델을 생산수불조정 테입블에 입력 
	with 재고단가 AS(
	select 품번,CAST(결산재고금액D as float)/결산재고수량B AS 최종결산월재고단가 --최종결산월재고단가
	 from DOI_IVDD
	where 1=1
		AND YYYYMM = @YYYYMM
		AND SITE = @SITE
		AND 중분류 = 'SDC'
	), 자재출고 AS ( 
	select	창고,	품번,	SUM(수량) 수량
	from	DOI_MIOS
	where 1=1
		AND YYYYMM 	= @YYYYMM
		AND SITE 	= @SITE
		AND 기타출고구분 = '유상사급매출상계'
	GROUP BY 창고,	품번
	), 상계원장 as(
		/*SELECT	A.창고,A.품번,A.수량,최종결산월재고단가,
			수량 * 최종결산월재고단가 AS 상계금액
	FROM	자재출고 A
	LEFT JOIN 재고단가 B ON	(A.품번 = B.품번)*/
	SELECT '현장창고' 창고,품번, 기타출고수량 수량, 최종결산월재고단가,
			/*수량 * 최종결산월재고단가*/기타출고금액 AS 상계금액
	FROm DOI_IVDD 
	where 1=1
		AND YYYYMM = @YYYYMM
		AND SITE = @SITE
		and 기타출고수량 <>0	
	), 생산수불 AS(
		SELECT 구분,도우모델 AS MODEL,(IN_MONTH + OUT_MONTH + LOSS_MONTH)/2 AS IN_MONTH --IN_MONTH
		FROM DOI_PROD_SUBUL 
		where 1=1
		AND YYYYMM = @YYYYMM
		AND SITE = @SITE
		AND IN_MONTH + OUT_MONTH + LOSS_MONTH != 0
		--AND IN_MONTH > 0
	), 자재_BOM AS
	(
	SELECT	DISTINCT 창고,품번,수량,최종결산월재고단가,ROUND(상계금액,0) as 상계금액,제품명
	FROM	상계원장 A
	LEFT JOIN DOI_BOM_MAST B ON
		(A.품번 = B.자재번호
			AND B.YYYYMM = @YYYYMM
			AND B.SITE = @SITE)
	)
	INSERT INTO DOI_SCOF
	 (YYYYMM,SITE,SEL_CODE,구분,MODEL,창고,품번,수량,최종결산월재고단가,상계금액,IN_MONTH,DIST_RATE,BASE_AMT,ORI_AMT,BASE_TOT,rn,FINAL_AMT)
	SELECT T.*,CASE WHEN Rn=1 then  BASE_AMT + (상계금액 - BASE_TOT) ELSE BASE_AMT END AS FINAL_AMT --INTO DOI_SCOF -- Sales Contra Offset
	FROM
	(
		SELECT A.*,
			SUM(BASE_AMT) OVER(PARTITION BY 창고,품번) as BASE_TOT,
			ROW_NUMBER() OVER(PARTITION BY 창고,품번 ORDER BY ORI_AMT DESC,MODEL) as rn
		FROM(
			SELECT
				@YYYYMM as YYYYMM,
				@SITE as SITE,
				@SEL_CODE as sel_code,
				구분,
				MODEL,
				창고,
				품번,
				수량,
				최종결산월재고단가,
				상계금액,
				IN_MONTH,
				CAST(IN_MONTH as float)/SUM(IN_MONTH) OVER(PARTITION BY 창고,품번) DIST_RATE,
				ROUND(상계금액 * CAST(IN_MONTH as float)/SUM(IN_MONTH) OVER(PARTITION BY 창고,품번),0) as BASE_AMT,
				상계금액 * CAST(IN_MONTH as float)/SUM(IN_MONTH) OVER(PARTITION BY 창고,품번) AS ORI_AMT
			FROM
				자재_BOM A
			INNER JOIN 생산수불 B ON
				(A.제품명 = B.MODEL)
			)a
		)T	
	ORDER BY 창고,품번,MODEL;
	
	SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 매출상계(DOI_SCOF) 테이블에 '+@YYYYMM + '월 '
		+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '원장 매출상계를 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계 했습니다';

	SET  @Message =  @Message + char(10) + '[FINISH]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 매출상계(DOI_SCOF) 테이블에 '+@YYYYMM + '월 '
		+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '원장 매출상계를 완료했습니다';

	 -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '매출상계', 'UP_DOI_SCOF', 'SUCCESS');
     
	 COMMIT TRANSACTION;
	 
     SELECT @Message as retMessage;
	
	 END TRY   
	  
	BEGIN CATCH
		SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_Message());-- AS ErrorR_Message;
		 INSERT INTO doi_execlog
		    values
		    (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '매출상계', 'UP_DOI_SCOF', 'FAIL');	
	ROLLBACK TRANSACTION;
	SELECT @Message as retMessage;
	   END CATCH;
	END;		
	
