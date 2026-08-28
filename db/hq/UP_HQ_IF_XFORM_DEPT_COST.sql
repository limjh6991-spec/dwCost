/* ============================================================================
 * UP_HQ_IF_XFORM_DEPT_COST  (HQ 부서별계정별비용 → 운영 DOI_DEPT_COST[HQ])
 *   staging DOI_HQ_IF_DEPT_COST → DOI_DEPT_COST. 멱등: (site,yyyymm,sel_code) 삭제 후 재적재.
 *
 *   매핑(2026-08-27, 정의서_HQ 응답라벨 + 운영 doi_dept_cost 실값 기준):
 *     · 코스트센터분류 ← UMCCtrKindName  (판매간접/생산간접)
 *     · 코스트센터유형 ← SMSourceTypeName (부서/수기입력)
 *     · 제외여부='집계제외' ← 비용구분 공란 OR 코스트센터 공란 OR 계정과목에 '매출원가'
 *       (운영 규칙 검증: 202607 64건 = 비용구분공란62 + 매출원가2)
 *     · 기타매출구분: 운영 전부 빈값 → NULL 유지
 * ========================================================================== */
CREATE OR ALTER PROCEDURE UP_HQ_IF_XFORM_DEPT_COST
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(6) = N'ACTUAL',
    @site    VARCHAR(4) = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM DOI_DEPT_COST
     WHERE site = @site AND yyyymm = @yyyymm AND sel_code = @selCode;

    INSERT INTO DOI_DEPT_COST
        (yyyymm, sel_code, site,
         코스트센터, 코스트센터분류, 코스트센터유형,
         계정코드, 계정과목, 비용구분,
         차변금액, 대변금액, 제외여부, 기타매출구분)
    SELECT
        @yyyymm, @selCode, @site,
        s.CCtrName,                           -- 코스트센터
        s.UMCCtrKindName,                     -- 코스트센터분류 ← UMCCtrKindName
        s.SMSourceTypeName,                   -- 코스트센터유형 ← SMSourceTypeName
        s.AccNo,                              -- 계정코드
        s.AccName,                            -- 계정과목
        s.UMCostTypeName,                     -- 비용구분
        CAST(s.DrAmt AS numeric(15,2)),       -- 차변금액
        CAST(s.CrAmt AS numeric(15,2)),       -- 대변금액
        CASE WHEN ISNULL(s.UMCostTypeName, N'') = N''      -- 비용구분 공란
                  OR ISNULL(s.CCtrName, N'') = N''         -- 코스트센터 공란
                  OR s.AccName LIKE N'%매출원가%'          -- 계정과목에 매출원가
             THEN N'집계제외' ELSE N'' END,   -- 제외여부
        NULL                                  -- 기타매출구분 (운영 전부 빈값)
    FROM DOI_HQ_IF_DEPT_COST s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'');

    SELECT @@ROWCOUNT AS transformed;
END;
