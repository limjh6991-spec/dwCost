/* ============================================================
   doi_acct 202608 — 유실된 4개 컬럼 복원  ★결산/리포트 전 필수
   DB : 도우제조원가시스템 (10.100.40.17,14233)

   [증상]
     202608 doi_acct 는 API 경로(UP_HQ_IF_XFORM_ACCOUNT)로 626행이 적재됐는데,
     202607 과 공통인 209개 계정에서 아래 4개 컬럼이 전부 NULL 이 됐다.
       관리항목유형  209 -> 0
       disp_seq     200 -> 0
       원가구분       185 -> 0
       총원가_순서     179 -> 0
     expen_sel / 소분류 / 상위계정과목 / 대분류 / 중분류 등은 정상(209 -> 209).

   [영향]
     · 총원가_순서 — 표시용이 아니라 **필터 조건**이다.
       DOI_PL_ByModel 의 PL_SGNA : WHERE 대분류=N'판매관리비' AND 총원가_순서 IS NOT NULL
       실측: 판관비 세부 라인 202607 28개 -> 202608 0개.
       모델별 손익 화면(C0009000.xml EXEC DOI_PL_ByModel)과 총원가 화면
       (DOI_TotalCost_Tree, 같은 조건이 트리 정의부와 SGA_BASE 두 곳)에서
       판관비 세부 28행이 통째로 사라진다. LABOR_BASE 의 15+총원가_순서,
       EXP_BASE 의 22+b.총원가_순서 도 NULL 이 되어 노무비·경비 세부도 깨진다.
     · 원가구분 — DOI_FixedCostByModel / DOI_고정비_ByModel / DOI_변동비_ByModel
       이 읽는다. 고정비·변동비 분해가 성립하지 않는다.
     · disp_seq — UP_DOI_EXPEN_MATL 이 GROUP BY / PARTITION BY 에 쓴다.
       전 행 NULL 이라 그룹 경계는 바뀌지 않지만(ACCT_NAME 이 계정을 유일 식별),
       DOI_EXPEN_MATL.disp_seq 가 202608 만 전량 NULL 이 되어 결산증빙 화면의
       경비항목 표시순서가 무너진다.
     · 관리항목유형 — XFORM 적재용으로만 쓰여 실질 영향 없음(정합성 차원에서 함께 복원).

   [복원 근거]
     202607 과 공통인 209개 계정에서 expen_sel·소분류·상위계정과목·대분류·중분류·
     ACCT_CLASS·경영계획과목은 202607 과 완전히 동일하다. 즉 계정 마스터의 성격이
     바뀐 것이 아니라 적재 경로가 4개 컬럼을 채우지 않은 것이므로 전월 값 복사가 맞다.
     202608 신규 417행(현금·외상매출금 등 재무상태표 계정)은 202607 에 대응이 없고
     이 컬럼들을 쓰지 않으므로 NULL 로 남긴다.

   ※ 관리항목유형은 202608 신규 계정 19행이 이미 값을 갖고 있어 복원 후 228 (=209+19) 이 된다.

   [적용 완료] 2026-09-11 실행. UPDATE 209행, 202607 대비 4개 컬럼 값 불일치 0건,
              판관비 세부 라인 0 -> 28 복원 확인.

   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @n INT;
UPDATE b
   SET b.disp_seq     = a.disp_seq,
       b.원가구분      = a.원가구분,
       b.총원가_순서   = a.총원가_순서,
       b.관리항목유형   = a.관리항목유형
  FROM doi_acct b
  JOIN doi_acct a
    ON a.acct = b.acct AND a.site = b.site AND a.sel_code = b.sel_code
   AND a.yyyymm = '202607'
 WHERE b.yyyymm = '202608' AND b.site = 'HQ';
SET @n = @@ROWCOUNT;

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(2000) = N'';
DECLARE @ds INT = (SELECT COUNT(*) FROM doi_acct WHERE yyyymm='202608' AND site='HQ' AND disp_seq IS NOT NULL);
DECLARE @cg INT = (SELECT COUNT(*) FROM doi_acct WHERE yyyymm='202608' AND site='HQ' AND ISNULL(CAST(원가구분 AS NVARCHAR(100)),'')<>'');
DECLARE @to INT = (SELECT COUNT(*) FROM doi_acct WHERE yyyymm='202608' AND site='HQ' AND 총원가_순서 IS NOT NULL);
DECLARE @mg INT = (SELECT COUNT(*) FROM doi_acct WHERE yyyymm='202608' AND site='HQ' AND ISNULL(CAST(관리항목유형 AS NVARCHAR(100)),'')<>'');
DECLARE @sg INT = (SELECT COUNT(DISTINCT CAST(상위계정과목 AS NVARCHAR(100))+'|'+CAST(총원가_순서 AS NVARCHAR(10)))
                     FROM doi_acct WHERE yyyymm='202608' AND site='HQ'
                      AND 대분류=N'판매관리비' AND 총원가_순서 IS NOT NULL);
DECLARE @tot INT = (SELECT COUNT(*) FROM doi_acct WHERE yyyymm='202608' AND site='HQ');

IF @n  <> 209 BEGIN SET @ok=0; SET @msg=@msg+N'UPDATE 209행 기대, 실제 '+CAST(@n  AS NVARCHAR(10))+N'; '; END
IF @ds <> 200 BEGIN SET @ok=0; SET @msg=@msg+N'disp_seq 200 기대, 실제 '  +CAST(@ds AS NVARCHAR(10))+N'; '; END
IF @cg <> 185 BEGIN SET @ok=0; SET @msg=@msg+N'원가구분 185 기대, 실제 '  +CAST(@cg AS NVARCHAR(10))+N'; '; END
IF @to <> 179 BEGIN SET @ok=0; SET @msg=@msg+N'총원가_순서 179 기대, 실제 '+CAST(@to AS NVARCHAR(10))+N'; '; END
IF @mg <> 228 BEGIN SET @ok=0; SET @msg=@msg+N'관리항목유형 228 기대(복사 209 + 기존 19), 실제 '+CAST(@mg AS NVARCHAR(10))+N'; '; END
IF @sg <> 28  BEGIN SET @ok=0; SET @msg=@msg+N'판관비 세부 28라인 기대, 실제 '+CAST(@sg AS NVARCHAR(10))+N'; '; END
IF @tot<> 626 BEGIN SET @ok=0; SET @msg=@msg+N'행수 626 기대, 실제 '      +CAST(@tot AS NVARCHAR(10))+N'; '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'doi_acct 4개 컬럼 복원 완료' AS 결과, @n AS 변경행수,
         @ds AS disp_seq, @cg AS 원가구분, @to AS 총원가_순서, @mg AS 관리항목유형,
         @sg AS 판관비세부라인;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'검증 실패 - 원상복구' AS 결과, @msg AS 사유;
END
GO
