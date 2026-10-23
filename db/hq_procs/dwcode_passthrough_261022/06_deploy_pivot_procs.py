# -*- coding: utf-8 -*-
"""동적피벗 3종 프로시저 도우코드 표기 ALTER (제조경비/원부자재/판관비).
   ★★반드시 신규 jar(C0009000.xml _Col 도우코드 반영)와 '동시' 배포할 것.
     proc만 ALTER+구jar → 헤더(_Col 도우모델) vs 산출열(도우코드) 불일치 → 열 공란.
     jar만 배포+구proc → 반대 불일치. 둘을 같은 유지보수 창에서 함께 적용해야 열이 매칭됨.

   대상(전부 동적 PIVOT, @Columns=IN-list(구분+도우모델) 불변, 출력 별칭만 구분+도우코드로 relabel):
     DOI_ManufacturingExpenseByModel (제조경비 C0009005)
     DOI_DsitributeMatCostByModel   (원부자재배부표 C0009006)
     DOI_SalesAdminByModel          (판매관리비 C0009008)
   값보존: throwaway 검증 완료(행수·숫자합 before=after, 열매칭 proc출력=_Col). 본 스크립트도 ALTER 전후 재검증.

   실행:  python 06_deploy_pivot_procs.py          # DRY-RUN
          python 06_deploy_pivot_procs.py --apply   # 운영 ALTER(+백업)
"""
import pyodbc, io, sys, os, re, json, datetime
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PROD="도우제조원가시스템"; HERE=os.path.dirname(os.path.abspath(__file__))
BAK=os.path.join(HERE,"..","bak261023")
EDITS=json.load(open(os.path.join(HERE,"06_pivot_proc_edits.json"),encoding='utf-8'))
APPLY="--apply" in sys.argv
ARGS="@YYYYMM='202609',@SITE='HQ',@SEL_CODE='ACTUAL'"
def conn(): return pyodbc.connect(f"DRIVER={{SQL Server}};SERVER=10.100.40.17,14233;DATABASE={PROD};UID=cost;PWD=Dowoo1234!",autocommit=True)

def run(cur,proc):
    cur.execute(f"EXEC {proc} {ARGS}"); S=[]
    while True:
        if cur.description: S.append(([x[0] for x in cur.description],[list(r) for r in cur.fetchall()]))
        if not cur.nextset(): break
    S=[s for s in S if s[0]!=['ErrorMessage']]
    S.sort(key=lambda s:len(s[0]),reverse=True); return S[0]
def inv(cols,rows):
    s=0.0;n=0
    for r in rows:
        for v in r:
            if isinstance(v,(int,float)): s+=float(v);n+=1
    return (len(rows),round(s,2),n)

c=conn().cursor()
os.makedirs(BAK,exist_ok=True)
print(f"=== 동적피벗 3종 proc {'운영 ALTER' if APPLY else 'DRY-RUN'} ===")
print("⚠️ 신규 jar(dwisCOST-prod-261023-0617.jar 이후)와 동시 배포 필수\n")
for proc, edits in EDITS.items():
    base=c.execute(f"SELECT OBJECT_DEFINITION(OBJECT_ID('{proc}'))").fetchone()[0]
    if not base: print(f"[{proc}] ★없음"); continue
    nl="\r\n" if "\r\n" in base else "\n"
    ed=base; ok=True
    for e in edits:
        o=e['old'].replace("\n",nl); n_=e['new'].replace("\n",nl)
        if ed.count(o)!=1: print(f"[{proc}] ★유일성 실패 count={ed.count(o)} (라이브 변경됨) → 건너뜀"); ok=False; break
        ed=ed.replace(o,n_,1)
    if not ok: continue
    # before/after 값보존(throwaway)
    try: b=inv(*run(c,proc))
    except Exception as ex: print(f"[{proc}] ★BASE 실행실패 {str(ex)[:120]}"); continue
    tn=proc+"_DEPLOYCHK"
    dep=re.sub(r'(CREATE\s+PROC(?:EDURE)?\s+)(\[?dbo\]?\.)?\[?'+proc+r'\]?', rf'\1[dbo].[{tn}]', ed, count=1, flags=re.IGNORECASE)
    ct=conn().cursor()
    try:
        ct.execute(f"IF OBJECT_ID('dbo.{tn}') IS NOT NULL DROP PROCEDURE dbo.{tn}"); ct.execute(dep)
        e_=inv(*run(ct,tn))
    finally:
        try: conn().cursor().execute(f"DROP PROCEDURE dbo.{tn}")
        except: pass
    same = e_==b
    print(f"[{proc}] 값보존 BASE={b} EDIT={e_} {'✅' if same else '★차이'}")
    if APPLY and same:
        open(os.path.join(BAK,f"{proc}_bak{datetime.date.today():%y%m%d}.sql"),"w",encoding="utf-8").write(base)
        ddl=re.sub(r'CREATE\s+PROC(EDURE)?','ALTER PROCEDURE',ed,count=1,flags=re.IGNORECASE)
        try: c.execute(ddl); print(f"         ALTER 운영 반영 OK (백업 저장)")
        except Exception as ex: print(f"         ★ALTER 실패 {str(ex)[:140]}")
    elif APPLY:
        print("         ★값 차이로 ALTER 중단")
if not APPLY: print("\nDRY-RUN 완료. jar 배포와 함께 --apply 실행.")
