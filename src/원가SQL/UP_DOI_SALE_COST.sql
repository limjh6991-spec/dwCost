-- =============================================
-- 매출원가 생성 프로시저
-- 설명: STCO의 출고금액을 SALES의 거래처별 매출수량 비율로 배부
-- =============================================
CREATE OR ALTER PROCEDURE UP_DOI_SALE_COST
    @YYYYMM VARCHAR(10),
    @SITE VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DeletedRows INT = 0;
    DECLARE @InsertedRows INT = 0;
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
            stco.YYYYMM,
            stco.SITE,
            stco.SEL_CODE,
            stco.구분,
            stco.MODEL,
            stco.EXPEN_SEL,
            stco.EXPEN_SEL명,
            sale.거래처,
            -- 거래처별 출고수량 = 총 출고수량 * (거래처 매출수량 / 모델 총 매출수량)
            CASE 
                WHEN ISNULL(sale_total.total_sale_qty, 0) = 0 THEN 0
                ELSE 
                    CASE
                        WHEN CAST(stco.[OUT] AS BIGINT) * CAST(sale.sale_qty AS BIGINT) / sale_total.total_sale_qty > 2147483647 THEN 2147483647
                        ELSE CAST(ROUND(CAST(stco.[OUT] AS BIGINT) * CAST(sale.sale_qty AS BIGINT) * 1.0 / sale_total.total_sale_qty, 0) AS INT)
                    END
            END AS OUT_qty,
            -- 거래처별 출고금액(매출원가) = 총 출고금액 * (거래처 매출수량 / 모델 총 매출수량)
            CASE 
                WHEN ISNULL(sale_total.total_sale_qty, 0) = 0 THEN 0
                ELSE ROUND(stco.OUT_AMT * CAST(sale.sale_qty AS BIGINT) * 1.0 / sale_total.total_sale_qty, 2)
            END AS OUT_AMT
        FROM (
            -- STCO: 모델별/비용항목별 출고 정보
            SELECT
                YYYYMM,
                SITE,
                SEL_CODE,
                구분,
                MODEL,
                EXPEN_SEL,
                EXPEN_SEL명,
                AVG([OUT]) AS [OUT],
                SUM(OUT_AMT) AS OUT_AMT
            FROM DOI_STOCK_COST
            WHERE YYYYMM = @YYYYMM
              AND SITE = @SITE
              AND SEL_CODE = 'ACTUAL'
            GROUP BY YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명
            HAVING SUM(OUT_AMT) > 0
        ) stco
        INNER JOIN (
            -- SALE: 거래처별 매출 정보
            SELECT
                거래처,
                품명 AS MODEL,
                CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END AS 구분,
                SUM(수량) AS sale_qty
            FROM DOI_SALE_RESC
            WHERE yyyymm = @YYYYMM
              AND SITE = @SITE
            GROUP BY 거래처, 품명, CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END
        ) sale ON stco.MODEL = sale.MODEL 
              AND stco.구분 = sale.구분
        INNER JOIN (
            -- SALE_TOTAL: 모델별 총 매출수량
            SELECT
                품명 AS MODEL,
                CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END AS 구분,
                SUM(수량) AS total_sale_qty
            FROM DOI_SALE_RESC
            WHERE yyyymm = @YYYYMM
              AND SITE = @SITE
            GROUP BY 품명, CASE WHEN RIGHT(품번, 1) = 'D' THEN '개발' ELSE '양산' END
        ) sale_total ON stco.MODEL = sale_total.MODEL 
                    AND stco.구분 = sale_total.구분;
        
        SET @InsertedRows = @@ROWCOUNT;
        SET @EndTime = GETDATE();
        
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 경비/매출원가(DOI_SLCO) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 ' 
            + CAST(@InsertedRows AS VARCHAR) + '건 상세 배부입니다';
        
        SET @Message = @Message + CHAR(10) + ' [INFO]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 실행 시간: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR) + '초';
        
        COMMIT TRANSACTION;
        
        -- 완료 메시지
        SET @Message = @Message + CHAR(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + CHAR(9) 
            + '- 경비/매출원가(DOI_SLCO) 데이터 ' + @YYYYMM + '월 ' + @SiteName + '원가 데이터 입력 완료되었습니다';
        
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
