-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_DEPT_COST (스테이징) → DOI_DEPT_COST (운영)
--   부서별계정별비용. 엑셀 업로드(C0007001 uploadExcel)를 API 적재분으로 대체.
--   멱등: 동일 (site, yyyymm, sel_code) 삭제 후 재적재.
--
-- 매핑 결정(2026-08-28 보강):
--   · 계정코드←AccNo, 비용구분←UMCostTypeName(SG&A/MFG), 차변/대변←DrAmt/CrAmt, 코스트센터←CCtrName
--   · ★코스트센터분류/코스트센터유형/제외여부 는 ERP 전수 공란(RAW_JSON UMCCtrKindName=''/
--     SMSourceTypeName='' 44/44 확인) → 도우 큐레이션. **전월(직전 큐레이션월) 이월**로 채움.
--     - 코스트센터분류/유형 ← 전월(코스트센터 1:1, 혼재 0)
--     - 제외여부 ← 전월(계정코드 기준). VN 제외규칙은 단순치 않아(원재료비 CC공란인데 포함,
--       매출/수익/기타비용/대체는 CC있어도 제외) 규칙식 대신 이월이 안전.
--   · ★계정과목: 결산에 사용됨(VN_TotalCost_Tree 가 dc.계정과목 = DOI_VN_STCO.acct_name 로
--     노무비/제조경비 브리지). ERP 원문(베트남어+코드접두)이면 브리지 실패→총원가 0.
--     → 전월 clean 한국어명(계정코드 1:1) 계승 + 잔여 엔대시→하이픈 + 코드접두 스트립.
--   · 신규(전월에 없던) 계정/코스트센터: 분류/제외 공란(화면 수기), 코스트센터유형은 CCtrName 있으면 'Dept.'
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_DEPT_COST
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(6) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM DOI_DEPT_COST
    WHERE site = @site AND yyyymm = @yyyymm AND sel_code = @selCode;

    -- 1) ERP 원문 적재 (계정과목=AccName 원문, 큐레이션 컬럼=NULL)
    INSERT INTO DOI_DEPT_COST
        (yyyymm, sel_code, site,
         코스트센터, 코스트센터분류, 코스트센터유형,
         계정코드, 계정과목, 비용구분,
         차변금액, 대변금액, 제외여부, 기타매출구분)
    SELECT
        @yyyymm, @selCode, @site,
        s.CCtrName,                           -- 코스트센터
        NULL, NULL,                           -- 코스트센터분류/유형 (아래 이월)
        s.AccNo,                              -- 계정코드
        s.AccName,                            -- 계정과목 (원문 → 아래 정규화)
        s.UMCostTypeName,                     -- 비용구분 (SG&A/MFG)
        CAST(s.DrAmt AS numeric(15,2)),
        CAST(s.CrAmt AS numeric(15,2)),
        NULL, NULL                            -- 제외여부/기타매출구분 (아래 이월)
    FROM DOI_VN_IF_DEPT_COST s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'');

    -- 직전월(같은 site/sel_code, 큐레이션 존재 최근월)
    DECLARE @prevYm VARCHAR(6);
    SELECT @prevYm = MAX(yyyymm)
      FROM DOI_DEPT_COST
     WHERE site = @site AND sel_code = @selCode AND yyyymm < @yyyymm
       AND (ISNULL(코스트센터분류, N'') <> N'' OR ISNULL(제외여부, N'') <> N'');

    IF @prevYm IS NOT NULL
    BEGIN
        -- 2a) 계정과목: 전월 clean명(한국어) 계승 — 계정코드 1:1
        UPDATE d SET d.계정과목 = p.계정과목
          FROM DOI_DEPT_COST d
          JOIN (SELECT 계정코드, MAX(계정과목) AS 계정과목
                  FROM DOI_DEPT_COST
                 WHERE site=@site AND sel_code=@selCode AND yyyymm=@prevYm
                   AND ISNULL(계정과목,N'')<>N''
                 GROUP BY 계정코드) p
            ON RTRIM(p.계정코드) = RTRIM(d.계정코드)
         WHERE d.site=@site AND d.sel_code=@selCode AND d.yyyymm=@yyyymm;

        -- 2b) 코스트센터분류/유형: 전월 계승 — 코스트센터 1:1(혼재 0 확인)
        UPDATE d SET d.코스트센터분류 = p.코스트센터분류,
                     d.코스트센터유형 = p.코스트센터유형
          FROM DOI_DEPT_COST d
          JOIN (SELECT LTRIM(RTRIM(코스트센터)) AS cc,
                       MAX(코스트센터분류) AS 코스트센터분류,
                       MAX(코스트센터유형) AS 코스트센터유형
                  FROM DOI_DEPT_COST
                 WHERE site=@site AND sel_code=@selCode AND yyyymm=@prevYm AND ISNULL(코스트센터,N'')<>N''
                 GROUP BY LTRIM(RTRIM(코스트센터))) p
            ON p.cc = LTRIM(RTRIM(d.코스트센터))
         WHERE d.site=@site AND d.sel_code=@selCode AND d.yyyymm=@yyyymm;

        -- 2c) 제외여부: 전월 계승 — (계정코드+코스트센터) 그레인.
        --     ★같은 계정이라도 코스트센터별로 제외/포함이 갈림(202607 91계정 혼재) →
        --       계정코드 단독 이월은 과도제외로 결산 오류. 반드시 코스트센터까지 매칭.
        UPDATE d SET d.제외여부 = p.제외여부
          FROM DOI_DEPT_COST d
          JOIN (SELECT 계정코드, LTRIM(RTRIM(코스트센터)) AS cc, MAX(제외여부) AS 제외여부
                  FROM DOI_DEPT_COST
                 WHERE site=@site AND sel_code=@selCode AND yyyymm=@prevYm
                 GROUP BY 계정코드, LTRIM(RTRIM(코스트센터))) p
            ON RTRIM(p.계정코드) = RTRIM(d.계정코드)
           AND p.cc = LTRIM(RTRIM(d.코스트센터))
         WHERE d.site=@site AND d.sel_code=@selCode AND d.yyyymm=@yyyymm
           AND ISNULL(p.제외여부,N'')<>N'';
    END

    -- 3) 계정과목 잔여 정규화(전월에 없던 신규계정): 엔대시(U+2013)→하이픈, 코드접두 스트립
    UPDATE DOI_DEPT_COST SET 계정과목 = REPLACE(계정과목, NCHAR(8211), '-')
     WHERE site=@site AND sel_code=@selCode AND yyyymm=@yyyymm AND 계정과목 LIKE '%'+NCHAR(8211)+'%';
    UPDATE DOI_DEPT_COST SET 계정과목 = LTRIM(SUBSTRING(계정과목, LEN(계정코드)+4, LEN(계정과목)))
     WHERE site=@site AND sel_code=@selCode AND yyyymm=@yyyymm AND 계정과목 LIKE 계정코드 + ' - %';

    -- 4) 코스트센터유형 파생(전월에 없던 신규 코스트센터, 아직 NULL): CCtrName 있으면 'Dept.'
    UPDATE DOI_DEPT_COST SET 코스트센터유형 = N'Dept.'
     WHERE site=@site AND sel_code=@selCode AND yyyymm=@yyyymm
       AND ISNULL(코스트센터유형,N'')=N'' AND ISNULL(코스트센터,N'')<>N'';

    SELECT @@ROWCOUNT AS transformed;
END;
