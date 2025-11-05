-- =====================================================
-- 데이터 검증 시스템 테이블 생성 스크립트
-- dwisCOST Manufacturing Cost System
-- 작성일: 2025-11-04
-- =====================================================

-- 1. 검증 이력 마스터 테이블
IF OBJECT_ID('DOI_VALIDATION_LOG', 'U') IS NULL
BEGIN
    CREATE TABLE DOI_VALIDATION_LOG (
        LOG_ID          BIGINT IDENTITY(1,1) PRIMARY KEY,
        VALIDATION_TYPE VARCHAR(50) NOT NULL,           -- 'PROD_SUBUL', 'STOCK', 'ALL'
        YYYYMM          CHAR(6) NOT NULL,                -- 검증 대상 월
        SITE            VARCHAR(10),                     -- 'HQ', 'VN', 'ALL'
        START_TIME      DATETIME2 NOT NULL DEFAULT GETDATE(),
        END_TIME        DATETIME2,
        STATUS          VARCHAR(20) NOT NULL DEFAULT 'RUNNING', -- 'RUNNING', 'COMPLETED', 'FAILED'
        TOTAL_CHECKS    INT DEFAULT 0,                   -- 총 검증 건수
        ERROR_COUNT     INT DEFAULT 0,                   -- 오류 건수
        WARNING_COUNT   INT DEFAULT 0,                   -- 경고 건수
        EXECUTED_BY     VARCHAR(100),                    -- 실행자
        ERROR_MESSAGE   NVARCHAR(MAX),                   -- 실패 시 오류 메시지
        REPORT_PATH     VARCHAR(500),                    -- 리포트 파일 경로
        CREATED_AT      DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        INDEX IX_VALIDATION_LOG_01 (VALIDATION_TYPE, YYYYMM, SITE),
        INDEX IX_VALIDATION_LOG_02 (START_TIME DESC)
    );
    
    PRINT '✅ DOI_VALIDATION_LOG 테이블 생성 완료';
END
ELSE
BEGIN
    PRINT '⚠️ DOI_VALIDATION_LOG 테이블이 이미 존재합니다.';
END
GO

-- 2. 검증 오류 상세 테이블
IF OBJECT_ID('DOI_VALIDATION_ERROR', 'U') IS NULL
BEGIN
    CREATE TABLE DOI_VALIDATION_ERROR (
        ERROR_ID        BIGINT IDENTITY(1,1) PRIMARY KEY,
        LOG_ID          BIGINT NOT NULL,                 -- DOI_VALIDATION_LOG.LOG_ID (FK)
        RULE_CODE       VARCHAR(50) NOT NULL,            -- 'R001', 'R002' 등
        RULE_NAME       NVARCHAR(200) NOT NULL,          -- 규칙 설명
        SEVERITY        VARCHAR(20) NOT NULL,            -- 'ERROR', 'WARNING', 'INFO'
        SOURCE_TABLE    VARCHAR(100),                    -- 원천 테이블명
        TARGET_TABLE    VARCHAR(100),                    -- 대상 테이블명
        KEY_COLUMN      NVARCHAR(500),                   -- 키 컬럼 (JSON 형식)
        KEY_VALUE       NVARCHAR(500),                   -- 키 값
        EXPECTED_VALUE  DECIMAL(18,2),                   -- 예상 값
        ACTUAL_VALUE    DECIMAL(18,2),                   -- 실제 값
        DIFF_VALUE      DECIMAL(18,2),                   -- 차이 값
        ERROR_MESSAGE   NVARCHAR(MAX),                   -- 오류 메시지
        SQL_QUERY       NVARCHAR(MAX),                   -- 재현용 SQL
        FIXED_YN        CHAR(1) DEFAULT 'N',             -- 수정 여부
        FIXED_AT        DATETIME2,                       -- 수정 일시
        FIXED_BY        VARCHAR(100),                    -- 수정자
        CREATED_AT      DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT FK_VALIDATION_ERROR_LOG 
            FOREIGN KEY (LOG_ID) REFERENCES DOI_VALIDATION_LOG(LOG_ID),
        
        INDEX IX_VALIDATION_ERROR_01 (LOG_ID, SEVERITY),
        INDEX IX_VALIDATION_ERROR_02 (RULE_CODE, SEVERITY),
        INDEX IX_VALIDATION_ERROR_03 (FIXED_YN)
    );
    
    PRINT '✅ DOI_VALIDATION_ERROR 테이블 생성 완료';
END
ELSE
BEGIN
    PRINT '⚠️ DOI_VALIDATION_ERROR 테이블이 이미 존재합니다.';
END
GO

-- 3. 검증 규칙 마스터 테이블
IF OBJECT_ID('DOI_VALIDATION_RULE', 'U') IS NULL
BEGIN
    CREATE TABLE DOI_VALIDATION_RULE (
        RULE_CODE       VARCHAR(50) PRIMARY KEY,
        RULE_CATEGORY   VARCHAR(50) NOT NULL,            -- 'PROD_SUBUL', 'STOCK', 'COMMON'
        RULE_NAME       NVARCHAR(200) NOT NULL,
        RULE_DESC       NVARCHAR(1000),
        SQL_TEMPLATE    NVARCHAR(MAX),                   -- 검증 SQL 템플릿
        SEVERITY        VARCHAR(20) DEFAULT 'ERROR',
        THRESHOLD       DECIMAL(18,2) DEFAULT 0.01,      -- 허용 오차 (금액/수량)
        ENABLED_YN      CHAR(1) DEFAULT 'Y',
        EXECUTION_ORDER INT DEFAULT 100,
        CREATED_AT      DATETIME2 NOT NULL DEFAULT GETDATE(),
        UPDATED_AT      DATETIME2,
        
        INDEX IX_VALIDATION_RULE_01 (RULE_CATEGORY, ENABLED_YN, EXECUTION_ORDER)
    );
    
    PRINT '✅ DOI_VALIDATION_RULE 테이블 생성 완료';
END
ELSE
BEGIN
    PRINT '⚠️ DOI_VALIDATION_RULE 테이블이 이미 존재합니다.';
END
GO

-- 4. 기준 데이터: 검증 규칙 등록
IF NOT EXISTS (SELECT 1 FROM DOI_VALIDATION_RULE WHERE RULE_CODE = 'PS001')
BEGIN
    INSERT INTO DOI_VALIDATION_RULE (RULE_CODE, RULE_CATEGORY, RULE_NAME, RULE_DESC, SEVERITY, EXECUTION_ORDER)
    VALUES
    -- 생산수불 검증 규칙
    ('PS001', 'PROD_SUBUL', '생산수불 수식 검증', 'EOH = BOH + IN + BONUS - OUT - LOSS - NG', 'ERROR', 10),
    ('PS002', 'PROD_SUBUL', 'Lot/Run 합계 검증', 'DOI_PROD_SUBUL ≈ SUM(DOI_PROD_LOTRUN)', 'ERROR', 20),
    ('PS003', 'PROD_SUBUL', 'BOH/EOH 연결성 검증', '전월 EOH = 당월 BOH', 'ERROR', 30),
    ('PS004', 'PROD_SUBUL', '원천 데이터 누락 검증', 'DW_PROD_* → DOI_PROD_SUBUL 누락 체크', 'WARNING', 40),
    ('PS005', 'PROD_SUBUL', '음수 재고 검증', 'EOH < 0 체크', 'ERROR', 50),
    
    -- 재고 검증 규칙
    ('ST001', 'STOCK', '재고 수식 검증', 'EOH = BOH + INPUT - OUT', 'ERROR', 110),
    ('ST002', 'STOCK', 'PROD OUT → STOCK IN 검증', 'DOI_PROD_SUBUL.OUT_MONTH = DOI_STOCK.INPUT_PROD', 'ERROR', 120),
    ('ST003', 'STOCK', 'BOH/EOH 연결성 검증', '전월 EOH = 당월 BOH', 'ERROR', 130),
    ('ST004', 'STOCK', '수량/금액 일치성 검증', 'DOI_STOCK.EOH = DOI_STOCK_COST.EOH_QTY', 'WARNING', 140),
    ('ST005', 'STOCK', '음수 재고 검증', 'EOH < 0 체크', 'ERROR', 150),
    
    -- 공통 검증 규칙
    ('CM001', 'COMMON', '중복 데이터 검증', 'PK 중복 체크', 'ERROR', 210),
    ('CM002', 'COMMON', 'NULL 필수값 검증', '필수 컬럼 NULL 체크', 'ERROR', 220);
    
    PRINT '✅ 검증 규칙 기준 데이터 등록 완료';
END
GO

-- 5. 검증 통계 뷰 생성
IF OBJECT_ID('VW_VALIDATION_SUMMARY', 'V') IS NOT NULL
    DROP VIEW VW_VALIDATION_SUMMARY;
GO

CREATE VIEW VW_VALIDATION_SUMMARY AS
SELECT 
    l.LOG_ID,
    l.VALIDATION_TYPE,
    l.YYYYMM,
    l.SITE,
    l.START_TIME,
    l.END_TIME,
    DATEDIFF(SECOND, l.START_TIME, ISNULL(l.END_TIME, GETDATE())) AS DURATION_SEC,
    l.STATUS,
    l.TOTAL_CHECKS,
    l.ERROR_COUNT,
    l.WARNING_COUNT,
    l.EXECUTED_BY,
    
    -- 오류 통계
    COUNT(DISTINCT e.ERROR_ID) AS DETAIL_ERROR_COUNT,
    SUM(CASE WHEN e.SEVERITY = 'ERROR' THEN 1 ELSE 0 END) AS ERROR_SEVERITY_COUNT,
    SUM(CASE WHEN e.SEVERITY = 'WARNING' THEN 1 ELSE 0 END) AS WARNING_SEVERITY_COUNT,
    SUM(CASE WHEN e.FIXED_YN = 'Y' THEN 1 ELSE 0 END) AS FIXED_COUNT,
    
    -- 성공률
    CASE 
        WHEN l.TOTAL_CHECKS = 0 THEN 100.0
        ELSE ROUND(100.0 * (l.TOTAL_CHECKS - l.ERROR_COUNT) / l.TOTAL_CHECKS, 2)
    END AS SUCCESS_RATE
    
FROM DOI_VALIDATION_LOG l
LEFT JOIN DOI_VALIDATION_ERROR e ON l.LOG_ID = e.LOG_ID
GROUP BY 
    l.LOG_ID, l.VALIDATION_TYPE, l.YYYYMM, l.SITE, 
    l.START_TIME, l.END_TIME, l.STATUS, l.TOTAL_CHECKS, 
    l.ERROR_COUNT, l.WARNING_COUNT, l.EXECUTED_BY;
GO

PRINT '✅ VW_VALIDATION_SUMMARY 뷰 생성 완료';
GO

-- 6. 인덱스 최적화 확인
PRINT '=========================================';
PRINT '데이터 검증 시스템 테이블 생성 완료';
PRINT '=========================================';
PRINT '생성된 객체:';
PRINT '  - DOI_VALIDATION_LOG (검증 이력)';
PRINT '  - DOI_VALIDATION_ERROR (오류 상세)';
PRINT '  - DOI_VALIDATION_RULE (검증 규칙)';
PRINT '  - VW_VALIDATION_SUMMARY (통계 뷰)';
PRINT '=========================================';
