/* ============================================================================
 * UP_HQ_IF_XFORM_ACCOUNT  (ERP 계정코드 → 운영 doi_acct 업서트)
 *   staging DOI_HQ_IF_ACCOUNT → doi_acct (YYYYMM+SEL_CODE+SITE+ACCT 그레인)
 *
 *   ★업서트(사용자 확정 2026-08-24): 도우 원가분류 컬럼(ACCT_CLASS/expen_sel/
 *     대·중·소분류/경영계획과목 등)은 ERP에 없으므로 절대 건드리지 않고 보존.
 *     - 코드(ACCT = ERP AccNo) 매칭: 있으면 이름(ACCT_NAME)만 갱신
 *     - 운영에 없는 ERP 신규 계정만 추가(분류=빈값, 화면에서 수기 보완)
 *     - DELETE 없음 → 기존/분류/운영전용 계정 전부 보존 (결산 안전)
 *   시그니처: (@yyyymm, @selCode, @site)  ※IfLoad.runXform EXEC 순서와 일치
 *   반환: 신규 추가 건수(int)  ※<select resultType=int>
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_ACCOUNT
    @yyyymm  VARCHAR(20),
    @selCode VARCHAR(10),
    @site    VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode = '' SET @selCode = 'ACTUAL';
    IF @site    IS NULL OR @site    = '' SET @site    = 'HQ';

    -- ERP staging 계정 (AccNo 중복 대비 집계)
    ;WITH erp AS (
        SELECT RTRIM(AccNo) AS acct, MAX(AccName) AS acct_name
          FROM DOI_HQ_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    -- 1) 기존 계정: 이름만 갱신 (원가분류 컬럼 보존)
    UPDATE a
       SET a.ACCT_NAME = e.acct_name
      FROM doi_acct a
      JOIN erp e ON RTRIM(a.ACCT) = e.acct
     WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site
       AND ISNULL(a.ACCT_NAME,'') <> e.acct_name;

    -- 2) 운영에 없는 ERP 신규 계정만 추가 (분류=빈값)
    ;WITH erp AS (
        SELECT RTRIM(AccNo) AS acct, MAX(AccName) AS acct_name
          FROM DOI_HQ_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    INSERT INTO doi_acct (YYYYMM, SEL_CODE, SITE, ACCT_CLASS, ACCT, ACCT_NAME)
    SELECT @yyyymm, @selCode, @site, '', e.acct, e.acct_name
      FROM erp e
     WHERE NOT EXISTS (
              SELECT 1 FROM doi_acct a
               WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site
                 AND RTRIM(a.ACCT) = e.acct);

    SELECT @@ROWCOUNT;   -- 신규 추가 건수
END
