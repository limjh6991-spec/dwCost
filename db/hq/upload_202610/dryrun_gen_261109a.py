"""HQ 202610 드라이런 SQL 생성: 10월 생산수불 임시 적재 + 창고수불 수기칸 보정 + 현행/수정 결산 비교 (전부 롤백)"""
import sys
import openpyxl

sys.stdout.reconfigure(encoding="utf-8")
W = sys.argv[1]
DEFS = sys.argv[2]
XLS = "C:/dev/dwisCOST/docs/26.10월 정보/26.10월 정보/10월 재고수불부(261109).xlsx"
YM = "202610"

ws = openpyxl.load_workbook(XLS, data_only=True)["재고금액"]
hdr = [ws.cell(3, c).value for c in range(2, 24)]
assert hdr == ['모델', '기초', '입고', '출고', 'LOSS', '공정발생 불량', '불량판매', '타계정입고', 'CODE변경', '불량 R/W', '제품 R/W',
               '전월 불량(불량품 판매)', '당월 불량(불량품 판매)', '샘플', '기타', '타계정출고', 'CODE변경', '폐기', '샘플', '연구개발', '기타', '재고'], hdr
DBC = ["BOH_MONTH", "IN_MONTH", "OUT_MONTH", "LOSS_MONTH", "공정발생불량", "불량판매", "타계정입고", "기타입고_LOT변환", "기타입고_불량_RW",
       "기타입고_RMA_RW", "기타입고_전월불량", "기타입고_당월불량", "기타입고_샘플", "기타입고_기타", "타계정출고", "기타출고_LOT변환",
       "기타출고_폐기", "기타출고_샘플", "기타출고_연구개발", "기타출고_기타", "EOH_MONTH"]
rows = []
tot = None
for r in range(4, ws.max_row + 1):
    code = ws.cell(r, 2).value
    if not code:
        continue
    vals = [ws.cell(r, c).value or 0 for c in range(3, 24)]
    if code == "합계":
        tot = vals
        continue
    code = str(code).strip()
    m, k = code[:-1], code[-1]
    yang = k == "P" or m.endswith("P")
    rows.append((code, m, k, yang, vals))
assert tot is not None
for i in (0, 1, 2, 3, 20):
    assert abs(sum(x[4][i] for x in rows) - tot[i]) < 0.01, (DBC[i], tot[i])
print("생산수불 행", len(rows), "기초", tot[0], "입고", tot[1], "출고", tot[2], "LOSS", tot[3], "재고", tot[20])

cols = ["YYYYMM", "SEL_CODE", "SITE", "구분", "구분_ORD", "도우코드", "도우모델", "작업구분", "DW_Site"] + DBC + ["BOH_ADJ", "OUT_ADJ", "EOH_ADJ", "ADJ_YN", "material_loss"]
vals_sql = []
for code, m, k, yang, v in rows:
    vals_sql.append("(N'%s',N'ACTUAL',N'HQ',N'%s',N'%s',N'%s',N'%s',N'%s',N'본사',%s,%s,%s,%s,N'N',0)" % (
        YM, "양산" if yang else "개발", "1" if yang else "2", code, m, k, ",".join(str(x) for x in v), v[0], v[2], v[20]))

# ---- 창고수불(DOI_STOCK) 10월: API 적재분(세부칸 NULL·카세트 누락) → 엑셀 261109본으로 교체 ----
ws2 = openpyxl.load_workbook(XLS, data_only=True)["창고수불(202609)"]
def g(r, c):
    x = ws2.cell(r, c).value
    return x if isinstance(x, (int, float)) else 0
SCOL = [("BOH",13),("INPUT",14),("OUT",15),("EOH",16),("INPUT_ETC",18),("INPUT_MOVING",19),("INPUT_PROD",21),("OUT_SHEET",26),
        ("OUT_INVOICE",27),("OUT_ETC",28),("OUT_MOVING",30),("작업실적",31),("기타입고",33),("재고실사입고조정",34),("RMA_반품입고",35),
        ("RMA_반품출고",36),("공정재투입",37),("연구개발",38),("기술평가",39),("출하검사",40),("폐기",41),("재고실사출고조정",42),("기타",43)]
srows = []
for r in range(4, ws2.max_row + 1):
    cls = ws2.cell(r, 1).value
    if cls not in ("제품", "카세트제품"):
        continue
    pn = str(ws2.cell(r, 6).value).strip()
    model = pn if cls == "카세트제품" else str(ws2.cell(r, 5).value).strip()
    stock = str(ws2.cell(r, 11).value).strip()
    srows.append("(N'202610',N'ACTUAL',N'HQ',N'%s',N'%s',N'%s',%s,0,0)" % (model, pn, stock, ",".join(str(g(r, c)) for _, c in SCOL)))
print("창고수불 행", len(srows))
STOCK_DEL = "DELETE FROM DOI_STOCK WHERE yyyymm='202610' AND site='HQ' AND sel_code='ACTUAL'"
STOCK_INS = "INSERT INTO DOI_STOCK ([YYYYMM],[SEL_CODE],[SITE],[MODEL],[MODEL_TYPE],[STOCK],%s,[OUT_RETURN],[RMA_AMT]) VALUES %s" % (",".join(f"[{n}]" for n, _ in SCOL), ", ".join(srows))
STOCK_CHK = ("IF (SELECT COUNT(*) FROM DOI_STOCK WHERE yyyymm='202610' AND site='HQ') <> 110 OR (SELECT SUM(BOH) FROM DOI_STOCK WHERE yyyymm='202610' AND site='HQ') <> 164213 "
             "OR (SELECT SUM(OUT) FROM DOI_STOCK WHERE yyyymm='202610' AND site='HQ') <> 182940 OR (SELECT SUM(EOH) FROM DOI_STOCK WHERE yyyymm='202610' AND site='HQ') <> 83639 "
             "RAISERROR(N'창고수불 적재 검증 실패', 16, 1)")
load = [
    "IF EXISTS (SELECT 1 FROM DOI_PROD_SUBUL WHERE yyyymm='202610' AND site='HQ') RAISERROR(N'202610 생산수불이 이미 있음 — 드라이런 전제 재확인', 16, 1)",
    "INSERT INTO DOI_PROD_SUBUL (%s) VALUES\n%s" % (",".join(f"[{c}]" for c in cols), ",\n".join(vals_sql)),
    STOCK_DEL, STOCK_INS, STOCK_CHK,
    "SELECT model_type, stock, 공정재투입, 기타 FROM DOI_STOCK WHERE yyyymm='202610' AND site='HQ' AND (ISNULL(공정재투입,0)<>0 OR ISNULL(기타,0)<>0)",
    # 카세트 배부율: 10월 미적재 → 9월 값 임시 복사 (드라이런 전용)
    "IF NOT EXISTS (SELECT 1 FROM DOI_CST_RATE WHERE yyyymm='202610' AND site='HQ') BEGIN SELECT * INTO #cst FROM DOI_CST_RATE WHERE yyyymm='202609' AND site='HQ'; UPDATE #cst SET yyyymm='202610'; INSERT INTO DOI_CST_RATE SELECT * FROM #cst; END",
    "IF OBJECT_ID('tempdb..#res') IS NOT NULL DROP TABLE #res; CREATE TABLE #res (ph varchar(2), metric nvarchar(40), k nvarchar(80), v decimal(38,2))",
]

CHAIN = [
    "EXEC UP_DOI_EXPEN_MATL '202610','HQ','ACTUAL'",
    "EXEC UP_DOI_MAT_AMT '202610','HQ','ACTUAL'",
    "EXEC UP_DOI_MAT_COST '202610','HQ','ACTUAL'",
    "EXEC UP_DOI_COST '202610','HQ','ACTUAL'",
    "EXEC UP_DOI_STOCK_BOH '202610','HQ','ACTUAL'",
    "DECLARE @m nvarchar(max)=N''; EXEC UP_DOI_STOCK_COST @YYYYMM='202610', @SITE='HQ', @SEL_CODE='ACTUAL', @R_Message=@m OUTPUT",
    "EXEC UP_DOI_SALE_COST '202610','HQ','ACTUAL'",
]


def chain():
    out = []
    for c in CHAIN:
        out.append(c)
        out.append("IF @@TRANCOUNT = 0 RAISERROR(N'트랜잭션이 끊김 — 중단', 16, 1)")
    out.append("SELECT proc_name, exec_rslt FROM doi_execlog WHERE yyyymm='202610' AND site='HQ' AND exec_date >= DATEADD(MINUTE,-20,GETDATE()) ORDER BY exec_date")
    return out


def capture(ph):
    P = f"'{ph}'"
    return [f"""
INSERT INTO #res SELECT {P}, N'자재3종배부', 자재번호+N' / '+구분+N' '+도우모델, SUM(배부금액) FROM DOI_MAT_COST WHERE yyyymm='202610' AND site='HQ' AND 자재번호 IN ('DWD05821W0','DWD04821B1','DWD04821F1') AND ISNULL(배부금액,0)<>0 GROUP BY 자재번호, 구분, 도우모델;
INSERT INTO #res SELECT {P}, N'미배부자재', a.mat_code, SUM(a.in_amt) - ISNULL((SELECT SUM(배부금액) FROM DOI_MAT_COST c WHERE c.yyyymm='202610' AND c.site='HQ' AND c.자재번호=a.mat_code),0)
  FROM doi_mat_amt a WHERE a.yyyymm='202610' AND a.site='HQ' AND a.sel_code='ACTUAL' GROUP BY a.mat_code
  HAVING ABS(SUM(a.in_amt) - ISNULL((SELECT SUM(배부금액) FROM DOI_MAT_COST c WHERE c.yyyymm='202610' AND c.site='HQ' AND c.자재번호=a.mat_code),0)) > 1;
INSERT INTO #res SELECT {P}, N'음수배부', 구분+N' '+도우모델, SUM(배부금액) FROM DOI_MAT_COST WHERE yyyymm='202610' AND site='HQ' GROUP BY 구분, 도우모델 HAVING SUM(배부금액) < 0;
INSERT INTO #res SELECT {P}, N'자재환산량', 구분+N' '+도우모델, MIN(환산량) FROM DOI_MAT_COST WHERE yyyymm='202610' AND site='HQ' AND 도우모델 IN ('8176','8213','0295') GROUP BY 구분, 도우모델;
INSERT INTO #res SELECT {P}, N'재공R/W재투입', MODEL+N' qty', MAX(ETC_IN_RMA_QTY) FROM DOI_EXPEN_MATL WHERE yyyymm='202610' AND site='HQ' AND EXPEN_SEL='RMA1' GROUP BY MODEL;
INSERT INTO #res SELECT {P}, N'재공R/W재투입', MODEL+N' amt', SUM([in]) FROM DOI_EXPEN_MATL WHERE yyyymm='202610' AND site='HQ' AND EXPEN_SEL='RMA1' GROUP BY MODEL;
INSERT INTO #res SELECT {P}, N'재공', 구분+N' '+MODEL+N' '+x.c, x.v FROM (SELECT 구분, MODEL, SUM(BOH) boh, SUM([IN]) inn, SUM(ETC_IN_RMA_AMT) rma, SUM([OUT]) outa, SUM(EOH) eoh, SUM(ISNULL(LOSS,0)) loss
   FROM DOI_COST WHERE yyyymm='202610' AND site='HQ' AND MODEL IN ('8176','8213') GROUP BY 구분, MODEL) t
   CROSS APPLY (VALUES (N'기초',boh),(N'투입',inn),(N'R/W재투입',rma),(N'출고',outa),(N'기말',eoh),(N'LOSS',loss)) x(c,v);
INSERT INTO #res SELECT {P}, N'제품', 구분+N' '+MODEL+N' '+x.c, x.v FROM (SELECT 구분, MODEL, SUM(BOH_AMT) boh, SUM(IN_AMT) inn, SUM(OUT_REWORK_QTY) rq, SUM(OUT_REWORK_AMT) ra, SUM(OUTETC_AMT) oe, SUM(OUT_AMT) o, SUM(EOH_AMT) e
   FROM DOI_STCO WHERE yyyymm='202610' AND site='HQ' AND MODEL IN ('8176','8213') GROUP BY 구분, MODEL) t
   CROSS APPLY (VALUES (N'기초',boh),(N'입고',inn),(N'공정재투입qty',rq),(N'공정재투입amt',ra),(N'타계정',oe),(N'출고',o),(N'기말',e)) x(c,v);
INSERT INTO #res SELECT {P}, N'재공8176상세', x.c, x.v FROM (SELECT SUM(BOH_QTY) a1,SUM(IN_QTY) a2,SUM(EOH_QTY) a3,SUM(OUT_QTY) a4,SUM(LOSS_QTY) a5,SUM(ADJ_QTY) a6,SUM(ETC_IN_RMA_QTY) a7,
   SUM(BOH) b1,SUM([IN]) b2,SUM(ETC_IN_RMA_AMT) b3,SUM(EOH) b4,SUM([OUT]) b5,SUM(LOSS) b6,SUM(BAD) b7,SUM(TRANSFER) b8,SUM(RMAIN_AMT) b9,SUM(ADJ_BOH) b10,SUM(OUT_ETC) b11,SUM(LOSS_DEFECT_AMT) b12,SUM(LOSS_SALE_AMT) b13,
   SUM(ETC_IN_LOT_AMT) b14,SUM(ETC_IN_DEF_RW_AMT) b15,SUM(ETC_IN_PREV_DEF_AMT) b16,SUM(ETC_IN_CUR_DEF_AMT) b17,SUM(ETC_OUT_LOT_AMT) b18,SUM(ETC_OUT_ETC_AMT) b19,SUM(ETC_IN_ETC_AMT) b20, COUNT(*) n
   FROM DOI_COST WHERE yyyymm='202610' AND site='HQ' AND MODEL='8176' AND 구분=N'양산') t
   CROSS APPLY (VALUES (N'q기초',a1),(N'q입고',a2),(N'q기말',a3),(N'q출고',a4),(N'qLOSS',a5),(N'q환산(ADJ)',a6),(N'qRW',a7),(N'기초',b1),(N'IN',b2),(N'RW재투입',b3),(N'기말',b4),(N'출고',b5),(N'LOSS',b6),(N'BAD',b7),(N'TRANSFER',b8),(N'RMAIN',b9),(N'ADJ_BOH',b10),(N'OUT_ETC',b11),(N'LOSS_DEFECT',b12),(N'LOSS_SALE',b13),(N'ETC_IN_LOT',b14),(N'ETC_IN_DEF_RW',b15),(N'ETC_IN_PREV_DEF',b16),(N'ETC_IN_CUR_DEF',b17),(N'ETC_OUT_LOT',b18),(N'ETC_OUT_ETC',b19),(N'ETC_IN_ETC',b20),(N'행수',n)) x(c,v);
INSERT INTO #res SELECT {P}, N'재공대차불일치', 구분+N' '+MODEL, SUM(BOH)+SUM([IN])-SUM([OUT])-SUM(EOH)-SUM(ISNULL(LOSS,0))-SUM(ISNULL(OUT_ETC,0))
   FROM DOI_COST WHERE yyyymm='202610' AND site='HQ' GROUP BY 구분, MODEL HAVING ABS(SUM(BOH)+SUM([IN])-SUM([OUT])-SUM(EOH)-SUM(ISNULL(LOSS,0))-SUM(ISNULL(OUT_ETC,0))) > 10;
INSERT INTO #res SELECT {P}, N'재공8176_RMA1행', x.c, x.v FROM (SELECT SUM(BOH_QTY) a1, SUM(EOH_QTY) a2, SUM(ADJ_QTY) a3, SUM(UNIT_COST) a4, SUM(BOH) b1, SUM([IN]) b2, SUM(EOH) b3, SUM([OUT]) b4, SUM(LOSS) b5
   FROM DOI_COST WHERE yyyymm='202610' AND site='HQ' AND MODEL='8176' AND EXPEN_SEL='RMA1') t
   CROSS APPLY (VALUES (N'q기초',a1),(N'q기말',a2),(N'q환산',a3),(N'단가',a4),(N'기초',b1),(N'IN',b2),(N'기말',b3),(N'출고',b4),(N'LOSS',b5)) x(c,v);
INSERT INTO #res SELECT {P}, N'합계', x.c, x.v FROM (SELECT
   (SELECT SUM(in_amt) FROM doi_mat_amt WHERE yyyymm='202610' AND site='HQ' AND sel_code='ACTUAL') mat_in,
   (SELECT SUM(배부금액) FROM DOI_MAT_COST WHERE yyyymm='202610' AND site='HQ') mat_alloc,
   (SELECT SUM([IN]) FROM DOI_COST WHERE yyyymm='202610' AND site='HQ') wip_in,
   (SELECT SUM([OUT]) FROM DOI_COST WHERE yyyymm='202610' AND site='HQ') wip_out,
   (SELECT SUM(EOH) FROM DOI_COST WHERE yyyymm='202610' AND site='HQ') wip_eoh,
   (SELECT SUM(IN_AMT) FROM DOI_STCO WHERE yyyymm='202610' AND site='HQ') st_in,
   (SELECT SUM(EOH_AMT) FROM DOI_STCO WHERE yyyymm='202610' AND site='HQ') st_eoh,
   (SELECT SUM(OUT_AMT) FROM DOI_SLCO WHERE yyyymm='202610' AND site='HQ') slco) t
   CROSS APPLY (VALUES (N'자재투입',mat_in),(N'자재배부',mat_alloc),(N'재공투입',wip_in),(N'재공출고',wip_out),(N'재공기말',wip_eoh),(N'제품입고',st_in),(N'제품기말',st_eoh),(N'매출원가',slco)) x(c,v)"""]


def fixed(name, pairs):
    d = open(f"{DEFS}/{name}.sql", encoding="utf-8").read()
    import re
    d, n = re.subn(r"CREATE\s+PROCEDURE", "CREATE OR ALTER PROCEDURE", d, count=1, flags=re.I)
    assert n == 1
    for a, b in pairs:
        assert d.count(a) == 1, (name, a[:60], d.count(a))
        d = d.replace(a, b)
    return d


EXPEN_FIX = [(
    "ON r.MAT_CODE = q.MODEL + 'R'",
    "ON r.MAT_CODE = COALESCE((SELECT TOP 1 x.MAT_CODE FROM RMA_MATL x WHERE x.MAT_CODE IN (q.MODEL + 'R', q.MODEL + 'P') "
    "ORDER BY CASE RIGHT(x.MAT_CODE,1) WHEN 'R' THEN 0 ELSE 1 END), q.MODEL + 'R') /* [261109a] 양산 제품 R/W(8176P)도 ERP 투입행 매칭 */")]
MATCOST_FIX = [(
    "sum(a.IN_MONTH + a.OUT_MONTH + a.LOSS_MONTH + ISNULL(a.기타입고_RMA_RW,0))/ 2.0 as 환산량",
    "sum(a.IN_MONTH + a.OUT_MONTH + CASE WHEN ISNULL(a.LOSS_MONTH,0) > 0 THEN a.LOSS_MONTH ELSE 0 END + ISNULL(a.기타입고_RMA_RW,0))/ 2.0 as 환산량 /* [261109a] 불량 R/W 회수(LOSS<0)는 환산량에서 빼지 않음 */")]


import re as _re
def salecost_fixed():
    d = open(f"{DEFS}/UP_DOI_SALE_COST.sql", encoding="utf-8").read()
    d, n = _re.subn(r"CREATE\s+PROCEDURE", "CREATE OR ALTER PROCEDURE", d, count=1, flags=_re.I); assert n == 1
    d, n = _re.subn(r"insert into DOI_SLCO\s+SELECT YYYYMM, SITE, SEL_CODE, 구분, MODEL, '\*' Local구분",
                    "insert into DOI_SLCO (YYYYMM,SITE,SEL_CODE,구분,MODEL,Local구분,판매단위,거래처,EXPEN_SEL,EXPEN_SEL명,OUT_qty,OUT_AMT)  -- [261109a] 10/23 도우코드 칸 추가 대응\n\t\tSELECT YYYYMM, SITE, SEL_CODE, 구분, MODEL, '*' Local구분", d)
    assert n == 1, n
    d, n = _re.subn(r"INSERT INTO DOI_SMCE_COST\s+SELECT\s+YYYYMM,\s+@SEL_CODE AS sel_code",
                    "INSERT INTO DOI_SMCE_COST (YYYYMM,sel_code,SITE,구분,model,Local구분,판매단위,거래처,EXPEN_SEL명,SUB_NAME,ITEM_NAME,EXPEN_SEL,TOT_ACCT,SALE_AMT,TOT_AMT,TOT_SMCE,DIST_RATE,DIST_AMT,DIST_AMT_ORI)  -- [261109a] 10/23 도우코드 칸 추가 대응\n\t\tSELECT\n\t\t    YYYYMM,\n\t\t    @SEL_CODE AS sel_code", d)
    assert n == 1, n
    return d

stmts = load + [salecost_fixed()] + chain() + capture("A")
stmts.append(fixed("UP_DOI_EXPEN_MATL", EXPEN_FIX))
stmts.append(fixed("UP_DOI_MAT_COST", MATCOST_FIX))
stmts += chain() + capture("B")
stmts.append("""SELECT COALESCE(a.metric,b.metric) metric, COALESCE(a.k,b.k) k, a.v 현행, b.v 수정, ISNULL(b.v,0)-ISNULL(a.v,0) 차이
FROM (SELECT * FROM #res WHERE ph='A') a FULL JOIN (SELECT * FROM #res WHERE ph='B') b ON a.metric=b.metric AND a.k=b.k
ORDER BY 1, 2""")
open(f"{W}/dry.sql", "w", encoding="utf-8").write("\n--;\n".join(stmts))
open(f"{W}/fix_UP_DOI_EXPEN_MATL.sql", "w", encoding="utf-8").write(fixed("UP_DOI_EXPEN_MATL", EXPEN_FIX))
open(f"{W}/fix_UP_DOI_MAT_COST.sql", "w", encoding="utf-8").write(fixed("UP_DOI_MAT_COST", MATCOST_FIX))
open(f"{W}/fix_UP_DOI_SALE_COST.sql", "w", encoding="utf-8").write(salecost_fixed())
print("statements", len(stmts))
