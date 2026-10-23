/* ============================================================
   UP_DOI_FILL_DWCODE — 결산 산출물에 도우코드(완전 품번) pass-through 채움
   - 값 중립: 도우코드 컬럼만 UPDATE. 원가/수량/금액·그레인·이월 전혀 불변.
   - 과거월(1~9월): EXEC 로 월별 1회 수동 백필.
   - 10월~: 결산 체인 끝(UP_DOI_SALE_COST 다음)에서 자동 호출.
   - 선행: DOI_COST/DOI_STCO/DOI_SLCO/DOI_SMCE_COST 에 도우코드 컬럼(NULL 허용) 존재해야 함(01_alter).
   - 1:1 가드(COUNT(DISTINCT)=1)로 다대1(카세트 다변종·미래 D/T 공존)이면 미기입(NULL→리포트 COALESCE 폴백).
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.UP_DOI_FILL_DWCODE
    @YYYYMM   varchar(6),
    @SITE     varchar(4),
    @SEL_CODE varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) DOI_STCO <- DOI_STOCK.MODEL_TYPE(품번).  (구분=품번 suffix 파생, 품명=MODEL) 1:1만 */
    ;WITH M AS (
        SELECT YYYYMM, SITE,
               CASE
                   WHEN RIGHT(MODEL_TYPE,1) LIKE '[0-9]' THEN
                        CASE WHEN SUBSTRING(MODEL_TYPE,LEN(MODEL_TYPE)-1,1)='P' THEN N'양산'
                             WHEN SUBSTRING(MODEL_TYPE,LEN(MODEL_TYPE)-1,1)='R' THEN N'RMA' ELSE N'개발' END
                   WHEN RIGHT(MODEL_TYPE,1)='P' THEN N'양산'
                   WHEN RIGHT(MODEL_TYPE,1)='R' THEN N'RMA'
                   ELSE N'개발'
               END AS 구분,
               MODEL AS 품명, MIN(MODEL_TYPE) AS 품번, COUNT(DISTINCT MODEL_TYPE) AS n
        FROM dbo.DOI_STOCK
        WHERE YYYYMM=@YYYYMM AND SITE=@SITE
        GROUP BY YYYYMM, SITE,
               CASE
                   WHEN RIGHT(MODEL_TYPE,1) LIKE '[0-9]' THEN
                        CASE WHEN SUBSTRING(MODEL_TYPE,LEN(MODEL_TYPE)-1,1)='P' THEN N'양산'
                             WHEN SUBSTRING(MODEL_TYPE,LEN(MODEL_TYPE)-1,1)='R' THEN N'RMA' ELSE N'개발' END
                   WHEN RIGHT(MODEL_TYPE,1)='P' THEN N'양산'
                   WHEN RIGHT(MODEL_TYPE,1)='R' THEN N'RMA'
                   ELSE N'개발'
               END, MODEL
    )
    UPDATE s SET s.도우코드 = m.품번
    FROM dbo.DOI_STCO s
    JOIN M m ON m.YYYYMM=s.YYYYMM AND m.SITE=s.SITE AND m.구분=s.구분 AND m.품명=s.MODEL AND m.n=1
    WHERE s.YYYYMM=@YYYYMM AND s.SITE=@SITE;

    /* 1b) DOI_STCO 잔여(창고수불 없는 재공 전량LOSS/기타출고 등) <- 생산수불 (구분, 도우모델=MODEL)->도우코드 폴백 */
    ;WITH Pst AS (
        SELECT 구분,
               CASE WHEN LTRIM(RTRIM(도우코드))='818VT' THEN '818VT' ELSE LTRIM(RTRIM(도우모델)) END AS mk,
               MIN(LTRIM(RTRIM(도우코드))) AS 도우코드, COUNT(DISTINCT LTRIM(RTRIM(도우코드))) AS n
        FROM dbo.DOI_PROD_SUBUL
        WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND LEN(LTRIM(RTRIM(도우코드)))>0
          AND LTRIM(RTRIM(도우코드)) NOT LIKE 'VN034P[0-9]'
        GROUP BY 구분, CASE WHEN LTRIM(RTRIM(도우코드))='818VT' THEN '818VT' ELSE LTRIM(RTRIM(도우모델)) END
    )
    UPDATE s SET s.도우코드 = p.도우코드
    FROM dbo.DOI_STCO s
    JOIN Pst p ON p.구분=s.구분 AND p.mk=s.MODEL AND p.n=1
    WHERE s.YYYYMM=@YYYYMM AND s.SITE=@SITE AND (s.도우코드 IS NULL OR s.도우코드='');

    /* 2) DOI_COST : 카세트(VN%)=MODEL 직접, 비카세트=생산수불 (구분,mk[818VT carve-out])->도우코드 1:1 */
    UPDATE dbo.DOI_COST SET 도우코드 = MODEL
    WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND MODEL LIKE 'VN%';

    ;WITH P AS (
        SELECT 구분,
               CASE WHEN LTRIM(RTRIM(도우코드))='818VT' THEN '818VT' ELSE LTRIM(RTRIM(도우모델)) END AS mk,
               MIN(LTRIM(RTRIM(도우코드))) AS 도우코드, COUNT(DISTINCT LTRIM(RTRIM(도우코드))) AS n
        FROM dbo.DOI_PROD_SUBUL
        WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND LEN(LTRIM(RTRIM(도우코드)))>0
          AND LTRIM(RTRIM(도우코드)) NOT LIKE 'VN034P[0-9]'
        GROUP BY 구분, CASE WHEN LTRIM(RTRIM(도우코드))='818VT' THEN '818VT' ELSE LTRIM(RTRIM(도우모델)) END
    )
    UPDATE c SET c.도우코드 = p.도우코드
    FROM dbo.DOI_COST c
    JOIN P p ON p.구분=c.구분 AND p.mk=c.MODEL AND p.n=1
    WHERE c.YYYYMM=@YYYYMM AND c.SITE=@SITE AND c.MODEL NOT LIKE 'VN%';

    /* 3) DOI_SLCO <- DOI_STCO (구분,MODEL)->도우코드 상속 */
    ;WITH S AS (
        SELECT DISTINCT 구분, MODEL, 도우코드 FROM dbo.DOI_STCO
        WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND 도우코드 IS NOT NULL AND 도우코드<>''
    )
    UPDATE l SET l.도우코드 = S.도우코드
    FROM dbo.DOI_SLCO l
    JOIN S ON S.구분=l.구분 AND S.MODEL=l.MODEL
    WHERE l.YYYYMM=@YYYYMM AND l.SITE=@SITE;

    /* 4) DOI_SMCE_COST <- DOI_STCO (구분,model)->도우코드 상속 */
    ;WITH S AS (
        SELECT DISTINCT 구분, MODEL, 도우코드 FROM dbo.DOI_STCO
        WHERE YYYYMM=@YYYYMM AND SITE=@SITE AND 도우코드 IS NOT NULL AND 도우코드<>''
    )
    UPDATE x SET x.도우코드 = S.도우코드
    FROM dbo.DOI_SMCE_COST x
    JOIN S ON S.구분=x.구분 AND S.MODEL=x.model
    WHERE x.YYYYMM=@YYYYMM AND x.SITE=@SITE;
END
GO
