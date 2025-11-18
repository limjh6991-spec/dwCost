#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
3단계: 재료비집계 프로시저 실행 스크립트
"""

import pymssql
import sys
from datetime import datetime

# 데이터베이스 연결 정보
DB_CONFIG = {
    'server': '172.16.200.204',
    'user': 'TEST_MES_USER',
    'password': 'Dowoo1!',
    'database': '도우제조MES시스템TEST',
    'charset': 'utf8'
}

# 실행 파라미터
PARAMS = {
    'YYYYMM': '202510',
    'SITE': 'HQ',
    'SELCODE': 'ACTUAL'
}

def main():
    print("=" * 80)
    print("3단계: 재료비집계 프로시저 실행")
    print(f"실행 시각: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    print()
    
    print("📋 실행 파라미터:")
    print(f"   - 프로시저: UP_DOI_MAT_AMT")
    print(f"   - 년월: {PARAMS['YYYYMM']}")
    print(f"   - 사업장: {PARAMS['SITE']}")
    print(f"   - 구분: {PARAMS['SELCODE']}")
    
    # 데이터베이스 연결
    try:
        conn = pymssql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ 데이터베이스 연결 성공")
        print()
    except Exception as e:
        print(f"❌ 데이터베이스 연결 실패: {e}")
        sys.exit(1)
    
    try:
        # 프로시저 실행
        print("🚀 프로시저 실행 시작...")
        print("-" * 80)
        print()
        
        start_time = datetime.now()
        
        cursor.execute("EXEC UP_DOI_MAT_AMT %s, %s, %s", 
                      (PARAMS['YYYYMM'], PARAMS['SITE'], PARAMS['SELCODE']))
        
        # 결과 메시지 출력
        result = cursor.fetchone()
        if result:
            print("📋 실행 결과:")
            print("=" * 80)
            print(result[0])
            print("=" * 80)
        
        conn.commit()
        
        end_time = datetime.now()
        elapsed = (end_time - start_time).total_seconds()
        
        print()
        print("✅ 재료비집계 실행 완료!")
        print(f"   소요시간: {elapsed:.2f}초")
        print()
        
        # 결과 데이터 확인
        print("🔍 결과 데이터 확인 중...")
        print()
        
        # DOI_MAT_AMT 통계
        cursor.execute("""
            SELECT COUNT(*) as 건수, 
                   SUM(in_qty) as 수량,
                   SUM(in_amt) as 금액
            FROM DOI_MAT_AMT
            WHERE YYYYMM = %s AND SITE = %s AND sel_code = %s
        """, (PARAMS['YYYYMM'], PARAMS['SITE'], PARAMS['SELCODE']))
        
        row = cursor.fetchone()
        if row:
            print(f"   📊 DOI_MAT_AMT (재료비집계):")
            print(f"      - 건수: {row[0]:,}건")
            print(f"      - 수량: {row[1]:,.2f}")
            print(f"      - 금액: {row[2]:,.0f}원")
        
        print()
        
        # 자재대분류별 재료비 상위 5개
        cursor.execute("""
            SELECT TOP 5 ISNULL(자재대분류, '미분류') as 자재대분류, 
                   COUNT(*) as 건수, 
                   SUM(in_qty) as 수량,
                   SUM(in_amt) as 금액
            FROM DOI_MAT_AMT
            WHERE YYYYMM = %s AND SITE = %s AND sel_code = %s
            GROUP BY 자재대분류
            ORDER BY SUM(in_amt) DESC
        """, (PARAMS['YYYYMM'], PARAMS['SITE'], PARAMS['SELCODE']))
        
        print(f"   📊 자재대분류별 재료비 상위 5개:")
        print()
        print(f"      {'자재대분류':<20}{'건수':>10}{'수량':>18}{'금액':>20}")
        print("      " + "-" * 68)
        
        for row in cursor.fetchall():
            mat_class, cnt, qty, amt = row
            print(f"      {mat_class:<20}{cnt:>10}{qty:>18,.2f}{amt:>20,.0f}원")
        
        print()
        print("=" * 80)
        print("✅ 3단계: 재료비집계 완료")
        print("=" * 80)
        print()
        
    except Exception as e:
        print(f"❌ 프로시저 실행 실패: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        print("✅ 데이터베이스 연결 종료")
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()
