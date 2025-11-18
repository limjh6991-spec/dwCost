#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
2단계: 가공비배부 프로시저 실행 스크립트
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
    'SITE': 'HQ'
}

def main():
    print("=" * 80)
    print("2단계: 가공비배부 프로시저 실행")
    print(f"실행 시각: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    print()
    
    print("📋 실행 파라미터:")
    print(f"   - 프로시저: UP_DOI_FAB_COST")
    print(f"   - 년월: {PARAMS['YYYYMM']}")
    print(f"   - 사업장: {PARAMS['SITE']}")
    
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
        
        cursor.execute("EXEC UP_DOI_FAB_COST %s, %s", 
                      (PARAMS['YYYYMM'], PARAMS['SITE']))
        
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
        print("✅ 가공비배부 실행 완료!")
        print(f"   소요시간: {elapsed:.2f}초")
        print()
        
        # 결과 데이터 확인
        print("🔍 결과 데이터 확인 중...")
        print()
        
        # DOI_FAB_COST 통계
        cursor.execute("""
            SELECT COUNT(*) as 건수, 
                   SUM([IN]) as IN금액
            FROM DOI_FAB_COST
            WHERE YYYYMM = %s AND SITE = %s
        """, (PARAMS['YYYYMM'], PARAMS['SITE']))
        
        row = cursor.fetchone()
        if row:
            print(f"   📊 DOI_FAB_COST (가공비배부):")
            print(f"      - 건수: {row[0]:,}건")
            print(f"      - IN 금액: {row[1]:,.0f}원")
        
        print()
        
        # 모델별 가공비 상위 5개
        cursor.execute("""
            SELECT TOP 5 model, 구분, COUNT(*) as 건수, SUM([IN]) as IN금액
            FROM DOI_FAB_COST
            WHERE YYYYMM = %s AND SITE = %s
            GROUP BY model, 구분
            ORDER BY SUM([IN]) DESC
        """, (PARAMS['YYYYMM'], PARAMS['SITE']))
        
        print(f"   📊 모델별 가공비배부 상위 5개:")
        print()
        print(f"      {'모델':<16}{'구분':<12}{'건수':>12}{'IN 금액':>20}")
        print("      " + "-" * 60)
        
        for row in cursor.fetchall():
            model, gubun, cnt, in_amt = row
            print(f"      {model:<16}{gubun:<12}{cnt:>12}{in_amt:>20,.0f}원")
        
        print()
        print("=" * 80)
        print("✅ 2단계: 가공비배부 완료")
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
