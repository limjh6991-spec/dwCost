#!/usr/bin/env python3
"""
VINA 월 결산자료(ERP·MES 엑셀) → DWCMSTEST 적재 — API 서버에 닿지 않을 때 쓰는 대체 경로.

  사용: python -I scripts/auto_settle/load_vn_month.py <YYYYMM> <자료폴더> [--commit]

  - --commit 이 없으면 끝에서 ROLLBACK 한다(건수·합계만 확인).
  - 대상: doi_dept_cost / DOI_VN_ETC_INOUT / DOI_VN_STOCK_DETAIL / DOI_VN_MAT_INPUT /
          doi_vn_stock_resc / doi_invoice_resc / DOI_VN_MATERIAL
  - 해당 월에 이미 행이 있으면 덮어쓰지 않고 멈춘다(API 적재분·수기 보정 보호).
  - doi_vn_prod_resc(재공 수불)가 먼저 적재돼 있어야 한다(division 기준).
"""

import datetime
import decimal
import glob
import os
import re
import sys
import warnings

import openpyxl
import pymssql

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dbq  # noqa: E402

warnings.filterwarnings("ignore")
EDIT_USER = "EXCEL_LOAD"
SEL = "ACTUAL"
SITE = "VN"
NUM_TYPES = {"decimal", "numeric", "float", "int", "bigint", "money", "real", "smallint"}


def find(folder, pattern):
    hits = glob.glob(os.path.join(folder, pattern))
    if len(hits) != 1:
        raise SystemExit(f"파일을 하나로 특정 못함: {pattern} → {hits}")
    return hits[0]


def table_cols(cur, table):
    cur.execute("SELECT c.name, ty.name FROM sys.columns c JOIN sys.types ty ON ty.user_type_id=c.user_type_id "
                "WHERE c.object_id=OBJECT_ID(%s) ORDER BY c.column_id", (table,))
    return dict(cur.fetchall())


def to_num(v):
    if v in (None, ""):
        return None
    try:
        return decimal.Decimal(str(v).replace(",", "").strip())
    except decimal.InvalidOperation:
        return None


def to_val(v, typ):
    if typ in NUM_TYPES:
        return to_num(v)
    if isinstance(v, (datetime.datetime, datetime.date)):
        return v.strftime("%Y%m%d")
    if v is None:
        return None
    return str(v).strip() or None


def insert(cur, table, rows):
    """rows: dict 목록(컬럼명 → 값)"""
    if not rows:
        return
    cols = list(rows[0])
    sql = f"INSERT INTO {table} ({','.join('[' + c + ']' for c in cols)}) VALUES ({','.join(['%s'] * len(cols))})"
    cur.executemany(sql, [tuple(r[c] for c in cols) for r in rows])


def sheet_rows(path, sheet=None, header_row=2):
    """(머리글, 데이터행 목록). TOTAL·중복 머리글·빈 행은 뺀다."""
    wb = openpyxl.load_workbook(path, data_only=True)
    ws = wb[sheet] if sheet else wb.worksheets[0]
    rows = ws.iter_rows(values_only=True)
    header = None
    out = []
    for i, r in enumerate(rows, 1):
        if i == header_row:
            header = list(r)
        elif i > header_row:
            if not any(v not in (None, "") for v in r):
                continue
            if list(r) == header or any(str(v).strip() == "TOTAL" for v in r if isinstance(v, str)):
                continue  # TOTAL 은 파일마다 칸이 다르다
            out.append(r)
    return header, out


def dept_cost_rows(path, ym, prev_names):
    h, data = sheet_rows(path, "코스트센터")
    ix = {n: h.index(n) for n in ("코스트센터", "코스트센터분류", "코스트센터유형", "계정코드", "계정과목", "비용구분", "차변금액", "대변금액", "집계제외", "구분")}
    out = []
    for r in data:
        code = str(r[ix["계정코드"]] or "").strip()
        if not code:
            continue
        name = prev_names.get(code)
        if name is None:  # 신규 계정: 코드접두 제거, 엔대시→하이픈 (normalize_dept_cost_acctname.sql 과 같은 규칙)
            name = re.sub(r"^\s*" + code + r"\s*-\s*", "", str(r[ix["계정과목"]] or "")).replace("–", "-").strip()
        out.append({"yyyymm": ym, "sel_code": SEL, "site": SITE,
                    "코스트센터": str(r[ix["코스트센터"]] or "").strip(), "코스트센터분류": str(r[ix["코스트센터분류"]] or "").strip(),
                    "코스트센터유형": str(r[ix["코스트센터유형"]] or "").strip(), "계정코드": code, "계정과목": name,
                    "비용구분": str(r[ix["비용구분"]] or "").strip(), "차변금액": to_num(r[ix["차변금액"]]) or 0, "대변금액": to_num(r[ix["대변금액"]]) or 0,
                    "제외여부": str(r[ix["집계제외"]] or "").strip(), "기타매출구분": str(r[ix["구분"]] or "").strip()})
    return out


def same_name_rows(cur, table, path, ym, rename=None):
    """머리글 이름이 컬럼명과 같은 표를 그대로 옮긴다."""
    cols = table_cols(cur, table)
    h, data = sheet_rows(path)
    rename = rename or {}
    pairs = [(i, rename.get(n, n)) for i, n in enumerate(h) if n and rename.get(n, n) in cols]
    out = []
    now = datetime.datetime.now()
    for r in data:
        row = {c: to_val(r[i], cols[c]) for i, c in pairs}
        row.update({"yyyymm": ym, "edit_user": EDIT_USER, "edit_date": now})
        out.append(row)
    return out


def stock_resc_rows(path, ym, division):
    ws = openpyxl.load_workbook(path, data_only=True).worksheets[0]
    n = lambda v: to_num(v) or decimal.Decimal(0)
    names = ["BOH", "IN_NORMAL_LAST", "IN_NORMAL_THIS", "IN_RW_BACKSHIP_SORT", "IN_RW_BACKSHIP_PFRW", "IN_RW_BACKSHIP_PLRW",
             "IN_RW_WHRET_SORT", "IN_RW_WHRET_PFRW", "IN_RW_WHRET_PLRW", "T_INPUT", "ETCIN_RMA", "ETCIN_SEMI_PAID", "ETCIN_SEMI_FREE",
             "ETCIN_ETC", "ETCIN_TOTAL", "OUT_SHIP_A_PAID", "OUT_SHIP_A_FREE", "OUT_SHIP_B", "T_OUTPUT", "ETCOUT_RESORT",
             "ETCOUT_REWORK", "ETCOUT_FREESALE", "ETCOUT_ETC", "ETCOUT_TOTAL", "LOSS", "EOH_WH0006"]
    out = []
    now = datetime.datetime.now()
    for r in ws.iter_rows(values_only=True):
        if r[2] not in ("MP", "R&D") or not r[1]:
            continue
        code = str(r[1]).strip()
        row = {"yyyymm": ym, "sel_code": SEL, "도우코드": code,
               "division": division.get(code) or ("MP" if code.endswith("P") else "R&D")}
        row.update({c: n(r[3 + i]) for i, c in enumerate(names)})
        row.update({"VERIFY": 0, "EDIT_USER": EDIT_USER, "EDIT_DT": now})
        out.append(row)
    return out


def invoice_rows(path, ym):
    """UP_VN_IF_XFORM_EXP_SALES 매핑을 엑셀 머리글로 옮긴 것."""
    h, data = sheet_rows(path)
    g = lambda r, n: r[h.index(n)] if n in h else None
    out = []
    for r in data:
        out.append({"yyyymm": ym, "sel_code": SEL, "site": SITE, "선택": 0, "출고처리": 1,
                    "사업단위": to_val(g(r, "사업단위"), ""), "Invoice_No": to_val(g(r, "Invoice No."), ""),
                    "Invoice관리번호": to_val(g(r, "매출번호"), ""), "Invoice_Date": to_val(g(r, "InvoiceDate"), ""),
                    "수출구분": to_val(g(r, "수출구분"), ""), "가격조건": to_val(g(r, "가격조건"), ""),
                    "부서": to_val(g(r, "부서"), ""), "담당자": to_val(g(r, "담당자"), ""), "Buyer": to_val(g(r, "Buyer"), ""),
                    "통화": to_val(g(r, "통화"), ""), "환율": to_num(g(r, "환율")), "품명": to_val(g(r, "품명"), ""),
                    "품번": to_val(g(r, "품번"), ""), "규격": to_val(g(r, "규격"), ""), "단위": to_val(g(r, "판매단위"), ""),
                    "판매기준가": to_num(g(r, "판매기준가")), "판매단가": to_num(g(r, "판매단가")), "수량": to_num(g(r, "수량")),
                    "판매금액": to_num(g(r, "판매금액")), "원화판매금액": to_num(g(r, "원화판매금액")), "매출금액계": to_num(g(r, "판매금액")),
                    "미매출금액": 0, "매출대상": 0, "진행상태": "완료", "매출진행상태": "완료"})
    return out


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    ym, folder = sys.argv[1], sys.argv[2]
    commit = "--commit" in sys.argv
    conn = pymssql.connect(autocommit=False, **dbq.load_conn("VN"))
    cur = conn.cursor()
    try:
        load_all(cur, ym, folder)
        if commit:
            conn.commit()
            print("### COMMIT")
        else:
            conn.rollback()
            print("### ROLLBACK (시험 실행)")
    finally:
        conn.close()


def load_all(cur, ym, folder):
    """열린 커서(트랜잭션)에 엑셀 7종을 적재한다. 커밋/롤백은 호출한 쪽이 한다."""
    prev = (datetime.date(int(ym[:4]), int(ym[4:]), 1) - datetime.timedelta(days=1)).strftime("%Y%m")
    if True:
        for t, w in (("doi_dept_cost", "yyyymm=%s AND site='VN'"), ("DOI_VN_ETC_INOUT", "yyyymm=%s"), ("DOI_VN_STOCK_DETAIL", "yyyymm=%s"),
                     ("DOI_VN_MAT_INPUT", "yyyymm=%s"), ("doi_vn_stock_resc", "yyyymm=%s"), ("doi_invoice_resc", "yyyymm=%s AND site='VN'"),
                     ("DOI_VN_MATERIAL", "yyyymm=%s")):
            cur.execute(f"SELECT COUNT(*) FROM {t} WHERE {w}", (ym,))
            if cur.fetchone()[0]:
                raise SystemExit(f"{t} 에 {ym} 행이 이미 있어 중단")
        cur.execute("SELECT 도우코드, MAX(division) FROM doi_vn_prod_resc WHERE yyyymm=%s AND sel_code=%s GROUP BY 도우코드", (ym, SEL))
        division = dict(cur.fetchall())
        if not division:
            raise SystemExit("재공 수불(doi_vn_prod_resc)이 없어 중단")
        cur.execute("SELECT 계정코드, MAX(계정과목) FROM doi_dept_cost WHERE yyyymm=%s AND site='VN' GROUP BY 계정코드", (prev,))
        names = {a.strip(): b for a, b in cur.fetchall()}

        loads = [
            ("doi_dept_cost", dept_cost_rows(find(folder, "2. *수익_비용조회*.xlsx"), ym, names)),
            ("DOI_VN_ETC_INOUT", same_name_rows(cur, "DOI_VN_ETC_INOUT", find(folder, "3. *기타입출고금액조회*.xlsx"), ym)),
            ("DOI_VN_STOCK_DETAIL", same_name_rows(cur, "DOI_VN_STOCK_DETAIL", find(folder, "3. *재고금액상세조회*.xlsx"), ym, {
                "재고수량(A)": "재고수량A", "결산 후 재고수량(B)": "결산후재고수량B", "차이수량(A-B)": "차이수량A_B",
                "재고금액(C)": "재고금액C", "결산 후 재고금액(D)": "결산후재고금액D", "차이금액(C-D)": "차이금액C_D"})),
            ("DOI_VN_MAT_INPUT", same_name_rows(cur, "DOI_VN_MAT_INPUT", find(folder, "10. *품목별투입조회*.xlsx"), ym)),
            ("doi_vn_stock_resc", stock_resc_rows(find(folder, "6. *FGS Inventory*.xlsx"), ym, division)),
            ("doi_invoice_resc", invoice_rows(find(folder, "4. *수출매출품목조회*.xlsx"), ym)),
        ]
        # 제품별 제조경비 집계표는 계정 이름으로 금액을 잇는다 → 같은 원가구간(622/627)에 같은 이름이 있으면 금액이 두 번 잡힌다
        seen = {}
        for r in loads[0][1]:
            if r["계정코드"][:3] in ("622", "627"):
                seen.setdefault(r["계정과목"], set()).add(r["계정코드"])
        for name, codes in seen.items():
            if len(codes) > 1:
                print(f"⚠ 계정명 중복: {name} {sorted(codes)} — 결산 전에 이름을 구분할 것")

        for t, rows in loads:
            insert(cur, t, rows)
            print(f"{t}: {len(rows)}행")

        # 자재 분류: 품목조회 파일은 제품 위주라 전월 자재를 이어받고, 신규 품번만 재고상세에서 추가
        cur.execute("SELECT c.name FROM sys.columns c WHERE c.object_id=OBJECT_ID('DOI_VN_MATERIAL') AND c.name NOT IN ('yyyymm','edit_user','edit_date') ORDER BY c.column_id")
        cols = ",".join("[" + r[0] + "]" for r in cur.fetchall())
        cur.execute(f"INSERT INTO DOI_VN_MATERIAL ({cols},yyyymm,edit_user,edit_date) SELECT {cols},%s,%s,GETDATE() FROM DOI_VN_MATERIAL WHERE yyyymm=%s", (ym, EDIT_USER, prev))
        cur.execute("""INSERT INTO DOI_VN_MATERIAL (자재번호, 자재명, 품목자산분류, 자재대분류, 자재중분류, 자재소분류, yyyymm, edit_user, edit_date)
                       SELECT s.품번, MAX(s.품명), MAX(s.품목자산분류), MAX(s.대분류), MAX(s.중분류), MAX(s.소분류), %s, %s, GETDATE()
                       FROM DOI_VN_STOCK_DETAIL s WHERE s.yyyymm=%s
                         AND NOT EXISTS (SELECT 1 FROM DOI_VN_MATERIAL m WHERE m.yyyymm=%s AND m.자재번호=s.품번) GROUP BY s.품번""", (ym, EDIT_USER, ym, ym))
        print(f"DOI_VN_MATERIAL 신규 품번: {cur.rowcount}행")
        for sql in ("SELECT COUNT(*), SUM(차변금액), SUM(대변금액) FROM doi_dept_cost WHERE yyyymm=%s AND site='VN'",
                    "SELECT COUNT(*), SUM(금액) FROM DOI_VN_ETC_INOUT WHERE yyyymm=%s",
                    "SELECT COUNT(*), SUM(투입금액) FROM DOI_VN_MAT_INPUT WHERE yyyymm=%s",
                    "SELECT COUNT(*), SUM(EOH_WH0006) FROM doi_vn_stock_resc WHERE yyyymm=%s",
                    "SELECT COUNT(*), SUM(원화판매금액) FROM doi_invoice_resc WHERE yyyymm=%s AND site='VN'",
                    "SELECT COUNT(*) FROM DOI_VN_MATERIAL WHERE yyyymm=%s"):
            cur.execute(sql, (ym,))
            print("  ", sql.split("FROM")[1].split("WHERE")[0].strip(), cur.fetchone())


if __name__ == "__main__":
    main()
