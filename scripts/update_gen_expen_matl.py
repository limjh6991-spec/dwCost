#!/usr/bin/env python3
"""
Gen_EXPEN_MATL 프로시저 업데이트 스크립트
"""

import pymssql
import sys

DB_CONFIG = {
    'server': '172.16.200.204',
    'database': '도우제조MES시스템TEST',
    'user': 'TEST_MES_USER',
    'password': 'Dowoo1!',
}

def main():
    print("="*80)
    print("Gen_EXPEN_MATL 프로시저 업데이트")
    print("="*80)
    
    try:
        # SQL 파일 읽기
        with open('/home/roarm_m3/dwisCOST/src/원가SQL/Gen_EXPEN_MATL.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("\n✅ SQL 파일 읽기 완료")
        
        # 데이터베이스 연결
        conn = pymssql.connect(
            server=DB_CONFIG['server'],
            database=DB_CONFIG['database'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            timeout=30
        )
        print("✅ 데이터베이스 연결 성공")
        
        cursor = conn.cursor()
        
        # 기존 프로시저 삭제
        print("\n🗑️  기존 프로시저 삭제 중...")
        cursor.execute("DROP PROCEDURE IF EXISTS Gen_EXPEN_MATL")
        conn.commit()
        print("✅ 기존 프로시저 삭제 완료")
        
        # 새 프로시저 생성
        print("\n📝 새 프로시저 생성 중...")
        cursor.execute(sql_content)
        conn.commit()
        print("✅ 프로시저 생성 완료")
        
        cursor.close()
        conn.close()
        
        print("\n" + "="*80)
        print("✅ Gen_EXPEN_MATL 프로시저 업데이트 완료!")
        print("="*80)
        
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
