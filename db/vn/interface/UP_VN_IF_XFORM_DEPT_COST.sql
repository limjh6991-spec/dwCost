-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_DEPT_COST (스테이징) → DOI_DEPT_COST (운영)
--   부서별계정별비용. 엑셀 업로드(C0007001 uploadExcel)를 API 적재분으로 대체.
--   멱등: 동일 (site, yyyymm, sel_code) 삭제 후 재적재.
--
-- 매핑 결정(2026-08):
--   · API 원문 그대로 저장 (계정과목/비용구분은 베트남어/영어 원문)
--   · API 미제공 컬럼(코스트센터분류/코스트센터유형/제외여부/기타매출구분)은 보류 → NULL
--   · yyyymm 은 API 응답에 없음 → 호출 파라미터로 주입
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_DEPT_COST
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(6) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    -- 대상 동일 키 제거 (멱등)
    DELETE FROM DOI_DEPT_COST
    WHERE site = @site AND yyyymm = @yyyymm AND sel_code = @selCode;

    INSERT INTO DOI_DEPT_COST
        (yyyymm, sel_code, site,
         코스트센터, 코스트센터분류, 코스트센터유형,
         계정코드, 계정과목, 비용구분,
         차변금액, 대변금액, 제외여부, 기타매출구분)
    SELECT
        @yyyymm,                              -- yyyymm (파라미터)
        @selCode,                             -- sel_code
        @site,                                -- site
        s.CCtrName,                           -- 코스트센터   ← CCtrName
        NULL,                                 -- 코스트센터분류 [보류: API 무]
        NULL,                                 -- 코스트센터유형 [보류: API 무]
        s.AccNo,                              -- 계정코드     ← AccNo
        s.AccName,                            -- 계정과목     ← AccName (원문)
        s.UMCostTypeName,                     -- 비용구분     ← UMCostTypeName (원문, 예: SG&A)
        CAST(s.DrAmt AS numeric(15,2)),       -- 차변금액     ← DrAmt
        CAST(s.CrAmt AS numeric(15,2)),       -- 대변금액     ← CrAmt
        NULL,                                 -- 제외여부     [보류: API 무]
        NULL                                  -- 기타매출구분 [보류]
    FROM DOI_VN_IF_DEPT_COST s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'');

    SELECT @@ROWCOUNT AS transformed;
END;
