#!/usr/bin/env python3
"""
VINA 월 결산 — 엑셀 자료만으로 적재부터 결산 체인까지 한 트랜잭션에서 실행. --commit 이 없으면 끝에서 ROLLBACK.

  사용: python -I scripts/auto_settle/vn_month_run.py <YYYYMM> <자료폴더> [--commit]

  1) 재공 수불: 6. *CMS_WIP_FN*.xlsx → DOI_VN_IF_WIP_SUBUL(스테이징) → UP_VN_IF_XFORM_WIP_SUBUL → doi_vn_prod_resc
  2) 면적기준 정보: 기존 품목 스테이징(DOI_VN_IF_ITEM) → UP_VN_IF_XFORM_ITEM (등록일 ≤ 결산월)
  3) 엑셀 7종: load_vn_month.load_all (부서비용·기타입출고·재고상세·투입·제품수불·매출·자재)
  4) 결산 체인 14단계 (VINA 9월과 같은 순서)
  5) 결과 요약 + 대차 점검
"""
import os
import sys

import pymssql

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dbq  # noqa: E402
import load_vn_month  # noqa: E402
import vn_wip_excel  # noqa: E402

CHAIN = ["UP_VN_STOCK_ADJ", "UP_VN_MATL_RESC", "UP_VN_MAT_AMT", "UP_VN_ACCT_EXPEN", "UP_VN_EXPN_INPUT", "UP_VN_MAT_COST_NEW",
         "UP_VN_COST_BOH", "UP_VN_COST_UNIT", "UP_VN_STOCK_BOH_NEW", "UP_VN_RSRW", "UP_VN_WIP_EVAL_NEW", "UP_VN_STOCK_COST_NEW",
         "UP_VN_SALE_COST_NEW", "UP_VN_SMCE_COST_NEW"]


def q(cur, sql, args=None):
    cur.execute(sql, args or ())
    return cur.fetchall()


def drain(cur):
    while True:
        if cur.description:
            cur.fetchall()
        if not cur.nextset():
            break


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    ym, folder = sys.argv[1], sys.argv[2]
    commit = "--commit" in sys.argv
    wd = ym + {"01": "31", "02": "28", "03": "31", "04": "30", "05": "31", "06": "30", "07": "31", "08": "31", "09": "30",
               "10": "31", "11": "30", "12": "31"}[ym[4:]]
    conn = pymssql.connect(autocommit=False, **dbq.load_conn("VN"))
    cur = conn.cursor()
    try:
        if q(cur, "SELECT COUNT(*) FROM doi_vn_prod_resc WHERE yyyymm=%s", (ym,))[0][0]:
            raise SystemExit(f"doi_vn_prod_resc 에 {ym} 행이 이미 있어 중단")
        if q(cur, "SELECT COUNT(*) FROM DOI_VN_IF_WIP_SUBUL WHERE work_date=%s", (wd,))[0][0]:
            raise SystemExit(f"DOI_VN_IF_WIP_SUBUL 에 {wd} 행이 이미 있어 중단 (API 적재분 확인)")
        if q(cur, "SELECT COUNT(*) FROM DOI_CLOSING_MONTH WHERE yyyymm=%s AND site='VN' AND IS_CLOSED='Y'", (ym,))[0][0]:
            raise SystemExit(f"{ym} VN 마감 상태")

        # 1) 재공 수불
        rows = vn_wip_excel.read_rows(load_vn_month.find(folder, "6. *CMS_WIP_FN*.xlsx"), wd)
        fields = list(rows[0].keys())
        cols = ["SITE", "SEL_CODE", "LOAD_DTTM", "REQUEST_ID"] + fields
        sql = "INSERT INTO DOI_VN_IF_WIP_SUBUL (%s) VALUES (%s)" % (",".join(f"[{c}]" for c in cols), ",".join(["%s"] * len(cols)))
        for d in rows:
            cur.execute(sql, tuple(["VN", "ACTUAL", __import__("datetime").datetime.now(), f"EXCEL-WIP-{ym}"] + [d[f] for f in fields]))
        print(f"재공 스테이징: {len(rows)}행 (기초 {sum(d['t_boh_before_pfl_50'] + d['t_boh_after_pfl_90'] for d in rows):,} · "
              f"USC투입 {sum(d['input_usc_cutting_qty'] for d in rows):,} · A급 {sum(d['total_out_a_level'] for d in rows):,} · "
              f"LOSS {sum(d['scrap_total_qty'] for d in rows):,} · 기말 {sum(d['t_eoh_mes_pfl_50'] + d['t_eoh_mes_pfl_90'] for d in rows):,})")
        cur.execute("EXEC UP_VN_IF_XFORM_WIP_SUBUL %s, 'ACTUAL', 'VN'", (ym,))
        drain(cur)
        print("doi_vn_prod_resc:", q(cur, "SELECT COUNT(*), SUM(division='MP') FROM doi_vn_prod_resc WHERE yyyymm=%s" .replace("SUM(division='MP')", "SUM(CASE WHEN division='MP' THEN 1 ELSE 0 END)"), (ym,))[0])

        # 2) 면적기준 정보
        if not q(cur, "SELECT COUNT(*) FROM DOI_MODEL_MAST WHERE yyyymm=%s AND site='VN'", (ym,))[0][0]:
            cur.execute("EXEC UP_VN_IF_XFORM_ITEM %s, 'ACTUAL', 'VN'", (ym,))
            drain(cur)
        print("DOI_MODEL_MAST:", q(cur, "SELECT COUNT(*) FROM DOI_MODEL_MAST WHERE yyyymm=%s AND site='VN'", (ym,))[0][0], "건")
        miss = q(cur, """SELECT p.도우코드 FROM doi_vn_prod_resc p WHERE p.yyyymm=%s AND NOT EXISTS
                          (SELECT 1 FROM DOI_MODEL_MAST m WHERE m.yyyymm=%s AND m.site='VN' AND m.MODEL=p.도우코드 AND ISNULL(m.XY,0)>0)""", (ym, ym))
        print("  면적 없는 재공 모델:", [r[0] for r in miss])

        # 2-1) 계정·부서 마스터: 당월이 없으면 전월 복사 (1·8·9번 엑셀이 전월과 같을 때의 대체 — 결과는 엑셀 적재와 동일)
        prevm = q(cur, "SELECT FORMAT(DATEADD(MONTH,-1,CONVERT(date,%s+'01')),'yyyyMM')", (ym,))[0][0]
        for t in ("DOI_ACCT", "DOI_DEPT"):
            if not q(cur, f"SELECT COUNT(*) FROM {t} WHERE yyyymm=%s AND site='VN'", (ym,))[0][0]:
                cur.execute(f"SELECT * INTO #cp FROM {t} WHERE yyyymm=%s AND site='VN'; UPDATE #cp SET yyyymm=%s; INSERT INTO {t} SELECT * FROM #cp; DROP TABLE #cp;", (prevm, ym))
                print(f"{t}: 전월({prevm}) 복사 {q(cur, f'SELECT COUNT(*) FROM {t} WHERE yyyymm=%s AND site=%s', (ym, 'VN'))[0][0]}행")

        # 3) 엑셀 7종
        load_vn_month.load_all(cur, ym, folder)

        # 4) 결산 체인
        for p in CHAIN:
            cur.execute(f"EXEC {p} %s, 'VN', 'ACTUAL'", (ym,))
            drain(cur)
            if q(cur, "SELECT @@TRANCOUNT")[0][0] == 0:
                raise SystemExit(f"{p} 실행 중 트랜잭션이 끊김")
        for r in q(cur, "SELECT proc_name, exec_rslt FROM doi_execlog WHERE yyyymm=%s AND site='VN' AND exec_date >= DATEADD(MINUTE,-30,GETDATE()) ORDER BY exec_date", (ym,)):
            print("  ", r)

        # 5) 결과
        res = {
            "투입(doi_expn_matl)": "SELECT SUM(투입금액) FROM doi_expn_matl WHERE yyyymm=%s AND site='VN' AND sel_code='ACTUAL'",
            "재공 출고(OUTPUT_A)": "SELECT SUM(OUTPUT_A_AMT) FROM doi_vn_cost WHERE yyyymm=%s AND site='VN'",
            "재공 기말": "SELECT SUM(EOH_LINE_WIP_전_AMT+EOH_LINE_WIP_후_AMT+EOH_LINE_FGS_전_AMT+EOH_LINE_FGS_후_AMT+EOH_B_WIP_전_AMT+EOH_B_WIP_후_AMT+EOH_B_FGS_전_AMT+EOH_B_FGS_후_AMT) FROM doi_vn_cost WHERE yyyymm=%s AND site='VN'",
            "제품 입고": "SELECT SUM(T_INPUT_AMT) FROM doi_vn_stco WHERE yyyymm=%s",
            "매출원가(T_OUTPUT)": "SELECT SUM(T_OUTPUT_AMT) FROM doi_vn_stco WHERE yyyymm=%s",
            "제품 기말(WH0006)": "SELECT SUM(EOH_WH0006_AMT) FROM doi_vn_stco WHERE yyyymm=%s",
            "제품 기타출고": "SELECT SUM(ETCOUT_TOTAL_AMT) FROM doi_vn_stco WHERE yyyymm=%s",
            "제품 LOSS": "SELECT SUM(LOSS_AMT) FROM doi_vn_stco WHERE yyyymm=%s",
            "RMA 수량": "SELECT SUM(ETCIN_RMA) FROM doi_vn_stock_resc WHERE yyyymm=%s",
            "판관비 배부": "SELECT SUM(DIST_AMT) FROM doi_smce_cost WHERE yyyymm=%s AND site='VN'",
            "제품수불 VERIFY≠0 행": "SELECT COUNT(*) FROM doi_vn_stco WHERE yyyymm=%s AND ISNULL(VERIFY,0)<>0",
        }
        for k, s in res.items():
            print(f"  {k}: {q(cur, s, (ym,))[0][0]}")
        # 재공 수불 금액 대차 (모델별): 기초+투입+기타입고 = 출고+기타출고+LOSS+기말
        bal = q(cur, """SELECT 도우코드, SUM(BOH_LINE_WIP_전_AMT+BOH_LINE_WIP_후_AMT+BOH_LINE_FGS_전_AMT+BOH_LINE_FGS_후_AMT+BOH_B_WIP_전_AMT+BOH_B_WIP_후_AMT+BOH_B_FGS_전_AMT+BOH_B_FGS_후_AMT
                  +USC_INPUT_AMT+ETCIN_CODE_AMT+ETCIN_RESORT_AMT+ETCIN_REWORK_AMT+ETCIN_SEMI_AMT+ETCIN_ETC_AMT
                  -OUTPUT_A_AMT-ETCOUT_CODE_전_AMT-ETCOUT_CODE_후_AMT-ETCOUT_SEMI_PAID_전_AMT-ETCOUT_SEMI_PAID_후_AMT-ETCOUT_SEMI_FREE_전_AMT-ETCOUT_SEMI_FREE_후_AMT-ETCOUT_ETC_전_AMT-ETCOUT_ETC_후_AMT
                  -LOSS_전_AMT-LOSS_후_AMT
                  -(EOH_LINE_WIP_전_AMT+EOH_LINE_WIP_후_AMT+EOH_LINE_FGS_전_AMT+EOH_LINE_FGS_후_AMT+EOH_B_WIP_전_AMT+EOH_B_WIP_후_AMT+EOH_B_FGS_전_AMT+EOH_B_FGS_후_AMT)) d
                  FROM doi_vn_cost WHERE yyyymm=%s AND site='VN' GROUP BY 도우코드 HAVING ABS(SUM(BOH_LINE_WIP_전_AMT+BOH_LINE_WIP_후_AMT+BOH_LINE_FGS_전_AMT+BOH_LINE_FGS_후_AMT+BOH_B_WIP_전_AMT+BOH_B_WIP_후_AMT+BOH_B_FGS_전_AMT+BOH_B_FGS_후_AMT
                  +USC_INPUT_AMT+ETCIN_CODE_AMT+ETCIN_RESORT_AMT+ETCIN_REWORK_AMT+ETCIN_SEMI_AMT+ETCIN_ETC_AMT
                  -OUTPUT_A_AMT-ETCOUT_CODE_전_AMT-ETCOUT_CODE_후_AMT-ETCOUT_SEMI_PAID_전_AMT-ETCOUT_SEMI_PAID_후_AMT-ETCOUT_SEMI_FREE_전_AMT-ETCOUT_SEMI_FREE_후_AMT-ETCOUT_ETC_전_AMT-ETCOUT_ETC_후_AMT
                  -LOSS_전_AMT-LOSS_후_AMT
                  -(EOH_LINE_WIP_전_AMT+EOH_LINE_WIP_후_AMT+EOH_LINE_FGS_전_AMT+EOH_LINE_FGS_후_AMT+EOH_B_WIP_전_AMT+EOH_B_WIP_후_AMT+EOH_B_FGS_전_AMT+EOH_B_FGS_후_AMT))) > 0.01""", (ym,))
        print("  재공 금액 대차 불일치 모델:", bal)
        # 재공 기초 금액 = 전월 기말 금액
        prev = q(cur, "SELECT FORMAT(DATEADD(MONTH,-1,CONVERT(date,%s+'01')),'yyyyMM')", (ym,))[0][0]
        print("  재공 기초(당월) / 기말(전월):", q(cur, """SELECT (SELECT SUM(BOH_LINE_WIP_전_AMT+BOH_LINE_WIP_후_AMT+BOH_LINE_FGS_전_AMT+BOH_LINE_FGS_후_AMT+BOH_B_WIP_전_AMT+BOH_B_WIP_후_AMT+BOH_B_FGS_전_AMT+BOH_B_FGS_후_AMT) FROM doi_vn_cost WHERE yyyymm=%s AND site='VN'),
                  (SELECT SUM(EOH_LINE_WIP_전_AMT+EOH_LINE_WIP_후_AMT+EOH_LINE_FGS_전_AMT+EOH_LINE_FGS_후_AMT+EOH_B_WIP_전_AMT+EOH_B_WIP_후_AMT+EOH_B_FGS_전_AMT+EOH_B_FGS_후_AMT) FROM doi_vn_cost WHERE yyyymm=%s AND site='VN')""", (ym, prev))[0])
        print("  제품 기초(당월) / 기말(전월):", q(cur, "SELECT (SELECT SUM(BOH_AMT) FROM doi_vn_stco WHERE yyyymm=%s), (SELECT SUM(EOH_WH0006_AMT) FROM doi_vn_stco WHERE yyyymm=%s)", (ym, prev))[0])

        # 추가 점검: --sql <파일> ('--;' 줄로 문장 구분, @ym 은 결산월로 치환)
        if "--sql" in sys.argv:
            import re
            for stmt in re.split(r"(?m)^--;\s*$", open(sys.argv[sys.argv.index("--sql") + 1], encoding="utf-8").read()):
                if not stmt.strip():
                    continue
                cur.execute(stmt.replace("@ym", f"'{ym}'"))
                if cur.description:
                    print("  ##", [d[0] for d in cur.description])
                    for r in cur.fetchall()[:60]:
                        print("    ", r)
        if commit:
            conn.commit()
            print("### COMMIT")
        else:
            conn.rollback()
            print("### ROLLBACK (드라이런)")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
