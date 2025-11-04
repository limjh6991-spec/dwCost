#!/usr/bin/env python3
"""
DOI_STOCK 테이블 구조 확인
"""

import pymssql

conn = pymssql.connect(
    server='172.16.200.204',
    user='TEST_MES_USER',
    password='Dowoo1!',
    database='도우제조MES시스템TEST'
)

cursor = conn.cursor()

# DOI_STOCK 테이블 컬럼 확인
cursor.execute("""
    SELECT TOP 1 * FROM DOI_STOCK
    WHERE YYYYMM = '202508'
""")

# 컬럼명 출력
columns = [desc[0] for desc in cursor.description]
print("DOI_STOCK 테이블 컬럼:")
print("=" * 70)
for i, col in enumerate(columns, 1):
    print(f"{i:2d}. {col}")

# 샘플 데이터
row = cursor.fetchone()
if row:
    print("\n샘플 데이터:")
    print("=" * 70)
    for col, val in zip(columns, row):
        print(f"{col:20s}: {val}")

conn.close()
