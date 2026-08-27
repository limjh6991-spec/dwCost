/* ============================================================================
 * UP_HQ_IF_XFORM_ACCOUNT  (HQ ERP 계정코드 → 운영 doi_acct 업서트)
 *   staging DOI_HQ_IF_ACCOUNT → doi_acct (YYYYMM+SEL_CODE+SITE+ACCT 그레인)
 *
 *   ★업서트 원칙: ERP 원천 필드는 갱신/삽입, 도우 원가분류는 보존.
 *     - ERP 원천(항상 최신화): ACCT_NAME, 상위계정과목(UpperAccName),
 *       계정과목내부코드(AccSeq), 계정과목Lev(AccLevel), 상위계정과목내부코드(UpperAccSeq)
 *     - 도우 분류(절대 미접촉): ACCT_CLASS/expen_sel/대·중·소분류/경영계획과목 등
 *     - 운영에 없는 신규 계정 추가(분류=빈값 → 화면·이월로 보완), DELETE 없음
 *   ※VN판(UP_VN_IF_XFORM_ACCOUNT)은 상위계정과목이 도우 큐레이션 매핑(판)지급수수료
 *     병합 등, 리포트 item)이므로 이 확장을 적용하지 않는다(2026-08-26).
 *   시그니처: (@yyyymm, @selCode, @site) / 반환: 신규 추가 건수(int)
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
        SELECT RTRIM(AccNo) AS acct,
               MAX(AccName)                          AS acct_name,
               MAX(UpperAccName)                     AS upper_name,
               MAX(TRY_CONVERT(int, AccSeq))         AS acc_seq,
               MAX(TRY_CONVERT(int, AccLevel))       AS acc_lev,
               MAX(TRY_CONVERT(int, UpperAccSeq))    AS upper_seq
          FROM DOI_HQ_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    -- 1) 기존 계정: ERP 원천 필드 갱신 (도우 분류 컬럼 보존)
    UPDATE a
       SET a.ACCT_NAME              = e.acct_name,
           a.상위계정과목           = e.upper_name,
           a.계정과목내부코드       = e.acc_seq,
           a.계정과목Lev            = e.acc_lev,
           a.상위계정과목내부코드   = e.upper_seq
      FROM doi_acct a
      JOIN erp e ON RTRIM(a.ACCT) = e.acct
     WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site;

    -- 2) 운영에 없는 ERP 신규 계정만 추가 (분류=빈값)
    ;WITH erp AS (
        SELECT RTRIM(AccNo) AS acct,
               MAX(AccName)                          AS acct_name,
               MAX(UpperAccName)                     AS upper_name,
               MAX(TRY_CONVERT(int, AccSeq))         AS acc_seq,
               MAX(TRY_CONVERT(int, AccLevel))       AS acc_lev,
               MAX(TRY_CONVERT(int, UpperAccSeq))    AS upper_seq
          FROM DOI_HQ_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    INSERT INTO doi_acct (YYYYMM, SEL_CODE, SITE, ACCT_CLASS, ACCT, ACCT_NAME,
                          상위계정과목, 계정과목내부코드, 계정과목Lev, 상위계정과목내부코드)
    SELECT @yyyymm, @selCode, @site, '', e.acct, e.acct_name,
           e.upper_name, e.acc_seq, e.acc_lev, e.upper_seq
      FROM erp e
     WHERE NOT EXISTS (
              SELECT 1 FROM doi_acct a
               WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site
                 AND RTRIM(a.ACCT) = e.acct);

    SELECT @@ROWCOUNT;   -- 신규 추가 건수
END
