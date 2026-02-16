CREATE Procedure UP_DOI_MAT_COST
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
    
		WITH BOM as (
			select
				b.yyyymm as byyyymm,
				b.자재번호,
				b.제품명,
				CASE WHEN b.품목중분류='VINA CST' 	  THEN '양산' 
					 WHEN RIGHT(b.품목중분류,1) = 'P' THEN '양산'
					 WHEN RIGHT(b.품목중분류,1) = 'D' THEN '개발'
					 WHEN b.제품번호 LIKE 'H%' 		  THEN CASE WHEN SUBSTRING(b.제품번호,6,1)='D' THEN '개발' else '양산' END --HTG 제품
					 WHEN SUBSTRING(b.제품번호,5,1)='D' THEN '개발' 
					 ELSE '양산' END 구분b,
				--b.제품번호,
				--b.품목대분류,
				b.자재대분류,
				cast(sum(소요량) as numeric(38,25)) as  소요량,
				count(*) cnt,
				row_number() over (partition by b.자재번호,	b.제품명,
											CASE WHEN b.품목중분류='VINA CST' 	  THEN '양산' 
												 WHEN RIGHT(b.품목중분류,1) = 'P' THEN '양산'
												 WHEN RIGHT(b.품목중분류,1) = 'D' THEN '개발'
												 WHEN b.제품번호 LIKE 'H%' 		  THEN CASE WHEN SUBSTRING(b.제품번호,6,1)='D' THEN '개발' else '양산' END --HTG 제품
												 WHEN SUBSTRING(b.제품번호,5,1)='D' THEN '개발' 
												 ELSE '양산' END order by  b.자재대분류  desc)  as rn, 
				row_number() over (partition by b.자재번호 order by (case when b.자재번호 in('DWR00001Z2','DWR00001Z1','AMF802MN01 0.0') then b.제품명 else  b.자재대분류 end) desc)  rn1 --select *
			from	doi_bom_mast b
			where 1=1
				and yyyymm=@YYYYMM
				and site=@SITE
				and nullif(자재번호, '') IS NOT NULL
				--and 공정차수 = '00'
			group by
				b.yyyymm,b.자재번호,	b.제품명,	
				CASE WHEN b.품목중분류='VINA CST' 	  THEN '양산' 
					 WHEN RIGHT(b.품목중분류,1) = 'P' THEN '양산'
					 WHEN RIGHT(b.품목중분류,1) = 'D' THEN '개발'
					 WHEN b.제품번호 LIKE 'H%' 		  THEN CASE WHEN SUBSTRING(b.제품번호,6,1)='D' THEN '개발' else '양산' END --HTG 제품
					 WHEN SUBSTRING(b.제품번호,5,1)='D' THEN '개발' 
					 ELSE '양산' END, b.자재대분류
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
			sum(a.OUTETC_MONTH) outetc_qty,
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
			inner join CHGQTY b on	(a.제품명 = b.도우모델 and a.구분b=b.구분 and case when a.자재번호 in('DWR00001Z2','DWR00001Z1','AMF802MN01 0.0') then rn1 else  rn end = 1)
			--order by 자재번호
		), MAT_COMM_RATE AS(
			select 
				a.*,
				case when 환산량=0 then 0  
					 else CAST((환산량 * b.xy) as NUMERIC(38,25)) / sum(환산량 * b.xy) over() end as comm_rate,
				b.xy,
				(환산량 * b.xy) as 배부적수
			from
				CHGQTY A
		  inner join DOI_MODEL_MAST B ON     --모델별 면적정보
	         (a.도우모델 = b.MODEL and b.YYYYMM = @YYYYMM and a.site = b.SITE)
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
			outetc_qty,
			환산량,
			소요량,
			배부율,
			--Final_BOH_Amt as BOH_AMT,
			Final_IN_Amt as 배부금액,
			사용량,
			배부방식,
			case when 환산량=0 then 0 else Final_IN_Amt/환산량 end as 단가,
			ADJ_YN 
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
						b.outetc_qty,
						b.환산량,
						b.소요량,
						b.배부율,
			--			round(a.in_amt * b.배부율,3) as 배부금액,
			--			ROUND(a.in_amt * b.배부율 / 2.0, 0) AS Base_BOH_Amt,
						a.in_amt * b.배부율 as Origin_IN_Amt,
						ROUND(a.in_amt * b.배부율,0) as Base_In_Amt,
						b.사용량,
						'BOM' AS 배부방식,
						b.ADJ_YN--TRUNCATE TABLE  DOI_MAT_COST
						-- sum(a.in_amt * b.배부적수)
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
			outetc_qty,
			환산량,
			xy,
			comm_rate,
			--Final_BOH_Amt,
			Final_Amt,
			사용량,
			배부방식,
			case when 환산량=0 then 0 else Final_Amt/환산량 end as 단가,
			ADJ_YN
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
					b.outetc_qty,
					b.환산량,
					CAST(b.xy as NUMERIC(38,25)) as xy,
					b.comm_rate,
					--ROUND(a.in_amt * b.comm_rate / 2.0, 0) AS Base_BOH_Amt,
					a.in_amt * b.comm_rate  as Origin_IN_Amt,
					round(a.in_amt * b.comm_rate,0) as Base_In_Amt,
					b.배부적수 as 사용량,
					'공통' as 배부방식,
					b.ADJ_YN
					-- sum(a.in_amt*b.comm_rate)
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
 Transfer_qty,outetc_qty,환산량,소요량,배부율,BOH_AMT ,배부금액,사용량,배부방식,단가,ADJ_YN)
SELECT yyyymm,sel_code,site,구분,도우모델,자재번호,mat_gubun,mat_class,자재대분류,in_amt,boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,
 Transfer_qty,outetc_qty,환산량,소요량,배부율,Final_BOH,배부금액,사용량,배부방식,
	COALESCE((Final_BOH + 배부금액)/ 
			 NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0),0) AS 단가,	ADJ_YN
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
					round(Tot_bohAmt * rate, 0) Base_Boh,
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
						round(IN_AMT/2 * CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE), 0) as Base_BOH_Amt,
						round(IN_AMT * CAST(b.총소요량 as INT)/sum(총소요량) over (partition by MAT_CODE), 0) as Base_IN_Amt,
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
   		
      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
      DECLARE @SOURCE_AMT BIGINT = 0,
              @TARGET_AMT BIGINT = 0,
              @DIFF_AMT BIGINT = 0,
           @SOURCE_CNT INT = 0,
              @TARGET_CNT INT = 0,
 @MODEL_CNT INT = 0;
      
 -- 1. 소스 데이터 (doi_mat_amt)
      SELECT @SOURCE_AMT = ISNULL(CAST(SUM(in_amt) AS BIGINT), 0),
             @SOURCE_CNT = COUNT(*)
      FROM doi_mat_amt
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE;
        --AND (sel_code = @SEL_CODE OR @SEL_CODE IS NULL OR @SEL_CODE = '');
      
      -- 2. 타겟 데이터 (DOI_MAT_COST) - 자재별로 그룹핑한 배부금액 합계
      SELECT @TARGET_AMT = ISNULL(CAST(SUM(배부금액) AS NUMERIC), 0),
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
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_CNT, 'N0'), 18)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@SOURCE_AMT, 'N0'), 18)+ '원';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
          + LEFT('타겟(DOI_MAT_COST) - 자재별' + REPLICATE(' ', 30), 28)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_CNT, 'N0'), 18)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@TARGET_AMT, 'N0'), 18)+ '원';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 5) 
          + LEFT('차이' + REPLICATE(' ', 40), 30)
          + RIGHT(REPLICATE(' ', 18) + '', 18)
          + RIGHT(REPLICATE(' ', 18) + FORMAT(@DIFF_AMT, 'N0'), 18)+ '원';
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
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '재료비 배부', 'UP_DOI_MAT_COST', 'SUCCESS');				
					
	COMMIT TRANSACTION;
	
	drop table #matCost
    SELECT @Message as retMessage;
    RETURN 0;     
	
	END TRY
   
	BEGIN CATCH
		SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
		INSERT INTO doi_execlog
		    values
		    (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '재료비 배부', 'UP_DOI_MAT_COST', 'FAIL');	
	ROLLBACK TRANSACTION;
		SELECT @Message as retMessage;
	END CATCH;
END;
