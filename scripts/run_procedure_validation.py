#!/usr/bin/env python3
"""
원가 프로시저 검증 실행 스크립트
2025-11-14
"""

import pyodbc
import sys
from datetime import datetime

# 데이터베이스 연결 정보
DB_CONFIG = {
    'server': '172.16.200.204',
    'database': '도우제조MES시스템TEST',
    'username': 'TEST_MES_USER',
    'password': 'Dowoo1!',
    'driver': '{ODBC Driver 17 for SQL Server}'
}

def get_connection():
    """데이터베이스 연결"""
    try:
        conn_str = (
            f"DRIVER={DB_CONFIG['driver']};"
            f"SERVER={DB_CONFIG['server']};"
            f"DATABASE={DB_CONFIG['database']};"
            f"UID={DB_CONFIG['username']};"
            f"PWD={DB_CONFIG['password']};"
            f"TrustServerCertificate=yes;"
        )
        conn = pyodbc.connect(conn_str, timeout=30)
        print("✅ 데이터베이스 연결 성공")
        return conn
    except Exception as e:
        print(f"❌ 데이터베이스 연결 실패: {e}")
        sys.exit(1)

def run_procedure(conn, proc_name, yyyymm, site, sel_code=None, use_output=False):
    """
    프로시저 실행
    
    Args:
        conn: 데이터베이스 연결
        proc_name: 프로시저 이름
        yyyymm: 년월 (예: '202510')
        site: 사업장 (예: 'HQ')
        sel_code: 선택코드 (예: 'DOI0001')
        use_output: OUTPUT 파라미터 사용 여부
    """
    cursor = conn.cursor()
    
    try:
        print(f"\n{'='*80}")
        print(f"🚀 프로시저 실행: {proc_name}")
        print(f"   - 년월: {yyyymm}")
        print(f"   - 사업장: {site}")
        if sel_code:
            print(f"   - 선택코드: {sel_code}")
        print(f"{'='*80}\n")
        
        start_time = datetime.now()
        
        if use_output:
            # OUTPUT 파라미터가 있는 경우 (UP_DOI_STOCK_COST)
            sql = f"""
            DECLARE @MSG NVARCHAR(MAX) = ''
            EXEC {proc_name} ?, ?, @MSG OUTPUT
            SELECT @MSG AS retMessage
            """
            cursor.execute(sql, (yyyymm, site))
        elif sel_code:
            # SEL_CODE 파라미터가 있는 경우
            sql = f"EXEC {proc_name} ?, ?, ?"
            cursor.execute(sql, (yyyymm, site, sel_code))
        else:
            # SEL_CODE 파라미터가 없는 경우 (Gen_EXPEN_MATL)
            sql = f"EXEC {proc_name} ?, ?"
            cursor.execute(sql, (yyyymm, site))
        
        # 결과 메시지 출력
        if cursor.description:
            row = cursor.fetchone()
            if row:
                message = row[0]
                print("📋 실행 결과 메시지:")
                print("-" * 80)
                print(message)
                print("-" * 80)
        
        conn.commit()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        print(f"\n✅ {proc_name} 실행 완료 (소요시간: {duration:.2f}초)")
        return True
        
    except Exception as e:
        print(f"\n❌ {proc_name} 실행 실패:")
        print(f"   에러: {str(e)}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def main():
    """메인 함수"""
    print("="*80)
    print("원가 프로시저 검증 실행")
    print(f"실행 시각: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)
    
    # 파라미터 설정
    YYYYMM = '202510'
    SITE = 'HQ'
    SEL_CODE = 'DOI0001'
    
    # 데이터베이스 연결
    conn = get_connection()
    
    try:
        # 1. 경비집계
        print("\n" + "="*80)
        print("1️⃣  경비집계 (Gen_EXPEN_MATL)")
        print("="*80)
        if not run_procedure(conn, 'Gen_EXPEN_MATL', YYYYMM, SITE):
            print("\n⚠️  경비집계 실패로 인해 중단합니다.")
            return
        
        input("\n✋ 다음 단계로 진행하려면 Enter를 누르세요... (Ctrl+C로 중단 가능)")
        
        # 2. 공비배부
        print("\n" + "="*80)
        print("2️⃣  공비배부 (UP_DOI_FAB_COST)")
        print("="*80)
        if not run_procedure(conn, 'UP_DOI_FAB_COST', YYYYMM, SITE, SEL_CODE):
            print("\n⚠️  공비배부 실패로 인해 중단합니다.")
            return
        
        input("\n✋ 다음 단계로 진행하려면 Enter를 누르세요... (Ctrl+C로 중단 가능)")
        
        # 3. 재료비집계
        print("\n" + "="*80)
        print("3️⃣  재료비집계 (UP_DOI_MAT_AMT)")
        print("="*80)
        if not run_procedure(conn, 'UP_DOI_MAT_AMT', YYYYMM, SITE, SEL_CODE):
            print("\n⚠️  재료비집계 실패로 인해 중단합니다.")
            return
        
        input("\n✋ 다음 단계로 진행하려면 Enter를 누르세요... (Ctrl+C로 중단 가능)")
        
        # 4. 재료비배부
        print("\n" + "="*80)
        print("4️⃣  재료비배부 (UP_DOI_MAT_COST)")
        print("="*80)
        if not run_procedure(conn, 'UP_DOI_MAT_COST', YYYYMM, SITE, SEL_CODE):
            print("\n⚠️  재료비배부 실패로 인해 중단합니다.")
            return
        
        input("\n✋ 다음 단계로 진행하려면 Enter를 누르세요... (Ctrl+C로 중단 가능)")
        
        # 5. 재공평가
        print("\n" + "="*80)
        print("5️⃣  재공평가 (UP_DOI_COST_MAT)")
        print("="*80)
        if not run_procedure(conn, 'UP_DOI_COST_MAT', YYYYMM, SITE, SEL_CODE):
            print("\n⚠️  재공평가 실패로 인해 중단합니다.")
            return
        
        input("\n✋ 다음 단계로 진행하려면 Enter를 누르세요... (Ctrl+C로 중단 가능)")
        
        # 6. 제품수불
        print("\n" + "="*80)
        print("6️⃣  제품수불 (UP_DOI_STOCK_COST)")
        print("="*80)
        if not run_procedure(conn, 'UP_DOI_STOCK_COST', YYYYMM, SITE, use_output=True):
            print("\n⚠️  제품수불 실패로 인해 중단합니다.")
            return
        
        print("\n" + "="*80)
        print("🎉 모든 프로시저 실행 완료!")
        print("="*80)
        
    except KeyboardInterrupt:
        print("\n\n⚠️  사용자에 의해 중단되었습니다.")
    except Exception as e:
        print(f"\n❌ 예상치 못한 오류 발생: {e}")
    finally:
        conn.close()
        print("\n✅ 데이터베이스 연결 종료")

if __name__ == "__main__":
    main()
