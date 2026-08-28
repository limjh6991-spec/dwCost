-- ⚠️운영(도우제조원가시스템) 배포용. dev(DWCMSTEST) 라이브 정의에서 추출(2026-08-28).
-- 검토 후 운영에서 실행. 멱등(존재시 스킵/ALTER).

-- 변환 프로시저 19종

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
GO

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
GO

/* ============================================================================
 * UP_HQ_IF_XFORM_DEPT_COST  (HQ 부서별계정별비용 → 운영 DOI_DEPT_COST[HQ])
 *   staging DOI_HQ_IF_DEPT_COST → DOI_DEPT_COST. 멱등: (site,yyyymm,sel_code) 삭제 후 재적재.
 *
 *   매핑(2026-08-28, 정의서_HQ 응답라벨 + 운영 doi_dept_cost 실값 기준):
 *     ⚠️부서별계정별비용 응답의 UMCCtrKindName/SMSourceTypeName 은 실호출 시 빈값('').
 *     · 코스트센터분류 ← **부서코드(코스트센터) 인터페이스 DOI_HQ_IF_DEPT.UMCCtrKindName**
 *       (CCtrName 조인; DEPT 응답엔 84/84 채워짐. 판매간접/생산간접/생산직접)
 *       → ★부서코드 API를 먼저(또는 함께) 호출해야 채워짐.
 *     · 코스트센터유형: 부서마스터(DEPT)에 코스트센터 있으면 N'부서', 없으면 N'수기입력'
 *       (운영 부서604/수기입력31 규칙 — ERP 원천 미제공이라 존재여부로 파생)
 *     · 제외여부='집계제외' ← 비용구분 공란 OR 코스트센터 공란 OR 계정과목에 '매출원가'
 *       OR 계정과목에 '집합계정'(재료비/제)경비/제)노무비 집합계정 — 중복집계 방지)
 *       (운영 규칙 검증: 202607 66건 = 비용구분공란62 + 매출원가2 + 제)집합계정2)
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
        d.UMCCtrKindName,                     -- 코스트센터분류 ← 부서코드(코스트센터) 조인
        CASE WHEN d.CCtrName IS NOT NULL THEN N'부서' ELSE N'수기입력' END,  -- 코스트센터유형(존재여부 파생)
        s.AccNo,                              -- 계정코드
        s.AccName,                            -- 계정과목
        s.UMCostTypeName,                     -- 비용구분
        CAST(s.DrAmt AS numeric(15,2)),       -- 차변금액
        CAST(s.CrAmt AS numeric(15,2)),       -- 대변금액
        CASE WHEN ISNULL(s.UMCostTypeName, N'') = N''      -- 비용구분 공란
                  OR ISNULL(s.CCtrName, N'') = N''         -- 코스트센터 공란
                  OR s.AccName LIKE N'%매출원가%'          -- 계정과목에 매출원가
                  OR s.AccName LIKE N'%집합계정%'          -- 제)~집합계정(재료비/경비/노무비 집합) — 중복집계 방지
             THEN N'집계제외' ELSE N'' END,   -- 제외여부
        NULL                                  -- 기타매출구분 (운영 전부 빈값)
    FROM DOI_HQ_IF_DEPT_COST s
    -- 코스트센터분류/유형: 부서코드(코스트센터) staging 에서 CCtrName 으로 조회
    LEFT JOIN (
        SELECT LTRIM(RTRIM(CCtrName)) AS CCtrName, MAX(UMCCtrKindName) AS UMCCtrKindName
          FROM DOI_HQ_IF_DEPT WHERE SITE = @site AND ISNULL(CCtrName,N'') <> N''
         GROUP BY LTRIM(RTRIM(CCtrName))
    ) d ON d.CCtrName = LTRIM(RTRIM(s.CCtrName))
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'');

    SELECT @@ROWCOUNT AS transformed;
END;
GO

/* ============================================================================
 * UP_HQ_IF_XFORM_EXP_INVOICE  (HQ 수출Invoice → 운영 DOI_INVOICE_RESC[HQ])
 *   staging DOI_HQ_IF_EXP_INVOICE → DOI_INVOICE_RESC (VN doi_invoice_resc와 동일 37컬럼)
 *   VN UP_VN_IF_XFORM_EXP_SALES 매핑 미러 + HQ 수출Invoice 응답필드명 반영.
 *   멱등: 동일 (site, yyyymm, sel_code) 삭제 후 재적재. 월필터=InvoiceDate.
 *   ※국내(거래명세서 SALES_HQ)는 별도 테이블 — 본 변환과 분리(충돌 없음).
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_EXP_INVOICE
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode='' SET @selCode='ACTUAL';
    IF @site    IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_INVOICE_RESC
     WHERE site=@site AND yyyymm=@yyyymm AND sel_code=@selCode;

    INSERT INTO DOI_INVOICE_RESC
        (yyyymm, sel_code, site, 사업단위, Invoice_No, Invoice관리번호, Invoice_Date, 수출구분, 출고구분, 가격조건,
         부서, 담당자, Buyer, Agent, 통화, 환율, 품명, 품번, 규격, 단위,
         판매기준가, 판매단가, 수량, 판매금액, 원화판매금액, 창고, 진행상태, Remarks, 특이사항)
    SELECT
         @yyyymm, @selCode, @site,
         s.BizUnitName, s.InvoiceNo, s.InvoiceRefNo, s.InvoiceDate, s.SMExpKindName, s.UMOutKindName, s.UMPriceTermName,
         s.DeptName, s.EmpName, s.CustName, s.BKCustName, s.CurrName,
         TRY_CONVERT(numeric(18,2), s.ExRate), s.ItemName, s.ItemNo, s.Spec, s.UnitName,
         TRY_CONVERT(numeric(18,0), s.ItemPrice), TRY_CONVERT(numeric(18,2), s.CustPrice),
         TRY_CONVERT(bigint, TRY_CONVERT(numeric(38,6), s.Qty)),   -- 수량: 소수문자열→numeric→bigint (직접 bigint 변환은 NULL)
         TRY_CONVERT(numeric(15,2), s.CurAmt), TRY_CONVERT(numeric(15,2), s.DomAmt),
         s.WHName, s.SMProgressTypeName, s.Remark, s.RemarkM
      FROM DOI_HQ_IF_EXP_INVOICE s
     WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'')
       AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT;
END
GO

/* ============================================================================
 * UP_HQ_IF_XFORM_MATERIAL  (HQ 자재코드/제품별공정별소요자재 → 운영 DOI_BOM_MAST[HQ])
 *   staging DOI_HQ_IF_MATERIAL(소요자재 66필드) → DOI_BOM_MAST (YYYYMM+SITE)
 *   제품/공정/자재 + 소요량/Loss율 1:1 의미 매핑. 멱등: (YYYYMM,SITE) 삭제 후 재적재.
 *   (마스터 — 요청이 스코프, 데이터-날짜 없음 → @yyyymm 태깅)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_MATERIAL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @site IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_BOM_MAST WHERE YYYYMM=@yyyymm AND SITE=@site;

    INSERT INTO DOI_BOM_MAST
        (YYYYMM, SITE, 제품명, 제품번호, 품목자산분류, 품목대분류, 품목중분류, 품목소분류,
         공정차수, 공정, 공정품명, 공정품번호, 자재명, 자재번호, 자재자산분류,
         자재대분류, 자재중분류, 자재소분류, 투입단위, 소요량, 내부Loss율, 외부Loss율,
         조립위치, 특이사항, 최초작성일, 최초작성자, 최종수정일, 최종수정자)
    SELECT
         @yyyymm, @site, s.ItemName, s.ItemNo, s.AssetName, s.UMItemClassLName, s.UMItemClassMName, s.UMItemClassName,
         s.ProcRev, s.ProcName, s.AssyItemName, s.AssyItemNo, s.MatItemName, s.MatItemNo, s.MatAssetName,
         s.MatUMItemClassLName, s.MatUMItemClassMName, s.MatUMItemClassName, s.MatUnitName,
         TRY_CONVERT(numeric(18,6), s.MatQty), TRY_CONVERT(numeric(18,4), s.InLossRate), TRY_CONVERT(numeric(18,4), s.OutLossRate),
         s.Location, s.Remark, s.RegDate, s.RegEmpName, s.LastDateTime, s.UptEmpName
      FROM DOI_HQ_IF_MATERIAL s
     WHERE s.SITE=@site;

    SELECT @@ROWCOUNT;
END
GO

/* ============================================================================
 * UP_HQ_IF_XFORM_SALES  (HQ 국내 거래명세서 → 운영 DOI_SALE_RESC[HQ])
 *   staging DOI_HQ_IF_SALES(84필드) → DOI_SALE_RESC(64컬럼, 국내매출)
 *   ※수출(EXP_INVOICE_HQ→DOI_INVOICE_RESC)과 별도 테이블(사용자 확정).
 *   멱등: 동일 (SITE,YYYYMM,SEL_CODE) 삭제 후 재적재. 월필터=InvoiceDate(거래명세서일).
 *   ⚠️필드 매핑은 정의서 응답필드 기반 best-effort — 실데이터로 검증 필요.
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_SALES
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode='' SET @selCode='ACTUAL';
    IF @site    IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_SALE_RESC
     WHERE SITE=@site AND YYYYMM=@yyyymm AND SEL_CODE=@selCode;

    INSERT INTO DOI_SALE_RESC
        (YYYYMM, SEL_CODE, SITE, 사업단위, 거래명세서번호, 거래명세서일, Local구분, 출고구분,
         부서, 담당자, 청구처, 거래처, 거래처번호, 중개인, 납품장소, 인도조건,
         품명, 품번, 규격, 판매단위, 판매기준가, 수량, 부가세포함, 통화, 환율,
         판매단가, 판매금액, 부가세액, 판매금액계, 원화판매금액, 원화부가세액, 원화판매금액계,
         창고, 보관위치, Lot_No, 세금계산서_진행상태, 배송상태, 매출수량, 반품,
         기타출고구분, 품목자산분류, PO_No, SEQ_NO)
    SELECT
         @yyyymm, @selCode, @site,
         s.BizUnitName, s.InvoiceNo, s.InvoiceDate, s.SMExpKindName, s.UMOutKindName,
         s.DeptName, s.EmpName, s.BillCustName, s.CustName, s.CustNo, s.BKCustName, s.DVPlaceName, s.DVCondition,
         s.ItemName, s.ItemNo, s.Spec, s.UnitName,
         TRY_CONVERT(numeric(18,2), s.Price), TRY_CONVERT(int, TRY_CONVERT(numeric(38,6), s.Qty)), s.IsInclusedVAT, s.CurrName,   -- 수량: numeric 경유(직접 int 변환은 소수문자열→NULL)
         TRY_CONVERT(numeric(18,2), s.ExRate),
         TRY_CONVERT(numeric(18,2), s.CustPrice), TRY_CONVERT(numeric(18,2), s.CurAmt),
         TRY_CONVERT(numeric(18,2), s.CurVAT), TRY_CONVERT(numeric(18,2), s.TotCurAmt),
         TRY_CONVERT(numeric(18,2), s.DomAmt), TRY_CONVERT(numeric(18,2), s.DomVAT),
         TRY_CONVERT(numeric(18,2), s.TotDomAmt),
         s.WHName, s.Location, s.LotNo, s.SMProgressTypeName, s.SMTransStatusName,
         TRY_CONVERT(int, TRY_CONVERT(numeric(38,6), s.SalesQty)), s.IsReturn, s.UMEtcOutKindName, s.AssetName, s.PONo,   -- 매출수량: numeric 경유
         ROW_NUMBER() OVER (ORDER BY s.InvoiceNo, s.ItemNo, s.InvoiceDate)   -- SEQ_NO (PK, 행 고유번호)
      FROM DOI_HQ_IF_SALES s
     WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'')
       AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT;
END
GO

CREATE OR ALTER PROCEDURE UP_HQ_IF_XFORM_STOCK_DETAIL
    @yyyymm  VARCHAR(6), @selCode VARCHAR(10) = N'ACTUAL', @site VARCHAR(4) = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_HQ_IF_STOCK_DETAIL(스테이징) -> ① DOI_HQ_STOCK_DETAIL(그리드 C0007014_Sch1, 원천/재고조정 UP_VN_STOCK_ADJ 입력) + ② DOI_MATL_RESC(재료비원장)
    --   재고금액상세. 스테이징 데이터-날짜 없음(월말 스냅샷) → 요청월(@yyyymm) 태깅.
    -- ① 그리드/원천 테이블
    DELETE FROM DOI_HQ_STOCK_DETAIL WHERE yyyymm=@yyyymm;
    INSERT INTO DOI_HQ_STOCK_DETAIL
        (자산처리계정, 품목자산분류, 재고자산종류, 매출원가계정, 대분류, 중분류, 소분류, 품목기타분류, 품명, 품번, 규격, 단위,
         기초수량, 기초금액, 입고수량, 입고금액, 출고수량, 출고금액, 재고수량A, 결산후재고수량B, 차이수량A_B, 재고금액C, 결산후재고금액D, 차이금액C_D,
         최종결산월재고단가, 생산수량, 생산금액, 구매수량, 구매금액, 적송입고수량, 적송입고금액, 기타입고수량, 기타입고금액,
         판매수량, 판매원가, 투입수량, 투입금액, 적송출고수량, 적송출고금액, 기타출고수량, 기타출고금액, yyyymm, edit_user, edit_date)
    SELECT s.AssetAccName, s.AssetName, s.AssetGroupName, TRY_CONVERT(numeric(28,8), LEFT(LTRIM(s.SalesAccName), NULLIF(PATINDEX('%[^0-9]%', LTRIM(s.SalesAccName)+'x')-1,-1))),
        s.UMItemClassLName, s.UMItmeClassMName, s.UMItemClassSName, s.UMItemEtcClassName, s.ItemName, s.ItemNo, s.Spec, s.UnitName,
        CAST(s.PreQty AS numeric(28,8)), CAST(s.PreAmt AS numeric(28,8)), CAST(s.InQty AS numeric(28,8)), CAST(s.InAmt AS numeric(28,8)),
        CAST(s.OutQty AS numeric(28,8)), CAST(s.OutAmt AS numeric(28,8)), CAST(s.StockQty AS numeric(28,8)), CAST(s.StockQty2 AS numeric(28,8)),
        CAST(s.DiffQty AS numeric(28,8)), CAST(s.StockAmt AS numeric(28,8)), CAST(s.StockAmt2 AS numeric(28,8)), CAST(s.DiffAmt AS numeric(28,8)),
        CAST(s.StkPrice AS numeric(28,8)), CAST(s.ProdQty AS numeric(28,8)), CAST(s.ProdAmt AS numeric(28,8)), CAST(s.BuyQty AS numeric(28,8)), CAST(s.BuyAmt AS numeric(28,8)),
        CAST(s.MvInQty AS numeric(28,8)), CAST(s.MvInAmt AS numeric(28,8)), CAST(s.EtcInQty AS numeric(28,8)), CAST(s.EtcInAmt AS numeric(28,8)),
        CAST(s.SalesQty AS numeric(28,8)), CAST(s.SalesAmt AS numeric(28,8)), CAST(s.InputQty AS numeric(28,8)), CAST(s.InputAmt AS numeric(28,8)),
        CAST(s.MvOutQty AS numeric(28,8)), CAST(s.MvOutAmt AS numeric(28,8)), CAST(s.EtcOutQty AS numeric(28,8)), CAST(s.EtcOutAmt AS numeric(28,8)),
        @yyyymm, N'IF-STOCK_DETAIL', GETDATE()
    FROM DOI_HQ_IF_STOCK_DETAIL s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');

    -- ② 재료비원장 (기존 유지)
    DELETE FROM DOI_MATL_RESC WHERE [YYYYMM]=@yyyymm AND [SEL_CODE]=@selCode AND [SITE]=@site;
    INSERT INTO DOI_MATL_RESC
        ([YYYYMM],[SEL_CODE],[SITE],[자산처리계정],[품목자산분류],[재고자산종류],[매출원가계정],[대분류],[중분류],[소분류],[품목기타분류],[품명],[품번],[규격],[단위],[기초수량],[기초금액],[입고수량],[입고금액],[출고수량],[출고금액],[재고수량],[결산후재고수량],[차이수량],[재고금액],[결산후재고금액],[차이금액],[최종결산월재고단가],[생산수량],[생산금액],[구매수량],[구매금액],[적송입고수량],[적송입고금액],[기타입고수량],[기타입고금액],[판매수량],[판매원가],[투입수량],[투입금액],[적송출고수량],[적송출고금액],[기타출고수량],[기타출고금액])
    SELECT @yyyymm,@selCode,@site, s.AssetAccName, s.AssetName, s.AssetGroupName, s.SalesAccName,
        s.UMItemClassLName, s.UMItmeClassMName, s.UMItemClassSName, s.UMItemEtcClassName, s.ItemName, s.ItemNo, s.Spec, s.UnitName,
        CAST(s.PreQty AS real), CAST(s.PreAmt AS numeric(15,2)), CAST(s.InQty AS real), CAST(s.InAmt AS numeric(15,2)),
        CAST(s.OutQty AS real), CAST(s.OutAmt AS numeric(15,2)), CAST(s.StockQty AS real), CAST(s.StockQty2 AS real), CAST(s.DiffQty AS real),
        CAST(s.StockAmt AS numeric(15,2)), CAST(s.StockAmt2 AS numeric(15,2)), CAST(s.DiffAmt AS numeric(15,2)), CAST(s.StkPrice AS real),
        CAST(s.ProdQty AS real), CAST(s.ProdAmt AS numeric(15,2)), CAST(s.BuyQty AS real), CAST(s.BuyAmt AS numeric(15,2)),
        CAST(s.MvInQty AS real), CAST(s.MvInAmt AS numeric(15,2)), CAST(s.EtcInQty AS real), CAST(s.EtcInAmt AS numeric(15,2)),
        CAST(s.SalesQty AS real), CAST(s.SalesAmt AS numeric(15,2)), CAST(s.InputQty AS real), CAST(s.InputAmt AS numeric(15,2)),
        CAST(s.MvOutQty AS real), CAST(s.MvOutAmt AS numeric(15,2)), CAST(s.EtcOutQty AS real), CAST(s.EtcOutAmt AS numeric(15,2))
    FROM DOI_HQ_IF_STOCK_DETAIL s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');

    SELECT @@ROWCOUNT AS transformed;
END
GO

/* ============================================================================
 * UP_HQ_IF_XFORM_WH_STOCK_SUM  (HQ 제품정보/창고별수불집계 → 운영 DOI_STOCK[HQ])
 *   staging DOI_HQ_IF_WH_STOCK_SUM → DOI_STOCK
 *   그레인: (YYYYMM, SEL_CODE, SITE, MODEL=품명, MODEL_TYPE=도우코드, STOCK=창고)
 *   요약(기초/입고/출고/재고)만 제공 → 상세컬럼(INPUT_ETC/OUT_* 등)은 0.
 *   멱등: 동일 (SITE,YYYYMM,SEL_CODE) 삭제 후 재적재. (스냅샷 — 요청기간이 스코프)
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_HQ_IF_XFORM_WH_STOCK_SUM
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4)  = N'HQ'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode='' SET @selCode='ACTUAL';
    IF @site    IS NULL OR @site='' SET @site='HQ';

    DELETE FROM DOI_STOCK WHERE YYYYMM=@yyyymm AND SEL_CODE=@selCode AND SITE=@site;

    INSERT INTO DOI_STOCK (YYYYMM, SEL_CODE, SITE, MODEL, MODEL_TYPE, STOCK, BOH, INPUT, OUT, EOH)
    SELECT @yyyymm, @selCode, @site,
           LTRIM(RTRIM(s.ItemName)), LTRIM(RTRIM(s.ItemNo)), LTRIM(RTRIM(s.WHName)),
           SUM(TRY_CONVERT(numeric(18,2), s.PrevQty)),
           SUM(TRY_CONVERT(numeric(18,2), s.InQty)),
           SUM(TRY_CONVERT(numeric(18,2), s.OutQty)),
           SUM(TRY_CONVERT(numeric(18,2), s.StockQty))
      FROM DOI_HQ_IF_WH_STOCK_SUM s
     WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'')
       AND s.ItemNo IS NOT NULL AND LTRIM(RTRIM(s.ItemNo))<>''
       AND s.WHName IS NOT NULL AND LTRIM(RTRIM(s.WHName))<>''
     GROUP BY LTRIM(RTRIM(s.ItemName)), LTRIM(RTRIM(s.ItemNo)), LTRIM(RTRIM(s.WHName));

    SELECT @@ROWCOUNT;
END
GO

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
GO

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
GO

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
GO

-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_ETC_INOUT (스테이징) -> doi_vn_etc_inout (운영)
--   기타입출고금액 (수량/금액/단가는 NVARCHAR->TRY_CONVERT)
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_ETC_INOUT
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_vn_etc_inout
    WHERE [yyyymm] = @yyyymm;

    INSERT INTO doi_vn_etc_inout
        ([회계단위], [일자], [입출고구분], [원천구분], [기타입출고구분], [품목자산분류], [대분류], [중분류], [소분류], [품명], [품번], [규격], [단위], [단수보정구분], [수량], [금액], [단가], [계정과목], [창고], [사용부서], [거래처], [특이사항], [품목특이사항], [yyyymm], [edit_user], [edit_date])
    SELECT
        ISNULL(JSON_VALUE(s.RAW_JSON, N'$.PriceUnitName'), N'DOWOO VINA'),  -- 회계단위 (ERP 가격단위=회계단위=DOWOO VINA, 공란시 상수)
        s.InOutDate,  -- 일자
        s.InOutName,  -- 입출고구분
        s.UMEtcOutKindSource,  -- 원천구분
        s.UMEtcOutKindDetail,  -- 기타입출고구분
        s.AssetName,  -- 품목자산분류
        s.UMItemClassLName,  -- 대분류
        s.UMItemClassMName,  -- 중분류
        s.UMItemClassSName,  -- 소분류
        s.ItemName,  -- 품명
        s.ItemNo,  -- 품번
        s.Spec,  -- 규격
        s.UnitName,  -- 단위
        s.SMAdjustKindName,  -- 단수보정구분
        TRY_CONVERT(numeric(28,8), s.EtcOutQty),  -- 수량
        TRY_CONVERT(numeric(28,8), s.EtcOutAmt),  -- 금액
        TRY_CONVERT(numeric(28,8), s.EtcOutPrice),  -- 단가
        s.AccName,  -- 계정과목
        s.WHName,  -- 창고
        s.DeptName,  -- 사용부서
        s.CustName,  -- 거래처
        s.Remark,  -- 특이사항
        s.ItemRemark,  -- 품목특이사항
        @yyyymm,  -- yyyymm
        N'IF',  -- edit_user
        GETDATE()   -- edit_date
    FROM DOI_VN_IF_ETC_INOUT s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InOutDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_EXP_CLAIM
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_VN_IF_EXP_CLAIM(스테이징) -> DOI_VN_EXP_CLAIM(운영/조회, 그리드 TAB070016_Sch1)
    --   멱등: 동일 키 삭제 후 재적재. 월 스코프: ClaimDate(YYYYMMDD)의 YYYYMM = @yyyymm.
    DELETE FROM DOI_VN_EXP_CLAIM
    WHERE yyyymm = @yyyymm AND sel_code = @selCode AND site = @site;

    INSERT INTO DOI_VN_EXP_CLAIM
        (yyyymm, sel_code, site, 사업단위, Claim번호, ClaimDate, 반품종류, 반품구분, 담당자, 부서,
         Buyer, Agent, 반품진행, 재수출진행, 통화, 환율, 품명, 품번, 규격, 판매단위, 기준단위,
         기준단위수량, 정가, 판매기준가, 판매단가, 수량, 판매금액, 원화판매금액, 창고, Remarks, edit_user, edit_date)
    SELECT
        @yyyymm, @selCode, @site,
        s.BizUnitName, s.ClaimNo, s.ClaimDate, s.SMExpKindName, s.UMOutKindName, s.EmpName, s.DeptName,
        s.CustName, s.BKCustName, s.SMProgressReturnTypeName, s.SMProgressTypeName, s.CurrName,
        CAST(s.ExRate AS numeric(18,5)), s.ItemName, s.ItemNo, s.Spec, s.UnitName, s.StdUnitName,
        CAST(s.StdQty AS numeric(18,3)), CAST(s.ItemPrice AS numeric(18,5)), CAST(s.CustPrice AS numeric(18,5)),
        CAST(s.Price AS numeric(18,5)), CAST(s.Qty AS numeric(18,3)), CAST(s.CurAmt AS numeric(18,2)),
        CAST(s.DomAmt AS numeric(18,2)), s.WHName, s.RemarkM, N'IF-EXP_CLAIM', GETDATE()
    FROM DOI_VN_IF_EXP_CLAIM s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.ClaimDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
GO

-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_EXP_SALES (스테이징) -> doi_invoice_resc (운영)
--   수출매출품목
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_EXP_SALES
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_invoice_resc
    WHERE [yyyymm] = @yyyymm AND [sel_code] = @selCode AND [site] = @site;

    INSERT INTO doi_invoice_resc
        ([yyyymm], [sel_code], [site], [선택], [출고처리], [사업단위], [Invoice_No], [Invoice관리번호], [Invoice_Date], [수출구분], [출고구분], [가격조건], [부서], [담당자], [Buyer], [통화], [환율], [품명], [품번], [규격], [단위], [판매기준가], [판매단가], [수량], [판매금액], [원화판매금액], [매출금액계], [미매출금액], [매출대상], [진행상태], [매출진행상태], [창고], [Remarks], [특이사항])
    SELECT
        @yyyymm,  -- yyyymm
        @selCode,  -- sel_code
        @site,  -- site
        0,  -- 선택 (큐레이션 기본값)
        1,  -- 출고처리 (큐레이션 기본값)
        s.BizUnitName,  -- 사업단위
        s.InvoiceRefNo,  -- Invoice_No (외부 인보이스 참조번호)
        JSON_VALUE(s.RAW_JSON, N'$.BillNo'),  -- Invoice관리번호 (ERP 전표관리번호, 매핑누락 정정)
        s.InvoiceDate,  -- Invoice_Date
        s.SMExpKindName,  -- 수출구분
        CASE WHEN NULLIF(LTRIM(RTRIM(s.UMChannelName)), N'') IS NULL THEN N'정상판매' ELSE s.UMChannelName END,  -- 출고구분 (ERP 공란→큐레이션 기본값)
        s.UMPriceTermsName,  -- 가격조건
        s.DeptName,  -- 부서
        s.EmpName,  -- 담당자
        s.CustName,  -- Buyer
        s.CurrName,  -- 통화
        CAST(s.ExRate AS numeric(18,2)),  -- 환율
        s.ItemName,  -- 품명
        s.ItemNo,  -- 품번
        s.Spec,  -- 규격
        s.UnitName,  -- 단위
        CAST(s.ItemPrice AS numeric(18,0)),  -- 판매기준가
        CAST(s.CustPrice AS numeric(18,2)),  -- 판매단가
        CAST(s.Qty AS bigint),  -- 수량
        CAST(s.CurAmt AS numeric(15,2)),  -- 판매금액
        CAST(s.DomAmt AS numeric(15,2)),  -- 원화판매금액
        CAST(s.CurAmt AS numeric(15,2)),  -- 매출금액계 (=판매금액)
        0,  -- 미매출금액 (큐레이션 기본값)
        0,  -- 매출대상 (큐레이션 기본값)
        N'완료',  -- 진행상태 (ERP 미제공→큐레이션 기본값)
        N'완료',  -- 매출진행상태 (큐레이션 기본값)
        s.WHName,  -- 창고
        s.RemarkI,  -- Remarks
        s.RemarkM   -- 특이사항
    FROM DOI_VN_IF_EXP_SALES s
    WHERE s.SITE = @site
      AND ISNULL(s.SEL_CODE, N'') = ISNULL(@selCode, N'')
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.InvoiceDate))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS transformed;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_FG_SUBUL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10),
    @site    VARCHAR(4) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    /* [VN 인터페이스 변환] MES 재고수불(FG) 스테이징 → 운영 제품재고수불(doi_vn_stock_resc)
       - mat_id = 도우코드 (직접), division = DOI_VN_STCO 조회(없으면 이력/기본값)
       - 컬럼은 정의서 ver1.8 재고수불 응답필드 ↔ doi_vn_stock_resc 1:1 매핑
       - 반제품(SEMI) 유/무상 입고는 API 미제공 → 0 (추후 필요시 보완) */

    DELETE FROM doi_vn_stock_resc WHERE yyyymm = @yyyymm AND sel_code = @selCode;

    INSERT INTO doi_vn_stock_resc
        (yyyymm, sel_code, 도우코드, division, BOH,
         IN_NORMAL_LAST, IN_NORMAL_THIS,
         IN_RW_BACKSHIP_SORT, IN_RW_BACKSHIP_PFRW, IN_RW_BACKSHIP_PLRW,
         IN_RW_WHRET_SORT, IN_RW_WHRET_PFRW, IN_RW_WHRET_PLRW,
         T_INPUT, ETCIN_RMA, ETCIN_SEMI_PAID, ETCIN_SEMI_FREE, ETCIN_ETC, ETCIN_TOTAL,
         OUT_SHIP_A_PAID, OUT_SHIP_A_FREE, OUT_SHIP_B, T_OUTPUT,
         ETCOUT_RESORT, ETCOUT_REWORK, ETCOUT_FREESALE, ETCOUT_ETC, ETCOUT_TOTAL,
         LOSS, EOH_WH0006, VERIFY, EDIT_USER, EDIT_DT)
    SELECT
         @yyyymm, @selCode, s.mat_id,
         COALESCE(
             (SELECT TOP 1 c.division FROM DOI_VN_STCO c WHERE c.도우코드 = s.mat_id ORDER BY c.yyyymm DESC, c.sel_code),
             (SELECT TOP 1 r.division FROM doi_vn_stock_resc r WHERE r.도우코드 = s.mat_id ORDER BY r.yyyymm DESC),
             'MP') AS division,
         ISNULL(s.boh_ok_mes, 0),
         ISNULL(s.normal_last_month, 0), ISNULL(s.normal_this_month, 0),
         ISNULL(s.backship_sorting, 0), ISNULL(s.backship_pfrw, 0), ISNULL(s.backship_plrw, 0),
         ISNULL(s.wh_rt_sorting, 0), ISNULL(s.wh_rt_pfrw, 0), ISNULL(s.wh_rt_plrw, 0),
         ISNULL(s.total_wh_input, 0),
         ISNULL(s.back_ship_ng_qty, 0),      -- ETCIN_RMA
         0, 0,                                -- ETCIN_SEMI_PAID / SEMI_FREE (API 미제공)
         ISNULL(s.etc_input, 0),              -- ETCIN_ETC
         ISNULL(s.other_input_total, 0),      -- ETCIN_TOTAL
         ISNULL(s.shipped_level_a_paid, 0), ISNULL(s.shipped_level_a_free, 0),
         ISNULL(s.shipped_level_b_paid, 0),   -- OUT_SHIP_B
         ISNULL(s.t_output_3, 0),             -- T_OUTPUT
         ISNULL(s.line_transfer_sorting, 0),  -- ETCOUT_RESORT
         ISNULL(s.line_transfer_rework, 0),   -- ETCOUT_REWORK
         ISNULL(s.shipped_level_b_free, 0),   -- ETCOUT_FREESALE (B급 무상매출)
         ISNULL(s.etc_output, 0),             -- ETCOUT_ETC
         ISNULL(s.other_output_total, 0),     -- ETCOUT_TOTAL
         ISNULL(s.loss_spare, 0),             -- LOSS
         ISNULL(s.eoh_ok_mes, 0),             -- EOH_WH0006
         0,                                   -- VERIFY (검증용, 후속 산식화)
         'IF_API', GETDATE()
    FROM DOI_VN_IF_FG_SUBUL s
    WHERE s.SITE = @site AND s.SEL_CODE = @selCode
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.work_date))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT AS loaded;
END
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_ITEM_INPUT
    @yyyymm VARCHAR(6), @selCode VARCHAR(10)=N'ACTUAL', @site VARCHAR(4)=N'VN'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_VN_IF_ITEM_INPUT(스테이징) -> DOI_VN_MAT_INPUT(그리드 C0007012_VN_Sch1)
    --   품목별투입조회. 스테이징에 데이터-날짜 없음 → 요청월(@yyyymm)로 태깅(요청이 월 스코프).
    DELETE FROM DOI_VN_MAT_INPUT WHERE yyyymm=@yyyymm;
    INSERT INTO DOI_VN_MAT_INPUT
        (제품명, 제품번호, 제품규격, 자재명, 자재번호, 자재규격, 투입수량, 단가, 투입금액,
         생산투입비용계정, 제품품목자산분류, 자재품목자산분류, yyyymm, edit_user, edit_date)
    SELECT s.ItemName, s.ItemNo, s.ItemSpec, s.MatName, s.MatNo, s.Spec,
        CAST(s.InputQty AS numeric(28,8)), CAST(s.Price AS numeric(28,8)), CAST(s.Amt AS numeric(28,8)),
        s.InputCost, s.AssetName, s.MatAssetName, @yyyymm, N'IF-ITEM_INPUT', GETDATE()
    FROM DOI_VN_IF_ITEM_INPUT s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');
    SELECT @@ROWCOUNT AS transformed;
END
GO

-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_MATERIAL (스테이징) -> doi_vn_material (운영)
--   자재코드 (마스터, IF SEL_CODE 무 -> site 기준)
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_MATERIAL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_vn_material
    WHERE [yyyymm] = @yyyymm;

    INSERT INTO doi_vn_material
        ([자재명], [자재번호], [규격], [품목자산분류], [기준단위], [자재상태], [내외자구분], [중요도], [관리부서], [관리자], [자재대분류], [자재중분류], [자재소분류], [영문명], [출고구분], [대표자재], [BOM등록], [제품별공정소요자재], [Lot 관리], [Serial 관리], [단가등록여부], [유통기한구분], [유통기간], [등록자], [등록일], [품목설명], [기본구매처], [수탁거래처], [부가세구분], [판매단가에 부가세포함여부], [첨부파일], [이미지], [최종수정자], [최종수정일], [MAT_GRP_1], [MAT_GRP_2], [MAT_GRP_4], [MAT_GRP_5], [MAT_GRP_6], [MAT_GRP_7], [MAT_GRP_8], [MAT_GRP_9], [MAT_GRP_10], [MAT_CMF_1], [MAT_CMF_2], [MAT_CMF_3], [MAT_CMF_4], [MAT_CMF_5], [MAT_CMF_6], [MAT_CMF_7], [MAT_CMF_8], [MAT_CMF_9], [MAT_CMF_10], [MAT_CMF_11], [MAT_CMF_12], [MAT_CMF_13], [MAT_CMF_14], [MAT_CMF_15], [MAT_CMF_16], [MAT_CMF_17], [MAT_CMF_18], [MAT_CMF_19], [MAT_CMF_20], [FIRST_FLOW], [FIRST_FLOW_SEQ_NUM], [LAST_FLOW], [LAST_FLOW_SEQ_NUM], [MFG_DEVISION], [SUBCONTRACT_FLAG], [BASE_MAT_ID], [VENDOR_ID], [VENDOR_MAT_ID], [CUSTOMER_ID], [CUSTOMER_MAT_ID], [BOM_SET_ID], [APPLY_START_TIME], [APPLY_END_TIME], [APPROVAL_FLAG], [APPROVAL_USER_ID], [APPROVAL_TIME], [RELEASE_FLAG], [RELEASE_USER_ID], [RELEASE_TIME], [DEACTIVE_FLAG], [DEACTIVE_USER_ID], [DEACTIVE_TIME], [MAT_SHORT_DESC], [VENDOR], [IQC YN], [yyyymm], [edit_user], [edit_date])
    SELECT
        s.ItemName,  -- 자재명
        s.ItemNo,  -- 자재번호
        s.Spec,  -- 규격
        s.AssetName,  -- 품목자산분류
        s.UnitName,  -- 기준단위
        s.SMStatusName,  -- 자재상태
        s.SMInOutKindName,  -- 내외자구분
        s.SMABCName,  -- 중요도
        s.DeptName,  -- 관리부서
        s.EmpName,  -- 관리자
        s.ItemClassLName,  -- 자재대분류
        s.ItemClassMName,  -- 자재중분류
        s.ItemClassSName,  -- 자재소분류
        s.ItemEngName,  -- 영문명
        s.SMOutKindName,  -- 출고구분
        s.IsSTDItem,  -- 대표자재
        s.IsBOMReg,  -- BOM등록
        s.IsProcMat,  -- 제품별공정소요자재
        s.IsLotMng,  -- Lot 관리
        s.IsSerialMng,  -- Serial 관리
        s.IsPrice,  -- 단가등록여부
        s.SMLimitTermKindName,  -- 유통기한구분
        s.SMLimitTermKind,  -- 유통기간
        CAST(s.RegUserSeq AS nvarchar(50)),  -- 등록자
        s.RegDate,  -- 등록일
        s.Remark,  -- 품목설명
        s.PurCustName,  -- 기본구매처
        s.TrustCustName,  -- 수탁거래처
        s.SMVatKindName,  -- 부가세구분
        s.PriceInVat,  -- 판매단가에 부가세포함여부
        s.IsFileCheck,  -- 첨부파일
        s.IsImageCheck,  -- 이미지
        CAST(s.LastUserSeq AS nvarchar(50)),  -- 최종수정자
        s.LastDate,  -- 최종수정일
        s.MAT_GRP_1,  -- MAT_GRP_1
        s.MAT_GRP_2,  -- MAT_GRP_2
        s.MAT_GRP_4,  -- MAT_GRP_4
        s.MAT_GRP_5,  -- MAT_GRP_5
        s.MAT_GRP_6,  -- MAT_GRP_6
        s.MAT_GRP_7,  -- MAT_GRP_7
        s.MAT_GRP_8,  -- MAT_GRP_8
        s.MAT_GRP_9,  -- MAT_GRP_9
        s.MAT_GRP_10,  -- MAT_GRP_10
        s.MAT_CMF_1,  -- MAT_CMF_1
        s.MAT_CMF_2,  -- MAT_CMF_2
        s.MAT_CMF_3,  -- MAT_CMF_3
        s.MAT_CMF_4,  -- MAT_CMF_4
        s.MAT_CMF_5,  -- MAT_CMF_5
        s.MAT_CMF_6,  -- MAT_CMF_6
        s.MAT_CMF_7,  -- MAT_CMF_7
        s.MAT_CMF_8,  -- MAT_CMF_8
        s.MAT_CMF_9,  -- MAT_CMF_9
        s.MAT_CMF_10,  -- MAT_CMF_10
        s.MAT_CMF_11,  -- MAT_CMF_11
        s.MAT_CMF_12,  -- MAT_CMF_12
        s.MAT_CMF_13,  -- MAT_CMF_13
        s.MAT_CMF_14,  -- MAT_CMF_14
        s.MAT_CMF_15,  -- MAT_CMF_15
        s.MAT_CMF_16,  -- MAT_CMF_16
        s.MAT_CMF_17,  -- MAT_CMF_17
        s.MAT_CMF_18,  -- MAT_CMF_18
        s.MAT_CMF_19,  -- MAT_CMF_19
        s.MAT_CMF_20,  -- MAT_CMF_20
        s.FIRST_FLOW,  -- FIRST_FLOW
        CAST(s.FIRST_FLOW_SEQ_NUM AS nvarchar(20)),  -- FIRST_FLOW_SEQ_NUM
        s.LAST_FLOW,  -- LAST_FLOW
        CAST(s.LAST_FLOW_SEQ_NUM AS nvarchar(20)),  -- LAST_FLOW_SEQ_NUM
        s.MFG_DEVISION,  -- MFG_DEVISION
        s.SUBCONTRACT_FLAG,  -- SUBCONTRACT_FLAG
        s.BASE_MAT_ID,  -- BASE_MAT_ID
        s.VENDOR_ID,  -- VENDOR_ID
        s.VENDOR_MAT_ID,  -- VENDOR_MAT_ID
        s.CUSTOMER_ID,  -- CUSTOMER_ID
        s.CUSTOMER_MAT_ID,  -- CUSTOMER_MAT_ID
        s.BOM_SET_ID,  -- BOM_SET_ID
        s.APPLY_START_TIME,  -- APPLY_START_TIME
        s.APPLY_END_TIME,  -- APPLY_END_TIME
        s.APPROVAL_FLAG,  -- APPROVAL_FLAG
        s.APPROVAL_USER_ID,  -- APPROVAL_USER_ID
        s.APPROVAL_TIME,  -- APPROVAL_TIME
        s.RELEASE_FLAG,  -- RELEASE_FLAG
        s.RELEASE_USER_ID,  -- RELEASE_USER_ID
        s.RELEASE_TIME,  -- RELEASE_TIME
        s.DEACTIVE_FLAG,  -- DEACTIVE_FLAG
        s.DEACTIVE_USER_ID,  -- DEACTIVE_USER_ID
        s.DEACTIVE_TIME,  -- DEACTIVE_TIME
        s.MAT_SHORT_DESC,  -- MAT_SHORT_DESC
        s.VENDOR,  -- VENDOR
        s.IQC_YN,  -- IQC YN
        @yyyymm,  -- yyyymm
        N'IF',  -- edit_user
        GETDATE()   -- edit_date
    FROM DOI_VN_IF_MATERIAL s
    WHERE s.SITE = @site;

    SELECT @@ROWCOUNT AS transformed;
END;
GO

CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_STOCK_DETAIL
    @yyyymm  VARCHAR(6), @selCode VARCHAR(10) = N'ACTUAL', @site VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;
    -- 다운스트림 변환: DOI_VN_IF_STOCK_DETAIL(스테이징) -> ① DOI_VN_STOCK_DETAIL(그리드 C0007014_Sch1, 원천/재고조정 UP_VN_STOCK_ADJ 입력) + ② DOI_MATL_RESC(재료비원장)
    --   재고금액상세. 스테이징 데이터-날짜 없음(월말 스냅샷) → 요청월(@yyyymm) 태깅.
    -- ① 그리드/원천 테이블
    DELETE FROM DOI_VN_STOCK_DETAIL WHERE yyyymm=@yyyymm;
    INSERT INTO DOI_VN_STOCK_DETAIL
        (자산처리계정, 품목자산분류, 재고자산종류, 매출원가계정, 대분류, 중분류, 소분류, 품목기타분류, 품명, 품번, 규격, 단위,
         기초수량, 기초금액, 입고수량, 입고금액, 출고수량, 출고금액, 재고수량A, 결산후재고수량B, 차이수량A_B, 재고금액C, 결산후재고금액D, 차이금액C_D,
         최종결산월재고단가, 생산수량, 생산금액, 구매수량, 구매금액, 적송입고수량, 적송입고금액, 기타입고수량, 기타입고금액,
         판매수량, 판매원가, 투입수량, 투입금액, 적송출고수량, 적송출고금액, 기타출고수량, 기타출고금액, yyyymm, edit_user, edit_date)
    SELECT s.AssetAccName, s.AssetName, s.AssetGroupName, TRY_CONVERT(numeric(28,8), LEFT(LTRIM(s.SalesAccName), NULLIF(PATINDEX('%[^0-9]%', LTRIM(s.SalesAccName)+'x')-1,-1))),
        s.UMItemClassLName, JSON_VALUE(s.RAW_JSON, N'$.UMItemClassMName'), s.UMItemClassSName, s.UMItemEtcClassName, s.ItemName, s.ItemNo, s.Spec, s.UnitName,
        CAST(s.PreQty AS numeric(28,8)), CAST(s.PreAmt AS numeric(28,8)), CAST(s.InQty AS numeric(28,8)), CAST(s.InAmt AS numeric(28,8)),
        CAST(s.OutQty AS numeric(28,8)), CAST(s.OutAmt AS numeric(28,8)), CAST(s.StockQty AS numeric(28,8)), CAST(s.StockQty2 AS numeric(28,8)),
        CAST(s.DiffQty AS numeric(28,8)), CAST(s.StockAmt AS numeric(28,8)), CAST(s.StockAmt2 AS numeric(28,8)), CAST(s.DiffAmt AS numeric(28,8)),
        CAST(s.StkPrice AS numeric(28,8)), CAST(s.ProdQty AS numeric(28,8)), CAST(s.ProdAmt AS numeric(28,8)), CAST(s.BuyQty AS numeric(28,8)), CAST(s.BuyAmt AS numeric(28,8)),
        CAST(s.MvInQty AS numeric(28,8)), CAST(s.MvInAmt AS numeric(28,8)), CAST(s.EtcInQty AS numeric(28,8)), CAST(s.EtcInAmt AS numeric(28,8)),
        CAST(s.SalesQty AS numeric(28,8)), CAST(s.SalesAmt AS numeric(28,8)), CAST(s.InputQty AS numeric(28,8)), CAST(s.InputAmt AS numeric(28,8)),
        CAST(s.MvOutQty AS numeric(28,8)), CAST(s.MvOutAmt AS numeric(28,8)), CAST(s.EtcOutQty AS numeric(28,8)), CAST(s.EtcOutAmt AS numeric(28,8)),
        @yyyymm, N'IF-STOCK_DETAIL', GETDATE()
    FROM DOI_VN_IF_STOCK_DETAIL s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');

    -- ② 재료비원장 (기존 유지)
    DELETE FROM DOI_MATL_RESC WHERE [YYYYMM]=@yyyymm AND [SEL_CODE]=@selCode AND [SITE]=@site;
    INSERT INTO DOI_MATL_RESC
        ([YYYYMM],[SEL_CODE],[SITE],[자산처리계정],[품목자산분류],[재고자산종류],[매출원가계정],[대분류],[중분류],[소분류],[품목기타분류],[품명],[품번],[규격],[단위],[기초수량],[기초금액],[입고수량],[입고금액],[출고수량],[출고금액],[재고수량],[결산후재고수량],[차이수량],[재고금액],[결산후재고금액],[차이금액],[최종결산월재고단가],[생산수량],[생산금액],[구매수량],[구매금액],[적송입고수량],[적송입고금액],[기타입고수량],[기타입고금액],[판매수량],[판매원가],[투입수량],[투입금액],[적송출고수량],[적송출고금액],[기타출고수량],[기타출고금액])
    SELECT @yyyymm,@selCode,@site, s.AssetAccName, s.AssetName, s.AssetGroupName, s.SalesAccName,
        s.UMItemClassLName, JSON_VALUE(s.RAW_JSON, N'$.UMItemClassMName'), s.UMItemClassSName, s.UMItemEtcClassName, s.ItemName, s.ItemNo, s.Spec, s.UnitName,
        CAST(s.PreQty AS real), CAST(s.PreAmt AS numeric(15,2)), CAST(s.InQty AS real), CAST(s.InAmt AS numeric(15,2)),
        CAST(s.OutQty AS real), CAST(s.OutAmt AS numeric(15,2)), CAST(s.StockQty AS real), CAST(s.StockQty2 AS real), CAST(s.DiffQty AS real),
        CAST(s.StockAmt AS numeric(15,2)), CAST(s.StockAmt2 AS numeric(15,2)), CAST(s.DiffAmt AS numeric(15,2)), CAST(s.StkPrice AS real),
        CAST(s.ProdQty AS real), CAST(s.ProdAmt AS numeric(15,2)), CAST(s.BuyQty AS real), CAST(s.BuyAmt AS numeric(15,2)),
        CAST(s.MvInQty AS real), CAST(s.MvInAmt AS numeric(15,2)), CAST(s.EtcInQty AS real), CAST(s.EtcInAmt AS numeric(15,2)),
        CAST(s.SalesQty AS real), CAST(s.SalesAmt AS numeric(15,2)), CAST(s.InputQty AS real), CAST(s.InputAmt AS numeric(15,2)),
        CAST(s.MvOutQty AS real), CAST(s.MvOutAmt AS numeric(15,2)), CAST(s.EtcOutQty AS real), CAST(s.EtcOutAmt AS numeric(15,2))
    FROM DOI_VN_IF_STOCK_DETAIL s
    WHERE s.SITE=@site AND ISNULL(s.SEL_CODE,N'')=ISNULL(@selCode,N'');

    SELECT @@ROWCOUNT AS transformed;
END
GO

/* ============================================================================
 * UP_VN_IF_XFORM_WIP_SUBUL  (MES 생산수불 → 운영 재공수불 doi_vn_prod_resc)
 *   staging DOI_VN_IF_WIP_SUBUL (mat_id 그레인, PL전50%=before_pfl_50 / 후90%=after_pfl_90 int)
 *   → doi_vn_prod_resc (도우코드 그레인, 전/후 numeric, 포지션 LINE·B_LEVEL × WIP·FGS)
 *
 *   ★매핑 근거(2026-08-24, staging 62행 전수 내부합계 검증 PASS):
 *     - mat_id = 도우코드 (직접, 중복 0 → 집계 불필요; FG_SUBUL과 동일)
 *     - division = DOI_VN_STCO 조회(MASS→MP 정규화), 없으면 접미 P→MP/else→R&D
 *     - 전 = before_pfl_50 / pfl_50, 후 = after_pfl_90 / pfl_90  (완성률 가중은 하류 재공평가 단계)
 *     - 검증: A_SUB=LINE_WIP+LINE_FGS, B_SUB=B_WIP+B_FGS, T_BOH=A+B, EOH_WIP=line+b,
 *             TOTAL_EOH=WIP+FGS, total_input_to_line=기타입고4합, total_output=A급+B급,
 *             out_b=반제품유상+무상, 코드변경/기타출고=전량0  (전부 62/62)
 *     - OUTPUT_A = total_out_a_level(A급 정상완성), 반제품(B급)=ETCOUT_SEMI 유/무상
 *     - ETCIN_SEMI(반제품입고)·T_EOH_FGS(합)는 MES 직접컬럼 없음 → 0 / 합산 산출
 *   시그니처: (@yyyymm, @selCode, @site) / 반환: 적재 건수(int)
 *   ⚠️doi_vn_prod_resc 는 _NEW 결산 입력. DELETE+INSERT(yyyymm+sel_code) 멱등.
 * ========================================================================== */
CREATE OR ALTER PROCEDURE dbo.UP_VN_IF_XFORM_WIP_SUBUL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10),
    @site    VARCHAR(4) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    IF @selCode IS NULL OR @selCode = '' SET @selCode = 'ACTUAL';
    IF @site    IS NULL OR @site    = '' SET @site    = 'VN';

    DELETE FROM doi_vn_prod_resc WHERE yyyymm = @yyyymm AND sel_code = @selCode;

    INSERT INTO doi_vn_prod_resc
        (yyyymm, sel_code, 도우코드, division,
         BOH_LINE_WIP_전, BOH_LINE_WIP_후, BOH_LINE_FGS_전, BOH_LINE_FGS_후,
         BOH_A_SUB_전, BOH_A_SUB_후, BOH_B_WIP_전, BOH_B_WIP_후, BOH_B_FGS_전, BOH_B_FGS_후,
         BOH_B_SUB_전, BOH_B_SUB_후, T_BOH_전, T_BOH_후,
         USC_INPUT, ETCIN_CODE, ETCIN_RESORT, ETCIN_REWORK, ETCIN_SEMI, ETCIN_ETC, ETCIN_TOTAL,
         OUTPUT_A,
         ETCOUT_CODE_전, ETCOUT_CODE_후, ETCOUT_SEMI_PAID_전, ETCOUT_SEMI_PAID_후,
         ETCOUT_SEMI_FREE_전, ETCOUT_SEMI_FREE_후, ETCOUT_ETC_전, ETCOUT_ETC_후,
         ETCOUT_TOTAL_전, ETCOUT_TOTAL_후, LOSS_전, LOSS_후,
         EOH_LINE_WIP_전, EOH_LINE_WIP_후, EOH_LINE_FGS_전, EOH_LINE_FGS_후,
         EOH_B_WIP_전, EOH_B_WIP_후, EOH_B_FGS_전, EOH_B_FGS_후,
         T_EOH_WIP_전, T_EOH_WIP_후, T_EOH_FGS_전, T_EOH_FGS_후, TOTAL_EOH_전, TOTAL_EOH_후,
         EDIT_USER, EDIT_DT)
    SELECT
         @yyyymm, @selCode, LTRIM(RTRIM(s.mat_id)),
         COALESCE(
             (SELECT TOP 1 CASE WHEN c.division IN ('MASS','MP') THEN 'MP' ELSE 'R&D' END
                FROM DOI_VN_STCO c WHERE c.도우코드 = LTRIM(RTRIM(s.mat_id)) ORDER BY c.yyyymm DESC, c.sel_code),
             CASE WHEN RIGHT(RTRIM(s.mat_id),1) = 'P' THEN 'MP' ELSE 'R&D' END) AS division,
         -- BOH (전=before_pfl_50, 후=after_pfl_90)
         ISNULL(s.boh_a_wip_before_pfl_50,0), ISNULL(s.boh_a_wip_after_pfl_90,0),
         ISNULL(s.boh_a_fgs_before_pfl_50,0), ISNULL(s.boh_a_fgs_after_pfl_90,0),
         ISNULL(s.boh_a_before_pfl_50,0),     ISNULL(s.boh_a_after_pfl_90,0),
         ISNULL(s.boh_b_wip_before_pfl_50,0), ISNULL(s.boh_b_wip_after_pfl_90,0),
         ISNULL(s.boh_b_fgs_before_pfl_50,0), ISNULL(s.boh_b_fgs_after_pfl_90,0),
         ISNULL(s.boh_b_before_pfl_50,0),     ISNULL(s.boh_b_after_pfl_90,0),
         ISNULL(s.t_boh_before_pfl_50,0),     ISNULL(s.t_boh_after_pfl_90,0),
         -- INPUT / 기타입고 (SEMI=API미제공→0, TOTAL=라인총투입=기타입고4합)
         ISNULL(s.input_usc_cutting_qty,0),
         ISNULL(s.change_code_qty,0), ISNULL(s.input_re_sorting_qty,0), ISNULL(s.input_rework_qty,0),
         0, ISNULL(s.wip_etc_input,0), ISNULL(s.total_input_to_line,0),
         -- OUTPUT_A (A급 정상완성)
         ISNULL(s.total_out_a_level,0),
         -- 기타출고 (전/후): CODE=0, 반제품(B급) 유/무상, ETC=0
         ISNULL(s.output_code_change_50,0),  ISNULL(s.output_code_change_90,0),
         ISNULL(s.b_level_ship_paid_50,0),   ISNULL(s.b_level_ship_paid_90,0),
         ISNULL(s.b_level_ship_free_50,0),   ISNULL(s.b_level_ship_free_90,0),
         ISNULL(s.output_other_50,0),        ISNULL(s.output_other_90,0),
         ISNULL(s.output_code_change_50,0)+ISNULL(s.b_level_ship_paid_50,0)+ISNULL(s.b_level_ship_free_50,0)+ISNULL(s.output_other_50,0),
         ISNULL(s.output_code_change_90,0)+ISNULL(s.b_level_ship_paid_90,0)+ISNULL(s.b_level_ship_free_90,0)+ISNULL(s.output_other_90,0),
         -- LOSS (SCRAP)
         ISNULL(s.scrap_before_pfl,0), ISNULL(s.scrap_after_pfl,0),
         -- EOH (전/후)
         ISNULL(s.eoh_line_wip_pfl_50,0), ISNULL(s.eoh_line_wip_pfl_90,0),
         ISNULL(s.eoh_line_fgs_pfl_50,0), ISNULL(s.eoh_line_fgs_pfl_90,0),
         ISNULL(s.eoh_b_wip_pfl_50,0),    ISNULL(s.eoh_b_wip_pfl_90,0),
         ISNULL(s.eoh_b_fgs_pfl_50,0),    ISNULL(s.eoh_b_fgs_pfl_90,0),
         ISNULL(s.t_eoh_wip_pfl_50,0),    ISNULL(s.t_eoh_wip_pfl_90,0),
         ISNULL(s.eoh_line_fgs_pfl_50,0)+ISNULL(s.eoh_b_fgs_pfl_50,0),   -- T_EOH_FGS_전 (합산)
         ISNULL(s.eoh_line_fgs_pfl_90,0)+ISNULL(s.eoh_b_fgs_pfl_90,0),   -- T_EOH_FGS_후 (합산)
         ISNULL(s.t_eoh_mes_pfl_50,0),    ISNULL(s.t_eoh_mes_pfl_90,0),
         'IF_API', GETDATE()
    FROM DOI_VN_IF_WIP_SUBUL s
    WHERE s.SITE = @site AND s.SEL_CODE = @selCode
      AND s.mat_id IS NOT NULL AND LTRIM(RTRIM(s.mat_id)) <> ''
      AND LEFT(REPLACE(REPLACE(LTRIM(RTRIM(CONVERT(varchar(20), s.work_date))),'-',''),'/',''),6) = @yyyymm;

    SELECT @@ROWCOUNT;
END
GO

