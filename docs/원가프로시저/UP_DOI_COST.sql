CREATE   procedure UP_DOI_COST
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
   	
	SET  @Message =  '[START] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '데이타 집계를 시작합니다';
   
	--데이타 체크
	SELECT @CNT = count(*)
		FROM DOI_ACCT
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 원가계정정보(DOI_ACCT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_EXPEN_MATL
      WHERE yyyymm=@YYYYMM
        and site  =@SITE
		and sel_code = @SEL_CODE;
	IF @CNT = 0 BEGIN
		SET @Message =  '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다'; -- as retMessage;
		SET @CHECK = 1;
	END

	   	
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
	
      --삭제
      DELETE FROM DOI_COST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE
        and sel_code = @SEL_CODE;
   	  
     SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';

      INSERT INTO DOI_COST   
	  (YYYYMM ,sel_code ,SITE ,구분 ,model ,expen_sel명 ,ACCT_NAME ,ITEM_NAME ,EXPEN_SEL ,boh_qty ,in_qty ,eoh_qty ,out_qty ,loss_qty ,bad_qty ,transfer_qty ,adj_qty,unit_cost ,boh ,[in] ,eoh ,out_단가 ,[out] ,loss ,bad ,transfer,adj_yn,UnitCost_YN,out_etc)
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
	         boh,
	         [in],
	         eoh,
	  		 case when out_qty = 0 THEN unit_cost 
	         	  ELSE coalesce((boh + "in"-eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) end as out_단가, --(boh금액+in금액-eoh금액)/(out수량+bad수량+Transfer수량)
	         round(case when boh_qty+in_qty = out_qty+loss_qty and out_qty != 0 and @SEL_CODE != 'ACTLSS' then boh + "in"
	         		 	else coalesce((boh + "in"- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * out_qty end,0) as out, --out금액 : out_단가 * out수량
	         --round(case when boh_qty+in_qty = loss_qty then 0 else boh+"in"-(unit_cost * (eoh_qty / 2)) end,0) as out1,
	         round(case when boh_qty+in_qty = loss_qty then boh+"in" 
	         			WHEN @SEL_CODE != 'ACTLSS' then 0
	         			else coalesce((boh + "in"- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * loss_qty end,0) as loss,
	         round(case when boh_qty+in_qty = bad_qty+loss_qty and bad_qty != 0 then boh + "in"
	         		 else coalesce((boh + "in"- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * bad_qty end,0) as bad, --Bad금액 : out_단가 * Bad수량(0)
	         round(case when boh_qty+in_qty = Transfer_qty+loss_qty and Transfer_qty != 0 then boh + "in"
	         		 else coalesce((boh + "in"- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * Transfer_qty end,0) as transfer,
	         adj_yn,UnitCost_YN,
	         case when boh_qty = outetc_qty then boh else 0 end out_etc
	   from (   
	   		select
	         YYYYMM,
	         @SEL_CODE as sel_code,
	         SITE,
	         구분,
	         model,
	         expen_sel명,
	         acct_name,
	         SUB_NAME  as item_name,
	         EXPEN_SEL,
	         boh_qty,
	         in_qty,
	         eoh_qty,
	         out_qty,
	         loss_qty,
	         bad_qty,
	         transfer_qty,
	         adj_qty,
	         outetc_qty,
	         unit_cost,
	         boh,
	         [in],
	         round(case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + bad_qty + transfer_qty = 0 and loss_qty > 0)) and eoh_qty != 0 
	         				then boh + "in" else unit_cost * (eoh_qty / 2.0) end,0) as eoh,
	         adj_yn,UnitCost_YN
	      from
	         doi_expen_matl
	      where yyyymm = @YYYYMM
	        and site = @SITE
	        and sel_code = @SEL_CODE
	        and len(model) <= 5 --카세트팀 제외
	    union all    
	  	select
	         YYYYMM,
	         @SEL_CODE as sel_code,
	         SITE,
	         구분,
	         도우모델,
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
	         bad_qty,
	         transfer_qty,
	         환산량 adj_qty,
	         outetc_qty,
	         단가 unit_cost,
	         boh_amt boh,
	         배부금액 as [in],
	         round(case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + bad_qty + transfer_qty = 0 and loss_qty > 0)) and eoh_qty != 0 
	         				then boh_amt + 배부금액 else 단가 * (eoh_qty / 2.0) end,0) as eoh,
	         adj_yn,1 UnitCost_YN
	      from
	         doi_mat_cost
	      where yyyymm = @YYYYMM
	        and site = @SITE
	        and sel_code = @SEL_CODE
		)a ;
  
   	 SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
				+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 부서별 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 배부했습니다';
     

     INSERT INTO DOI_COST
     	(YYYYMM,sel_code,SITE,구분,MODEL,EXPEN_SEL명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
			BOH_QTY ,IN_QTY ,EOH_QTY ,OUT_QTY ,LOSS_QTY ,BAD_QTY ,TRANSFER_QTY ,ADJ_QTY ,UNIT_COST,OUT_단가,[IN],[OUT],ADJ_YN,UnitCost_YN)
		select
				A.YYYYMM,
				a.sel_code,
				A.SITE,
				B.구분,
				A.CST_NO AS MODEL,
				B.EXPEN_SEL명,
				B.ACCT_NAME,
				B.SUB_NAME as ITEM_NAME,
				B.EXPEN_SEL,
				BOH_QTY = 0 ,
				IN_QTY = A.수량 ,
				EOH_QTY = 0 ,
				OUT_QTY = A.수량,
				LOSS_QTY = 0 ,
				BAD_QTY = 0 ,
				TRANSFER_QTY = 0 ,
				ADJ_QTY = A.수량,
				[IN]/ A.수량 as unit_cost,
				[IN]/ A.수량 as out_단가,
				[IN],
				[IN] AS [OUT],
				'Y' as ADJ_YN,
				1 as UmitCost_YN
			from doi_vncst_rate a
			     INNER JOIN doi_expen_matl b 
			     	ON (a.yyyymm=b.yyyymm and a.site=b.site and a.cst_no=b.model and b.sel_code = @SEL_CODE)
		      where 1=1 
		         and a.yyyymm = @YYYYMM
		         and a.site = @SITE;
     
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '카세스팀 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 배부했습니다';

      IF @YYYYMM in (@YYYYMM) BEGIN
	      INSERT INTO DOI_COST   
		  (YYYYMM ,sel_code ,SITE ,구분 ,model ,expen_sel명 ,ACCT_NAME ,ITEM_NAME ,EXPEN_SEL ,ADJ_BOH ,adj_yn,UnitCost_YN)
		  select YYYYMM,
		         sel_code,
		         SITE,
		         구분,
		         model,
		         '*' as expen_sel명,
		         '*' as acct_name,
		         '*' as item_name,
		         '*' as EXPEN_SEL,
		         PRE_EOH_AMT as ADJ_BOH,
		         'Y' adj_yn,
		         1 UnitCost_YN --select *
		   from DOI_BOH_AMT 
		   WHERE 1=1
		     AND yyyymm		= @YYYYMM
		     AND sel_code   = @SEL_CODE
		     AND SITE 		= @SITE
			 AND 기초수량 		= 'N';
      END

      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '기초금액만 있는 MODEL '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 배부했습니다';

      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
      DECLARE @SOURCE_AMT BIGINT = 0,
              @CASSTE_AMT BIGINT = 0,
              @CASSTE_CNT INT = 0,
              @VN_CASSTE_AMT BIGINT = 0,
              @VN_CASSTE_CNT INT = 0,
              @TARGET_AMT BIGINT = 0,
              @DIFF_AMT BIGINT = 0;
      
      -- 소스 금액 (DOI_EXPEN_MATL)
      SELECT @SOURCE_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
      FROM DOI_EXPEN_MATL
      WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE;
      
      --카세트팀 VINA  CASSTE 배뷰 
      select @VN_CASSTE_AMT =  sum(a.ACCT_AMT * c.VINA_CST * coalesce(d.rate,0)) , @VN_CASSTE_CNT = count(*)
      from  doi_acct_expen a
      left join doi_acct b on (a.acct = b.acct and a.yyyymm=b.yyyymm and a.site=b.site)
      left join doi_cst_rate c on (a.yyyymm=c.yyyymm and a.site=c.site)  --카세트의 일부 비용은 정해진 율로 나누고(UTG와 카세트 제품에 귀속)
      left join doi_vncst_rate d on (a.yyyymm=d.yyyymm and a.site=d.site)
      where  a.YYYYMM = @YYYYMM AND a.SITE = @SITE AND a.sel_code = @SEL_CODE
         and a.dept in ('400','448') --카세트팀 
      
      --카세트팀 VINA UTG 배뷰 
      select @CASSTE_AMT =  sum(a.ACCT_AMT * c.UTG * coalesce(d.rate,0)) , @CASSTE_CNT = count(*)
      from  doi_acct_expen a
      left join doi_acct b on (a.acct = b.acct and a.yyyymm=b.yyyymm and a.site=b.site)
      left join doi_cst_rate c on (a.yyyymm=c.yyyymm and a.site=c.site)  --카세트의 일부 비용은 정해진 율로 나누고(UTG와 카세트 제품에 귀속)
      left join doi_vncst_rate d on (a.yyyymm=d.yyyymm and a.site=d.site)
   where  a.YYYYMM = @YYYYMM AND a.SITE = @SITE AND a.sel_code = @SEL_CODE
         and a.dept in ('400','448') --카세트팀 
      
      -- 타겟 금액 (DOI_COST)
      SELECT @TARGET_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
      FROM DOI_COST
      WHERE YYYYMM = @YYYYMM AND SITE = @SITE and SEL_CODE = @SEL_CODE AND expen_sel명 not like  '%재료비';
      
      SET @DIFF_AMT = @SOURCE_AMT - @TARGET_AMT;
  
      -- ========================================
      -- 1. 소스 vs 타겟 금액 검증
      -- ========================================
      SET  @Message =  @Message + char(10) + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + '1. 소스 데이터와 타겟 데이터 금액 검증';
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '구분' + REPLICATE(' ', 25) + '건수' + REPLICATE(' ', 15) + '금액';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      
      -- 소스 상세
      DECLARE @SOURCE_CNT INT = 0;
      SELECT @SOURCE_CNT = COUNT(*) FROM DOI_EXPEN_MATL
      WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE;
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('소스(DOI_EXPEN_MATL)' + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@SOURCE_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@SOURCE_AMT, 'N0'), 20) + '원';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('소스(CST팀 VINA)'    + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@VN_CASSTE_CNT AS VARCHAR(10)), 9) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@VN_CASSTE_AMT, 'N0'), 20) + '원';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('소스(CST팀 UTG)'     + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@CASSTE_CNT AS VARCHAR(10)), 9) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@CASSTE_AMT, 'N0'), 20) + '원';      
      -- 타겟 상세
      DECLARE @TARGET_CNT INT = 0;
      SELECT @TARGET_CNT = COUNT(*) FROM DOI_COST WHERE YYYYMM = @YYYYMM AND SITE = @SITE and SEL_CODE = @SEL_CODE AND expen_sel명 != '재료비';
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('타겟(DOI_COST)' + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@TARGET_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@TARGET_AMT, 'N0'), 20) + '원';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '차이' + REPLICATE(' ', 32) + RIGHT(REPLICATE(' ', 20) + FORMAT(@DIFF_AMT, 'N0'), 20) + '원';
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      
      -- ========================================
      -- 2. 차이금액 상세 (항목별)
      -- ========================================
      IF ABS(@DIFF_AMT) > 100 BEGIN
          SET  @Message =  @Message + char(10) + char(10) + '====================================================================================================';
          SET  @Message =  @Message + char(10) + '2. 차이금액 상세 (항목별)';
          SET  @Message =  @Message + char(10) + '====================================================================================================';
          
          DECLARE @EXPEN_SEL NVARCHAR(50), @EXPEN_NAME NVARCHAR(100);
          DECLARE @SOURCE_ITEM_AMT BIGINT, @TARGET_ITEM_AMT BIGINT, @ITEM_DIFF BIGINT;
          
          SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + '항목코드' + REPLICATE(' ', 7) + '항목명' + REPLICATE(' ', 34) + '소스금액' + REPLICATE(' ', 10) + '타겟금액' + REPLICATE(' ', 10) + '차이';
          SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
          
          DECLARE item_cursor CURSOR FOR
          SELECT DISTINCT EXPEN_SEL, EXPEN_SEL명
         FROM DOI_EXPEN_MATL
          WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE
          ORDER BY EXPEN_SEL;
          
     OPEN item_cursor;
          FETCH NEXT FROM item_cursor INTO @EXPEN_SEL, @EXPEN_NAME;
          
          WHILE @@FETCH_STATUS = 0
          BEGIN
              -- 소스에서 해당 항목 금액
        SELECT @SOURCE_ITEM_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
              FROM DOI_EXPEN_MATL
              WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND EXPEN_SEL = @EXPEN_SEL AND sel_code = @SEL_CODE;
              
              -- 타겟에서 해당 항목 금액
              SELECT @TARGET_ITEM_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
              FROM DOI_COST
              WHERE YYYYMM = @YYYYMM AND SITE = @SITE and SEL_CODE = @SEL_CODE AND EXPEN_SEL = @EXPEN_SEL;
              
              SET @ITEM_DIFF = @SOURCE_ITEM_AMT - @TARGET_ITEM_AMT;
              
              IF ABS(@ITEM_DIFF) > 10 BEGIN
                  SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
                      + LEFT(@EXPEN_SEL + REPLICATE(' ', 15), 15)
					  --+ LEFT(ISNULL(@EXPEN_NAME, '') + REPLICATE(' ', 40), 40)
					  + LEFT(ISNULL(@EXPEN_NAME, '')+ REPLICATE(' ',3-dbo.DOI_ASCII_COUNT(@EXPEN_NAME)) + REPLICATE(NCHAR(0x3000), 15), 17)
                   	  + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_ITEM_AMT, 'N0'), 18)
                      + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_ITEM_AMT, 'N0'), 18)
                      + RIGHT(REPLICATE(' ', 18) + FORMAT(@ITEM_DIFF, 'N0'), 18);
              END
              
              FETCH NEXT FROM item_cursor INTO @EXPEN_SEL, @EXPEN_NAME;
          END
          
          CLOSE item_cursor;
          DEALLOCATE item_cursor;
          
          SET  @Message =  @Message + char(10) + '====================================================================================================';
      END
      
      -- ========================================
      -- 3. 경비항목별 상세 집계
      -- ========================================
      SET  @Message =  @Message + char(10) + char(10) + REPLICATE('=', 140)
      SET  @Message =  @Message + char(10) + '3. 경비항목별 상세 집계';
      SET  @Message =  @Message + char(10) + REPLICATE('=', 140)
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + '항목코드' + REPLICATE(' ', 7) + '항목명' + REPLICATE(' ', 34) + 'UTG집계' + REPLICATE(' ', 10) + 'VINA CST집계'+ REPLICATE(' ', 10) + '소스집계'+ REPLICATE(' ', 10) + '배부집계' + REPLICATE(' ', 10) + '차이금액';
      SET  @Message =  @Message + char(10) + REPLICATE('-', 140);
      
      DECLARE @EXPEN_SEL_DTL NVARCHAR(50), @EXPEN_NAME_DTL NVARCHAR(100);
      DECLARE @SOURCE_DTL_AMT BIGINT, @UTG_DTL_AMT BIGINT, @CASSTE_DTL_AMT BIGINT, @TARGET_DTL_AMT BIGINT, @DTL_DIFF BIGINT;
      
     SELECT
         B.EXPEN_SEL, 
         B.EXPEN_SEL명 ,
         SUM(A.ACCT_AMT * C.VINA_CST * D.RATE) AS [IN] INTO #VINA_CST
      FROM
         DOI_ACCT_EXPEN A
      LEFT JOIN DOI_ACCT B ON (A.ACCT = B.ACCT AND A.YYYYMM=B.YYYYMM AND A.SITE=B.SITE)
      LEFT JOIN DOI_CST_RATE C ON (A.YYYYMM=C.YYYYMM AND A.SITE=C.SITE)  --카세트의 일부 비용은 정해진 율로 나누고(UTG와 카세트 제품에 귀속)
      LEFT JOIN DOI_VNCST_RATE D ON (A.YYYYMM=D.YYYYMM AND A.SITE=D.SITE)
      WHERE 1=1 
         AND A.YYYYMM = @YYYYMM AND A.SITE=@SITE AND A.SEL_CODE = @SEL_CODE
         AND A.DEPT IN ('400','448') --카세트팀 
      GROUP BY
         B.EXPEN_SEL,
         B.EXPEN_SEL명 ;
            
      
      DECLARE detail_cursor CURSOR FOR
      SELECT DISTINCT EXPEN_SEL, EXPEN_SEL명
      FROM DOI_EXPEN_MATL
      WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SEL_CODE = @SEL_CODE
        AND EXPEN_SEL IS NOT NULL
      ORDER BY EXPEN_SEL;
    
      OPEN detail_cursor;
      FETCH NEXT FROM detail_cursor INTO @EXPEN_SEL_DTL, @EXPEN_NAME_DTL;
      
      WHILE @@FETCH_STATUS = 0
      BEGIN
          -- 소스 금액
          SELECT @SOURCE_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
          FROM DOI_EXPEN_MATL
          WHERE YYYYMM = @YYYYMM 
      		AND SITE = @SITE 
      		AND EXPEN_SEL = @EXPEN_SEL_DTL AND SEL_CODE = @SEL_CODE
      		AND SUB_NAME in('UTG','CST');
          
      	  -- 카세트 금액
          SELECT @CASSTE_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
          FROM #VINA_CST
          WHERE EXPEN_SEL = @EXPEN_SEL_DTL;
      
      
          
          -- 타겟 금액
          SELECT @TARGET_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
       FROM DOI_COST
          WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SEL_CODE = @SEL_CODE AND EXPEN_SEL = @EXPEN_SEL_DTL;
          
          SET @DTL_DIFF = @SOURCE_DTL_AMT + @CASSTE_DTL_AMT - @TARGET_DTL_AMT ; 
   
         SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
              + LEFT(ISNULL(@EXPEN_SEL_DTL, '') + REPLICATE(' ', 15), 15)
          + LEFT(ISNULL(@EXPEN_NAME_DTL, '') + REPLICATE(' ',3-dbo.DOI_ASCII_COUNT(@EXPEN_NAME_DTL))+ REPLICATE(NCHAR(0x3000), 13), 18)
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_DTL_AMT, 'N0'), 18)              
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@CASSTE_DTL_AMT, 'N0'), 18)             
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_DTL_AMT+@CASSTE_DTL_AMT, 'N0'), 18)
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_DTL_AMT, 'N0'), 18)
              + RIGHT(REPLICATE(' ', 15) + FORMAT(@DTL_DIFF, 'N0'), 15);
          
          FETCH NEXT FROM detail_cursor INTO @EXPEN_SEL_DTL, @EXPEN_NAME_DTL;
      END
      
      CLOSE detail_cursor;
      DEALLOCATE detail_cursor;
      
      SET  @Message =  @Message + char(10) + REPLICATE('=', 140);
      -- 소스 금액(UTG)
          SELECT @UTG_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
          FROM DOI_EXPEN_MATL
          WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SUB_NAME in('UTG','CST') AND SEL_CODE = @SEL_CODE;
       -- 카세트 금액
          SELECT @CASSTE_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
          FROM #VINA_CST
       -- 소스 금액
          SELECT @SOURCE_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
          FROM DOI_EXPEN_MATL
          WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SEL_CODE = @SEL_CODE
      -- 타겟 금액(재료비는 별도 배부함)
          SELECT @TARGET_DTL_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
          FROM DOI_COST
          WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND SEL_CODE = @SEL_CODE and EXPEN_SEL not in ('MIAX','MDAX');
       --차이 
      SET @ITEM_DIFF = @SOURCE_DTL_AMT - @TARGET_DTL_AMT; 
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 20) + '합계' + RIGHT(REPLICATE(' ', 43) + FORMAT(@UTG_DTL_AMT, 'N0'), 43)
      		+ RIGHT(REPLICATE(' ', 18) + FORMAT(@CASSTE_DTL_AMT, 'N0'), 18) + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_DTL_AMT, 'N0'), 18)
      		+ RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_DTL_AMT, 'N0'), 18) + RIGHT(REPLICATE(' ', 15) + FORMAT(@ITEM_DIFF, 'N0'), 15);
      
      -- 최종 상태
      IF ABS(@DIFF_AMT) > 100 BEGIN
          DECLARE @DIFF_PCT DECIMAL(10,4) = (CAST(@DIFF_AMT AS DECIMAL(20,2)) / CAST(@TARGET_AMT AS DECIMAL(20,2))) * 100;
          SET  @Message =  @Message + char(10) + char(10) + '⚠️  [WARN] 가공비배부 데이터 불일치 발생! (차이율: ' + CAST(@DIFF_PCT AS VARCHAR(10)) + '%)';
      END
      ELSE BEGIN
          SET  @Message =  @Message + char(10) + char(10) + '✅ [CHECK] 가공비배부 데이터 무결성 검증 통과';
      END
      SET  @Message =  @Message + char(10);
      
      
      -- ========================================
      -- 재료비 데이터 무결성 검증
      -- ========================================
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
      
      SET  @Message =  @Message + char(10) + '[FINISH]' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 배부 완료했습니다';

	 -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '가공비 배부', 'UP_DOI_COST', 'SUCCESS');
					
      COMMIT TRANSACTION;
      
      --Temp 테이블  DROP
      DROP TABLE #VINA_CST;
      
      SELECT @Message as retMessage;
      RETURN 0;
      
 	END TRY
   
   BEGIN CATCH
       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
       
       INSERT INTO doi_execlog
       	 values
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '가공비,재료비 배부', 'UP_DOI_COST', 'FAIL');	
       SELECT @Message as retMessage;
       RETURN -1;
       ROLLBACK TRANSACTION;
       SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   		SELECT @Message as retMessage;
   END CATCH;
END
