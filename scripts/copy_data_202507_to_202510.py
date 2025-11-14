#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
202507월 데이터를 202510월로 복사
"""

import pymssql
import sys

# DB 연결 정보
SERVER = '172.16.200.204'
DATABASE = '도우제조MES시스템TEST'
USERNAME = 'TEST_MES_USER'
PASSWORD = 'Dowoo1!'

def execute_copy():
    try:
        # DB 연결
        print("=" * 60)
        print("DB 연결 중...")
        conn = pymssql.connect(server=SERVER, user=USERNAME, password=PASSWORD, database=DATABASE, charset='utf8')
        cursor = conn.cursor()
        print("✓ DB 연결 성공")
        print("=" * 60)
        print()
        
        # 1. DOI_ACCT 복사
        print("1. DOI_ACCT (원가계정정보) 복사 중...")
        cursor.execute("DELETE FROM DOI_ACCT WHERE YYYYMM = '202510' AND SITE = 'HQ'")
        deleted = cursor.rowcount
        
        cursor.execute("""
            INSERT INTO DOI_ACCT 
            SELECT '202510' AS YYYYMM, SEL_CODE, SITE, ACCT_CLASS, 계정과목내부코드, 전표기표여부,
                   ACCT, ACCT_NAME, 차대, 계정대분류, 관리항목유형, 계정과목Lev, 상위계정과목,
                   경영계획과목, 상위계정과목내부코드, 소분류, 중분류, 대분류, expen_sel, expen_sel명, 특이사항
            FROM DOI_ACCT
            WHERE YYYYMM = '202507' AND SITE = 'HQ'
        """)
        inserted = cursor.rowcount
        conn.commit()
        print(f"   → {deleted}건 삭제, {inserted}건 복사 완료")
        print()
        
        # 2. DOI_DEPT 복사
        print("2. DOI_DEPT (부서정보) 복사 중...")
        cursor.execute("DELETE FROM DOI_DEPT WHERE YYYYMM = '202510' AND SITE = 'HQ'")
        deleted = cursor.rowcount
        
        cursor.execute("""
            INSERT INTO DOI_DEPT
            SELECT '202510' AS YYYYMM, SEL_CODE, SITE, DEPT, DEPT_NAME, EXPEN_AREA
            FROM DOI_DEPT
            WHERE YYYYMM = '202507' AND SITE = 'HQ'
        """)
        inserted = cursor.rowcount
        conn.commit()
        print(f"   → {deleted}건 삭제, {inserted}건 복사 완료")
        print()
        
        # 3. DOI_DEPT_COST 복사
        print("3. DOI_DEPT_COST (부서별,계정별 투입비용) 복사 중...")
        cursor.execute("DELETE FROM DOI_DEPT_COST WHERE yyyymm = '202510' AND site = 'HQ'")
        deleted = cursor.rowcount
        
        cursor.execute("""
            INSERT INTO DOI_DEPT_COST
            SELECT '202510' AS yyyymm, sel_code, site, 코스트센터, 코스트센터분류, 코스트센터유형,
                   계정코드, 계정과목, 비용구분, 차변금액, 대변금액
            FROM DOI_DEPT_COST
            WHERE yyyymm = '202507' AND site = 'HQ'
        """)
        inserted = cursor.rowcount
        conn.commit()
        print(f"   → {deleted}건 삭제, {inserted}건 복사 완료")
        print()
        
        # 4. DOI_MODEL_MAST 복사
        print("4. DOI_MODEL_MAST (면적정보) 복사 중...")
        cursor.execute("DELETE FROM DOI_MODEL_MAST WHERE YYYYMM = '202510' AND SITE = 'HQ'")
        deleted = cursor.rowcount
        
        cursor.execute("""
            INSERT INTO DOI_MODEL_MAST
            SELECT '202510' AS YYYYMM, SEL_CODE, SITE, MODEL, SPEC, INCH, GLASS_THICK,
                   SHEET, BLOCK, CELL, RUN_SIZE, X, Y, XY
            FROM DOI_MODEL_MAST
            WHERE YYYYMM = '202507' AND SITE = 'HQ'
        """)
        inserted = cursor.rowcount
        conn.commit()
        print(f"   → {deleted}건 삭제, {inserted}건 복사 완료")
        print()
        
        # 5. DOI_CASSETTE_RESC 복사
        print("5. DOI_CASSETTE_RESC (카세트 발생비용) 복사 중...")
        cursor.execute("DELETE FROM DOI_CASSETTE_RESC WHERE YYYYMM = '202510' AND SITE = 'HQ'")
        deleted = cursor.rowcount
        
        cursor.execute("""
            INSERT INTO DOI_CASSETTE_RESC
            SELECT '202510' AS YYYYMM, SEL_CODE, SITE, CST_NO, CST_NAME, CST_CLASS, SPEC,
                   UNIT, IN_QTY, IN_DATE, IN_DEPT, DEPT_CODE, IN_PERSON, LAST_DATETIME
            FROM DOI_CASSETTE_RESC
            WHERE YYYYMM = '202507' AND SITE = 'HQ'
        """)
        inserted = cursor.rowcount
        conn.commit()
        print(f"   → {deleted}건 삭제, {inserted}건 복사 완료")
        print()
        
        # 결과 확인
        print("=" * 60)
        print("복사 결과 확인")
        print("=" * 60)
        
        cursor.execute("""
            SELECT '1. DOI_ACCT' AS 테이블, COUNT(*) AS 건수
            FROM DOI_ACCT WHERE YYYYMM = '202510' AND SITE = 'HQ'
            UNION ALL
            SELECT '2. DOI_DEPT', COUNT(*)
            FROM DOI_DEPT WHERE YYYYMM = '202510' AND SITE = 'HQ'
            UNION ALL
            SELECT '3. DOI_DEPT_COST', COUNT(*)
            FROM DOI_DEPT_COST WHERE yyyymm = '202510' AND site = 'HQ'
            UNION ALL
            SELECT '4. DOI_MODEL_MAST', COUNT(*)
            FROM DOI_MODEL_MAST WHERE YYYYMM = '202510' AND SITE = 'HQ'
            UNION ALL
            SELECT '5. DOI_CASSETTE_RESC', COUNT(*)
            FROM DOI_CASSETTE_RESC WHERE YYYYMM = '202510' AND SITE = 'HQ'
        """)
        
        for row in cursor.fetchall():
            print(f"{row[0]}: {row[1]:,}건")
        
        print()
        print("=" * 60)
        print("✓ 모든 데이터 복사 완료!")
        print("=" * 60)
        
        cursor.close()
        conn.close()
        
        return 0
        
    except Exception as e:
        print(f"✗ 오류 발생: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(execute_copy())
