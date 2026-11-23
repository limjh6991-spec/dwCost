"""
VINA 202606~202608 수출매출(doi_invoice_resc) 재적재   [261123a]
요청: 장시문 프로 2026-11-20 「RE: DWV 2026년도 10월 CMS 결산관련 자료 송부의 件」 — 제품별 손익계산서·총원가 6~8월 미표기
원인: 6~8월 doi_invoice_resc(site='VN') 0행. 판관비 배부(DOI_SMCE_COST)의 기준매출은 6~8월 엑셀 합계와 같아
      결산 당시에는 있었으나, 이후 수출매출 API 변환(UP_VN_IF_XFORM_EXP_SALES — 해당 월 DELETE 후 스테이징 INSERT)이
      빈 스테이징으로 다시 돌면서 지워진 것으로 보임. 제품별 손익계산서(VN_PL_ByModel·_Detail)·총원가(VN_TotalCost_Tree)는
      모델 목록을 수출매출에서 만들기 때문에 빈 화면이 됨.
조치: 결산 때 받은 엑셀 「4. 수출매출품목조회」를 load_vn_month.invoice_rows 로 다시 넣는다(해당 월 VN 행이 0일 때만).
      결산 결과 테이블은 바꾸지 않음(판관비 배부 기준매출과 같은 자료라 재실행 불필요).
드라이런(2026-11-23, 롤백): 6월 119행 14,148,059.87(배부 기준 14,148,060.00, 반올림 차 0.13) / 7월 97행 14,790,874.02 일치 /
      8월 47행 10,749,447.16 일치. 세 화면 모두 9·10월과 같은 행수(21·38·98).

  사용: python -I db/vn/reload_invoice_202606_08_261123a.py <8월 엑셀 경로> [--commit]
"""
import os
import sys

import pymssql

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "scripts", "auto_settle"))
import dbq  # noqa: E402
import load_vn_month as L  # noqa: E402

DOCS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    commit = "--commit" in sys.argv
    src = {
        "202606": os.path.join(DOCS, "26.06월 정보", "새로받은자료", "4. DWVN_수출매출품목조회_20260716.xlsx"),
        "202607": os.path.join(DOCS, "DWVN 2026년도 7월 CMS 결산 업로드자료", "4. DWVN_수출매출품목조회_20260819.xlsx"),
        "202608": sys.argv[1],
    }
    conn = pymssql.connect(autocommit=False, **dbq.load_conn("VN"))
    cur = conn.cursor()
    ok = True
    try:
        for ym, path in src.items():
            cur.execute("SELECT COUNT(*) FROM doi_invoice_resc WHERE yyyymm=%s AND site='VN'", (ym,))
            if cur.fetchone()[0]:
                raise SystemExit(f"{ym} 수출매출이 이미 있음 — 중단")
            rows = L.invoice_rows(path, ym)
            tot = round(sum(float(r["원화판매금액"] or 0) for r in rows), 2)
            cur.execute("SELECT MAX(TOT_AMT) FROM DOI_SMCE_COST WHERE yyyymm=%s AND site='VN' AND sel_code='ACTUAL'", (ym,))
            basis = float(cur.fetchone()[0] or 0)
            L.insert(cur, "doi_invoice_resc", rows)
            counts = []
            for p, arg in (("VN_PL_ByModel_Detail", "@SEL_CODE"), ("VN_PL_ByModel", "@SEL_CODE"), ("VN_TotalCost_Tree", "@SELCODE")):
                cur.execute(f"EXEC {p} @YYYYMM=%s, @SITE='VN', {arg}='ACTUAL'", (ym,))
                n = 0
                while True:
                    if cur.description:
                        n += len(cur.fetchall())
                    if not cur.nextset():
                        break
                counts.append(n)
            good = abs(tot - basis) < 1 and min(counts) > 3
            ok &= good
            print(f"{ym}: {len(rows)}행 {tot:,.2f} (배부 기준 {basis:,.2f}) 화면행수 {counts} {'OK' if good else '확인 필요'}")
        if ok and commit:
            conn.commit()
            print("### COMMIT")
        else:
            conn.rollback()
            print("### ROLLBACK", "(검증 실패)" if not ok else "(시험 실행)")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
