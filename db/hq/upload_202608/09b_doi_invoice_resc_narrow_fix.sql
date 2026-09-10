/* ============================================================================
   doi_invoice_resc 202608 — 전체 재적재(09_doi_invoice_resc.sql) 대신 쓰는 좁은 수정
   DB : 도우제조원가시스템 (10.100.40.17,14233)
   대상: yyyymm='202608' AND site='HQ' — 7행

   [배경]
   API(UP_HQ_IF_XFORM_EXP_INVOICE) 적재분은 수량/판매금액/원화판매금액이 엑셀과
   전부 일치하므로 결산 산출물(매출액·수량·판가·판관비 배부)에는 영향이 없다.
   다만 아래 컬럼이 엑셀/과거월 관행과 어긋나 결산증빙 화면(C0008012 매출명세)에
   잘못 표시된다. 그 컬럼만 제자리로 돌린다.

     (a) Invoice_No <-> Invoice관리번호 가 서로 뒤바뀜
         · 202507~202607 전월 관행: Invoice_No='DWE-260701-001'(하이픈), 관리번호='202607010001'(숫자12)
         · 원인: XFORM 이 s.InvoiceNo(=관리번호)를 Invoice_No 로,
                 s.InvoiceRefNo(=실 Invoice No)를 Invoice관리번호 로 매핑
     (b) 판매단가 = 0        (ERP CustPrice 가 0으로 내려옴)
     (c) 매출금액계 = NULL   (XFORM INSERT 컬럼목록에 아예 없음)
     (d) Invoice_Date = '20260820' (8자리) — 전월 관행은 '2026-08-20' (10자리)
     (e) 판매기준가/미매출금액/매출대상/선택/출고처리/가격조건/매출진행상태 = NULL

   [검증된 산식]  ※ 실행 전 SELECT 로 확인 완료, 엑셀 값과 7행 전부 일치
     판매단가   = ROUND(판매금액 / 수량, 2)
                  -> 93700.61 / 193921.05 / 104558.64 / 49.98 / 49.98 / 49.98 / 50.21
     매출금액계 = 판매금액   (202607 실적도 매출금액계 == 판매금액 로 일치)
                  -> 합계 140,151,067.37 (엑셀 합계와 동일)

   [안전장치]
   WHERE 의 Invoice_No NOT LIKE '%[^0-9]%' 는 "Invoice_No 가 전부 숫자" = 뒤바뀐 행만
   골라낸다. 전체 13개월 중 202608 7행에만 적중하며, 두 번 실행해도 재차 뒤바뀌지 않는다.

   실행: 검증 통과 시 COMMIT, 실패 시 ROLLBACK
   ============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

/* ---------- 수정 전 스냅샷 ---------- */
SELECT N'BEFORE' AS 시점, Invoice_No, Invoice관리번호, Invoice_Date, 품번, 수량,
       판매단가, 판매금액, 원화판매금액, 매출금액계
  FROM doi_invoice_resc
 WHERE yyyymm = '202608' AND site = 'HQ'
 ORDER BY Invoice_Date, 품번;

/* ---------- 좁은 수정 (7행) ----------
   T-SQL 의 단일 UPDATE 는 SET 우변을 모두 '수정 전' 값으로 평가하므로
   Invoice_No / Invoice관리번호 맞교환이 한 문장으로 안전하게 된다.          */
UPDATE doi_invoice_resc
   SET Invoice_No      = Invoice관리번호,          -- (a) 맞교환
       Invoice관리번호 = Invoice_No,
       Invoice_Date    = STUFF(STUFF(Invoice_Date, 5, 0, '-'), 8, 0, '-'),  -- (d) 20260820 -> 2026-08-20
       판매단가        = CAST(ROUND(판매금액 / NULLIF(수량, 0), 2) AS numeric(18,2)),  -- (b)
       매출금액계      = 판매금액,                  -- (c)
       판매기준가      = 0,                         -- (e) 이하 전월 관행값
       미매출금액      = 0,
       매출대상        = 0,
       선택            = 0,
       출고처리        = 1,
       가격조건        = 'FOB',
       매출진행상태    = N'완료'
 WHERE yyyymm  = '202608'
   AND site    = 'HQ'
   AND Invoice_No NOT LIKE '%[^0-9]%';   -- 뒤바뀐 행만. 정상 행(하이픈 포함)은 건드리지 않음

DECLARE @rows INT = @@ROWCOUNT;

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(2000) = N'';

IF @rows <> 7
    BEGIN SET @ok = 0; SET @msg = @msg + N'수정행수 7 기대, 실제 ' + CAST(@rows AS NVARCHAR(20)) + N'; '; END

-- Invoice_No 는 전부 하이픈 포함, 관리번호는 전부 숫자여야 한다
IF EXISTS (SELECT 1 FROM doi_invoice_resc
            WHERE yyyymm='202608' AND site='HQ'
              AND (Invoice_No NOT LIKE '%-%' OR Invoice관리번호 LIKE '%[^0-9]%'))
    BEGIN SET @ok = 0; SET @msg = @msg + N'Invoice_No/관리번호 형식 검증 실패; '; END

-- Invoice_Date 는 YYYY-MM-DD 10자리
IF EXISTS (SELECT 1 FROM doi_invoice_resc
            WHERE yyyymm='202608' AND site='HQ' AND LEN(Invoice_Date) <> 10)
    BEGIN SET @ok = 0; SET @msg = @msg + N'Invoice_Date 형식 검증 실패; '; END

-- 매출금액계 합계 = 엑셀 140,151,067.37
IF ABS(ISNULL((SELECT SUM(매출금액계) FROM doi_invoice_resc WHERE yyyymm='202608' AND site='HQ'),0)
       - 140151067.37) > 0.01
    BEGIN SET @ok = 0; SET @msg = @msg + N'매출금액계 합계 불일치; '; END

-- 불변식: 결산이 읽는 3개 값은 절대 변하면 안 된다
IF ISNULL((SELECT SUM(수량)         FROM doi_invoice_resc WHERE yyyymm='202608' AND site='HQ'),0) <> 14114
    BEGIN SET @ok = 0; SET @msg = @msg + N'수량 합계 변동(14114 기대); '; END
IF ABS(ISNULL((SELECT SUM(원화판매금액) FROM doi_invoice_resc WHERE yyyymm='202608' AND site='HQ'),0)
       - 1043787944) > 1
    BEGIN SET @ok = 0; SET @msg = @msg + N'원화판매금액 합계 변동(1043787944 기대); '; END
IF ABS(ISNULL((SELECT SUM(판매금액)  FROM doi_invoice_resc WHERE yyyymm='202608' AND site='HQ'),0)
       - 140151067.37) > 0.01
    BEGIN SET @ok = 0; SET @msg = @msg + N'판매금액 합계 변동; '; END

IF @ok = 1
BEGIN
    COMMIT;
    SELECT N'AFTER (커밋됨)' AS 시점, Invoice_No, Invoice관리번호, Invoice_Date, 품번, 수량,
           판매단가, 판매금액, 원화판매금액, 매출금액계
      FROM doi_invoice_resc
     WHERE yyyymm = '202608' AND site = 'HQ'
     ORDER BY Invoice_Date, 품번;
    SELECT N'doi_invoice_resc 202608 좁은수정 완료' AS 결과, @rows AS 수정행수;
END
ELSE
BEGIN
    ROLLBACK;
    SELECT N'검증 실패 — 원상복구(ROLLBACK)' AS 결과, @msg AS 사유;
END
GO

/* ============================================================================
   [재결산 필요 여부]  불필요.
   결산 프로시저(UP_DOI_SALE_COST / DOI_TotalCost_Tree / DOI_PL_ByModel /
   DOI_PL_ByModel_세목 / DOI_KYH_ByModel / DOI_TotalCost / DOI_AnnualReportBySale /
   DOI_AnnualReportBySite)는 doi_invoice_resc 에서
   YYYYMM, SITE, 품번, 품명, 수량, 원화판매금액, 단위, 수출구분, Buyer 만 읽는다.
   본 스크립트는 그 9개 컬럼을 일절 건드리지 않으므로 결산 결과는 불변이다.
   (2026-09-10 기준 202608 은 아직 결산 미실행·미마감 상태)

   [별도 조치 — 근본원인]
   dbo.UP_HQ_IF_XFORM_EXP_INVOICE 의 매핑을 다음과 같이 바로잡아야
   202609 이후 같은 문제가 재발하지 않는다.
     · s.InvoiceRefNo -> Invoice_No       (현재는 Invoice관리번호로 감)
     · s.InvoiceNo    -> Invoice관리번호  (현재는 Invoice_No로 감)
     · Invoice_Date   : STUFF 로 YYYY-MM-DD 정규화
     · 판매단가       : ERP CustPrice 가 0 이므로 ROUND(CurAmt/Qty, 2) 로 대체
     · 매출금액계     : INSERT 컬럼목록에 누락 — CurAmt 로 추가
   ============================================================================ */
