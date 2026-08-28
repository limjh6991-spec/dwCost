/* ============================================================================
 * UP_HQ_IF_XFORM_DEPT  (ERP 부서코드(코스트센터) → 운영 doi_dept 업서트)
 *   staging DOI_HQ_IF_DEPT → doi_dept (YYYYMM+SEL_CODE+SITE+DEPT 그레인)
 *
 *   ★그레인=코스트센터(CCtrName). ⚠️운영 doi_dept 는 부서가 아니라 **코스트센터** 단위:
 *     DEPT_NAME = 코스트센터명(CCtrName), DEPT = 도우 순번(1..N). (그리드 헤더도 코스트센터/코스트센터명)
 *     운영 HQ 202607 = 83개, DEPT_NAME 이 CCtrName 과 83/83 일치(DeptName은 68/83 뿐).
 *   ★업서트:
 *     - 비용구분(EXPEN_AREA) ← UMCCtrKindName(생산직접/생산간접/판매간접): ERP 원천이라
 *       기존/신규 모두 갱신. 운영 EXPEN_AREA와 100% 일치(83/83), DEPT_COST 코스트센터분류와 동일값.
 *       ※UMCostTypeName(제조/판관)이 아님 — 운영은 UMCCtrKind 3분류를 사용.
 *     - 운영에 없는 신규 코스트센터만 순번(MAX+1..) 부여해 추가.
 *       (RND_YN/COST_DIST/COST_DIST_RATE 등 배부 컬럼은 NULL → 화면에서 수기 보완)
 *     - DELETE 없음 → 배부 컬럼 전부 보존 (결산 안전). CCtrName 으로 매칭.
 *   시그니처: (@yyyymm, @selCode, @site) / 반환: 신규 추가 건수(int)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_DEPT
    @yyyymm  VARCHAR(20),
    @selCode VARCHAR(10),
    @site    VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode = '' SET @selCode = 'ACTUAL';
    IF @site    IS NULL OR @site    = '' SET @site    = 'HQ';

    -- ERP 코스트센터별 비용구분(코스트센터분류 UMCCtrKindName)
    -- 1) 기존 코스트센터: 비용구분(EXPEN_AREA) 갱신 (배부컬럼 COST_DIST/COST_DIST_RATE 등 보존)
    ;WITH erp AS (
        SELECT LTRIM(RTRIM(CCtrName)) AS nm, MAX(UMCCtrKindName) AS kind
          FROM DOI_HQ_IF_DEPT
         WHERE SITE = @site AND LTRIM(RTRIM(CCtrName)) <> ''
         GROUP BY LTRIM(RTRIM(CCtrName))
    )
    UPDATE o
       SET o.EXPEN_AREA = e.kind
      FROM doi_dept o
      JOIN erp e ON LTRIM(RTRIM(o.DEPT_NAME)) = e.nm
     WHERE o.YYYYMM = @yyyymm AND o.SEL_CODE = @selCode AND o.SITE = @site
       AND ISNULL(e.kind, N'') <> N'';

    -- 2) 운영에 없는 ERP 신규 코스트센터만 순번(MAX+1..) 부여해 추가 (+ 비용구분)
    DECLARE @maxDept INT =
        (SELECT ISNULL(MAX(TRY_CONVERT(int, DEPT)), 0)
           FROM doi_dept
          WHERE YYYYMM = @yyyymm AND SEL_CODE = @selCode AND SITE = @site);

    ;WITH erp AS (
        SELECT LTRIM(RTRIM(CCtrName)) AS nm, MAX(UMCCtrKindName) AS kind
          FROM DOI_HQ_IF_DEPT
         WHERE SITE = @site AND LTRIM(RTRIM(CCtrName)) <> ''
         GROUP BY LTRIM(RTRIM(CCtrName))
    )
    INSERT INTO doi_dept (YYYYMM, SEL_CODE, SITE, DEPT, DEPT_NAME, EXPEN_AREA)
    SELECT @yyyymm, @selCode, @site,
           CAST(@maxDept + ROW_NUMBER() OVER (ORDER BY e.nm) AS VARCHAR(10)),
           e.nm, e.kind
      FROM erp e
     WHERE NOT EXISTS (
               SELECT 1 FROM doi_dept o
                WHERE o.YYYYMM = @yyyymm AND o.SEL_CODE = @selCode AND o.SITE = @site
                  AND LTRIM(RTRIM(o.DEPT_NAME)) = e.nm);

    SELECT @@ROWCOUNT;   -- 신규 추가 건수
END
