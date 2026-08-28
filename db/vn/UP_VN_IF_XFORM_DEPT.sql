/* ============================================================================
 * UP_VN_IF_XFORM_DEPT  (ERP 부서코드 → 운영 doi_dept 업서트)
 *   staging DOI_VN_IF_DEPT → doi_dept (YYYYMM+SEL_CODE+SITE+DEPT 그레인)
 *
 *   ★업서트(사용자 확정 2026-08-24):
 *     ⚠️운영 doi_dept.DEPT 는 도우 자체 순번(1..N)이라 ERP DeptSeq(체계 다름)와
 *       매칭 불가 → 부서명(DEPT_NAME = ERP DeptName)으로 매칭.
 *     - 운영에 이름이 이미 있으면 스킵(배부/영역 컬럼 보존, 갱신할 값 없음)
 *     - 운영에 없는 ERP 신규 부서만 순번(MAX+1..) 부여해 추가
 *       (EXPEN_AREA/RND_YN/COST_DIST 등 배부 컬럼은 NULL → 화면에서 수기 보완)
 *     - DELETE 없음 → 기존/배부 전부 보존 (결산 안전)
 *   ※현재 ERP 34개가 이름으로 운영 34개와 전부 일치 → 신규 0(향후 신규 대비).
 *   시그니처: (@yyyymm, @selCode, @site) / 반환: 신규 추가 건수(int)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_VN_IF_XFORM_DEPT
    @yyyymm  VARCHAR(20),
    @selCode VARCHAR(10),
    @site    VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode = '' SET @selCode = 'ACTUAL';
    IF @site    IS NULL OR @site    = '' SET @site    = 'VN';

    DECLARE @maxDept INT =
        (SELECT ISNULL(MAX(TRY_CONVERT(int, DEPT)), 0)
           FROM doi_dept
          WHERE YYYYMM = @yyyymm AND SEL_CODE = @selCode AND SITE = @site);

    ;WITH newdept AS (
        SELECT LTRIM(RTRIM(e.DeptName)) AS nm,
               MAX(e.Remark)      AS remark,     -- ERP원천 → 비고
               MAX(e.EngDeptName) AS engnm       -- ERP원천 → 영문부서명
          FROM (SELECT DeptName, Remark, EngDeptName FROM DOI_VN_IF_DEPT WHERE SITE = @site) e
         WHERE LTRIM(RTRIM(e.DeptName)) <> ''
           AND NOT EXISTS (
                   SELECT 1 FROM doi_dept o
                    WHERE o.YYYYMM = @yyyymm AND o.SEL_CODE = @selCode AND o.SITE = @site
                      AND LTRIM(RTRIM(o.DEPT_NAME)) = LTRIM(RTRIM(e.DeptName)))
         GROUP BY LTRIM(RTRIM(e.DeptName))
    )
    INSERT INTO doi_dept (YYYYMM, SEL_CODE, SITE, DEPT, DEPT_NAME, 비고, 영문부서명)
    SELECT @yyyymm, @selCode, @site,
           CAST(@maxDept + ROW_NUMBER() OVER (ORDER BY nm) AS VARCHAR(10)),
           nm,
           NULLIF(LTRIM(RTRIM(remark)), ''),
           NULLIF(LTRIM(RTRIM(engnm)),  '')
      FROM newdept;
    DECLARE @ins INT = @@ROWCOUNT;   -- 신규 추가 건수

    -- ERP원천 명칭 컬럼 backfill: 기존 행에 비고/영문부서명이 비어있을 때만 채움
    -- (배부 컬럼 EXPEN_AREA/RND_YN/COST_DIST/COST_DIST_RATE, 사용자 수기 편집분 보존)
    UPDATE o
       SET o.비고      = COALESCE(NULLIF(LTRIM(RTRIM(o.비고)), ''),      NULLIF(LTRIM(RTRIM(s.Remark)), '')),
           o.영문부서명 = COALESCE(NULLIF(LTRIM(RTRIM(o.영문부서명)), ''), NULLIF(LTRIM(RTRIM(s.EngDeptName)), ''))
      FROM doi_dept o
      JOIN DOI_VN_IF_DEPT s
        ON s.SITE = @site AND LTRIM(RTRIM(s.DeptName)) = LTRIM(RTRIM(o.DEPT_NAME))
     WHERE o.YYYYMM = @yyyymm AND o.SEL_CODE = @selCode AND o.SITE = @site
       AND (NULLIF(LTRIM(RTRIM(o.비고)), '') IS NULL
         OR NULLIF(LTRIM(RTRIM(o.영문부서명)), '') IS NULL);

    SELECT @ins;   -- 신규 추가 건수
END
