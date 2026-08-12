CREATE   PROCEDURE UP_DOI_EXPEN_MATL
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

    -- ======================================================================
    -- STEP 1: 기본 데이터 체크
    -- 체크대상: DOI_ACCT, DOI_DEPT, DOI_DEPT_COST, V_DOI_PROD_SUBUL,
    --          DOI_MODEL_MAST, DOI_CST_RATE
    -- ======================================================================
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


    -- ======================================================================
    -- STEP 2: 생산수불 조정 (ADJ_DOI_PROD_SUBUL 호출)
    -- 창고 입고수량을 생산수불 FAB OUT 수량 및 EOH 수량으로 조정
    -- ======================================================================
  	DECLARE @Ret_M nvarchar(MAX)='';  --2026.01.05 임시로 막음
	EXEC ADJ_DOI_PROD_SUBUL
		@YYYYMM = @YYYYMM,
		@SITE = @SITE,
		@R_Message = @Ret_M OUTPUT;
      SET  @Message = ISNULL(@Message,'') + ISNULL(@Ret_M,'') ;	
	

    -- ======================================================================
    -- STEP 3: DOI_ACCT_EXPEN 삭제 후 생성
    -- 부서별 계정과목 투입비용을 DOI_ACCT_EXPEN에 집계
    -- ======================================================================
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
			차변금액 - 대변금액 as ACCT_AMT,
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

     

    -- ======================================================================
    -- STEP 5: DOI_EXPEN_MATL 핵심 배부 (UTG 모델별)
    -- CTE: MODEL_SUBUL → MODEL_RATE → vina_cst_expen → sum_expen
    -- 출력: #EXPEN_AMT (임시테이블) → DOI_EXPEN_MATL (INSERT)
    -- ======================================================================
      DELETE FROM DOI_EXPEN_MATL
      WHERE 1=1
 		and yyyymm = @YYYYMM
        and site  = @SITE
		and sel_code = @SEL_CODE;
      
      SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';
 
WITH MODEL_SUBUL AS ( 
    -- [1] 모델별 배부 기준(물량/면적) 계산
    SELECT
        a.YYYYMM,
        a.site AS site,
        a.구분,
        -- [변경] 2026-07-14 818VT 도우코드는 별도 모델로 분리
        -- [사유] 818V/818VT 두 제품이 도우모델(818V)로 합산되어 수기와 불일치
        CASE WHEN a.도우코드 = '818VT' THEN '818VT' ELSE a.도우모델 END AS MODEL,
        b.xy AS 면적,
        SUM((ISNULL(IN_MONTH,0) + ISNULL(기타입고_RMA_RW,0) + ISNULL(OUT_MONTH,0) + ISNULL(LOSS_MONTH,0)))/ 2.0 AS adj_qty, -- 정수 나눗셈 방지
        -- [변경] 2026-07-14 loss-only, 음수 LOSS 모델도 배부 포함 (수기와 동일)
        -- [사유] 818T,8192(loss-only) 및 8122,902K(음수LOSS) 모델의 노무비/경비 미배부로 수기 대비 차이 발생
        SUM((ISNULL(IN_MONTH,0) + ISNULL(기타입고_RMA_RW,0) + ISNULL(OUT_MONTH,0) + ISNULL(LOSS_MONTH,0)))/ 2.0 * b.xy AS dist_in,
        SUM(a.boh_month) AS boh_qty,
        SUM(a.in_month)  AS in_qty,
        SUM(a.eoh_month) AS eoh_qty,
        SUM(a.out_month) AS out_qty,
        SUM(a.loss_month) AS loss_qty,
        SUM(a.outetc_month) as outetc_qty,
        0 AS bad_qty,
        0 AS Transfer_qty,
		SUM(ISNULL(a.기타입고_RMA_RW,0)) AS ETC_IN_RMA_QTY,        
        a.Adj_YN
    FROM V_DOI_PROD_SUBUL A
    LEFT JOIN DOI_MODEL_MAST B ON (a.도우모델 = b.MODEL AND a.yyyymm = b.YYYYMM AND a.site = b.SITE)
    WHERE 1=1 
      AND a.yyyymm  = @YYYYMM
      AND a.site = @SITE
    GROUP BY a.YYYYMM, a.site, CASE WHEN a.도우코드 = '818VT' THEN '818VT' ELSE a.도우모델 END, a.구분, b.xy, a.Adj_YN
),MODEL_RATE AS ( 
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
        Adj_yn,
        outetc_qty,
    	ETC_IN_RMA_QTY
    FROM MODEL_SUBUL
), vina_cst_expen as (
	select *,   
	    Base_IN + CASE WHEN RN = 1 THEN round(sum(Target_Total) over() - sum(Base_IN) over(),0) ELSE 0  END AS ACCT_AMT_ADJ
	FROM (
        SELECT
            a.*,
            a.ACCT_AMT * c.UTG AS Target_Total,
            ROUND(a.ACCT_AMT * c.UTG, 0) AS Base_IN,
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
		      AND a.acct LIKE '5%' 
		      AND a.acct NOT LIKE '51%'
		      AND a.dept NOT IN ('400','448')
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
--    ROUND((cast(Ori_IN as float)/adj_qty)*boh_qty,0) as boh,
    Final_IN,
    disp_seq,Adj_YN,outetc_qty,ETC_IN_RMA_QTY,
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
                b.adj_qty, b.boh_qty, b.in_qty, b.eoh_qty, b.out_qty, b.loss_qty, b.bad_qty, b.transfer_qty,b.Adj_YN,b.outetc_qty,b.ETC_IN_RMA_QTY,
                a.disp_seq,
                
                -- 원본 총 금액 (Target)
                a.total AS Original_Total,
                --ROUND(a.total / 2.0, 0) AS Original_BOH_Total, -- BOH는 Total의 절반(반올림)이 목표라고 가정
                coalesce(c.경비기초,0) AS BOH_AMT,

                -- 1차 배부 (IN) : 소수점 2자리
                ROUND(a.total * b.dist_rate, 0) AS Base_IN,
                a.total * b.dist_rate as Ori_IN,
   
-- 1차 배부 (BOH) : 정수 반올림
             ROUND(a.total * b.dist_rate / 2.0, 0) AS Base_BOH

            FROM sum_expen a
            INNER JOIN MODEL_RATE b ON (1=1) --b.dist_rate > 0.0 -- Cross Join 성격 (비율 있는 모델에 배부)
            LEFT JOIN DOI_BOH_AMT c ON (b.yyyymm=c.yyyymm and b.site=c.site and b.model=c.model and b.구분=c.구분)
) A
  ) T
) Final
ORDER BY disp_seq, model;


    -- ======================================================================
    -- STEP 6: 전월 기초금액(BOH) 배부
    -- #EXPEN_AMT의 IN 금액 비율로 BOH 금액을 배부
    -- ======================================================================
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
disp_seq,in_ori,ADJ_YN,UnitCost_YN,outetc_qty,ETC_IN_RMA_QTY
)
SELECT YYYYMM,sel_code,SITE,구분,model,면적,dist_rate,dist_in,SUB_NAME,ACCT_NAME,EXPEN_SEL,EXPEN_SEL명,adj_qty,
		boh_qty,in_qty,eoh_qty,out_qty,loss_qty,bad_qty,transfer_qty,unit_cost,Final_BOH as boh,Final_IN as [in],
		disp_seq,0 in_ori,ADJ_YN,UnitCost_YN,outetc_qty,ETC_IN_RMA_QTY
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
				ROUND(BOH * ACCT_RATE, 0) AS Base_Boh,
				SUM(ROUND(BOH * ACCT_RATE, 0)) OVER (PARTITION BY 구분, model) as Sum_Base_Boh,
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

    -- ======================================================================
    -- STEP 7: VINA 카세트 양산 배부
    -- 카세트팀 금액 중 VINA 카세트를 수출비중으로 배부
    -- ======================================================================
WITH VINA_CST_EXPEn as (
	select *,   
	    Base_IN + CASE WHEN RN = 1 THEN round(sum(Target_Total) over() - sum(Base_IN) over(),0) ELSE 0  END AS ACCT_AMT_ADJ
	FROM (
	    SELECT 
	        A.*,
	        ROW_NUMBER() OVER (ORDER BY Target_Total DESC) AS RN
	    FROM (
	        SELECT
	            a.*,
	            a.ACCT_AMT * c.VINA_CST AS Target_Total,
	            ROUND(a.ACCT_AMT * c.VINA_CST, 0) AS Base_IN
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
    Base_IN + CASE WHEN RN = 1 THEN ROUND((Target_Total - Grp_Sum_IN),0) ELSE 0  END AS [IN],
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
            ROUND(SUM(a.ACCT_AMT_ADJ * d.rate), 0) AS Base_IN

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
	

    -- ======================================================================
    -- STEP 8: 전월 EOH → 당월 BOH 이월 + 단가 업데이트
    -- 전월 DOI_COST의 EOH를 당월 DOI_EXPEN_MATL의 BOH로 MERGE
    -- ======================================================================
		DECLARE @PREV_MONTH VARCHAR(6);
		SELECT @PREV_MONTH=FORMAT(DATEADD(MONTH, -1, @YYYYMM  + '01'), 'yyyyMM');
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
    
	SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 ' + CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END 
       +@PREV_MONTH + '월 EOH금액, 수량을 ' +@YYYYMM + '월 BOH 금액,수량으로 '+CAST(@@ROWCOUNT AS VARCHAR) +'건 가져 왔습니다';


	UPDATE DOI_EXPEN_MATL SET unit_cost = COALESCE((BOH + [IN])/ 
				 NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0),0)
     WHERE 1=1
       AND YYYYMM	= @YYYYMM
       AND SITE 	= @SITE
       AND SEL_CODE = @SEL_CODE;
     SET  @Message =  @Message + char(10) + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 ' + CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END 
      	 +@YYYYMM + '월 단가(unit_cost) '+CAST(@@ROWCOUNT AS VARCHAR) +'건 업데이트 헸습니다'; 
	--전월 EOH금액 복사 END


    -- ======================================================================
    -- STEP 9: RMA 재투입 데이터 추가
    -- 기타입고_RMA_RW가 있는 모델의 RMA 원가를 DOI_EXPEN_MATL에 INSERT
    -- ======================================================================
	DECLARE @RMA_RW_CNT INT = 0;
	
	;WITH ETC_IN_RMA_QTY AS
	(
	    SELECT
	        p.YYYYMM,
	        p.SITE,
	        p.SEL_CODE,
	        '양산' AS 구분,
	        LEFT(p.도우코드, 4) AS MODEL,
	        SUM(ISNULL(p.기타입고_RMA_RW, 0)) AS ETC_IN_RMA_QTY
	    FROM DOI_PROD_SUBUL p
	    WHERE p.YYYYMM = @YYYYMM
	      AND p.SITE = @SITE
	      AND p.SEL_CODE = @SEL_CODE
	      AND ISNULL(p.기타입고_RMA_RW, 0) <> 0
	    GROUP BY
	        p.YYYYMM,
	        p.SITE,
	        p.SEL_CODE,
	        LEFT(p.도우코드, 4)
	),
	PREV_RMA_UNIT AS
	(
	    SELECT
	        s.MODEL,
	        CASE
	            WHEN SUM(ISNULL(s.EOH, 0)) = 0 THEN 0
	            ELSE SUM(ISNULL(s.EOH_AMT, 0)) / NULLIF(SUM(ISNULL(s.EOH, 0)), 0)
	        END AS RMA_UNIT_COST
	    FROM DOI_STCO s
	    WHERE s.YYYYMM = '202512'
	      AND s.SITE = @SITE
	      AND s.SEL_CODE = @SEL_CODE
	      AND s.구분 = 'RMA'
	    GROUP BY s.MODEL
	),
	CURR_QTY AS
	(
	    SELECT
	        v.구분,
	        v.도우모델 AS MODEL,
	        SUM(ISNULL(v.BOH_MONTH, 0)) AS BOH_QTY,
	        SUM(ISNULL(v.IN_MONTH, 0)) AS IN_QTY,
	        SUM(ISNULL(v.EOH_MONTH, 0)) AS EOH_QTY,
	        SUM(ISNULL(v.OUT_MONTH, 0)) AS OUT_QTY,
	        SUM(ISNULL(v.LOSS_MONTH, 0)) AS LOSS_QTY,
	        SUM(ISNULL(v.OUTETC_MONTH, 0)) AS OUTETC_QTY,
	        SUM(ISNULL(v.IN_MONTH, 0) + ISNULL(v.OUT_MONTH, 0) + ISNULL(v.LOSS_MONTH, 0) + ISNULL(v.기타입고_RMA_RW, 0)) / 2.0 AS ADJ_QTY,
	        MAX(v.ADJ_YN) AS ADJ_YN
	    FROM V_DOI_PROD_SUBUL v
	    WHERE v.YYYYMM = @YYYYMM
	      AND v.SITE = @SITE
	    GROUP BY
	        v.구분,
	        v.도우모델
	)
	INSERT INTO DOI_EXPEN_MATL
	(
	    YYYYMM,
	    SEL_CODE,
	    SITE,
	    구분,
	    MODEL,
	    면적,
	    dist_rate,
	    dist_in,
	    SUB_NAME,
	    ACCT_NAME,
	    EXPEN_SEL,
	    EXPEN_SEL명,
	    adj_qty,
	    boh_qty,
	    in_qty,
	    eoh_qty,
	    out_qty,
	    loss_qty,
	    bad_qty,
	    transfer_qty,
	    unit_cost,
	    boh,
	    [in],
	    disp_seq,
	    in_ori,
	    ADJ_YN,
	    UnitCost_YN,
	    outetc_qty,
	    ETC_IN_RMA_QTY
	)
	SELECT
	    q.YYYYMM,
	    q.SEL_CODE,
	    q.SITE,
	    q.구분,
	    q.MODEL,
	    0 AS 면적,
	    0 AS dist_rate,
	    0 AS dist_in,
	    'RMA_RW' AS SUB_NAME,
	    'RMA_RW' AS ACCT_NAME,
	    'RMA1' AS EXPEN_SEL,
	    'RMA_RW' AS EXPEN_SEL명,
	    ISNULL(c.ADJ_QTY, 0) AS adj_qty,
	    ISNULL(c.BOH_QTY, 0) AS boh_qty,
	    ISNULL(c.IN_QTY, 0) AS in_qty,
	    ISNULL(c.EOH_QTY, 0) AS eoh_qty,
	    ISNULL(c.OUT_QTY, 0) AS out_qty,
	    ISNULL(c.LOSS_QTY, 0) AS loss_qty,
	    0 AS bad_qty,
	    0 AS transfer_qty,
	    ISNULL(u.RMA_UNIT_COST, 0) AS unit_cost,
	    0 AS boh,
	    0 AS [in],
	    999 AS disp_seq,
	    0 AS in_ori,
	    ISNULL(c.ADJ_YN, 'Y') AS ADJ_YN,
	    1 AS UnitCost_YN,
	    ISNULL(c.OUTETC_QTY, 0) AS outetc_qty,
	    q.ETC_IN_RMA_QTY
	FROM ETC_IN_RMA_QTY q
	LEFT JOIN PREV_RMA_UNIT u
	  ON q.MODEL = u.MODEL
	LEFT JOIN CURR_QTY c
	  ON q.구분 = c.구분
	 AND q.MODEL = c.MODEL;
	
	SET @RMA_RW_CNT = @@ROWCOUNT;
	
	SET @Message = @Message + CHAR(10) + CHAR(10)
	    + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
	    + '- 경비집계(DOI_EXPEN_MATL) 테이블에 '
	    + CASE WHEN @SITE = 'HQ' THEN '본사' ELSE 'VINA' END
	    + @YYYYMM + '월 RMA 재투입금액(RMA_RW) '
	    + CAST(@RMA_RW_CNT AS VARCHAR) + '건을 추가했습니다';      	
   	
      -- ========================================

    -- ======================================================================
    -- STEP 10: 데이터 무결성 검증 + 로그 기록
    -- 소스(DOI_ACCT_EXPEN) vs 타겟(DOI_EXPEN_MATL) 금액 비교
    -- ======================================================================
      DECLARE @SOURCE_AMT BIGINT = 0,
 @TARGET_AMT BIGINT = 0,
              @DIFF_AMT BIGINT = 0,
              @FILTERED_AMT BIGINT = 0,
              @CASSETTE_AMT BIGINT = 0;
      
      -- 필터링된 금액 계산
      SELECT @FILTERED_AMT = ISNULL(SUM(CAST(ACCT_AMT AS BIGINT)), 0)
      FROM DOI_ACCT_EXPEN
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE
        AND ACCT LIKE '5%' AND ACCT NOT LIKE '51%' /*AND DEPT NOT IN ('448','400')*/;
      
      SELECT @CASSETTE_AMT = ISNULL(SUM(CAST((A.ACCT_AMT * B.VINA_CST * D.RATE) AS BIGINT)), 0)
      FROM DOI_ACCT_EXPEN  A 
      LEFT JOIN DOI_CST_RATE B ON (A.YYYYMM=B.YYYYMM AND A.SITE=B.SITE)
      LEFT JOIN DOI_VNCST_RATE D ON (A.YYYYMM=D.YYYYMM AND A.SITE=D.SITE)
      WHERE a.yyyymm = @YYYYMM AND A.site = @SITE AND A.sel_code = @SEL_CODE AND  DEPT IN ('448','400');
      
      SELECT @TARGET_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
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
      WHERE yyyymm = @YYYYMM AND site = @SITE AND sel_code = @SEL_CODE AND ACCT LIKE '5%' AND ACCT NOT LIKE '51%';
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '소스(DOI_ACCT_EXPEN)' + REPLICATE(' ', 10) + RIGHT(REPLICATE(' ', 10) + CAST(@SOURCE_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@SOURCE_AMT, 'N0'), 20) + '원';
      
      -- 타겟 상세
      DECLARE @TARGET_CNT INT = 0;
      SELECT @TARGET_CNT = COUNT(*) FROM DOI_EXPEN_MATL WHERE YYYYMM = @YYYYMM AND SITE = @SITE AND sel_code = @SEL_CODE;
      
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '타겟(DOI_EXPEN_MATL)' + REPLICATE(' ', 10) + RIGHT(REPLICATE(' ', 10) + CAST(@TARGET_CNT AS VARCHAR(10)), 10) + REPLICATE(' ', 4) + RIGHT(REPLICATE(' ', 20) + FORMAT(@TARGET_AMT, 'N0'), 20) + '원';
      SET  @Message =  @Message + char(10) + '----------------------------------------------------------------------------------------------------';
      SET  @Message =  @Message + char(10) + REPLICATE(' ', 10) + '차이' + REPLICATE(' ', 40) + RIGHT(REPLICATE(' ', 20) + FORMAT(@DIFF_AMT, 'N0'), 20) + '원';
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
          SET  @Message = @Message + char(10) + '====================================================================================================';
          
          DECLARE @EXPEN_SEL NVARCHAR(50), @EXPEN_NAME NVARCHAR(100);
          DECLARE @SOURCE_ITEM_AMT BIGINT, @TARGET_ITEM_AMT BIGINT, @ITEM_DIFF BIGINT;
          
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
                AND A.ACCT LIKE '5%' AND A.ACCT NOT LIKE '51%';
              
              -- [타겟 금액 가져오기]
              SELECT @TARGET_ITEM_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
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
                      + RIGHT(REPLICATE(' ', 15) + FORMAT(@SOURCE_ITEM_AMT, 'N0'), 15)
                      + RIGHT(REPLICATE(' ', 17) + FORMAT(@TARGET_ITEM_AMT, 'N0'), 17)
                      + RIGHT(REPLICATE(' ', 15) + FORMAT(@ITEM_DIFF, 'N0'), 15);
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
                AND A.ACCT LIKE '5%' AND A.ACCT NOT LIKE '51%';
          SELECT @TARGET_ITEM_AMT = ISNULL(CAST(SUM([IN]) AS BIGINT), 0)
              FROM DOI_EXPEN_MATL
              WHERE YYYYMM = @YYYYMM 
                AND SITE = @SITE
          		AND sel_code = @SEL_CODE;
          SET @ITEM_DIFF = @SOURCE_ITEM_AMT - @TARGET_ITEM_AMT; 
          SET  @Message =  @Message + char(10) + '====================================================================================================';
          SET  @Message =  @Message + char(10) + REPLICATE(' ', 35) + '합계' + RIGHT(REPLICATE(' ', 30) + FORMAT(@SOURCE_AMT, 'N0'), 27)+ RIGHT(REPLICATE(' ', 17) + FORMAT(@TARGET_ITEM_AMT, 'N0'), 17) + RIGHT(REPLICATE(' ', 15) + FORMAT(@ITEM_DIFF, 'N0'), 15);
          
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

--     SELECT @Message AS before_log_message;                  
                       
     -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '경비 집계', 'UP_DOI_EXPEN_MATL', 'SUCCESS');
     
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
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '경비 집계', 'UP_DOI_EXPEN_MATL', 'FAIL');	
       SELECT @Message as retMessage;
       RETURN -1;
   END CATCH;
-- ======================================================================
-- 변경이력
-- ======================================================================
-- 2026-07-14: 818VT 도우코드 별도 모델 분리 (818V/818VT 합산 방지)
-- 2026-07-14: loss-only, 음수 LOSS 모델도 배부 포함 (818T,8192,8122,902K)
-- 2026-07-16: STEP 주석 표준화, 불필요 주석 블록 제거
-- ======================================================================

END;
