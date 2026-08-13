CREATE   procedure UP_DOI_STOCK_COST
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(2),  --사업장코드 (본사 : HQ, 베트남 : VN)
    @SEL_CODE varchar(10),
 	@R_Message nvarchar(MAX) OUTPUT
)
AS
BEGIN
BEGIN TRY
SET NOCOUNT ON;
    SET LOCK_TIMEOUT 5000; -- 10초로 증가
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- 격리 수준 변경
--    DECLARE  @R_Message  NVARCHAR(MAX)='';

   DECLARE @CNT INT = 0,
       @CHECK BIT = 0;
   

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
      
	 SET  @R_Message =   char(10) + @R_Message + char(10) + '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '
			+ @YYYYMM + '월 '+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '제품수불금액 집계를 시작합니다'; 
   
   --데이타 체크
    IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('DOI_COST') AND type in ('U')) -- 테이블 존재 여부 확인
    BEGIN
		SELECT @CNT = count(*)
		FROM DOI_COST
		      WHERE yyyymm	= @YYYYMM
		        and site  	= @SITE
   				and sel_code= @SEL_CODE;
		IF @CNT = 0 BEGIN
		SET  @R_Message =  @R_Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비 배부(DOI_COST) 테이블에 '
		+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
		END
		ELSE
		BEGIN
		SET  @R_Message =  @R_Message + char(10) + '[CHECK]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 가공비 배부(DOI_COST) 테이블에 '
		+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 '+CAST(@CNT AS VARCHAR)+'건 정상입니다'
		END
	END
    ELSE
    BEGIN
        SET  @R_Message =  @R_Message + char(10) + '[ERROR] ' +  '가공비 배부(DOI_COST)테이블이 존재하지 않습니다.';
        SET @CHECK = 1;
    END

    -- 1초 대기
	-- WAITFOR DELAY '00:00:01';
    
	SELECT @CNT = count(*)
	FROM DOI_STOCK_BOH
	      WHERE yyyymm	 = @YYYYMM
	        and site  	 = @SITE
			and sel_code = @SEL_CODE;
	IF @CNT = 0 BEGIN
	SET  @R_Message =  @R_Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품BOH(DOI_STOCK_BOH) 테이블에 '
	+@YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
	SET @CHECK = 1;
	END
	ELSE
	BEGIN
	SET  @R_Message =  @R_Message + char(10) + '[CHECK]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품BOH(DOI_STOCK_BOH) 테이블에 '
	+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 '+CAST(@CNT AS VARCHAR)+'건 정상입니다'
	END

	SELECT @CNT = count(*)
	FROM DOI_STOCK
	      WHERE yyyymm=@YYYYMM
	        and site  =@SITE;
	IF @CNT = 0 BEGIN
	SET  @R_Message =  @R_Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불(DOI_STOCK) 테이블에 '
	+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
	SET @CHECK = 1;
	END
	ELSE
	BEGIN
	SET  @R_Message =  @R_Message + char(10) + '[CHECK]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불(DOI_STOCK) 테이블에 '
	+ @YYYYMM + '월 ' + CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + ' 데이타가 '+CAST(@CNT AS VARCHAR)+'건 정상입니다'
	END
	
	IF @CHECK = 1 BEGIN
	RETURN -1;
	END

	BEGIN TRANSACTION;
	
	DELETE FROM DOI_STCO 
	WHERE YYYYMM	= @YYYYMM
	  AND SITE		= @SITE
	  AND SEL_CODE  = @SEL_CODE;	
	SET  @R_Message =  @R_Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '+@YYYYMM + '월 '
	+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '제품수불금액 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';
	
	-- 202601은 수동 보정 완료된 doi_stco_202601 데이터를 그대로 사용
--	IF @YYYYMM = '202601'
--	BEGIN
--	    INSERT INTO DOI_STCO
--	    (
--	        YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,
--	        BOH, [INPUT], [OUT], EOH, INETC, OUTETC,
--	        BOH_AMT, IN_AMT, EOH_AMT, OUT_AMT, INETC_AMT, OUTETC_AMT,
--	        RMAIN_QTY, RMAIN_AMT, AREAOUT_QTY, AREAOUT_AMT
--	    )
--	    SELECT
--	        YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,
--	        BOH, [INPUT], [OUT], EOH, INETC, OUTETC,
--	        BOH_AMT, IN_AMT, EOH_AMT, OUT_AMT, INETC_AMT, OUTETC_AMT,
--	        RMAIN_QTY, RMAIN_AMT, AREAOUT_QTY, AREAOUT_AMT
--	    FROM DOI_STCO_202601
--	    WHERE YYYYMM   = @YYYYMM
--	      AND SITE     = @SITE
--	      AND SEL_CODE = @SEL_CODE;
--	
--	    SET @R_Message = @R_Message + CHAR(10)
--	        + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
--	        + '- 제품수불금액(DOI_STCO) 테이블에 ' + @YYYYMM + '월 '
--	        + CASE WHEN @SITE = 'HQ' THEN '본사' ELSE 'VINA' END
--	        + ' 수동집계 데이터(DOI_STCO_202601) '
--	        + CAST(@@ROWCOUNT AS VARCHAR) + '건을 입력했습니다';
--	
--	    SET @R_Message = @R_Message + CHAR(10)
--	        + '  [END]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9)
--	        + '- 제품수불금액(DOI_STCO) 테이블에 ' + @YYYYMM + '월 '
--	        + CASE WHEN @SITE = 'HQ' THEN '본사' ELSE 'VINA' END
--	        + ' 수동집계 데이터 반영 완료했습니다';	      
--	       
--	    COMMIT TRANSACTION;
--	    RETURN 0;
--	END;

-- expen_sel (원가항목) 기준으로 집계하도록 수정
	;WITH MODEL_IN_AMT AS (
	    SELECT 
	        a.YYYYMM, 
	        a.SITE, 
	        a.MODEL, 
	        a.구분, 
	        a.EXPEN_SEL,
	        a.EXPEN_SEL명,
	        a.ACCT_NAME, 
	        SUM(ISNULL(a.[OUT], 0)) AS IN_AMT
	    FROM DOI_COST a 
	    WHERE a.YYYYMM = @YYYYMM
	      AND a.SITE = @SITE
	      AND a.SEL_CODE = @SEL_CODE
	      AND a.EXPEN_SEL <> 'NONE'
	    GROUP BY 
	        a.YYYYMM, a.SITE, a.MODEL, a.구분,
	        a.EXPEN_SEL, a.EXPEN_SEL명, a.ACCT_NAME
	),
	MODEL_BOH_AMT AS (
	 SELECT 
        a.YYYYMM, 
        a.SITE, 
        a.MODEL, 
        a.구분, 
        a.EXPEN_SEL, 
        a.EXPEN_SEL명,
        a.ACCT_NAME,
        SUM(ISNULL(a.BOH_AMT, 0)) AS BOH_AMT,
        SUM(ISNULL(a.INETC_AMT, 0)) AS INETC_AMT,
        SUM(ISNULL(a.OUTETC_AMT, 0)) AS OUTETC_AMT
    FROM DOI_STOCK_BOH a 
    WHERE a.YYYYMM = @YYYYMM
      AND a.SITE = @SITE
      AND a.SEL_CODE = @SEL_CODE
    GROUP BY 
        a.YYYYMM, a.SITE, a.MODEL, a.구분,
        a.EXPEN_SEL, a.EXPEN_SEL명, a.ACCT_NAME
	),
	MODEL_STOCK AS (
	    SELECT
	        a.YYYYMM,
	        a.SITE,
	        @SEL_CODE AS SEL_CODE,
	        CASE
	            -- cassette products (numeric-ending code): map by 2nd-to-last char (e.g. VN034P1 -> 'P')
	            WHEN RIGHT(a.MODEL_TYPE, 1) LIKE '[0-9]' THEN
	                CASE
	                    WHEN SUBSTRING(a.MODEL_TYPE, LEN(a.MODEL_TYPE) - 1, 1) = 'P' THEN N'양산'
	                    WHEN SUBSTRING(a.MODEL_TYPE, LEN(a.MODEL_TYPE) - 1, 1) = 'R' THEN N'RMA'
	                    ELSE N'개발'
	                END
	            WHEN RIGHT(a.MODEL_TYPE, 1) = 'P' THEN N'양산'
	            WHEN RIGHT(a.MODEL_TYPE, 1) = 'R' THEN N'RMA'
	            ELSE N'개발'
	        END AS 구분,
	        a.MODEL,
	        SUM(ISNULL(a.BOH, 0)) AS BOH,
	        SUM(ISNULL(a.INPUT_PROD, 0)) AS [INPUT],
	        SUM(ISNULL(a.OUT_SHEET, 0) + ISNULL(a.OUT_INVOICE, 0)) AS [OUT],
	        SUM(ISNULL(a.EOH, 0)) AS EOH,
	        SUM(ISNULL(a.INPUT_ETC, 0)) AS INETC,
	        SUM(ISNULL(a.OUT_ETC, 0)) AS OUTETC,
--	        SUM(ISNULL(a.작업실적, 0)) AS 작업실적,
	        SUM(ISNULL(a.기타입고, 0)) AS IN_OTHER_QTY,
--	        SUM(ISNULL(a.재고실사입고조정, 0)) AS IN_INV_ADJ_QTY,
	        SUM(ISNULL(a.RMA_반품입고, 0)) AS RMA_IN_QTY,
	        SUM(ISNULL(a.RMA_반품출고, 0)) AS OUT_RMA_QTY,
	        SUM(ISNULL(a.공정재투입, 0)) AS OUT_REWORK_QTY,
	        SUM(ISNULL(a.연구개발, 0)) AS OUT_RND_QTY,
	        SUM(ISNULL(a.기술평가, 0)) AS OUT_TECH_EVAL_QTY,
	        SUM(ISNULL(a.출하검사, 0)) AS OUT_SHIP_INSP_QTY,
	 SUM(ISNULL(a.폐기, 0)) AS OUT_DISPOSE_QTY,
	        SUM(ISNULL(a.재고실사출고조정, 0)) AS OUT_INV_ADJ_QTY,
	        SUM(ISNULL(a.기타, 0)) AS OUT_OTHER_QTY
	    FROM DOI_STOCK a
	    WHERE a.YYYYMM = @YYYYMM
	      AND a.SITE = @SITE
	      AND a.SEL_CODE = @SEL_CODE
	    GROUP BY 
	        a.YYYYMM,
	        a.SITE,
	        a.MODEL,
	        CASE
	            -- cassette products (numeric-ending code): map by 2nd-to-last char (e.g. VN034P1 -> 'P')
	            WHEN RIGHT(a.MODEL_TYPE, 1) LIKE '[0-9]' THEN
	                CASE
	                    WHEN SUBSTRING(a.MODEL_TYPE, LEN(a.MODEL_TYPE) - 1, 1) = 'P' THEN N'양산'
	                    WHEN SUBSTRING(a.MODEL_TYPE, LEN(a.MODEL_TYPE) - 1, 1) = 'R' THEN N'RMA'
	                    ELSE N'개발'
	                END
	            WHEN RIGHT(a.MODEL_TYPE, 1) = 'P' THEN N'양산'
	            WHEN RIGHT(a.MODEL_TYPE, 1) = 'R' THEN N'RMA'
	            ELSE N'개발'
	        END
	),
	DIM_EXPEN AS (
	    SELECT         
	    	x.*,
        ROW_NUMBER() OVER (
            PARTITION BY x.MODEL, x.구분
            ORDER BY
                CASE WHEN x.EXPEN_SEL = 'RMA1'
                       AND x.ACCT_NAME = N'RMA1'
                     THEN 0 ELSE 1 END,
                x.EXPEN_SEL,
                x.ACCT_NAME
        ) AS RN_MODEL
	    FROM (
	        SELECT MODEL, 구분, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME FROM MODEL_IN_AMT
	        UNION
	        SELECT MODEL, 구분, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME FROM MODEL_BOH_AMT
	    ) x
	    WHERE ACCT_NAME IS NOT NULL
	),
	STUC_RMA_LATEST AS (
	    SELECT *
	    FROM (
	        SELECT
	            s.YYYYMM,
	            s.SEL_CODE,
	            s.SITE,
	            s.구분,
	            s.MODEL,
	            s.EXPEN_SEL,
	            s.ACCT_NAME,
	            s.OUT_UNITCOST AS RMA_UNITCOST,
	            ROW_NUMBER() OVER (
	                PARTITION BY
	                    s.SEL_CODE,
	                    s.SITE,
	                    s.구분,
	                    s.MODEL,
	                    s.EXPEN_SEL,
	                    s.ACCT_NAME
	                ORDER BY s.YYYYMM DESC
	            ) AS RN
	        FROM DOI_STUC s
	        WHERE s.YYYYMM < @YYYYMM
	          AND s.SITE = @SITE
	          AND s.SEL_CODE = @SEL_CODE
	          AND s.EXPEN_SEL = 'RMA1'
	          AND s.ACCT_NAME = N'RMA1'
	          AND COALESCE(s.OUT_UNITCOST, 0) <> 0
	    ) x
	    WHERE RN = 1
	),
	MODEL_EOH_AMT AS (
	    SELECT 
	        YYYYMM,
	        SITE,
	        SEL_CODE,
	        구분,
	        MODEL,
	        expen_sel,
	        expen_sel명,
	        acct_name,
	        BOH,
	        [INPUT],
	        [OUT],
	        EOH,
	        INETC,
	        OUTETC,
	        BOH_AMT,
	        IN_AMT,
	        Final_Eoh AS EOH_AMT,
	        coalesce(INETC_AMT,0) INETC_AMT,
	        --CASE WHEN OUTETC != 0 then BOH_AMT +  IN_AMT - Final_Eoh ELSE 0 END as OUTETC_AMT
/*	        Final_OUTETC as OUTETC_AMT,*/
	        IN_OTHER_QTY,
			RMA_IN_QTY,
			OUT_RMA_QTY,
			OUT_REWORK_QTY,
			OUT_RND_QTY,
			OUT_TECH_EVAL_QTY,
			OUT_SHIP_INSP_QTY,
			OUT_DISPOSE_QTY,
			OUT_INV_ADJ_QTY,
			OUT_OTHER_QTY,
	        0 AS IN_OTHER_AMT,
            coalesce(OUT_RMA_AMT,0) + coalesce(OUT_DISPOSE_AMT,0) + coalesce(OUT_RND_AMT,0) + coalesce(OUT_OTHER_AMT,0) AS OUTETC_AMT,
			RMA_IN_AMT,
			OUT_RMA_AMT,
			0 AS OUT_REWORK_AMT,
			OUT_RND_AMT,
			0 AS OUT_TECH_EVAL_AMT,
			0 AS OUT_SHIP_INSP_AMT,
			OUT_DISPOSE_AMT,
			0 AS OUT_INV_ADJ_AMT,
			OUT_OTHER_AMT
	    FROM (
	        SELECT 
	            t.*, 
--	  Base_OUTETC_AMT + CASE WHEN rn_outetc = 1 THEN ROUND(Ori_OUTETC_total - Base_OUTETC_total, 0) ELSE 0 END AS Final_OUTETC,
	            Base_EOH_AMT + CASE WHEN rn_eoh = 1 THEN ROUND(Ori_total - Base_total, 0) ELSE 0 END AS Final_Eoh
	        FROM (
	            SELECT 
	                a.*,
	                -- expen_sel 기준 파티셔닝 제거 (MODEL_STOCK에 expen_sel 정보 없음)
/*	                ROW_NUMBER() OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel ORDER BY Ori_OUTETC_amt DESC) AS RN_OUTETC,*/
	                ROW_NUMBER() OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel ORDER BY Ori_Eoh_amt DESC) AS RN_Eoh,
/*	                SUM(Ori_OUTETC_amt) OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel) AS Ori_OUTETC_total,
	                SUM(Base_OUTETC_amt) OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel) AS Base_OUTETC_total,*/
	                SUM(Ori_Eoh_amt) OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel) AS Ori_total,
	                SUM(Base_EOH_amt) OVER (PARTITION BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, expen_sel) AS Base_total
	            FROM (
	                SELECT
	                    a.YYYYMM,
	                    a.SITE,
	                    a.SEL_CODE,
	                    a.구분,
	                    A.MODEL,
	                    d.expen_sel,
	                    d.expen_sel명,
	                    d.acct_name,
	                    A.BOH,
						A.INPUT,
	        A.OUT,
	           		A.EOH,
	                    A.INETC,
	                    A.OUTETC,
	                    A.IN_OTHER_QTY,
						A.RMA_IN_QTY,
						A.OUT_RMA_QTY,
						A.OUT_REWORK_QTY,
						A.OUT_RND_QTY,
						A.OUT_TECH_EVAL_QTY,
						A.OUT_SHIP_INSP_QTY,
						A.OUT_DISPOSE_QTY,
						A.OUT_INV_ADJ_QTY,
						A.OUT_OTHER_QTY,
	                    coalesce(B.BOH_AMT,0) as BOH_AMT,
	                    B.INETC_AMT,
            			ROUND(a.RMA_IN_QTY  * COALESCE(ru.RMA_UNITCOST, 0), 0) AS RMA_IN_AMT,
						CASE
						    WHEN d.RN_MODEL = 1
						      OR d.RN_MODEL IS NULL
						    THEN ROUND(a.OUT_RMA_QTY * COALESCE(ru.RMA_UNITCOST, 0), 0)
						    ELSE 0
						END AS OUT_RMA_AMT,
						ROUND(a.OUT_DISPOSE_QTY * CASE WHEN COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0) = 0 THEN 0
						            ELSE(COALESCE(B.BOH_AMT,0) + COALESCE(C.IN_AMT,0) + COALESCE(B.INETC_AMT,0) + COALESCE(ROUND(A.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0))
						                / NULLIF(CONVERT(NUMERIC(17,6),COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0)),0)END,0) AS OUT_DISPOSE_AMT,
						ROUND(a.OUT_RND_QTY * CASE WHEN COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0) = 0 THEN 0
						            ELSE(COALESCE(B.BOH_AMT,0) + COALESCE(C.IN_AMT,0) + COALESCE(B.INETC_AMT,0) + COALESCE(ROUND(A.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0))
						                / NULLIF(CONVERT(NUMERIC(17,6),COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0)),0)END,0) AS OUT_RND_AMT,
						ROUND(a.OUT_OTHER_QTY * CASE WHEN COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0) = 0 THEN 0
						            ELSE(COALESCE(B.BOH_AMT,0) + COALESCE(C.IN_AMT,0) + COALESCE(B.INETC_AMT,0) + COALESCE(ROUND(A.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0))
						                / NULLIF(CONVERT(NUMERIC(17,6),COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0)),0)END,0) AS OUT_OTHER_AMT,
	                    --B.OUTETC_AMT,
/*
	                    CASE WHEN COALESCE(a.BOH,0)+ COALESCE(a.[INPUT],0) = 0 THEN 0 -- 26.06.24 okw
		                     WHEN COALESCE(a.BOH,0)+COALESCE(a.[INPUT],0) = OUTETC THEN  (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0))
	                    	 ELSE (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0))/(COALESCE(A.boh, 0) + COALESCE(a.[INPUT], 0))*A.OUTETC END AS Ori_OUTETC_AMT,
	                    CASE WHEN COALESCE(a.BOH,0)+ COALESCE(a.[INPUT],0) = 0 THEN 0 -- 26.06.24 okw
		                     WHEN COALESCE(a.BOH,0)+COALESCE(a.[INPUT],0) = OUTETC THEN  (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0))
	                	 	 ELSE round( (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0))/(COALESCE(A.boh, 0) + COALESCE(a.INPUT, 0))*A.OUTETC ,0) END AS Base_OUTETC_AMT,
*/
	                    COALESCE(c.IN_AMT, 0) AS IN_AMT,
	                    CASE WHEN COALESCE(a.BOH,0)+COALESCE(a.[INPUT],0)+COALESCE(a.INETC,0) = EOH THEN  (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(INETC_AMT, 0)+ COALESCE(ROUND(a.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0) )
	                    	 ELSE (COALESCE(b.boh_amt*1.0, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(INETC_AMT, 0)+ COALESCE(ROUND(a.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0))/(COALESCE(A.boh, 0) + COALESCE(a.INPUT, 0) + COALESCE(INETC, 0))*A.EOH END AS Ori_EOH_AMT,
	                    CASE WHEN COALESCE(a.BOH,0)+COALESCE(INPUT,0)+COALESCE(a.INETC,0) = EOH THEN  (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(INETC_AMT, 0)+ COALESCE(ROUND(a.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0))
	                    	 ELSE round((COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(INETC_AMT, 0)+ COALESCE(ROUND(a.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0))/(COALESCE(A.boh, 0) + COALESCE(a.INPUT, 0) + COALESCE(INETC, 0))*A.EOH ,0) END AS Base_EOH_AMT,
						CASE
						    WHEN COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0) = 0 THEN 0
						    ELSE
						        (
						            COALESCE(B.BOH_AMT,0)
						          + COALESCE(C.IN_AMT,0)
						          + COALESCE(B.INETC_AMT,0)
						          + COALESCE(ROUND(A.RMA_IN_QTY * COALESCE(ru.RMA_UNITCOST,0),0),0)
						        )
						        / NULLIF(
						            CONVERT(NUMERIC(17,6),
						                COALESCE(A.BOH,0) + COALESCE(A.[INPUT],0) + COALESCE(A.INETC,0)
						            ),
						        0)
						END AS OUT_UNIT_AMT
						
	                   /* CASE 
	                        WHEN a.out + a.outetc = 0 AND a.eoh != 0 
	                        THEN COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(b.INETC_AMT, 0)
	   ELSE (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(b.INETC_AMT, 0) - COALESCE(b.OUTETC_AMT, 0))
	                             / NULLIF((a.eoh + a.out), 0) * a.eoh * 1.0
	                    END AS Ori_EOH_AMT,
	                    ROUND(CASE 
	                        WHEN a.out + a.outetc = 0 AND a.eoh != 0 
	                        THEN COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(b.INETC_AMT, 0)
	                        ELSE (COALESCE(b.boh_amt, 0) + COALESCE(c.IN_AMT, 0) + COALESCE(b.INETC_AMT, 0) - COALESCE(b.OUTETC_AMT, 0))
	                             / NULLIF((a.eoh + a.out), 0) * a.eoh
	                    END, 0) AS Base_EOH_AMT*/
					FROM MODEL_STOCK a
					LEFT JOIN DIM_EXPEN d
					    ON a.model = d.model AND a.구분 = d.구분
					LEFT JOIN MODEL_BOH_AMT b
					    ON a.yyyymm = b.yyyymm AND a.site = b.site
					   AND a.model = b.model AND a.구분 = b.구분
					   AND d.expen_sel = b.expen_sel AND d.acct_name = b.acct_name
					LEFT JOIN MODEL_IN_AMT c
					    ON a.yyyymm = c.yyyymm AND a.site = c.site
					   AND a.model = c.model AND a.구분 = c.구분
					   AND d.expen_sel = c.expen_sel AND d.acct_name = c.acct_name
					LEFT JOIN STUC_RMA_LATEST ru
					    ON ru.SITE = a.SITE
					   AND ru.SEL_CODE = a.SEL_CODE
					   AND ru.구분 = a.구분
					   AND ru.MODEL = a.MODEL
	                WHERE A.yyyymm = @YYYYMM
	                  AND a.site = @SITE
	            ) a
	        ) t
	    ) Final
	)
	INSERT INTO DOI_STCO (
	    YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,
	    BOH, [INPUT], [OUT], EOH, INETC, OUTETC,
	    BOH_AMT, IN_AMT, EOH_AMT, OUT_AMT, INETC_AMT, OUTETC_AMT,
--	    WORK_QTY, WORK_AMT,
	    IN_OTHER_QTY, IN_OTHER_AMT,
--	    IN_INV_ADJ_QTY, IN_INV_ADJ_AMT,
	    RMA_IN_QTY, RMA_IN_AMT,
	    OUT_RMA_QTY, OUT_RMA_AMT,
	    OUT_REWORK_QTY, OUT_REWORK_AMT,
	    OUT_RND_QTY, OUT_RND_AMT,
	    OUT_TECH_EVAL_QTY, OUT_TECH_EVAL_AMT,
	    OUT_SHIP_INSP_QTY, OUT_SHIP_INSP_AMT,
	    OUT_DISPOSE_QTY, OUT_DISPOSE_AMT,
	 OUT_INV_ADJ_QTY, OUT_INV_ADJ_AMT,
	    OUT_OTHER_QTY, OUT_OTHER_AMT
	)
	SELECT 
	    YYYYMM,
	    SITE,
	    SEL_CODE,
	    구분,
	    MODEL,
	    ISNULL(EXPEN_SEL, 'NONE') AS EXPEN_SEL,
	    ISNULL(EXPEN_SEL명, N'생산수불없음') AS EXPEN_SEL명,
	    ISNULL(ACCT_NAME, N'생산수불없음') AS ACCT_NAME,
	    BOH,
	    [INPUT],
	    [OUT],
	    EOH,
	    INETC,
	    OUTETC,
	    BOH_AMT,
	    IN_AMT,
	    EOH_AMT,
	    BOH_AMT + IN_AMT + (IN_OTHER_AMT + RMA_IN_AMT) - EOH_AMT - OUT_RMA_AMT - OUT_DISPOSE_AMT - OUT_RND_AMT - OUT_OTHER_AMT AS OUT_AMT,
	    IN_OTHER_AMT + /*IN_INV_ADJ_AMT +*/ RMA_IN_AMT AS INETC_AMT,
	    OUTETC_AMT,
--	    WORK_QTY,
--	    WORK_AMT,
	    IN_OTHER_QTY,
	    IN_OTHER_AMT,
--	    IN_INV_ADJ_QTY,
--	    IN_INV_ADJ_AMT,
	    RMA_IN_QTY,
	    RMA_IN_AMT,
	    OUT_RMA_QTY,
	    OUT_RMA_AMT,
	    OUT_REWORK_QTY,
	    OUT_REWORK_AMT,
	    OUT_RND_QTY,
	    OUT_RND_AMT,
	    OUT_TECH_EVAL_QTY,
	    OUT_TECH_EVAL_AMT,
	    OUT_SHIP_INSP_QTY,
	    OUT_SHIP_INSP_AMT,
	    OUT_DISPOSE_QTY,
	    OUT_DISPOSE_AMT,
	    OUT_INV_ADJ_QTY,
	    OUT_INV_ADJ_AMT,
	    OUT_OTHER_QTY,
	    OUT_OTHER_AMT
	FROM MODEL_EOH_AMT
	ORDER BY 
	    구분,
	    MODEL,
	    EXPEN_SEL,
	  EXPEN_SEL명,
	    ACCT_NAME;
	
	SET  @R_Message =  @R_Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '+@YYYYMM + '월 '
		+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '재품수불금액 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
	
	--카세트 재료비 1
	INSERT	INTO	DOI_STCO
	(YYYYMM ,SITE ,SEL_CODE ,구분 ,MODEL ,expen_sel ,expen_sel명 ,acct_name, BOH ,[INPUT] , EOH , [OUT] ,BOH_AMT ,IN_AMT ,EOH_AMT ,OUT_AMT)
	select YYYYMM ,SITE ,SEL_CODE ,CASE WHEN model like 'VINA%' THEN '카세트' else 구분 end as 구분,
		MODEL ,expen_sel ,expen_sel명 ,acct_name,boh_qty ,in_qty ,eoh_qty ,out_qty ,boh ,[in] ,eoh ,[out]
	from doi_cost a
	WHERE 1 = 1 
	 and YYYYMM   = @YYYYMM
     and SITE 	  = @SITE
    and SEL_CODE = @SEL_CODE
     and model like 'VINA%'
     and expen_sel명 not like '%재료비'
     and ADJ_YN='Y'
    UNION ALL --재료비부분
	select YYYYMM ,SITE ,SEL_CODE ,CASE WHEN model like 'VINA%' THEN '카세트' else 구분 end as 구분,
		MODEL ,expen_sel ,expen_sel명 ,acct_name,sum(boh_qty) ,sum(in_qty) ,sum(eoh_qty) ,sum(out_qty) ,sum(boh) ,sum([out]) ,sum(eoh) ,sum([out]) --select *
	from doi_cost a
	WHERE 1 = 1 
	 and YYYYMM   = @YYYYMM
     and SITE 	  = @SITE
     and SEL_CODE = @SEL_CODE
     and model like 'VINA%'
     and expen_sel명 like '%재료비'
     and ADJ_YN='Y'
	GROUP by YYYYMM ,SITE ,SEL_CODE ,CASE WHEN model like 'VINA%' THEN '카세트' else 구분 end ,
		MODEL ,expen_sel ,expen_sel명 ,acct_name ;
	
	SET  @R_Message =  @R_Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '+@YYYYMM + '월 '
		+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '카셑트재료비 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';

	--EXTRA (수불은 없지만 재공 기초금액이 있는 모델) 처리 
	INSERT INTO DOI_STCO 
	(YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,expen_sel명,ACCT_NAME,BOH,[INPUT],[OUT],EOH,BOH_AMT,IN_AMT,EOH_AMT,OUT_AMT,OUTETC_AMT)
	select
		YYYYMM,
		SEL_CODE,
		SITE,
		'개발' as 구분,
		'EXTRA' AS MODEL,
		'*' as EXPEN_SEL,
		'*' as expen_sel명,
		'*' as ACCT_NAME,
		SUM(BOH_QTY) as BOH,
		SUM(IN_QTY) as INPUT,
		SUM(OUT_QTY) as OUT,
		SUM(EOH_QTY) as EOH,
		SUM(BOH) as BOH_AMT,
		SUM(ADJ_BOH) as IN_AMT,
		SUM(EOH) as EOH_AMT, 
		SUM(ADJ_BOH) as OUT_AMT,
		SUM(OUT_ETC) as OUTETC_AMT --select *
	from
		doi_cost
	where
		yyyymm = @YYYYMM
		and sel_code = @SEL_CODE
		and site = @SITE
		and expen_sel = '*'
		and @YYYYMM <> '202601'
	group by 	YYYYMM,
		SEL_CODE,
		SITE;
	
	-- ##1 재공 전량LOSS --> STCO (기타매출)
	INSERT INTO DOI_STCO 
	(YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,expen_sel명,ACCT_NAME,BOH,[INPUT],[OUT],EOH,BOH_AMT,IN_AMT,EOH_AMT,OUT_AMT,OUTETC_AMT)
	SELECT YYYYMM, SEL_CODE, SITE, 구분, MODEL, '*' EXPEN_SEL,  '*' expen_sel명, '기타출고' ACCT_NAME,
	       0 BOH, 0 [INPUT], 0 [OUT], 0 EOH, 0 BOH_AMT, 
	    SUM(LOSS) IN_AMT, 0 EOH_AMT, 0  OUT_AMT, SUM(LOSS) OUTETC_AMT
	FROM
	(
	   SELECT 
	   YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,expen_sel명,ACCT_NAME, LOSS
	   FROM
	   (
	      select YYYYMM, SEL_CODE, SITE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,  
	             SUM(LOSS) LOSS
	      from doi_cost
	      where yyyymm = @YYYYMM
	      and sel_code = @SEL_CODE
	      AND SITE = @SITE
	      and  boh_qty + in_qty != 0
	      --and out_qty + eoh_qty = 0
	      and out = 0
	      and eoh = 0
	      GROUP BY YYYYMM, SEL_CODE, SITE, 구분, MODEL, EXPEN_SEL명, ACCT_NAME, EXPEN_SEL
	      HAVING SUM(LOSS) != 0
	   ) X
	) Y
	GROUP BY   YYYYMM, SEL_CODE, SITE, 구분,  MODEL; --,  EXPEN_SEL,  expen_sel명
		/*INSERT INTO DOI_STCO  --차후 수정 필요 2026.04.05 KYH
	(YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,expen_sel명,ACCT_NAME,BOH,[INPUT],[OUT],EOH,BOH_AMT,IN_AMT,EOH_AMT,OUT_AMT,OUTETC_AMT,COST_TYPE)
	      select YYYYMM,SEL_CODE,SITE,구분,MODEL,EXPEN_SEL,expen_sel명,ACCT_NAME
	      ,MAX(BOH_QTY) BOH_QTY,MAX(IN_QTY) IN_QTY,MAX(OUT_QTY) OUT_QTY,MAX(EOH_QTY) EOH_QTY,
	      SUM(BOH) BOH_AMT,SUM([IN]) IN_AMT,SUM(EOH) EOH_AMT,SUM([LOSS]) OUT_AMT,SUM(OUT_ETC) OUTETC_AMT,'LOSS' COST_TYPE
	      from doi_cost
	      where yyyymm = :YYYYMM
	      and sel_code = :SEL_CODE
	      AND SITE = :SITE
	      and  boh_qty + in_qty = loss_qty
	      and loss != 0*/
	
	SET  @R_Message =  @R_Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '+@YYYYMM + '월 '
		+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '수불은 없지만 재공 기초금액이 있는 모델 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 처리했습니다';
	
	 SET  @R_Message =  @R_Message + char(10) + '  [END]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '+@YYYYMM + '월 '
		+ CASE WHEN @SITE =@SITE THEN '본사' ELSE 'VINA' END + '재품수불금액 집계 완료했습니다';
	 COMMIT TRANSACTION;
	 
	 END TRY   
	  
	BEGIN CATCH
		SET  @R_Message =  @R_Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_Message());-- AS ErrorR_Message;
		ROLLBACK TRANSACTION;
	--SELECT @R_Message as retMessage;
	   END CATCH;
	END;
