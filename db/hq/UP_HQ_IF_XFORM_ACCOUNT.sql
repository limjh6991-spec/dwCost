/* ============================================================================
 * UP_HQ_IF_XFORM_ACCOUNT  (HQ ERP 계정코드 → 운영 doi_acct 업서트)
 *   staging DOI_HQ_IF_ACCOUNT → doi_acct (YYYYMM+SEL_CODE+SITE+ACCT 그레인)
 *
 *   ★업서트 원칙: ERP 원천 필드는 갱신/삽입, 도우 원가분류는 보존.
 *     - ERP 원천(항상 최신화): ACCT_NAME, 상위계정과목(UpperAccName),
 *       계정과목내부코드(AccSeq), 계정과목Lev(AccLevel), 상위계정과목내부코드(UpperAccSeq),
 *       계정대분류(SMAccKindName=자산/부채/자본/수익/비용),
 *       차대(SMDrOrCr 1→차변/-1→대변, RAW_JSON), 전표기표여부(IsSlip, RAW_JSON),
 *       관리항목유형(UMRemTypeName=예금/어음/부가세 유형, RAW_JSON)
 *       ⚠️관리항목유형은 ERP값이 있을 때만 갱신(COALESCE) — ERP 606/625 공란이며,
 *         운영엔 도우 큐레이션 원가분류가 들어있을 수 있어 공란으로 덮지 않음.
 *     - 도우 분류: ACCT_CLASS/expen_sel/expen_sel명/대·중·소분류/경영계획과목/특이사항 은
 *       ERP 원천이 아니라 도우 자체분류(계정관리 C0001004에서 관리).
 *       ★3)단계에서 '직전월 이월(backfill)'로 자동 채움 — 단 이미 값이 있는 계정은
 *         미접촉(수기편집 보존). 전월에 없던 신규계정은 공란 → 화면 수기.
 *       (dev는 전월 HQ월이 없으므로 운영 최신월 큐레이션을 1회 시드해야 이월 동작)
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
               MAX(TRY_CONVERT(int, UpperAccSeq))    AS upper_seq,
               MAX(SMAccKindName)                    AS acc_kind,   -- 계정대분류(자산/부채/자본/수익/비용)
               MAX(CASE JSON_VALUE(RAW_JSON,'$.SMDrOrCr')           -- 차대(계정별 실제 정상잔액측)
                        WHEN '1'  THEN N'차변' WHEN '-1' THEN N'대변' END) AS dr_cr,
               MAX(TRY_CONVERT(int, JSON_VALUE(RAW_JSON,'$.IsSlip'))) AS is_slip,  -- 전표기표여부
               MAX(NULLIF(JSON_VALUE(RAW_JSON,'$.UMRemTypeName'),'')) AS rem_type  -- 관리항목유형(ERP=예금/어음/부가세 유형, 606/625 공란)
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
           a.상위계정과목내부코드   = e.upper_seq,
           a.계정대분류             = e.acc_kind,
           a.차대                   = e.dr_cr,
           a.전표기표여부           = e.is_slip,
           a.관리항목유형           = COALESCE(e.rem_type, a.관리항목유형)  -- ERP값 있을때만, 공란이면 기존 보존
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
               MAX(TRY_CONVERT(int, UpperAccSeq))    AS upper_seq,
               MAX(SMAccKindName)                    AS acc_kind,   -- 계정대분류(자산/부채/자본/수익/비용)
               MAX(CASE JSON_VALUE(RAW_JSON,'$.SMDrOrCr')           -- 차대(계정별 실제 정상잔액측)
                        WHEN '1'  THEN N'차변' WHEN '-1' THEN N'대변' END) AS dr_cr,
               MAX(TRY_CONVERT(int, JSON_VALUE(RAW_JSON,'$.IsSlip'))) AS is_slip,  -- 전표기표여부
               MAX(NULLIF(JSON_VALUE(RAW_JSON,'$.UMRemTypeName'),'')) AS rem_type  -- 관리항목유형(ERP=예금/어음/부가세 유형, 606/625 공란)
          FROM DOI_HQ_IF_ACCOUNT
         WHERE SITE = @site AND AccNo IS NOT NULL AND RTRIM(AccNo) <> ''
         GROUP BY RTRIM(AccNo)
    )
    INSERT INTO doi_acct (YYYYMM, SEL_CODE, SITE, ACCT_CLASS, ACCT, ACCT_NAME,
                          상위계정과목, 계정과목내부코드, 계정과목Lev, 상위계정과목내부코드,
                          계정대분류, 차대, 전표기표여부, 관리항목유형)
    SELECT @yyyymm, @selCode, @site, '', e.acct, e.acct_name,
           e.upper_name, e.acc_seq, e.acc_lev, e.upper_seq,
           e.acc_kind, e.dr_cr, e.is_slip, e.rem_type
      FROM erp e
     WHERE NOT EXISTS (
              SELECT 1 FROM doi_acct a
               WHERE a.YYYYMM = @yyyymm AND a.SEL_CODE = @selCode AND a.SITE = @site
                 AND RTRIM(a.ACCT) = e.acct);

    DECLARE @added int = @@ROWCOUNT;   -- 신규 추가 건수(반환용)

    -- 3) 도우 큐레이션 이월(backfill): 직전월(같은 SITE/SEL_CODE) doi_acct 에서
    --    큐레이션이 아직 공란인 계정에만 복사. 수기 편집분은 미접촉(expen_sel 있으면 스킵).
    --    ※ERP 원천 컬럼은 위 1)·2)에서 이미 최신화. 여기서는 도우 자체분류만 이월.
    DECLARE @prevYm VARCHAR(20);
    SELECT @prevYm = MAX(YYYYMM)
      FROM doi_acct
     WHERE SITE = @site AND SEL_CODE = @selCode AND YYYYMM < @yyyymm
       AND ISNULL(expen_sel, N'') <> N'';   -- 큐레이션이 존재하는 가장 최근 과거월

    IF @prevYm IS NOT NULL
    BEGIN
        UPDATE a
           SET a.ACCT_CLASS   = p.ACCT_CLASS,
               a.expen_sel    = p.expen_sel,
               a.expen_sel명  = p.expen_sel명,
               a.경영계획과목 = p.경영계획과목,
               a.대분류       = p.대분류,
               a.중분류       = p.중분류,
               a.소분류       = p.소분류,
               a.특이사항     = p.특이사항
          FROM doi_acct a
          JOIN doi_acct p
            ON p.SITE = @site AND p.SEL_CODE = @selCode AND p.YYYYMM = @prevYm
           AND RTRIM(p.ACCT) = RTRIM(a.ACCT)
         WHERE a.SITE = @site AND a.SEL_CODE = @selCode AND a.YYYYMM = @yyyymm
           AND ISNULL(a.expen_sel, N'') = N''    -- 아직 미큐레이션 계정만(수기분 보존)
           AND ISNULL(p.expen_sel, N'') <> N'';  -- 원천에 세목이 있는 경우만
    END

    SELECT @added;   -- 신규 추가 건수
END
