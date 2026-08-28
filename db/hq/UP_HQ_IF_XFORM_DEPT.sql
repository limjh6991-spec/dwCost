/* ============================================================================
 * UP_HQ_IF_XFORM_DEPT  (ERP 부서코드(코스트센터) → 운영 doi_dept 업서트)
 *   staging DOI_HQ_IF_DEPT → doi_dept (YYYYMM+SEL_CODE+SITE+DEPT 그레인)
 *
 *   ★그레인=코스트센터. DEPT_NAME=코스트센터명(CCtrName), **DEPT=ERP CCtrSeq(코스트센터 코드)**.
 *     ⚠️DEPT 는 도우 순번이 아니라 ERP CCtrSeq 그대로 사용해야 운영과 일치
 *       (운영 HQ 202607: DEPT=CCtrSeq 83/83 일치. 과거 순번 생성 방식은 코드가 전부 어긋남).
 *     운영 DEPT_NAME 이 CCtrName 과 83/83 일치(DeptName은 68/83 뿐) → 코스트센터 그레인.
 *   ★업서트(코스트센터코드=CCtrSeq 기준):
 *     - 기존(DEPT=CCtrSeq 매칭): 코스트센터명·비용구분 갱신, 배부컬럼 보존
 *     - 비용구분(EXPEN_AREA) ← UMCCtrKindName(생산직접/생산간접/판매간접): ERP 원천, 기존/신규 갱신.
 *       운영과 100% 일치, DEPT_COST 코스트센터분류와 동일값. ※UMCostTypeName(제조/판관) 아님.
 *     - 신규 코스트센터만 DEPT=CCtrSeq 로 추가. DELETE 없음 → 배부(COST_DIST/RATE 등) 보존.
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

    -- ERP 코스트센터: 코드(CCtrSeq)·이름(CCtrName)·비용구분(UMCCtrKindName)
    ;WITH erp AS (
        SELECT LTRIM(RTRIM(CCtrName))          AS nm,
               MAX(TRY_CONVERT(int, CCtrSeq))  AS cctr_seq,
               MAX(UMCCtrKindName)             AS kind
          FROM DOI_HQ_IF_DEPT
         WHERE SITE = @site
           AND LTRIM(RTRIM(CCtrName)) <> ''
           AND TRY_CONVERT(int, CCtrSeq) > 0
         GROUP BY LTRIM(RTRIM(CCtrName))
    )
    -- 1) 기존 코스트센터(DEPT=CCtrSeq 매칭): 이름·비용구분 갱신 (배부컬럼 보존)
    UPDATE o
       SET o.DEPT_NAME  = e.nm,
           o.EXPEN_AREA = e.kind
      FROM doi_dept o
      JOIN erp e ON RTRIM(o.DEPT) = CAST(e.cctr_seq AS VARCHAR(10))
     WHERE o.YYYYMM = @yyyymm AND o.SEL_CODE = @selCode AND o.SITE = @site;

    -- 2) 운영에 없는 신규 코스트센터만 추가 (DEPT=CCtrSeq)
    ;WITH erp AS (
        SELECT LTRIM(RTRIM(CCtrName))          AS nm,
               MAX(TRY_CONVERT(int, CCtrSeq))  AS cctr_seq,
               MAX(UMCCtrKindName)             AS kind
          FROM DOI_HQ_IF_DEPT
         WHERE SITE = @site
           AND LTRIM(RTRIM(CCtrName)) <> ''
           AND TRY_CONVERT(int, CCtrSeq) > 0
         GROUP BY LTRIM(RTRIM(CCtrName))
    )
    INSERT INTO doi_dept (YYYYMM, SEL_CODE, SITE, DEPT, DEPT_NAME, EXPEN_AREA)
    SELECT @yyyymm, @selCode, @site,
           CAST(e.cctr_seq AS VARCHAR(10)), e.nm, e.kind
      FROM erp e
     WHERE NOT EXISTS (
               SELECT 1 FROM doi_dept o
                WHERE o.YYYYMM = @yyyymm AND o.SEL_CODE = @selCode AND o.SITE = @site
                  AND RTRIM(o.DEPT) = CAST(e.cctr_seq AS VARCHAR(10)));

    SELECT @@ROWCOUNT;   -- 신규 추가 건수
END
