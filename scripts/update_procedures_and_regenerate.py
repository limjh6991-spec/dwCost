#!/usr/bin/env python3
"""
원가 프로시저 업데이트 및 202510 데이터 재생성 스크립트
- 6개 원가 프로시저를 무결성 검증 로직이 포함된 버전으로 업데이트
- 202510 데이터를 순서대로 재생성 (기존 데이터 삭제 후)
"""

import pymssql
import time
import sys
from datetime import datetime

# DB 연결 정보
DB_CONFIG = {
    'server': '172.16.200.204',
    'port': 1433,
    'user': 'TEST_MES_USER',
    'password': 'Dowoo1!',
    'database': '도우제조MES시스템TEST'
}

# 프로시저 파일 정보 (순서대로) - UP_DOI_STOCK_COST 제외 (테이블 구조 문제)
PROCEDURE_FILES = [
    ('Gen_EXPEN_MATL', '/home/roarm_m3/dwisCOST/src/원가SQL/Gen_EXPEN_MATL.sql'),
    ('UP_DOI_FAB_COST', '/home/roarm_m3/dwisCOST/src/원가SQL/UP_DOI_FAB_COST'),
    ('UP_DOI_MAT_AMT', '/home/roarm_m3/dwisCOST/src/원가SQL/UP_DOI_MAT_AMT'),
    ('UP_DOI_MAT_COST', '/home/roarm_m3/dwisCOST/src/원가SQL/UP_DOI_MAT_COST'),
    ('UP_DOI_COST_MAT', '/home/roarm_m3/dwisCOST/src/원가SQL/UP_DOI_COST_MAT')
    # UP_DOI_STOCK_COST는 테이블 구조 문제로 인해 일단 제외
]

# 실행할 프로시저 정보 (순서대로)
PROCEDURES_TO_EXECUTE = [
    ('Gen_EXPEN_MATL', '경비집계', ['202510', 'HQ']),
    ('UP_DOI_FAB_COST', '공비배부', ['202510', 'HQ', 'DOI0001']),
    ('UP_DOI_MAT_AMT', '재료비집계', ['202510', 'HQ', 'DOI0001']),
    ('UP_DOI_MAT_COST', '재료비배부', ['202510', 'HQ', 'DOI0001']),
    ('UP_DOI_COST_MAT', '재공평가', ['202510', 'HQ', 'DOI0001']),
    ('UP_DOI_STOCK_COST', '제품수불', ['202510', 'HQ'])
]

# 삭제할 결과 테이블 (역순으로 삭제)
RESULT_TABLES = [
    'DOI_STOCK_COST',
    'DOI_FAB_COST',
    'DOI_COST_MAT',
    'DOI_MAT_COST',
    'DOI_MAT_AMT',
    'DOI_EXPEN_MATL'
]

def print_log(message, level='INFO'):
    """로그 출력"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{level}] {timestamp} - {message}")
    sys.stdout.flush()

def update_procedure(cursor, proc_name, file_path):
    """프로시저 업데이트"""
    try:
        print_log(f"프로시저 업데이트 시작: {proc_name}")
        
        # SQL 파일 읽기
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # CREATE PROCEDURE를 ALTER PROCEDURE로 변경 (이미 존재하므로)
        # 다양한 형태의 CREATE procedure 처리
        import re
        sql_content = re.sub(
            r'CREATE\s+procedure',
            'ALTER PROCEDURE',
            sql_content,
            flags=re.IGNORECASE
        )
        
        # 프로시저 실행
        cursor.execute(sql_content)
        cursor.connection.commit()
        
        print_log(f"✓ 프로시저 업데이트 완료: {proc_name}", 'SUCCESS')
        return True
        
    except Exception as e:
        print_log(f"✗ 프로시저 업데이트 실패: {proc_name} - {str(e)}", 'ERROR')
        return False

def delete_existing_data(cursor, yyyymm, site):
    """기존 202510 데이터 삭제 (역순으로)"""
    try:
        print_log(f"기존 {yyyymm}/{site} 데이터 삭제 시작")
        
        total_deleted = 0
        for table in RESULT_TABLES:
            try:
                cursor.execute(f"""
                    DELETE FROM {table}
                    WHERE yyyymm = %s AND site = %s
                """, (yyyymm, site))
                deleted = cursor.rowcount
                total_deleted += deleted
                print_log(f"  - {table}: {deleted}건 삭제")
            except Exception as e:
                print_log(f"  - {table}: 삭제 실패 ({str(e)})", 'WARN')
        
        cursor.connection.commit()
        print_log(f"✓ 기존 데이터 삭제 완료: 총 {total_deleted}건", 'SUCCESS')
        return True
        
    except Exception as e:
        print_log(f"✗ 데이터 삭제 실패: {str(e)}", 'ERROR')
        cursor.connection.rollback()
        return False

def execute_procedure(cursor, proc_name, proc_desc, params):
    """프로시저 실행"""
    try:
        print_log(f"{proc_desc} 실행 시작: {proc_name}")
        
        # LOCK_TIMEOUT 설정
        cursor.execute("SET LOCK_TIMEOUT 60000")
        
        # 프로시저 실행
        param_str = ', '.join([f"'{p}'" for p in params])
        exec_sql = f"EXEC {proc_name} {param_str}"
        
        cursor.execute(exec_sql)
        
        # 결과 메시지 출력
        if cursor.description:
            result = cursor.fetchone()
            if result and result[0]:
                print("\n" + "="*80)
                print(result[0])
                print("="*80 + "\n")
        
        cursor.connection.commit()
        
        print_log(f"✓ {proc_desc} 실행 완료", 'SUCCESS')
        return True
        
    except Exception as e:
        error_msg = str(e)
        print_log(f"✗ {proc_desc} 실행 실패: {error_msg}", 'ERROR')
        cursor.connection.rollback()
        return False

def verify_results(cursor, yyyymm, site):
    """결과 검증"""
    try:
        print_log("결과 데이터 검증 시작")
        
        tables = [
            ('DOI_EXPEN_MATL', '경비집계'),
            ('DOI_FAB_COST', '공비배부/재공평가'),
            ('DOI_MAT_AMT', '재료비집계'),
            ('DOI_MAT_COST', '재료비배부'),
            ('DOI_STOCK_COST', '제품수불')
        ]
        
        print("\n" + "="*80)
        print(f"[결과 검증] {yyyymm}/{site} 데이터 생성 현황")
        print("="*80)
        
        for table, desc in tables:
            cursor.execute(f"""
                SELECT COUNT(*) FROM {table}
                WHERE yyyymm = %s AND site = %s
            """, (yyyymm, site))
            count = cursor.fetchone()[0]
            print(f"  {desc:20s} ({table:20s}): {count:>6d}건")
        
        print("="*80 + "\n")
        
        return True
        
    except Exception as e:
        print_log(f"✗ 결과 검증 실패: {str(e)}", 'ERROR')
        return False

def main():
    """메인 함수"""
    print_log("="*80)
    print_log("원가 프로시저 업데이트 및 202510 데이터 재생성 시작")
    print_log("="*80)
    
    conn = None
    try:
        # DB 연결
        print_log("DB 연결 중...")
        conn = pymssql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print_log("✓ DB 연결 성공", 'SUCCESS')
        
        # 1단계: 프로시저 업데이트
        print_log("\n" + "="*80)
        print_log("1단계: 프로시저 업데이트 (무결성 검증 로직 포함)")
        print_log("="*80)
        
        update_success = True
        for proc_name, file_path in PROCEDURE_FILES:
            if not update_procedure(cursor, proc_name, file_path):
                update_success = False
                print_log(f"프로시저 업데이트 실패로 중단: {proc_name}", 'ERROR')
                return 1
            time.sleep(1)  # 1초 대기
        
        if update_success:
            print_log("✓ 모든 프로시저 업데이트 완료", 'SUCCESS')
        
        # 2단계: 기존 데이터 삭제
        print_log("\n" + "="*80)
        print_log("2단계: 기존 202510 데이터 삭제")
        print_log("="*80)
        
        if not delete_existing_data(cursor, '202510', 'HQ'):
            print_log("데이터 삭제 실패로 중단", 'ERROR')
            return 1
        
        # 3단계: 프로시저 순서대로 실행
        print_log("\n" + "="*80)
        print_log("3단계: 202510 데이터 생성 (순서대로 실행)")
        print_log("="*80)
        
        for proc_name, proc_desc, params in PROCEDURES_TO_EXECUTE:
            if not execute_procedure(cursor, proc_name, proc_desc, params):
                print_log(f"프로시저 실행 실패로 중단: {proc_desc}", 'ERROR')
                return 1
            time.sleep(2)  # 2초 대기
        
        # 4단계: 결과 검증
        print_log("\n" + "="*80)
        print_log("4단계: 결과 검증")
        print_log("="*80)
        
        verify_results(cursor, '202510', 'HQ')
        
        print_log("\n" + "="*80)
        print_log("✓ 모든 작업 완료!", 'SUCCESS')
        print_log("="*80)
        
        cursor.close()
        return 0
        
    except Exception as e:
        print_log(f"✗ 오류 발생: {str(e)}", 'ERROR')
        return 1
        
    finally:
        if conn:
            conn.close()
            print_log("DB 연결 종료")

if __name__ == '__main__':
    sys.exit(main())
