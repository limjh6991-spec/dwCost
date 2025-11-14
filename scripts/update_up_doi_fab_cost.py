#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UP_DOI_FAB_COST 프로시저 업데이트 스크립트
"""

import pymssql
import sys
from pathlib import Path

# 데이터베이스 연결 정보
DB_CONFIG = {
    'server': '172.16.200.204',
    'user': 'TEST_MES_USER',
    'password': 'Dowoo1!',
    'database': '도우제조MES시스템TEST',
    'charset': 'utf8'
}

def main():
    print("=" * 80)
    print("UP_DOI_FAB_COST 프로시저 업데이트")
    print("=" * 80)
    print()
    
    # SQL 파일 읽기
    sql_file = Path(__file__).parent.parent / 'src' / '원가SQL' / 'UP_DOI_FAB_COST'
    
    try:
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        print("✅ SQL 파일 읽기 완료")
    except Exception as e:
        print(f"❌ SQL 파일 읽기 실패: {e}")
        sys.exit(1)
    
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
        # 기존 프로시저 삭제
        print("🗑️  기존 프로시저 삭제 중...")
        cursor.execute("DROP PROCEDURE IF EXISTS UP_DOI_FAB_COST")
        conn.commit()
        print("✅ 기존 프로시저 삭제 완료")
        print()
        
        # 새 프로시저 생성
        print("📝 새 프로시저 생성 중...")
        cursor.execute(sql_content)
        conn.commit()
        print("✅ 프로시저 생성 완료")
        print()
        
        print("=" * 80)
        print("✅ UP_DOI_FAB_COST 프로시저 업데이트 완료!")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ 프로시저 업데이트 실패: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()
