-- =============================================================================
-- DOI_ETC_INOUT : 기타입출고금액조회(통합) — 본사(HQ)
--   원천: ERP 「기타입출고금액조회(통합)」 엑셀 (docs/1~7월 기타입출고금액 DB)
--   컬럼 구성은 엑셀 헤더 23컬럼 + 적재 메타(yyyymm/edit_user/edit_date).
--   VN 대응 테이블 DOI_VN_ETC_INOUT 과 동일 스키마(사이트만 다름).
-- =============================================================================
IF OBJECT_ID('DOI_ETC_INOUT', 'U') IS NULL
BEGIN
    CREATE TABLE DOI_ETC_INOUT (
        [회계단위]        NVARCHAR(20)   NULL,
        [일자]            NVARCHAR(20)   NULL,
        [입출고구분]      NVARCHAR(20)   NULL,
        [원천구분]        NVARCHAR(20)   NULL,
        [기타입출고구분]  NVARCHAR(100)  NULL,
        [품목자산분류]    NVARCHAR(20)   NULL,
        [대분류]          NVARCHAR(50)   NULL,
        [중분류]          NVARCHAR(50)   NULL,
        [소분류]          NVARCHAR(50)   NULL,
        [품명]            NVARCHAR(200)  NULL,
        [품번]            NVARCHAR(20)   NULL,
        [규격]            NVARCHAR(50)   NULL,
        [단위]            NVARCHAR(20)   NULL,
        [단수보정구분]    NVARCHAR(20)   NULL,
        [수량]            NUMERIC(28,8)  NULL,
        [금액]            NUMERIC(28,8)  NULL,
        [단가]            NUMERIC(28,8)  NULL,
        [계정과목]        NVARCHAR(100)  NULL,
        [창고]            NVARCHAR(50)   NULL,
        [사용부서]        NVARCHAR(20)   NULL,
        [거래처]          NVARCHAR(20)   NULL,
        [특이사항]        NVARCHAR(200)  NULL,
        [품목특이사항]    NVARCHAR(254)  NULL,
        [yyyymm]          VARCHAR(6)     NOT NULL,
        [edit_user]       NVARCHAR(40)   NOT NULL,
        [edit_date]       DATETIME       NOT NULL
    );

    CREATE INDEX IX_DOI_ETC_INOUT_YYYYMM ON DOI_ETC_INOUT ([yyyymm]);
END
GO
