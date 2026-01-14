CREATE                                                                                                           Procedure UP_DOI_EXPEN_MATL
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
	
	/*SELECT @CNT = count(*)  --2026.01.05 
		FROM DOI_CASSETTE_RESC
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 카세트 발생비용(DOI_CASSETTE_RESC) 테이블에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
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
      SET  @Message =  @Message + @Ret_M + char(10);	
	      	
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
   
      DELETE FROM DOI_EXPEN_MATL
      WHERE 1=1
 		and yyyymm = @YYYYMM
        and site  = @SITE
		and sel_code = @SEL_CODE;
      
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';
 
WITH MODEL_SUBUL AS ( 
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
        0 AS bad_qty,
        0 AS Transfer_qty,
        a.Adj_YN
    FROM V_DOI_PROD_SUBUL A
    LEFT JOIN DOI_MODEL_MAST B ON (a.도우모델 = b.MODEL AND a.yyyymm = b.YYYYMM AND a.site = b.SITE)
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
    /*WHERE 1=1 
 AND a.yyyymm = @YYYYMM
 AND a.site = @SITE
      AND a.acct LIKE '5%' 
      AND a.acct NOT LIKE '51%'*/
    GROUP BY
        a.YYYYMM,
        a.SITE,
        b.EXPEN_SEL,
        b.EXPEN_SEL명,
        a.ACCT_NAME,
        CASE WHEN a.dept IN ('400','448') THEN 'CST' ELSE 'UTG' END,
        a.DISP_SEQ
)
INSERT INTO DOI_EXPEN_MATL (
    YYYYMM, SEL_CODE, SITE, 구분, model, 면적, dist_in, dist_rate, SUB_NAME, EXPEN_SEL, EXPEN_SEL명,ACCT_NAME,
    adj_qty, boh_qty, in_qty, eoh_qty, out_qty, loss_qty, bad_qty, transfer_qty,
    unit_cost, boh, [in], disp_seq,adj_yn,IN_Ori,UnitCost_YN
)
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
    --2025.12.19 수정
    COALESCE(
        (Final_BOH + Final_IN) 
        / NULLIF((eoh_qty / 2.0) + out_qty + bad_qty + transfer_qty + IIF(@SEL_CODE = 'ACTLSS',loss_qty,0), 0), 
        0
    ) AS unit_cost,
    Final_BOH AS boh,
--    Ori_IN/adj_qty as unit_cost,
--    ROUND((cast(Ori_IN as float)/adj_qty)*boh_qty,0) as boh,
    Final_IN AS [in],
    disp_seq,Adj_YN,0,
    row_number() over (partition by YYYYMM ,SEL_CODE ,SITE ,구분 ,model ,SUB_NAME ,EXPEN_SEL ,ACCT_NAME order by SUB_NAME, ADJ_YN DESC) as UnitCost_YN 
FROM (
    SELECT
        T.*,
        -- [4-3] 최종 보정: 1차 배부액 + (1등에게 잔액 몰아주기)
        -- IN 금액 보정
        Base_IN + CASE WHEN RN = 1 THEN (Original_Total - Sum_Base_IN) ELSE 0 END AS Final_IN,
        -- BOH 금액 보정
        Base_BOH + CASE WHEN RN = 1 THEN (Original_BOH_Total - Sum_Base_BOH) ELSE 0 END AS Final_BOH
    FROM (
        SELECT 
            A.*,
            -- [4-2] 그룹별(비용항목별) 배부 합계 계산
            SUM(Base_IN) OVER (PARTITION BY YYYYMM, SITE, EXPEN_SEL, SUB_NAME, a.ACCT_NAME, DISP_SEQ) AS Sum_Base_IN,
            SUM(Base_BOH) OVER (PARTITION BY YYYYMM, SITE, EXPEN_SEL, SUB_NAME, a.ACCT_NAME, DISP_SEQ) AS Sum_Base_BOH,
            
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
                b.adj_qty, b.boh_qty, b.in_qty, b.eoh_qty, b.out_qty, b.loss_qty, b.bad_qty, b.transfer_qty,b.Adj_YN,
                a.disp_seq,
                
                -- 원본 총 금액 (Target)
                a.total AS Original_Total,
                ROUND(a.total / 2.0, 0) AS Original_BOH_Total, -- BOH는 Total의 절반(반올림)이 목표라고 가정

                -- 1차 배부 (IN) : 소수점 2자리
                ROUND(a.total * b.dist_rate, 0) AS Base_IN,
                a.total * b.dist_rate as Ori_IN,
   
-- 1차 배부 (BOH) : 정수 반올림
             ROUND(a.total * b.dist_rate / 2.0, 0) AS Base_BOH

            FROM sum_expen a
            INNER JOIN MODEL_RATE b ON b.dist_rate > 0.0 -- Cross Join 성격 (비율 있는 모델에 배부)
        ) A
    ) T
) Final
ORDER BY disp_seq, model;

SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + 'UTG 부서별 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계했습니다';
 --VINA 카세트 양산 배부 (카세트팀 금액중 VINA 카세트를 비바 카세트 수출비중으로 배부함)
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

      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + 'CST 부서별 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계했습니다';
      --카세팀 입력
      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
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
          SET  @Message =  @Message + char(10) + '====================================================================================================';
          
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

     -- 로그 테이블 기록
	 INSERT INTO doi_execlog
	 values
	 (@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '경비 집계', 'UP_DOI_EXPEN_MATL', 'SUCCESS');
      
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
       	 values
	 	(@YYYYMM, @SEL_CODE, @SITE, getdate(), @Message, 'system', '매출상계', 'UP_DOI_SCOF', 'FAIL');	
       SELECT @Message as retMessage;
       RETURN -1;
   END CATCH;
END;