/* 면적기준(모델별 기본정보) HQ 변환 — DOI_HQ_IF_PRODUCT_SPEC(스테이징) → DOI_MODEL_MAST[HQ] 면적
 *   매핑: MODEL←Model, X←width, Y←height, XY←area(면적 권위값; area 없으면 width×height 폴백), SPEC←Spec(76 절단).
 *   ★면적기준=MES 권위원천 → 매칭 '자동행(ADD_YN='N')'의 X/Y/XY/SPEC 덮어쓰기 + 누락 모델 INSERT.
 *     - 기존 HQ DOI_MODEL_MAST 는 이미 XY가 채워져 있어(genData 경유) fill-empty 로 하면 no-op → 덮어쓰기가 맞음.
 *     - 수동추가/보정행(ADD_YN='Y')은 UPDATE 대상에서 제외해 보존(사용자 add UI 입력 보호).
 *   ADD_YN 미지정 INSERT → DEFAULT 'N'(자동행). PK=(YYYYMM,SEL_CODE,SITE,MODEL).
 *   ※마감무관(마스터, 사용자 확정): 호출측 skipClosingGuard 로 마감월도 갱신 가능(DOI_MODEL_MAST 갱신은
 *     저장된 결산결과를 소급변경하지 않음 — 재정산해야 반영). 재정산 대상 월 갱신 시 주의.
 */
CREATE OR ALTER PROCEDURE UP_HQ_IF_XFORM_PRODUCT_SPEC
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;

    -- 스테이징 → 모델별 1건 정제 (MODEL 있는 행, 숫자화; 모델 중복시 area 최대 1건).
    --   XY = area 우선, 없으면 width×height 폴백(누락시 배부적수 0 방지, VN 관례).
    IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;
    SELECT MODEL, X, Y, XY, SPEC
    INTO #src
    FROM (
        SELECT
            LTRIM(RTRIM(s.Model))                       AS MODEL,
            TRY_CONVERT(real, s.width)                  AS X,
            TRY_CONVERT(real, s.height)                 AS Y,
            ISNULL(TRY_CONVERT(numeric(38,25), s.area),
                   TRY_CONVERT(numeric(38,25), TRY_CONVERT(real, s.width) * TRY_CONVERT(real, s.height))) AS XY,
            LEFT(LTRIM(RTRIM(s.Spec)), 76)              AS SPEC,
            ROW_NUMBER() OVER (PARTITION BY LTRIM(RTRIM(s.Model))
                               ORDER BY TRY_CONVERT(numeric(38,25), s.area) DESC) AS rn
        FROM DOI_HQ_IF_PRODUCT_SPEC s
        WHERE s.SITE = @site
          AND LTRIM(RTRIM(ISNULL(s.Model, N''))) <> N''
    ) t
    WHERE t.rn = 1;

    -- ① 기존 '자동행'(ADD_YN='N') 갱신 (권위원천 → 매칭 모델 면적 덮어쓰기; 소스값 유효시에만).
    --    수동추가/보정행(ADD_YN='Y')은 제외해 보존.
    UPDATE m
       SET m.X    = ISNULL(s.X,  m.X),
           m.Y    = ISNULL(s.Y,  m.Y),
           m.XY   = ISNULL(s.XY, m.XY),
           m.SPEC = COALESCE(NULLIF(s.SPEC, N''), m.SPEC)
    FROM DOI_MODEL_MAST m
    JOIN #src s ON s.MODEL = m.MODEL
    WHERE m.YYYYMM = @yyyymm AND m.SEL_CODE = @selCode AND m.SITE = @site
      AND ISNULL(m.ADD_YN, 'N') = 'N';
    DECLARE @upd INT = @@ROWCOUNT;

    -- ② 누락 모델 INSERT (기존 행 보존; ADD_YN 생략 → DEFAULT 'N')
    INSERT INTO DOI_MODEL_MAST (YYYYMM, SEL_CODE, SITE, MODEL, SPEC, X, Y, XY)
    SELECT @yyyymm, @selCode, @site, s.MODEL, s.SPEC, s.X, s.Y, s.XY
    FROM #src s
    WHERE NOT EXISTS (
        SELECT 1 FROM DOI_MODEL_MAST m
        WHERE m.YYYYMM = @yyyymm AND m.SEL_CODE = @selCode AND m.SITE = @site AND m.MODEL = s.MODEL
    );

    SELECT @upd + @@ROWCOUNT AS transformed;   -- 갱신 + 신규 합계

    DROP TABLE #src;
END;
