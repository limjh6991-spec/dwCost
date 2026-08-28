/* ============================================================================
 * UP_VN_IF_XFORM_ACCOUNT  (ERP 계정코드 → 운영 doi_acct 업서트, VN)
 *   staging DOI_VN_IF_ACCOUNT → doi_acct (YYYYMM+SEL_CODE+SITE+ACCT 그레인)
 *
 *   ★매핑(2026-08-28 보강, VN 참조 202607 기준):
 *     - ERP 원천(항상 최신화): ACCT_NAME(AccName), 차대(SMDrOrCr 1→차변/-1→대변, RAW_JSON),
 *       전표기표여부(IsSlip, RAW_JSON)
 *     - 도우/VN 큐레이션(ERP에 없음 → 전월 이월 backfill, 공란셀만·수기편집 보존):
 *       ACCT_CLASS, 상위계정과목(★VN 전용 리포트 item명 — ERP UpperAccName(베트남어) 아님),
 *       expen_sel, expen_sel명, 원가구분, 한국어, English
 *     - VN 미사용(참조도 공란): 계정대분류/관리항목유형/계정과목내부코드/계정과목Lev/
 *       상위계정과목내부코드/경영계획과목/대·중·소분류/특이사항 → 미접촉
 *   시그니처: (@yyyymm, @selCode, @site) / 반환: 신규 추가 건수(int)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_VN_IF_XFORM_ACCOUNT
    @yyyymm  VARCHAR(20),
    @selCode VARCHAR(10),
    @site    VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode = '' SET @selCode = 'ACTUAL';
    IF @site    IS NULL OR @site    = '' SET @site    = 'VN';

    -- ERP staging 계정 (AccNo 중복 대비 집계). 차대=SMDrOrCr, 전표기표여부=IsSlip (RAW_JSON)
    ;WITH erp AS (
        SELECT RTRIM(AccNo) AS acct, MAX(AccName) AS acct_name,
               MAX(JSON_VALUE(RAW_JSON,'$.SMDrOrCr')) AS drcr,
               MAX(JSON_VALUE(RAW_JSON,'$.IsSlip'))   AS isslip
          FROM DOI_VN_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    -- 1) 기존 계정: 이름 + ERP원천(차대/전표기표여부) 갱신 (도우 큐레이션 컬럼 보존)
    UPDATE a
       SET a.ACCT_NAME    = e.acct_name,
           a.차대         = CASE WHEN e.drcr = '1'  THEN N'차변'
                                 WHEN e.drcr = '-1' THEN N'대변'
                                 ELSE a.차대 END,
           a.전표기표여부 = COALESCE(TRY_CONVERT(int, e.isslip), a.전표기표여부)
      FROM doi_acct a
      JOIN erp e ON RTRIM(a.ACCT) = e.acct
     WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site;

    -- 2) 운영에 없는 ERP 신규 계정만 추가 (도우분류=빈값, ERP원천 차대/전표기표여부 세팅)
    ;WITH erp AS (
        SELECT RTRIM(AccNo) AS acct, MAX(AccName) AS acct_name,
               MAX(JSON_VALUE(RAW_JSON,'$.SMDrOrCr')) AS drcr,
               MAX(JSON_VALUE(RAW_JSON,'$.IsSlip'))   AS isslip
          FROM DOI_VN_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    INSERT INTO doi_acct (YYYYMM, SEL_CODE, SITE, ACCT_CLASS, ACCT, ACCT_NAME, 차대, 전표기표여부)
    SELECT @yyyymm, @selCode, @site, '', e.acct, e.acct_name,
           CASE WHEN e.drcr = '1' THEN N'차변' WHEN e.drcr = '-1' THEN N'대변' ELSE N'' END,
           TRY_CONVERT(int, e.isslip)
      FROM erp e
     WHERE NOT EXISTS (
              SELECT 1 FROM doi_acct a
               WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site
                 AND RTRIM(a.ACCT) = e.acct);

    DECLARE @added int = @@ROWCOUNT;   -- 신규 추가 건수(반환용)

    -- 3) 도우/VN 큐레이션 전월 이월(backfill): ERP에 없는 자체분류를 직전월(같은 SITE/SEL_CODE,
    --    큐레이션 존재 최근월)에서 '현재 공란인 셀'에만 복사. 수기편집분(값 있는 셀) 미접촉.
    --    ※VN 전용: 상위계정과목(리포트 item명)/한국어/English/원가구분 포함(HQ와 상이).
    DECLARE @prevYm VARCHAR(20);
    SELECT @prevYm = MAX(YYYYMM)
      FROM doi_acct
     WHERE SITE = @site AND SEL_CODE = @selCode AND YYYYMM < @yyyymm
       AND ISNULL(expen_sel, N'') <> N'';   -- 큐레이션이 존재하는 가장 최근 과거월

    IF @prevYm IS NOT NULL
    BEGIN
        UPDATE a
           SET a.ACCT_CLASS   = CASE WHEN ISNULL(a.ACCT_CLASS,N'')=N''   AND ISNULL(p.ACCT_CLASS,N'')<>N''   THEN p.ACCT_CLASS   ELSE a.ACCT_CLASS   END,
               a.상위계정과목 = CASE WHEN ISNULL(a.상위계정과목,N'')=N'' AND ISNULL(p.상위계정과목,N'')<>N'' THEN p.상위계정과목 ELSE a.상위계정과목 END,
               a.expen_sel    = CASE WHEN ISNULL(a.expen_sel,N'')=N''    AND ISNULL(p.expen_sel,N'')<>N''    THEN p.expen_sel    ELSE a.expen_sel    END,
               a.expen_sel명  = CASE WHEN ISNULL(a.expen_sel명,N'')=N''  AND ISNULL(p.expen_sel명,N'')<>N''  THEN p.expen_sel명  ELSE a.expen_sel명  END,
               a.원가구분     = CASE WHEN ISNULL(a.원가구분,N'')=N''     AND ISNULL(p.원가구분,N'')<>N''     THEN p.원가구분     ELSE a.원가구분     END,
               a.한국어       = CASE WHEN ISNULL(a.한국어,N'')=N''       AND ISNULL(p.한국어,N'')<>N''       THEN p.한국어       ELSE a.한국어       END,
               a.English      = CASE WHEN ISNULL(a.English,N'')=N''      AND ISNULL(p.English,N'')<>N''      THEN p.English      ELSE a.English      END
          FROM doi_acct a
          JOIN doi_acct p
            ON p.SITE = @site AND p.SEL_CODE = @selCode AND p.YYYYMM = @prevYm
           AND RTRIM(p.ACCT) = RTRIM(a.ACCT)
         WHERE a.SITE = @site AND a.SEL_CODE = @selCode AND a.YYYYMM = @yyyymm;
    END

    SELECT @added;   -- 신규 추가 건수
END
