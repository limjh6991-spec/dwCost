#!/usr/bin/env python3
"""
기타입출고금액조회(통합) 엑셀 → DOI_ETC_INOUT (본사/운영DB) 적재

  사용: python scripts/load_etc_inout.py ["docs/1~7월 기타입출고금액 DB/1~7월 기타입출고금액 DB"]

  - 엑셀 포맷: 1행 제목 / 2행 헤더(23컬럼) / 3행 TOTAL / 4행~ 데이터
  - yyyymm 은 [일자] 에서 유도, yyyymm 단위 DELETE 후 INSERT (멱등)
  - 적재 후 엑셀 TOTAL 행의 수량·금액과 대조 검증
  - 접속정보는 환경변수로 주입 (CMS_DB_HOST / CMS_DB_PORT / CMS_DB_USER / CMS_DB_PW / CMS_DB_NAME)
"""

import glob
import os
import sys
import decimal
import openpyxl
import pymssql

SRC_DEFAULT = "docs/1~7월 기타입출고금액 DB/1~7월 기타입출고금액 DB"
EDIT_USER = "EXCEL_LOAD"

COLS = ['회계단위', '일자', '입출고구분', '원천구분', '기타입출고구분', '품목자산분류', '대분류', '중분류',
        '소분류', '품명', '품번', '규격', '단위', '단수보정구분', '수량', '금액', '단가', '계정과목', '창고',
        '사용부서', '거래처', '특이사항', '품목특이사항']
NUM_IDX = {14, 15, 16}   # 수량 / 금액 / 단가


def cell(value, idx):
    """빈 문자열은 NULL, 수량·금액·단가는 Decimal 로 변환"""
    if value is None:
        return None
    if idx in NUM_IDX:
        try:
            return decimal.Decimal(str(value))
        except decimal.InvalidOperation:
            return None
    text = str(value).strip()
    return text if text != "" else None


def read_excel(path):
    wb = openpyxl.load_workbook(path, data_only=True, read_only=True)
    rows = list(wb.worksheets[0].iter_rows(min_row=1, values_only=True))
    wb.close()

    if list(rows[1]) != COLS:
        raise ValueError(f"헤더가 표준 23컬럼과 다릅니다: {path}")

    total = rows[2]
    records = []
    for row in rows[3:]:
        if not any(v not in (None, '') for v in row):
            continue
        yyyymm = str(row[1])[:7].replace('-', '')
        records.append(tuple(cell(row[i], i) for i in range(23)) + (yyyymm, EDIT_USER))
    return records, total


def connect():
    return pymssql.connect(
        server=os.environ.get('CMS_DB_HOST', '10.100.40.17'),
        port=int(os.environ.get('CMS_DB_PORT', '14233')),
        user=os.environ['CMS_DB_USER'],
        password=os.environ['CMS_DB_PW'],
        database=os.environ.get('CMS_DB_NAME', '도우제조원가시스템'),
    )


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else SRC_DEFAULT
    files = sorted(glob.glob(os.path.join(src, "*.xlsx")))
    if not files:
        print(f"엑셀 파일이 없습니다: {src}")
        return 1

    conn = connect()
    cursor = conn.cursor()

    insert_sql = ("INSERT INTO DOI_ETC_INOUT ([" + "],[".join(COLS) + "],[yyyymm],[edit_user],[edit_date]) "
                  "VALUES (" + ",".join(["%s"] * 25) + ", GETDATE())")

    expected = {}
    for path in files:
        records, total = read_excel(path)
        yyyymm = records[0][23]
        cursor.execute("DELETE FROM DOI_ETC_INOUT WHERE yyyymm = %s", (yyyymm,))
        cursor.executemany(insert_sql, records)
        expected[yyyymm] = (len(records),
                            decimal.Decimal(str(total[14])),
                            decimal.Decimal(str(total[15])))
        print(f"  {os.path.basename(path):45s} yyyymm={yyyymm} rows={len(records)}")
    conn.commit()

    print("\n=== 검증: DB 적재결과 vs 엑셀 TOTAL 행 ===")
    cursor.execute("SELECT yyyymm, COUNT(*), SUM(수량), SUM(금액) "
                   "FROM DOI_ETC_INOUT GROUP BY yyyymm ORDER BY yyyymm")
    all_ok = True
    for yyyymm, cnt, sum_qty, sum_amt in cursor.fetchall():
        exp_cnt, exp_qty, exp_amt = expected[yyyymm]
        ok = (cnt == exp_cnt and sum_qty == exp_qty and sum_amt == exp_amt)
        all_ok &= ok
        print(f"  {yyyymm}  건수 {cnt:4d}/{exp_cnt:4d}  "
              f"수량 {sum_qty:>12,.0f}/{exp_qty:>12,.0f}  "
              f"금액 {sum_amt:>16,.0f}/{exp_amt:>16,.0f}  {'OK' if ok else 'MISMATCH'}")

    conn.close()
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
