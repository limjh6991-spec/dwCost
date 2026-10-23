# -*- coding: utf-8 -*-
"""결산증빙 매출원가 C0008010 = DOI_SaleCOGM 모델 표기 도우코드 relabel (proc-only, no jar).
   원천 DOI_SLCO.도우코드 유일성가드. throwaway 값보존 검증 → --apply 시 라이브 ALTER."""
import pyodbc, io, sys, os, re, datetime
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PROD="도우제조원가시스템"; BAK=r"C:\dev\dwCost\db\hq_procs\bak261023"
def conn(): return pyodbc.connect(f"DRIVER={{SQL Server}};SERVER=10.100.40.17,14233;DATABASE={PROD};UID=cost;PWD=Dowoo1234!",autocommit=True)
ARGS="@YYYY='2026',@SITE='HQ',@SEL_CODE='ACTUAL'"
APPLY="--apply" in sys.argv; PROC="DOI_SaleCOGM"
e1_old="            , M.모델\n            , M.Local구분"
e1_new="            , COALESCE(NULLIF(dw.ldwcode, N''), M.모델) AS 모델\n            , M.Local구분"
e2_old="        FROM #MODEL_BASE M\n        CROSS JOIN #GEN_YYYYMM G"
e2_new=("        FROM #MODEL_BASE M\n"
  "        LEFT JOIN (SELECT 구분 AS lgubun, MODEL AS lmodel, CASE WHEN COUNT(DISTINCT 도우코드)=1 THEN MAX(도우코드) ELSE NULL END AS ldwcode "
  "FROM DOI_SLCO WITH(NOLOCK) WHERE SUBSTRING(YYYYMM,1,4)=@YYYY AND SITE=@SITE AND SEL_CODE=@SEL_CODE AND 도우코드 IS NOT NULL AND 도우코드<>N'' "
  "GROUP BY 구분, MODEL) dw ON dw.lgubun=M.구분 AND dw.lmodel=M.모델\n"
  "        CROSS JOIN #GEN_YYYYMM G")
c=conn().cursor()
base=c.execute(f"SELECT OBJECT_DEFINITION(OBJECT_ID('{PROC}'))").fetchone()[0]
nl="\r\n" if "\r\n" in base else "\n"
ed=base
for o,n in [(e1_old,e1_new),(e2_old,e2_new)]:
    o2=o.replace("\n",nl); n2=n.replace("\n",nl)
    if ed.count(o2)!=1: print(f"★유일성 실패 count={ed.count(o2)}: {o2[:40]!r}"); sys.exit(1)
    ed=ed.replace(o2,n2,1)
print("편집적용 OK, 도우코드 출현",ed.count('도우코드'))
def run(cur,proc):
    cur.execute(f"EXEC {proc} {ARGS}"); S=[]
    while True:
        if cur.description: S.append(([x[0] for x in cur.description],[list(r) for r in cur.fetchall()]))
        if not cur.nextset(): break
    S=[s for s in S if s[0]!=['ErrorMessage']]; S.sort(key=lambda s:len(s[0]),reverse=True); return S[0]
def inv(c_,r_):
    s=0.0;n=0
    for r in r_:
        for v in r:
            if isinstance(v,(int,float)): s+=float(v);n+=1
    return (len(r_),round(s,2),n)
def labels(c_,r_):
    i=c_.index('모델') if '모델' in c_ else 1
    return sorted(set(str(r[i]) for r in r_ if any(k in str(r[i]) for k in ('818','8136','0271','H81'))))[:8]
bc,br=run(c,PROC); b=inv(bc,br)
print(f"BASE: {b}  라벨={labels(bc,br)[:6]}")
ct=conn().cursor()
try:
    dep=re.sub(r'(CREATE\s+PROC(?:EDURE)?\s+)(\[?dbo\]?\.)?\[?'+PROC+r'\]?', r'\1[dbo].[DOI_SaleCOGM_DWCHK]', ed, count=1, flags=re.IGNORECASE)
    ct.execute("IF OBJECT_ID('dbo.DOI_SaleCOGM_DWCHK') IS NOT NULL DROP PROCEDURE dbo.DOI_SaleCOGM_DWCHK"); ct.execute(dep)
    ec,er=run(ct,'DOI_SaleCOGM_DWCHK'); e=inv(ec,er); same=e==b
    print(f"EDIT: {e}  {'✅값보존' if same else '★차이'}  라벨={labels(ec,er)[:8]}")
    if same and APPLY:
        open(os.path.join(BAK,f"{PROC}_bak{datetime.date.today():%y%m%d}.sql"),"w",encoding="utf-8").write(base)
        ddl=re.sub(r'CREATE\s+PROC(EDURE)?','ALTER PROCEDURE',ed,count=1,flags=re.IGNORECASE)
        c.execute(ddl); print("★ 라이브 ALTER OK (백업 저장)")
    elif same: print("값보존 확인(DRY). --apply 로 반영.")
finally:
    try: conn().cursor().execute("DROP PROCEDURE dbo.DOI_SaleCOGM_DWCHK")
    except: pass
