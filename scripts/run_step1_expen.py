#!/usr/bin/env python3
"""
1단계: 경비집계 (Gen_EXPEN_MATL) 실행
2025-11-14
"""

import pymssql
import sys
from datetime import datetime

# 데이터베이스 연결 정보
DB_CONFIG = {
    'server': '172.16.200.204',
    'database': '도우제조MES시스템TEST',
    'user': 'TEST_MES_USER',
    'password': 'Dowoo1!',
}

def get_connection():
    """데이터베이스 연결"""
    try:
        conn = pymssql.connect(
            server=DB_CONFIG['server'],
            database=DB_CONFIG['database'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            timeout=30,
            login_timeout=30
        )
        print("✅ 데이터베이스 연결 성공")
        return conn
    except Exception as e:
        print(f"❌ 데이터베이스 연결 실패: {e}")
        sys.exit(1)

def main():
    """메인 함수"""
    print("="*80)
    print("1단계: 경비집계 프로시저 실행")
    print(f"실행 시각: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)
    
    # 파라미터 설정
    YYYYMM = '202510'
    SITE = 'HQ'
    
    print(f"\n📋 실행 파라미터:")
    print(f"   - 프로시저: Gen_EXPEN_MATL")
    print(f"   - 년월: {YYYYMM}")
    print(f"   - 사업장: {SITE}")
    
    # 데이터베이스 연결
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        print(f"\n🚀 프로시저 실행 시작...")
        print("-" * 80)
        
        start_time = datetime.now()
        
        # 프로시저 실행
        sql = "EXEC Gen_EXPEN_MATL %s, %s"
        cursor.execute(sql, (YYYYMM, SITE))
        
        # 결과 메시지 출력
        if cursor.description:
            row = cursor.fetchone()
            if row:
                message = row[0]
                print("\n📋 실행 결과:")
                print("=" * 80)
                for line in message.split('\n'):
                    print(line)
                print("=" * 80)
        
        conn.commit()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        print(f"\n✅ 경비집계 실행 완료!")
        print(f"   소요시간: {duration:.2f}초")
        
        # 결과 데이터 확인
        print(f"\n🔍 결과 데이터 확인 중...")
        
        # DOI_ACCT_EXPEN 건수 확인
        cursor.execute("""
            SELECT COUNT(*) as cnt, SUM(CAST(ACCT_AMT AS BIGINT)) as total_amt
            FROM DOI_ACCT_EXPEN
            WHERE yyyymm = %s AND site = %s
        """, (YYYYMM, SITE))
        row = cursor.fetchone()
        if row:
            print(f"\n   📊 DOI_ACCT_EXPEN (부서별/원가항목별 투입비용):")
            print(f"      - 건수: {row[0]:,}건")
            print(f"      - 금액: {row[1]:,.0f}원")
        
        # DOI_EXPEN_MATL 건수 확인
        cursor.execute("""
            SELECT COUNT(*) as cnt, SUM([IN]) as total_in
            FROM DOI_EXPEN_MATL
            WHERE YYYYMM = %s AND SITE = %s
        """, (YYYYMM, SITE))
        row = cursor.fetchone()
        if row:
            print(f"\n   📊 DOI_EXPEN_MATL (경비집계):")
            print(f"      - 건수: {row[0]:,}건")
            print(f"      - IN 금액: {row[1]:,.0f}원")
        
        # 모델별 상위 5개 확인
        print(f"\n   📊 모델별 경비집계 상위 5개:")
        cursor.execute("""
            SELECT TOP 5
                model,
                구분,
                COUNT(*) as cnt,
                SUM([IN]) as total_in
            FROM DOI_EXPEN_MATL
            WHERE YYYYMM = %s AND SITE = %s
            GROUP BY model, 구분
            ORDER BY SUM([IN]) DESC
        """, (YYYYMM, SITE))
        
        rows = cursor.fetchall()
        if rows:
            print(f"\n      {'모델':<15} {'구분':<10} {'건수':<10} {'IN 금액':<20}")
            print(f"      {'-'*60}")
            for row in rows:
                print(f"      {row[0]:<15} {row[1]:<10} {row[2]:<10} {row[3]:>18,.0f}원")
        
        print("\n" + "="*80)
        print("✅ 1단계: 경비집계 완료")
        print("="*80)
        
    except Exception as e:
        print(f"\n❌ 경비집계 실행 실패:")
        print(f"   에러: {str(e)}")
        conn.rollback()
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()
        print("\n✅ 데이터베이스 연결 종료")

if __name__ == "__main__":
    main()
