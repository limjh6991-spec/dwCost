# -*- coding: utf-8 -*-
"""
HQ 도우코드(완전품번) 표기 전환 — 남은 리포트 3종 coordinated 배포 (운영).
전략A(표시 relabel): GROUP BY/PIVOT 키·총액·행수 불변, 도우코드는 표시 라벨만.

대상(모두 리포트 SELECT 전용 — 재결산 불필요):
  1) DOI_TotalCost_Tree        (총원가, 화면 C0009010)   — dev 값보존 검증 완료
  2) DOI_AnnualReportBySale    (매출실적, 화면 C0009003)  — 운영 read-only tie-out 검증 완료
  3) DOI_ProdSubulMonthlyReport(수불월보, 화면 C0009001)  — 운영 값보존+무손실(가드) 검증 완료

제외:
  - DOI_ManufacturingQtyByMonth(생산수량): 동적 PIVOT+B급 모호성((개발,818V)→{818VD,818VT},
    VN034P→{1,3})로 대표라벨 시 행수 변동 → 전환불가, 도우모델 유지.
  - DOI_VariableCostByModel(변동비): 어떤 매퍼/화면에도 미연결(TotalCost 내 EXEC 주석) → 스킵.

프론트: 3종 모두 프론트 무변경(C0009010은 결과컬럼명서 그리드생성+getModelMetaFromField가
        구분접두 제거로 완전코드 수용 / C0009003·C0009001은 행기반, 별칭 유지).
        ※ PL 손익화면(C0009009)의 매출수량 매퍼 수정(품명→품번)은 별도(jar 재빌드 필요) — 본 스크립트 대상 아님.

실행:  python 05_deploy_remaining_reports.py            # DRY-RUN(검증만)
       python 05_deploy_remaining_reports.py --apply    # 운영 ALTER(백업 선행)
라이브-우선: 매 실행 시 운영 OBJECT_DEFINITION을 재수신해 old_string 유일성 재확인 후 적용.
"""
import pyodbc, io, sys, os, re, datetime
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PROD = "도우제조원가시스템"
BAK  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bak261023")
APPLY = "--apply" in sys.argv

def cur():
    return pyodbc.connect(
        f"DRIVER={{SQL Server}};SERVER=10.100.40.17,14233;DATABASE={PROD};UID=cost;PWD=Dowoo1234!",
        autocommit=True).cursor()

# ── 검증 완료된 단일행 편집(라이브 기준) ─────────────────────────────────────
EDITS = {
 "DOI_TotalCost_Tree": [
  ("            SELECT 구분, model, pivot_key, sort_group, sort_structure, sort_numeric FROM #MODEL",
   "            SELECT 구분, model, pivot_key, sort_group, sort_structure, sort_numeric, col_label = 구분 + COALESCE(NULLIF((SELECT MAX(sc.도우코드) FROM DOI_STCO sc WITH(NOLOCK) WHERE sc.YYYYMM=@YYYYMM AND sc.SITE=@SITE AND sc.SEL_CODE=@SELCODE AND sc.MODEL=#MODEL.model AND sc.구분=#MODEL.구분),N''), NULLIF((SELECT MAX(cc.도우코드) FROM DOI_COST cc WITH(NOLOCK) WHERE cc.YYYYMM=@YYYYMM AND cc.SITE=@SITE AND cc.SEL_CODE=@SELCODE AND cc.model=#MODEL.model AND cc.구분=#MODEL.구분),N''), model) FROM #MODEL"),
  ("                    N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0) AS ' + QUOTENAME(pivot_key)",
   "                    N'COALESCE(Cur.' + QUOTENAME(pivot_key) + N',0) AS ' + QUOTENAME(col_label)"),
 ],
 "DOI_AnnualReportBySale": [
  ("a.품명 as 도우코드,",
   "a.품명 as 도우코드, MAX(a.품번) as 도우코드완전,"),
  ("도우코드,구분,Inch,SET업체,고객코드,제품구조,",
   "COALESCE(NULLIF(MAX(도우코드완전), N''), 도우코드) as 도우코드,구분,Inch,SET업체,고객코드,제품구조,"),
 ],
 # 수불월보: 유일성 가드(비손실). 모호(COUNT DISTINCT>1, 예 개발818V)→NULL→COALESCE로 도우모델 폴백.
 "DOI_ProdSubulMonthlyReport": [
  ("                , MAX(DW_Site) AS DW_Site",
   "                , MAX(DW_Site) AS DW_Site\r\n                , CASE WHEN COUNT(DISTINCT 도우코드)=1 THEN MAX(도우코드) ELSE NULL END AS 도우코드"),
  ("\t\t        , cb.모델",
   "\t\t        , COALESCE(NULLIF(cb.도우코드, N''), cb.모델) AS 모델"),
 ],
}

def main():
    os.makedirs(BAK, exist_ok=True)
    c = cur()
    print(f"=== 남은 리포트 3종 도우코드 표기 {'운영 ALTER' if APPLY else 'DRY-RUN(검증만)'} ===\n")
    for proc, edits in EDITS.items():
        d = c.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", proc).fetchone()[0]
        if not d:
            print(f"[{proc}] ★운영에 객체 없음 — 중단"); continue
        ok = True; ed = d
        for old, new in edits:
            n = ed.count(old)
            if n != 1:
                ok = False; print(f"[{proc}] ★old_string count={n} (라이브 변경됨?): {old[:55]!r}")
            else:
                ed = ed.replace(old, new, 1)
        if not ok:
            print(f"[{proc}] → 유일성 실패, 이 프로시저 건너뜀(라이브 재확인 필요)\n"); continue
        print(f"[{proc}] 편집 {len(edits)}건 적용 OK · 도우코드 출현 {ed.count('도우코드')}")
        if APPLY:
            # 1) 라이브 백업
            bakfile = os.path.join(BAK, f"{proc}_bak{datetime.date.today():%y%m%d}.sql")
            open(bakfile, "w", encoding="utf-8").write(d)
            # 2) CREATE→ALTER
            ddl = re.sub(r'CREATE\s+PROC(EDURE)?', 'ALTER PROCEDURE', ed, count=1, flags=re.IGNORECASE)
            try:
                c.execute(ddl); print(f"         ALTER 운영 반영 OK (백업: {os.path.basename(bakfile)})")
            except Exception as ex:
                print(f"         ★ALTER 실패(원본유지): {str(ex)[:160]}")
        print()
    if not APPLY:
        print("DRY-RUN 완료. 실제 반영은 --apply 로 재실행.")

if __name__ == "__main__":
    main()
