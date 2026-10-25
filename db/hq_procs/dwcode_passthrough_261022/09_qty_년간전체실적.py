# -*- coding: utf-8 -*-
"""생산실적 년간전체실적 C0009001/TAB090003 = DOI_ManufacturingQtyByMonth 자사코드(도우모델)→도우코드 relabel.
   동적SQL 외부 SELECT: 도우모델→COALESCE(가드 도우코드,도우모델) + PIVOT 뒤 유일성가드 LEFT JOIN.
   모호(개발818V·양산VN034P)=도우모델 유지(무손실). throwaway 값보존 검증 → --apply 시 ALTER."""
import pyodbc, io, sys, os, re, datetime
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PROD="도우제조원가시스템"; BAK=r"C:\dev\dwCost\db\hq_procs\bak261023"
def conn(): return pyodbc.connect(f"DRIVER={{SQL Server}};SERVER=10.100.40.17,14233;DATABASE={PROD};UID=cost;PWD=Dowoo1234!",autocommit=True)
APPLY="--apply" in sys.argv; PROC="DOI_ManufacturingQtyByMonth"; ARGS="@YYYY='2026',@SITE='HQ'"
c=conn().cursor()
base=c.execute(f"SELECT OBJECT_DEFINITION(OBJECT_ID('{PROC}'))").fetchone()[0]

# EDIT1: 외부 SELECT의 도우모델(뒤에 Inch 오는 것=외부)만 COALESCE relabel
e1=re.subn(r'도우모델,(\s*\n\s*)Inch,', r'COALESCE(dw_lk.dwcode, 도우모델) AS 도우모델,\1Inch,', base, count=1)
if e1[1]!=1: print("★EDIT1 매칭 실패",e1[1]); sys.exit(1)
ed=e1[0]
# EDIT2: PIVOT 뒤 가드 LEFT JOIN 주입(ORDER BY 앞). @SQL 문자열 내부이므로 @YYYY는 proc 기존 패턴 사용.
JOIN=(" LEFT JOIN (SELECT 구분 AS lkg, 도우모델 AS lkm, CASE WHEN COUNT(DISTINCT 도우코드)=1 THEN MAX(도우코드) ELSE NULL END AS dwcode "
      "FROM doi_prod_subul WHERE YYYYMM LIKE '''+@YYYY+''' + ''%'' AND 도우코드 IS NOT NULL AND LEN(도우코드) > 0 "
      "GROUP BY 구분, 도우모델) dw_lk ON dw_lk.lkg = PivotTable.구분 AND dw_lk.lkm = PivotTable.도우모델")
e2=re.subn(r'(\)\s*AS\s*PivotTable)(\s*\n\s*ORDER BY)', r'\1'+JOIN.replace('\\','\\\\')+r'\2', ed, count=1)
if e2[1]!=1: print("★EDIT2 매칭 실패",e2[1]); sys.exit(1)
ed=e2[0]
print("편집 적용 OK, 도우코드 출현",ed.count('도우코드'),"| dw_lk",ed.count('dw_lk'))

def run(cur,proc):
    cur.execute(f"EXEC {proc} {ARGS}"); S=[]
    while True:
        if cur.description: S.append(([x[0] for x in cur.description],[list(r) for r in cur.fetchall()]))
        if not cur.nextset(): break
    S=[s for s in S if s[0]!=['ErrorMessage']]
    if not S:
        cur.execute(f"EXEC {proc} {ARGS}")
        return (['ErrorMessage'],[])  # 에러메시지
    S.sort(key=lambda s:len(s[0]),reverse=True); return S[0]
def inv(cols,rows):
    import collections
    s=0.0;n=0
    for r in rows:
        for v in r:
            if isinstance(v,(int,float)): s+=float(v);n+=1
    return (len(rows),round(s,2),n)
def models(cols,rows):
    i=cols.index('도우모델') if '도우모델' in cols else None
    if i is None: return []
    return sorted(set(str(r[i]) for r in rows))

bc,br=run(c,PROC); b=inv(bc,br)
print(f"BASE: 행수/숫자합/셀수={b}")
print("  BASE 도우모델 샘플:",[m for m in models(bc,br) if any(k in m for k in ('818','7073','0271','VN034','H81'))][:10])
ct=conn().cursor()
try:
    dep=re.sub(r'(CREATE\s+PROC(?:EDURE)?\s+)(\[?dbo\]?\.)?\[?'+PROC+r'\]?', r'\1[dbo].[DOI_QTY_DWCHK]', ed, count=1, flags=re.IGNORECASE)
    ct.execute("IF OBJECT_ID('dbo.DOI_QTY_DWCHK') IS NOT NULL DROP PROCEDURE dbo.DOI_QTY_DWCHK"); ct.execute(dep)
    ec,er=run(ct,'DOI_QTY_DWCHK')
    if ec==['ErrorMessage']:
        ct.execute("EXEC DOI_QTY_DWCHK @YYYY='2026',@SITE='HQ'");
        print("★ 실행에러:", ct.fetchone()[0][:300])
    else:
        e=inv(ec,er); same=e==b
        print(f"EDIT: 행수/숫자합/셀수={e}  {'✅값보존' if same else '★차이'}")
        print("  EDIT 자사코드(도우모델열) 샘플:",[m for m in models(ec,er) if any(k in m for k in ('818','7073','0271','VN034','H81'))][:12])
        if same and APPLY:
            open(os.path.join(BAK,f"{PROC}_bak{datetime.date.today():%y%m%d}.sql"),"w",encoding="utf-8").write(base)
            ddl=re.sub(r'CREATE\s+PROC(EDURE)?','ALTER PROCEDURE',ed,count=1,flags=re.IGNORECASE)
            c.execute(ddl); print("★ 라이브 ALTER OK (백업 저장)")
        elif same: print("값보존 확인(DRY). --apply 로 반영.")
finally:
    try: conn().cursor().execute("DROP PROCEDURE dbo.DOI_QTY_DWCHK")
    except: pass
