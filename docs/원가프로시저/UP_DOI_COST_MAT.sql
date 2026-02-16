CREATE                                         procedure UP_DOI_COST_MAT
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
  	-- 2초 대기
    WAITFOR DELAY '00:00:01';
   	
	--데이타 체크
	SELECT @CNT = count(*)
		FROM DOI_MAT_COST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE
		and sel_code = @SEL_CODE;
	IF @CNT = 0 BEGIN
		SET @Message =  '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	IF @CHECK = 1 BEGIN 
		SELECT @Message as retMessage;
		RETURN -1;
	END

	SET  @Message =  '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비 데이타 배부를 시작합니다';
		
	BEGIN TRANSACTION;
      --삭제 (재료비 관련 데이터: EXPEN_SEL이 MDAX 또는 MIAX인 데이터)
      DELETE FROM DOI_COST
      WHERE yyyymm= @YYYYMM
        and site  = @SITE
        and sel_code = @SEL_CODE
		and EXPEN_SEL IN ('MDAX', 'MIAX');
			
	SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';
    
		INSERT INTO DOI_COST 
		(YYYYMM ,sel_code ,SITE ,구분 ,model ,expen_sel명 ,ACCT_NAME ,ITEM_NAME ,EXPEN_SEL ,boh_qty ,in_qty ,eoh_qty ,out_qty ,loss_qty ,bad_qty ,transfer_qty ,adj_qty, unit_cost ,boh ,[in] ,eoh ,out_단가 ,[out] , loss ,bad ,transfer, adj_yn, unitcost_yn)
		select  YYYYMM,
	         sel_code,
	         SITE,
	         구분,
	         model,
	         expen_sel명,
	         acct_name,
	         item_name,
	         EXPEN_SEL,
	         boh_qty,
	         in_qty,
	         eoh_qty,
	         out_qty,
	         loss_qty,
	         bad_qty,
	         transfer_qty,
	         adj_qty,
	         unit_cost,
	         CASE WHEN model like 'VINA%' then 0 else boh end as boh, --2026.01.14
	         [in],
	         eoh,
	  		 case when out_qty = 0 THEN unit_cost 
	         	  ELSE coalesce((boh + "in"-eoh)/ nullif(out_qty+bad_qty+Transfer_qty, 0), 0) end as out_단가, --(boh금액+in금액-eoh금액)/(out수량+bad수량+Transfer수량)
	         CASE WHEN model like 'VINA%' then [in] else 	  
	         		round(case when boh_qty+in_qty = out_qty+loss_qty and out_qty != 0 then boh + "in" - eoh
	         				   when boh_qty+in_qty = out_qty+loss_qty and out_qty  = 0 then 0
	         					else /*coalesce(*/boh + "in"- eoh/* / nullif(out_qty+bad_qty+Transfer_qty, 0), 0) * out_qty*/ end,0) END as out, --out금액 : out_단가 * out수량
	         --round(case when boh_qty+in_qty = loss_qty then 0 else boh+"in"-(unit_cost * (eoh_qty / 2)) end,0) as out1,
	         round(case when boh_qty+in_qty = loss_qty then boh+"in" else 0 end,0) as loss,
	         round(case when boh_qty+in_qty = bad_qty+loss_qty and bad_qty != 0 then boh + "in"
	         		 else coalesce((boh + "in"- eoh)/ nullif(out_qty+bad_qty+Transfer_qty, 0), 0) * bad_qty end,0) as bad, --Bad금액 : out_단가 * Bad수량(0)
	         round(case when boh_qty+in_qty = Transfer_qty+loss_qty and Transfer_qty != 0 then boh + "in"
	         		 else coalesce((boh + "in"- eoh)/ nullif(out_qty+bad_qty+Transfer_qty, 0), 0) * Transfer_qty end,0) as transfer,
	         adj_yn,
	         1 UnitCost_YN
	   from (      		 
	  	select
	         YYYYMM,
	         @SEL_CODE as sel_code,
	         SITE,
	         구분,
	         도우모델 as model,
	         case when mat_class='원자재' then '직접재료비' else '간접재료비' end as expen_sel명,
	         			 case 	when mat_gubun='제품' and mat_class='원자재' then '원장'
					when 자재대분류='필름' then 'PF'
					when 자재대분류='트레이' then '트레이' 
					when mat_class='약액' then '약액'
					when mat_class='더미글라스' then '더미글라스'
					else '기타' 
			 end as ACCT_NAME,
	         자재번호  as item_name,
	   case when mat_class='원자재' then 'MDAX' else 'MIAX' end as EXPEN_SEL,
	         boh_qty,
	         in_qty,
	         eoh_qty,
	         out_qty,
	         loss_qty,
	         0 bad_qty,
	         0 transfer_qty,
	         환산량 adj_qty,
	         단가 as unit_cost,
	         BOH_AMT as  boh,
	         배부금액 as [in],
	         /*if boh수량+in수량 = eoh수량 then eoh금액 = boh금액+in금액 else unit_cost * (eoh_qty / 2) */  -- eoh금액 :(단가)*eoh수량/2 
	         round(case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + /*bad_qty*/0 + /*transfer_qty*/0 = 0 and loss_qty > 0)) and eoh_qty != 0 
	         				then BOH_AMT + 배부금액 else 단가 * (eoh_qty / 2.0) end,0) as eoh,
	         adj_yn--,UnitCost_YN --select *
	      from
	         doi_mat_cost
	      where yyyymm = @YYYYMM
	        and site = @SITE
	        and sel_code = @SEL_CODE
        )a
      order by
         YYYYMM, SITE, 구분, model, expen_sel;
		
/*	INSRET INTO DOI_COST
 	(YYYYMM,SEL_CODE,SITE,구분,MODEL,expen_sel명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,ADJ_QTY,[IN],[OUT],OUT_단가,ADJ_YN,UnitCost_YN)
		select
			a.yyyymm,
			a.sel_code,
			a.site,
			a.구분,
			a.도우모델 as model,
			 case	when a.mat_class='원자재' then '직접재료비' else '간접재료비' end as expen_sel명,
			 case 	when mat_gubun='제품' and mat_class='원자재' then '원장'
					when 자재대분류='필름' then 'PF'
					when 자재대분류='트레이' then '트레이' 
					when mat_class='약액' then '약액'
					when mat_class='더미글라스' then '더미글라스'
					else '기타' 
			 end as ACCT_NAME,
			'재료비' as ITEM_NAME,
			 case when a.mat_class='원자재' then 'MDAX' else 'MIAX' end as EXPEN_SEL,
			 AVG(a.BOH_QTY) as BOH_QTY,
			 AVG(a.IN_QTY) as IN_QTY,
			 AVG(a.EOH_QTY) as EOH_QTY,
			 AVG(a.OUT_QTY) as OUT_QTY,
			 AVG(a.LOSS_QTY) as LOSS_QTY,
			 AVG(a.환산량) as ADJ_QTY,
			 sum(a.배부금액) as [IN],
			 --sum(a.배부금액) as [OUT],
			 CASE WHEN 도우모델 like 'VINA%' then sum(a.배부금액) else ROUND(sum(a.단가) * AVG(a.OUT_QTY),0) end AS OUT1,
--			 sum(sum(a.단가) * AVG(a.OUT_QTY)) over (partition by yyyymm)  Model_Total,
			 sum(a.단가) as OUT_단가,
			 case when a.배부방식='CST' THEN 'Y' else COALESCE(A.Adj_YN,'N') end ,
			 1 UnitCost_YN  --select sum(a.배부금액) as [IN]
		from DOI_MAT_COST a
		/*LEFT JOIN (select DISTINCT 도우모델, 구분,ADJ_YN FROM V_DOI_PROD_SUBUL WHERE yyyymm = @YYYYMM and site = @SITE) b 
				ON ( a.도우모델=b.도우모델  and a.구분=b.구분) */
		where 1=1
		  and a.yyyymm = @YYYYMM --and a.도우모델='8136'
		  and a.site = @SITE
		group by a.yyyymm,
			a.sel_code,
			a.site,a.구분,
			a.도우모델,
			case when a.배부방식='CST' THEN 'Y' else COALESCE(A.Adj_YN,'N') end,
			case when a.mat_class='원자재' then '직접재료비' else '간접재료비' end,
			case when a.mat_class='원자재' then 'MDAX' else 'MIAX' end,
			 case 	when mat_gubun='제품' and mat_class='원자재' then '원장'
					when 자재대분류='필름' then 'PF'
					when 자재대분류='트레이' then '트레이' 
					when mat_class='약액' then '약액'
					when mat_class='더미글라스' then '더미글라스'
					else '기타' end;*/
  	  SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비집계 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
  

      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
      DECLARE @SOURCE_AMT DECIMAL(18,2) = 0,
              @TARGET_AMT DECIMAL(18,2) = 0,
              @DIFF_AMT DECIMAL(18,2) = 0;
      
      -- 1. 소스 데이터 (DOI_MAT_COST)
      SELECT @SOURCE_AMT = ISNULL(SUM(배부금액), 0)
      FROM DOI_MAT_COST
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE;
      
      -- 2. 타겟 데이터 (DOI_COST - 재료비만)
      SELECT @TARGET_AMT = ISNULL(SUM([IN]), 0)
      FROM DOI_COST
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE AND expen_sel명 like '%재료비';
 
      SET @DIFF_AMT = @SOURCE_AMT - @TARGET_AMT;
      
    SET  @Message =  @Message + char(10) + '[CHECK] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                    + '- 소스금액(재료비배부): ' + FORMAT(@SOURCE_AMT, 'N0') + '원, '
        + '타겟금액(재공평가): ' + FORMAT(@TARGET_AMT, 'N0') + '원, '
                    + '차이: ' + FORMAT(@DIFF_AMT, 'N0') + '원';
      
   IF ABS(@DIFF_AMT) > 1 BEGIN
          SET  @Message =  @Message + char(10) + '[WARN] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
 + '- 재공평가(재료비) 데이터 불일치 발생!';
      END
      ELSE BEGIN
          SET  @Message =  @Message + char(10) + '[CHECK] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
          + '- 재공평가(재료비) 데이터 무결성 검증 완료 (일치)';
      END
      
      SET  @Message =  @Message + char(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비/재료비집계(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '재료비 데이타 입력 완료했습니다';
      
	 -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '재공 평가', 'UP_DOI_COST_MAT', 'SUCCESS');
					
	  COMMIT TRANSACTION; 
      SELECT @Message as retMessage;
      RETURN 0;
      END TRY
   
   BEGIN CATCH
   
   	 INSERT INTO doi_execlog
	 	values
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '재공 평가', 'UP_DOI_COST_MAT', 'SUCCESS');
     SELECT @Message as retMessage;
	 RETURN -1;
	 
	 ROLLBACK TRANSACTION;
       SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   		SELECT @Message as retMessage;
   END CATCH;
END;		
