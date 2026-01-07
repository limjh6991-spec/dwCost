CREATE                           PROCEDURE UP_DOI_SALE_COST
    @YYYYMM VARCHAR(10),
    @SITE VARCHAR(4)
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
    DECLARE @SiteName VARCHAR(10) = CASE WHEN @SITE = 'HQ' THEN '본사' ELSE 'VINA' END;
    
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
		      WHERE yyyymm=@YYYYMM
		        and site  =@SITE;
			IF @CNT = 0 BEGIN
				SET  @Message =  @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 제품수불금액(DOI_STCO) 테이블에 '
						+@YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
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
	      WHERE yyyymm=@YYYYMM
	        and site  =@SITE;
		IF @CNT = 0 BEGIN
			SET  @Message =  @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_ACCT_EXPEN) 테이블에 '
					+@YYYYMM + '월 ' + CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
			SET @CHECK = 1;
		END	
		
		IF @CHECK = 1 BEGIN 
			SELECT @Message as retMessage;
			RETURN -1;
		END 
	 /* SELECT YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처, SUM(수량) as 수량, SUM(원화판매금액계) as 원화판매금액계
	  FROM (
	 	select YYYYMM, SITE,
		 CASE
	        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
	        WHEN RIGHT(품번, 1) = 'D' THEN N'개발'
	        ELSE N'양산'
	      END AS 구분, 품명, 품번, Local구분, 판매단위, 거래처,수량, 원화판매금액계
		from DOI_SALE_RESC
		where 1=1 
		  and YYYYMM = '202510'
		  and SITE 	 = 'HQ'
	    union all
	    select YYYYMM, SITE,
			 CASE
		        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
		        WHEN RIGHT(품번, 1) = 'D' THEN N'개발'
		        ELSE N'양산'
		     END AS 구분, 품명, 품번,  수출구분, 단위, Buyer, 수량 ,원화판매금액 --select *
		from DOI_INVOICE_RESC
		where 1=1 
		  and YYYYMM = '202510'
		  and SITE 	 = 'HQ'
	    )a
	    GROUP BY YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처
	    ORDER BY YYYYMM, SITE, 구분, 품명, 품번, Local구분, 판매단위, 거래처*/
        -- 1. 기존 데이터 삭제
        DELETE FROM DOI_SLCO
        WHERE YYYYMM = @YYYYMM
          AND SITE = @SITE;
        
        SET @DeletedRows = @@ROWCOUNT;
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 기존 데이터 ' + CAST(@DeletedRows AS VARCHAR) + '건 삭제';
        
        -- 2. 매출원가 데이터 생성
        -- STCO의 출고금액을 SALES의 거래처별 수량 비율로 배부
		INSERT INTO DOI_SLCO (
		    YYYYMM,
		    SITE,
		    SEL_CODE,
		    구분,
		    MODEL,
		    expen_sel,
		    expen_sel명,
		    거래처,
		    OUT_qty,
		    OUT_AMT
		)
		SELECT 
		    YYYYMM,
		    SITE,
		    SEL_CODE,
		    구분,
		    MODEL,
		    EXPEN_SEL,
		    EXPEN_SEL명,
		    거래처,
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
		            stco.EXPEN_SEL,
		            stco.EXPEN_SEL명,
		            sale.거래처,
		            sale_total.판매금액,
		            
		            -- 원본 총 수량 & 총 금액 보존
		            CAST(stco.[OUT] AS INT) AS Original_Total_Qty,
		            stco.OUT_AMT AS Original_Total_Amt,
		
		            -- 1. 수량 1차 배부 (정수 반올림)
		            CASE 
		                WHEN ISNULL(sale_total.total_sale_qty, 0) = 0 THEN 0
		   			ELSE 
		                  CASE
		                        WHEN CAST(stco.[OUT] AS BIGINT) * CAST(sale.sale_qty AS BIGINT) / sale_total.total_sale_qty > 2147483647 THEN 2147483647
		                        ELSE CAST(ROUND(CAST(stco.[OUT] AS BIGINT) * CAST(sale.sale_qty AS BIGINT) * 1.0 / sale_total.total_sale_qty, 0) AS INT)
		                    END
		            END AS Base_OUT_Qty,
		
		            -- 2. 금액 1차 배부 (소수점 2자리 반올림 - 필요시 0으로 수정)
		            CASE 
		                WHEN ISNULL(sale_total.total_sale_qty, 0) = 0 THEN 0
		                ELSE ROUND(stco.OUT_AMT * CAST(sale.sale_qty AS BIGINT) * 1.0 / sale_total.total_sale_qty, 2)
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
		                EXPEN_SEL명,
		                AVG([OUT]) AS [OUT],
		                SUM(OUT_AMT) AS OUT_AMT
		            FROM DOI_STCO
		            WHERE YYYYMM = @YYYYMM
		              AND SITE = @SITE
		              AND SEL_CODE = 'ACTUAL'
		            GROUP BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명
		            HAVING SUM(OUT_AMT) > 0
		        ) stco
		        INNER JOIN (
		            -- SALE 소스
		            SELECT
		                거래처,
		                품명 AS MODEL,
		                /*CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END AS*/ 구분,
		                SUM(수량) AS sale_qty
		            FROM ( select YYYYMM, SITE, 품명,
		            		 CASE
						        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
						        WHEN RIGHT(품번, 1) = 'D' THEN N'개발'
						        ELSE N'양산'
						      END AS 구분, 거래처, 수량
							from DOI_SALE_RESC
							where 1=1 
							  and YYYYMM = @YYYYMM
				      		  and SITE 	 = @SITE
					        union all
					        select YYYYMM, SITE, 품명, 
		            			 CASE
							        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
							        WHEN RIGHT(품번, 1) = 'D' THEN N'개발'
							        ELSE N'양산'
							     END AS 구분, Buyer, 수량  --select *
							from DOI_INVOICE_RESC
							where 1=1 
							  and YYYYMM = @YYYYMM
				      		  and SITE 	 = @SITE
				      		  --and Buyer != '도우VINA'
				      		)a
		            GROUP BY 거래처, 품명, 구분/*CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END*/
		        ) sale ON stco.MODEL = sale.MODEL 
		              AND stco.구분 = sale.구분
		        INNER JOIN (
		            -- TOTAL SALE 소스
		            SELECT
		                품명 AS MODEL,
		                /*CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END AS*/ 구분,
		                SUM(수량) AS total_sale_qty,sum(원화판매금액계) as 판매금액
		            FROM ( select YYYYMM, SITE, 품명,
		            		 CASE
						        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
						        WHEN RIGHT(품번, 1) = 'D' THEN N'개발'
						        ELSE N'양산'
						      END AS 구분, 수량, 원화판매금액계
							from DOI_SALE_RESC
							where 1=1 
							  and YYYYMM = @YYYYMM
				      		  and SITE 	 = @SITE
					        union all
					        select YYYYMM, SITE, 품명, 
		            			 CASE
							        WHEN LEFT(품번, 2) = 'VN' THEN N'카세트'
							        WHEN RIGHT(품번, 1) = 'D' THEN N'개발'
							        ELSE N'양산'
							     END AS 구분, 수량 ,원화판매금액 --select *
							from DOI_INVOICE_RESC
							where 1=1 
							  and YYYYMM = @YYYYMM
				      		  and SITE 	 = @SITE
				      		  --and Buyer != '도우VINA'
				      		)a
		            GROUP BY 품명, 구분/*CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END*/
		        ) sale_total ON stco.MODEL = sale_total.MODEL 
		                    AND stco.구분 = sale_total.구분
		    ) A
		) Final;
        
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
		'ACTUAL' as sel_code,
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
		  AND yyyymm = @YYYYMM
		  AND SITE = @SITE;
			
		SET  @Message =  @Message + char(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 판매관리비배부(DOI_SMCE_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제 했습니다';

		WITH sale_data AS (
		    -- [1] 매출 데이터 및 비율 계산용 기초 데이터
		    SELECT
		        yyyymm,
		        CASE WHEN RIGHT(품번,1)='D' THEN '개발' ELSE '양산' END as 구분,
		        품명 AS model,
		        SUM(원화판매금액계) AS SALE_AMT --select *
		    FROM (
					select YYYYMM, SITE, 품명, 품번, 원화판매금액계
					from DOI_SALE_RESC
					where 1=1 
					  and YYYYMM = @YYYYMM
		      		  and SITE 	 = @SITE
			        union all
			        select YYYYMM, SITE, 품명, 품번, 원화판매금액  --select *
					from DOI_INVOICE_RESC
					where 1=1 
					  and YYYYMM = @YYYYMM
		      		  and SITE 	 = @SITE
		      		  --and Buyer != '도우VINA'
		      		)a
		    GROUP BY yyyymm, 품명,CASE WHEN RIGHT(품번,1)='D' THEN '개발' ELSE '양산' END
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
		    GROUP BY YYYYMM, SITE, EXPEN_SEL, ACCT_NAME
		)
		INSERT INTO DOI_SMCE_COST
		SELECT
		    YYYYMM,
		    'ACTUAL' AS sel_code,
		    SITE,
		    구분,
		    model,
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
		    
		    DIST_AMT_ORI -- 참고용 원본 계산값
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
		            s.model,
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
        
        COMMIT TRANSACTION;

        -- 실행 결과 반환 (retMessage 형식)
        SELECT @Message AS retMessage;
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
         ROLLBACK TRANSACTION;
        
        -- 에러 정보
        SET @ErrorMsg = ERROR_MESSAGE();
        SET @EndTime = GETDATE();
        
        -- 에러 메시지
        SET @Message = @Message + CHAR(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 오류 발생: ' + @ErrorMsg;
        
        -- 에러 결과 반환
        SELECT @Message AS retMessage;
        
        -- 실패 반환
        RETURN -1;
    END CATCH
END;