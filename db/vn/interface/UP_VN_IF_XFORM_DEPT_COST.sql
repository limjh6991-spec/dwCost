-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_DEPT_COST (스테이징) → DOI_DEPT_COST (운영)
--   부서별계정별비용. 엑셀 업로드(C0007001 uploadExcel)를 API 적재분으로 대체.
--   멱등: 동일 (site, yyyymm, sel_code) 삭제 후 재적재.
--
-- 매핑 결정(2026-08-28 보강):
--   · 계정코드←AccNo, 비용구분←UMCostTypeName(SG&A/MFG), 차변/대변←DrAmt/CrAmt, 코스트센터←CCtrName
--   · ★계정과목: 결산에 사용됨(VN_TotalCost_Tree 가 dc.계정과목 = DOI_VN_STCO.acct_name 로
--     노무비/제조경비 브리지). ERP 원문(베트남어+코드접두)이면 브리지 실패→총원가 0.
--     → **계정마스터 DOI_ACCT_VN.ACCT_KO(한국어명, 계정코드=ACCT)에서 직접 조회 + 정규화**
--       (엔대시 U+2013→하이픈, 선두 'NNNNNNN -' 코드접두 스트립). 이월(월의존) 대신 단일 마스터.
--       DOI_ACCT_VN 이 doi_dept_cost 계정코드 110/110 커버, 정규화 후 STCO 브리지 32/35(원장/트레이 제외).
--     · 마스터에 없는 계정(예외): 원문 AccName 접두/대시만 정규화(폴백, 베트남어 잔존 가능).
--   · ★코스트센터분류/코스트센터유형/제외여부 는 ERP 전수 공란(RAW_JSON UMCCtrKindName=''/
--     SMSourceTypeName='' 44/44 확인) → 도우 큐레이션. **전월(직전 큐레이션월) 이월**로 채움.
--     - 코스트센터분류/유형 ← 전월(코스트센터 1:1, 혼재 0)
--     - 제외여부 ← 전월(계정코드+코스트센터 그레인). 같은 계정도 코스트센터별 제외/포함 갈림
--       (202607 91계정 혼재)→계정코드 단독이면 과도제외. 규칙식은 원재료비(CC공란 포함) 예외로 부적합.
--   · 신규(전월에 없던) 코스트센터: 분류/제외 공란(화면 수기), 코스트센터유형은 CCtrName 있으면 'Dept.'
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
        s.AccName,                            -- 계정과목 (원문 → 아래 마스터조회로 교체)
        s.UMCostTypeName,                     -- 비용구분 (SG&A/MFG)
        CAST(s.DrAmt AS numeric(15,2)),
        CAST(s.CrAmt AS numeric(15,2)),
        NULL, NULL                            -- 제외여부/기타매출구분 (아래 이월)
    FROM DOI_VN_IF_DEPT_COST s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'');

    -- 2) ★계정과목: 계정마스터 DOI_ACCT_VN.ACCT_KO(한국어)에서 계정코드로 직접 조회 + 정규화
    --    (엔대시→하이픈, 선두 'NNNNNNN -'(공백유무 무관) 코드접두 스트립). 이월 아님.
    UPDATE d
       SET d.계정과목 =
           LTRIM(CASE
             WHEN REPLACE(v.ACCT_KO, NCHAR(8211), '-') LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9]%-%'
             THEN STUFF(REPLACE(v.ACCT_KO, NCHAR(8211), '-'), 1,
                        CHARINDEX('-', REPLACE(v.ACCT_KO, NCHAR(8211), '-')), '')
             ELSE REPLACE(v.ACCT_KO, NCHAR(8211), '-')
           END)
      FROM DOI_DEPT_COST d
      JOIN (SELECT ACCT, MAX(ACCT_KO) AS ACCT_KO
              FROM DOI_ACCT_VN WHERE ISNULL(ACCT_KO, N'') <> N'' GROUP BY ACCT) v
        ON RTRIM(v.ACCT) = RTRIM(d.계정코드)
     WHERE d.site=@site AND d.sel_code=@selCode AND d.yyyymm=@yyyymm;

    -- 2f) 폴백: 마스터에 없는 계정 — 원문 계정과목의 엔대시→하이픈, 코드접두 스트립
    UPDATE DOI_DEPT_COST SET 계정과목 = REPLACE(계정과목, NCHAR(8211), '-')
     WHERE site=@site AND sel_code=@selCode AND yyyymm=@yyyymm AND 계정과목 LIKE '%'+NCHAR(8211)+'%';
    UPDATE DOI_DEPT_COST SET 계정과목 = LTRIM(SUBSTRING(계정과목, LEN(계정코드)+4, LEN(계정과목)))
     WHERE site=@site AND sel_code=@selCode AND yyyymm=@yyyymm AND 계정과목 LIKE 계정코드 + ' - %';

    -- 3) 코스트센터분류/유형/제외여부: 전월(직전 큐레이션월) 이월
    DECLARE @prevYm VARCHAR(6);
    SELECT @prevYm = MAX(yyyymm)
      FROM DOI_DEPT_COST
     WHERE site = @site AND sel_code = @selCode AND yyyymm < @yyyymm
       AND (ISNULL(코스트센터분류, N'') <> N'' OR ISNULL(제외여부, N'') <> N'');

    IF @prevYm IS NOT NULL
    BEGIN
        -- 3a) 코스트센터분류/유형 ← 전월(코스트센터 1:1)
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

        -- 3b) 제외여부 ← 전월 (계정코드+코스트센터 그레인 필수)
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

    -- 4) 코스트센터유형 파생(전월에 없던 신규 코스트센터, 아직 NULL): CCtrName 있으면 'Dept.'
    UPDATE DOI_DEPT_COST SET 코스트센터유형 = N'Dept.'
     WHERE site=@site AND sel_code=@selCode AND yyyymm=@yyyymm
       AND ISNULL(코스트센터유형,N'')=N'' AND ISNULL(코스트센터,N'')<>N'';

    SELECT @@ROWCOUNT AS transformed;
END;
