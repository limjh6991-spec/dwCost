-- ==========================================
-- File: UP_VN_COST.sql
-- ==========================================
CREATE OR ALTER PROCEDURE UP_VN_COST
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
   
	IF EXISTS (
	    SELECT 1
	    FROM DOI_CLOSING_MONTH
	    WHERE YYYYMM = @YYYYMM
	      AND IS_CLOSED = 'Y'
	)
	BEGIN
	    RAISERROR(N'마감된 결산월(%s)은 실행할 수 없습니다.', 16, 1, @YYYYMM);
	    RETURN;
	END          
   	
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

	 BEGIN TRANSACTION;	
      --삭제
      DELETE FROM DOI_COST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE
        and sel_code = @SEL_CODE;
   	  
     SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비배부(DOI_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';

      INSERT INTO DOI_COST   
	  (YYYYMM ,sel_code ,SITE ,구분 ,model ,expen_sel명 ,ACCT_NAME ,ITEM_NAME ,EXPEN_SEL ,boh_qty ,in_qty ,eoh_qty ,out_qty ,loss_qty ,bad_qty ,transfer_qty ,adj_qty,unit_cost ,boh ,[in] ,eoh ,out_단가 ,[out] ,loss ,bad ,transfer,adj_yn,UnitCost_YN,out_etc ,ETC_IN_DEF_RW_QTY ,ETC_IN_DEF_RW_AMT ,RMAIN_QTY ,RMAIN_AMT)
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
	         coalesce("in",0),
	         eoh,
	  		 case when out_qty = 0 THEN unit_cost 
	         	  ELSE coalesce((boh + coalesce("in",0)-eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) end as out_단가, --(boh금액+in금액-eoh금액)/(out수량+bad수량+Transfer수량)
	         round(case when boh_qty+in_qty = out_qty+loss_qty and out_qty != 0 and @SEL_CODE != 'ACTLSS' then boh + coalesce("in",0)
	         		 	else coalesce((boh + coalesce("in",0)- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * out_qty end,0) as out, --out금액 : out_단가 * out수량
	         --round(case when boh_qty+in_qty = loss_qty then 0 else boh+"in"-(unit_cost * (eoh_qty / 2)) end,0) as out1,
	         round(case when boh_qty+in_qty = loss_qty then boh+coalesce("in",0) 
	  			WHEN @SEL_CODE != 'ACTLSS' then 0
	         			else coalesce((boh + coalesce("in",0)- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * loss_qty end,0) as loss,
	         round(case when boh_qty+in_qty = bad_qty+loss_qty and bad_qty != 0 then boh + coalesce("in",0)
	         		 else coalesce((boh + coalesce("in",0)- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * bad_qty end,0) as bad, --Bad금액 : out_단가 * Bad수량(0)
	         round(case when boh_qty+in_qty = Transfer_qty+loss_qty and Transfer_qty != 0 then boh + coalesce("in",0)
	         		 else coalesce((boh + coalesce("in",0)- eoh)/ nullif(out_qty+bad_qty+Transfer_qty+ IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 0) * Transfer_qty end,0) as transfer,
	         adj_yn,UnitCost_YN,
	         case when boh_qty = outetc_qty then boh else 0 end out_etc,
         coalesce(def_rw_qty,0) as ETC_IN_DEF_RW_QTY,
         round(coalesce(def_rw_qty,0) * unit_cost, 2) as ETC_IN_DEF_RW_AMT,
         coalesce(transfer_in_qty,0) as RMAIN_QTY,
         round(coalesce(transfer_in_qty,0) * unit_cost, 2) as RMAIN_AMT
	   from ( 
	    select f.*, Base_eoh + CASE WHEN RN = 1 THEN ROUND(Sum_Ori_eoh,0) - Sum_Base_eoh ELSE 0 END AS eoh
	    from (
	   		select o.*,
	   		sum(Ori_eoh) over(partition by 구분,model) as Sum_Ori_eoh, 
	    	sum(Base_eoh) over(partition by 구분,model) as Sum_Base_eoh,
	    	ROW_NUMBER() over(partition by 구분,model order by Ori_eoh DESC) as rn
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
	         case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + bad_qty + transfer_qty = 0 and loss_qty > 0)) and eoh_qty != 0 
	         				then boh + coalesce("in",0) else unit_cost * (eoh_qty / 2.0) end as Ori_eoh,
 	         round(case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + bad_qty + transfer_qty = 0 and loss_qty > 0)) and eoh_qty != 0 
 				then boh + coalesce("in",0) else unit_cost * (eoh_qty / 2.0) end,0) as Base_eoh,
	         adj_yn,UnitCost_YN,
         (SELECT ISNULL(SUM(p.기타입고_불량_RW),0) FROM doi_prod_subul p WHERE p.yyyymm=doi_expen_matl.yyyymm AND p.site=doi_expen_matl.site AND p.구분=doi_expen_matl.구분 AND p.도우모델=doi_expen_matl.model) AS def_rw_qty,
         (SELECT ISNULL(SUM(ISNULL(p.기타입고_LOT변환,0)+ISNULL(p.기타입고_불량_RW,0)+ISNULL(p.기타입고_RMA_RW,0)+ISNULL(p.기타입고_전월불량,0)+ISNULL(p.기타입고_당월불량,0)),0) FROM doi_prod_subul p WHERE p.yyyymm=doi_expen_matl.yyyymm AND p.site=doi_expen_matl.site AND p.구분=doi_expen_matl.구분 AND p.도우모델=doi_expen_matl.model) AS transfer_in_qty
	      from
	         doi_expen_matl
	      where yyyymm = @YYYYMM
	        and site = @SITE
	        and sel_code = @SEL_CODE
	        and len(model) <= 5 --카세트팀 제외
	        ) o
	     ) f   
	    union all
	    select f.*, Base_eoh + CASE WHEN RN = 1 THEN round(Sum_Ori_eoh,0) - Sum_Base_eoh ELSE 0 END AS eoh
	    from (
	    select o.*,
	    	sum(Ori_eoh) over(partition by 구분,도우모델) as Sum_Ori_eoh, 
	    	sum(Base_eoh) over(partition by 구분,도우모델) as Sum_Base_eoh,
	    	ROW_NUMBER() over(partition by 구분,도우모델 order by Ori_eoh DESC) as rn
	    from(	
	  	select
	         YYYYMM,
	         @SEL_CODE as sel_code,
	         SITE,
	         구분,
	         도우모델,
	         case when 
	         mat_class='원자재' or 원가자재분류 = '원장' 
	         or mat_class+자재대분류 ='부자재'+'필름' or 원가자재분류 ='필름'
	         or mat_class+자재대분류 ='원자재'+'카세트' or 원가자재분류 = '카세트' 
	         or (mat_class+coalesce(자재대분류,'1') ='약액'+'1'  )
	         or (mat_class+자재대분류 ='부자재'+'약액' )  or 원가자재분류 ='약액'
	         then '직접재료비' else '간접재료비' end as expen_sel명,
	         		case
					when mat_class+자재대분류 ='부자재'+'필름' or 원가자재분류 = '필름' then 'PF'
					WHEN mat_class+자재대분류 ='원자재'+'카세트' or 원가자재분류 ='카세트' THEN '카세트'
					when (mat_class+coalesce(자재대분류,'1') ='약액'+'1'  ) or (mat_class+자재대분류 ='부자재'+'약액' ) or 원가자재분류 ='약액' then '약액'
					WHEN (mat_class+자재대분류 ='부자재'+'트레이' or 원가자재분류 = '트레이') THEN '트레이'
					when mat_class='원자재' then '원장'
					else '기타' 
			 end as ACCT_NAME,
	         자재번호  as item_name,
	   		case when mat_class='원자재' or 원가자재분류 = '원장'
	   		or mat_class+자재대분류 ='부자재'+'필름' or 원가자재분류 ='필름'
	   		or mat_class+자재대분류 ='원자재'+'카세트' or 원가자재분류 ='카세트'
	   		or (mat_class+coalesce(자재대분류,'1') ='약액'+'1'  ) 
	   		or (mat_class+자재대분류 ='부자재'+'약액' ) or 원가자재분류 ='약액'
	   			 then 'MDAX' else 'MIAX' end as EXPEN_SEL,
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
	         case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + bad_qty + transfer_qty = 0 and loss_qty > 0)) and eoh_qty != 0 
	         				then boh_amt + 배부금액 else 단가 * (eoh_qty / 2.0) end as Ori_eoh,
	         round(case when (boh_qty+in_qty = eoh_qty or boh_qty+in_qty = eoh_qty+loss_qty or (out_qty + bad_qty + transfer_qty = 0 and loss_qty > 0)) and eoh_qty != 0 
	         				then boh_amt + 배부금액 else 단가 * (eoh_qty / 2.0) end,0) as Base_Eoh,
	         adj_yn,1 UnitCost_YN,
         (SELECT ISNULL(SUM(p.기타입고_불량_RW),0) FROM doi_prod_subul p WHERE p.yyyymm=doi_mat_cost.yyyymm AND p.site=doi_mat_cost.site AND p.구분=doi_mat_cost.구분 AND p.도우모델=doi_mat_cost.도우모델) AS def_rw_qty,
         (SELECT ISNULL(SUM(ISNULL(p.기타입고_LOT변환,0)+ISNULL(p.기타입고_불량_RW,0)+ISNULL(p.기타입고_RMA_RW,0)+ISNULL(p.기타입고_전월불량,0)+ISNULL(p.기타입고_당월불량,0)),0) FROM doi_prod_subul p WHERE p.yyyymm=doi_mat_cost.yyyymm AND p.site=doi_mat_cost.site AND p.구분=doi_mat_cost.구분 AND p.도우모델=doi_mat_cost.도우모델) AS transfer_in_qty
	      from
	         doi_mat_cost
	      where yyyymm = @YYYYMM
	        and site = @SITE
	        and sel_code = @SEL_CODE
	        ) o
	      ) f  
		) a ;
  
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

      /*IF @YYYYMM in (@YYYYMM) BEGIN  --2026.03.28 KYH
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
      END*/

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
      select @VN_CASSTE_AMT =  ISNULL(sum(a.ACCT_AMT * c.VINA_CST * coalesce(d.rate,0)),0) , @VN_CASSTE_CNT = count(*)
      from  doi_acct_expen a
      left join doi_acct b on (a.acct = b.acct and a.yyyymm=b.yyyymm and a.site=b.site)
      left join doi_cst_rate c on (a.yyyymm=c.yyyymm and a.site=c.site)  --카세트의 일부 비용은 정해진 율로 나누고(UTG와 카세트 제품에 귀속)
      left join doi_vncst_rate d on (a.yyyymm=d.yyyymm and a.site=d.site)
      where  a.YYYYMM = @YYYYMM AND a.SITE = @SITE AND a.sel_code = @SEL_CODE
         and a.dept in ('400','448') --카세트팀 
      
      --카세트팀 VINA UTG 배뷰 
      select @CASSTE_AMT =  ISNULL(sum(a.ACCT_AMT * c.UTG * coalesce(d.rate,0)),0) , @CASSTE_CNT = count(*)
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
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('소스(DOI_EXPEN_MATL)' + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@SOURCE_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@SOURCE_AMT, 'N2'), 20) + '달러';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('소스(CST팀 VINA)'    + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@VN_CASSTE_CNT AS VARCHAR(10)), 9) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@VN_CASSTE_AMT, 'N2'), 20) + '달러';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('소스(CST팀 UTG)'     + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@CASSTE_CNT AS VARCHAR(10)), 9) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@CASSTE_AMT, 'N2'), 20) + '달러';      
      -- 타겟 상세
      DECLARE @TARGET_CNT INT = 0;
      SELECT @TARGET_CNT = COUNT(*) FROM DOI_COST WHERE YYYYMM = @YYYYMM AND SITE = @SITE and SEL_CODE = @SEL_CODE AND expen_sel명 != '재료비';
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + LEFT('타겟(DOI_COST)' + REPLICATE(' ', 20),20) + RIGHT(REPLICATE(' ', 10) + CAST(@TARGET_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@TARGET_AMT, 'N2'), 20) + '달러';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '차이' + REPLICATE(' ', 32) + RIGHT(REPLICATE(' ', 20) + FORMAT(@DIFF_AMT, 'N2'), 20) + '달러';
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
                   	  + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_ITEM_AMT, 'N2'), 18)
                      + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_ITEM_AMT, 'N2'), 18)
                      + RIGHT(REPLICATE(' ', 18) + FORMAT(@ITEM_DIFF, 'N2'), 18);
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
      SET @Message =  @Message + char(10) + REPLICATE('-', 140);
      
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
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_DTL_AMT, 'N2'), 18)              
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@CASSTE_DTL_AMT, 'N2'), 18)             
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_DTL_AMT+@CASSTE_DTL_AMT, 'N2'), 18)
              + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_DTL_AMT, 'N2'), 18)
              + RIGHT(REPLICATE(' ', 15) + FORMAT(@DTL_DIFF, 'N2'), 15);
          
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

      SET  @Message =  @Message + char(10) + REPLICATE(' ', 20) + '합계' + RIGHT(REPLICATE(' ', 43) + FORMAT(@UTG_DTL_AMT, 'N2'), 43)
      		+ RIGHT(REPLICATE(' ', 18) + FORMAT(@CASSTE_DTL_AMT, 'N2'), 18) + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_DTL_AMT, 'N2'), 18)
      		+ RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_DTL_AMT, 'N2'), 18) + RIGHT(REPLICATE(' ', 15) + FORMAT(@ITEM_DIFF, 'N2'), 15);
      
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
      + '- 소스금액(재료비배부): ' + FORMAT(@SOURCE_AMT, 'N2') + '원, '
        + '타겟금액(재공평가): ' + FORMAT(@TARGET_AMT, 'N2') + '원, '
                    + '차이: ' + FORMAT(@DIFF_AMT, 'N2') + '달러';
      
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
	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '가공비 배부', 'UP_VN_FAB_COST', 'SUCCESS');

      -- ============================================================
      -- [임시] PL전/PL후/입고전 재공 완성률 평가금액 → DOI_COST(PL전_AMT/PL후_AMT/입고전_AMT)
      --   금액 = 모델단가(SUM UNIT_COST) × 수량(DOI_PROD_SUBUL, 콤마제거) × 완성률
      --          PL전 50% / PL후 90% / 입고전 100%
      --   모델당 대표 1행([IN] 최대)에만 저장하여 중복합산 방지. (비파괴·추후 조정)
      --   ※ 저볼륨 개발모델은 단가 과대 → 금액 과대 가능(추후 단가기준 재검토)
      -- ============================================================
      ;WITH uc AS (
          SELECT SITE, 구분, MODEL, SUM(UNIT_COST) AS unit_cost_tot
          FROM DOI_COST
          WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE
          GROUP BY SITE, 구분, MODEL
      ),
      pq AS (
          SELECT SITE, 구분, 도우모델,
                 SUM(TRY_CONVERT(float, REPLACE(REPLACE(ISNULL(PL전,N'0'),N',',N''),N' ',N'')))  AS PL전_qty,
                 SUM(TRY_CONVERT(float, REPLACE(REPLACE(ISNULL(PL후,N'0'),N',',N''),N' ',N'')))  AS PL후_qty,
                 SUM(TRY_CONVERT(float, REPLACE(REPLACE(ISNULL(입고전,N'0'),N',',N''),N' ',N''))) AS 입고전_qty
          FROM DOI_PROD_SUBUL
          WHERE YYYYMM=@YYYYMM AND SITE=@SITE
          GROUP BY SITE, 구분, 도우모델
      ),
      ranked AS (
          SELECT c.PL전_AMT, c.PL후_AMT, c.입고전_AMT, c.SITE, c.구분, c.MODEL,
                 ROW_NUMBER() OVER (PARTITION BY c.SITE, c.구분, c.MODEL ORDER BY c.[IN] DESC, c.ITEM_NAME) AS rn
          FROM DOI_COST c
          WHERE c.YYYYMM=@YYYYMM AND c.SITE=@SITE AND c.SEL_CODE=@SEL_CODE
      )
      UPDATE r SET
          PL전_AMT   = ROUND(uc.unit_cost_tot * ISNULL(pq.PL전_qty,0)   * 0.5, 2),
          PL후_AMT   = ROUND(uc.unit_cost_tot * ISNULL(pq.PL후_qty,0)   * 0.9, 2),
          입고전_AMT = ROUND(uc.unit_cost_tot * ISNULL(pq.입고전_qty,0) * 1.0, 2)
      FROM ranked r
      JOIN uc ON uc.SITE=r.SITE AND uc.구분=r.구분 AND uc.MODEL=r.MODEL
      LEFT JOIN pq ON pq.SITE=r.SITE AND pq.구분=r.구분 AND pq.도우모델=r.MODEL
      WHERE r.rn = 1;
					
      COMMIT TRANSACTION;
      
      --Temp 테이블  DROP
      DROP TABLE #VINA_CST;
      
      SELECT @Message as retMessage;
      RETURN 0;
      
 	END TRY
   
   BEGIN CATCH
       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
       
       INSERT INTO doi_execlog
       	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
       	 values
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system','가공비,재료비 배부', 'UP_VN_COST', 'FAIL');

       SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   		SELECT @Message as retMessage;
       RETURN -1;
   END CATCH;
END;
GO

-- ==========================================
-- File: UP_VN_EXPEN_MATL.sql
-- ==========================================

CREATE OR ALTER Procedure UP_VN_EXPEN_MATL
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(5),  --사업장코드 (본사 : HQ, 베트남 : VN)
    @SEL_CODE VARCHAR(6)
)
AS
BEGIN
	SET NOCOUNT ON;
    SET LOCK_TIMEOUT 10000; -- 10초로 증가
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- 격리 수준 변경
    DECLARE  @Message  NVARCHAR(MAX)=''
    
    -- 1초 대기
    WAITFOR DELAY '00:00:01';
   
	IF EXISTS (
	    SELECT 1
	    FROM DOI_CLOSING_MONTH
	    WHERE YYYYMM = @YYYYMM
	      AND IS_CLOSED = 'Y'
	)
	BEGIN
	    RAISERROR(N'마감된 결산월(%s)은 실행할 수 없습니다.', 16, 1, @YYYYMM);
	    RETURN;
	END          
      	
   	BEGIN TRY
      /*DECLARE @YYYYMM VARCHAR(6) = '202507', --집계 년/월 설정
            @SITE   VARCHAR(2) = 'HQ';*/
   	
	SET  @Message =  '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '데이타 집계를 시작합니다';
	
	DECLARE @CNT INT = 0,
			@CHECK BIT = 0;
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
		FROM DOI_DEPT
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+ '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서정보(DOI_DEPT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	SELECT @CNT = count(*)
		FROM DOI_DEPT_COST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+ '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서별,계정별 투입비용(DOI_DEPT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE = 'HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM V_DOI_PROD_SUBUL
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 생산수불(DOI_PROD_SUBUL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_MODEL_MAST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 면적정보(DOI_MODEL_MAST) 테이블에 '
				+ @YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	SELECT @CNT = count(*)
		FROM DOI_CST_RATE
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- VINA카세트 배부비율(DOI_CST_RATE) 테이블에 '
				+ @YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	/*SELECT @CNT = count(*)
		FROM DOI_BOH_AMT
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재공기초금액(DOI_BOH_AMT) 테이블에 '
				+ @YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END*/

	IF @CHECK = 1 BEGIN 
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 기본정보 테이블들에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SELECT @Message as retMessage;
		RETURN -1;
	END

	--창고 입고수량을 생산수불 FAB OUT 수량 및 EOH 수량을 조정
  	DECLARE @Ret_M nvarchar(MAX)='';  --2026.01.05 임시로 막음
	EXEC ADJ_DOI_PROD_SUBUL
		@YYYYMM = @YYYYMM,
		@SITE = @SITE,
		@R_Message = @Ret_M OUTPUT;
      SET  @Message =  @Message + @Ret_M ;	
	
	--삭제
 BEGIN TRANSACTION;
      DELETE FROM DOI_ACCT_EXPEN
      WHERE 1=1
        and yyyymm = @YYYYMM
        and site  = @SITE
		and sel_code = @SEL_CODE;
     
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서별/원가항목별 투입비용(DOI_ACCT_EXPEN) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';
     
      INSERT INTO DOI_ACCT_EXPEN
		(YYYYMM, SEL_CODE, SITE, ACCT_CLASS, DEPT, ACCT, ACCT_NAME, ITEM_NAME, ACCT_AMT, DBT_AMT, CRT_AMT, EXPEN_SEL, EXPEN_SEL명,DISP_SEQ)
		select
			a.yyyymm as YYYYMM,
			@SEL_CODE as SEL_CODE,
			a.site as SITE,
			case
				when 비용구분 = '판관' then 'CC'
				when 비용구분 = '제조' then 'AA'
			else 비용구분	
			end as ACCT_CLASS,
			b.dept as DEPT,
			a.계정코드 as ACCT ,
			a.계정과목 as ACCT_NAME,
			c.소분류 as ITEM_NAME,
			차변금액 /*- 대변금액*/ as ACCT_AMT,
			차변금액 as DBT_AMT,
			대변금액 as CRT_AMT,
			c.expen_sel as EXPEN_SEL,
			c.expen_sel명 as EXPEN_SEL명,
			c.disp_seq
		from
			DOI_DEPT_COST a
		left join (select distinct dept,dept_name from doi_dept where yyyymm=@YYYYMM and site = @SITE) b	on (a.코스트센터 = b.dept_name)
		left join doi_acct c on (a.yyyymm= c.yyyymm	and a.sel_code = c.sel_code	and a.site = c.site	and a.계정코드 = c.acct)
		where 1=1
		  and a.yyyymm = @YYYYMM
          and a.site  = @SITE
          and coalesce(nullif(a.제외여부,''),'N') = 'N'
      	  --and a.계정코드 not in ('52099010','53099010');
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서별/원가항목별 투입비용(DOI_ACCT_EXPEN) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';

	/* 20260514 삭제 YHKIM
      --생산수불이 있는 물량은 기초금액을 경비와 재료비로 금액 비율로 배부한다 
     	UPDATE doi_boh_amt 
		SET 기초수량 = 'Y'
		WHERE YYYYMM = @YYYYMM
		  AND EXISTS (
		    SELECT 1
		    FROM doi_prod_subul b
		    WHERE b.yyyymm = @YYYYMM
		      --AND b.도우모델 = doi_boh_amt.MODEL
		      AND b.도우코드 = doi_boh_amt.MODEL_type
		      AND b.BOH_month != 0
		  );
		--생산수불이 없는 물량은 기초금액을 경비에만 배부한다 
		UPDATE doi_boh_amt 
		SET 기초수량 = 'N'
		WHERE YYYYMM = @YYYYMM
		  AND NOT EXISTS (
		    SELECT 1
		    FROM doi_prod_subul b
		    WHERE b.yyyymm = @YYYYMM
		      --AND b.도우모델 = doi_boh_amt.MODEL
		      AND b.도우코드 = doi_boh_amt.MODEL_type
		      AND b.BOH_month != 0
		  );
      
		DECLARE @제조경비 bigint,
		@재료비 bigint,
		@기초금액 bigint,
		@경비비율 float;

		select @기초금액=sum(PRE_EOH_AMT) 
		from doi_boh_amt
		where 1=1 
			and yyyymm = @YYYYMM
			and site = @SITE
			and sel_code = @SEL_CODE;
		
		select	@제조경비 = sum(ACCT_AMT)
		from	doi_acct_expen
		where 1=1 
			and yyyymm = @YYYYMM
			and site = @SITE
			and sel_code = @SEL_CODE
			and ACCT_CLASS = 'AA';
		
		select	@재료비 = sum(투입금액)
		from	doi_matl_resc
		where 1=1
			and yyyymm = @YYYYMM
			and site = @SITE
			and sel_code = @SEL_CODE;
		
		select @경비비율=CAST(@제조경비 as float)/(@제조경비+@재료비);
		
		select	YYYYMM,SEL_CODE,SITE,구분,MODEL,MODEL_TYPE,PRE_EOH_AMT,기초수량,
			case when 기초수량 ='Y' then round((PRE_EOH_AMT * @경비비율), 0) else PRE_EOH_AMT end as 경비기초,
			case when 기초수량 ='Y' then PRE_EOH_AMT-round((PRE_EOH_AMT * @경비비율), 0) else 0 end 재료비기초  --select *
			INTO #bohAmt
		FROM
			doi_boh_amt 
		where 1=1 
			and yyyymm = @YYYYMM
			and site = @SITE
			and sel_code = @SEL_CODE;
		
		UPDATE ori set 경비기초  = div.경비기초,
					   재료비기초 = div.재료비기초
		from doi_boh_amt ori
		 inner join  #bohAmt div on(ori.model_type=div.model_type)
		where 1=1 
			and ori.yyyymm = @YYYYMM
			and ori.site = @SITE
			and ori.sel_code = @SEL_CODE;     
        
      SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재공기초금액(DOI_BOH_AMT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 금액비율로 경비/재료비로 설정했습니다';
 
--기초금액 배부 확인 SQL
with boh as (select 구분,model,sum(PRE_EOH_AMT) boh_amt,기초수량 from doi_boh_amt where yyyymm=@YYYYMM group by 구분,model,기초수량)
, cost as(	select 구분,model,sum(boh+adj_boh) boh_cost from doi_cost where yyyymm=@YYYYMM and sel_code=@SEL_CODE 
	group by 구분,model having sum(boh+adj_boh) != 0)
 select * from boh a full join cost b on(a.model=b.model AND A.구분=B.구분) order by 1;*/
     
      DELETE FROM DOI_EXPEN_MATL
      WHERE 1=1
 		and yyyymm = @YYYYMM
        and site  = @SITE
		and sel_code = @SEL_CODE;
      
      SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';
 
	WITH MODEL_MAST_NORM AS (
	    SELECT
	        YYYYMM,
	        SITE,
            MODEL,
            LEFT(MODEL, LEN(MODEL)-1) AS 도우모델,
	        XY,
            CASE 
                WHEN RIGHT(REPLACE(MODEL, '-', ''), 1) = 'P'
                THEN N'양산'
                ELSE N'개발'
            END AS 구분,
            ROW_NUMBER() OVER (
                PARTITION BY YYYYMM, SITE, LEFT(MODEL, LEN(MODEL)-1),
                             CASE 
                                WHEN RIGHT(REPLACE(MODEL, '-', ''), 1) = 'P'
                                THEN N'양산'
                                ELSE N'개발'
                             END
                ORDER BY
                    CASE
                        WHEN MODEL = LEFT(MODEL, LEN(MODEL)-1) THEN 1
                        WHEN MODEL = LEFT(MODEL, LEN(MODEL)-1) + 'P' THEN 2
                        WHEN MODEL = LEFT(MODEL, LEN(MODEL)-1) + 'C' THEN 3
                        WHEN MODEL NOT LIKE '%-%'
                         AND MODEL NOT LIKE '%TT%'
                         AND LEN(MODEL) = 5 THEN 4
                        ELSE 9
                    END,
                    MODEL
            ) AS rn
	    FROM DOI_MODEL_MAST
	    WHERE YYYYMM = @YYYYMM
	      AND SITE = @SITE
	),
	MODEL_SUBUL AS ( 
	    -- [1] 모델별 배부 기준(물량/면적) 계산
	    SELECT
	        a.YYYYMM,
	        a.site AS site,
	        a.구분,
	        a.도우모델 AS MODEL,
	        b.xy AS 면적,
	        SUM((IN_MONTH + OUT_MONTH + LOSS_MONTH))/ 2.0 AS adj_qty, -- 정수 나눗셈 방지
	        SUM((IN_MONTH + OUT_MONTH + LOSS_MONTH))/ 2.0 * b.xy AS dist_in,
	        SUM(a.boh_month) AS boh_qty,
	        SUM(a.in_month)  AS in_qty,
	        SUM(a.eoh_month) AS eoh_qty,
	        SUM(a.out_month) AS out_qty,
	        SUM(a.loss_month) AS loss_qty,
	--        SUM(a.outetc_month) as outetc_qty,
	        0 AS bad_qty,
	        0 AS Transfer_qty,
	        a.Adj_YN
	    FROM V_DOI_PROD_SUBUL A
	    LEFT JOIN MODEL_MAST_NORM B ON (B.도우모델 = A.도우모델 AND a.yyyymm = b.YYYYMM AND a.site = b.SITE  AND B.구분 = A.구분  AND B.rn = 1)
	    WHERE 1=1 
	      AND a.yyyymm  = @YYYYMM
	      AND a.site = @SITE
	    GROUP BY a.YYYYMM, a.site, a.도우모델, a.구분, b.xy, a.Adj_YN
	),
	MODEL_RATE AS ( 
	    -- [2] 배부 비율(dist_rate) 계산
	    SELECT
	        YYYYMM,
	        SITE,
			MODEL,
	        구분,
	        면적,
	        dist_in,
	        -- 비율 합계가 정확히 1이 되도록 계산
	        CAST(CAST(dist_in AS NUMERIC(38,25)) / NULLIF(SUM(dist_in) OVER (), 0) AS NUMERIC(38,25)) AS dist_rate,
	        adj_qty,
	        boh_qty,
	        in_qty,
	        eoh_qty,
	        out_qty,
	        loss_qty,
	        bad_qty,
	        Transfer_qty,
	        Adj_yn
	--        outetc_qty
	    FROM MODEL_SUBUL
	), vina_cst_expen as (
		select *,   
		    Base_IN + CASE WHEN RN = 1 THEN round(sum(Target_Total) over() - sum(Base_IN) over(),2) ELSE 0  END AS ACCT_AMT_ADJ
		FROM (
	        SELECT
	            a.*,
	            a.ACCT_AMT * c.UTG AS Target_Total,
	            ROUND(a.ACCT_AMT * c.UTG, 2) AS Base_IN,
	            ROW_NUMBER() OVER (ORDER BY a.ACCT_AMT * c.UTG DESC) AS RN
	        FROM doi_acct_expen a
	        LEFT JOIN doi_cst_rate c ON (a.yyyymm = c.yyyymm AND a.site = c.site)
	        WHERE 1=1 
	          AND a.yyyymm = @YYYYMM
	          AND a.site = @SITE
	          AND a.sel_code = @SEL_CODE
	          AND a.dept IN ('400','448') -- 카세트팀 
	    ) A
	),
	sum_expen AS ( 
	    -- [3] 배부 대상 비용 집계 (Source Data)
	    SELECT
	        a.YYYYMM,
	a.SEL_CODE,
	        a.SITE,
	        b.EXPEN_SEL,
	        b.EXPEN_SEL명,
	        a.ACCT_NAME,
	        CASE WHEN a.dept IN ('400','448') THEN 'CST' ELSE 'UTG' END AS SUB_NAME,
	        a.DISP_SEQ,
	        -- 총 배부 대상 금액
	  SUM(ACCT_AMT/* * CASE WHEN a.dept IN ('400','448') THEN c.utg ELSE 1 END*/) AS total 
	    FROM (SELECT YYYYMM,SEL_CODE,SITE,ACCT_CLASS,DEPT,ACCT,ACCT_NAME,ITEM_NAME,ACCT_AMT,EXPEN_SEL,EXPEN_SEL명,disp_seq
	    		FROM doi_acct_expen a
			    WHERE 1=1 
			      AND a.yyyymm = @YYYYMM
			  	  AND a.site = @SITE
			  	  AND a.sel_code = @SEL_CODE
				  AND (
				       a.acct LIKE '62%' AND a.acct NOT LIKE '621%'
				  )
				  AND ISNULL(a.expen_sel, '') <> ''
			      AND ISNULL(a.dept,'') NOT IN ('400','448')
			   UNION ALL 
			   SELECT YYYYMM,SEL_CODE,SITE,ACCT_CLASS,DEPT,ACCT,ACCT_NAME,ITEM_NAME,ACCT_AMT_ADJ ACCT_AMT,EXPEN_SEL,EXPEN_SEL명,disp_seq
			 FROM vina_cst_expen
	    	) a
	    LEFT JOIN doi_acct b ON (a.acct = b.acct AND a.yyyymm = b.yyyymm AND a.site = b.site)
	    LEFT JOIN doi_cst_rate c ON (a.yyyymm = c.yyyymm AND a.site = c.site)
	    GROUP BY
	  a.YYYYMM,
	  a.SEL_CODE,
	        a.SITE,
	        b.EXPEN_SEL,
	        b.EXPEN_SEL명,
	        a.ACCT_NAME,
	        CASE WHEN a.dept IN ('400','448') THEN 'CST' ELSE 'UTG' END,
	        a.DISP_SEQ
	)
--INSERT INTO DOI_EXPEN_MATL (
--    YYYYMM, SEL_CODE, SITE, 구분, model, 면적, dist_in, dist_rate, SUB_NAME, EXPEN_SEL, EXPEN_SEL명,ACCT_NAME,
--    adj_qty, boh_qty, in_qty, eoh_qty, out_qty, loss_qty, bad_qty, transfer_qty,
--    unit_cost, boh, [in], disp_seq,adj_yn,IN_Ori,UnitCost_YN
--)
	SELECT
	    YYYYMM,
	    SEL_CODE,
	    SITE,
	    구분,
	    model,
	    면적,
	    dist_in,
	    dist_rate,
	    SUB_NAME,
	    EXPEN_SEL,
	    EXPEN_SEL명,
	    ACCT_NAME,
	    adj_qty,
	    boh_qty,
	    in_qty,
	    eoh_qty,
	    out_qty,
	    loss_qty,
	    bad_qty,
	    transfer_qty,
	    -- [최종 단가] 보정된 BOH와 IN 금액을 합산하여 단가 재계산 (데이터 정합성 유지)
	    --2026.01.12 수정
	    /*COALESCE(
	        (Final_BOH + Final_IN) 
	        / NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 
	        0
	    ) AS unit_cost,*/
	    BOH_AMT AS boh,
	--    Ori_IN/adj_qty as unit_cost,
	--    ROUND((cast(Ori_IN as float)/adj_qty)*boh_qty,2) as boh,
	    Final_IN,
	    disp_seq,Adj_YN,--outetc_qty,
	    row_number() over (partition by YYYYMM ,SEL_CODE ,SITE ,구분 ,model ,SUB_NAME ,EXPEN_SEL ,ACCT_NAME order by SUB_NAME, ADJ_YN DESC) as UnitCost_YN 
	    INTO #EXPEN_AMT  --DROP TABLE #EXPEN_AMT
	FROM (
	    SELECT
	        T.*,
	        -- [4-3] 최종 보정: 1차 배부액 + (1등에게 잔액 몰아주기)
	        -- IN 금액 보정
	        Base_IN + CASE WHEN RN = 1 THEN (Original_Total - Sum_Base_IN) ELSE 0 END AS Final_IN
	        -- BOH 금액 보정
	        --Base_BOH + CASE WHEN RN = 1 THEN (Original_BOH_Total - Sum_Base_BOH) ELSE 0 END AS Final_BOH
	    FROM (
	        SELECT 
	          A.*,
	            -- [4-2] 그룹별(비용항목별) 배부 합계 계산
	            SUM(Base_IN) OVER (PARTITION BY YYYYMM, SITE, EXPEN_SEL, SUB_NAME, a.ACCT_NAME, DISP_SEQ) AS Sum_Base_IN,
	            --SUM(Base_BOH) OVER (PARTITION BY YYYYMM, SITE, EXPEN_SEL, SUB_NAME, a.ACCT_NAME, DISP_SEQ) AS Sum_Base_BOH,
	            
	            -- [4-2] 보정 대상 순위 (배부율 높은 순)
	            ROW_NUMBER() OVER (PARTITION BY YYYYMM, SITE, EXPEN_SEL, SUB_NAME, a.ACCT_NAME, DISP_SEQ ORDER BY dist_rate DESC, model) AS RN
	        FROM (
	            -- [4-1] 1차 배부 계산 (Base Amount)
	            SELECT
	                a.YYYYMM,
	                @SEL_CODE AS SEL_CODE,
	                a.SITE,
	                b.구분,
	                b.model,
	                b.면적,
	                b.dist_in,
	                b.dist_rate,
	                a.SUB_NAME,
	                a.EXPEN_SEL,
	                a.EXPEN_SEL명,
	                a.ACCT_NAME,
	                b.adj_qty, b.boh_qty, b.in_qty, b.eoh_qty, b.out_qty, b.loss_qty, b.bad_qty, b.transfer_qty,b.Adj_YN,--b.outetc_qty,
	                a.disp_seq,
	                
	                -- 원본 총 금액 (Target)
	                a.total AS Original_Total,
	                --ROUND(a.total / 2.0, 2) AS Original_BOH_Total, -- BOH는 Total의 절반(반올림)이 목표라고 가정
	                coalesce(c.경비기초,0) AS BOH_AMT,
	
	                -- 1차 배부 (IN) : 소수점 2자리
	                ROUND(a.total * b.dist_rate, 2) AS Base_IN,
	                a.total * b.dist_rate as Ori_IN,
	   
	-- 1차 배부 (BOH) : 정수 반올림
	             ROUND(a.total * b.dist_rate / 2.0, 2) AS Base_BOH
	
	            FROM sum_expen a
	            INNER JOIN MODEL_RATE b ON (1=1) --b.dist_rate > 0.0 -- Cross Join 성격 (비율 있는 모델에 배부)
	            LEFT JOIN DOI_BOH_AMT c ON (b.yyyymm=c.yyyymm and b.site=c.site and b.model=c.model and b.구분=c.구분)
	        ) A
	    ) T
	) Final
	ORDER BY disp_seq, model;
	
	--전월 기말금액을 당월 기초금액으로  Expen_sel,acct_name별로 배부
	WITH EXPEN_ACCT_RATE AS (
		SELECT
			EXPEN_SEL,
			ACCT_NAME,
			SUB_NAME,
			SUM([Final_IN]) IN_AMT ,
			CAST(SUM([Final_IN]) as FLOAT)/ SUM(SUM([Final_IN])) OVER() ACCT_RATE
		FROM	#EXPEN_AMT
		GROUP BY
			EXPEN_SEL,
			ACCT_NAME,
			SUB_NAME
	)
	INSERT INTO DOI_EXPEN_MATL (
	YYYYMM,sel_code,SITE,구분,model,면적,dist_rate,dist_in,SUB_NAME,ACCT_NAME,EXPEN_SEL,EXPEN_SEL명,adj_qty,
	boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,transfer_qty,unit_cost,boh,[in],
	disp_seq,in_ori,ADJ_YN,UnitCost_YN--,outetc_qty
	)
	SELECT YYYYMM,sel_code,SITE,구분,model,면적,dist_rate,dist_in,SUB_NAME,ACCT_NAME,EXPEN_SEL,EXPEN_SEL명,adj_qty,
			boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,transfer_qty,unit_cost,Final_BOH as boh,Final_IN as [in],
			disp_seq,0 in_ori,ADJ_YN,UnitCost_YN--,outetc_qty
	FROM (		
		SELECT t.*,
			COALESCE((Final_BOH + Final_IN)/ 
					 NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0),0) AS unit_cost
		FROM (    
			SELECT A.*,
				  Base_BOH + CASE WHEN RN = 1 THEN BOH - Sum_Base_Boh ELSE 0 END Final_BOH
			 FROm (
				SELECT
					A.*,
					BOH * ACCT_RATE AS Ori_BOH,
					ROUND(BOH * ACCT_RATE, 2) AS Base_Boh,
					SUM(ROUND(BOH * ACCT_RATE, 2)) OVER (PARTITION BY 구분, model) as Sum_Base_Boh,
					BOH BH,
					ROW_NUMBER() OVER (PARTITION BY 구분,	model order by	BOH * ACCT_RATE DESC) rn
				FROM
					#EXPEN_AMT A
				INNER JOIN EXPEN_ACCT_RATE B ON
					(a.expen_sel = b.expen_sel and a.acct_name = b.acct_name and a.sub_name = b.sub_name)
			)A
		)T
	)Final;
	
	SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
							+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + 'UTG 부서별 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계했습니다';
	 --VINA 카세트 양산 배부 (카세트팀 금액중 VINA 카세트를 비바 카세트 수출비중으로 배부함)
	WITH VINA_CST_EXPEn as (
		select *,   
		    Base_IN + CASE WHEN RN = 1 THEN round(sum(Target_Total) over() - sum(Base_IN) over(),2) ELSE 0  END AS ACCT_AMT_ADJ
		FROM (
		    SELECT 
		        A.*,
		        ROW_NUMBER() OVER (ORDER BY Target_Total DESC) AS RN
		    FROM (
		        SELECT
		            a.*,
		            a.ACCT_AMT * c.VINA_CST AS Target_Total,
		            ROUND(a.ACCT_AMT * c.VINA_CST, 2) AS Base_IN
		        FROM doi_acct_expen a
		        LEFT JOIN doi_cst_rate c ON (a.yyyymm = c.yyyymm AND a.site = c.site)
		        WHERE 1=1 
		          AND a.yyyymm = @YYYYMM
		          AND a.site = @SITE
		          AND a.sel_code = @SEL_CODE
		          AND a.dept IN ('400','448') -- 카세트팀 
		    		) A
		)v 
	)
	INSERT INTO doi_expen_matl (
	    YYYYMM, sel_code, SITE, 구분, model, 면적, dist_rate, SUB_NAME, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME, [in], in_ori
	)
	SELECT 
	    @YYYYMM,
	    SEL_CODE,
	    @SITE,
	    '양산' AS 구분,
	    CST_NO AS model,
	    utg AS 면적, -- 면적 컬럼에 utg 매핑 (원 쿼리 참조)
	    VINA_CST AS dist_rate, -- dist_rate 컬럼에 VINA_CST 매핑
	    'VINA CST' AS SUB_NAME,
	    --'카세트팀배부' AS ITEM_NAME,
	    EXPEN_SEL, 
	    EXPEN_SEL명,
	    ACCT_NAME,
	    -- [최종 보정]
	    Base_IN + CASE WHEN RN = 1 THEN ROUND((Target_Total - Grp_Sum_IN),2) ELSE 0  END AS [IN],
	    Target_Total as in_ori
	FROM (
	    SELECT 
	        A.*,
	        -- [3] 그룹별 배부액 합계
	       SUM(Base_IN) OVER (PARTITION BY SEL_CODE, EXPEN_SEL, ACCT_NAME) AS Grp_Sum_IN,
	        
	        -- [3] 보정 순위 (금액 큰 순서)
	        ROW_NUMBER() OVER (PARTITION BY SEL_CODE, EXPEN_SEL, ACCT_NAME ORDER BY Base_IN DESC, CST_NO) AS RN
	    FROM (
	        -- [1] 기초 데이터 집계 및 목표 금액 산출
	        -- 주의: 원본 쿼리는 sum(ACCT_AMT * VINA_CST * rate) 구조임.
	        -- 단수차 보정을 위해 "총액 * 비율" 구조인지, "개별 계산 합"인지 명확해야 함.
	        -- 여기서는 개별 행 단위 계산 후 합계 보정 방식을 적용.
	        SELECT
	            a.SEL_CODE,
	            D.CST_NO,
	            C.utg,
	            C.VINA_CST,
	            B.EXPEN_SEL,
	            B.EXPEN_SEL명,
	            A.ACCT_NAME,
	            -- 목표 총액 (그룹 전체의 합) : 이 부분은 로직에 따라 유동적일 수 있으나, 
	            -- 아래 Base_IN의 합계가 원본 계산 의도와 맞아야 함.
	            -- 여기서는 'rate'가 배부 비율이라고 가정하고, 전체 그룹의 Target을 구하기 위해 Window Function 사용
	            SUM(SUM(a.ACCT_AMT_ADJ * d.rate)) OVER (PARTITION BY a.SEL_CODE, a.ACCT_NAME,B.EXPEN_SEL) AS Target_Total,
	
	            -- 1차 계산 금액 (반올림 없음 or 소수점 처리)
	            -- 원 쿼리가 [IN] 컬럼 타입에 맞게 들어가야 하므로 여기서는 일단 계산
	    SUM(a.ACCT_AMT_ADJ * d.rate) AS Base_IN_Raw,
	            
	            -- 실제 Insert될 값 (반올림 처리 가정, 필요시 소수점 조정)
	            ROUND(SUM(a.ACCT_AMT_ADJ * d.rate), 2) AS Base_IN
	
	        FROM VINA_CST_EXPEn a
	        LEFT JOIN doi_acct b ON (a.acct = b.acct AND a.yyyymm = b.yyyymm AND a.site = b.site)
		    LEFT JOIN doi_cst_rate c ON (a.yyyymm = c.yyyymm AND a.site = c.site)
	        LEFT JOIN doi_vncst_rate d ON (a.yyyymm = d.yyyymm AND a.site = d.site)
	        WHERE 1=1
	          AND c.vina_cst != 0
	          AND a.yyyymm = @YYYYMM
	          AND a.site = @SITE
	          AND a.dept IN ('400','448') -- 카세트팀 
	        GROUP BY  
	            a.SEL_CODE, D.CST_NO, C.utg, C.VINA_CST, B.EXPEN_SEL, B.EXPEN_SEL명,A.ACCT_NAME
	    ) A
	) Final;
	
	SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + 'CST 부서별 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계했습니다';
	
	--전월 EOH금액, 수량을 가져옴 (2026.03.28 By KYH, 03.31수정)
		DECLARE @PREV_MONTH VARCHAR(6);
		SELECT @PREV_MONTH=FORMAT(DATEADD(MONTH, -1, @YYYYMM  + '01'), 'yyyyMM');
		IF NOT EXISTS (SELECT 1 FROM DOI_BOH_AMT WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE AND ISNULL(경비기초,0)<>0)
		BEGIN
		UPDATE doi_expen_matl set boh=0 where yyyymm=@YYYYMM;  --BOH금액,수량 초기화 
		WITH 당월_QTY AS(
		    SELECT
				구분,
				MODEL,
				MAX(ADJ_QTY) AS ADJ_QTY,
				MAX(BOH_QTY) AS BOH_QTY,
				MAX(IN_QTY)  AS IN_QTY,
				MAX(EOH_QTY) AS EOH_QTY,
				MAX(OUT_QTY) AS OUT_QTY,
				MAX(LOSS_QTY) AS LOSS_QTY,
				MAX(BAD_QTY)  AS BAD_QTY,
				MAX(TRANSFER_QTY) AS TRANSFER_QTY --select *
			FROM
				DOI_EXPEN_MATL
			WHERE 1=1
			  AND YYYYMM   = @YYYYMM
			  AND SITE     = @SITE
			  AND SEL_CODE = @SEL_CODE
			GROUP BY 구분, MODEL
		), 전월_EOH AS(
			SELECT
				A.YYYYMM,
				A.SEL_CODE,
				A.SITE,
				A.구분,
				A.MODEL,
				A.expen_sel명,
				A.ACCT_NAME,
				A.ITEM_NAME,
				A.EXPEN_SEL,
				A.EOH_QTY, --전월 기말수량을 당월 기초수량으로
				B.IN_QTY,
				B.EOH_QTY AS C_EOH_QTY, --당월 기말수량
				B.OUT_QTY,
				B.LOSS_QTY,
				B.BAD_QTY,
				B.TRANSFER_QTY,
				B.ADJ_QTY,
				A.UNIT_COST,
				A.EOH  --전월 기말금액을 당월 기초금액으로
			FROM DOI_COST A
			LEFT JOIN 당월_QTY B ON (A.MODEL=B.MODEL AND A.구분=B.구분)
			WHERE 1 = 1
				AND a.yyyymm = @PREV_MONTH
				--and a.model='0271'
				AND (a.eoh <> 0)
				AND a.expen_sel NOT IN ('MDAX', 'MIAX')
		)
		MERGE  DOI_EXPEN_MATL AS t
		USING 전월_EOH AS s
		    ON  t.YYYYMM = @YYYYMM
		    AND t.SITE	 = s.SITE
		    AND t.구분	 = s.구분
		    AND t.MODEL  = s.MODEL
		    AND t.EXPEN_SEL = s.EXPEN_SEL
		    AND t.ACCT_NAME = s.ACCT_NAME
		    AND t.SUB_NAME = s.ITEM_NAME
		WHEN MATCHED 
		    THEN UPDATE SET 
		        t.BOH_QTY = s.EOH_QTY,
		        t.BOH 	  = s.EOH
		WHEN NOT MATCHED BY TARGET 
		    THEN INSERT (YYYYMM ,SITE ,SEL_CODE ,구분 ,MODEL ,expen_sel ,expen_sel명,acct_name,sub_name
		      ,adj_qty,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,transfer_qty,boh,ADJ_YN)
		        VALUES (@YYYYMM ,s.SITE ,s.SEL_CODE ,s.구분 ,s.MODEL ,s.expen_sel ,s.expen_sel명,s.acct_name,s.item_name
				,s.adj_qty,s.eoh_qty,s.in_qty,s.c_eoh_qty,s.out_qty,s.loss_qty,s.bad_qty,s.transfer_qty,s.EOH,'Y');
		END 
    
	SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 ' + CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END 
       +@PREV_MONTH + '월 EOH금액, 수량을 ' +@YYYYMM + '월 BOH 금액,수량으로 '+CAST(@@ROWCOUNT AS VARCHAR) +'건 가져 왔습니다';

	-- [중복해소] 한 도우모델에 품번변형 다수(예 716T=716T1~716TM)면 boh 분배가 같은 키에 중복행 생성 → DOI_COST PK 위반. 대표행에 boh/in 합산 후 나머지 삭제(총액 보존).
	;WITH _dd AS (
	    SELECT boh, [in],
	        ROW_NUMBER() OVER (PARTITION BY 구분,model,expen_sel,acct_name,sub_name ORDER BY %%physloc%%) AS _rn,
	        SUM(boh)  OVER (PARTITION BY 구분,model,expen_sel,acct_name,sub_name) AS _sboh,
	        SUM([in]) OVER (PARTITION BY 구분,model,expen_sel,acct_name,sub_name) AS _sin
	    FROM DOI_EXPEN_MATL
	    WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
	)
	UPDATE _dd SET boh = CASE WHEN _rn=1 THEN _sboh ELSE 0 END, [in] = CASE WHEN _rn=1 THEN _sin ELSE 0 END;
	;WITH _dd2 AS (
	    SELECT ROW_NUMBER() OVER (PARTITION BY 구분,model,expen_sel,acct_name,sub_name ORDER BY %%physloc%%) AS _rn
	    FROM DOI_EXPEN_MATL
	    WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
	)
	DELETE FROM _dd2 WHERE _rn > 1;

	UPDATE DOI_EXPEN_MATL SET unit_cost = COALESCE((BOH + [IN])/
				 NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0),0)
     WHERE 1=1
       AND YYYYMM	= @YYYYMM
       AND SITE 	= @SITE
       AND SEL_CODE = @SEL_CODE;
    SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 ' + CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END 
      	 +@YYYYMM + '월 단가(unit_cost) '+CAST(@@ROWCOUNT AS VARCHAR) +'건 업데이트 헸습니다'; 
	--전월 EOH금액 복사 END
	
      --카세팀 입력
      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
      DECLARE   @SOURCE_AMT      NUMERIC(15,2) = 0,
			    @TARGET_AMT      NUMERIC(15,2) = 0,
			    @DIFF_AMT        NUMERIC(15,2) = 0,
			    @FILTERED_AMT    NUMERIC(15,2) = 0,
			    @CASSETTE_AMT    NUMERIC(15,2) = 0;
      
      -- 필터링된 금액 계산
      SELECT @FILTERED_AMT = ISNULL(SUM(ACCT_AMT), 0)
      FROM DOI_ACCT_EXPEN
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE
        AND ACCT LIKE '62%' AND ACCT NOT LIKE '621%' -- AND ACCT NOT LIKE '51%' /*AND DEPT NOT IN ('448','400')*/;
      
      SELECT @CASSETTE_AMT = ISNULL(SUM((A.ACCT_AMT * B.VINA_CST * D.RATE)), 0)
      FROM DOI_ACCT_EXPEN  A 
      LEFT JOIN DOI_CST_RATE B ON (A.YYYYMM=B.YYYYMM AND A.SITE=B.SITE)
      LEFT JOIN DOI_VNCST_RATE D ON (A.YYYYMM=D.YYYYMM AND A.SITE=D.SITE)
      WHERE a.yyyymm = @YYYYMM AND A.site = @SITE AND A.sel_code = @SEL_CODE AND  DEPT IN ('448','400');
      
      SELECT @TARGET_AMT = ISNULL(SUM([IN]), 0)
      FROM DOI_EXPEN_MATL
      WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE;
   
      SET @SOURCE_AMT = @FILTERED_AMT/* + @CASSETTE_AMT*/;
      SET @DIFF_AMT = @SOURCE_AMT - @TARGET_AMT;
      
      -- ========================================
      -- 1. 소스 vs 타겟 금액 검증
      -- ========================================
      SET  @Message = @Message + char(10) + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + '1. 소스 데이터와 타겟 데이터 금액 검증';
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '구분' + REPLICATE(' ', 30) + '건수' + REPLICATE(' ', 20) + '금액';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      
     -- 소스 상세
      DECLARE @SOURCE_CNT INT = 0;
      SELECT @SOURCE_CNT = COUNT(*) FROM DOI_ACCT_EXPEN 
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE AND ACCT LIKE '62%' AND ACCT NOT LIKE '621%' AND ISNULL(EXPEN_SEL, '') <> '';
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '소스(DOI_ACCT_EXPEN)' + REPLICATE(' ', 10) + RIGHT(REPLICATE(' ', 10) + CAST(@SOURCE_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@SOURCE_AMT, 'N2'), 20) + '달러';
      
      -- 타겟 상세
      DECLARE @TARGET_CNT INT = 0;
      SELECT @TARGET_CNT = COUNT(*) FROM DOI_EXPEN_MATL WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE;
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '타겟(DOI_EXPEN_MATL)' + REPLICATE(' ', 10) + RIGHT(REPLICATE(' ', 10) + CAST(@TARGET_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@TARGET_AMT, 'N2'), 20) + '달러';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '차이' + REPLICATE(' ', 40) + RIGHT(REPLICATE(' ', 20) + FORMAT(@DIFF_AMT, 'N2'), 20) + '달러';
      SET  @Message =  @Message + char(10) + '====================================================================================================';
 
      -- ========================================
      -- 2. 차이금액 상세 (항목별)
      -- ========================================
      -- [알림] 전체 차이가 9원 초과일 때만 상세 내역을 찍도록 설정되어 있습니다.
      -- 무조건 확인하려면 IF/BEGIN/END를 모두 주석 처리해야 합니다.
  
       /*IF ABS(@DIFF_AMT) > 0   -- [주석처리]
BEGIN*/                   -- [주석처리] 짝을 맞추기 위해 BEGIN도 주석 처리
      
          SET  @Message =  @Message + char(10) + char(10) + '====================================================================================================';
          SET  @Message =  @Message + char(10) + '2. 차이금액 상세 (항목별)';
          SET  @Message =  @Message + char(10) + '====================================================================================================';
          
          DECLARE @EXPEN_SEL NVARCHAR(50), @EXPEN_NAME NVARCHAR(100);
          DECLARE     @SOURCE_ITEM_AMT NUMERIC(15,2), @TARGET_ITEM_AMT NUMERIC(15,2), @ITEM_DIFF NUMERIC(15,2);
          
          SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + '항목코드' + REPLICATE(' ', 7) + '항목명' + REPLICATE(' ', 30) + '소스금액' + REPLICATE(' ', 10) + '배부금액' + REPLICATE(' ', 14) + '차이';
          SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
          
          -- 커서 정의: 타겟(DOI_EXPEN_MATL)에 존재하는 항목을 기준으로 순회
          DECLARE item_cursor CURSOR FOR
          SELECT DISTINCT EXPEN_SEL, EXPEN_SEL명
          FROM DOI_EXPEN_MATL
          WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE
          ORDER BY EXPEN_SEL;
          
          OPEN item_cursor;
          FETCH NEXT FROM item_cursor INTO @EXPEN_SEL, @EXPEN_NAME;
          
          WHILE @@FETCH_STATUS = 0
          BEGIN
              -- --------------------------------------------------------------------------
              -- [소스 금액 계산 수정]
              -- 1. 정확한 계산을 위해 CAST(AS BIGINT) 대신 FLOAT 연산 사용
              -- 2. INSERT 로직과 동일하게 (일반배부 + VINA배부) 합산 로직 적용
              -- 3. 합산 후 ROUND 처리하여 단수차 제거
              -- --------------------------------------------------------------------------
              SELECT @SOURCE_ITEM_AMT = ISNULL( SUM(ACCT_AMT),0)
                 /* ROUND(
                      SUM(
                          -- A. 일반 및 UTG 배부 계산
   (CAST(A.ACCT_AMT AS FLOAT) * CASE 
                               WHEN A.dept IN ('400','448') THEN ISNULL(B.utg, 1) 
                               ELSE 1 
         END)
         +
    -- B. VINA 배부 계산 (카세트팀인 경우에만 추가)
                          (CASE 
                               WHEN A.dept IN ('400','448') THEN 
                                    CAST(A.ACCT_AMT AS FLOAT) * ISNULL(B.VINA_CST, 0) * ISNULL(D.rate, 0)
                               ELSE 0 
                           END)
                      )
                  , 0), 0)*/ -- 최종 합계 반올림하여 정수화
              FROM DOI_ACCT_EXPEN A 
              LEFT JOIN DOI_CST_RATE B ON (A.YYYYMM = B.YYYYMM AND A.SITE = B.SITE)
              LEFT JOIN DOI_VNCST_RATE D ON (A.YYYYMM = D.YYYYMM AND A.SITE = D.SITE)
              WHERE A.YYYYMM = @YYYYMM 
                AND A.SITE = @SITE 
                AND A.SEL_CODE = @SEL_CODE
                AND A.EXPEN_SEL = @EXPEN_SEL -- 현재 커서의 비용항목
                AND (
				       a.acct LIKE '62%' AND a.acct NOT LIKE '621%'
				)
				AND ISNULL(a.expen_sel, '') <> '';
              
              -- [타겟 금액 가져오기]
              SELECT @TARGET_ITEM_AMT = ISNULL(SUM([IN]), 0)
              FROM DOI_EXPEN_MATL
              WHERE YYYYMM = @YYYYMM 
                AND SITE = @SITE 
                AND SEL_CODE = @SEL_CODE
                AND EXPEN_SEL = @EXPEN_SEL;
              
              SET @ITEM_DIFF = @SOURCE_ITEM_AMT - @TARGET_ITEM_AMT;
              
              -- 차이가 1원보다 클 때만 로그에 기록 (1원 이하는 단수차 허용 범위로 간주 시)
              -- 모든 항목을 보고 싶다면 '> -1' 등으로 변경
              IF ABS(@ITEM_DIFF) > -1 
              BEGIN
                  SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
                      + LEFT(ISNULL(@EXPEN_SEL, '') + REPLICATE(' ', 15), 15)
                      + LEFT(ISNULL(@EXPEN_NAME, '') + REPLICATE(' ', 3-dbo.DOI_ASCII_COUNT(@EXPEN_NAME)) + REPLICATE(NCHAR(0x3000), 15), 17)
                      + RIGHT(REPLICATE(' ', 15) + FORMAT(@SOURCE_ITEM_AMT, 'N2'), 15)
                      + RIGHT(REPLICATE(' ', 17) + FORMAT(@TARGET_ITEM_AMT, 'N2'), 17)
                      + RIGHT(REPLICATE(' ', 15) + FORMAT(@ITEM_DIFF, 'N2'), 15);
              END
              
              FETCH NEXT FROM item_cursor INTO @EXPEN_SEL, @EXPEN_NAME;
          END
          
          CLOSE item_cursor;
DEALLOCATE item_cursor;
    SELECT @SOURCE_ITEM_AMT = ISNULL( SUM(ACCT_AMT),0)
              FROM DOI_ACCT_EXPEN A 
              LEFT JOIN DOI_CST_RATE B ON (A.YYYYMM = B.YYYYMM AND A.SITE = B.SITE)
            LEFT JOIN DOI_VNCST_RATE D ON (A.YYYYMM = D.YYYYMM AND A.SITE = D.SITE)
              WHERE A.YYYYMM = @YYYYMM 
                AND A.SITE = @SITE 
                AND A.SEL_CODE = @SEL_CODE
                AND (
				       a.acct LIKE '62%' AND a.acct NOT LIKE '621%'
				)
				AND ISNULL(a.expen_sel, '') <> '';
          SELECT @TARGET_ITEM_AMT = ISNULL(SUM([IN]), 0)
              FROM DOI_EXPEN_MATL
              WHERE YYYYMM = @YYYYMM 
                AND SITE = @SITE
          		AND sel_code = @SEL_CODE;
          SET @ITEM_DIFF = @SOURCE_ITEM_AMT - @TARGET_ITEM_AMT; 
          SET  @Message =  @Message + char(10) + '====================================================================================================';
          SET  @Message =  @Message + char(10) + REPLICATE(' ', 35) + '합계' + RIGHT(REPLICATE(' ', 30) + FORMAT(@SOURCE_AMT, 'N2'), 27)+ RIGHT(REPLICATE(' ', 17) + FORMAT(@TARGET_ITEM_AMT, 'N2'), 17) + RIGHT(REPLICATE(' ', 15) + FORMAT(@ITEM_DIFF, 'N2'), 15);
          
       --END -- [주석처리] 위의 BEGIN과 짝이 맞는 END도 주석 처리
      
      -- ========================================
      -- 최종 상태 및 트랜잭션 처리
      -- ========================================
      -- 전체 차이가 100원 초과 시 경고 (허용 오차 범위 설정)
      IF ABS(@DIFF_AMT) > 100 
      BEGIN
     DECLARE @DIFF_PCT DECIMAL(10,4);
          -- 0으로 나누기 오류 방지
          IF @TARGET_AMT = 0 SET @DIFF_PCT = 0;
          ELSE SET @DIFF_PCT = (CAST(@DIFF_AMT AS DECIMAL(20,2)) / CAST(@TARGET_AMT AS DECIMAL(20,2))) * 100;

          SET  @Message =  @Message + char(10) + char(10) + N'⚠️  [WARN] 경비집계 데이터 불일치 발생! (차이율: ' + CAST(@DIFF_PCT AS VARCHAR(10)) + '%)';
      END
   ELSE 
      BEGIN
          SET  @Message =  @Message + char(10) + char(10) + N'✅ [CHECK] 경비집계 데이터 무결성 검증 통과';
      END

      SET  @Message =  @Message + char(10);
      
      SET  @Message =  @Message + char(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
                        + CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 집계 완료했습니다';

     -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '경비 집계', 'UP_VN_EXPEN_MATL', 'SUCCESS');
     
     --임지테이블 DROP
     DROP TABLE #EXPEN_AMT
     
      -- 정상 처리 확정
      COMMIT TRANSACTION;
      
      -- 결과 메시지 반환
      SELECT @Message as retMessage;
      RETURN 0;

   END TRY
   
   BEGIN CATCH
       -- 에러 발생 시 롤백
 IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
       
       SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9) + ERROR_MESSAGE();
       INSERT INTO doi_execlog
       	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
       	 values
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '매출상계', 'UP_VN_SCOF', 'FAIL');	
       SELECT @Message as retMessage;
       RETURN -1;
   END CATCH;
END;

GO

-- ==========================================
-- File: UP_VN_MAT_COST.sql
-- ==========================================

CREATE OR ALTER Procedure UP_VN_MAT_COST
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

  	-- 1초 대기
    WAITFOR DELAY '00:00:01';

	IF EXISTS (
	    SELECT 1
	    FROM DOI_CLOSING_MONTH
	    WHERE YYYYMM = @YYYYMM
	      AND IS_CLOSED = 'Y'
	)
	BEGIN
	    RAISERROR(N'마감된 결산월(%s)은 실행할 수 없습니다.', 16, 1, @YYYYMM);
	    RETURN;
	END          
   
	SET  @Message =  '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + '데이타 배부를 시작합니다';
	
	--데이타 체크	
	SELECT @CNT = count(*)
		FROM DOI_MODEL_MAST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 면적정보(DOI_MODEL_MAST) 테이블에 '
				+ @YYYYMM + '월 '+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_BOM_MAST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 자재BOM(DOI_BOM_MAST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
			
	SELECT @CNT = count(*)
		FROM V_DOI_PROD_SUBUL
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message =  @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 생산집계(DOI_PROD_SUBUL) 테이블에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END	
	
	SELECT @CNT = count(*)
		FROM doi_mat_amt WITH (NOLOCK)
      WHERE yyyymm	= @YYYYMM
        and site  	= @SITE
		and sel_code= @SEL_CODE  ;
	IF @CNT = 0 BEGIN
		SET @Message =  @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비집계(doi_mat_amt) 테이블에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	IF @CHECK = 1 BEGIN 
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 기본정보 테이블들에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SELECT @Message as retMessage;
		RETURN -1;
	END

	BEGIN TRANSACTION;
	--삭제
	DELETE FROM doi_mat_cost 
	WHERE yyyymm	= @YYYYMM
	  and site  	= @SITE
	  and sel_code  = @SEL_CODE;

	SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + '데이타가 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';
    
		WITH MODEL_MAST_NORM AS (
		    SELECT
		        YYYYMM,
		        SITE,
		        LEFT(MODEL, PATINDEX('%[A-Z]%', MODEL + 'A')) AS MODEL_KEY,
		        CASE 
		            WHEN SUBSTRING(
		                    REPLACE(MODEL, '-', ''),
		                    LEN(REPLACE(MODEL, '-', '')) 
		                      - PATINDEX('%[A-Z]%', REVERSE(REPLACE(MODEL, '-', ''))) + 1,
		                    1
		                 ) = 'P'
		            THEN '개발'
		            ELSE '양산'
		        END AS 구분,
		        MAX(XY) AS XY
		    FROM DOI_MODEL_MAST
		    WHERE YYYYMM = @YYYYMM
		      AND SITE = @SITE
		    GROUP BY
		        YYYYMM,
		        SITE,
		        LEFT(MODEL, PATINDEX('%[A-Z]%', MODEL + 'A')),
		        CASE 
		            WHEN SUBSTRING(
		                    REPLACE(MODEL, '-', ''),
		                    LEN(REPLACE(MODEL, '-', '')) 
		                      - PATINDEX('%[A-Z]%', REVERSE(REPLACE(MODEL, '-', ''))) + 1,
		                    1
		                 ) = 'P'
		            THEN '개발'
		            ELSE '양산'
		        END
		),		
		BOM as (
			select
				b.yyyymm as byyyymm,
				b.자재번호,
				b.제품명,
				CASE WHEN b.품목중분류='VINA CST' 	  THEN '양산'   
					 WHEN RIGHT(b.제품번호,1) = 'P' THEN '양산' ELSE '개발'
					 /*WHEN RIGHT(b.품목중분류,1) = 'P' THEN '양산'
					 WHEN RIGHT(b.품목중분류,1) = 'D' THEN '개발'
					 WHEN b.제품번호 LIKE 'H%' 		  THEN CASE WHEN SUBSTRING(b.제품번호,6,1)='D' THEN '개발' else '양산' END --HTG 제품
					 WHEN SUBSTRING(b.제품번호,5,1)='D' THEN '개발' 
					 ELSE '양산'*/ END 구분b,
				--b.제품번호,
				--b.품목대분류,
				b.자재대분류,
				cast(sum(소요량) as numeric(38,25)) as  소요량,
				count(*) cnt,
				row_number() over (partition by b.자재번호,	b.제품명,
											CASE WHEN b.품목중분류='VINA CST' 	  THEN '양산'   
					 							 WHEN RIGHT(b.제품번호,1) = 'P' THEN '양산' ELSE '개발'
												 /*WHEN RIGHT(b.품목중분류,1) = 'P' THEN '양산'
												 WHEN RIGHT(b.품목중분류,1) = 'D' THEN '개발'
												 WHEN b.제품번호 LIKE 'H%' 		  THEN CASE WHEN SUBSTRING(b.제품번호,6,1)='D' THEN '개발' else '양산' END --HTG 제품
												 WHEN SUBSTRING(b.제품번호,5,1)='D' THEN '개발' 
												 ELSE '양산'*/ END order by  b.자재대분류  desc)  as rn, 
				row_number() over (partition by b.자재번호 order by (case when b.자재번호 in('DWR00001Z2','DWR00001Z1','AMF802MN21 0.0') then b.제품명 else  b.자재대분류 end) desc)  rn1 --select *
			from	doi_bom_mast b
			where 1=1
				and yyyymm=@YYYYMM
				and site=@SITE
				and nullif(자재번호, '') IS NOT NULL
				--and 공정차수 = '00'
			group by
				b.yyyymm,b.자재번호,	b.제품명,	
				CASE WHEN b.품목중분류='VINA CST' 	  THEN '양산'   
					 WHEN RIGHT(b.제품번호,1) = 'P' THEN '양산' ELSE '개발'
					 /*WHEN RIGHT(b.품목중분류,1) = 'P' THEN '양산'
					 WHEN RIGHT(b.품목중분류,1) = 'D' THEN '개발'
					 WHEN b.제품번호 LIKE 'H%' 		  THEN CASE WHEN SUBSTRING(b.제품번호,6,1)='D' THEN '개발' else '양산' END --HTG 제품
					 WHEN SUBSTRING(b.제품번호,5,1)='D' THEN '개발' 
					 ELSE '양산'*/ END, b.자재대분류
		), CHGQTY AS( --생산 환산량
		select
			a.yyyymm,
			a.sel_code,
			a.site,
			a.도우모델,
			a.구분,
			sum(a.BOH_MONTH) boh_qty,
			sum(a.IN_MONTH) in_qty,
			sum(a.EOH_MONTH) eoh_qty,
			sum(a.OUT_MONTH) out_qty,
			sum(a.LOSS_MONTH) loss_qty,
	        0 AS bad_qty,
	        0 AS Transfer_qty,
--			sum(a.OUTETC_MONTH) outetc_qty,
			sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH)/ 2.0 as 환산량,
			A.Adj_YN --SELECT *
		from
			V_DOI_PROD_SUBUL a
		where	1=1
			and a.yyyymm = @YYYYMM
			and a.site = @SITE
		group by a.yyyymm,a.sel_code,a.site,a.도우모델,a.구분,a.Adj_YN
		--having sum(a.IN_MONTH+a.OUT_MONTH+a.LOSS_MONTH) > 0
		), MAT_DISTRATE AS(
		select	(환산량 * 소요량) as 사용량,
				sum(환산량 * 소요량) over(partition by 자재번호) as 자재사용량,
				case when 환산량=0 then 0  
					 else CAST((환산량 * 소요량) AS NUMERIC(38,18))/sum(환산량 * 소요량) over(partition by 자재번호) end  as 배부율,
				--CAST( (환산량 * 소요량) AS DECIMAL(38,15) ) / CAST( sum(환산량 * 소요량) over(partition by 자재번호) AS DECIMAL(38,15) )as 배부적수, 
			*
			from BOM a
			inner join CHGQTY b on	(a.제품명 = b.도우모델 and a.구분b=b.구분 and case when a.자재번호 in('DWR00001Z2','DWR00001Z1','AMF802MN21 0.0') then rn1 else  rn end = 1)
			--order by 자재번호
		), 
		MAT_COMM_RATE AS(
			select 
				a.*,
				case when 환산량=0 then 0  
					 else CAST((환산량 * b.xy) as NUMERIC(38,25)) / sum(환산량 * b.xy) over() end as comm_rate,
				b.xy,
				(환산량 * b.xy) as 배부적수
			from
				CHGQTY A
		  inner join MODEL_MAST_NORM B ON     --모델별 면적정보
	         (b.YYYYMM = @YYYYMM and b.site = a.SITE  AND b.구분 = a.구분 AND b.MODEL_KEY = a.도우모델)
		)
--		INSERT INTO doi_mat_cost
--		(yyyymm,sel_code,site,구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,in_amt,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,환산량,소요량,배부율,BOH_AMT,배부금액,사용량,배부방식,단가,ADJ_YN)
		SELECT
			yyyymm,
			sel_code,
			site,
			구분,
			도우모델,
			자재번호,
			mat_gubun,
			mat_class,
			자재대분류,
			in_amt,
			boh_qty,
			in_qty,
			eoh_qty,
			out_qty,
			loss_qty,
	        bad_qty,
	        Transfer_qty,
--			outetc_qty,
			환산량,
			소요량,
			배부율,
			--Final_BOH_Amt as BOH_AMT,
			Final_IN_Amt as 배부금액,
			사용량,
			배부방식,
			case when 환산량=0 then 0 else Final_IN_Amt/환산량 end as 단가,
			ADJ_YN, 
			원가자재분류
			INTO #matCost  --drop table #matCost
		FROM (
			SELECT
		        T.*,
		        -- [4-3] 최종 보정: 1차 배부액 + (1등에게 잔액 몰아주기)
		        -- IN 금액 보정
		        --Base_BOH_Amt + CASE WHEN RN = 1 THEN (ROUND(In_amt / 2.0, 0) - Sum_Base_BOH_Amt) ELSE 0 END AS Final_BOH_Amt,
		        Base_In_Amt + CASE WHEN RN = 1 THEN (IN_Amt - Sum_Base_In_Amt) ELSE 0 END AS Final_IN_Amt
		     FROM(   
				 SELECT 
		            A.*,
		            -- [4-2] 그룹별(비용항목별) 원금액 합계 계산
		            --SUM(Base_BOH_Amt) OVER (PARTITION BY YYYYMM, SITE,자재번호) AS Sum_Base_BOH_Amt,
		            SUM(Base_In_Amt) OVER (PARTITION BY YYYYMM, SITE,자재번호) AS Sum_Base_In_Amt,
		            -- [4-2] 보정 대상 순위 (배부율 높은 순)
		            ROW_NUMBER() OVER (PARTITION BY YYYYMM, SITE, 자재번호 ORDER BY 배부율 DESC, 도우모델) AS RN
		         FROM(
		            -- [4-1] 1차 배부 계산 (Base Amount)    
					select
						b.yyyymm,
						@SEL_CODE as sel_code,
						b.site site,
						b.구분,
						b.도우모델,
						b.자재번호,
						a.mat_gubun,
						a.mat_class,
						a.자재대분류,
						a.in_amt,
						b.boh_qty,
						b.in_qty,
						b.eoh_qty,
						b.out_qty,
						b.loss_qty,
				        b.bad_qty,
				        b.Transfer_qty,
--						b.outetc_qty,
						b.환산량,
						b.소요량,
						b.배부율,
			--			round(a.in_amt * b.배부율,3) as 배부금액,
			--			ROUND(a.in_amt * b.배부율 / 2.0, 0) AS Base_BOH_Amt,
						a.in_amt * b.배부율 as Origin_IN_Amt,
						ROUND(a.in_amt * b.배부율,2) as Base_In_Amt,
						b.사용량,
						'BOM' AS 배부방식,
						b.ADJ_YN,--TRUNCATE TABLE  DOI_MAT_COST
						-- sum(a.in_amt * b.배부적수)
						a.원가자재분류
					from
						doi_mat_amt a with(nolock)
					inner join MAT_DISTRATE b on
						(a.mat_code = b.자재번호)
					where a.yyyymm		= @YYYYMM
						and a.site 		= @SITE
						and a.sel_code 	= @SEL_CODE
						and a.mat_gubun!='카세트제품'
				 )A
			)T
		) F
		union all
		SELECT
			yyyymm,
			sel_code,
			site,
			구분,
			도우모델,
			mat_code,
			mat_gubun,
			mat_class,
			자재대분류,
			in_amt,
			boh_qty,
			in_qty,
			eoh_qty,
			out_qty,
			loss_qty,
	        bad_qty,
	        Transfer_qty,
--			outetc_qty,
			환산량,
			xy,
			comm_rate,
			--Final_BOH_Amt,
			Final_Amt,
			사용량,
			배부방식,
			case when 환산량=0 then 0 else Final_Amt/환산량 end as 단가,
			ADJ_YN,
			원가자재분류
		FROM (
			SELECT
		        T.*,
		        -- [4-3] 최종 보정: 1차 배부액 + (1등에게 잔액 몰아주기)
		        -- IN 금액 보정
		        --Base_BOH_Amt + CASE WHEN RN = 1 THEN (ROUND(In_amt / 2.0, 0) - Sum_Base_BOH_Amt) ELSE 0 END AS Final_BOH_Amt,
		        Base_In_Amt + CASE WHEN RN = 1 THEN (IN_Amt - Sum_Base_In_Amt) ELSE 0 END AS Final_Amt
		     FROM(   
				 SELECT 
		            A.*,
		            -- [4-2] 그룹별(비용항목별) 원금액 합계 계산
		            --SUM(Base_BOH_Amt) OVER (PARTITION BY YYYYMM, SITE,mat_code) AS Sum_Base_BOH_Amt,
		            SUM(Base_In_Amt) OVER (PARTITION BY YYYYMM, SITE,mat_code) AS Sum_Base_In_Amt,
		            -- [4-2] 보정 대상 순위 (배부율 높은 순)
		            ROW_NUMBER() OVER (PARTITION BY YYYYMM, SITE, mat_code ORDER BY comm_rate DESC, 도우모델) AS RN
		         FROM(
		            -- [4-1] 1차 배부 계산 (Base Amount)    
				  select
					b.yyyymm,
					@SEL_CODE as sel_code,
					b.site site,
					b.구분,
					b.도우모델,
					a.mat_code,
					a.mat_gubun,
					a.mat_class,
					a.자재대분류,
					a.in_amt,
					b.boh_qty,
					b.in_qty,
					b.eoh_qty,
					b.out_qty,
					b.loss_qty,
			        b.bad_qty,
			        b.Transfer_qty,
--					b.outetc_qty,
					b.환산량,
					CAST(b.xy as NUMERIC(38,25)) as xy,
					b.comm_rate,
					--ROUND(a.in_amt * b.comm_rate / 2.0, 0) AS Base_BOH_Amt,
					a.in_amt * b.comm_rate  as Origin_IN_Amt,
					round(a.in_amt * b.comm_rate,2) as Base_In_Amt,
					b.배부적수 as 사용량,
					'공통' as 배부방식,
					b.ADJ_YN,
					-- sum(a.in_amt*b.comm_rate)
				    a.원가자재분류
				from
					doi_mat_amt a with(nolock)
				inner join MAT_COMM_RATE b on
					(1 = 1)
				where a.yyyymm 		= @YYYYMM 
					and a.site 		= @SITE
					and a.sel_code  = @SEL_CODE
					and a.mat_gubun != '카세트제품'
					--and (a.sel_code = @SEL_CODE OR @SEL_CODE IS NULL OR @SEL_CODE = '')
					and not exists (select 1 from MAT_DISTRATE c where a.mat_code = c.자재번호)
				)A
			)T
		)F;

WITH BOH as (
	select
		구분,
		MODEL, --select
		sum(재료비기초) Tot_bohAmt--,sum(경비기초) Tot_ExpenAmt
	from	doi_boh_amt
	where 1=1 
		and yyyymm = @YYYYMM
		and sel_code = @SEL_CODE
		and site = @SITE
	group by 구분,MODEL	having sum(재료비기초) != 0 --order by 2
)
INSERT INTO doi_mat_cost
(yyyymm,sel_code,site,구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,in_amt,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,
 Transfer_qty,/*outetc_qty,*/환산량,소요량,배부율,BOH_AMT ,배부금액,사용량,배부방식,단가,ADJ_YN,원가자재분류)
SELECT yyyymm,sel_code,site,구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,in_amt,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,
 Transfer_qty,/*outetc_qty,*/환산량,소요량,배부율,Final_BOH,배부금액,사용량,배부방식,
	COALESCE(CAST((Final_BOH + 배부금액)  as numeric(24,12))/ 
			 NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0),0) AS 단가, ADJ_YN, 원가자재분류
--sum(Final.Final_BOH)
From
(
	select F.*,coalesce(Base_Boh + case when rn=1 then Tot_bohAmt - Sum_base_boh else 0 end,0) as Final_BOH
	from
	(
		select T.*, sum(base_Boh) over (partition by 구분,도우모델) as Sum_base_boh 
		from
		(
			select
					a.*,
					Tot_bohAmt * rate Ori_Boh,
					round(Tot_bohAmt * rate, 2) Base_Boh,
					row_number() over (partition by 구분,도우모델 order by Tot_bohAmt * rate desc) RN
				from
				 (select a.*,b.구분 구분1,MODEL,b.Tot_bohAmt,
				 		case when 배부금액=0 then 0 else 배부금액/sum(배부금액) over(partition by a.구분,a.도우모델) end as rate
				 	from #matCost a 
					full join BOH b  on( a.도우모델=b.model and a.구분=b.구분)
				  )A  
		)T
	)F
)Final	
WHERE 배부금액+Final_BOH != 0
		
	  SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + '일반 재료비 배부 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';

		WITH CST_BOM AS (
			SELECT
				제품명,
				자재번호,
				총소요량
			from
				DOI_CST_BOM
			WHERE 1=1 
				AND 품목자산분류 NOT IN ('카세트제품', '제품')
				AND YYYYMM =  @YYYYMM
				AND SITE = @SITE
		), MAT_CST as (
			select
				품번 AS MAT_CODE,
				SUM(투입수량) AS IN_QTY,
				SUM(투입금액) AS IN_AMT,
				재고자산종류 AS MAT_CLASS
			from
				DOI_MATL_RESC
			WHERE 1 = 1 
				 and YYYYMM = @YYYYMM
            	and SITE = @SITE
				AND 품목자산분류 = '카세트제품'
			GROUP BY 품번,재고자산종류
		)
		INSERT INTO DOI_MAT_COST
		(yyyymm,sel_code,site,구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,in_amt,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,환산량,소요량,배부율,BOH_AMT,배부금액,사용량,배부방식,단가,ADJ_YN)
		SELECT
			YYYYMM ,
			SEL_CODE ,
			SITE ,
			구분 ,
			도우모델 ,
			자재번호 ,
			'카세트제품' as MAT_GUBUN,
			MAT_CLASS ,
			자재대분류 ,
			IN_Amt as in_AMT ,
			0 as BOH_QTY ,
			in_QTY ,
			0 as EOH_QTY,
			in_QTY as OUT_QTY,
			0 as LOSS_QTY,
			ADJ_QTY ,
			총소요량 ,
			배부율 ,
			Final_BOH_Amt as BOH_AMT,
			Final_IN_Amt as 배부금액,
			사용량 ,
			배부방식,Final_IN_Amt/in_QTY as 단가,
			'Y' AS ADJ_YN
		FROM
		(
			SELECT
		        T.*,
		        -- [4-3] 최종 보정: 1차 배부액 + (1등에게 잔액 몰아주기)
		        -- IN 금액 보정
		        Base_BOH_Amt + CASE WHEN RN = 1 THEN (IN_Amt/2 - Sum_Base_BOH_Amt) ELSE 0 END AS Final_BOH_Amt,
		        Base_IN_Amt + CASE WHEN RN = 1 THEN (IN_Amt - Sum_Base_IN_Amt) ELSE 0 END AS Final_IN_Amt
		     FROM(  
				SELECT 
		            A.*,
		            -- [4-2] 그룹별(비용항목별) 원금액 합계 계산
		            SUM(Base_BOH_Amt) OVER (PARTITION BY 자재번호) AS Sum_Base_BOH_Amt,
		          SUM(Base_IN_Amt) OVER (PARTITION BY 자재번호) AS Sum_Base_IN_Amt,
		            -- [4-2] 보정 대상 순위 (배부율 높은 순)
		            ROW_NUMBER() OVER (PARTITION BY 자재번호 ORDER BY 배부율 DESC, 도우모델) AS RN
		         FROM(
		            -- [4-1] 1차 배부 계산 (Base Amount)    
					SELECT
						@YYYYMM as YYYYMM,
						@SEL_CODE as SEL_CODE,
						@SITE as SITE,
						'양산' as 구분,
						b.제품명 as 도우모델,
						b.자재번호 as 자재번호,
						a.MAT_CLASS,
						'카세트' as  자재대분류,
						a.in_AMT,
						a.in_QTY,
						a.in_QTY as ADJ_QTY, --sum(총소요량) over (partition by MAT_CODE) AS TOT,
						b.총소요량,
						CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE) as 배부율,
						IN_AMT * CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE) AS  Origin_Amt,
						round(IN_AMT/2 * CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE), 2) as Base_BOH_Amt,
						round(IN_AMT * CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE), 2) as Base_IN_Amt,
						sum(총소요량) over (partition by MAT_CODE) * CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE) as 사용량,
						'CST' as 배부방식 
					FROM
						MAT_CST A
					LEFT JOIN CST_BOM B ON
						(A.MAT_CODE = B.자재번호)
			  	)a
		  	)T
	  )F;
		
 		SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + '카세트 재료비 배부 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
 
	--전월 EOH금액, 수량을 가져옴 (2026.03.28 By KYH)
 		DECLARE @PREV_MONTH VARCHAR(6);
 				
		SELECT @PREV_MONTH=FORMAT(DATEADD(MONTH, -1, @YYYYMM  + '01'), 'yyyyMM');
		IF NOT EXISTS (SELECT 1 FROM DOI_BOH_AMT WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE AND ISNULL(재료비기초,0)<>0)
		BEGIN
		UPDATE DOI_MAT_COST set boh_amt=0 where yyyymm=@YYYYMM;
		
		WITH 당월_QTY AS(
		    SELECT
				구분,
				도우모델 as MODEL,
				--MAX(ADJ_QTY) AS ADJ_QTY,
				MAX(BOH_QTY) AS BOH_QTY,
				MAX(IN_QTY)  AS IN_QTY,
				MAX(EOH_QTY) AS EOH_QTY,
				MAX(OUT_QTY) AS OUT_QTY,
				MAX(LOSS_QTY) AS LOSS_QTY,
				MAX(BAD_QTY)  AS BAD_QTY,
				MAX(TRANSFER_QTY) AS TRANSFER_QTY --select *
			FROM
				DOI_MAT_COST
			WHERE
				YYYYMM = @YYYYMM
			GROUP BY 구분, 도우모델
		), 전월_EOH AS(
		  SELECT
		  	c.자재번호,
	        c.mat_gubun,
	        c.mat_class,
	        c.자재대분류,
	        c.원가자재분류,
	        c.배부방식,
	        c.단가,
			A.YYYYMM,
			A.SEL_CODE,
			A.SITE,
			A.구분,
			A.MODEL,
			A.expen_sel명,
			A.ACCT_NAME,
			A.ITEM_NAME,
			A.EXPEN_SEL,
			A.EOH_QTY,
			b.IN_QTY,
			b.EOH_QTY AS C_EOH_QTY,
			b.OUT_QTY,
			b.LOSS_QTY,
			b.BAD_QTY,
			b.TRANSFER_QTY,
			A.EOH
		FROM	DOI_COST a
		  left join 당월_QTY B ON (A.MODEL=B.MODEL AND A.구분=B.구분)
		  left join ( SELECT DISTINCT 구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,원가자재분류,배부방식,단가 
		  				from DOI_MAT_COST 
		  				WHERE YYYYMM=@PREV_MONTH 
		  				  and SITE=@SITE and sel_code=@SEL_CODE) c on (a.구분 = c.구분 and a.model=c.도우모델 and a.ITEM_NAME=c.자재번호)
		  WHERE 1=1
		    AND a.yyyymm=@PREV_MONTH
		    AND (a.eoh <> 0)
		    AND a.expen_sel IN ('MDAX','MIAX')
		)
		MERGE  DOI_MAT_COST AS t
		USING 전월_EOH AS s
		    ON  t.YYYYMM = @YYYYMM
		    AND t.SITE	 = s.SITE
		    AND t.구분	 = s.구분
		    AND t.도우모델  = s.MODEL
		    AND t.자재번호 = s.ITEM_NAME
		WHEN MATCHED 
		    THEN UPDATE SET 
		        t.BOH_QTY = s.EOH_QTY,
		        t.BOH_AMT 	  = s.EOH
		WHEN NOT MATCHED BY TARGET 
		    THEN INSERT (YYYYMM ,SITE ,SEL_CODE ,구분 ,도우모델 ,자재번호,mat_gubun,mat_class,자재대분류,원가자재분류
		    ,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,transfer_qty,boh_amt,배부방식,adj_yn,배부금액,단가)
		      VALUES (@YYYYMM ,s.SITE ,s.SEL_CODE ,s.구분 ,s.MODEL ,s.자재번호,s.mat_gubun,s.mat_class,s.자재대분류,s.원가자재분류
			,s.EOH_QTY,COALESCE(s.in_qty,0),COALESCE(s.c_eoh_qty,s.EOH_QTY),COALESCE(s.out_qty,0),COALESCE(s.loss_qty,0),COALESCE(s.bad_qty,0),COALESCE(s.transfer_qty,0),s.EOH,COALESCE(s.배부방식, 'BOH'),'X',0,단가);
		END
		--전월 EOH금액 복사 END
		
		UPDATE DOI_MAT_COST
		SET 단가 = COALESCE((BOH_AMT + 배부금액)
		            / NULLIF((EOH_QTY / 2.0) + OUT_QTY + BAD_QTY + TRANSFER_QTY + IIF(@SEL_CODE = 'ACTLSS', LOSS_QTY, 0), 0), 0)
		WHERE 1=1 
		  AND YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE;		

		SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END
						+@PREV_MONTH + '월 EOH금액, 수량을 ' +@YYYYMM + '월 BOH 금액,수량으로 '+CAST(@@ROWCOUNT AS VARCHAR) +'건 가져 왔습니다';
			
      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
      DECLARE @SOURCE_AMT DECIMAL(18,2) = 0,
              @TARGET_AMT DECIMAL(18,2) = 0,
              @DIFF_AMT DECIMAL(18,2) = 0,
       @SOURCE_CNT INT = 0,
              @TARGET_CNT INT = 0,
 @MODEL_CNT INT = 0;
      
 -- 1. 소스 데이터 (doi_mat_amt)
      SELECT @SOURCE_AMT = ISNULL(CAST(SUM(in_amt) AS DECIMAL(18,2)), 0),
             @SOURCE_CNT = COUNT(*)
      FROM doi_mat_amt
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE;
        --AND (sel_code = @SEL_CODE OR @SEL_CODE IS NULL OR @SEL_CODE = '');
      
      -- 2. 타겟 데이터 (DOI_MAT_COST) - 자재별로 그룹핑한 배부금액 합계
      SELECT @TARGET_AMT = ISNULL(CAST(SUM(배부금액) AS DECIMAL(18,2)), 0),
             @TARGET_CNT = COUNT(DISTINCT 자재번호)
      FROM doi_mat_cost
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE;
        --AND (sel_code = @SEL_CODE OR @SEL_CODE IS NULL OR @SEL_CODE = '');
      
      -- 3. 모델 수
      SELECT @MODEL_CNT = COUNT(DISTINCT 도우모델)
      FROM doi_mat_cost
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE;
        --AND (sel_code = @SEL_CODE OR @SEL_CODE IS NULL OR @SEL_CODE = '');
      
      SET @DIFF_AMT = @SOURCE_AMT - @TARGET_AMT;
      
      SET  @Message =  @Message + char(10) + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + '데이터 무결성 검증';
 SET  @Message =  @Message + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + '구분' + REPLICATE(' ', 40) + '건수' + REPLICATE(' ', 14) + '금액';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
          + LEFT('소스(doi_mat_amt)' + REPLICATE(' ', 30), 30)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_CNT, 'N2'), 18)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_AMT, 'N2'), 18)+ '달러';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
          + LEFT('타겟(DOI_MAT_COST) - 자재별' + REPLICATE(' ', 30), 28)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_CNT, 'N2'), 18)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_AMT, 'N2'), 18)+ '달러';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
          + LEFT('차이' + REPLICATE(' ', 40), 30)
          + RIGHT(REPLICATE(' ', 18) + '', 18)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@DIFF_AMT, 'N2'), 18)+ '달러';
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + '배부된 모델 수: ' + CAST(@MODEL_CNT AS VARCHAR) + '개';
      
      -- 세부 검증 정보 (항상 표시)
      DECLARE @BOM_MISSING INT = 0, @PROD_MISSING INT = 0, @MAT_NOALLOC INT = 0;
      
      -- BOM 미등록 자재 수
      SELECT @BOM_MISSING = COUNT(DISTINCT a.mat_code)
      FROM doi_mat_amt a
      LEFT JOIN DOI_BOM_MAST b ON (a.yyyymm = b.yyyymm AND a.site = b.site AND a.mat_code = b.자재번호)
      WHERE a.yyyymm = @YYYYMM AND a.site = @SITE
        AND a.sel_code = @SEL_CODE
        AND b.자재번호 IS NULL;
      
      -- 미배부 자재 수 (소스에는 있는데 타겟에 없는 자재)
      SELECT @MAT_NOALLOC = COUNT(DISTINCT a.mat_code)
      FROM doi_mat_amt a
      LEFT JOIN doi_mat_cost b ON (a.yyyymm = b.yyyymm AND a.site = b.site AND a.mat_code = b.자재번호)
      WHERE a.yyyymm = @YYYYMM AND a.site = @SITE
        AND a.sel_code = @SEL_CODE
        AND b.자재번호 IS NULL;
      
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10) + '세부 검증 정보:';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + 'BOM 미등록 자재: ' + CAST(@BOM_MISSING AS VARCHAR) + '개';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) + '미배부 자재: ' + CAST(@MAT_NOALLOC AS VARCHAR) + '개';
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      
      IF ABS(@DIFF_AMT) > 100 BEGIN
          IF @BOM_MISSING > 0 BEGIN
              SET  @Message =  @Message + char(10) + N'⚠️  [WARN] BOM 마스터 미등록 자재가 공통 배부로 적용되었습니다';
          END
          
          IF @MAT_NOALLOC > 0 BEGIN
              SET  @Message =  @Message + char(10) + '[ERROR] 미배부 자재가 발견되었습니다';
          END
          
          DECLARE @DIFF_PCT DECIMAL(10,4) = (CAST(@DIFF_AMT AS DECIMAL(20,2)) / NULLIF(CAST(@SOURCE_AMT AS DECIMAL(20,2)), 0)) * 100;
          SET  @Message =  @Message + char(10) + N'⚠️  [WARN] 재료비배부 데이터 불일치 발생! (차이율: ' + CAST(ISNULL(@DIFF_PCT, 0) AS VARCHAR(10)) + '%)';
      END
      ELSE BEGIN
          SET  @Message =  @Message + char(10) + N'✅ [CHECK] 재료비배부 데이터 무결성 검증 통과';
      END
      SET  @Message =  @Message + char(10) + '====================================================================================================';
      SET  @Message =  @Message + char(10);
      
      SET  @Message =  @Message + char(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 재료비배부(DOI_MAT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE='HQ' THEN '본사' ELSE 'VINA' END + '데이타 입력 완료했습니다';
      
	-- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '재료비 배부', 'UP_VN_MAT_COST', 'SUCCESS');				
					
	COMMIT TRANSACTION;
	
	drop table #matCost
    SELECT @Message as retMessage;
    RETURN 0;     
	
	END TRY
   
	BEGIN CATCH
		SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
		INSERT INTO doi_execlog
			 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
		    values
		    (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '재료비 배부', 'UP_VN_MAT_COST', 'FAIL');	
	ROLLBACK TRANSACTION;
		SELECT @Message as retMessage;
	END CATCH;
END;
GO

-- ==========================================
-- File: UP_VN_SALE_COST.sql
-- ==========================================
CREATE OR ALTER PROCEDURE UP_VN_SALE_COST
    @YYYYMM VARCHAR(10),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DeletedRows INT = 0;
    DECLARE @InsertedRows INT = 0;
    DECLARE @CNT INT = 0;
    DECLARE @CHECK BIT = 0;
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @EndTime DATETIME;
    DECLARE @ErrorMsg NVARCHAR(4000);
    DECLARE @Message NVARCHAR(MAX) = '';
    DECLARE @SiteName VARCHAR(10) = CASE WHEN @SITE = @SITE THEN '본사' ELSE 'VINA' END;
    
    BEGIN TRY
        -- 시작 메시지
        SET @Message = '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 경비/매출원가(DOI_SLCO) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 배부를 시작합니다';
        
        BEGIN TRANSACTION;

        --데이타 체크	
	    IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('DOI_STCO') AND type in ('U')) -- 테이블 존재 여부 확인
	    BEGIN
			SELECT @CNT = count(*)
				FROM DOI_STCO
		      WHERE yyyymm	= @YYYYMM
		        and site  	= @SITE
        		and sel_code= @SEL_CODE;
			IF @CNT = 0 BEGIN
				SET  @Message =  @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '
						+@YYYYMM + '월 '+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
				SET @CHECK = 1;
			END
		END
	    ELSE
	    BEGIN
	        SET  @Message =  @Message + char(10) + '[ERROR] ' + '제품수불금액(DOI_STCO)테이블이 존재하지 않습니다.';
	        SET @CHECK = 1;
	    END	
	
		SELECT @CNT = count(*)
			FROM DOI_ACCT_EXPEN
	      WHERE yyyymm	= @YYYYMM
	        and site  	= @SITE
			and sel_code= @SEL_CODE;
		IF @CNT = 0 BEGIN
			SET  @Message =  @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_ACCT_EXPEN) 테이블에 '
					+@YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
			SET @CHECK = 1;
		END	
		
		IF @CHECK = 1 BEGIN 
			SELECT @Message as retMessage;
			RETURN -1;
		END 
	        -- 1. 기존 SALE 데이터 삭제
        DELETE FROM DOI_SALE
        WHERE YYYYMM = @YYYYMM
          AND SITE = @SITE;
        
        SET @DeletedRows = @@ROWCOUNT;
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 기존 SALE 데이터 ' + CAST(@DeletedRows AS VARCHAR) + '건 삭제';
        
	 	 INSERT INTO DOI_SALE (YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처, 수량, 합계수량, 판매금액)
	  	 SELECT YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처, SUM(수량) as 수량, 
	 		SUM(SUM(수량)) OVER(PARTITION BY 구분, 품명) as 합계수량, 
	 		SUM(원화판매금액) as 판매금액 
		  FROM (
		 	select YYYYMM, SITE,
			 CASE
		        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
		        WHEN RIGHT(품번, 1) = 'P' THEN N'양산'
		        ELSE N'개발'
		      END AS 구분, LEFT(품번, LEN(품번)-1) AS 품명, 품번, Local구분, 판매단위, 거래처,수량, 원화판매금액
			from DOI_SALE_RESC
			where 1=1 
			  and YYYYMM = @YYYYMM
			  and SITE 	 = @SITE
		    union all
		    select YYYYMM, SITE,
				 CASE
			        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
			        WHEN RIGHT(품번, 1) = 'P' THEN N'양산'
			        ELSE N'개발'
			     END AS 구분, LEFT(품번, LEN(품번)-1) AS 품명, 품번,  수출구분, 단위, Buyer, 수량 ,원화판매금액 --select *
			from DOI_INVOICE_RESC
			where 1=1 
			  and YYYYMM = @YYYYMM
			  and SITE 	 = @SITE
		    )a
		    GROUP BY YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처
		    ORDER BY YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처;
	    
	 	SET @InsertedRows = @@ROWCOUNT;
	 	SET @EndTime = GETDATE();
        
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 매출테이블(DOI_SALE)  ' + @YYYYMM + '월 ' + @SiteName + '매출 데이터 ' 
            + CAST(@InsertedRows AS VARCHAR) + '건 집계 했습니다';	
        
        -- 1. 기존 데이터 삭제
        DELETE FROM DOI_SLCO
        WHERE YYYYMM  = @YYYYMM
          AND SITE 	  = @SITE
          AND SEL_CODE= @SEL_CODE;
        
        SET @DeletedRows = @@ROWCOUNT;
SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 기존 매풀원가 데이터 ' + CAST(@DeletedRows AS VARCHAR) + '건 삭제';
        
        -- 2. 매출원가 데이터 생성
        -- STCO의 출고금액을 SALES의 거래처별 수량 비율로 배부
		INSERT	INTO DOI_SLCO (
			YYYYMM,
			SITE,
			SEL_CODE,
			구분,
			MODEL,
			Local구분,
			판매단위,
			거래처,
			EXPEN_SEL,
			EXPEN_SEL명,
			OUT_qty,
			OUT_AMT
		)
		SELECT 
		    YYYYMM,
		    SITE,
		    SEL_CODE,
		    구분,
		    MODEL,
            Local구분,
            판매단위,
            거래처,
		    EXPEN_SEL,
		    EXPEN_SEL명,
		    -- [수량 최종 보정]
		    -- 1차 계산 수량 + (1위 거래처에 [원본 총수량 - 배부 수량 합계] 적용)
		    Base_OUT_Qty + CASE 
		        WHEN RN = 1 THEN (Original_Total_Qty - Grp_Sum_Qty) 
		        ELSE 0 
		    END AS OUT_qty,
		    -- [금액 최종 보정]
		    -- 1차 계산 금액 + (1위 거래처에 [원본 총금액 - 배부 금액 합계] 적용)
		    Base_OUT_AMT + CASE 
		        WHEN RN = 1 THEN (Original_Total_Amt - Grp_Sum_Amt) 
		        ELSE 0 
		    END AS OUT_AMT 
		    --판매금액,
		FROM (
		    SELECT 
		        A.*,
		        -- [2단계] 파티션별 배부된 '수량'의 합계
		        SUM(Base_OUT_Qty) OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL) AS Grp_Sum_Qty,
		        -- [2단계] 파티션별 배부된 '금액'의 합계 (새로 추가됨)
		        SUM(Base_OUT_AMT) OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL) AS Grp_Sum_Amt,
		        -- [2단계] 보정 대상 선정을 위한 순위 (수량/금액 모두 비중이 제일 큰 곳에 몰아주기 위함)
		        ROW_NUMBER() OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL ORDER BY Base_OUT_Qty DESC, 거래처) AS RN
		    FROM (
		        -- [1단계] 개별 행의 배부 수량 및 금액을 먼저 계산하여 확정
		        SELECT
		            stco.YYYYMM,
		            stco.SITE,
		            stco.SEL_CODE,
		            stco.구분,
		            stco.MODEL,
		            sale.Local구분,
		            sale.판매단위,
		            sale.거래처,
		            stco.EXPEN_SEL,
		            stco.EXPEN_SEL명,
		            sale.판매금액,
		            -- 원본 총 수량 & 총 금액 보존
		            CAST(stco.[OUT] AS INT) AS Original_Total_Qty,
		            stco.OUT_AMT AS Original_Total_Amt,
		            -- 1. 수량 1차 배부 (정수 반올림)
		            CASE 
		                WHEN ISNULL(sale.수량, 0) = 0 THEN 0
		   			ELSE 
		                  CASE
		                        WHEN CAST(stco.[OUT] AS BIGINT) * CAST(COALESCE(sale.수량,stco.[OUT]) AS BIGINT) / COALESCE(sale.합계수량,stco.[OUT]) > 2147483647 THEN 2147483647
		                        ELSE CAST(ROUND(CAST(stco.[OUT] AS BIGINT) * CAST(COALESCE(sale.수량,stco.[OUT]) AS BIGINT) * 1.0 / COALESCE(sale.합계수량,stco.[OUT]), 0) AS INT)
		                    END
		            END AS Base_OUT_Qty,
		            -- 2. 금액 1차 배부 (소수점 2자리 반올림 - 필요시 0으로 수정)
		            CASE 
		                WHEN ISNULL(sale.수량, 0) = 0 THEN 0
		                ELSE ROUND(stco.OUT_AMT * CAST(sale.수량 AS BIGINT) * 1.0 / sale.합계수량, 0)
		            END AS Base_OUT_AMT
		        FROM (
		            -- STCO 소스
		            SELECT
		                YYYYMM,
		                SITE,
		                SEL_CODE,
		                /*CASE WHEN 구분='카세트' then '양산' else 구분 end as*/ 구분, 
		                MODEL,
		                EXPEN_SEL,
		                MAX(EXPEN_SEL명) AS EXPEN_SEL명,
		                CASE WHEN AVG([OUT]) != 0 THEN AVG([OUT]) else AVG([OUTETC]) end AS [OUT],--select
		                SUM(coalesce(OUT_AMT,0) - coalesce(OUTETC_AMT,0)) AS OUT_AMT
		            FROM DOI_STCO
		            WHERE YYYYMM = @YYYYMM --and model='8136' --and expen_sel='MCOM'
		              AND SITE = @SITE
		              AND SEL_CODE = @SEL_CODE
		            GROUP BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL
		            --HAVING SUM(OUT_AMT) > 0 --2026.01.14
		        ) stco
		        INNER JOIN DOI_SALE sale ON stco.MODEL = sale.품명 
		                    AND stco.구분 = sale.구분  
		                    and stco.yyyymm	= sale.yyyymm
		                    and stco.site	= sale.site
		    ) A
		) Final; 
			SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 매풀원가 데이터 ' + CAST(@@ROWCOUNT AS VARCHAR) + '건 입력 했습니다';
        --EXTRA (수불은 없지만 재공 기초금액이 있는 모델) 처리 
		INSERT INTO DOI_SLCO 
		(YYYYMM,SEL_CODE,SITE,구분,MODEL,Local구분,판매단위,거래처,EXPEN_SEL,EXPEN_SEL명,OUT_qty,OUT_AMT)
		select
			YYYYMM,
			SEL_CODE,
			SITE,
			'개발' as 구분,
			'EXTRA' AS MODEL,
			'*' as Local구분,
			'*' as 판매단위,
			'*' as 거래처,
			'*' as EXPEN_SEL,
			'*' as expen_sel명,
			0 as out_qty,
			SUM(ADJ_BOH) as OUT_AMT
		from
			doi_cost
		where
			yyyymm = @YYYYMM
			and sel_code = @SEL_CODE
			and site = @SITE
			and expen_sel = '*'
		group by 	YYYYMM,
			SEL_CODE,
			SITE;  
		
		-- ##2 재공 전량LOSS --> STCO (기타매출) -->  SLCO_OUT_AMT
		insert into DOI_SLCO
		SELECT YYYYMM, SITE, SEL_CODE, 구분, MODEL, '*' Local구분, '*' 판매단위, '*' 거래처, '*' EXPEN_SEL, '기타매출' EXPEN_SEL명, 
		       0 OUT_qty,
		       SUM(LOSS) OUT_AMT       
		FROM
		(
		   SELECT 
		   YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,expen_sel명,ACCT_NAME, loss_qty, LOSS
		   FROM
		   (
		      select YYYYMM, SEL_CODE, SITE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,  
		             sum(loss_qty) loss_qty, SUM(LOSS) LOSS
		      from doi_cost
		      where 
				yyyymm = @YYYYMM
				and sel_code = @SEL_CODE
				and site = @SITE
		      and  boh_qty + in_qty != 0
		      --and out_qty + eoh_qty = 0
		      and out = 0
		      and eoh = 0
		      GROUP BY YYYYMM, SEL_CODE, SITE, 구분, MODEL, EXPEN_SEL명, ACCT_NAME, EXPEN_SEL
		      HAVING SUM(LOSS) != 0
		   ) X
		) Y
		GROUP BY   YYYYMM, SEL_CODE, SITE, 구분,  MODEL; --, EXPEN_SEL, EXPEN_SEL명;
		
		
        SET @InsertedRows = @@ROWCOUNT;
        SET @EndTime = GETDATE();
        
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
    + '- 경비/매출원가(DOI_SLCO) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 ' 
 + CAST(@InsertedRows AS VARCHAR) + '건 상세 배부입니다';
 
        /*SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 실행 시간: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR) + '초';*/
        
        -- 완료 메시지
        SET @Message = @Message + CHAR(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 경비/매출원가(DOI_SLCO) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 입력 완료되었습니다';
        
        -- 판관비 시작 메시지
        SET @Message = @Message + CHAR(10)+ CHAR(10) + '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 판매관리비(DOI_SMCE_COST) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 배부를 시작합니다';
       /* 
		DELETE FROM DOI_SMCE_COST
        WHERE YYYYMM = @YYYYMM
          AND SITE = @SITE;
        
        SET @DeletedRows = @@ROWCOUNT;
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 기존 판관비 데이터 ' + CAST(@DeletedRows AS VARCHAR) + '건 삭제';
            
    	--판매관리비 배부
      	with sale_rate as(
  		select
			yyyymm,
			구분,
			품명 as model,
			sum(원화판매금액) SALE_AMT,
			sum(sum(원화판매금액)) over() tot_amt,
			CAST(CAST(SUM(원화판매금액) as NUMERIC(38,25))/ NULLIF(SUM(SUM(원화판매금액)) OVER(), 0) AS NUMERIC(38,25)) dist_rate --select *
		FROM	
			(select yyyymm, CASE WHEN RIGHT(품번,1)='D' THEN '개발' ELSE '양산' END as 구분,품명, 원화판매금액	
			from
				DOI_SALE_RESC
			where 1=1 
			  and YYYYMM = @YYYYMM
      		  and SITE 	 = @SITE
	        union all
	        select yyyymm, CASE WHEN RIGHT(품번,1)='D' THEN '개발' ELSE '양산' END as 구분, 품명, 원화판매금액
			from
				DOI_INVOICE_RESC
			where 1=1 
			  and YYYYMM = @YYYYMM
      		  and SITE 	 = @SITE
      		  and 단위	 = 'Cell'
        ) a   
		group by yyyymm, 구분, 품명 
		),
		sale_cntr as(
		 select 
		 	YYYYMM, 
		 	SITE,
			ACCT_NAME AS SUB_NAME,
			MAX(ITEM_NAME) AS ITEM_NAME,
			EXPEN_SEL,
			MIN(EXPEN_SEL명) AS EXPEN_SEL명, --select
			sum(ACCT_AMT) TOT_ACCT,
			sum(sum(ACCT_AMT)) over() TOT_SMCE  --select *
		from
			DOI_ACCT_EXPEN
		where
			1 = 1
			and YYYYMM = @YYYYMM
          	and SITE   = @SITE
			and acct_class = 'CC'
		group by YYYYMM, SITE, EXPEN_SEL,ACCT_NAME
		)
	 	INSERT into DOI_SMCE_COST
		select 
		a.YYYYMM,
		@SEL_CODE as sel_code,
		a.SITE,
		b.구분,
		b.model,
		a.EXPEN_SEL명,
		a.SUB_NAME,
		a.ITEM_NAME,
		a.EXPEN_SEL,
		a.TOT_ACCT,
		b.SALE_AMT,
		b.TOT_AMT,
		a.TOT_SMCE,
		b.DIST_RATE,
		round((a.tot_acct * b.dist_rate),0) as DIST_AMT,
		(a.tot_acct * b.dist_rate) as DIST_AMT --into #kyhaa
		from
			sale_cntr a
		left join sale_rate b on
		(1 = 1)
		order by b.model;*/
  	--기존 데이타 삭제
	DELETE FROM DOI_SMCE_COST
		WHERE 1=1
		  AND yyyymm 	= @YYYYMM
		  AND SITE 		= @SITE
          AND SEL_CODE  = @SEL_CODE;
			
		SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 판매관리비배부(DOI_SMCE_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';

		WITH sale_data AS (
		    -- [1] 매출 데이터 및 비율 계산용 기초 데이터
			SELECT yyyymm, 구분, 품명 model,Local구분, 판매단위, 거래처, 판매금액 as SALE_AMT
			FROM DOI_SALE 
			where 1=1 
			  and YYYYMM = @YYYYMM
      		  and SITE 	 = @SITE
			  and 판매단위='Cell'
		),
		sale_total AS (
		    -- [2] 전체 매출 합계 (분모)
		    SELECT SUM(SALE_AMT) AS TOT_SALE_AMT 
		    FROM sale_data
		),
		expen_data AS (
		    -- [3] 비용 데이터 (배부 대상)
		    SELECT 
		        YYYYMM, 
		        SITE,
		        ACCT_NAME AS SUB_NAME,
		        MAX(ITEM_NAME) AS ITEM_NAME,
		        EXPEN_SEL,
		        MIN(EXPEN_SEL명) AS EXPEN_SEL명,
		        SUM(ACCT_AMT) AS TOT_ACCT,       -- 개별 비용 항목의 금액
		        SUM(SUM(ACCT_AMT)) OVER() AS TOT_SMCE -- 전체 비용 합계 (참고용)
		    FROM DOI_ACCT_EXPEN
		    WHERE yyyymm = @YYYYMM
		      AND site = @SITE
		      AND acct_class = 'CC'
		      AND sel_code = @SEL_CODE
		    GROUP BY YYYYMM, SITE, EXPEN_SEL, ACCT_NAME
		)
		INSERT INTO DOI_SMCE_COST
		SELECT
		    YYYYMM,
		    @SEL_CODE AS sel_code,
		    SITE,
		    구분,
		    model,Local구분, 판매단위, 거래처,
		    EXPEN_SEL명,
		    SUB_NAME,
		    ITEM_NAME,
		    EXPEN_SEL,
		    TOT_ACCT,
		    SALE_AMT,
		  	TOT_AMT,
		    TOT_SMCE,
		    DIST_RATE,
		    -- [최종 보정]
		    -- 1차 배부액 + (1위 모델에게 [원본비용 - 배부합계] 차이 반영)
		    Base_Dist_Amt + CASE 
		        WHEN RN = 1 THEN (TOT_ACCT - Grp_Sum_Amt) 
		        ELSE 0 
		    END AS DIST_AMT,
		    DIST_AMT_ORI-- 참고용 원본 계산값
		FROM (
		    SELECT 
		        A.*,
		        -- [그룹별 배부액 합계] 비용항목(EXPEN_SEL)별로 배부된 금액의 합
		        SUM(Base_Dist_Amt) OVER (PARTITION BY EXPEN_SEL,SUB_NAME) AS Grp_Sum_Amt,
		        -- [순위] 단수차를 몰아줄 대상 (매출액이 가장 큰 모델 순)
		        ROW_NUMBER() OVER (PARTITION BY EXPEN_SEL,SUB_NAME ORDER BY SALE_AMT DESC) AS RN
		    FROM (
		        SELECT
		            e.YYYYMM,
		            e.SITE,
		            s.구분,
		            s.model, s.Local구분, s.판매단위, s.거래처,
		            e.EXPEN_SEL명,
		            e.SUB_NAME,
		            e.ITEM_NAME,
		            e.EXPEN_SEL,
		            e.TOT_ACCT,  -- 이 비용을 배부해야 함
		            e.TOT_SMCE,
		            s.SALE_AMT,
		            t.TOT_SALE_AMT AS TOT_AMT,
		            -- [비율 계산 수정] * 1.0을 추가하여 실수 연산 유도
		            CASE 
		                WHEN ISNULL(t.TOT_SALE_AMT, 0) = 0 THEN 0
		                ELSE CAST(s.SALE_AMT AS FLOAT) / t.TOT_SALE_AMT 
		            END AS DIST_RATE,
		            -- [1차 배부액] 반올림 처리
		            CASE 
		                WHEN ISNULL(t.TOT_SALE_AMT, 0) = 0 THEN 0
		                ELSE ROUND(e.TOT_ACCT * (CAST(s.SALE_AMT AS FLOAT) / t.TOT_SALE_AMT), 0)
		            END AS Base_Dist_Amt,
		            -- [참고용] 소수점 포함 원본 배부액
		            e.TOT_ACCT * (CAST(s.SALE_AMT AS FLOAT) / NULLIF(t.TOT_SALE_AMT, 0)) AS DIST_AMT_ORI
		        FROM expen_data e
		        CROSS JOIN sale_data s -- 모든 비용을 모든 모델에 배부 (1=1 조건과 동일)
		        CROSS JOIN sale_total t
		    ) A
		) Final
		ORDER BY model;

       SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 판매관리비(DOI_SMCE_COST) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 ' 
            + CAST(@@ROWCOUNT AS VARCHAR) + '건 상세 배부입니다';
        -- 판관비 완료 메시지
SET @Message = @Message + CHAR(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
        + '- 경비/매출원가(DOI_SMCE_COST) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 입력 완료되었습니다';
        
       
     -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '매출원가/판관비', 'UP_DOI_SALE_COST', 'SUCCESS');
       
       COMMIT TRANSACTION;

        -- 실행 결과 반환 (retMessage 형식)
        SELECT @Message AS retMessage;
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        -- 에러 정보
        SET @ErrorMsg = ERROR_MESSAGE();
        SET @EndTime = GETDATE();
        
        -- 에러 메시지
        SET @Message = @Message + CHAR(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 오류 발생: ' + @ErrorMsg;
    
       INSERT INTO doi_execlog
       	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
        values
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '매출원가/판관비', 'UP_DOI_SALE_COST', 'FAIL');
       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        -- 에러 결과 반환
        SELECT @Message AS retMessage;
        
        -- 실패 반환
        RETURN -1;
    END CATCH
END;
GO

-- ==========================================
-- File: VN_ManufacturingExpenseByDept.sql
-- ==========================================
CREATE OR ALTER Procedure VN_ManufacturingExpenseByDept(
	@YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

		-- 1) 금액(#vamt) : 재료(원재료=doi_mat_amt 단일) + 노무/경비(doi_dept_cost 세분 브리지)
		--    항목 = 세분(경영계획과목 우선, 없으면 상위계정과목), 섹션 = 계정코드(621/6272재료,622직접노무,627간접경비)
		IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
		SELECT dept_name, sec, item, MIN(iord) iord, SUM(amt) amt
		INTO #vamt
		FROM (
			SELECT N'제조공통' dept_name, 1 sec, N'원재료비' item, CAST(0 AS bigint) iord, SUM(in_amt) amt
				FROM doi_mat_amt WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
			UNION ALL
			SELECT LTRIM(RTRIM(d.코스트센터)) dept_name,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN 1
					 WHEN LEFT(d.계정코드,3)='622' THEN 2
					 WHEN LEFT(d.계정코드,3)='627' THEN 3 ELSE 9 END sec,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN N'부재료비 (6272)' WHEN d.계정과목=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN d.계정과목=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') END item,
				MIN(TRY_CONVERT(bigint,d.계정코드)) iord,
				SUM(d.차변금액 - d.대변금액) amt
			FROM doi_dept_cost d
			JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.acct=d.계정코드
			WHERE d.yyyymm=@YYYYMM AND d.site=@SITE AND d.비용구분='제조'
			  AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
			  AND LEFT(d.계정코드,3) IN ('622','627')
			  AND ISNULL(REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N''),'')<>''
			GROUP BY LTRIM(RTRIM(d.코스트센터)),
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN 1 WHEN LEFT(d.계정코드,3)='622' THEN 2 WHEN LEFT(d.계정코드,3)='627' THEN 3 ELSE 9 END,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN N'부재료비 (6272)' WHEN d.계정과목=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN d.계정과목=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') END
		) t
		WHERE sec IN (1,2,3)
		GROUP BY dept_name, sec, item;

		-- 2) 부서 목록
		IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
		SELECT dept_name, ord INTO #vdept FROM (
			SELECT DISTINCT dept_name, CASE WHEN dept_name=N'제조공통' THEN 0 ELSE 1 END ord FROM #vamt
			UNION SELECT N'합계', 2
		) t;

		-- 3) 골격(섹션 헤더 + 세분항목, (N) 번호)
		IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
		CREATE TABLE #vskel(rn int, sec int, item nvarchar(200), gubun nvarchar(200));
		INSERT #vskel(rn, sec, item, gubun)
		SELECT sec*10000 + seq*10, sec, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
		FROM (VALUES
			(1,1,N'원재료비'),(1,2,N'부재료비 (6272)'),
			(2,1,N'제)급여-직원'),(2,2,N'제)상여금'),(2,3,N'제)제수당'),(2,4,N'제)퇴직급여'),(2,5,N'제)주식보상비용'),(2,6,N'제)급여-사회보험료'),(2,7,N'제)급여-건강보험'),(2,8,N'제)급여-노동자실업보험료'),(2,9,N'제)급여-노동자노조비'),(2,10,N'제)급여-개인소득세'),(2,11,N'제)급여-기타'),
			(3,1,N'제)직원급여'),(3,2,N'제)상여금'),(3,3,N'제)제수당'),(3,4,N'제)퇴직급여'),(3,5,N'제)주식보상비용'),(3,6,N'제)급여-사회보험료'),(3,7,N'제)급여-건강보험'),(3,8,N'제)급여-노동자실업보험료'),(3,9,N'제)급여-노동자노조비'),(3,10,N'제)급여-개인소득세'),(3,11,N'제)급여-기타'),
			(3,12,N'제)급여-기타비용'),(3,13,N'제)여비교통비'),(3,14,N'제)통신비'),(3,15,N'제)수도광열비'),(3,16,N'제)전력비'),(3,17,N'제)감가상각비'),(3,18,N'제)지급임차료'),(3,19,N'제)수선비'),(3,20,N'제)보험료'),(3,21,N'제)차량유지비'),(3,22,N'제)운반비'),(3,23,N'제)교육훈련비'),
			(3,24,N'제)도서인쇄비'),(3,25,N'제)소모품비'),(3,26,N'제)지급수수료'),(3,27,N'제)외주가공비'),(3,28,N'제)사용권자산감가상각비'),(3,29,N'제)검사비'),(3,30,N'제)견본비'),(3,31,N'기술지원 및 기술이전비')
		) v(sec,seq,item);
		INSERT #vskel(rn, sec, item, gubun) VALUES
			(10000,1,N'__H1',N'  I. 재료비'),
			(20000,2,N'__H2',N'  II. 직접노무비'),
			(30000,3,N'__H3',N'  III. 간접제조경비'),
			(90000,9,N'__T', N'  IV. 당기총제조원가');
		-- 공구 및 도구비용 별도 2항목 ((12) 뒤, 감가상각비에서 제외)
		INSERT #vskel(rn, sec, item, gubun) VALUES
			(30125,3,N'제)공구 및 도구 비용 - 상각비용', N'    (1-1) 제)공구 및 도구 비용 - 상각비용'),
			(30126,3,N'제)공구 및 도구 비용 -일회성비용', N'    (1-2) 제)공구 및 도구 비용 -일회성비용');

		-- 4) 소스테이블
		IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
		;WITH matched AS (SELECT v.dept_name, v.sec, sk.rn, v.amt FROM #vamt v JOIN #vskel sk ON sk.sec=v.sec AND sk.item=v.item),
		 amt_item AS (SELECT dept_name, rn, SUM(amt) amt FROM matched GROUP BY dept_name, rn),
		 amt_hdr AS (SELECT dept_name, sec*10000 rn, SUM(amt) amt FROM matched GROUP BY dept_name, sec),
		 amt_tot AS (SELECT dept_name, 90000 rn, SUM(amt) amt FROM matched GROUP BY dept_name),
		 amt_all AS (SELECT * FROM amt_item UNION ALL SELECT * FROM amt_hdr UNION ALL SELECT * FROM amt_tot)
		SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
		INTO #vsource
		FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
		LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

		-- 5) 동적 PIVOT (부서 컬럼)
		SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vColumns = N'[' + @vColumns + N']';
		SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce([' FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');
		SET @vSQL = N'
SELECT ' + @vNullCols + N'
FROM ( SELECT dept_name, rn, gubun, amt FROM #vsource
       UNION ALL SELECT N''합계'' dept_name, rn, gubun, SUM(amt) amt FROM #vsource GROUP BY rn, gubun ) AS S
PIVOT ( SUM(amt) FOR dept_name IN (' + @vColumns + N') ) AS P
ORDER BY rn;';
		EXEC sp_executesql @vSQL;

		DROP TABLE #vsource; DROP TABLE #vskel; DROP TABLE #vamt; DROP TABLE #vdept;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

GO

-- ==========================================
-- File: VN_ManufacturingExpenseByDept_Cum.sql
-- ==========================================
CREATE OR ALTER Procedure VN_ManufacturingExpenseByDept_Cum(
	@FROM_YYYYMM varchar(10),
	@TO_YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

		-- 1) 금액(#vamt) : 재료(원재료=doi_mat_amt 단일) + 노무/경비(doi_dept_cost 세분 브리지)  (기간 누적)
		--    항목 = 세분(경영계획과목 우선, 없으면 상위계정과목), 섹션 = 계정코드(6272재료,622직접노무,627간접경비)
		IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
		SELECT dept_name, sec, item, MIN(iord) iord, SUM(amt) amt
		INTO #vamt
		FROM (
			SELECT N'제조공통' dept_name, 1 sec, N'원재료비' item, CAST(0 AS bigint) iord, SUM(in_amt) amt
				FROM doi_mat_amt WHERE yyyymm BETWEEN @FROM_YYYYMM AND @TO_YYYYMM AND site=@SITE AND sel_code=@SEL_CODE
			UNION ALL
			SELECT LTRIM(RTRIM(d.코스트센터)) dept_name,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN 1
					 WHEN LEFT(d.계정코드,3)='622' THEN 2
					 WHEN LEFT(d.계정코드,3)='627' THEN 3 ELSE 9 END sec,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN N'부재료비 (6272)' ELSE REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') END item,
				MIN(TRY_CONVERT(bigint,d.계정코드)) iord,
				SUM(d.차변금액 - d.대변금액) amt
			FROM doi_dept_cost d
			JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.acct=d.계정코드
			WHERE d.yyyymm BETWEEN @FROM_YYYYMM AND @TO_YYYYMM AND d.site=@SITE AND d.비용구분='제조'
			  AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
			  AND LEFT(d.계정코드,3) IN ('622','627')
			  AND ISNULL(REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N''),'')<>''
			GROUP BY LTRIM(RTRIM(d.코스트센터)),
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN 1 WHEN LEFT(d.계정코드,3)='622' THEN 2 WHEN LEFT(d.계정코드,3)='627' THEN 3 ELSE 9 END,
				CASE WHEN LEFT(d.계정코드,4)='6272' THEN N'부재료비 (6272)' ELSE REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') END
		) t
		WHERE sec IN (1,2,3)
		GROUP BY dept_name, sec, item;

		-- 2) 부서 목록
		IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
		SELECT dept_name, ord INTO #vdept FROM (
			SELECT DISTINCT dept_name, CASE WHEN dept_name=N'제조공통' THEN 0 ELSE 1 END ord FROM #vamt
			UNION SELECT N'합계', 2
		) t;

		-- 3) 골격(섹션 헤더 + 세분항목, (N) 번호)
		IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
		CREATE TABLE #vskel(rn int, sec int, item nvarchar(200), gubun nvarchar(200));
		INSERT #vskel(rn, sec, item, gubun)
		SELECT sec*10000 + seq*10, sec, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
		FROM (VALUES
			(1,1,N'원재료비'),(1,2,N'부재료비 (6272)'),
			(2,1,N'제)급여-직원'),(2,2,N'제)상여금'),(2,3,N'제)제수당'),(2,4,N'제)퇴직급여'),(2,5,N'제)주식보상비용'),(2,6,N'제)급여-사회보험료'),(2,7,N'제)급여-건강보험'),(2,8,N'제)급여-노동자실업보험료'),(2,9,N'제)급여-노동자노조비'),(2,10,N'제)급여-개인소득세'),(2,11,N'제)급여-기타'),
			(3,1,N'제)직원급여'),(3,2,N'제)상여금'),(3,3,N'제)제수당'),(3,4,N'제)퇴직급여'),(3,5,N'제)주식보상비용'),(3,6,N'제)급여-사회보험료'),(3,7,N'제)급여-건강보험'),(3,8,N'제)급여-노동자실업보험료'),(3,9,N'제)급여-노동자노조비'),(3,10,N'제)급여-개인소득세'),(3,11,N'제)급여-기타'),
			(3,12,N'제)급여-기타비용'),(3,13,N'제)여비교통비'),(3,14,N'제)통신비'),(3,15,N'제)수도광열비'),(3,16,N'제)전력비'),(3,17,N'제)감가상각비'),(3,18,N'제)지급임차료'),(3,19,N'제)수선비'),(3,20,N'제)보험료'),(3,21,N'제)차량유지비'),(3,22,N'제)운반비'),(3,23,N'제)교육훈련비'),
			(3,24,N'제)도서인쇄비'),(3,25,N'제)소모품비'),(3,26,N'제)지급수수료'),(3,27,N'제)외주가공비'),(3,28,N'제)사용권자산감가상각비'),(3,29,N'제)검사비'),(3,30,N'제)견본비'),(3,31,N'기술지원 및 기술이전비')
		) v(sec,seq,item);
		INSERT #vskel(rn, sec, item, gubun) VALUES
			(10000,1,N'__H1',N'  I. 재료비'),
			(20000,2,N'__H2',N'  II. 직접노무비'),
			(30000,3,N'__H3',N'  III. 간접제조경비'),
			(90000,9,N'__T', N'  IV. 당기총제조원가');

		-- 4) 소스테이블
		IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
		;WITH matched AS (SELECT v.dept_name, v.sec, sk.rn, v.amt FROM #vamt v JOIN #vskel sk ON sk.sec=v.sec AND sk.item=v.item),
		 amt_item AS (SELECT dept_name, rn, SUM(amt) amt FROM matched GROUP BY dept_name, rn),
		 amt_hdr AS (SELECT dept_name, sec*10000 rn, SUM(amt) amt FROM matched GROUP BY dept_name, sec),
		 amt_tot AS (SELECT dept_name, 90000 rn, SUM(amt) amt FROM matched GROUP BY dept_name),
		 amt_all AS (SELECT * FROM amt_item UNION ALL SELECT * FROM amt_hdr UNION ALL SELECT * FROM amt_tot)
		SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
		INTO #vsource
		FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
		LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

		-- 5) 동적 PIVOT (부서 컬럼)
		SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vColumns = N'[' + @vColumns + N']';
		SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce([' FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');
		SET @vSQL = N'
SELECT ' + @vNullCols + N'
FROM ( SELECT dept_name, rn, gubun, amt FROM #vsource
       UNION ALL SELECT N''합계'' dept_name, rn, gubun, SUM(amt) amt FROM #vsource GROUP BY rn, gubun ) AS S
PIVOT ( SUM(amt) FOR dept_name IN (' + @vColumns + N') ) AS P
ORDER BY rn;';
		EXEC sp_executesql @vSQL;

		DROP TABLE #vsource; DROP TABLE #vskel; DROP TABLE #vamt; DROP TABLE #vdept;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

GO

-- ==========================================
-- File: VN_ManufacturingExpenseByModel.sql
-- ==========================================


CREATE OR ALTER Procedure VN_ManufacturingExpenseByModel(
	@YYYYMM varchar(10),
 	@SITE varchar(4),
 	@SEL_CODE varchar(10)
 )
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		--declare @YYYYMM varchar(10)=@YYYYMM, @SITE varchar(4)=@SITE;
		DECLARE @Columns VARCHAR(3000);
		DECLARE @Null_Columns VARCHAR(3000);
		DECLARE @SQL NVARCHAR(MAX);
		-- PIVOT할 열 목록 조회
		SELECT @Columns = COALESCE(@Columns + '], [', '') + model
		FROM (SELECT TOP 500 CONCAT(구분, model) model 
				FROM (
					SELECT DISTINCT 구분, model 
					FROM (
						SELECT DISTINCT 구분, replace(도우모델,' ','') as model 
						FROM doi_mat_cost 
						where yyyymm=@YYYYMM 
						  and site=@SITE 
						  and sel_code=@SEL_CODE
						  --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
						group by 구분, 도우모델
						UNION 
						SELECT 구분, replace(model,' ','') as model 
						  from doi_expen_matl 
						 where yyyymm=@YYYYMM 
						   and site=@SITE 
						   and sel_code=@SEL_CODE 
						   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
						group by 구분, model 
						UNION
						SELECT 'Z' 구분, CONCAT(구분, '합계') model 
						  FROM (
								SELECT DISTINCT 구분 
								  from doi_mat_cost 
								 where yyyymm=@YYYYMM 
								   and site=@SITE 
								   and sel_code=@SEL_CODE
						  		  -- and not (in_qty = 0 and out_qty = 0 and loss_qty = 0) 
								 group by 구분 
								 UNION 
								 SELECT 구분 
								   FROM doi_expen_matl 
								  where yyyymm=@YYYYMM 
								    and site=@SITE 
								    and sel_code=@SEL_CODE 								    
						   			and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
								  group by 구분
								)a
						UNION
						SELECT 'Z' 구분, '합계' model
					) A 
				) A 
				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			
						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;
		select @Columns=  '['+@Columns+']'; --select @Columns;
		SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
		FROM (SELECT TOP 500 CONCAT(구분, model) model 
				FROM (
					SELECT DISTINCT 구분, model 
					FROM (
						SELECT DISTINCT 구분, replace(도우모델,' ','') as model 
						  FROM doi_mat_cost 
						 where yyyymm=@YYYYMM 
						   and site=@SITE 
						   and sel_code=@SEL_CODE 
						   --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
						group by 구분, 도우모델 
						UNION 
						SELECT 구분, replace(model,' ','') as model 
						  from doi_expen_matl 
						 where yyyymm=@YYYYMM 
						   and site=@SITE 
						   and sel_code=@SEL_CODE 
						   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
						group by 구분, model 
						UNION
						SELECT 'Z' 구분, CONCAT(구분, '합계') model 
						  FROM (
							SELECT DISTINCT 구분 
							  from doi_mat_cost 
							 where yyyymm=@YYYYMM 
							   and site=@SITE 
							   and sel_code=@SEL_CODE
							   --and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
							group by 구분 
							UNION 
							SELECT 구분 
							  FROM doi_expen_matl 
							 where yyyymm=@YYYYMM 
							   and site=@SITE 
							   and sel_code=@SEL_CODE
							   and not (in_qty = 0 and out_qty = 0 and loss_qty = 0)
							group by 구분
						)a
						UNION
						SELECT 'Z' 구분, '합계' model
					) A 
				) A 
				ORDER BY CASE WHEN 구분 = '양산' THEN 1 ELSE 2 END, 구분			
						,CASE WHEN model = '양산합계' THEN 1 ELSE 2 END, model )AS 도우모델 ;
			select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]',''); --SELECT @Null_Columns


	-- ===== [세분 기준 재작성] 금액(#amt) + 골격(#skel) + 소스(#sourceTable) =====
	-- 재료비: doi_mat_cost(도우모델 배부금액)
	-- 노무/경비: doi_expen_matl → doi_dept_cost(계정과목=ACCT_NAME) 브리지 → doi_acct.acct=계정코드
	--            항목 = 세분(경영계획과목 우선, 없으면 상위계정과목), 섹션 = 계정코드 접두(622 직접노무 / 627 간접경비)
	IF OBJECT_ID('tempdb..#amt') IS NOT NULL DROP TABLE #amt;
	SELECT 구분, model, sec, item, MIN(iord) iord, SUM(amt) amt
	INTO #amt
	FROM (
				select 구분, replace(도우모델,' ','') model, 1 sec, N'원재료비' item, CAST(1 AS bigint) iord, sum(배부금액) amt from doi_mat_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE group by 구분,도우모델
		union all
		select e.구분, replace(e.model,' ','') model,
		       case when left(dc.계정코드,4)='6272' then 1 when left(dc.계정코드,3)='622' then 2 else 3 end sec,
		       case when left(dc.계정코드,4)='6272' then N'부재료비 (6272)' when e.ACCT_NAME=N'공구 및 도구비용 - 상각비용' then N'제)공구 및 도구 비용 - 상각비용' when e.ACCT_NAME=N'공구 및 도구비용 - 일회성비용' then N'제)공구 및 도구 비용 -일회성비용' else REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') end item,
		       MIN(TRY_CONVERT(bigint, dc.계정코드)) iord,
		       sum(e.[in]) amt
		from doi_expen_matl e
		join (select distinct yyyymm,site,계정과목,계정코드 from doi_dept_cost) dc on dc.yyyymm=e.yyyymm and dc.site=e.site and dc.계정과목=e.ACCT_NAME
		join doi_acct a on a.yyyymm=e.yyyymm and a.site=e.site and a.acct=dc.계정코드
		where e.yyyymm=@YYYYMM and e.site=@SITE and e.sel_code=@SEL_CODE
		  and left(dc.계정코드,3) in ('622','627')
		  and ISNULL(REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N''),'')<>''
		group by e.구분, replace(e.model,' ',''), case when left(dc.계정코드,4)='6272' then 1 when left(dc.계정코드,3)='622' then 2 else 3 end, case when left(dc.계정코드,4)='6272' then N'부재료비 (6272)' when e.ACCT_NAME=N'공구 및 도구비용 - 상각비용' then N'제)공구 및 도구 비용 - 상각비용' when e.ACCT_NAME=N'공구 및 도구비용 - 일회성비용' then N'제)공구 및 도구 비용 -일회성비용' else REPLACE(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),N'(간접)',N'') end
	) t
	GROUP BY 구분, model, sec, item;

	-- 고정 골격 (재료2 + 직접노무11 + 간접경비31), 데이터 없으면 0, 목록 밖(공구도구 등)은 제외
	IF OBJECT_ID('tempdb..#skel') IS NOT NULL DROP TABLE #skel;
	CREATE TABLE #skel(rn int, sec int, item nvarchar(200), gubun nvarchar(200));
	INSERT #skel(rn, sec, item, gubun)
	SELECT sec*10000 + seq*10, sec, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
	FROM (VALUES
		(1,1,N'원재료비'),(1,2,N'부재료비 (6272)'),
		(2,1,N'제)급여-직원'),(2,2,N'제)상여금'),(2,3,N'제)제수당'),(2,4,N'제)퇴직급여'),(2,5,N'제)주식보상비용'),(2,6,N'제)급여-사회보험료'),(2,7,N'제)급여-건강보험'),(2,8,N'제)급여-노동자실업보험료'),(2,9,N'제)급여-노동자노조비'),(2,10,N'제)급여-개인소득세'),(2,11,N'제)급여-기타'),
		(3,1,N'제)직원급여'),(3,2,N'제)상여금'),(3,3,N'제)제수당'),(3,4,N'제)퇴직급여'),(3,5,N'제)주식보상비용'),(3,6,N'제)급여-사회보험료'),(3,7,N'제)급여-건강보험'),(3,8,N'제)급여-노동자실업보험료'),(3,9,N'제)급여-노동자노조비'),(3,10,N'제)급여-개인소득세'),(3,11,N'제)급여-기타'),
		(3,12,N'제)급여-기타비용'),(3,13,N'제)여비교통비'),(3,14,N'제)통신비'),(3,15,N'제)수도광열비'),(3,16,N'제)전력비'),(3,17,N'제)감가상각비'),(3,18,N'제)지급임차료'),(3,19,N'제)수선비'),(3,20,N'제)보험료'),(3,21,N'제)차량유지비'),(3,22,N'제)운반비'),(3,23,N'제)교육훈련비'),
		(3,24,N'제)도서인쇄비'),(3,25,N'제)소모품비'),(3,26,N'제)지급수수료'),(3,27,N'제)외주가공비'),(3,28,N'제)사용권자산감가상각비'),(3,29,N'제)검사비'),(3,30,N'제)견본비'),(3,31,N'기술지원 및 기술이전비')
	) v(sec,seq,item);
	INSERT #skel(rn, sec, item, gubun) VALUES
		(10000,1,N'__H1',N'  I. 재료비'),
		(20000,2,N'__H2',N'  II. 직접노무비'),
		(30000,3,N'__H3',N'  III. 간접제조경비'),
		(90000,9,N'__T', N'  IV. 당기총제조원가');
	-- 공구 및 도구비용 별도 2항목 ((12) 뒤, 감가상각비에서 제외)
	INSERT #skel(rn, sec, item, gubun) VALUES
		(30125,3,N'제)공구 및 도구 비용 - 상각비용', N'    (1-1) 제)공구 및 도구 비용 - 상각비용'),
		(30126,3,N'제)공구 및 도구 비용 -일회성비용', N'    (1-2) 제)공구 및 도구 비용 -일회성비용');

	IF OBJECT_ID('tempdb..#sourceTable') IS NOT NULL DROP TABLE #sourceTable;
	;WITH mdl AS (SELECT DISTINCT 구분, model FROM #amt),
	matched AS (SELECT v.구분, v.model, v.sec, sk.rn, v.amt FROM #amt v JOIN #skel sk ON sk.sec=v.sec AND sk.item=v.item),
	amt_item AS (SELECT 구분, model, rn, SUM(amt) amt FROM matched GROUP BY 구분, model, rn),
	amt_hdr  AS (SELECT 구분, model, sec*10000 rn, SUM(amt) amt FROM matched GROUP BY 구분, model, sec),
	amt_tot  AS (SELECT 구분, model, 90000 rn, SUM(amt) amt FROM matched GROUP BY 구분, model),
	amt_all  AS (SELECT * FROM amt_item UNION ALL SELECT * FROM amt_hdr UNION ALL SELECT * FROM amt_tot)
	SELECT m.구분, m.model, sk.rn, sk.gubun, CAST(ISNULL(a.amt,0) AS decimal(18,2)) amt
	INTO #sourceTable
	FROM mdl m CROSS JOIN #skel sk
	LEFT JOIN amt_all a ON a.구분=m.구분 AND a.model=m.model AND a.rn=sk.rn;

-- 동적 SQL 생성
		SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
	select CONCAT(구분,model) model, rn, gubun, amt from #sourceTable
	union all 
	select ''Z합계'' model, rn, gubun, sum(amt) amt from #sourceTable group by rn, gubun
	union all  
	select CONCAT(''Z'',구분,''합계'') model, rn, gubun, amt from (
		select rn, gubun, 구분, sum(amt) amt from #sourceTable group by rn, gubun, 구분 
	) a 	
) AS SourceTable
PIVOT 
(
	SUM(AMT)
	FOR model IN (' + @Columns + ')
) AS PivotTable
order by 1,2 desc;';
		
		-- 동적 SQL 실행
		--select @SQL;
		EXEC sp_executesql @SQL;
		COMMIT TRANSACTION;
-- 임시 테이블 정리
DROP TABLE #sourceTable;	
	END TRY
	
	BEGIN CATCH
	    ROLLBACK TRANSACTION;
	    SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;

GO

-- ==========================================
-- File: VN_PL_ByModel.sql
-- ==========================================
CREATE OR ALTER PROCEDURE VN_PL_ByModel --운영
(
    @YYYYMM VARCHAR(6),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

       	DECLARE @PivotColumns NVARCHAR(MAX);
        DECLARE @Columns     NVARCHAR(MAX);
        DECLARE @SQL         NVARCHAR(MAX);
       	DECLARE @SCOFTotal DECIMAL(18,2) = 0;
		DECLARE @CostAdj     DECIMAL(18,2) = 0;
		DECLARE @LossAdj     DECIMAL(18,2) = 0;    	

       	DROP TABLE IF EXISTS #MODEL;

        ----------------------------------------------------------------------
        -- 1. 모델 목록 (#MODEL)
        ----------------------------------------------------------------------
		;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SEL_CODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),
		MODEL_LIST AS (
		    -- 국내(매출)
		    SELECT DISTINCT
		        CASE 
		          WHEN A.품번 LIKE N'VN%' THEN N'카세트'
		          WHEN MI.품번 IS NOT NULL THEN N'구매'
		          WHEN RIGHT(A.품번,1)='P' THEN N'양산'
		          ELSE N'개발'
		        END AS 구분,
		        CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		      AND A.SITE   = @SITE
		
		    UNION
		
		    -- 해외(인보이스)
		    SELECT DISTINCT
		        CASE 
		          WHEN B.품번 LIKE N'VN%' THEN N'카세트'
		          WHEN MI.품번 IS NOT NULL THEN N'구매'
		          WHEN RIGHT(B.품번,1)='P' THEN N'양산'
		          ELSE N'개발'
		        END AS 구분,
		        CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번) - 1) ELSE B.품명 END AS model
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		      
		 UNION
		 
		 SELECT C.구분, C.MODEL
		 FROM DOI_STCO C
		    WHERE C.YYYYMM = @YYYYMM
		      AND C.SITE   = @SITE
		      AND C.SEL_CODE = @SEL_CODE
		      AND C.MODEL = 'EXTRA'
		UNION 
		SELECT 구분, MODEL
		FROM DOI_STCO
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND ACCT_NAME LIKE '기타출고'
		
		UNION
		
		SELECT
			O.구분,O.모델 AS model
		FROM DOI_원장상계 O
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND COALESCE(O.매출상계,0) <> 0
		)  
		SELECT DISTINCT
		    model, 구분
		INTO #MODEL
		FROM MODEL_LIST;

		SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
		FROM DOI_SCOF WITH(NOLOCK)
		WHERE yyyymm   = @YYYYMM
		  AND site     = @SITE
		  AND SEL_CODE = @SEL_CODE;

		SELECT @CostAdj = COALESCE(ABS(SUM(ISNULL(대변금액,0))), 0)
		FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE
		  AND 계정과목 = N'제품매출원가'
		  AND 대변금액 <> 0;		 
		 
		SELECT @LossAdj = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE; 
		 
		DROP TABLE IF EXISTS #sourceTable;
		 ;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SEL_CODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),
        ----------------------------------------------------------------------
        -- 2~5. 연간 매출 / 매출원가 / 판관비
        ----------------------------------------------------------------------
        SALES_RAW AS (
            ------------------------------------------------------------------
            -- (1) 매출 : 국내/해외
            ------------------------------------------------------------------
		    -- 국내매출
		    SELECT
		          A.SITE
		        , CASE 
			          WHEN A.품번 LIKE N'VN%' THEN N'카세트'
			          WHEN MI.품번 IS NOT NULL THEN N'구매'
			          WHEN RIGHT(A.품번,1)='P' THEN N'양산'
		          	ELSE N'개발'
		          END AS 구분
		        , A.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , N'국내'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , A.원화판매금액   AS amt
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		 AND A.SITE   = @SITE
		
		    UNION ALL
		
		    -- 해외매출
		    SELECT
		          B.SITE
		        , CASE 
			          WHEN B.품번 LIKE N'VN%' THEN N'카세트'
			          WHEN MI.품번 IS NOT NULL THEN N'구매'
			       WHEN RIGHT(B.품번,1)='P' THEN N'양산'
		          	ELSE N'개발'
		          END AS 구분
		        , B.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번) - 1) ELSE B.품명 END AS model
		        , N'해외'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , B.원화판매금액   AS amt
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		
		    /*UNION ALL
		
		    -- 기타매출(원천이 DOI_SLCO면 품번이 없으니 별도 라벨)
		    SELECT
		          S.SITE
				, S.구분 AS 구분
		        , NULL AS 품번
		        , S.model
		        , N'*' AS 매출구분
		        , N'기타' AS 매출대분류
		        , ISNULL(S.out_amt,0) AS amt
		    FROM DOI_SLCO S WITH(NOLOCK)
		    WHERE S.YYYYMM = @YYYYMM
		      AND S.SITE   = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.expen_sel명 = N'기타매출'*/
        )
        , SALES_BASE AS (
            ------------------------------------------------------------------
            -- (2) 모델별 매출 집계
            ------------------------------------------------------------------
            SELECT
		          구분
		        , model, 매출대분류
		        , SUM(CASE WHEN 매출대분류 = N'제품' THEN amt ELSE 0 END) AS prod_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'상품' THEN amt ELSE 0 END) AS merch_sale_amt
		        --, SUM(CASE WHEN 매출대분류 = N'기타' THEN amt ELSE 0 END) AS etc_sale_amt
		        , SUM(amt) AS total_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'국내' THEN amt ELSE 0 END) AS domestic_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'해외' THEN amt ELSE 0 END) AS export_sale_amt
		    FROM SALES_RAW
		    GROUP BY 구분, model, 매출대분류
        )
		, MERCH_SALES AS (
		    SELECT
		          S.구분
		        , S.model
		        , SUM(S.amt) AS merch_sale_amt
		    FROM SALES_RAW S
		    INNER JOIN DOI_MATL_RESC M WITH(NOLOCK)
		      ON M.YYYYMM = @YYYYMM
		     AND M.SITE   = @SITE
		     AND M.SEL_CODE = @SEL_CODE
		     AND M.품목자산분류 = N'상품'
		     AND M.품번 = S.품번
		    WHERE S.품번 IS NOT NULL
		    GROUP BY S.구분, S.model
		)
		, MERCH_SALES_SUM AS (
		    SELECT SUM(merch_sale_amt) AS merch_sale_total
		    FROM MERCH_SALES
		)
		, MERCH_COGS_TOTAL AS (
		    SELECT SUM(ISNULL(출고금액,0)) AS merch_cogs_total
		    FROM DOI_MATL_RESC WITH(NOLOCK)
		    WHERE YYYYMM = @YYYYMM
		      AND SITE   = @SITE
		      AND SEL_CODE = @SEL_CODE
		      AND 품목자산분류 = N'상품'
		)
		, MERCH_COGS_ALLOC AS (
		    SELECT
		          MS.구분
		        , MS.model
		        , CASE
		            WHEN MSS.merch_sale_total = 0 THEN 0
		            ELSE MCT.merch_cogs_total * (MS.merch_sale_amt / MSS.merch_sale_total)
		          END AS merch_cogs_amt
		    FROM MERCH_SALES MS
		    CROSS JOIN MERCH_SALES_SUM MSS
		    CROSS JOIN MERCH_COGS_TOTAL MCT
		)        
		, STCO_BASE AS (
		    SELECT
		        S.구분 AS 구분
		        , S.MODEL AS model
		        , SUM(ISNULL(S.BOH_AMT, 0)) AS begin_fg_amt
		        , SUM(ISNULL(S.IN_AMT, 0))  AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , SUM(ISNULL(S.EOH_AMT, 0)) AS end_fg_amt
		        , SUM(S.out_amt) AS prod_cogs_amt --select *
		    FROM DOI_STCO S
		    WHERE S.YYYYMM   = @YYYYMM
		      AND S.SITE     = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.COST_TYPE != 'LOSS'
		    GROUP BY S.구분, S.MODEL
		)
		, STCO_OUTETC AS (
			SELECT
			      구분
			    , MODEL AS model
			    , SUM(
			        CASE
			            WHEN 구분 = N'양산'
			            THEN -ISNULL(OUTETC_AMT,0)
			            ELSE  ISNULL(OUTETC_AMT,0)
			        END
			      ) AS outetc_amt
			FROM DOI_STCO
			WHERE YYYYMM = @YYYYMM
			  AND SITE = @SITE
			  AND SEL_CODE = @SEL_CODE
			  AND ISNULL(OUTETC_AMT,0) <> 0
			GROUP BY 구분, MODEL
		)
		, COGS_BASE AS (
		    -- 1) STCO 있는 모델: 상품원가 붙이기
		    SELECT
		          S.구분
		        , S.model
		        , S.begin_fg_amt
		        , S.cur_mfg_cost_amt
		        , S.trans_out_amt
		        , S.end_fg_amt
		        , ISNULL(MCA.merch_cogs_amt,0) AS merch_cogs_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS merch_purchase_amt
		        , S.prod_cogs_amt
		    FROM STCO_BASE S
		    LEFT JOIN MERCH_COGS_ALLOC MCA
		      ON MCA.구분  = S.구분   
		      AND MCA.model = S.model
		
		    UNION ALL
		
		    -- 2) STCO 없는 모델(상품만 판매된 품명): 행을 새로 만들어서 상품원가만 넣기
		    SELECT
		          MCA.구분
		        , MCA.model
		        , CAST(0 AS DECIMAL(18,2)) AS begin_fg_amt
		        , CAST(0 AS DECIMAL(18,2)) AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , CAST(0 AS DECIMAL(18,2)) AS end_fg_amt
		        , ISNULL(MCA.merch_cogs_amt,0) AS merch_cogs_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS merch_purchase_amt
		        , CAST(0 AS DECIMAL(18,2)) AS prod_cogs_amt
		    FROM MERCH_COGS_ALLOC MCA
		    WHERE NOT EXISTS (
		        SELECT 1
		        FROM STCO_BASE S
		        WHERE S.구분 = MCA.구분
		      AND S.model = MCA.model
		    )
		)
		, COGS_ADJ AS (
		    SELECT
		        a.구분 AS 구분
		        , a.model
		        , SUM(a.out_amt) AS adj_amt
		    FROM DOI_SLCO a WITH(NOLOCK)
		    WHERE a.YYYYMM = @YYYYMM
		      AND a.SITE   = @SITE
		      AND a.SEL_CODE = @SEL_CODE
		      AND a.expen_sel명 = N'기타매출'
		    GROUP BY a.구분, a.model
		)
        , SGNA_BASE AS (
            ------------------------------------------------------------------
            -- (4) 판관비
            ------------------------------------------------------------------
            SELECT
            	구분
                , MODEL           AS model
                , SUB_NAME
                , SUM(ISNULL(DIST_AMT,0)) AS amt      -- 배부된 판관비 금액
            FROM DOI_SMCE_COST
            WHERE YYYYMM 	= @YYYYMM
              AND SITE 		= @SITE
              AND SEL_CODE  = @SEL_CODE 
            GROUP BY 구분, MODEL, SUB_NAME
        )
        , SGNA_SUM AS (
            ------------------------------------------------------------------
            -- (5) 모델별 판관비 합계
            ------------------------------------------------------------------
            SELECT
                  구분, model
                , SUM(amt) AS sgna_amt
            FROM SGNA_BASE
            GROUP BY 구분, model
        )
		, SCOF_BASE AS (
		    SELECT
		          M.구분
		        , M.model
		        , CAST(COALESCE(XX.scof_amt,0) AS DECIMAL(18,2)) AS scof_amt
		    FROM #MODEL M
		    LEFT JOIN (
		        SELECT
		              구분
		            , 모델 AS model
		            , SUM(COALESCE(매출상계,0)) AS scof_amt
		        FROM DOI_원장상계
		        where  1=1
				   AND YYYYMM = @YYYYMM
				   AND SITE   = @SITE
				   AND SEL_CODE = @SEL_CODE
		        GROUP BY 구분, 모델
		    ) XX
		       ON XX.model = M.model
		      AND XX.구분 = M.구분
		)        

        ----------------------------------------------------------------------
        -- 6. PL 헤더(I~III, IV 합계, V 영업이익) : PL_HEAD
        ----------------------------------------------------------------------
        , PL_HEAD AS (
            ------------------------------------------------------------------
            --  I. 매출액
            ------------------------------------------------------------------
            SELECT 1 rn, '  I. 매출액' AS gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0) AS amt FROM #MODEL M 
        LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
			LEFT JOIN SCOF_BASE  SC ON SC.model = M.model AND SC.구분 = M.구분
 			-- WHERE S.매출대분류 != '기타'			
            UNION ALL
   			SELECT 2 rn, '    (1) 제품매출' gubun, M.구분, M.model, ISNULL(S.prod_sale_amt,0) FROM #MODEL M 
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분
            UNION ALL
            SELECT 3 rn, '    (2) 유상사급' gubun, M.구분, M.model, ISNULL(SC.scof_amt,0) AS amt FROM #MODEL M 
			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
            UNION ALL
            SELECT 4 rn, '    (3) 상품매출' gubun, M.구분, M.model, ISNULL(S.merch_sale_amt,0) FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분

            ------------------------------------------------------------------
            --  II. 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 5 rn, '  II. 매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(E.outetc_amt,0) /*- ISNULL(SC.scof_amt,0)*/ AS amt 
            FROM #MODEL M 
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
 			LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분  = M.구분
-- 			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
            UNION ALL
            SELECT 6 rn, '    (1) 제품매출원가' gubun, M.구분, M.model, ISNULL(C.prod_cogs_amt,0)  + ISNULL(A.adj_amt,0) + ISNULL(E.outetc_amt,0)  AS amt FROM #MODEL M 
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분 and C.구분 = M.구분
            LEFT JOIN COGS_ADJ  A ON A.model = M.model AND A.구분 = M.구분
            LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분  = M.구분
            UNION ALL
            SELECT 11 rn, '    (2) 상품매출원가' gubun, M.구분, M.model, C.merch_cogs_amt FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
            UNION ALL
            SELECT 12 rn, '    (3) 제품매출원가조정' gubun, M.구분, M.model, ISNULL(A.adj_amt,0) AS amt FROM #MODEL M
            LEFT JOIN COGS_ADJ  A ON A.model = M.model AND A.구분 = M.구분       
            ------------------------------------------------------------------
            --  III. 매출총이익 = 매출액 - 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 13 rn, '  III. 매출총이익' gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)
            - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(E.outetc_amt,0) + ISNULL(D.adj_amt,0) )  AS amt
			FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분            
			LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분  --where M.model='818U'
			LEFT JOIN COGS_ADJ D ON D.model = M.model and D.구분 = M.구분
			LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분 = M.구분
			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
			------------------------------------------------------------------
            --  IV. 판매비와관리비 (전체 합계)
            ------------------------------------------------------------------
            UNION ALL
            SELECT 14 rn, '  IV. 판매비와관리비' gubun, M.구분, M.model, ISNULL(G.sgna_amt,0) AS amt FROM #MODEL M
            LEFT JOIN SGNA_SUM G ON G.model = M.model and G.구분 = M.구분
            ------------------------------------------------------------------
            --  V. 영업이익 = 매출총이익 - 판관비
            ------------------------------------------------------------------
            UNION ALL
            SELECT 141 rn, '  V. 영업이익'+REPLICATE(NCHAR(0x3000),7) gubun, M.구분, M.model, ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)
        - ( ISNULL(C.prod_cogs_amt,0) + ISNULL(C.merch_cogs_amt,0) + ISNULL(D.adj_amt,0) + ISNULL(E.outetc_amt,0) ) - ISNULL(G.sgna_amt,0)  AS amt 
            FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model = M.model and S.구분 = M.구분           
            LEFT JOIN COGS_BASE C ON C.model = M.model and C.구분 = M.구분
			LEFT JOIN COGS_ADJ D ON D.model = M.model and D.구분 = M.구분
            LEFT JOIN SGNA_SUM G ON G.model = M.model and G.구분 = M.구분
            LEFT JOIN STCO_OUTETC E ON E.model = M.model AND E.구분 = M.구분
			LEFT JOIN SCOF_BASE SC ON SC.model = M.model AND SC.구분 = M.구분
        )

        ----------------------------------------------------------------------
        -- 7. 판관비 세부 항목(이미지 기준 풀버전) : PL_SGNA
        ----------------------------------------------------------------------
        -- 판관비 세부: 고정 27항목 골격 (집계표 VN_SalesAdminByModel과 동일 목록/순서)
        , SGNA_SKEL AS (
            SELECT seq, item FROM (VALUES
                (1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
                (6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
                (11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
                (16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
                (21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
                (26,N'판)잡비'),(27,N'기술이전비 및 기술지원비'),(28,N'판)외주용역비')
            ) v(seq,item)
        )
        , SGNA_AMT AS (
            -- doi_smce_cost → doi_dept_cost(판관) 브리지 → doi_acct.상위계정과목(경영계획 우선), 모델별 dist_amt 합
            SELECT B.구분, B.model,
                   COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목) AS item,
                   SUM(ISNULL(B.dist_amt,0)) AS amt
            FROM doi_smce_cost B WITH (NOLOCK)
            JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분 = N'판관' GROUP BY yyyymm, site, 계정과목) dc
                ON dc.yyyymm = B.yyyymm AND dc.site = B.site AND dc.계정과목 = B.sub_name
            JOIN doi_acct A WITH (NOLOCK)
                ON A.yyyymm = B.yyyymm AND A.site = B.site AND A.acct = dc.계정코드
            WHERE B.YYYYMM = @YYYYMM AND B.SITE = @SITE AND B.SEL_CODE = @SEL_CODE
              AND ISNULL(COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목),N'') <> N''
            GROUP BY B.구분, B.model, COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목)
        )
        , PL_SGNA AS (
            SELECT
                14 + SK.seq AS rn,
                N'    (' + CAST(SK.seq AS varchar(2)) + N') ' + SK.item AS gubun,
                M.구분,
                M.model,
                CAST(ISNULL(SUM(AM.amt), 0) AS DECIMAL(18, 2)) AS amt
            FROM SGNA_SKEL SK
            CROSS JOIN #MODEL M
            LEFT JOIN SGNA_AMT AM ON AM.구분 = M.구분 AND AM.model = M.model AND AM.item = SK.item
            GROUP BY SK.seq, SK.item, M.구분, M.model
        )

        ----------------------------------------------------------------------
        -- 8. PL_HEAD + PL_SGNA 통합 소스 : PL_SOURCE
        ----------------------------------------------------------------------
        , PL_SOURCE AS (
            SELECT rn, gubun, 구분, model, amt
            FROM PL_HEAD

            UNION ALL

   SELECT rn, gubun, 구분, model, amt
            FROM PL_SGNA
        )

        ----------------------------------------------------------------------
        -- 9. PL_SOURCE → #sourceTable
        ----------------------------------------------------------------------
        SELECT
        	구분
            , model
            , rn
            , gubun
            , amt
        INTO #sourceTable
        FROM PL_SOURCE;
       
        ----------------------------------------------------------------------
        -- 10. Z합계 행 추가
        ----------------------------------------------------------------------
        INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
        SELECT
        	'' as 구분
            ,  N'Z합계' AS model
            , rn
		    , gubun
            , SUM(amt) AS amt
        FROM #sourceTable
        GROUP BY rn, gubun order by rn;
       
--		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
--		VALUES (N'', N'Z합계', 12, N'    (3) 제품매출원가조정', @CostAdj + @LossAdj);
		
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) /*+ @CostAdj + @LossAdj*/
		WHERE model = N'Z합계'
		  AND rn = 5;
		
--		UPDATE #sourceTable
--		SET amt = COALESCE(amt,0) - @SCOFTotal--- (@CostAdj + @LossAdj)
--		WHERE model = N'Z합계'
--		  AND rn = 13;
		
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) -- - (@CostAdj + @LossAdj)
		WHERE model = N'Z합계'
		  AND rn = 141;	

       -- 개발 모델 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'개발' AS 구분,
		    N'Z합계개발' AS model,
		    rn,
		    gubun,
		    SUM(amt) AS amt
		FROM #sourceTable
		WHERE 구분 = N'개발'
		GROUP BY rn, 구분, gubun;
		
		-- 양산 모델 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'양산' AS 구분,
		    N'Z합계양산' AS model,
		    rn,
		    gubun,
		    SUM(amt) AS amt
		FROM #sourceTable
		WHERE 구분 = N'양산'
		GROUP BY rn, 구분, gubun;
	
		-- 카세트 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'카세트',
		    N'Z합계카세트',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'카세트'
		GROUP BY rn, gubun;
		
		-- 구매 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'구매',
		    N'Z합계구매',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'구매'
		GROUP BY rn, gubun;	
	
/*		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		VALUES (N'', N'Z합계', 3, N'    (2) 유상사급', @SCOFTotal);
	
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) - @SCOFTotal
		WHERE model = N'Z합계'
		  AND rn    = 1
		  AND gubun = N'  I. 매출액';*/
       
        ----------------------------------------------------------------------
        -- 11. PIVOT용 컬럼
        ----------------------------------------------------------------------
		;WITH COLS AS (
		    SELECT DISTINCT
		        sort_key = CASE 
		                     WHEN 구분 = N'양산'   THEN 10
		                     WHEN 구분 = N'개발'   THEN 20
		                     WHEN 구분 = N'카세트' THEN 30
		                     WHEN 구분 = N'구매'   THEN 40
		                     ELSE 99
		                   END,
		        model_sort = model,
		        col_name = 구분 + model
		    FROM #MODEL
		    WHERE model != ''  --202604월 이전 유상사급 때문에 
		
		    UNION ALL SELECT 910, N'ZZZ', N'양산Z합계양산'
		    UNION ALL SELECT 920, N'ZZZ', N'개발Z합계개발'
		   UNION ALL SELECT 930, N'ZZZ', N'카세트Z합계카세트'
		    UNION ALL SELECT 940, N'ZZZ', N'구매Z합계구매'
		    UNION ALL SELECT 999, N'ZZZ', N'Z합계'
		)
		SELECT
		    @Columns = STRING_AGG(QUOTENAME(col_name), N', ')
		              WITHIN GROUP (ORDER BY sort_key, model_sort, col_name),
		    @PivotColumns = STRING_AGG(
		                      N'COALESCE(' + QUOTENAME(col_name) + N',0) AS ' + QUOTENAME(col_name),
		                      N', '
		                   )
		                   WITHIN GROUP (ORDER BY sort_key, model_sort, col_name)
		FROM COLS;
        
        ----------------------------------------------------------------------
        -- 12. 동적 PIVOT 실행
        ----------------------------------------------------------------------
        SET @SQL = N'
            SELECT 
                P.rn,
                P.gubun,
                ' + @PivotColumns + '
            FROM (
                SELECT rn, gubun, 구분+model as model, amt
                FROM #sourceTable
         ) AS S
            PIVOT (
                SUM(amt) FOR model IN (' + @Columns + ')
            ) AS P
            ORDER BY P.rn;
        ';
		print @SQL;
        EXEC sp_executesql @SQL;


        DROP TABLE #sourceTable;
        DROP TABLE #MODEL;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
     IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;

GO

-- ==========================================
-- File: VN_PL_ByModel_Detail.sql
-- ==========================================
CREATE OR ALTER PROCEDURE VN_PL_ByModel_Detail
(
    @YYYYMM VARCHAR(6),
    @SITE VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

       	DECLARE @PivotColumns NVARCHAR(MAX);
        DECLARE @Columns     NVARCHAR(MAX);
        DECLARE @SQL         NVARCHAR(MAX);
       	DECLARE @SCOFTotal DECIMAL(18,2) = 0;
		DECLARE @CostAdj     DECIMAL(18,2) = 0;
		DECLARE @LossAdj     DECIMAL(18,2) = 0;    	

       	DROP TABLE IF EXISTS #MODEL;

        ----------------------------------------------------------------------
        -- 1. 모델 목록 (#MODEL)
        ----------------------------------------------------------------------
		;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SEL_CODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),
		MODEL_LIST AS (
		    -- 국내(매출)
		    SELECT DISTINCT
		        CASE 
		          WHEN A.품번 LIKE N'VN%' THEN N'카세트'
		          WHEN MI.품번 IS NOT NULL THEN N'구매'
		          WHEN RIGHT(A.품번,1)='P' THEN N'양산'
		          ELSE N'개발'
		        END AS 구분,
		        CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		      AND A.SITE   = @SITE
		
		    UNION
		
		    -- 해외(인보이스)
		    SELECT DISTINCT
		        CASE 
		          WHEN B.품번 LIKE N'VN%' THEN N'카세트'
		          WHEN MI.품번 IS NOT NULL THEN N'구매'
		          WHEN RIGHT(B.품번,1)='P' THEN N'양산'
		          ELSE N'개발'
		        END AS 구분,
		        CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번) - 1) ELSE B.품명 END AS model
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		      
		 UNION
		 
		 SELECT C.구분, C.MODEL
		 FROM DOI_STCO C
		    WHERE C.YYYYMM = @YYYYMM
		      AND C.SITE   = @SITE
		      AND C.SEL_CODE = @SEL_CODE
		      AND C.MODEL = 'EXTRA'
		UNION 
		SELECT 구분, MODEL
		FROM DOI_STCO
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND ACCT_NAME LIKE '기타출고'
		
		UNION
		
		SELECT
			O.구분,O.모델 AS model
		FROM DOI_원장상계 O
		WHERE 1=1
		   AND YYYYMM = @YYYYMM
		   AND SITE   = @SITE
		   AND SEL_CODE = @SEL_CODE
		   AND COALESCE(O.매출상계,0) <> 0
		)  
		SELECT DISTINCT
		    model, 구분
		INTO #MODEL
		FROM MODEL_LIST;

		SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
		FROM DOI_SCOF WITH(NOLOCK)
		WHERE yyyymm   = @YYYYMM
		  AND site     = @SITE
		  AND SEL_CODE = @SEL_CODE;

		SELECT @CostAdj = COALESCE(ABS(SUM(ISNULL(대변금액,0))), 0)
		FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE
		  AND 계정과목 = N'제품매출원가'
		  AND 대변금액 <> 0;		 
		 
		SELECT @LossAdj = COALESCE(SUM(COALESCE(LOSS,0)), 0)
		FROM DOI_COST WITH(NOLOCK)
		WHERE YYYYMM   = @YYYYMM
		  AND SITE     = @SITE
		  AND SEL_CODE = @SEL_CODE; 
		 
		-- ===== 금융/영업외/법인세 (회사 전체 → 총합계 컬럼 전용) =====
		DECLARE @FinInc_Int DECIMAL(18,2)=0, @FinInc_FX DECIMAL(18,2)=0;
		DECLARE @FinCost_Int DECIMAL(18,2)=0, @FinCost_FX DECIMAL(18,2)=0;
		DECLARE @NonOpInc DECIMAL(18,2)=0, @NonOpCost DECIMAL(18,2)=0, @CorpTax DECIMAL(18,2)=0;
		SELECT @FinInc_Int = COALESCE(SUM(CASE WHEN 계정과목=N'이자수익' THEN 대변금액 ELSE 0 END),0),
		       @FinInc_FX  = COALESCE(SUM(CASE WHEN 계정과목 LIKE N'%환차익%' THEN 대변금액 ELSE 0 END),0)
		FROM DOI_DEPT_COST WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND LEFT(계정코드,3)=N'515';
		SELECT @FinCost_Int = COALESCE(SUM(CASE WHEN 계정과목 LIKE N'%이자비용%' THEN 차변금액 ELSE 0 END),0),
		       @FinCost_FX  = COALESCE(SUM(CASE WHEN 계정과목 LIKE N'%환차손%' THEN 차변금액 ELSE 0 END),0)
		FROM DOI_DEPT_COST WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND LEFT(계정코드,3)=N'635';
		SELECT @NonOpInc  = COALESCE(SUM(대변금액),0) FROM DOI_DEPT_COST WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND LEFT(계정코드,3)=N'711';
		SELECT @NonOpCost = COALESCE(SUM(차변금액),0) FROM DOI_DEPT_COST WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND LEFT(계정코드,3)=N'811';
		SELECT @CorpTax   = COALESCE(SUM(차변금액),0) FROM DOI_DEPT_COST WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND LEFT(계정코드,3)=N'821';
		-- 재고흐름(회사 전체 doi_stco) — 기초/당기제조/타계정/기말 총합계 정확화용
		DECLARE @BOH_T DECIMAL(18,2)=0, @IN_T DECIMAL(18,2)=0, @OUTETC_T DECIMAL(18,2)=0, @EOH_T DECIMAL(18,2)=0;
		SELECT @BOH_T=COALESCE(SUM(BOH_AMT),0), @IN_T=COALESCE(SUM(IN_AMT),0),
		       @OUTETC_T=COALESCE(SUM(OUTETC_AMT),0), @EOH_T=COALESCE(SUM(EOH_AMT),0)
		FROM DOI_STCO WITH(NOLOCK) WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND COST_TYPE<>'LOSS';
		-- 기타매출 = DOI_DEPT_COST 계정코드 5118000 대변금액 합 (회사 전체 → 총합계 전용)
		DECLARE @EtcSale DECIMAL(18,2)=0;
		SELECT @EtcSale = COALESCE(SUM(대변금액),0) FROM DOI_DEPT_COST WITH(NOLOCK)
		WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND 계정코드='5118000';

		DROP TABLE IF EXISTS #sourceTable;
		 ;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SEL_CODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),
        ----------------------------------------------------------------------
        -- 2~5. 연간 매출 / 매출원가 / 판관비
        ----------------------------------------------------------------------
        SALES_RAW AS (
            ------------------------------------------------------------------
            -- (1) 매출 : 국내/해외
            ------------------------------------------------------------------
		    -- 국내매출
		    SELECT
		          A.SITE
		        , CASE 
			          WHEN A.품번 LIKE N'VN%' THEN N'카세트'
			          WHEN MI.품번 IS NOT NULL THEN N'구매'
			          WHEN RIGHT(A.품번,1)='P' THEN N'양산'
		          	ELSE N'개발'
		          END AS 구분
		        , A.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , N'국내'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , A.원화판매금액   AS amt
		    FROM DOI_SALE_RESC A
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		 AND A.SITE   = @SITE
		
		    UNION ALL
		
		    -- 해외매출
		    SELECT
		          B.SITE
		        , CASE 
			          WHEN B.품번 LIKE N'VN%' THEN N'카세트'
			          WHEN MI.품번 IS NOT NULL THEN N'구매'
			       WHEN RIGHT(B.품번,1)='P' THEN N'양산'
		          	ELSE N'개발'
		          END AS 구분
		        , B.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번) - 1) ELSE B.품명 END AS model
		        , N'해외'          AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , B.원화판매금액   AS amt
		    FROM DOI_INVOICE_RESC B
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		
		    /*UNION ALL
		
		    -- 기타매출(원천이 DOI_SLCO면 품번이 없으니 별도 라벨)
		    SELECT
		          S.SITE
				, S.구분 AS 구분
		        , NULL AS 품번
		        , S.model
		        , N'*' AS 매출구분
		        , N'기타' AS 매출대분류
		        , ISNULL(S.out_amt,0) AS amt
		    FROM DOI_SLCO S WITH(NOLOCK)
		    WHERE S.YYYYMM = @YYYYMM
		      AND S.SITE   = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.expen_sel명 = N'기타매출'*/
        )
        , SALES_BASE AS (
            ------------------------------------------------------------------
            -- (2) 모델별 매출 집계
            ------------------------------------------------------------------
            SELECT
		          구분
		        , model, 매출대분류
		        , SUM(CASE WHEN 매출대분류 = N'제품' THEN amt ELSE 0 END) AS prod_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'상품' THEN amt ELSE 0 END) AS merch_sale_amt
		        --, SUM(CASE WHEN 매출대분류 = N'기타' THEN amt ELSE 0 END) AS etc_sale_amt
		        , SUM(amt) AS total_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'국내' THEN amt ELSE 0 END) AS domestic_sale_amt
		        , SUM(CASE WHEN 매출구분 = N'해외' THEN amt ELSE 0 END) AS export_sale_amt
		    FROM SALES_RAW
		    GROUP BY 구분, model, 매출대분류
        )
		, MERCH_SALES AS (
		    SELECT
		          S.구분
		        , S.model
		        , SUM(S.amt) AS merch_sale_amt
		    FROM SALES_RAW S
		    INNER JOIN DOI_MATL_RESC M WITH(NOLOCK)
		      ON M.YYYYMM = @YYYYMM
		     AND M.SITE   = @SITE
		     AND M.SEL_CODE = @SEL_CODE
		     AND M.품목자산분류 = N'상품'
		     AND M.품번 = S.품번
		    WHERE S.품번 IS NOT NULL
		    GROUP BY S.구분, S.model
		)
		, MERCH_SALES_SUM AS (
		    SELECT SUM(merch_sale_amt) AS merch_sale_total
		    FROM MERCH_SALES
		)
		, MERCH_COGS_TOTAL AS (
		    SELECT SUM(ISNULL(출고금액,0)) AS merch_cogs_total
		    FROM DOI_MATL_RESC WITH(NOLOCK)
		    WHERE YYYYMM = @YYYYMM
		      AND SITE   = @SITE
		      AND SEL_CODE = @SEL_CODE
		      AND 품목자산분류 = N'상품'
		)
		, MERCH_COGS_ALLOC AS (
		    SELECT
		          MS.구분
		        , MS.model
		        , CASE
		            WHEN MSS.merch_sale_total = 0 THEN 0
		            ELSE MCT.merch_cogs_total * (MS.merch_sale_amt / MSS.merch_sale_total)
		          END AS merch_cogs_amt
		    FROM MERCH_SALES MS
		    CROSS JOIN MERCH_SALES_SUM MSS
		    CROSS JOIN MERCH_COGS_TOTAL MCT
		)        
		, STCO_BASE AS (
		    SELECT
		        S.구분 AS 구분
		        , S.MODEL AS model
		        , SUM(ISNULL(S.BOH_AMT, 0)) AS begin_fg_amt
		        , SUM(ISNULL(S.IN_AMT, 0))  AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , SUM(ISNULL(S.EOH_AMT, 0)) AS end_fg_amt
		        , SUM(S.out_amt) AS prod_cogs_amt --select *
		    FROM DOI_STCO S
		    WHERE S.YYYYMM   = @YYYYMM
		      AND S.SITE     = @SITE
		      AND S.SEL_CODE = @SEL_CODE
		      AND S.COST_TYPE != 'LOSS'
		    GROUP BY S.구분, S.MODEL
		)
		, STCO_OUTETC AS (
			SELECT
			      구분
			    , MODEL AS model
			    , SUM(
			        CASE
			            WHEN 구분 = N'양산'
			            THEN -ISNULL(OUTETC_AMT,0)
			            ELSE  ISNULL(OUTETC_AMT,0)
			        END
			      ) AS outetc_amt
			FROM DOI_STCO
			WHERE YYYYMM = @YYYYMM
			  AND SITE = @SITE
			  AND SEL_CODE = @SEL_CODE
			  AND ISNULL(OUTETC_AMT,0) <> 0
			GROUP BY 구분, MODEL
		)
		, COGS_BASE AS (
		    -- 1) STCO 있는 모델: 상품원가 붙이기
		    SELECT
		          S.구분
		        , S.model
		        , S.begin_fg_amt
		        , S.cur_mfg_cost_amt
		        , S.trans_out_amt
		        , S.end_fg_amt
		        , ISNULL(MCA.merch_cogs_amt,0) AS merch_cogs_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS merch_purchase_amt
		        , S.prod_cogs_amt
		    FROM STCO_BASE S
		    LEFT JOIN MERCH_COGS_ALLOC MCA
		      ON MCA.구분  = S.구분   
		      AND MCA.model = S.model
		
		    UNION ALL
		
		    -- 2) STCO 없는 모델(상품만 판매된 품명): 행을 새로 만들어서 상품원가만 넣기
		    SELECT
		          MCA.구분
		        , MCA.model
		        , CAST(0 AS DECIMAL(18,2)) AS begin_fg_amt
		        , CAST(0 AS DECIMAL(18,2)) AS cur_mfg_cost_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS trans_out_amt
		        , CAST(0 AS DECIMAL(18,2)) AS end_fg_amt
		        , ISNULL(MCA.merch_cogs_amt,0) AS merch_cogs_amt
		        , CAST(NULL AS DECIMAL(18,2)) AS merch_purchase_amt
		        , CAST(0 AS DECIMAL(18,2)) AS prod_cogs_amt
		    FROM MERCH_COGS_ALLOC MCA
		    WHERE NOT EXISTS (
		        SELECT 1
		        FROM STCO_BASE S
		        WHERE S.구분 = MCA.구분
		      AND S.model = MCA.model
		    )
		)
		, COGS_ADJ AS (
		    SELECT
		        a.구분 AS 구분
		        , a.model
		        , SUM(a.out_amt) AS adj_amt
		    FROM DOI_SLCO a WITH(NOLOCK)
		    WHERE a.YYYYMM = @YYYYMM
		      AND a.SITE   = @SITE
		      AND a.SEL_CODE = @SEL_CODE
		      AND a.expen_sel명 = N'기타매출'
		    GROUP BY a.구분, a.model
		)
        , SGNA_BASE AS (
            ------------------------------------------------------------------
            -- (4) 판관비
            ------------------------------------------------------------------
            SELECT
            	구분
                , MODEL           AS model
                , SUB_NAME
                , SUM(ISNULL(DIST_AMT,0)) AS amt      -- 배부된 판관비 금액
            FROM DOI_SMCE_COST
            WHERE YYYYMM 	= @YYYYMM
              AND SITE 		= @SITE
              AND SEL_CODE  = @SEL_CODE 
            GROUP BY 구분, MODEL, SUB_NAME
        )
        , SGNA_SUM AS (
            ------------------------------------------------------------------
            -- (5) 모델별 판관비 합계
            ------------------------------------------------------------------
            SELECT
                  구분, model
                , SUM(amt) AS sgna_amt
            FROM SGNA_BASE
            GROUP BY 구분, model
        )
        , SGNA_SPLIT AS (
            -- 판관비 641(판매비)/642(일반관리비) 분할 (doi_dept_cost 계정코드 브리지)
            SELECT B.구분, B.MODEL AS model,
                   SUM(CASE WHEN LEFT(dc.계정코드,3)=N'641' THEN ISNULL(B.DIST_AMT,0) ELSE 0 END) AS sell_amt,
                   SUM(CASE WHEN LEFT(dc.계정코드,3)=N'642' THEN ISNULL(B.DIST_AMT,0) ELSE 0 END) AS admin_amt
            FROM DOI_SMCE_COST B WITH(NOLOCK)
            JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드
                    FROM doi_dept_cost WHERE 비용구분=N'판관'
                    GROUP BY yyyymm, site, 계정과목) dc
              ON dc.yyyymm=B.yyyymm AND dc.site=B.site AND dc.계정과목=B.SUB_NAME
            WHERE B.YYYYMM=@YYYYMM AND B.SITE=@SITE AND B.SEL_CODE=@SEL_CODE
            GROUP BY B.구분, B.MODEL
        )
		, SCOF_BASE AS (
		    SELECT
		          M.구분
		        , M.model
		        , CAST(COALESCE(XX.scof_amt,0) AS DECIMAL(18,2)) AS scof_amt
		    FROM #MODEL M
		    LEFT JOIN (
		        SELECT
		              구분
		            , 모델 AS model
		            , SUM(COALESCE(매출상계,0)) AS scof_amt
		        FROM DOI_원장상계
		        where  1=1
				   AND YYYYMM = @YYYYMM
				   AND SITE   = @SITE
				   AND SEL_CODE = @SEL_CODE
		        GROUP BY 구분, 모델
		    ) XX
		       ON XX.model = M.model
		      AND XX.구분 = M.구분
		)        

        ----------------------------------------------------------------------
        -- 6. PL 헤더(I~III, IV 합계, V 영업이익) : PL_HEAD
        ----------------------------------------------------------------------
        , PL_HEAD AS (
            ------------------------------------------------------------------
            --  1. 매출액 (= 제품매출 + 기타매출[총합계])
            ------------------------------------------------------------------
            SELECT 100 rn, N'  1. 매출액' gubun, M.구분, M.model,
                   ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0) AS amt
            FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model=M.model AND S.구분=M.구분
            LEFT JOIN SCOF_BASE  SC ON SC.model=M.model AND SC.구분=M.구분
            UNION ALL
            SELECT 101, N'    (2) 제품매출', M.구분, M.model, ISNULL(S.prod_sale_amt,0)
            FROM #MODEL M LEFT JOIN SALES_BASE S ON S.model=M.model AND S.구분=M.구분
            UNION ALL
            SELECT 102, N'      2. 제품매출-수출', M.구분, M.model, ISNULL(S.export_sale_amt,0)
            FROM #MODEL M LEFT JOIN SALES_BASE S ON S.model=M.model AND S.구분=M.구분
            UNION ALL
            SELECT 103, N'    (3) 기타매출', M.구분, M.model, CAST(0 AS DECIMAL(18,2))
            FROM #MODEL M
            UNION ALL
            SELECT 104, N'      1. 기타매출', M.구분, M.model, CAST(0 AS DECIMAL(18,2))
            FROM #MODEL M

            ------------------------------------------------------------------
            --  2. 매출에누리
            ------------------------------------------------------------------
            UNION ALL
            SELECT 200, N'  2. 매출에누리', M.구분, M.model, CAST(0 AS DECIMAL(18,2))
            FROM #MODEL M

            ------------------------------------------------------------------
            --  3. 순매출액 = 매출액 - 매출에누리
            ------------------------------------------------------------------
            UNION ALL
            SELECT 1000, N'  3. 순매출액', M.구분, M.model,
                   ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)
            FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model=M.model AND S.구분=M.구분
            LEFT JOIN SCOF_BASE  SC ON SC.model=M.model AND SC.구분=M.구분

            ------------------------------------------------------------------
            --  4. 매출원가 (재고흐름: 기초 + 당기제조 - 타계정대체 - 기말)
            ------------------------------------------------------------------
            UNION ALL
            SELECT 1100, N'  4. 매출원가', M.구분, M.model, ISNULL(C.prod_cogs_amt,0)
            FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model=M.model AND C.구분=M.구분
            UNION ALL
            SELECT 1101, N'    (1) 제품매출원가', M.구분, M.model, ISNULL(C.prod_cogs_amt,0)
            FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model=M.model AND C.구분=M.구분
            UNION ALL
            SELECT 1102, N'      1. 기초제품재고액', M.구분, M.model, ISNULL(C.begin_fg_amt,0)
            FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model=M.model AND C.구분=M.구분
            UNION ALL
            SELECT 1103, N'      2. 당기제품제조원가', M.구분, M.model, ISNULL(C.cur_mfg_cost_amt,0)
            FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model=M.model AND C.구분=M.구분
            UNION ALL
            SELECT 1104, N'      3. 타계정으로제품대체액', M.구분, M.model,
                   -( ISNULL(C.begin_fg_amt,0)+ISNULL(C.cur_mfg_cost_amt,0)-ISNULL(C.end_fg_amt,0)-ISNULL(C.prod_cogs_amt,0) )
            FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model=M.model AND C.구분=M.구분
            UNION ALL
            SELECT 1105, N'      4. 기말제품재고액', M.구분, M.model, -ISNULL(C.end_fg_amt,0)
            FROM #MODEL M LEFT JOIN COGS_BASE C ON C.model=M.model AND C.구분=M.구분

            ------------------------------------------------------------------
            --  5. 매출이익 = 순매출액 - 매출원가
            ------------------------------------------------------------------
            UNION ALL
            SELECT 2000, N'  5. 매출이익', M.구분, M.model,
                   (ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)) - ISNULL(C.prod_cogs_amt,0)
            FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model=M.model AND S.구분=M.구분
            LEFT JOIN SCOF_BASE  SC ON SC.model=M.model AND SC.구분=M.구분
            LEFT JOIN COGS_BASE  C ON C.model=M.model AND C.구분=M.구분

            ------------------------------------------------------------------
            --  8. 판매비(641) / 9. 일반관리비(642)  — 세부항목은 주석처리
            ------------------------------------------------------------------
            UNION ALL
            SELECT 2400, N'  8. 판매비', M.구분, M.model, ISNULL(SP.sell_amt,0)
            FROM #MODEL M LEFT JOIN SGNA_SPLIT SP ON SP.model=M.model AND SP.구분=M.구분
            UNION ALL
            SELECT 2500, N'  9. 일반관리비', M.구분, M.model, ISNULL(SP.admin_amt,0)
            FROM #MODEL M LEFT JOIN SGNA_SPLIT SP ON SP.model=M.model AND SP.구분=M.구분

            ------------------------------------------------------------------
            --  10. 영업이익 = 매출이익 + (재무이익-재무비용) - (판매비+일반관리비)
            --      재무이익/비용은 회사 전체(총합계 전용 행)에서 가감
            ------------------------------------------------------------------
            UNION ALL
            SELECT 3000, N'  10. 영업이익', M.구분, M.model,
                   ((ISNULL(S.total_sale_amt,0) - ISNULL(SC.scof_amt,0)) - ISNULL(C.prod_cogs_amt,0))
                   - ISNULL(SP.sell_amt,0) - ISNULL(SP.admin_amt,0)
            FROM #MODEL M
            LEFT JOIN SALES_BASE S ON S.model=M.model AND S.구분=M.구분
            LEFT JOIN SCOF_BASE  SC ON SC.model=M.model AND SC.구분=M.구분
            LEFT JOIN COGS_BASE  C ON C.model=M.model AND C.구분=M.구분
            LEFT JOIN SGNA_SPLIT SP ON SP.model=M.model AND SP.구분=M.구분
        )

        ----------------------------------------------------------------------
        -- 7. 판관비 세부 항목(이미지 기준 풀버전) : PL_SGNA
        ----------------------------------------------------------------------
        -- 판관비 세부: 고정 27항목 골격 (집계표 VN_SalesAdminByModel과 동일 목록/순서)
        , SGNA_SKEL AS (
            SELECT seq, item FROM (VALUES
                (1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
                (6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
                (11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
                (16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
                (21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
                (26,N'판)잡비'),(27,N'기술이전비 및 기술지원비'),(28,N'판)외주용역비')
            ) v(seq,item)
        )
        , SGNA_AMT AS (
            -- doi_smce_cost → doi_dept_cost(판관) 브리지 → doi_acct.상위계정과목(경영계획 우선), 모델별 dist_amt 합
            SELECT B.구분, B.model,
                   COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목) AS item,
                   SUM(ISNULL(B.dist_amt,0)) AS amt
            FROM doi_smce_cost B WITH (NOLOCK)
            JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분 = N'판관' GROUP BY yyyymm, site, 계정과목) dc
                ON dc.yyyymm = B.yyyymm AND dc.site = B.site AND dc.계정과목 = B.sub_name
            JOIN doi_acct A WITH (NOLOCK)
                ON A.yyyymm = B.yyyymm AND A.site = B.site AND A.acct = dc.계정코드
            WHERE B.YYYYMM = @YYYYMM AND B.SITE = @SITE AND B.SEL_CODE = @SEL_CODE
              AND ISNULL(COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목),N'') <> N''
            GROUP BY B.구분, B.model, COALESCE(NULLIF(A.경영계획과목,N''),A.상위계정과목)
        )
        , PL_SGNA AS (
            SELECT
                40 + SK.seq AS rn,
                N'    (' + CAST(SK.seq AS varchar(2)) + N') ' + SK.item AS gubun,
                M.구분,
                M.model,
                CAST(ISNULL(SUM(AM.amt), 0) AS DECIMAL(18, 2)) AS amt
            FROM SGNA_SKEL SK
            CROSS JOIN #MODEL M
            LEFT JOIN SGNA_AMT AM ON AM.구분 = M.구분 AND AM.model = M.model AND AM.item = SK.item
            GROUP BY SK.seq, SK.item, M.구분, M.model
        )

        /* ======================================================================
           [보류] 판관비 세목(계정과목 단위) — 계산로직만 작성, 화면 미표시(주석)
             경로: doi_smce_cost(모델배부) → doi_dept_cost(판관) → doi_acct 계정과목
             부모 = 상위계정과목(판관 (n)항목), 세목 = ACCT_NAME(또는 경영계획과목)
             활성화 시: 아래 CTE 주석 해제 + rn을 부모(40+seq) 하위로 부여하여
                        PL_SOURCE에 UNION ALL 추가.
        , PL_SGNA_DETAIL AS (
            SELECT
                B.구분, B.model,
                A.상위계정과목 AS 판관항목,           -- 부모 (n) 항목
                COALESCE(NULLIF(A.경영계획과목,N''), A.ACCT_NAME) AS 세목,
                SUM(ISNULL(B.dist_amt,0)) AS amt
            FROM doi_smce_cost B WITH(NOLOCK)
            JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드
                    FROM doi_dept_cost WHERE 비용구분 = N'판관'
                    GROUP BY yyyymm, site, 계정과목) dc
              ON dc.yyyymm = B.yyyymm AND dc.site = B.site AND dc.계정과목 = B.sub_name
            JOIN doi_acct A WITH(NOLOCK)
              ON A.yyyymm = B.yyyymm AND A.site = B.site AND A.acct = dc.계정코드
            WHERE B.YYYYMM = @YYYYMM AND B.SITE = @SITE AND B.SEL_CODE = @SEL_CODE
              AND A.상위계정과목 LIKE N'판)%'
            GROUP BY B.구분, B.model, A.상위계정과목,
                     COALESCE(NULLIF(A.경영계획과목,N''), A.ACCT_NAME)
        )
        ====================================================================== */

        ----------------------------------------------------------------------
        -- 8. PL_HEAD + PL_SGNA 통합 소스 : PL_SOURCE
        ----------------------------------------------------------------------
        , PL_SOURCE AS (
            SELECT rn, gubun, 구분, model, amt
            FROM PL_HEAD
            -- [보류] 판관 세부항목(판)직원급여 등 28항목)은 화면 미표시 — 판매비/일반관리비는 합계만
            -- UNION ALL
            -- SELECT rn, gubun, 구분, model, amt FROM PL_SGNA
        )

        ----------------------------------------------------------------------
        -- 9. PL_SOURCE → #sourceTable
        ----------------------------------------------------------------------
        SELECT
        	구분
            , model
            , rn
            , gubun
            , amt
        INTO #sourceTable
        FROM PL_SOURCE;
       
        ----------------------------------------------------------------------
        -- 10. Z합계 행 추가
        ----------------------------------------------------------------------
        INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
        SELECT
        	'' as 구분
            ,  N'Z합계' AS model
            , rn
		    , gubun
            , SUM(amt) AS amt
        FROM #sourceTable
        GROUP BY rn, gubun order by rn;
       
--		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
--		VALUES (N'', N'Z합계', 12, N'    (3) 제품매출원가조정', @CostAdj + @LossAdj);
		
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) /*+ @CostAdj + @LossAdj*/
		WHERE model = N'Z합계'
		  AND rn = 5;
		
--		UPDATE #sourceTable
--		SET amt = COALESCE(amt,0) - @SCOFTotal--- (@CostAdj + @LossAdj)
--		WHERE model = N'Z합계'
--		  AND rn = 13;
		
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) -- - (@CostAdj + @LossAdj)
		WHERE model = N'Z합계'
		  AND rn = 141;

		-- 재고흐름 4항목: 총합계는 회사 전체 doi_stco 잔액으로 (모델별 컬럼은 출고발생 모델 커버분)
		UPDATE #sourceTable SET amt = @BOH_T     WHERE model=N'Z합계' AND rn=1102;   -- 기초제품재고액
		UPDATE #sourceTable SET amt = @IN_T      WHERE model=N'Z합계' AND rn=1103;   -- 당기제품제조원가
		UPDATE #sourceTable SET amt = -@OUTETC_T WHERE model=N'Z합계' AND rn=1104;   -- 타계정으로제품대체액
		UPDATE #sourceTable SET amt = -@EOH_T    WHERE model=N'Z합계' AND rn=1105;   -- 기말제품재고액

		-- (3) 기타매출 = 5118000 대변합 (총합계 전용) → 매출액/순매출액/매출이익/영업이익에 가산
		UPDATE #sourceTable SET amt = @EtcSale                     WHERE model=N'Z합계' AND rn IN (103,104);
		UPDATE #sourceTable SET amt = COALESCE(amt,0) + @EtcSale   WHERE model=N'Z합계' AND rn IN (100,1000,2000,3000);

		-- ===== 6.재무활동이익 / 7.재무활동비용 (회사 전체 → 총합계 컬럼 전용) =====
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt) VALUES
		  (N'', N'Z합계', 2100, N'  6. 재무활동으로 부터의 이익', @FinInc_Int + @FinInc_FX),
		  (N'', N'Z합계', 2200, N'  7. 재무활동으로부터의 비용',  @FinCost_Int + @FinCost_FX),
		  (N'', N'Z합계', 2300, N'    - 재무 비용',               @FinCost_Int + @FinCost_FX);
		-- 10. 영업이익(총합계) += (재무이익 - 재무비용)
		UPDATE #sourceTable
		   SET amt = COALESCE(amt,0) + (@FinInc_Int + @FinInc_FX) - (@FinCost_Int + @FinCost_FX)
		 WHERE model=N'Z합계' AND rn=3000;

       -- 개발 모델 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'개발' AS 구분,
		    N'Z합계개발' AS model,
		    rn,
		    gubun,
		    SUM(amt) AS amt
		FROM #sourceTable
		WHERE 구분 = N'개발'
		GROUP BY rn, 구분, gubun;
		
		-- 양산 모델 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'양산' AS 구분,
		    N'Z합계양산' AS model,
		    rn,
		    gubun,
		    SUM(amt) AS amt
		FROM #sourceTable
		WHERE 구분 = N'양산'
		GROUP BY rn, 구분, gubun;
	
		-- 카세트 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'카세트',
		    N'Z합계카세트',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'카세트'
		GROUP BY rn, gubun;
		
		-- 구매 합계
		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		SELECT
		    N'구매',
		    N'Z합계구매',
		    rn, gubun,
		    SUM(amt)
		FROM #sourceTable
		WHERE 구분 = N'구매'
		GROUP BY rn, gubun;	
	
/*		INSERT INTO #sourceTable (구분, model, rn, gubun, amt)
		VALUES (N'', N'Z합계', 3, N'    (2) 유상사급', @SCOFTotal);
	
		UPDATE #sourceTable
		SET amt = COALESCE(amt,0) - @SCOFTotal
		WHERE model = N'Z합계'
		  AND rn    = 1
		  AND gubun = N'  I. 매출액';*/
       
        ----------------------------------------------------------------------
        -- 11. PIVOT용 컬럼
        ----------------------------------------------------------------------
		;WITH COLS AS (
		    SELECT DISTINCT
		        sort_key = CASE 
		                     WHEN 구분 = N'양산'   THEN 10
		                     WHEN 구분 = N'개발'   THEN 20
		                     WHEN 구분 = N'카세트' THEN 30
		                     WHEN 구분 = N'구매'   THEN 40
		                     ELSE 99
		                   END,
		        model_sort = model,
		        col_name = 구분 + model
		    FROM #MODEL
		    WHERE model != ''  --202604월 이전 유상사급 때문에 
		
		    UNION ALL SELECT 910, N'ZZZ', N'양산Z합계양산'
		    UNION ALL SELECT 920, N'ZZZ', N'개발Z합계개발'
		   UNION ALL SELECT 930, N'ZZZ', N'카세트Z합계카세트'
		    UNION ALL SELECT 940, N'ZZZ', N'구매Z합계구매'
		    UNION ALL SELECT 999, N'ZZZ', N'Z합계'
		)
		SELECT
		    @Columns = STRING_AGG(QUOTENAME(col_name), N', ')
		              WITHIN GROUP (ORDER BY sort_key, model_sort, col_name),
		    @PivotColumns = STRING_AGG(
		                      N'COALESCE(' + QUOTENAME(col_name) + N',0) AS ' + QUOTENAME(col_name),
		                      N', '
		                   )
		                   WITHIN GROUP (ORDER BY sort_key, model_sort, col_name)
		FROM COLS;
        
        ----------------------------------------------------------------------
        -- 12. 동적 PIVOT 실행
        ----------------------------------------------------------------------
        SET @SQL = N'
            SELECT 
                P.rn,
                P.gubun,
                ' + @PivotColumns + '
            FROM (
                SELECT rn, gubun, 구분+model as model, amt
                FROM #sourceTable
         ) AS S
            PIVOT (
                SUM(amt) FOR model IN (' + @Columns + ')
            ) AS P
            ORDER BY P.rn;
     ';
		print @SQL;
        EXEC sp_executesql @SQL;


        DROP TABLE #sourceTable;
        DROP TABLE #MODEL;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
     IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;

GO

-- ==========================================
-- File: VN_PL_Qty.sql
-- ==========================================
CREATE OR ALTER PROCEDURE VN_PL_Qty
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4),
    @SEL_CODE VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;
    -- 제품별 손익계산서 '매출수량' : PL 금액(VN_PL_ByModel)과 동일 모델키(LEFT(품번,LEN-1))로 산출
    ;WITH MERCH_ITEM AS (
        SELECT DISTINCT M.품번
        FROM DOI_MATL_RESC M WITH(NOLOCK)
        WHERE M.YYYYMM = @YYYYMM AND M.SITE = @SITE AND M.SEL_CODE = @SEL_CODE
          AND M.품목자산분류 = N'상품' AND M.품번 IS NOT NULL
    )
    SELECT 구분, LTRIM(RTRIM(model)) AS model, SUM(qty) AS qty
    FROM (
        -- 국내매출
        SELECT
            CASE
              WHEN A.품번 LIKE N'VN%' THEN N'카세트'
              WHEN MI.품번 IS NOT NULL THEN N'구매'
              WHEN RIGHT(LTRIM(RTRIM(A.품번)),1)='P' THEN N'양산'
              ELSE N'개발'
            END AS 구분,
            CASE WHEN LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번)-1) ELSE LTRIM(RTRIM(A.품명)) END AS model,
            ISNULL(A.수량,0) AS qty
        FROM doi_sale_resc A WITH(NOLOCK)
        LEFT JOIN MERCH_ITEM MI ON MI.품번 = A.품번
        WHERE A.yyyymm = @YYYYMM AND A.site = @SITE

        UNION ALL

        -- 해외매출
        SELECT
            CASE
              WHEN B.품번 LIKE N'VN%' THEN N'카세트'
              WHEN MI.품번 IS NOT NULL THEN N'구매'
              WHEN RIGHT(LTRIM(RTRIM(B.품번)),1)='P' THEN N'양산'
              ELSE N'개발'
            END AS 구분,
            CASE WHEN LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번)-1) ELSE LTRIM(RTRIM(B.품명)) END AS model,
            ISNULL(B.수량,0) AS qty
        FROM doi_invoice_resc B WITH(NOLOCK)
        LEFT JOIN MERCH_ITEM MI ON MI.품번 = B.품번
        WHERE B.yyyymm = @YYYYMM AND B.site = @SITE
    ) A
    GROUP BY 구분, LTRIM(RTRIM(model))
    ORDER BY 구분 DESC, model;
END

GO

-- ==========================================
-- File: VN_SalesAdminByDept.sql
-- ==========================================
CREATE OR ALTER Procedure VN_SalesAdminByDept(
	@YYYYMM varchar(10),
	@SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

		-- 1) 금액(#vamt) : doi_dept_cost(판관, 센터채움 차변-대변) → doi_acct.상위계정과목
		IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
		SELECT LTRIM(RTRIM(d.코스트센터)) dept_name, COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목) item, SUM(d.차변금액) amt
		INTO #vamt
		FROM doi_dept_cost d
		JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.acct=d.계정코드
		WHERE d.yyyymm=@YYYYMM AND d.site=@SITE AND d.비용구분=N'판관'
		  AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
		  AND ISNULL(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),'')<>''
		GROUP BY LTRIM(RTRIM(d.코스트센터)), COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목);

		-- 2) 부서 목록 (데이터 부서 + 합계)
		IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
		SELECT dept_name, ord INTO #vdept FROM (
			SELECT DISTINCT dept_name, 1 ord FROM #vamt
			UNION SELECT N'합계', 2
		) t;

		-- 3) 고정항목
		IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
		CREATE TABLE #vskel(rn int, item nvarchar(200), gubun nvarchar(200));
		INSERT #vskel(rn, item, gubun)
		SELECT seq*10, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
		FROM (VALUES
			(1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
			(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
			(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
			(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
			(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
			(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비'),(28,N'판)외주용역비')
		) v(seq,item);
		INSERT #vskel(rn, item, gubun) VALUES (0, N'__T', N'합계');

		-- 4) 소스테이블
		IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
		;WITH item_amt AS (SELECT v.dept_name, sk.rn, SUM(v.amt) amt FROM #vamt v JOIN #vskel sk ON sk.item=v.item GROUP BY v.dept_name, sk.rn),
		 tot AS (SELECT dept_name, 0 rn, SUM(amt) amt FROM item_amt GROUP BY dept_name),
		 amt_all AS (SELECT * FROM item_amt UNION ALL SELECT * FROM tot)
		SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
		INTO #vsource
		FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
		LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

		-- 5) 동적 PIVOT (부서 컬럼)
		SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vColumns = N'[' + @vColumns + N']';
		SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce([' FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');
		SET @vSQL = N'
SELECT ' + @vNullCols + N'
FROM ( SELECT dept_name, rn, gubun, amt FROM #vsource
       UNION ALL SELECT N''합계'' dept_name, rn, gubun, SUM(amt) amt FROM #vsource GROUP BY rn, gubun ) AS S
PIVOT ( SUM(amt) FOR dept_name IN (' + @vColumns + N') ) AS P
ORDER BY rn;';
		EXEC sp_executesql @vSQL;

		DROP TABLE #vsource; DROP TABLE #vskel; DROP TABLE #vamt; DROP TABLE #vdept;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

GO

-- ==========================================
-- File: VN_SalesAdminByDept_Cum.sql
-- ==========================================
CREATE OR ALTER Procedure VN_SalesAdminByDept_Cum(
	@FROM_YYYYMM varchar(10),
	@TO_YYYYMM varchar(10),
	@SITE varchar(4)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @vColumns NVARCHAR(4000), @vNullCols NVARCHAR(4000), @vSQL NVARCHAR(MAX);

		-- 1) 금액(#vamt) : doi_dept_cost(판관, 센터채움 차변-대변) → doi_acct.상위계정과목  (기간 누적)
		IF OBJECT_ID('tempdb..#vamt') IS NOT NULL DROP TABLE #vamt;
		SELECT LTRIM(RTRIM(d.코스트센터)) dept_name, COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목) item, SUM(d.차변금액 - d.대변금액) amt
		INTO #vamt
		FROM doi_dept_cost d
		JOIN doi_acct a ON a.yyyymm=d.yyyymm AND a.site=d.site AND a.acct=d.계정코드
		WHERE d.yyyymm BETWEEN @FROM_YYYYMM AND @TO_YYYYMM AND d.site=@SITE AND d.비용구분=N'판관'
		  AND LTRIM(RTRIM(ISNULL(d.코스트센터,'')))<>''
		  AND ISNULL(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),'')<>''
		GROUP BY LTRIM(RTRIM(d.코스트센터)), COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목);

		-- 2) 부서 목록 (데이터 부서 + 합계)
		IF OBJECT_ID('tempdb..#vdept') IS NOT NULL DROP TABLE #vdept;
		SELECT dept_name, ord INTO #vdept FROM (
			SELECT DISTINCT dept_name, 1 ord FROM #vamt
			UNION SELECT N'합계', 2
		) t;

		-- 3) 고정항목
		IF OBJECT_ID('tempdb..#vskel') IS NOT NULL DROP TABLE #vskel;
		CREATE TABLE #vskel(rn int, item nvarchar(200), gubun nvarchar(200));
		INSERT #vskel(rn, item, gubun)
		SELECT seq*10, item, N'    (' + CAST(seq AS varchar(3)) + N') ' + item
		FROM (VALUES
			(1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
			(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
			(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
			(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
			(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
			(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비')
		) v(seq,item);
		INSERT #vskel(rn, item, gubun) VALUES (0, N'__T', N'합계');

		-- 4) 소스테이블
		IF OBJECT_ID('tempdb..#vsource') IS NOT NULL DROP TABLE #vsource;
		;WITH item_amt AS (SELECT v.dept_name, sk.rn, SUM(v.amt) amt FROM #vamt v JOIN #vskel sk ON sk.item=v.item GROUP BY v.dept_name, sk.rn),
		 tot AS (SELECT dept_name, 0 rn, SUM(amt) amt FROM item_amt GROUP BY dept_name),
		 amt_all AS (SELECT * FROM item_amt UNION ALL SELECT * FROM tot)
		SELECT b.dept_name, b.rn, b.gubun, CAST(ISNULL(a.amt,0) AS DECIMAL(18,2)) amt
		INTO #vsource
		FROM (SELECT d.dept_name, sk.rn, sk.gubun FROM #vdept d CROSS JOIN #vskel sk WHERE d.dept_name<>N'합계') b
		LEFT JOIN amt_all a ON a.dept_name=b.dept_name AND a.rn=b.rn;

		-- 5) 동적 PIVOT (부서 컬럼)
		SELECT @vColumns = COALESCE(@vColumns + N'],[', N'') + dept_name FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vColumns = N'[' + @vColumns + N']';
		SELECT @vNullCols = COALESCE(@vNullCols, N'') + dept_name + N'],0) as [' + dept_name + N'],coalesce([' FROM (SELECT TOP 500 dept_name FROM #vdept ORDER BY ord, dept_name) x;
		SELECT @vNullCols = N'rn, gubun, ' + REPLACE(N'coalesce([' + @vNullCols + N']', N',coalesce([]', N'');
		SET @vSQL = N'
SELECT ' + @vNullCols + N'
FROM ( SELECT dept_name, rn, gubun, amt FROM #vsource
       UNION ALL SELECT N''합계'' dept_name, rn, gubun, SUM(amt) amt FROM #vsource GROUP BY rn, gubun ) AS S
PIVOT ( SUM(amt) FOR dept_name IN (' + @vColumns + N') ) AS P
ORDER BY rn;';
		EXEC sp_executesql @vSQL;

		DROP TABLE #vsource; DROP TABLE #vskel; DROP TABLE #vamt; DROP TABLE #vdept;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

GO

-- ==========================================
-- File: VN_SalesAdminByModel.sql
-- ==========================================
CREATE OR ALTER PROCEDURE VN_SalesAdminByModel(
	@YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @Columns NVARCHAR(MAX);
		DECLARE @Null_Columns NVARCHAR(MAX);
		DECLARE @SQL NVARCHAR(MAX);
		DECLARE @Prod_Rate DECIMAL(18,6) = 0;
		DECLARE @Dev_Rate  DECIMAL(18,6) = 0;

		-- 1) 금액(#amt) : doi_smce_cost → doi_dept_cost(판관) 브리지 → doi_acct.상위계정과목
		IF OBJECT_ID('tempdb..#amt') IS NOT NULL DROP TABLE #amt;
		SELECT b.구분 + replace(b.model,' ','') model, COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목) item, SUM(b.dist_amt) amt
		INTO #amt
		FROM doi_smce_cost b
		JOIN (SELECT yyyymm,site,계정과목,MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분=N'판관' GROUP BY yyyymm,site,계정과목) dc
			ON dc.yyyymm=b.yyyymm AND dc.site=b.site AND dc.계정과목=b.sub_name
		JOIN doi_acct a ON a.yyyymm=b.yyyymm AND a.site=b.site AND a.acct=dc.계정코드
		WHERE b.yyyymm=@YYYYMM AND b.site=@SITE AND b.sel_code=@SEL_CODE
		  AND ISNULL(COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목),'')<>''
		GROUP BY b.구분 + replace(b.model,' ',''), COALESCE(NULLIF(a.경영계획과목,''),a.상위계정과목);

		-- 2) @Columns : 모델(구분+model) + X/Y/Z합계
		SELECT @Columns = COALESCE(@Columns + N'],[', N'') + model FROM (SELECT DISTINCT model FROM #amt UNION SELECT N'X합계' UNION SELECT N'Y합계' UNION SELECT N'Z합계') A;
		SELECT @Columns = N'[' + @Columns + N']';
		SELECT @Null_Columns = COALESCE(@Null_Columns, N'') + model + N'],0) as [' + model + N'],coalesce([' FROM (SELECT DISTINCT model FROM #amt UNION SELECT N'X합계' UNION SELECT N'Y합계' UNION SELECT N'Z합계') A;
		SELECT @Null_Columns = N'rn,gubun,' + REPLACE(N'coalesce([' + @Null_Columns + N']', N',coalesce([]', N'');

		-- 3) 골격 : 배부율(rn=0) + 판관 27개 고정항목 + 합계(rn=99990)
		IF OBJECT_ID('tempdb..#skel') IS NOT NULL DROP TABLE #skel;
		CREATE TABLE #skel(rn int, gubun nvarchar(200), item nvarchar(200));
		INSERT #skel(rn, gubun, item)
		SELECT seq*10, N'    (' + CAST(seq AS varchar(3)) + N') ' + item, item
		FROM (VALUES
			(1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
			(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
			(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
			(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
			(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
			(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비'),(28,N'판)외주용역비')
		) v(seq,item);
		INSERT #skel(rn, gubun, item) VALUES (0, N'    판관비 배부율 (제품별 매출비중)', N'__RATE'), (99990, N'    합계', N'__TOT');

		-- 4) 소스 : 모델 × 골격, 항목=금액 / 합계=27항목합 / 배부율=모델합/총합
		IF OBJECT_ID('tempdb..#sourceTable1') IS NOT NULL DROP TABLE #sourceTable1;
		;WITH item_amt AS (SELECT a.model, sk.rn, SUM(a.amt) amt FROM #amt a JOIN #skel sk ON sk.item=a.item GROUP BY a.model, sk.rn),
		 mtot AS (SELECT model, SUM(amt) tot FROM item_amt GROUP BY model),
		 g AS (SELECT NULLIF(SUM(tot),0) g FROM mtot)
		SELECT m.model, sk.rn, sk.gubun,
			CAST(CASE WHEN sk.rn=0     THEN mt.tot / (SELECT g FROM g)
			          WHEN sk.rn=99990 THEN mt.tot
			          ELSE ISNULL(ia.amt,0) END AS DECIMAL(18,3)) amt
		INTO #sourceTable1
		FROM (SELECT DISTINCT model FROM #amt) m
		CROSS JOIN #skel sk
		LEFT JOIN mtot mt ON mt.model=m.model
		LEFT JOIN item_amt ia ON ia.model=m.model AND ia.rn=sk.rn;

		-- 5) 양산/개발 배부율(매출비중) : 27항목합 기준
		SELECT @Prod_Rate = SUM(CASE WHEN model LIKE N'양산%' THEN tot ELSE 0 END) / NULLIF(SUM(tot),0),
		       @Dev_Rate  = SUM(CASE WHEN model LIKE N'개발%' THEN tot ELSE 0 END) / NULLIF(SUM(tot),0)
		FROM (SELECT a.model, SUM(a.amt) tot FROM #amt a JOIN #skel sk ON sk.item=a.item GROUP BY a.model) z;

		-- 6) 동적 PIVOT
		SET @SQL = N'
SELECT ' + @Null_Columns + N'
FROM (
	select * from #sourceTable1
	union all select N''X합계'' model, rn, gubun, CASE WHEN rn=0 THEN ' + CAST(@Prod_Rate as varchar(30)) + N' ELSE sum(amt) END amt from #sourceTable1 where model like N''양산%'' group by rn, gubun
	union all select N''Y합계'' model, rn, gubun, CASE WHEN rn=0 THEN ' + CAST(@Dev_Rate as varchar(30)) + N' ELSE sum(amt) END amt from #sourceTable1 where model like N''개발%'' group by rn, gubun
	union all select N''Z합계'' model, rn, gubun, CASE WHEN rn=0 THEN 1 ELSE sum(amt) END amt from #sourceTable1 group by rn, gubun
) AS SourceTable
PIVOT ( SUM(AMT) FOR model IN (' + @Columns + N') ) AS PivotTable
order by rn;';
		EXEC sp_executesql @SQL;

		DROP TABLE #sourceTable1; DROP TABLE #skel; DROP TABLE #amt;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END

GO

-- ==========================================
-- File: VN_TotalCost_Tree.sql
-- ==========================================
CREATE OR ALTER PROCEDURE VN_TotalCost_Tree
(
    @YYYYMM VARCHAR(6),
    @SITE   VARCHAR(4),
    @SELCODE VARCHAR(6)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @Columns         NVARCHAR(MAX) = N'';
        DECLARE @ModelSelectCols NVARCHAR(MAX) = N'';
        DECLARE @SumYangsan      NVARCHAR(MAX) = N'0';
        DECLARE @SumDev          NVARCHAR(MAX) = N'0';
        DECLARE @SumCassette     NVARCHAR(MAX) = N'0';
       	DECLARE @SumPurchase     NVARCHAR(MAX) = N'0';
        DECLARE @SumYangsan_Sale NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Qty  NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Sale     NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Qty      NVARCHAR(MAX)=N'0';
		DECLARE @SumCas_Sale     NVARCHAR(MAX)=N'0';
		DECLARE @SumCas_Qty      NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Sale     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Qty      NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Bep NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Bep     NVARCHAR(MAX)=N'0';  --손익분기점 : Break-Even Point (BEP) Operating Profit
		DECLARE @SumCas_Bep     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Bep     NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_Op NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Op     NVARCHAR(MAX)=N'0';  -- 영업이익  : Operating Profit
		DECLARE @SumCas_Op     NVARCHAR(MAX)=N'0';
		DECLARE @SumPur_Op     NVARCHAR(MAX)=N'0';
        DECLARE @SumYangsan_FiX  NVARCHAR(MAX)=N'0';
		DECLARE @SumDev_Fix      NVARCHAR(MAX)=N'0';
--		DECLARE @SumCas_Fix      NVARCHAR(MAX)=N'0';
--		DECLARE @SumPur_Fix      NVARCHAR(MAX)=N'0';

        DECLARE @SCOFTotal DECIMAL(18,2) = 0;

        DECLARE @SQL             NVARCHAR(MAX);

        /*==============================================================
          0) 매출 발생 모델만 추출 (SALES_BASE)
        ==============================================================*/
		;WITH MERCH_ITEM AS (
		    -- 당월/사업장/SEL 기준 "상품" 품번 목록
		    SELECT DISTINCT M.품번
		    FROM DOI_MATL_RESC M WITH(NOLOCK)
		    WHERE M.YYYYMM   = @YYYYMM
		      AND M.SITE     = @SITE
		      AND M.SEL_CODE = @SELCODE
		      AND M.품목자산분류 = N'상품'
		      AND M.품번 IS NOT NULL
		),        
       SALES_RAW AS (
		    -- 국내매출
		    SELECT
		          A.SITE
		        , CASE
			        WHEN MI.품번 IS NOT NULL THEN N'구매'
		            WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		            WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		            ELSE N'개발'
		          END AS 구분
		        , A.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , N'국내' AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , CAST(A.원화판매금액 AS DECIMAL(18,2)) AS amt
		    FROM DOI_SALE_RESC A WITH(NOLOCK)
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = A.품번
		    WHERE A.YYYYMM = @YYYYMM
		      AND A.SITE   = @SITE
		
		    UNION ALL
		    -- 해외매출
		    SELECT
		          B.SITE
		        , CASE
			        WHEN MI.품번 IS NOT NULL THEN N'구매'			        
		            WHEN LEFT(B.품번, 2) = 'VN' THEN N'카세트'
		            WHEN RIGHT(B.품번, 1) = 'P' THEN N'양산'
		            ELSE N'개발'
		          END AS 구분
		        , B.품번
		        , CASE WHEN @SITE = N'VN' AND LEN(B.품번) > 1 THEN LEFT(B.품번, LEN(B.품번) - 1) ELSE B.품명 END AS model
		        , N'해외' AS 매출구분
		        , CASE WHEN MI.품번 IS NOT NULL THEN N'상품' ELSE N'제품' END AS 매출대분류
		        , CAST(B.원화판매금액 AS DECIMAL(18,2)) AS amt
		    FROM DOI_INVOICE_RESC B WITH(NOLOCK)
		    LEFT JOIN MERCH_ITEM MI
		      ON MI.품번 = B.품번
		    WHERE B.YYYYMM = @YYYYMM
		      AND B.SITE   = @SITE
		       
		    /*UNION ALL  --2026.02.15 KYH 삭제
		      
            --기타매출
			SELECT
	          S.SITE
	        , S.구분
	        , NULL AS 품번
	        , S.model
	        , N'*'  AS 매출구분
	        , N'기타' AS 매출대분류
	        , CAST(ISNULL(/*S.out_amt*/0,0) AS DECIMAL(18,2)) AS amt
	    FROM DOI_SLCO S WITH(NOLOCK)
	    WHERE S.YYYYMM = @YYYYMM
	      AND S.SITE   = @SITE
	      AND S.SEL_CODE = @SELCODE
	      AND S.expen_sel명 = N'기타매출'*/
	  
	     UNION ALL  
		      
            --기타매출
			SELECT
	          S.SITE
	        , S.구분
	        , NULL AS 품번
	        , S.model
	        , N'*'  AS 매출구분
	        , N'기타' AS 매출대분류
	        , CAST(ISNULL(/*S.out_amt*/0,0) AS DECIMAL(18,2)) AS amt
	    FROM DOI_SLCO S WITH(NOLOCK)
	    WHERE S.YYYYMM = @YYYYMM
	      AND S.SITE   = @SITE
	      AND S.SEL_CODE = @SELCODE
	      AND S.MODEL = 'EXTRA' 
			  
        ),
        SALES_BASE AS (
		    SELECT
		          구분
		        , model
		        , SUM(CASE WHEN 매출대분류 = N'제품' THEN amt ELSE 0 END) AS prod_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'상품' THEN amt ELSE 0 END) AS merch_sale_amt
		        , SUM(CASE WHEN 매출대분류 = N'기타' THEN amt ELSE 0 END) AS etc_sale_amt
		        , SUM(amt) AS total_sale_amt
		    FROM SALES_RAW
		    GROUP BY 구분, model
        )
        SELECT *
        INTO #SALES_BASE
        FROM SALES_BASE;
        --WHERE COALESCE(total_sale_amt,0) <> 0;

        /*==============================================================
          1) #MODEL : 모델 + 제품구조/카세트 포함
        ==============================================================*/
        ;WITH MODEL_BASE AS (
            SELECT
                  S.model
                , S.구분 AS 구분
                , CASE
	                  WHEN S.구분 = N'구매' THEN N'상품'
                      WHEN S.구분 = N'카세트' THEN N'카세트'
                      WHEN LEFT(S.model, 1) = 'I' THEN 'ITG'
                      WHEN LEFT(S.model, 1) = 'H' THEN 'HTG'
                      WHEN LEFT(S.model, 1) = 'C' THEN 'Coated'
                      ELSE 'UTG'
                  END AS 제품구조
                , CASE
                      WHEN S.구분 = N'카세트' THEN 1
                      WHEN LEFT(S.model, 2) = 'VN' THEN 1   -- 안전장치(모델명이 VN으로 오는 경우)
                      ELSE 0
                  END AS is_cassette
            FROM #SALES_BASE S
        )
        SELECT
              model
            , 구분
            , 제품구조
            , is_cassette
            , (CASE
                  WHEN 구분 = N'카세트' THEN N'카세트'
                  WHEN 구분 = N'개발'   THEN N'개발'
                  WHEN 구분 = N'구매'   THEN N'구매'                  
                  ELSE N'양산'
               END) + model AS pivot_key
			,	CASE
				    WHEN LEFT(model, 1) BETWEEN '0' AND '9' THEN 0
				    ELSE 1
				END AS sort_numeric  
            , CASE
                  WHEN 구분 = N'양산' THEN 1
                  WHEN 구분 = N'개발' THEN 2
                  WHEN 구분 = N'카세트' THEN 3
                  WHEN 구분 = N'구매' THEN 4                  
                  ELSE 9
              END AS sort_group
            , CASE 제품구조
                  WHEN 'UTG' THEN 1
                  WHEN 'ITG' THEN 2
                  WHEN 'HTG' THEN 3
                  WHEN 'Coated' THEN 4
                  WHEN N'카세트' THEN 8
                  WHEN N'상품' THEN 9                  
                  ELSE 9
              END AS sort_structure
        INTO #MODEL
        FROM MODEL_BASE;
       
       SELECT @SCOFTotal = CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2))
	   FROM DOI_SCOF WITH(NOLOCK)
	   WHERE yyyymm  = @YYYYMM
	    AND site   	 = @SITE
        AND sel_code = @SELCODE

		/*==============================================================
		  (추가) 1-1) 변동비/고정비 프로시저 결과 받아오기 (세로형)
		==============================================================*/
		IF OBJECT_ID('tempdb..#VAR') IS NOT NULL DROP TABLE #VAR;
		IF OBJECT_ID('tempdb..#FIX') IS NOT NULL DROP TABLE #FIX;
		
		CREATE TABLE #VAR (
		  rn   INT,
		  gubun NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  구분  NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
		  model NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  amt  DECIMAL(18,2)
		);
		
		CREATE TABLE #FIX (
		  rn   INT,
		  gubun NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  구분  NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
		  model NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		  amt  DECIMAL(18,2)
		);
		
		INSERT INTO #VAR (rn, gubun, 구분, model, amt)
		EXEC DOI_변동비_ByModel @YYYYMM=@YYYYMM, @SITE=@SITE , @SELCODE = @SELCODE;
		--EXEC DOI_VariableCostByModel @YYYYMM=@YYYYMM, @SITE=@SITE , @SELCODE = @SELCODE;
		
		INSERT INTO #FIX (rn, gubun, 구분, model, amt)
		EXEC DOI_고정비_ByModel @YYYYMM=@YYYYMM, @SITE=@SITE, @SELCODE = @SELCODE; 
		--EXEC DOI_FixedCostByModel @YYYYMM=@YYYYMM, @SITE=@SITE, @SELCODE = @SELCODE; 

       SELECT @SumYangsan_FiX = CAST(COALESCE(SUM(AMT),0) AS DECIMAL(18,2)) 
       FROM #FIX 
       WHERE 구분=N'양산'

       SELECT @SumDev_Fix = CAST(COALESCE(SUM(AMT),0) AS DECIMAL(18,2)) 
       FROM #FIX 
       WHERE 구분=N'개발'
      
        /*==============================================================
          2) #RN
        ==============================================================*/
        -- 고정 항목 골격 (집계표 VN_ManufacturingExpense* / VN_SalesAdmin* 와 동일 목록/순서)
        IF OBJECT_ID('tempdb..#SKL_LAB') IS NOT NULL DROP TABLE #SKL_LAB;
        IF OBJECT_ID('tempdb..#SKL_EXP') IS NOT NULL DROP TABLE #SKL_EXP;
        IF OBJECT_ID('tempdb..#SKL_SGA') IS NOT NULL DROP TABLE #SKL_SGA;
        SELECT N'12.'+RIGHT(N'0'+CAST(seq AS varchar(2)),2) tree_id, 15+seq rn,
               N'    ('+CAST(seq AS varchar(2))+N') '+item gubun, CAST(item AS nvarchar(200)) item, seq
        INTO #SKL_LAB
        FROM (VALUES (1,N'제)급여-직원'),(2,N'제)상여금'),(3,N'제)제수당'),(4,N'제)퇴직급여'),(5,N'제)주식보상비용'),(6,N'제)급여-사회보험료'),(7,N'제)급여-건강보험'),(8,N'제)급여-노동자실업보험료'),(9,N'제)급여-노동자노조비'),(10,N'제)급여-개인소득세'),(11,N'제)급여-기타')) v(seq,item);
        SELECT CAST(N'13.'+RIGHT(N'0'+CAST(seq AS varchar(2)),2) AS nvarchar(20)) tree_id, 30+seq+CASE WHEN seq>=13 THEN 2 ELSE 0 END rn,
               CAST(N'    ('+CAST(seq AS varchar(2))+N') '+item AS nvarchar(200)) gubun, CAST(item AS nvarchar(200)) item, seq
        INTO #SKL_EXP
        FROM (VALUES (1,N'제)직원급여'),(2,N'제)상여금'),(3,N'제)제수당'),(4,N'제)퇴직급여'),(5,N'제)주식보상비용'),(6,N'제)급여-사회보험료'),(7,N'제)급여-건강보험'),(8,N'제)급여-노동자실업보험료'),(9,N'제)급여-노동자노조비'),(10,N'제)급여-개인소득세'),(11,N'제)급여-기타'),(12,N'제)급여-기타비용'),(13,N'제)여비교통비'),(14,N'제)통신비'),(15,N'제)수도광열비'),(16,N'제)전력비'),(17,N'제)감가상각비'),(18,N'제)지급임차료'),(19,N'제)수선비'),(20,N'제)보험료'),(21,N'제)차량유지비'),(22,N'제)운반비'),(23,N'제)교육훈련비'),(24,N'제)도서인쇄비'),(25,N'제)소모품비'),(26,N'제)지급수수료'),(27,N'제)외주가공비'),(28,N'제)사용권자산감가상각비'),(29,N'제)검사비'),(30,N'제)견본비'),(31,N'기술지원 및 기술이전비')) v(seq,item);
        -- 공구 및 도구비용 별도 2항목 ((12) 뒤 rn43/44, 감가상각비에서 제외)
        INSERT #SKL_EXP(tree_id, rn, gubun, item, seq) VALUES
          (N'13.51', 43, N'    (1-1) 제)공구 및 도구 비용 - 상각비용', N'제)공구 및 도구 비용 - 상각비용', 121),
          (N'13.52', 44, N'    (1-2) 제)공구 및 도구 비용 -일회성비용', N'제)공구 및 도구 비용 -일회성비용', 122);
        SELECT N'16.'+RIGHT(N'0'+CAST(seq AS varchar(2)),2) tree_id, 75+seq rn,
               N'    ('+CAST(seq AS varchar(2))+N') '+item gubun, CAST(item AS nvarchar(200)) item, seq
        INTO #SKL_SGA
        FROM (VALUES (1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),(6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),(11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),(16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),(21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),(26,N'판)잡비'),(27,N'기술이전비 및 기술지원비'),(28,N'판)외주용역비')) v(seq,item);

        SELECT tree_id, rn, gubun
        INTO #RN
        FROM (
            SELECT N'10' tree_id, 1 rn, N'  I. 매출액' gubun UNION ALL
            SELECT N'10.01', 2, N'    (1) 제품매출' UNION ALL
            SELECT N'10.02', 3, N'        수량' UNION ALL
            SELECT N'10.03', 4, N'        단가' UNION ALL
            SELECT N'10.04', 5, N'    (2) 유상사급' UNION ALL
            SELECT N'10.05', 6, N'    (3) 상품매출' UNION ALL
            SELECT N'10.06', 7, N'    (4) 기타매출' UNION ALL
            SELECT N'11', 8, N'  II. 재료비' UNION ALL
            SELECT N'11.01', 9, N'    (1) 원재료비' UNION ALL
            SELECT N'12', 15, N'  III. 노무비' UNION ALL
            SELECT N'13', 30, N'  IV. 제조경비' UNION ALL
            SELECT N'14', 70, N'  V. 매출원가' UNION ALL
            SELECT N'14.01', 71, N'    (1) 제품매출원가' UNION ALL
            SELECT N'14.02', 72, N'    (2) 상품매출원가' UNION ALL
            SELECT N'16', 75, N'  VI. 판관비' UNION ALL
            SELECT N'17', 110, N'  VII. 총원가' UNION ALL
            SELECT N'18', 111, N'  VIII. 영업이익' UNION ALL
            SELECT N'18.01', 112, N'    영업이익률' UNION ALL
            SELECT N'19', 120, N'  IX. 한계이익' UNION ALL
            SELECT N'19.01', 121, N'    한계이익률' UNION ALL
            SELECT N'20', 130, N'  X. 손익분기점'+ REPLICATE(NCHAR(0x3000), 5) UNION ALL
            SELECT tree_id, rn, gubun FROM #SKL_LAB UNION ALL
            SELECT tree_id, rn, gubun FROM #SKL_EXP UNION ALL
            SELECT tree_id, rn, gubun FROM #SKL_SGA
        ) A;
       
        /*==============================================================
          3) FACT (rn/gubun/model/amt)
             - 매출: #SALES_BASE
             - 재료비: doi_mat_cost
             - 노무비/제조경비: doi_expen_matl
             - V 재고조정: DOI_COST + DOI_STCO
             - VI 판관비: DOI_SMCE_COST
             - VII 총원가: 재고조정 + 판관비
             - VIII 영업이익: 매출액 - 총원가 
             - IX~X: 우선 NULL
        ==============================================================*/
        ;WITH MERCH_ITEM AS (
      SELECT DISTINCT M.품번
            FROM DOI_MATL_RESC M WITH(NOLOCK)
            WHERE M.YYYYMM   = @YYYYMM
              AND M.SITE     = @SITE
              AND M.SEL_CODE = @SELCODE
              AND M.품목자산분류 = N'상품'
              AND M.품번 IS NOT NULL
        ),
       SALES_FACT AS (
            SELECT 1 rn, N'  I. 매출액'     AS gubun, 구분, model, total_sale_amt AS amt FROM #SALES_BASE
            UNION ALL
            SELECT 2 rn, N'    (1) 제품매출' AS gubun, 구분, model, prod_sale_amt AS amt FROM #SALES_BASE
   			UNION ALL
    		SELECT 6 rn, N'    (3) 상품매출'   AS gubun, 구분, model, merch_sale_amt  AS amt FROM #SALES_BASE        
           ),
        QTY_BASE AS (
		    SELECT
		          CASE
                      WHEN MI.품번 IS NOT NULL THEN N'구매'     
		              WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		              WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		              ELSE N'개발'
		          END AS 구분
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , SUM(A.수량) AS qty
		    FROM (
                SELECT YYYYMM, SITE, 품번, 품명, 수량 FROM DOI_SALE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
                UNION ALL
                SELECT YYYYMM, SITE, 품번, 품명, 수량 FROM DOI_INVOICE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
		    ) A
            LEFT JOIN MERCH_ITEM MI ON MI.품번 = A.품번
            GROUP BY
                CASE
                    WHEN MI.품번 IS NOT NULL THEN N'구매'
                    WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
                    WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
                    ELSE N'개발'
                END,
                CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END
		),
		QTY_FACT AS (
		    SELECT
		          3 AS rn
		        , N'        수량' AS gubun
		        , 구분
		        , model
		        , CAST(qty AS DECIMAL(18,2)) AS amt
		    FROM QTY_BASE
		),
		PRICE_BASE AS (
		    SELECT
		          CASE
		              WHEN MI.품번 IS NOT NULL THEN N'구매'
		              WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		              WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		              ELSE N'개발'
		          END AS 구분
		        , CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END AS model
		        , SUM(A.매출금액) AS sale_amt
		        , SUM(A.수량)     AS qty
		    FROM (
		        SELECT 품번, 품명, 수량, 원화판매금액 AS 매출금액 FROM DOI_SALE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
		        UNION ALL
		        SELECT 품번, 품명, 수량, 원화판매금액 AS 매출금액 FROM DOI_INVOICE_RESC WHERE YYYYMM = @YYYYMM AND SITE = @SITE
		    ) A
		    LEFT JOIN MERCH_ITEM MI ON MI.품번 = A.품번
		    GROUP BY
		        CASE
		            WHEN MI.품번 IS NOT NULL THEN N'구매'
		            WHEN LEFT(A.품번, 2) = 'VN' THEN N'카세트'
		            WHEN RIGHT(A.품번, 1) = 'P' THEN N'양산'
		            ELSE N'개발'
		        END,
		        CASE WHEN @SITE = N'VN' AND LEN(A.품번) > 1 THEN LEFT(A.품번, LEN(A.품번) - 1) ELSE A.품명 END
		),
		PRICE_FACT AS (
		    SELECT
		          4 AS rn
		        , N'        단가' AS gubun
		        , 구분
		        , model
		        , CAST(
		              CASE WHEN qty = 0 THEN 0
		                   ELSE sale_amt / qty
		              END
		          AS DECIMAL(18,2)) AS amt
		    FROM PRICE_BASE
		),
		SCOF_BASE AS (
		    SELECT
		          5 AS rn
		        , N'    (2) 유상사급' AS gubun
		        , N'총합계' AS 구분
		        , N'총합계' AS model
		        , CAST(COALESCE(SUM(FINAL_AMT),0) AS DECIMAL(18,2)) AS amt
		    FROM DOI_SCOF WITH(NOLOCK)
		    WHERE yyyymm  = @YYYYMM
		      AND site    = @SITE
              AND sel_code= @SELCODE
		),
		ETC_SALE_BASE AS (
            SELECT 7 rn, 
                   N'    매출원가조정' gubun, 
                   구분, 
                 model,
                   SUM(out_amt) AS amt
            FROM doi_slco a WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM
              AND site   = @SITE
              AND sel_code = @SELCODE
              and EXPEN_SEL명 = '기타매출'
            GROUP BY 구분, model
		),		
		MAT_BASE AS (
            SELECT
            	구분
                , model    
                , acct_name
                , out_amt AS amt --select distinct acct_name
   FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm = @YYYYMM
              AND site   = @SITE
              AND sel_code = @SELCODE
              and expen_sel IN('MDAX','MIAX')  --직접재료비, 간접재료비
              and out_amt != 0
        ),
        MAT_AGG AS (
            -- II. 재료비 (VN: 단일 원재료비)
            SELECT 8 rn, N'  II. 재료비' gubun, 구분, model, SUM(amt) amt
            FROM MAT_BASE
            GROUP BY 구분, model
            UNION ALL
            SELECT 9 rn, N'    (1) 원재료비' gubun, 구분, model, SUM(amt) amt
            FROM MAT_BASE
            GROUP BY 구분, model
          ),
        LABOR_BASE AS (
         SELECT 15+총원가_순서 rn, N'    ('+CAST(총원가_순서 as varchar(1))+') '+b.상위계정과목 as gubun, a.구분, a.model,
                   SUM(out_amt) AS amt
            FROM doi_stco a WITH(NOLOCK)
            LEFT JOIN (SELECT DISTINCT yyyymm, site, 계정과목, 계정코드 FROM doi_dept_cost) dc
                   ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.acct_name
            inner join doi_acct b on(a.yyyymm=b.yyyymm and a.site=b.site
                   and ( b.acct_name = a.acct_name
                         OR ( b.acct = dc.계정코드
                              AND NOT EXISTS (SELECT 1 FROM doi_acct bx WHERE bx.yyyymm=a.yyyymm AND bx.site=a.site AND bx.acct_name=a.acct_name) ) ) )
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND b.상위계정과목 in ('제)임원급여','제)직원급여', '제)상여금', '제)제수당', '제)퇴직급여', '제)주식보상비용')
            GROUP BY a.구분, a.model ,b.상위계정과목,b.총원가_순서
        ),  
        LABOR_AGG AS (
            SELECT 15 rn, N'  III. 노무비' gubun, 구분, model,
                   SUM(amt) AS amt
            FROM LABOR_BASE 
            GROUP BY 구분, model
        ),
        EXP_BASE AS (
                 SELECT 22+총원가_순서 rn, N'    ('+CAST(총원가_순서 as varchar(2))+') '+b.상위계정과목 as gubun, a.구분, a.model,
                   SUM(out_amt) AS amt
            FROM doi_stco a WITH(NOLOCK)
            LEFT JOIN (SELECT DISTINCT yyyymm, site, 계정과목, 계정코드 FROM doi_dept_cost) dc
                   ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.acct_name
            inner join doi_acct b on(a.yyyymm=b.yyyymm and a.site=b.site
                   and ( b.acct_name = a.acct_name
                         OR ( b.acct = dc.계정코드
                              AND NOT EXISTS (SELECT 1 FROM doi_acct bx WHERE bx.yyyymm=a.yyyymm AND bx.site=a.site AND bx.acct_name=a.acct_name) ) ) )
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND b.상위계정과목 in ('제)복리후생비','제)여비교통비','제)통신비','제)수도광열비','제)전력비','제)세금과공과','제)감가상각비','제)지급임차료','제)수선비','제)보험료','제)차량유지비','제)운반비','제)교육훈련비','제)도서인쇄비','제)소모품비','제)지급수수료','제)외주가공비','제)사용권자산감가상각비','제)검사비','제)견본비','제)공구 및 도구비용')
            GROUP BY a.구분, a.model ,b.상위계정과목,b.총원가_순서
            UNION ALL
            /*SELECT 22 rn, N'  EXTRA' gubun, 구분, model, out_amt
             FROM doi_slco a WITH(NOLOCK)
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND a.model = 'EXTRA'
            UNION ALL*/
            SELECT 22 rn, N'  기타출고' gubun, 구분, model, out_amt
             FROM doi_stco a WITH(NOLOCK)
            WHERE a.yyyymm = @YYYYMM
              AND a.site   = @SITE
              AND a.sel_code = @SELCODE
              AND a.acct_name = '*'
              AND a.out_amt != 0
        ),
        EXP_AGG AS (
            SELECT 30 rn, N'  IV. 제조경비' gubun, 구분, model,
                   SUM(amt) AS amt
            FROM EXP_BASE 
            GROUP BY 구분, model
        ),

        /* ====== 상품매출원가 ====== */
        MERCH_COGS AS ( 
            SELECT 99 rn, N'    상품매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(SUM(R.출고금액),0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_MATL_RESC R WITH(NOLOCK)
              ON R.YYYYMM = @YYYYMM
             AND R.SITE   = @SITE
             AND R.SEL_CODE = @SELCODE
             AND R.품목자산분류 = N'상품'
             AND (CASE WHEN @SITE = N'VN' AND LEN(R.품번) > 1 THEN LEFT(R.품번, LEN(R.품번) - 1) ELSE R.품명 END) = M.model
            WHERE M.구분 = N'구매'
            GROUP BY M.구분, M.model
        ),				
		
        /* ====== 제품매출원가(doi_stco OUT, 비LOSS) = 실제 제품출고원가 ====== */
        PROD_COGS AS (
            SELECT 구분, model, CAST(SUM(out_amt) AS DECIMAL(18,2)) AS amt
            FROM doi_stco WITH(NOLOCK)
            WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SELCODE
              AND COST_TYPE <> 'LOSS'
            GROUP BY 구분, model
        ),
        TOTAL_MFG AS (
            /*SELECT 43 rn, N'    당기총제조원가' gubun, M.구분, M.model,
                   SUM(COALESCE(A.[in],0)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_COST A  
            ON A.YYYYMM   = @YYYYMM
            AND A.SITE     = @SITE
            AND A.SEL_CODE = @SELCODE
            AND A.model = M.model 
            AND A.구분 = M.구분
            GROUP BY M.구분, M.MODEL*/
            -- V 매출원가 = 제품매출원가(doi_stco 실제출고원가) + 상품매출원가
			SELECT 70 rn, N'  V. 매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(PC.amt,0) + COALESCE(XX.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN PROD_COGS     PC ON PC.model = M.model AND PC.구분 = M.구분
            LEFT JOIN MERCH_COGS    XX ON XX.model = M.model AND XX.구분 = M.구분
            ),
        /* ====== V 매출원가 하위: (1)제품매출원가 (2)상품매출원가 ====== */
        PROD_COGS_FACT AS (
            SELECT 71 rn, N'    (1) 제품매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(PC.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN PROD_COGS PC ON PC.model = M.model AND PC.구분 = M.구분
            ),
        MERCH_COGS_FACT AS (
            SELECT 72 rn, N'    (2) 상품매출원가' gubun, M.구분, M.model,
                   CAST(COALESCE(XX.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN MERCH_COGS XX ON XX.model = M.model AND XX.구분 = M.구분
            ),
        ADJ_SALE AS (  --26-02-13 삭제
            SELECT 44 rn, N'    매출원가조정' gubun, M.구분, M.model,
                   COALESCE(E.amt,0) AS amt
            FROM #MODEL M
            LEFT JOIN ETC_SALE_BASE E ON E.model = M.model AND E.구분 = M.구분
        ),
        
        /* ====== V 재고조정 ======
           재고조정 = (기초재공 - 기말재공) + (기초제품 - 기말제품)
                   + (타계정입고(재공/제품) - 타계정출고(재공/제품))
        */
		COST_ADJ AS (  --26-02-13 삭제
		    SELECT
		          YYYYMM, SITE, 구분, MODEL
		        , SUM(COALESCE(BOH+ADJ_BOH,0))       AS BOH
		        , SUM(COALESCE(EOH,0))       AS EOH
		        , SUM(COALESCE(RMAIN_AMT,0)) AS RMAIN_AMT
		    FROM DOI_COST WITH(NOLOCK)
		    WHERE YYYYMM  = @YYYYMM
		      AND SITE    = @SITE
              AND SEL_CODE= @SELCODE
		    GROUP BY YYYYMM, SITE, 구분, MODEL
		),
		STCO_ADJ AS ( 
		    SELECT
		          YYYYMM, SITE, 구분, MODEL
		        , SUM(COALESCE(BOH_AMT,0))    AS BOH_AMT
		        , SUM(COALESCE(EOH_AMT,0))    AS EOH_AMT
		        , SUM(COALESCE(INETC_AMT,0))  AS INETC_AMT
		        , SUM(COALESCE(OUTETC_AMT,0)) AS OUTETC_AMT
		    FROM DOI_STCO WITH(NOLOCK)
		    WHERE YYYYMM = @YYYYMM
		      AND SITE   = @SITE
		      AND SEL_CODE = @SELCODE
		      AND ACCT_NAME != '기타출고'
		    GROUP BY YYYYMM, SITE, 구분, MODEL
		),
		INV_ADJ AS (
		    SELECT
		          45 rn
		        , N'  V. 재고조정' gubun
		        , M.구분
		        , M.model
		        , CAST(
		              (COALESCE(C.BOH,0) - COALESCE(C.EOH,0))
		            + (COALESCE(S.BOH_AMT,0) - COALESCE(S.EOH_AMT,0))
		            /*+ COALESCE(C.RMAIN_AMT,0)*/
		            + COALESCE(S.INETC_AMT,0)
		            - COALESCE(S.OUTETC_AMT,0)
		          AS DECIMAL(18,2)) AS amt
		    FROM #MODEL M
		    LEFT JOIN COST_ADJ C
		           ON C.YYYYMM = @YYYYMM
		          AND C.SITE   = @SITE
		          AND C.MODEL  = M.model
		          AND C.구분    = M.구분
		    LEFT JOIN STCO_ADJ S
		           ON S.YYYYMM = @YYYYMM
		          AND S.SITE   = @SITE
		       AND S.MODEL  = M.model
		          AND S.구분    = M.구분
		),
    /* ====== VI 판관비 ====== */
		SGA_BASE AS (
			SELECT 47+b.총원가_순서 rn,
			       N'    ('+CAST(b.총원가_순서 as varchar(2))+') '+b.상위계정과목 as gubun,
			       a.구분,
			       a.model,
			       SUM(a.dist_amt) AS amt
			FROM doi_smce_cost a WITH(NOLOCK)
			-- VN: sub_name(원장명)은 doi_acct.acct_name과 매칭 안 되므로 doi_dept_cost(판관) 브리지
			left join (select distinct yyyymm, site, 계정과목, 계정코드 from doi_dept_cost where 비용구분=N'판관') dc
			  on @SITE=N'VN' and dc.yyyymm=a.yyyymm and dc.site=a.site and dc.계정과목=a.sub_name
			inner join doi_acct b
			  on (a.yyyymm=b.yyyymm and a.site=b.site
			      and ( (@SITE<>N'VN' and a.sub_name=b.acct_name)
			            or (@SITE=N'VN' and b.acct=dc.계정코드) ))
			WHERE a.yyyymm = CASE WHEN @SITE=N'VN' THEN @YYYYMM ELSE '202508' END
			  AND a.site   = CASE WHEN @SITE=N'VN' THEN @SITE  ELSE 'HQ' END
			  AND a.sel_code = CASE WHEN @SITE=N'VN' THEN @SELCODE ELSE 'ACTUAL' END
			  AND ( (@SITE<>N'VN' AND b.상위계정과목 in (
				'판)임원급여','판)직원급여','판)상여금','판)제수당','판)퇴직급여','판)복리후생비',
				'판)여비교통비','판)접대비','판)통신비','판)수도광열비','판)세금과공과','판)감가상각비',
				'판)지급임차료','판)수선비','판)보험료','판)차량유지비','판)경상연구개발비','판)운반비',
				'판)교육훈련비','판)도서인쇄비','판)소모품비','판)지급수수료','판)광고선전비',
				'판)무형자산상각비','판)견본비','판)사용권자산감가상각비','판)주식보상비용','판)해외시장개척비'
			  ))
			    OR (@SITE=N'VN' AND b.상위계정과목 LIKE N'판)%' AND NULLIF(b.총원가_순서,N'') IS NOT NULL) )
			GROUP BY a.구분, a.model, b.상위계정과목, b.총원가_순서
		),
        SGA AS (
      	SELECT
                  75 rn
                , N'  VI. 판관비' gubun
                , CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE M.구분 END 구분
                , M.model
                , CAST(COALESCE(SUM(X.dist_amt),0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN DOI_SMCE_COST X WITH(NOLOCK)
            ON X.YYYYMM = @YYYYMM
                  AND X.SITE   = @SITE
                  AND X.SEL_CODE = @SELCODE
                  AND X.MODEL  = M.model
                  AND M.구분 = CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE M.구분 END
            GROUP BY CASE WHEN X.MODEL LIKE 'VINA%' THEN '카세트' ELSE M.구분 END, M.model
        ),

        TOTAL_COST AS (
            -- VII 총원가 = 당기총제조원가 + 재고조정 + 판관비 + 매출원가조정
			SELECT 110 rn, N'  VII. 총원가' gubun, M.구분, M.model,
                   CAST(COALESCE(A.amt,0) /*+ COALESCE(V.amt,0)*/ + COALESCE(VI.amt,0) /*+ COALESCE(B.amt,0)*/ AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN TOTAL_MFG A ON A.model = M.model AND A.구분 = M.구분 
            --LEFT JOIN INV_ADJ V ON V.model = M.model AND V.구분 = M.구분
            LEFT JOIN SGA     VI ON VI.model = M.model AND VI.구분 = M.구분
            --LEFT JOIN ETC_SALE_BASE B ON B.model  = M.model AND B.구분 = M.구분
        ),
        OP_PROFIT AS (
            -- VIII 영업이익 = 매출액 - 총원가
            SELECT 111 rn, N'  VIII. 영업이익' gubun, M.구분, M.model,
                   CAST(COALESCE(SL.total_sale_amt,0) - COALESCE(TC.amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN TOTAL_COST TC  ON TC.model = M.model AND TC.구분 = M.구분
        ),
        OP_MARGIN AS (
            -- VIII 영업이익률 = 영업이익 / 매출액
            SELECT 112 rn, N'    영업이익률' gubun, M.구분, M.model,
                   CAST(
                        CASE WHEN COALESCE(SL.total_sale_amt,0) = 0 THEN NULL
                             ELSE (COALESCE(OP.amt,0) / SL.total_sale_amt) * 100
                        END
                   AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
 			LEFT JOIN OP_PROFIT OP   ON OP.model = M.model AND OP.구분 = M.구분
        ),
        /*==============================================================
    (추가) IX~X 계산용: 변동비/고정비 (모델별)
          - (총합계/양산/개발/카세트) 중에서 "현재 모델의 구분"만 매칭
        ==============================================================*/
        VAR_TOTAL AS (
            SELECT
                  M.구분
                , M.model
                , CAST(COALESCE(SUM(V.amt),0) AS DECIMAL(18,2)) AS var_amt
            FROM #MODEL M
            LEFT JOIN #VAR V
                   ON V.model = M.model
                  AND V.구분 = M.구분
                  --AND V.rn    = 1   -- ✅ 변동비 합계 rn
            GROUP BY M.구분, M.model
        ),
        FIX_TOTAL AS (
            SELECT
                  M.구분
                , M.model
                , CAST(COALESCE(SUM(F.amt),0) AS DECIMAL(18,2)) AS fix_amt
            FROM #MODEL M
            LEFT JOIN #FIX F
                   ON F.model = M.model
                  AND F.구분 = M.구분
                  --AND F.rn    = 1 -- ✅ 고정비 합계 rn
            GROUP BY M.구분, M.model
        ),
        CM_PROFIT AS (
            -- IX. 한계이익 = 매출액 - 변동비
            SELECT
                  120 rn
                , N'  IX. 한계이익' gubun
                , M.구분
                , M.model
                , CAST(COALESCE(SL.total_sale_amt,0) - COALESCE(VT.var_amt,0) AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN VAR_TOTAL VT   ON VT.model = M.model AND VT.구분 = M.구분
        ),
        CM_MARGIN AS (
            -- IX. 한계이익률(%) = 한계이익 / 매출액 * 100
            SELECT
                  121 rn
                , N'    한계이익률' gubun
                , M.구분
                , M.model
        , CAST(
                      CASE WHEN COALESCE(SL.total_sale_amt,0) = 0 THEN NULL
                           ELSE (COALESCE(CM.amt,0) / SL.total_sale_amt) * 100
                      END
                  AS DECIMAL(18,2)) AS amt
      FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN CM_PROFIT CM   ON CM.model = M.model AND CM.구분 = M.구분
        ),
        BEP AS (
            -- X. 손익분기점(BEP 매출) = 고정비 / (한계이익/매출액)
            SELECT
  				130 rn
            	, N'  X. 손익분기점' gubun 
                , M.구분
                , M.model
                , CAST(
                      CASE
                        WHEN COALESCE(SL.total_sale_amt,0) = 0 THEN NULL
                        WHEN (COALESCE(CM.amt,0) / NULLIF(SL.total_sale_amt,0)) = 0 THEN NULL
                        ELSE COALESCE(FT.fix_amt,0) / ((COALESCE(CM.amt,0) / SL.total_sale_amt))
                      END  AS DECIMAL(18,2)) AS amt
            FROM #MODEL M
            LEFT JOIN #SALES_BASE SL ON SL.model = M.model AND SL.구분 = M.구분
            LEFT JOIN CM_PROFIT CM   ON CM.model = M.model AND CM.구분 = M.구분
            LEFT JOIN FIX_TOTAL FT   ON FT.model = M.model AND FT.구분 = M.구분
        ),
        /* ===== 세부 항목(집계표 골격): doi_stco(제조 622/627) + doi_smce_cost(판관) 브리지 ===== */
        STCO_OH AS (
            SELECT a.구분, a.model, LEFT(dc.계정코드,3) code3,
                   CASE WHEN a.acct_name=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN a.acct_name=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목),N'(간접)',N'') END item,
                   SUM(a.out_amt) amt
            FROM doi_stco a WITH(NOLOCK)
            JOIN (SELECT DISTINCT yyyymm,site,계정과목,계정코드 FROM doi_dept_cost) dc
              ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.acct_name
            JOIN doi_acct b WITH(NOLOCK)
              ON b.yyyymm=a.yyyymm AND b.site=a.site AND b.acct=dc.계정코드
            WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND a.sel_code=@SELCODE
              AND LEFT(dc.계정코드,3) IN ('622','627') AND a.out_amt<>0
              AND ISNULL(CASE WHEN a.acct_name=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN a.acct_name=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목),N'(간접)',N'') END,N'')<>N''
            GROUP BY a.구분, a.model, LEFT(dc.계정코드,3),
                     CASE WHEN a.acct_name=N'공구 및 도구비용 - 상각비용' THEN N'제)공구 및 도구 비용 - 상각비용' WHEN a.acct_name=N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용' ELSE REPLACE(COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목),N'(간접)',N'') END
        ),
        LABOR_ITEMS AS (
            SELECT sk.rn, sk.gubun, o.구분, o.model, CAST(SUM(o.amt) AS DECIMAL(18,2)) amt
            FROM STCO_OH o JOIN #SKL_LAB sk ON sk.item=o.item AND o.code3='622'
            GROUP BY sk.rn, sk.gubun, o.구분, o.model
        ),
        EXP_ITEMS AS (
            SELECT sk.rn, sk.gubun, o.구분, o.model, CAST(SUM(o.amt) AS DECIMAL(18,2)) amt
            FROM STCO_OH o JOIN #SKL_EXP sk ON sk.item=o.item AND o.code3='627'
            GROUP BY sk.rn, sk.gubun, o.구분, o.model
        ),
        SGA_OH AS (
            SELECT a.구분, a.model,
                   COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목) item,
                   SUM(a.dist_amt) amt
            FROM doi_smce_cost a WITH(NOLOCK)
            JOIN (SELECT yyyymm,site,계정과목,MIN(계정코드) AS 계정코드 FROM doi_dept_cost WHERE 비용구분=N'판관' GROUP BY yyyymm,site,계정과목) dc
              ON dc.yyyymm=a.yyyymm AND dc.site=a.site AND dc.계정과목=a.sub_name
            JOIN doi_acct b WITH(NOLOCK)
              ON b.yyyymm=a.yyyymm AND b.site=a.site AND b.acct=dc.계정코드
            WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND a.sel_code=@SELCODE
            GROUP BY a.구분, a.model, COALESCE(NULLIF(b.경영계획과목,N''),b.상위계정과목)
        ),
        SGA_ITEMS AS (
            SELECT sk.rn, sk.gubun, o.구분, o.model, CAST(SUM(o.amt) AS DECIMAL(18,2)) amt
            FROM SGA_OH o JOIN #SKL_SGA sk ON sk.item=o.item
            GROUP BY sk.rn, sk.gubun, o.구분, o.model
        ),
        FACT AS (
            SELECT rn, gubun, 구분, model, amt FROM SALES_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM QTY_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM PRICE_FACT
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM SCOF_BASE
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM ETC_SALE_BASE    		    		
    		UNION ALL SELECT rn, gubun, 구분, model, amt FROM MAT_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM LABOR_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM LABOR_ITEMS
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM EXP_AGG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM EXP_ITEMS
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM TOTAL_MFG
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM PROD_COGS_FACT
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM MERCH_COGS_FACT
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM ADJ_SALE
--            UNION ALL SELECT rn, gubun, 구분, model, amt FROM INV_ADJ  --26/02/13 KYH삭제
--            UNION ALL SELECT rn, gubun, 구분, model, amt FROM MERCH_COGS    --26/02/13 KYH삭제         
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA        
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM SGA_ITEMS
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM TOTAL_COST
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM OP_PROFIT
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM OP_MARGIN
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM CM_PROFIT
        UNION ALL SELECT rn, gubun, 구분, model, amt FROM CM_MARGIN
            UNION ALL SELECT rn, gubun, 구분, model, amt FROM BEP            
        ),
        BASE AS (
            SELECT
            	R.tree_id
                , R.rn
                , R.gubun
                , M.구분
                , M.model
                , M.pivot_key
                , COALESCE(F.amt, 0) AS amt
            FROM #RN R
            CROSS JOIN #MODEL M
            LEFT JOIN FACT F
                   ON F.rn    = R.rn
                  AND F.gubun = R.gubun
                  AND F.model = M.model
                  AND F.구분 = M.구분
        )
        SELECT 구분, tree_id, rn, gubun, model, pivot_key, amt
        INTO #BASE
        FROM BASE;

        /*==============================================================
          4) 동적 PIVOT + 피벗 후 합계컬럼 생성
             - 총합계 = 양산 + 개발 + 카세트 + 상품매출(NULL) + 기타매출(NULL)
             - (표시는 상품/기타는 NULL, 계산에는 포함 안됨)
        ==============================================================*/
        ;WITH COLS AS (
            SELECT 구분, model, pivot_key, sort_group, sort_structure, sort_numeric FROM #MODEL
        )
        SELECT
              @Columns = STRING_AGG(QUOTENAME(pivot_key), N', ')
           WITHIN GROUP (ORDER BY sort_group, sort_structure, sort_numeric, model)
            , @ModelSelectCols = STRING_AGG(
                    N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0) AS ' + QUOTENAME(pivot_key)
                  , N', '
        ) WITHIN GROUP (ORDER BY sort_group, sort_structure, sort_numeric, model)         
        FROM COLS;

        SELECT
            @SumYangsan = COALESCE(
                STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
           N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'양산'
          AND is_cassette = 0;

		SELECT @SumYangsan_Sale =
		  COALESCE(STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;
		
		SELECT @SumYangsan_Qty =
		  COALESCE(STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;
                  
        SELECT
            @SumDev = COALESCE(
          STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
        WITHIN GROUP (ORDER BY sort_structure, model),
                N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'개발';

       	SELECT @SumDev_Sale =
		  COALESCE(STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
		
		SELECT @SumDev_Qty =
		  COALESCE(STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
       
        SELECT
            @SumCassette = COALESCE(
                STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
                N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;

        SELECT
            @SumCas_Sale = COALESCE(
                STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
                N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;
          
        SELECT
            @SumCas_Qty = COALESCE(
                STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
              N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;             

        SELECT @SumPurchase = COALESCE(
            STRING_AGG(N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';

        SELECT @SumPur_Sale = COALESCE(
            STRING_AGG(N'COALESCE(Sales.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL WHERE 구분 = N'구매';

        SELECT @SumPur_Qty = COALESCE(
            STRING_AGG(N'COALESCE(Qty.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL WHERE 구분 = N'구매';  
        
        -------------
		SELECT @SumYangsan_Bep =
		  COALESCE(STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;

       	SELECT @SumDev_Bep =
		  COALESCE(STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
		
       	SELECT
            @SumCas_Bep = COALESCE(
                STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
              N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;             

        SELECT @SumPur_Bep = COALESCE(
            STRING_AGG(N'COALESCE(Bep.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';     
        ---------------
		SELECT @SumYangsan_Op =
		  COALESCE(STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'양산' AND is_cassette=0;

       	SELECT @SumDev_Op =
		  COALESCE(STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
		    WITHIN GROUP (ORDER BY sort_structure, model), N'0')
		FROM #MODEL
		WHERE 구분=N'개발' AND is_cassette=0;
		
       	SELECT
            @SumCas_Op = COALESCE(
                STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                    WITHIN GROUP (ORDER BY sort_structure, model),
              N'0'
            )
        FROM #MODEL M
        WHERE M.구분 = N'카세트'
           OR is_cassette = 1;     

        SELECT @SumPur_Op = COALESCE(
            STRING_AGG(N'COALESCE(Op.' + QUOTENAME(pivot_key) + N',0)', N' + ')
                WITHIN GROUP (ORDER BY sort_structure, model), N'0')
        FROM #MODEL M WHERE M.구분 = N'구매';     
          
		SET @SQL = N'
		;WITH P AS (
		    SELECT tree_id, TRY_CONVERT(INT, rn) AS rn, gubun, ' + @Columns + N'
		    FROM (
		        SELECT tree_id, TRY_CONVERT(INT, rn) AS rn, gubun, pivot_key, amt
		        FROM #BASE
		    ) S
		    PIVOT (SUM(amt) FOR pivot_key IN (' + @Columns + N')) PV
		)
		SELECT
			Cur.tree_id
      		, Cur.rn
		    , Cur.gubun
		
		    -- ✅ 총합계: 유상사급/매출액만 특수 처리
		    , CAST(
					CASE
					  WHEN Cur.rn = 5 THEN @SCOF
					  WHEN Cur.rn = 4 THEN
					      ((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + '))
					      / NULLIF(((' + @SumYangsan_Qty + ')+(' + @SumDev_Qty + ')+(' + @SumCas_Qty + ')+(' + @SumPur_Qty + ')),0)
            		  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumYangsan_Op + ')+(' + @SumDev_Op + ')+(' + @SumCas_Op + ')+(' + @SumPur_Op +'))
					      /NULLIF(((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ')),0)*100
           			  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
						  ('+@SumYangsan_FiX + ' + ' + @SumDev_Fix +')
					      /NULLIF(((' + @SumYangsan_Bep + ')+(' + @SumDev_Bep + ')+(' + @SumCas_Bep + ')+(' + @SumPur_Bep +')),0)*100
					       --/NULLIF(((' + @SumYangsan_Sale + ')+(' + @SumDev_Sale + ')+(' + @SumCas_Sale + ')+(' + @SumPur_Sale + ')),0)*100
					  WHEN Cur.rn = 1 THEN ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + ')) - @SCOF
					  ELSE ((' + @SumYangsan + ')+(' + @SumDev + ')+(' + @SumCassette + ')+(' + @SumPurchase + '))
					END
		      AS DECIMAL(18,2)) AS [총합계]
		
		    -- ✅ 양산/개발/카세트 합계: 유상사급은 0으로
		    , CAST(
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumYangsan_Sale + ') / NULLIF((' + @SumYangsan_Qty + '),0))
            	  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumYangsan_Op  +'))
					      /NULLIF(((' + @SumYangsan_Sale + ')),0)*100
         		  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
					  ('+@SumYangsan_FiX +')
				      /NULLIF(((' + @SumYangsan_Bep +')),0)*100
				  ELSE (' + @SumYangsan + ')
				END AS DECIMAL(18,2)) AS [양산합계]
			, CAST(
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumDev_Sale + ') / NULLIF((' + @SumDev_Qty + '),0))
            	  WHEN LTRIM(Cur.gubun) = N''영업이익률'' THEN
						  ((' + @SumDev_Op +'))
					      /NULLIF(((' + @SumDev_Sale + ')),0)*100
          		  WHEN LTRIM(Cur.gubun) = N''한계이익률'' THEN
					  ('+ @SumDev_Fix +')
				      /NULLIF(((' + @SumDev_Bep +')),0)*100
				  ELSE (' + @SumDev + ')
				END AS DECIMAL(18,2)) AS [개발합계]
			, CAST(	
				CASE
				  WHEN Cur.rn = 5 THEN 0
				  WHEN Cur.rn = 4 THEN ((' + @SumCas_Sale + ') / NULLIF((' + @SumCas_Qty + '),0))
				  ELSE (' + @SumCassette + ')
				END AS DECIMAL(18,2)) AS [카세트합계]

            , CAST( 
                CASE
                  WHEN Cur.rn = 5 THEN 0
                  WHEN Cur.rn = 4 THEN ((' + @SumPur_Sale + ') / NULLIF((' + @SumPur_Qty + '),0))
                  ELSE (' + @SumPurchase + ')
                END AS DECIMAL(18,2)) AS [구매합계]
		
		    -- 요청: 상품/기타매출은 NULL
		    , CAST(NULL AS DECIMAL(18,2)) AS [상품매출]
		    , CAST(NULL AS DECIMAL(18,2)) AS [기타매출]
		
		    , ' + @ModelSelectCols + N'
		FROM P Cur
		LEFT JOIN P Sales ON Sales.rn = 1 
		LEFT JOIN P Qty   ON Qty.rn   = 3
    	LEFT JOIN P Op    ON LTRIM(Op.gubun) = N''VIII. 영업이익''
    	LEFT JOIN P Bep   ON LTRIM(Bep.gubun) LIKE N''X. 손익분기점%''
		ORDER BY TRY_CONVERT(INT, Cur.rn);
		';
		
		--SELECT @SQL;
		EXEC sp_executesql @SQL, N'@SCOF DECIMAL(18,2)', @SCOF = @SCOFTotal;

        DROP TABLE #BASE;
        DROP TABLE #RN;
        DROP TABLE #MODEL;
        DROP TABLE #SALES_BASE;
        DROP TABLE #VAR;
        DROP TABLE #FIX;
        DROP TABLE #SKL_LAB; DROP TABLE #SKL_EXP; DROP TABLE #SKL_SGA;       

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT 
         ERROR_NUMBER()  AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE()   AS ErrorState,
        ERROR_LINE()    AS ErrorLine,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_MESSAGE() AS ErrorMessage;
       
    THROW;   
    END CATCH
END;

GO
