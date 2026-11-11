#!/usr/bin/env python
# -*- coding: utf-8 -*-
r"""
================================================================================
 HQ 월결산 — 엑셀 기초자료 적재 + 결산체인  (운영 도우제조원가시스템 직접 실행)
================================================================================
 작성   : 2026-11-10 (202610 결산 기준)
 용도   : 인수인계. 매월 HQ 결산을 재현/실행하기 위한 단일 실행 스크립트.
 전제   : 반드시 같은 폴더의 README.md 를 먼저 읽을 것.

 [핵심 원칙]
  - 운영 DB 직접 쓰기. 각 적재는 "트랜잭션 → DELETE(월/사업장 한정) → INSERT →
    엑셀 TOTAL/항등식 검증 → 일치 시 commit, 불일치 시 rollback" 구조.
  - 결산 프로시저는 다른 개발자와 공유하는 라이브 개체. 실행만 하고 편집하지 않음
    (단 하나의 예외: UP_DOI_SALE_COST 도우코드 열 대응 ALTER — 아래 B-0 참고).
  - 월별로 바뀌는 항목(엑셀 열 위치·시트명·특이사항)은 각 함수 상단 ⚠️ 주석 참고.

 [실행]
    python -I hq_settlement.py --step base      # 기초 12종 적재
    python -I hq_settlement.py --step settle     # 결산체인 (기초 적재 후)
    python -I hq_settlement.py --step verify     # 검증만
    python -I hq_settlement.py --step all        # base → settle → verify
  (다운로드 엑셀은 신뢰 못 하는 외부 데이터 → python -I 로 실행 권장)

 [미포함 — 결산 후 별도 단계]
  - ★재고자산충당금(DOI_재고자산평가) : 결산 완료 후 담당자로부터 '충당금 내역'을 받으면
        그때 적재/업데이트해야 한다(결산 전에는 값이 확정되지 않음). README §5 참고.
        → PL '(4)재고금액평가손실' = 당월 차이합 − 전월 차이합 으로 자동 반영.
  - 마감(DOI_CLOSING_MONTH)           : 위 충당금까지 반영·검증 후 최종 승인 시. README §5 참고.
================================================================================
"""
import sys, io, os, glob, math, argparse, datetime
from decimal import Decimal, InvalidOperation

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
import pyodbc
import openpyxl

# ============================================================================
#  설정 — 월마다 수정
# ============================================================================
# DB 자격증명: 비밀번호는 파일에 쓰지 않는다(팀이 이미 공유). 실행 전 환경변수로 주입:
#   PowerShell :  $env:DWCOST_PWD = '...'
#   cmd        :  set DWCOST_PWD=...
#   bash       :  export DWCOST_PWD=...
_PWD = os.environ.get('DWCOST_PWD', '')
DSN = ('DRIVER={SQL Server};SERVER=10.100.40.17,14233;'
       'DATABASE=도우제조원가시스템;UID=cost;PWD=' + _PWD)
YYYYMM      = '202610'      # 결산 대상 월
PREV_YYYYMM = '202609'      # 직전 월 (CarryOver/이월 참조)
SITE        = 'HQ'
SEL         = 'ACTUAL'
XLSX_DIR    = r'C:\Users\USER\Downloads\26.10월 정보'   # 엑셀 원천 폴더

# MES 연계 (DOI_MODEL_MAST 면적 주입용) — 원가 인스턴스의 링크드 서버 'MES'(10.100.40.250)
MES_LINKED  = 'MES'                   # sys.servers 의 링크드 서버명
MES_DB      = '도우제조MES시스템DB'    # MES 쪽 DB명 (MES.[MES_DB].dbo.dw_product_mast)

# 엑셀 파일 glob (날짜 접미사가 매월 바뀌므로 패턴으로 찾음)
FILEPAT = {
    'deptcost'  : '*계정별비용*',
    'resc'      : '*재고수불부*',
    'sale'      : '*매출품목*',
    'dept'      : '*부서*코스트*',
    'scof'      : '*유상사급*',
    'bom'       : '*제품별공정별소요자재*',
    'etc'       : '*기타입출고*',
    'cassette'  : '*카세트*',
}

# ============================================================================
#  공통 유틸
# ============================================================================
def connect(autocommit=False):
    if not _PWD:
        raise RuntimeError("환경변수 DWCOST_PWD 가 설정되지 않았습니다. 실행 전 DB 비밀번호를 환경변수로 주입하세요 "
                           "(PowerShell: $env:DWCOST_PWD='...').")
    cn = pyodbc.connect(DSN, timeout=0, autocommit=autocommit)
    cn.cursor().fast_executemany = False   # 혼합정밀도 'loses precision' 회피
    return cn

def find_file(key):
    hits = [h for h in glob.glob(os.path.join(XLSX_DIR, FILEPAT[key]))
            if not os.path.basename(h).startswith('~$')]   # 엑셀 잠금파일 제외
    if not hits:
        raise FileNotFoundError(f"[{key}] 패턴 {FILEPAT[key]} 파일 없음 in {XLSX_DIR}")
    if len(hits) > 1:
        raise RuntimeError(f"[{key}] 패턴 {FILEPAT[key]} 가 여러 파일 매칭 — 전월 잔여/중복 의심, 확인 필요:\n  "
                           + "\n  ".join(hits))
    return hits[0]

def find_sheet(wb, *prefixes):
    """시트명에 YYYYMM 등이 섞여 매월 바뀌므로 접두어로 찾는다. 정확일치 우선(접두어 혼동 방지).
       ⚠️ 창고수불 시트는 (전월) 년월로 명명되는 함정 — 접두어 '창고수불' 로 매칭.
       ⚠️ '재고금액'(재공품수불) 과 '재고금액(YYYYMM)'(재고금액상세) 가 공존 → 정확일치 우선으로 구분."""
    for p in prefixes:                                  # 1) 정확일치
        if p in wb.sheetnames:
            return wb[p]
    for p in prefixes:                                  # 2) 접두어 일치
        for s in wb.sheetnames:
            if s.startswith(p):
                return wb[s]
    raise KeyError(f"시트 없음: {prefixes} / 보유 {wb.sheetnames}")

def num(v):
    try: return int(v)
    except (TypeError, ValueError): return 0

def fnum(v):
    try: return float(v)
    except (TypeError, ValueError): return None

def dec(v):
    if v is None or v == '': return None
    try: return Decimal(str(v))
    except (InvalidOperation, ValueError): return None

def tx_load(table, rows, insert_sql, verify_fn, scope_sql, scope_args):
    """DELETE(한정) → executemany INSERT → verify_fn(cs) True 면 commit."""
    cn = connect(autocommit=False)
    cs = cn.cursor(); cs.fast_executemany = False
    before = cs.execute(f"SELECT COUNT(*) FROM {table} WHERE {scope_sql}", *scope_args).fetchone()[0]
    cs.execute(f"DELETE FROM {table} WHERE {scope_sql}", *scope_args)
    if rows:
        cs.executemany(insert_sql, rows)
    ok, msg = verify_fn(cs)
    if ok:
        cn.commit(); print(f"  ✓ {table}: {len(rows)}행 COMMIT (기존 {before} 삭제) — {msg}")
    else:
        cn.rollback(); print(f"  ✗ {table}: ROLLBACK — {msg}")
    cn.close()
    return ok

# ============================================================================
#  A. 기초자료 적재 (12종)
#     ⚠️ 품목별투입조회 = HQ 미적재(VN 전용) → 스킵.
# ============================================================================

def load_dept_cost():
    """DOI_DEPT_COST ← 계정별비용조회 '코스트센터' 시트.
       ⚠️ API 적재분은 원천 ERP 코스트센터라 '재배부 확정본'이 아님 → 반드시 엑셀(결산담당자
          재배부본)로 적재. 열: 코스트센터(1)/분류(2)/유형(3)/계정코드(4)/계정과목(5)/비용구분(6)/
          차변(7)/대변(8)/집계제외(9). 제외여부 = 집계제외열 값 그대로(비면 NULL). 기타매출구분=NULL.
       검증: 차변/대변 적재합 == 엑셀 TOTAL행."""
    f = find_file('deptcost'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = find_sheet(wb, '코스트센터')
    rows = []; tot_dr = tot_cr = Decimal(0); ex_dr = ex_cr = Decimal(0)
    for r in ws.iter_rows(min_row=3, values_only=True):     # r1 title, r2 header, r3+ data(incl TOTAL)
        cc = str(r[0]).strip() if r[0] else ''
        if cc == '' or cc == 'TOTAL':
            if cc == 'TOTAL': ex_dr, ex_cr = (dec(r[6]) or Decimal(0)), (dec(r[7]) or Decimal(0))
            continue
        if not (r[3] and str(r[3]).strip()):               # 계정코드 없으면 스킵
            continue
        dr = dec(r[6]) or Decimal(0); cr = dec(r[7]) or Decimal(0)
        excl = '제외' if (r[8] and str(r[8]).strip() == '제외') else None   # 집계제외='제외'만 반영(그 외 NULL, 원본 기준)
        tot_dr += dr; tot_cr += cr
        rows.append((YYYYMM, SEL, SITE, cc, r[1], r[2], str(r[3]).strip(), r[4], r[5], dr, cr, excl, None))
    wb.close()
    assert tot_dr == ex_dr and tot_cr == ex_cr, f"엑셀 TOTAL 불일치 차변 {tot_dr}/{ex_dr} 대변 {tot_cr}/{ex_cr}"
    ins = ("INSERT INTO DOI_DEPT_COST (yyyymm,sel_code,site,코스트센터,코스트센터분류,코스트센터유형,"
           "계정코드,계정과목,비용구분,차변금액,대변금액,제외여부,기타매출구분) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)")
    def vf(cs):
        cs.execute("SELECT COUNT(*),SUM(차변금액),SUM(대변금액) FROM DOI_DEPT_COST WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL)
        n, d, c = cs.fetchone()
        okk = (n == len(rows) and dec(d) == tot_dr and dec(c) == tot_cr)
        return okk, f"차변 {d:,} 대변 {c:,}"
    print(f"[DEPT_COST] 엑셀 {len(rows)}행 차변 {tot_dr:,} 대변 {tot_cr:,} (TOTAL 대조 OK)")
    return tx_load('DOI_DEPT_COST', rows, ins, vf,
                   "YYYYMM=? AND SITE=? AND SEL_CODE=?", (YYYYMM, SITE, SEL))


def load_matl_resc():
    """DOI_MATL_RESC ← 재고수불부 '재고금액(YYYYMM)' 시트 (재고금액상세).
       DB 데이터열(4~44, 41개) 순서대로 엑셀 데이터열(0~40) 1:1 위치대응.
       타입은 DB 컬럼명 기반: 수량·단가→float(real), 금액·원가→Decimal(numeric), 그 외→문자열.
       ⚠️ 투입금액/수량은 재료비 배부 원천(UP_DOI_MAT_AMT/MAT_COST) → 정확해야 함.
       검증: 기초금액·입고금액 적재합 == 엑셀 TOTAL행(r3)."""
    cn0 = connect(autocommit=True)
    allcols = [r[0] for r in cn0.cursor().execute(
        "SELECT name FROM sys.columns WHERE object_id=OBJECT_ID('DOI_MATL_RESC') ORDER BY column_id").fetchall()]
    cn0.close()
    datacols = allcols[3:]
    assert len(datacols) == 41, f"DOI_MATL_RESC 데이터열 {len(datacols)} != 41 (스키마 변경? 확인)"
    def is_num(nm): return any(k in nm for k in ('수량', '금액', '원가', '단가'))
    def conv(nm, v):
        if v is None: return None
        if is_num(nm):
            if ('수량' in nm) or ('단가' in nm):
                return fnum(v)
            return dec(v)
        return str(v)
    f = find_file('resc'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = find_sheet(wb, '재고금액(', '재고금액상세')
    allr = list(ws.iter_rows(values_only=True))
    total = allr[2]                                    # r1 title, r2 header, r3 TOTAL, r4+ data
    ex = {datacols[i]: dec(total[i]) for i in range(41) if '금액' in datacols[i] and total[i] is not None}
    rows = []
    for r in allr[3:]:
        if r[0] is None or str(r[0]).strip() in ('', 'TOTAL'): continue
        rows.append(tuple([YYYYMM, SEL, SITE] + [conv(datacols[i], r[i] if i < len(r) else None) for i in range(41)]))
    wb.close()
    ins = (f"INSERT INTO DOI_MATL_RESC ({','.join('['+c+']' for c in allcols)}) "
           f"VALUES ({','.join(['?']*(3+41))})")
    def vf(cs):
        cs.execute("SELECT COUNT(*),SUM(기초금액),SUM(입고금액) FROM DOI_MATL_RESC WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL)
        n, b, i2 = cs.fetchone()
        okk = (n == len(rows) and dec(b) == ex.get('기초금액') and dec(i2) == ex.get('입고금액'))
        return okk, f"기초금액 {b:,} 입고금액 {i2:,} (엑셀 {ex.get('기초금액'):,}/{ex.get('입고금액'):,})"
    print(f"[MATL_RESC] 엑셀 {len(rows)}행")
    return tx_load('DOI_MATL_RESC', rows, ins, vf,
                   "YYYYMM=? AND SITE=? AND SEL_CODE=?", (YYYYMM, SITE, SEL))


def load_stock():
    """DOI_STOCK ← 재고수불부 '창고수불(...)' 시트 (제품/카세트제품 수불).
       ⚠️ 시트명이 (전월) 년월로 명명되는 함정 — find_sheet('창고수불') 로 매칭.
       ⚠️ API 적재분은 headline만 채우고 breakdown 전부 NULL → 엑셀로 전체 적재 필수.
       필터: 품목자산분류 IN ('제품','카세트제품').
       키  : 제품 MODEL←품명(5열) / 카세트제품 MODEL←품번(6열), MODEL_TYPE←품번(6열), STOCK←창고(11열).
       ★ 특이사항(공정재투입): 창고수불 '공정재투입'(37열)→ DOI_STOCK.공정재투입.
         (예: 202610 8176P 공정재투입 = 43 → 매출원가(제품) 화면 반영)
       검산: OUT(15열) = 거래명세표(26)+수출Invoice(27)+기타출고(28)."""
    C = dict(CLS=1, PNAME=5, PNO=6, STOCK=11, BOH=13, IN=14, OUT=15, EOH=16)
    # breakdown: DB컬럼 → 창고수불 1-based 열
    MAP = dict(INPUT_ETC=18, INPUT_MOVING=19, INPUT_PROD=21, OUT_SHEET=26, OUT_INVOICE=27,
               OUT_ETC=28, OUT_MOVING=30, 작업실적=31, 기타입고=33, 재고실사입고조정=34,
               RMA_반품입고=35, RMA_반품출고=36, 공정재투입=37, 연구개발=38, 기술평가=39,
               출하검사=40, 폐기=41, 재고실사출고조정=42, 기타=43)   # OUT_RETURN, RMA_AMT = 소스없음 → 0
    f = find_file('resc'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = find_sheet(wb, '창고수불')
    def g(r, i):
        v = r[i-1] if i-1 < len(r) else None
        return int(v) if v not in (None, '') else 0
    rows = []; tb = ti = to = te = 0
    o_sheet = o_inv = o_etc = o_mov = rw_sum = 0      # OUT 분해·공정재투입 누적(검산용)
    rma_qty = 0                                       # RMA 반품입고+출고 수량(RMA_AMT 하드코딩 0 경고용)
    flow_bad = []                                     # 행별 흐름항등식 BOH+IN-OUT=EOH 위반
    for r in ws.iter_rows(min_row=4, values_only=True):
        cls = str(r[C['CLS']-1]).strip() if r[C['CLS']-1] else ''
        if cls not in ('제품', '카세트제품'): continue
        pno = str(r[C['PNO']-1]).strip() if r[C['PNO']-1] else ''
        pname = str(r[C['PNAME']-1]).strip() if r[C['PNAME']-1] else ''
        stock = str(r[C['STOCK']-1]).strip() if r[C['STOCK']-1] else ''
        model = pno if cls == '카세트제품' else pname
        boh, inp, out, eoh = g(r, C['BOH']), g(r, C['IN']), g(r, C['OUT']), g(r, C['EOH'])
        bd = {k: g(r, c) for k, c in MAP.items()}
        tb += boh; ti += inp; to += out; te += eoh
        o_sheet += bd['OUT_SHEET']; o_inv += bd['OUT_INVOICE']; o_etc += bd['OUT_ETC']
        o_mov += bd['OUT_MOVING']; rw_sum += bd['공정재투입']
        rma_qty += abs(bd['RMA_반품입고']) + abs(bd['RMA_반품출고'])
        if boh + inp - out != eoh:
            flow_bad.append((model, stock, boh + inp - out - eoh))
        rows.append((YYYYMM, SEL, SITE, model, pno, stock, boh, inp, out, eoh,
                     bd['INPUT_ETC'], bd['INPUT_MOVING'], bd['INPUT_PROD'], bd['OUT_SHEET'], 0,
                     bd['OUT_INVOICE'], bd['OUT_ETC'], bd['OUT_MOVING'], 0, bd['작업실적'],
                     bd['기타입고'], bd['재고실사입고조정'], bd['RMA_반품입고'], bd['RMA_반품출고'],
                     bd['공정재투입'], bd['연구개발'], bd['기술평가'], bd['출하검사'], bd['폐기'],
                     bd['재고실사출고조정'], bd['기타']))
    wb.close()
    out_breakdown = o_sheet + o_inv + o_etc + o_mov           # OUT = 거래명세표+수출Invoice+기타출고+이동처리(출)
    cols = ("[YYYYMM],[SEL_CODE],[SITE],[MODEL],[MODEL_TYPE],[STOCK],[BOH],[INPUT],[OUT],[EOH],[INPUT_ETC],"
            "[INPUT_MOVING],[INPUT_PROD],[OUT_SHEET],[OUT_RETURN],[OUT_INVOICE],[OUT_ETC],[OUT_MOVING],[RMA_AMT],"
            "[작업실적],[기타입고],[재고실사입고조정],[RMA_반품입고],[RMA_반품출고],[공정재투입],[연구개발],[기술평가],"
            "[출하검사],[폐기],[재고실사출고조정],[기타]")
    ins = f"INSERT INTO DOI_STOCK ({cols}) VALUES ({','.join(['?']*31)})"
    def vf(cs):
        cs.execute("SELECT COUNT(*),SUM(BOH),SUM(INPUT),SUM(OUT),SUM(EOH),SUM(공정재투입) FROM DOI_STOCK WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL)
        n, b, i2, o, e, rw = cs.fetchone()
        okk = (n == len(rows) and b == tb and i2 == ti and o == to and e == te and rw == rw_sum
               and out_breakdown == to and tb + ti - to == te and len(flow_bad) == 0)
        return okk, (f"이월{b} 입고{i2} 출고{o} 재고{e} 공정재투입{rw} | OUT분해={out_breakdown}"
                     f"{'=OUT' if out_breakdown==to else '≠OUT!'} 흐름위반{len(flow_bad)}")
    print(f"[STOCK] 제품/카세트 {len(rows)}행  이월{tb} 입고{ti} 출고{to} 재고{te} 공정재투입{rw_sum}"
          f"  OUT분해 {out_breakdown}{'=OUT✓' if out_breakdown==to else '≠OUT⚠️'} 흐름위반 {len(flow_bad)} {flow_bad[:3]}")
    if rma_qty != 0:
        print(f"  ⚠️ RMA 반품수량 {rma_qty} > 0 인데 RMA_AMT 는 0 하드코딩(창고수불에 금액 소스 없음). "
              f"RMA 반품평가 금액 소스(별도 반품 엑셀 등)를 RMA_AMT 에 주입해야 함 — 담당자 확인.")
    return tx_load('DOI_STOCK', rows, ins, vf,
                   "YYYYMM=? AND SITE=? AND SEL_CODE=?", (YYYYMM, SITE, SEL))


def load_prod_subul():
    """DOI_PROD_SUBUL ← 재고수불부 '재고금액' 시트 재공품수불 R4~.
       도우코드=모델열(2), 작업구분=끝글자(P/D), 도우모델=코드[:-1], 구분=양산(P)/개발(D).
       ★ 열구조: 3기초 4입고 5출고 6LOSS 7공정발생불량 8불량판매 | 기타입고: 9타계정입고(롤업)
         10CODE변경 11불량R/W 12제품R/W 13전월불량 14당월불량 15샘플 16기타 |
         기타출고: 17타계정출고(롤업) 18CODE변경 19폐기 20샘플 21연구개발 22기타 | 23재고.
       ★ 특이사항(제품R/W): 제품R/W(12열) → 기타입고_RMA_RW. 환산량 산식에 가산.
         (예: 202610 8176P 제품R/W=43 → 제조원가(재공) 화면 반영)
       ★ 특이사항(불량품 R/W → 환산량 0): 8213D 처럼 OUT41 & LOSS-41 이면
         환산량=(IN+RMA_RW+OUT+LOSS)/2=0 이 됨. 공용자재는 생산출력 기반 배부라 정상 처리됨
         (해당 모델이 유일 소비처면 전액 배부. README '특이사항 2' 참고).
       검산 항등식(롤업): 기초+입고+타계정입고 = 출고+LOSS+타계정출고+재고.
       INSERT는 31컬럼(ADJ_YN 까지). 나머지 확장열은 이번 달 전부 0 → 미입력(NULL)."""
    f = find_file('resc'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = find_sheet(wb, '재고금액')  # 정확일치 '재고금액'(재공품수불). (재고금액상세는 '재고금액(YYYYMM)')
    # 시트 sanity: 헤더행(3행)에 재공품수불 기대 토큰이 있나 (오매칭 방지)
    hdr = next(ws.iter_rows(min_row=3, max_row=3, values_only=True))
    hdr_txt = ' '.join(str(c) for c in hdr if c)
    if not ('기초' in hdr_txt and '입고' in hdr_txt and 'LOSS' in hdr_txt.upper()):
        wb.close(); raise RuntimeError(f"재공품수불 시트 헤더 미확인(오매칭 의심): {hdr_txt[:80]}")
    rows = []; viol = []; tb = ti = to = tl = te = trw = 0
    drop_sum = 0   # 미매핑 개별버킷(불량R/W11·샘플15·기타16·폐기19·샘플출20·연구개발21) 합 — 0 이어야 함
    for r in ws.iter_rows(min_row=4, values_only=True):
        code = r[1]
        if code in (None, '') or not str(code).strip(): continue
        code = str(code).strip()
        if code in ('합계', '총계', '소계', 'TOTAL'): continue
        gb = code[-1]
        jg = '양산' if gb == 'P' else '개발'; ordv = '1' if gb == 'P' else '2'
        boh, inp, out, loss = num(r[2]), num(r[3]), num(r[4]), num(r[5])
        ngb, saleng = num(r[6]), num(r[7])
        etc_in, code_in, product_rw = num(r[8]), num(r[9]), num(r[11])   # 타계정입고(롤업), CODE변경, 제품R/W
        prev_ng, curr_ng = num(r[12]), num(r[13])
        etc_out, code_out, etc_out_etc = num(r[16]), num(r[17]), num(r[21])
        eoh = num(r[22])
        drop_sum += abs(num(r[10])) + abs(num(r[14])) + abs(num(r[15])) + abs(num(r[18])) + abs(num(r[19])) + abs(num(r[20]))
        lhs = boh + inp + etc_in; rhs = out + loss + etc_out + eoh
        if lhs != rhs: viol.append((code, lhs - rhs))
        tb += boh; ti += inp; to += out; tl += loss; te += eoh; trw += product_rw
        rows.append((YYYYMM, SEL, SITE, jg, ordv, code, code[:-1], gb, None, None, None, '본사',
                     boh, inp, out, loss, ngb, saleng, etc_in, code_in, product_rw, prev_ng, curr_ng,
                     etc_out, code_out, etc_out_etc, eoh, boh, out, eoh, 'N'))
    wb.close()
    # ⚠️ 미매핑 개별버킷(불량R/W·샘플·기타·폐기·연구개발)이 nonzero면 31컬럼 INSERT로는 상세가 소실됨 → 중단 유도
    if drop_sum != 0:
        print(f"  ⚠️ 미매핑 재공 개별버킷 합 {drop_sum} ≠ 0 — 상세 소실 위험. DOI_PROD_SUBUL 확장열 매핑 추가 필요(README §1-4).")
    cols = ("[YYYYMM],[SEL_CODE],[SITE],[구분],[구분_ORD],[도우코드],[도우모델],[작업구분],[org작업구분],[model],[inch],"
            "[DW_Site],[BOH_MONTH],[IN_MONTH],[OUT_MONTH],[LOSS_MONTH],[공정발생불량],[불량판매],[타계정입고],"
            "[기타입고_LOT변환],[기타입고_RMA_RW],[기타입고_전월불량],[기타입고_당월불량],[타계정출고],[기타출고_LOT변환],"
            "[기타출고_기타],[EOH_MONTH],[BOH_ADJ],[OUT_ADJ],[EOH_ADJ],[ADJ_YN]")
    ins = f"INSERT INTO DOI_PROD_SUBUL ({cols}) VALUES ({','.join(['?']*31)})"
    def vf(cs):
        cs.execute("SELECT COUNT(*),SUM(BOH_MONTH),SUM(IN_MONTH),SUM(OUT_MONTH),SUM(LOSS_MONTH),SUM(EOH_MONTH),SUM(기타입고_RMA_RW) FROM DOI_PROD_SUBUL WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL)
        n, b, i2, o, l, e, rw = cs.fetchone()
        okk = (n == len(rows) and int(b) == tb and i2 == ti and o == to and l == tl and int(e) == te
               and rw == trw and len(viol) == 0 and drop_sum == 0)
        return okk, f"기초{b} 입고{i2} 출고{o} LOSS{l} 재고{e} 제품R/W{rw} 항등식위반{len(viol)} 미매핑버킷{drop_sum}"
    print(f"[PROD_SUBUL] 재공 {len(rows)}행 제품R/W합={trw} 항등식위반 {len(viol)} {viol[:5]} 미매핑버킷 {drop_sum}")
    return tx_load('DOI_PROD_SUBUL', rows, ins, vf,
                   "YYYYMM=? AND SITE=? AND SEL_CODE=?", (YYYYMM, SITE, SEL))


def load_scof():
    """DOI_원장상계 ← 유상사급 모델별 상계 'N월' 시트.
       모델행: 구분=양산(P)/개발(D), 모델=도우코드(as-is), 원장사용량=FLOOR(출하기여×소요량).
       회계-조정 행: 구분='회계', 모델='회계-조정', 원장매칭/사용량=NULL.
       ⚠️ 회계-조정 금액이 월별로 크게 변동 가능(예: 202610 = -773,988,566) → 적재 시 값 표면화 + 임계 경고.
       검증: 적재 매출상계합 == 엑셀 TOTAL행(독립 대조)."""
    SCOF_WARN = 100_000_000   # 회계-조정 |금액| 이 이 값 초과면 경고(이상치 눈대조 유도)
    f = find_file('scof'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    # 'N월' 시트: 대상 월 숫자. (파일에 1~12월 시트 존재)
    mon = str(int(YYYYMM[4:6])) + '월'
    ws = wb[mon] if mon in wb.sheetnames else wb[wb.sheetnames[0]]
    rows = []; tot = 0; ex_total = None; acct_adj = None
    for r in ws.iter_rows(min_row=3, values_only=True):
        m = r[0]
        if m in (None, '') or not str(m).strip(): continue
        m = str(m).strip()
        sales = int(round(fnum(r[7]) or 0))
        if m.upper() == 'TOTAL':
            ex_total = sales                       # 엑셀 TOTAL행 — 독립 대조용
            continue
        if m == '회계-조정':
            acct_adj = sales
            rows.append((YYYYMM, SITE, SEL, '회계', m, None, None, None, None, None, None, sales))
        else:
            gb = '양산' if m.endswith('P') else '개발'
            soyo, baeyul, chulha, usage = fnum(r[2]), fnum(r[3]), fnum(r[4]), fnum(r[5])
            rows.append((YYYYMM, SITE, SEL, gb, m, (str(r[1]).strip() if r[1] else None),
                         (dec(soyo) if soyo is not None else None),
                         (int(baeyul) if baeyul is not None else None),
                         (int(chulha) if chulha is not None else None),
                         (int(math.floor(usage)) if usage is not None else None),
                         None, sales))
        tot += sales
    wb.close()
    print(f"[원장상계] {len(rows)}행 매출상계합={tot:,}  회계-조정={acct_adj:,}" if acct_adj is not None
          else f"[원장상계] {len(rows)}행 매출상계합={tot:,} (회계-조정 행 없음)")
    if acct_adj is not None and abs(acct_adj) > SCOF_WARN:
        print(f"  ⚠️ 회계-조정 이상치 |{acct_adj:,}| > {SCOF_WARN:,} — 담당자 확인(유상사급→매출액 반영).")
    if ex_total is not None and ex_total != tot:
        print(f"  ⚠️ 엑셀 TOTAL행({ex_total:,}) != 적재합({tot:,}) — 행 누락/중복 의심.")
    ins = ("INSERT INTO DOI_원장상계 (yyyymm,site,sel_code,구분,모델,원장매칭,소요량,배율,출하기여수량,"
           "원장사용량,원장단가,매출상계) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)")
    def vf(cs):
        cs.execute("SELECT COUNT(*),SUM(매출상계) FROM DOI_원장상계 WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL)
        n, s = cs.fetchone()
        okk = (n == len(rows) and int(s) == tot and (ex_total is None or ex_total == tot))
        return okk, f"매출상계합 {s:,} (엑셀 TOTAL {ex_total if ex_total is not None else 'N/A'})"
    return tx_load('DOI_원장상계', rows, ins, vf,
                   "YYYYMM=? AND SITE=? AND SEL_CODE=?", (YYYYMM, SITE, SEL))


def load_cst_rate():
    """DOI_CST_RATE (카세트 배부율) — 결산 구동 필수(UP_DOI_EXPEN_MATL STEP1이 0행이면 중단).
       ⚠️ 카세트 실적/노무비 없는 달에만 UTG=1.0/VINA_CST=0.0 단일행(이번 가정). DOI_VNCST_RATE 0행.
       ★ 카세트 실적이 있는 달엔 1.0/0.0 을 쓰면 '조용히 틀린 배부'가 됨 →
         카세트 창고 입출고가 감지되면 중단하고, '카세트팀 원가 배부' 엑셀로 UTG/VINA 비율을
         산정해 넣어야 한다(DOI_VNCST_RATE 포함, 담당자 확인). README §1-6 참고."""
    cn = connect(autocommit=False); cs = cn.cursor()
    # 카세트 실적 감지: 카세트 창고에 당월 입/출고가 있나
    cs.execute("""SELECT ISNULL(SUM(INPUT),0)+ISNULL(SUM(OUT),0) FROM DOI_STOCK
                  WHERE YYYYMM=? AND SITE=? AND STOCK LIKE '%카세트%'""", YYYYMM, SITE)
    cassette_move = cs.fetchone()[0] or 0
    if cassette_move != 0:
        cn.rollback(); cn.close()
        print(f"  ✗ DOI_CST_RATE: 카세트 창고 입출고 {cassette_move} 감지 — UTG=1.0 적용 금지. "
              f"'카세트팀 원가 배부' 엑셀로 UTG/VINA 비율 산정 후 DOI_CST_RATE/DOI_VNCST_RATE 수기 적재(README §1-6).")
        return False
    cs.execute("DELETE FROM DOI_CST_RATE WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL)
    cs.execute("INSERT INTO DOI_CST_RATE (YYYYMM,SEL_CODE,SITE,UTG,VINA_CST) VALUES (?,?,?,?,?)",
               YYYYMM, SEL, SITE, Decimal('1.0'), Decimal('0.0'))
    cn.commit(); cn.close()
    print("  ✓ DOI_CST_RATE: UTG=1.0 / VINA_CST=0.0 (카세트 실적 없음 확인)")
    return True


def replace_bom():
    """DOI_BOM_MAST ← 제품별공정별소요자재조회 Sheet1 R3~. 엑셀 col1~26 → DB 1:1(col27 무시).
       ⚠️ API 적재분은 (1) 소요량 정밀도 오류(0.1667 ↔ 원본 0.1666) (2) 신규모델 BOM 누락
          → 반드시 엑셀 전체 교체. 소요량/Loss율=numeric, 최초작성일/최종수정일=date.
       ★ HTG(H접두) 제품명 'H' 누락 교정: H818VT·H8075T 등은 제품명이 'H'를 뺀 값('818V'/'8075')으로 와서,
         배부 조인(UP_DOI_MAT_COST: BOM.제품명=생산 도우모델)이 H818VT→도우모델 '818V' 개발(=818VD)로
         오조인된다(H818V 누락). 제품번호가 'H'로 시작하고 제품명≠품목중분류(정확한 도우모델)면 제품명=품목중분류로 교정.
         (818VT 등 비H 특수모델은 미접촉 — 품목중분류가 도우모델이 아님)."""
    NUMCOL = {18, 19, 20}; DATECOL = {23, 25}
    def conv(cell, col):
        if cell is None: return None
        if col in NUMCOL: return dec(cell)
        if col in DATECOL:
            if isinstance(cell, (datetime.datetime, datetime.date)): return cell.strftime('%Y-%m-%d')
            s = str(cell).strip(); return s[:10] if len(s) >= 8 else None
        s = str(cell).strip(); return s if s != '' else None
    f = find_file('bom'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = wb['Sheet1']
    rows = []; htg_fix = 0
    for r in ws.iter_rows(min_row=3, values_only=True):
        if r[1] in (None, '') or not str(r[1]).strip(): continue
        vals = [YYYYMM, SITE] + [conv(r[c-1], c) for c in range(1, 27)]
        # vals: [2]제품명(col1) [3]제품번호(col2) [6]품목중분류(col5)
        pno = vals[3] or ''
        if pno.startswith('H') and vals[6] and vals[2] != vals[6]:
            vals[2] = vals[6]; htg_fix += 1          # HTG 제품명 'H' 누락 교정 → 품목중분류(정확한 도우모델)
        rows.append(tuple(vals))
    wb.close()
    if htg_fix: print(f"  · HTG 제품명 교정 {htg_fix}행 (H접두 제품명→품목중분류)")
    cols = ("[YYYYMM],[SITE],[제품명],[제품번호],[품목자산분류],[품목대분류],[품목중분류],[품목소분류],[공정차수],[공정],"
            "[공정품명],[공정품번호],[자재명],[자재번호],[자재자산분류],[자재대분류],[자재중분류],[자재소분류],[투입단위],"
            "[소요량],[내부Loss율],[외부Loss율],[조립위치],[특이사항],[최초작성일],[최초작성자],[최종수정일],[최종수정자]")
    ins = f"INSERT INTO DOI_BOM_MAST ({cols}) VALUES ({','.join(['?']*28)})"
    def vf(cs):
        cs.execute("SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE)
        n = cs.fetchone()[0]
        cs.execute("SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM=? AND SITE=? AND 소요량=0.1667", YYYYMM, SITE)
        bad = cs.fetchone()[0]
        return (n == len(rows) and bad == 0), f"{n}행 소요량0.1667={bad}(0이어야 정상)"
    print(f"[BOM] 엑셀 {len(rows)}행 전체교체")
    return tx_load('DOI_BOM_MAST', rows, ins, vf, "YYYYMM=? AND SITE=?", (YYYYMM, SITE))


def verify_preloaded():
    """DEPT / sale / invoice / ETC_INOUT 는 보통 이미 적재되어 있음(API/수동).
       엑셀과 대조해 불일치 시 경고만 출력(필요 시 담당자가 재적재 결정).
       DOI_DEPT 는 CarryOver가 생성하므로 코스트센터명/분류 엑셀 일치 확인."""
    cn = connect(autocommit=True); cs = cn.cursor()
    print("[검증] 사전 적재 테이블 vs 엑셀")
    # DOI_DEPT (코스트센터명/분류)
    f = find_file('dept'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = find_sheet(wb, '코스트센터')
    exc = {}
    for r in ws.iter_rows(min_row=3, values_only=True):
        if r[0] and str(r[0]).strip():
            exc[str(r[0]).strip()] = (str(r[1]).strip() if r[1] else None)
    wb.close()
    cs.execute("SELECT DEPT_NAME,EXPEN_AREA FROM DOI_DEPT WHERE YYYYMM=? AND SITE='HQ'", YYYYMM)
    db = {a: b for a, b in cs.fetchall()}
    mis = sum(1 for nm, cls in exc.items() if db.get(nm) != cls)
    print(f"  DOI_DEPT: {len(db)}행, 엑셀 코스트센터분류 불일치 {mis}  {'OK' if mis==0 else '⚠️ 재적재 검토'}")
    # ETC_INOUT: 엑셀 행레벨 금액합(TOTAL셀 아님, col16) vs DB (프로그램 대조)
    f = find_file('etc'); wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    ws = wb['Sheet1']; etc_ex = 0
    for r in ws.iter_rows(min_row=4, values_only=True):
        if r[3] in (None, '') or str(r[3]).strip() == 'TOTAL' or r[10] in (None, ''): continue
        etc_ex += fnum(r[15]) or 0
    wb.close()
    cs.execute("SELECT COUNT(*),SUM(금액) FROM DOI_ETC_INOUT WHERE yyyymm=?", YYYYMM)
    n, s = cs.fetchone(); s = float(s or 0)
    print(f"  DOI_ETC_INOUT: {n}행 금액 {s:,.0f} vs 엑셀 행레벨 {etc_ex:,.0f} "
          f"{'✓' if round(s)==round(etc_ex) else '⚠️ 불일치(재적재 검토)'} (엑셀 TOTAL셀은 스테일이라 무시)")
    # sale/invoice: DB 합계 출력(엑셀 세금계산서/수출신고필증 TOTAL행과 눈대조 — 열위치 월별 상이)
    cs.execute("SELECT COUNT(*),SUM(원화판매금액) FROM doi_sale_resc WHERE YYYYMM=? AND SITE='HQ'", YYYYMM)
    r = cs.fetchone(); print(f"  doi_sale_resc: {r[0]}행 원화판매 {float(r[1] or 0):,.0f} (엑셀 세금계산서 TOTAL행과 눈대조)")
    cs.execute("SELECT COUNT(*),SUM(원화판매금액) FROM doi_invoice_resc WHERE yyyymm=? AND site='HQ'", YYYYMM)
    r = cs.fetchone(); print(f"  doi_invoice_resc: {r[0]}행 원화판매 {float(r[1] or 0):,.0f} (엑셀 수출신고필증 TOTAL행과 눈대조)")
    cn.close()
    return True


def run_base_loads():
    print("=" * 70, "\n A. 기초자료 적재\n", "=" * 70)
    load_dept_cost(); load_matl_resc(); load_stock(); load_prod_subul()
    load_scof(); load_cst_rate(); replace_bom(); verify_preloaded()


# ============================================================================
#  B. 결산 체인
# ============================================================================

def check_settle_prereq():
    """결산 전 선행조건 점검.
       ★ CarryOver: DOI_ACCT·DOI_BOM_MAST·DOI_DEPT·DOI_MODEL_MAST 를 생성한다.
         - 이미 실행되어 채워져 있으면 재실행 금지(방금 적재한 BOM/DEPT를 전월 stale로 덮어씀).
         - 신규 월 최초 1회만: CarryOver 실행 → BOM 재적재 → DEPT 검증.
         - DOI_MODEL_MAST 는 CarryOver 본(stale)을 쓰지 않고 inject_model_mast() 로 재주입(아래)."""
    cn = connect(autocommit=True); cs = cn.cursor()
    print("[선행조건]")
    for t in ('DOI_ACCT',):
        cs.execute(f"SELECT COUNT(*) FROM {t} WHERE YYYYMM=? AND SITE='HQ'", YYYYMM)
        print(f"  {t}: {cs.fetchone()[0]}행 (0이면 CarryOver 선행 필요)")
    cs.execute("SELECT COUNT(*) FROM DOI_BOM_MAST WHERE YYYYMM=? AND SITE='HQ'", YYYYMM)
    print(f"  DOI_BOM_MAST: {cs.fetchone()[0]}행 (엑셀 전체교체본이어야 함)")
    cn.close()
    return True


def inject_model_mast():
    """★ DOI_MODEL_MAST 주입 (면적 X/Y/XY) — 배부(재료비·경비) 前 필수.
       UP_DOI_EXPEN_MATL·UP_DOI_MAT_COST 가 면적 XY(배부적수=환산량×XY)를 사용하므로
       CarryOver 가 만든 전월 이월본(stale)이 아니라 매월 아래 3단계로 재주입해야 한다.

       1) MES.dw_product_mast 전체 → 원가.dw_product_mast 복사 (원가쪽 DELETE 후).
          ⚠️ MES 와 원가의 dw_product_mast 는 컬럼 '순서'가 달라 SELECT * 금지 → 명시적 컬럼리스트(이름 일치).
       2) 원가.dw_product_mast.Spec 파싱 → doi_model_mast INSERT (해당 월 DELETE 후).
          Spec '장변[*×Xx]단변' 분리 → ±/M·콤마 정제 → X/Y/XY(면적=X*Y).
          ⚠️ 혹 CAST(x/y as real) 오류가 나면(치수 뒤 공백+텍스트 Spec), x/y 를 공백절단하고
             XY 를 TRY_CONVERT(real,…)*TRY_CONVERT(real,…) 로 바꿔 재실행(README §6 참고).
       3) 전월 doi_model_mast 의 ADD_YN='Y'(수기 추가 모델, 예: 716D/H8075/H8133/H818V) 이월."""
    DWPM = ("LINE,Prod_code,Model,Inch,Glass_thick,Version,Spec,Unit,Unit_code,customer_name,"
            "customer_code,Sheet,Block,Cell,RUN_SIZE,Mass_Prod,Note,create_date,create_name,use_yn")
    # --- 1) dw_product_mast 복사 (MES → 원가) ---
    cn = connect(autocommit=False); cs = cn.cursor()
    before = cs.execute("SELECT COUNT(*) FROM dw_product_mast").fetchone()[0]
    cs.execute("DELETE FROM dw_product_mast")
    cs.execute(f"INSERT INTO dw_product_mast ({DWPM}) SELECT {DWPM} "
               f"FROM {MES_LINKED}.[{MES_DB}].dbo.dw_product_mast")
    after = cs.execute("SELECT COUNT(*) FROM dw_product_mast").fetchone()[0]
    if after <= 0:
        cn.rollback(); cn.close(); print("  ✗ dw_product_mast 복사 0행 — ROLLBACK"); return False
    cn.commit(); cn.close()
    print(f"  ✓ dw_product_mast: MES에서 {after}행 복사 (기존 {before})")

    # --- 2) Spec 파싱 INSERT + 3) 전월 ADD_YN='Y' 이월 (한 트랜잭션) ---
    cn = connect(autocommit=False); cs = cn.cursor()
    cs.execute("DELETE FROM doi_model_mast WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE)
    spec_sql = f"""
With Spec_split1 as (
  select Model,upper(Spec) spec,Inch,Glass_thick,Sheet,Block,Cell,RUN_SIZE,
      substring(Spec,1,PATINDEX('%[*|×|X|x]%',Spec)-1) x,
      substring(Spec,PATINDEX('%[*|×|X|x]%',Spec)+1,len(Spec)) y
  from dw_product_mast
  where PATINDEX('%[*|×|X|x]%',Spec)> 0
), Spec_split2 as (
  select model, spec,Inch,Glass_thick,Sheet,Block,Cell,RUN_SIZE,
      replace(case when PATINDEX('%[±|M]%',x)=0 then x else substring(x,1,PATINDEX('%[±|M]%',x)-1) end,',','.') x,
      replace(case when PATINDEX('%[±|M]%',y)=0 then y else substring(y,1,PATINDEX('%[±|M]%',y)-1) end,',','.') y,
      row_number() over (partition by model order by x desc, y desc) as rn
  from Spec_split1
), Spec_split3 as (
  select '{YYYYMM}' yyyymm,'{SEL}' sel_code,'{SITE}' site,model, spec,Inch,Glass_thick,Sheet,Block,Cell,RUN_SIZE,
      x, replace(case when PATINDEX('%*%',y)=0 then y else substring(y,1,PATINDEX('%*%',y)-1) end,',','.') y
  from Spec_split2 where rn=1
)
insert into doi_model_mast (YYYYMM,SEL_CODE,SITE,MODEL,SPEC,INCH,GLASS_THICK,SHEET,BLOCK,CELL,RUN_SIZE,X,Y,XY)
select *,cast(x as real)* cast(y as real) xy
from Spec_split3 order by model;"""
    cs.execute(spec_sql)
    n_spec = cs.rowcount
    # 3) 전월 ADD_YN='Y' 이월 (단 step2 Spec 결과와 중복 모델은 제외 — 방어용 NOT EXISTS)
    cs.execute("""INSERT INTO doi_model_mast (YYYYMM,SEL_CODE,SITE,MODEL,SPEC,INCH,GLASS_THICK,SHEET,BLOCK,CELL,RUN_SIZE,X,Y,XY,ADD_YN)
                  SELECT ?,p.SEL_CODE,?,p.MODEL,p.SPEC,p.INCH,p.GLASS_THICK,p.SHEET,p.BLOCK,p.CELL,p.RUN_SIZE,p.X,p.Y,p.XY,p.ADD_YN
                  FROM doi_model_mast p
                  WHERE p.YYYYMM=? AND p.SITE=? AND p.ADD_YN='Y'
                    AND NOT EXISTS (SELECT 1 FROM doi_model_mast c WHERE c.YYYYMM=? AND c.SITE=? AND c.MODEL=p.MODEL)""",
               YYYYMM, SITE, PREV_YYYYMM, SITE, YYYYMM, SITE)
    n_add = cs.rowcount
    # 검증: XY 전부 유효 + 재공 모델 전부 커버
    cs.execute("SELECT COUNT(*),SUM(CASE WHEN TRY_CONVERT(float,XY)>0 THEN 1 ELSE 0 END) FROM doi_model_mast WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE)
    tot, xyok = cs.fetchone()
    cs.execute("""SELECT COUNT(*) FROM DOI_PROD_SUBUL p WHERE p.YYYYMM=? AND p.SITE=?
                  AND NOT EXISTS (SELECT 1 FROM doi_model_mast m WHERE m.YYYYMM=p.YYYYMM AND m.SITE=p.SITE AND m.MODEL=p.도우모델)""", YYYYMM, SITE)
    miss = cs.fetchone()[0]
    ok = (tot == xyok and miss == 0)
    if ok:
        cn.commit()
        print(f"  ✓ DOI_MODEL_MAST: Spec {n_spec} + 이월(ADD_YN=Y) {n_add} = {tot}행, XY유효 {xyok}, 재공누락 {miss} — COMMIT")
    else:
        cn.rollback()
        print(f"  ✗ DOI_MODEL_MAST: XY유효 {xyok}/{tot} 재공누락 {miss} — ROLLBACK (README §6 CAST/누락 참고)")
    cn.close()
    return ok


def ensure_sale_cost_alter():
    """★ UP_DOI_SALE_COST 도우코드 열 대응 ALTER (최초 1회, 멱등).
       도우코드 열 추가(2026-10-23)로 위치기반 INSERT 2개가 오류 213 → 명시적 컬럼리스트 추가.
       이미 적용돼 있으면 스킵. SQL 전문: UP_DOI_SALE_COST_fix261110_dwcode_collist.sql"""
    cn = connect(autocommit=True); cs = cn.cursor()
    cs.execute("SELECT definition FROM sys.sql_modules WHERE object_id=OBJECT_ID('UP_DOI_SALE_COST')")
    d = cs.fetchone()[0]
    norm = lambda s: ''.join(s.split())   # 공백/개행 무관 비교
    need = norm("(YYYYMM,SITE,SEL_CODE,구분,MODEL,Local구분,판매단위,거래처,EXPEN_SEL,EXPEN_SEL명,OUT_qty,OUT_AMT)")
    if need in norm(d):
        print("  UP_DOI_SALE_COST: 이미 도우코드 대응됨(ALTER 불필요)")
    else:
        fix = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'UP_DOI_SALE_COST_fix261110_dwcode_collist.sql')
        with open(fix, encoding='utf-8') as fp:
            sqltext = fp.read()
        # ⚠️ 공유 라이브 개체 — 적용 전 라이브 최신본과 diff 확인 권장(동료 변경분 보존). GO 없는 단일 배치.
        cs.execute(sqltext)
        print("  ✓ UP_DOI_SALE_COST ALTER 적용(도우코드 열 대응)")
    cn.close()


def _drain(cs):
    """프로시저 결과 메시지를 소비하며 [ERROR]/실패 신호를 감지. 오류 있으면 True 반환(전문 출력)."""
    err = False; printed = 0
    while True:
        try:
            for row in (cs.fetchall() or []):
                t = str(tuple(row))
                if ('[ERROR]' in t) or ('검증 실패' in t) or ('오류가' in t) or ('RETURN -1' in t):
                    err = True
                    print("     [!] ", t)            # 오류 메시지는 절단 없이 전문
                elif printed < 1:
                    print("     ", t[:600] + (' …' if len(t) > 600 else '')); printed += 1
        except pyodbc.ProgrammingError:
            pass
        if not cs.nextset(): break
    return err


def run_settlement_chain():
    """배부/원가 체인. 각 EXEC @YYYYMM,@SITE='HQ',@SEL_CODE='ACTUAL'. ★ UP_DOI_FAB_COST 제외.
       순서: EXPEN_MATL→MAT_AMT→MAT_COST→COST→STOCK_BOH→STOCK_COST→SALE_COST→(IVDD복사)→SCOF→FILL_DWCODE.
       각 proc 실행 후 [ERROR] 감지 시 즉시 중단(부분 결산 방지)."""
    cn = connect(autocommit=True); cs = cn.cursor()
    def run(proc, sql, *args):
        print(f">>> EXEC {proc}")
        try:
            cs.execute(sql, *args)
        except Exception as e:
            raise RuntimeError(f"{proc} T-SQL 오류 — 체인 중단: {e}")
        if _drain(cs):
            raise RuntimeError(f"{proc} 응답에 오류/실패 감지 — 체인 중단(위 [!] 메시지 확인).")
    for proc in ('UP_DOI_EXPEN_MATL', 'UP_DOI_MAT_AMT', 'UP_DOI_MAT_COST', 'UP_DOI_COST', 'UP_DOI_STOCK_BOH'):
        run(proc, f"EXEC {proc} @YYYYMM=?, @SITE=?, @SEL_CODE=?", YYYYMM, SITE, SEL)
    run('UP_DOI_STOCK_COST',
        "DECLARE @m NVARCHAR(4000); EXEC UP_DOI_STOCK_COST @YYYYMM=?, @SITE=?, @SEL_CODE=?, @R_Message=@m OUTPUT; SELECT @m;",
        YYYYMM, SITE, SEL)
    run('UP_DOI_SALE_COST', "EXEC UP_DOI_SALE_COST @YYYYMM=?, @SITE=?, @SEL_CODE=?", YYYYMM, SITE, SEL)
    cn.close()
    copy_ivdd()                                      # 독립 트랜잭션
    cn = connect(autocommit=True); cs = cn.cursor()
    run('UP_DOI_SCOF', "EXEC UP_DOI_SCOF @YYYYMM=?, @SITE=?, @SEL_CODE=?", YYYYMM, SITE, SEL)
    run('UP_DOI_FILL_DWCODE', "EXEC UP_DOI_FILL_DWCODE @YYYYMM=?, @SITE=?, @SEL_CODE=?", YYYYMM, SITE, SEL)
    cn.close()


def copy_ivdd():
    """DOI_IVDD ← DOI_MATL_RESC 복사 (UP_DOI_SCOF 선행조건; SCOF는 IVDD를 읽기만 함). DELETE+INSERT 한 트랜잭션.
       ⚠️ IVDD 텍스트열은 nvarchar(바이트 max_length) — LEFT 폭=max_length/2(nvarchar), varchar=max_length CONVERT.
          nvarchar(max)/varchar(max)는 max_length=-1 → 절단 없이 원본 그대로."""
    TEXT = ['자산처리계정', '품목자산분류', '재고자산종류', '매출원가계정', '대분류', '중분류',
            '소분류', '품목기타분류', '품명', '품번', '규격', '단위']
    cn = connect(autocommit=False); cs = cn.cursor()
    cs.execute("""SELECT c.name,ty.name,c.max_length FROM sys.columns c JOIN sys.types ty ON c.user_type_id=ty.user_type_id
                  WHERE c.object_id=OBJECT_ID('DOI_IVDD')""")
    meta = {r[0]: (r[1], r[2]) for r in cs.fetchall()}
    exprs = []
    for col in TEXT:
        tp, ml = meta[col]
        if ml == -1:                                 # nvarchar(max)/varchar(max): 절단 불필요
            exprs.append(f"m.[{col}]")
        elif tp == 'nvarchar':
            exprs.append(f"LEFT(m.[{col}],{ml//2})")
        else:
            exprs.append(f"CONVERT(varchar({ml}),m.[{col}])")
    amt = ("m.기초수량,m.기초금액,m.입고수량,m.입고금액,m.출고수량,m.출고금액,m.재고수량,m.결산후재고수량,m.차이수량,"
           "m.재고금액,m.결산후재고금액,m.차이금액,m.최종결산월재고단가,m.생산수량,m.생산금액,m.구매수량,m.구매금액,"
           "m.적송입고수량,m.적송입고금액,m.기타입고수량,m.기타입고금액,m.판매수량,m.판매원가,m.투입수량,m.투입금액,"
           "m.적송출고수량,m.적송출고금액,m.기타출고수량,m.기타출고금액")
    cols = ("[YYYYMM],[SEL_CODE],[SITE],[자산처리계정],[품목자산분류],[재고자산종류],[매출원가계정],[대분류],[중분류],[소분류],"
            "[품목기타분류],[품명],[품번],[규격],[단위],[기초수량],[기초금액],[입고수량],[입고금액],[출고수량],[출고금액],"
            "[재고수량A],[결산재고수량B],[차이수량A_B],[재고금액C],[결산재고금액D],[차이금액C_D],[최종결산월재고단가],"
            "[생산수량],[생산금액],[구매수량],[구매금액],[적송입고수량],[적송입고금액],[기타입고수량],[기타입고금액],"
            "[판매수량],[판매원가],[투입수량],[투입금액],[적송출고수량],[적송출고금액],[기타출고수량],[기타출고금액]")
    print(">>> DOI_IVDD 복사")
    cs.execute("DELETE FROM DOI_IVDD WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE)
    cs.execute(f"INSERT INTO DOI_IVDD ({cols}) SELECT m.[YYYYMM],m.[SEL_CODE],m.[SITE],{','.join(exprs)},{amt} "
               f"FROM DOI_MATL_RESC m WHERE m.YYYYMM=? AND m.SITE=? AND m.SEL_CODE=?", YYYYMM, SITE, SEL)
    iv = cs.execute("SELECT COUNT(*) FROM DOI_IVDD WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE).fetchone()[0]
    mr = cs.execute("SELECT COUNT(*) FROM DOI_MATL_RESC WHERE YYYYMM=? AND SITE=? AND SEL_CODE=?", YYYYMM, SITE, SEL).fetchone()[0]
    if iv == mr and iv > 0:
        cn.commit(); print(f"      ✓ DOI_IVDD={iv} (MATL_RESC={mr}) COMMIT")
    else:
        cn.rollback(); cn.close(); raise RuntimeError(f"DOI_IVDD 복사 불일치 {iv}≠{mr} — ROLLBACK, SCOF 중단")
    cn.close()


def run_settle():
    print("=" * 70, "\n B. 결산 체인\n", "=" * 70)
    check_settle_prereq()
    print("[DOI_MODEL_MAST 주입]")
    if not inject_model_mast():                       # 배부 前 면적 주입(3단계)
        print("⚠️ MODEL_MAST 주입 실패 — 중단. README §2-1 / §6 참고.")
        return
    ensure_sale_cost_alter()
    run_settlement_chain()


# ============================================================================
#  C. 검증
# ============================================================================

def verify_special_cases():
    """특이사항 반영 확인(모델/품번은 월별로 다름 — 해당 월 특이사항에 맞게 조정)."""
    cn = connect(autocommit=True); cs = cn.cursor()
    print("[특이사항 검증]")
    # 예: 8176 공정재투입/제품R/W (202610). 월별 대상 모델로 교체해 사용.
    cs.execute("SELECT 도우코드,SUM(OUT_REWORK_QTY),SUM(OUT_REWORK_AMT) FROM DOI_STCO WHERE YYYYMM=? AND SITE='HQ' AND 도우코드 LIKE '8176%' GROUP BY 도우코드", YYYYMM)
    for r in cs.fetchall():
        print(f"  DOI_STCO 공정재투입 {r[0]}: 수량(행당) {r[1]} 금액 {float(r[2] or 0):,.0f}")
    cn.close()


def verify_tie_out():
    """PL tie-out (DOI_PL_ByModel Z합계) + 항등식 자동검산."""
    cn = connect(autocommit=True); cs = cn.cursor()
    print("[PL tie-out] DOI_PL_ByModel")
    cs.execute("EXEC DOI_PL_ByModel @YYYYMM=?, @SITE='HQ', @SEL_CODE='ACTUAL'", YYYYMM)
    cols = [d[0] for d in cs.description]; zi = cols.index('Z합계') if 'Z합계' in cols else len(cols) - 1
    val = {}
    for r in cs.fetchall():
        g = str(r[1]) if r[1] else ''
        if g.strip():
            v = float(r[zi] or 0); val[str(r[0]).strip()] = v
            print(f"  {str(r[0]):5} {g[:28]:30} {v:>18,.0f}")
    # 항등식 검산 (rn 코드 기준: 1매출액 5매출원가 13매출총이익 14판관비 141영업이익)
    def g(k): return val.get(k)
    checks = []
    if g('1.0') is not None and g('5.0') is not None and g('13.0') is not None:
        checks.append(('매출총이익 = 매출액 − 매출원가', round(g('1.0') - g('5.0')), round(g('13.0'))))
    if g('13.0') is not None and g('14.0') is not None and g('141.0') is not None:
        checks.append(('영업이익 = 매출총이익 − 판관비', round(g('13.0') - g('14.0')), round(g('141.0'))))
    allok = True
    for name, calc, rep in checks:
        ok = (calc == rep); allok = allok and ok
        print(f"  {'✓' if ok else '✗'} {name}: 계산 {calc:,} vs 리포트 {rep:,}")
    # ByModel = ByDept (판관비) + 매출원가(STCO 양품) 교차
    cs.execute("SELECT SUM(DIST_AMT) FROM DOI_SMCE_COST WHERE YYYYMM=? AND SITE='HQ'", YYYYMM)
    sga_model = float(cs.fetchone()[0] or 0)
    cs.execute("SELECT SUM(ACCT_AMT) FROM DOI_ACCT_EXPEN WHERE yyyymm=? AND site='HQ' AND acct_class='CC' AND sel_code='ACTUAL'", YYYYMM)
    sga_src = float(cs.fetchone()[0] or 0)
    ok = (round(sga_model) == round(sga_src)); allok = allok and ok
    print(f"  {'✓' if ok else '✗'} 판관비 ByModel({sga_model:,.0f}) = 원천 DOI_ACCT_EXPEN({sga_src:,.0f})")
    cs.execute("SELECT SUM(OUT_GOOD_AMT) FROM DOI_STCO WHERE YYYYMM=? AND SITE='HQ'", YYYYMM)
    print(f"  · 참고 매출원가(STCO 양품출고) {float(cs.fetchone()[0] or 0):,.0f} (PL (1)제품매출원가와 대조)")
    print("  → " + ("전 항등식 통과 ✓" if allok else "⚠️ 불일치 항목 있음 — 상단 ✗ 확인"))
    cn.close()
    return allok


def run_carryover():
    """★ UP_DOI_CarryOver — 신규 월 '최초 1회'만. DOI_ACCT·DOI_BOM_MAST·DOI_DEPT·DOI_MODEL_MAST 를
       전월 복사로 생성한다. ⚠️ @YYYYMM 에 '결산 대상(신규) 월', @PREV_YYYYMM 에 '전월' 을 넣는다.
       실행 순서: (신규월 1회) run_carryover → base(BOM 재적재/DEPT 검증) → settle(MODEL_MAST 재주입 포함).
       ⚠️ 이미 생성돼 있으면 재실행 금지 — base 에서 교체한 BOM/DEPT 를 전월 stale 로 덮는다.
       ⚠️ 전월 복사라 '당월 신규 모델'은 BOM/MODEL_MAST 에서 빠질 수 있음(BOM=엑셀 전체교체,
          MODEL_MAST=Spec 재주입이 보완)."""
    cn = connect(autocommit=True); cs = cn.cursor()
    exist = cs.execute("SELECT COUNT(*) FROM DOI_ACCT WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE).fetchone()[0]
    if exist > 0:
        print(f"  ⚠️ DOI_ACCT {YYYYMM} 이미 {exist}행 — CarryOver 재실행 금지(BOM/DEPT stale 덮어쓰기 위험). 스킵.")
        cn.close(); return
    print(f">>> EXEC UP_DOI_CarryOver @YYYYMM={YYYYMM}, @SITE={SITE}, @PREV_YYYYMM={PREV_YYYYMM}")
    cs.execute("EXEC UP_DOI_CarryOver @YYYYMM=?, @SITE=?, @PREV_YYYYMM=?", YYYYMM, SITE, PREV_YYYYMM)
    _drain(cs)
    for t in ('DOI_ACCT', 'DOI_BOM_MAST', 'DOI_DEPT', 'DOI_MODEL_MAST'):
        cs.execute(f"SELECT COUNT(*) FROM {t} WHERE YYYYMM=? AND SITE=?", YYYYMM, SITE)
        print(f"  {t}: {cs.fetchone()[0]}행 생성")
    print("  → 다음: base(BOM 재적재·DEPT 검증) → settle(MODEL_MAST 재주입 포함)")
    cn.close()


def run_verify():
    print("=" * 70, "\n C. 검증\n", "=" * 70)
    verify_special_cases(); verify_tie_out()


# ============================================================================
if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='HQ 월결산 실행')
    ap.add_argument('--step', choices=['carryover', 'base', 'settle', 'verify', 'all'], default='verify',
                    help="carryover=신규월 1회(CarryOver) / base=기초적재 / settle=결산체인 / verify=검증 / all=base→settle→verify")
    a = ap.parse_args()
    print(f"### HQ {YYYYMM} 결산 — step={a.step} (운영 DB) ###")
    if a.step == 'carryover':       run_carryover()   # 신규월 최초 1회만 (all 에는 미포함)
    if a.step in ('base', 'all'):   run_base_loads()
    if a.step in ('settle', 'all'): run_settle()
    if a.step in ('verify', 'all'): run_verify()
