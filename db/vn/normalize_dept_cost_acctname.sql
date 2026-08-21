/* ============================================================
   [VN 260821] doi_dept_cost.계정과목 정규화 (월 업로드 후 결산 전 실행)
   문제: 202607 업로드본의 계정과목이 코드접두형("6221100 - 직접 노무비...")
         + 엔대시(–, U+2013) 사용 → doi_vn_stco.acct_name(하이픈, clean)과
         브리지 실패 → 총원가 리포트 노무/제조경비가 거의 0.
   6월(202606)은 코드접두 없이 하이픈 순수명 → 정상 매칭.
   해법: (1) 전월 계정과목(계정코드 기준)으로 교체 (2) 잔여 엔대시→하이픈
         (3) 남은 코드접두 스트립.  실행 후 결산 재실행 필요.
   ★근본대책: 업로드 로더에서 계정과목 정규화(접두제거+대시통일) 권장.
   ============================================================ */
DECLARE @YYYYMM varchar(6) = '202607';
DECLARE @SITE   varchar(4) = 'VN';
DECLARE @PREV   varchar(6) = CONVERT(varchar(6), DATEADD(MONTH,-1,CAST(@YYYYMM+'01' AS date)), 112);

-- (선택) 백업
IF OBJECT_ID('doi_dept_cost_bak_acctname','U') IS NOT NULL DROP TABLE doi_dept_cost_bak_acctname;
SELECT * INTO doi_dept_cost_bak_acctname FROM doi_dept_cost WHERE yyyymm=@YYYYMM AND site=@SITE;

-- (1) 전월 계정과목(계정코드 1:1)으로 교체 — 전월 clean 포맷 계승
UPDATE d SET d.계정과목 = p.계정과목
FROM doi_dept_cost d
JOIN (SELECT 계정코드, MAX(계정과목) 계정과목 FROM doi_dept_cost WHERE yyyymm=@PREV AND site=@SITE GROUP BY 계정코드) p
  ON p.계정코드 = d.계정코드
WHERE d.yyyymm=@YYYYMM AND d.site=@SITE;

-- (2) 잔여 엔대시(U+2013)→하이픈 (전월에 없던 신규 계정코드 대상)
UPDATE doi_dept_cost SET 계정과목 = REPLACE(계정과목, NCHAR(8211), '-')
WHERE yyyymm=@YYYYMM AND site=@SITE AND 계정과목 LIKE '%'+NCHAR(8211)+'%';

-- (3) 남은 코드접두("계정코드 - ") 스트립
UPDATE doi_dept_cost SET 계정과목 = LTRIM(SUBSTRING(계정과목, LEN(계정코드)+4, LEN(계정과목)))
WHERE yyyymm=@YYYYMM AND site=@SITE AND 계정과목 LIKE 계정코드 + ' - %';

-- 검증: 코드접두/엔대시 잔존 0 이어야 함
SELECT SUM(CASE WHEN PATINDEX('[0-9][0-9][0-9][0-9][0-9][0-9][0-9] - %',계정과목)>0 THEN 1 ELSE 0 END) AS 접두잔존,
       SUM(CASE WHEN 계정과목 LIKE '%'+NCHAR(8211)+'%' THEN 1 ELSE 0 END) AS 엔대시잔존,
       COUNT(*) AS 전체
FROM doi_dept_cost WHERE yyyymm=@YYYYMM AND site=@SITE;
