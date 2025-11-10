CREATE         procedure UP_DOI_COST_MAT
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(2),  --사업장코드 (본사 : HQ, 베트남 : VN)
    @SELCODE varchar(10)
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
  	-- 2초 대기
    WAITFOR DELAY '00:00:01';
   	
	--데이타 체크
	SELECT @CNT = count(*)
		FROM DOI_MAT_COST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message =  '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	IF @CHECK = 1 BEGIN 
		SELECT @Message as retMessage;
		RETURN -1;
	END

	SET  @Message =  '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_FAB_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비 데이타 배부를 시작합니다';
		
	BEGIN TRANSACTION;
      --삭제
      DELETE FROM DOI_FAB_COST
      WHERE yyyymm= @YYYYMM
        and site  = @SITE
		and acct_name='재료비';
			
	SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_FAB_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';
    
		INSERT INTO DOI_FAB_COST    
		(YYYYMM,SEL_CODE,SITE,구분,MODEL,ACCT_NAME,SUB_NAME,ITEM_NAME,EXPEN_SEL,[IN])
		 select
			yyyymm,
			sel_code,
			site,
			'양산' as 구분,
			도우모델 as model,
			'재료비' as acct_name,
			 case when mat_class='원자재' then '직접재료비' else '간접재료비' end as SUB_NAME,
			 case when mat_class='원자재' then '직접재료비' else '간접재료비' end as ITEM_NAME,
			 case when mat_class='원자재' then 'MDAX' else 'MIAX' end as EXPEN_SEL,
			 sum(배부금액) as [in]
		from DOI_MAT_COST
		where 1=1
		  and yyyymm = @YYYYMM
		  and site = @SITE
		group by yyyymm,
			sel_code,
			site,
			도우모델,
			mat_class;
  	  SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_FAB_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비집계 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
      SET  @Message =  @Message + char(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_FAB_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비 데이타 입력 완료했습니다';
      COMMIT TRANSACTION; 
      SELECT @Message as retMessage;
      RETURN 0;
      END TRY
   
   BEGIN CATCH
       ROLLBACK TRANSACTION;
       SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   		SELECT @Message as retMessage;
   END CATCH;
END;		