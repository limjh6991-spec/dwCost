"""
VINA 재공 수불 엑셀(6. DWV_CMS_WIP_FN_*.xlsx, 'WIP Inventory (CMS)') → DOI_VN_IF_WIP_SUBUL 스테이징 행.
MES API(/api/v1/wip_inv)에 닿지 않을 때 쓰는 대체 경로. 열 매핑은 202609 엑셀 ↔ API 적재분 54행 대조로 확정.

  검증: python -I scripts/auto_settle/vn_wip_excel.py verify <9월 엑셀>   (DB의 202609 API 스테이징과 필드별 대조)
"""
import os
import sys

import openpyxl

# 엑셀 열 번호(1부터) → API 필드. 열 7~10행이 머리글, 데이터는 11행부터(공장 칸에 값이 있는 행).
COLMAP = {
    4: "boh_a_wip_before_pfl_50", 5: "boh_a_wip_after_pfl_90", 6: "boh_a_fgs_before_pfl_50", 7: "boh_a_fgs_after_pfl_90",
    8: "boh_a_before_pfl_50", 9: "boh_a_after_pfl_90", 10: "boh_b_wip_before_pfl_50", 11: "boh_b_wip_after_pfl_90",
    12: "boh_b_fgs_before_pfl_50", 13: "boh_b_fgs_after_pfl_90", 14: "boh_b_before_pfl_50", 15: "boh_b_after_pfl_90",
    16: "t_boh_before_pfl_50", 17: "t_boh_after_pfl_90",
    18: "input_usc_cutting_qty",
    19: "change_code_qty", 20: "input_re_sorting_qty", 21: "input_rework_qty", 22: "wip_etc_input", 24: "total_input_to_line",
    25: "total_out_a_level",
    26: "output_code_change_50", 27: "output_code_change_90", 28: "b_level_ship_paid_50", 29: "b_level_ship_paid_90",
    30: "b_level_ship_free_50", 31: "b_level_ship_free_90", 32: "output_other_50", 33: "output_other_90",
    36: "scrap_before_pfl", 37: "scrap_after_pfl", 38: "scrap_total_qty",
    39: "eoh_line_wip_pfl_50", 40: "eoh_line_wip_pfl_90", 41: "eoh_line_fgs_pfl_50", 42: "eoh_line_fgs_pfl_90",
    43: "eoh_b_wip_pfl_50", 44: "eoh_b_wip_pfl_90", 45: "eoh_b_fgs_pfl_50", 46: "eoh_b_fgs_pfl_90",
    47: "t_eoh_wip_pfl_50", 48: "t_eoh_wip_pfl_90", 49: "t_eoh_b_pfl_50", 50: "t_eoh_b_pfl_90",
    51: "t_eoh_mes_pfl_50", 52: "t_eoh_mes_pfl_90",
}
# 변환 프로시저(UP_VN_IF_XFORM_WIP_SUBUL)가 읽는 필드 — 검증 대상
XFORM_FIELDS = list(COLMAP.values())


def num(v):
    if v is None or v == "":
        return 0
    if isinstance(v, (int, float)):
        return int(round(v))
    return int(round(float(str(v).replace(",", ""))))


def read_rows(path, work_date):
    ws = openpyxl.load_workbook(path, data_only=True).worksheets[0]
    out = []
    for r in range(11, ws.max_row + 1):
        fac, mat, grp = ws.cell(r, 1).value, ws.cell(r, 2).value, ws.cell(r, 3).value
        if not fac or not mat or str(fac).strip().upper() in ("TOTAL", "합계"):
            continue
        d = {"factory": str(fac).strip(), "mat_id": str(mat).strip(), "mat_grp_1": str(grp or "").strip(), "work_date": work_date}
        for c, f in COLMAP.items():
            d[f] = num(ws.cell(r, c).value)
        # 엑셀에 없는 합계 필드 (변환 프로시저는 쓰지 않음, 스테이징 일관성용)
        d["b_level_ship_paid"] = d["b_level_ship_paid_50"] + d["b_level_ship_paid_90"]
        d["b_level_ship_free"] = d["b_level_ship_free_50"] + d["b_level_ship_free_90"]
        d["b_level_ship_50"] = d["b_level_ship_paid_50"] + d["b_level_ship_free_50"]
        d["b_level_ship_90"] = d["b_level_ship_paid_90"] + d["b_level_ship_free_90"]
        d["total_out_b_level"] = d["b_level_ship_paid"] + d["b_level_ship_free"]
        d["total_output"] = d["total_out_a_level"] + d["total_out_b_level"]
        d["total_input"] = d["input_usc_cutting_qty"] + d["total_input_to_line"]
        out.append(d)
    return out


def verify(path):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import dbq
    import pymssql
    rows = {d["mat_id"]: d for d in read_rows(path, "20260930")}
    c = pymssql.connect(**dbq.load_conn("VN"))
    cur = c.cursor()
    cur.execute("SELECT * FROM DOI_VN_IF_WIP_SUBUL WHERE work_date='20260930'")
    cols = [x[0] for x in cur.description]
    api = {dict(zip(cols, t))["mat_id"].strip(): dict(zip(cols, t)) for t in cur.fetchall()}
    print("엑셀", len(rows), "API", len(api), "엑셀만", sorted(set(rows) - set(api)), "API만", sorted(set(api) - set(rows)))
    bad = 0
    for m in sorted(set(rows) & set(api)):
        for f in XFORM_FIELDS + ["mat_grp_1"]:
            a, b = rows[m][f], api[m][f] if f == "mat_grp_1" else (api[m][f] or 0)
            if (a.strip() if isinstance(a, str) else a) != (b.strip() if isinstance(b, str) else b):
                bad += 1
                if bad <= 20:
                    print("불일치", m, f, "엑셀", a, "API", b)
    print("필드 불일치", bad)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    if sys.argv[1] == "verify":
        verify(sys.argv[2])
