#!/usr/bin/env python3
"""
202510월 원가 데이터 생성 스크립트
- 7월 기본정보 테이블 복사
- 프로시저 순차 실행: 경비집계 → 공비배부 → 재료비집계 → 재료비배부 → 재공평가 → 제품수불
"""

import pymssql
import sys
from datetime import datetime

# DB 연결 정보
DB_CONFIG = {
    'server': '172.16.200.204',
    'user': 'TEST_MES_USER',
    'password': 'Dowoo1!',
    'database': '도우제조MES시스템TEST',
    'port': 1433,
    'charset': 'utf8'
}

def print_header(title):
    print("\n" + "="*70)
    print(title)
    print("="*70)

def copy_table_data(cursor, table_name, source_yyyymm, target_yyyymm, site):
    """테이블 데이터 복사 (YYYYMM을 target으로 변경)"""
    
    # 테이블별 컬럼명 확인 (대소문자 구분)
    yyyymm_col = 'yyyymm' if table_name == 'DOI_DEPT_COST' else 'YYYYMM'
    site_col = 'site' if table_name == 'DOI_DEPT_COST' else 'SITE'
    
    try:
        # 1. 기존 target 데이터 삭제
        delete_sql = f"""
            DELETE FROM {table_name} 
            WHERE {yyyymm_col} = '{target_yyyymm}' AND {site_col} = '{site}'
        """
        cursor.execute(delete_sql)
        deleted = cursor.rowcount
        
        # 2. source 데이터의 컬럼 목록 가져오기
        cursor.execute(f"SELECT TOP 1 * FROM {table_name} WHERE {yyyymm_col} = '{source_yyyymm}' AND {site_col} = '{site}'")
        
        if cursor.description is None:
            print(f"   ⚠ {table_name}: {source_yyyymm}/{site} 데이터 없음")
            return 0, 0
            
        columns = [desc[0] for desc in cursor.description]
        
        # 3. YYYYMM 컬럼만 target으로 변경하여 복사
        select_parts = []
        for col in columns:
            if col.upper() == 'YYYYMM':
                select_parts.append(f"'{target_yyyymm}' AS {col}")
            else:
                select_parts.append(f"[{col}]")
        
        insert_sql = f"""
            INSERT INTO {table_name} ([{'], ['.join(columns)}])
            SELECT {', '.join(select_parts)}
            FROM {table_name}
            WHERE {yyyymm_col} = '{source_yyyymm}' AND {site_col} = '{site}'
        """
        
        cursor.execute(insert_sql)
        inserted = cursor.rowcount
        
        return deleted, inserted
        
    except Exception as e:
        print(f"   ✗ 오류: {str(e)}")
        raise

def execute_procedure(cursor, proc_name, yyyymm, site, selcode=None):
    """프로시저 실행"""
    
    try:
        # Lock timeout 30초로 설정
        cursor.execute("SET LOCK_TIMEOUT 30000")
        
        # 프로시저별 파라미터 구성
        if proc_name in ['Gen_EXPEN_MATL', 'UP_DOI_FAB_COST']:
            # @YYYYMM, @SITE만 필요
            sql = f"EXEC {proc_name} @YYYYMM='{yyyymm}', @SITE='{site}'"
            
        elif proc_name in ['UP_DOI_MAT_AMT', 'UP_DOI_MAT_COST', 'UP_DOI_COST_MAT']:
            # @YYYYMM, @SITE, @SELCODE 필요
            sql = f"EXEC {proc_name} @YYYYMM='{yyyymm}', @SITE='{site}', @SELCODE='{selcode}'"
            
        elif proc_name == 'UP_DOI_STOCK_COST':
            # OUTPUT 파라미터 사용
            sql = f"""
                DECLARE @R_Message NVARCHAR(MAX) = '';
                EXEC {proc_name} @YYYYMM='{yyyymm}', @SITE='{site}', @R_Message=@R_Message OUTPUT;
                SELECT @R_Message AS retMessage;
            """
        
        cursor.execute(sql)
        
        # 결과 메시지 출력
        try:
            row = cursor.fetchone()
            if row:
                if hasattr(row, 'retMessage') and row.retMessage:
                    for line in row.retMessage.split('\n'):
                        if line.strip():
                            print(f"     {line.strip()}")
                elif isinstance(row, dict) and 'retMessage' in row and row['retMessage']:
                    for line in row['retMessage'].split('\n'):
                        if line.strip():
                            print(f"     {line.strip()}")
        except:
            pass  # 결과가 없어도 정상
            
        return True
        
    except Exception as e:
        error_msg = str(e)
        # SQL Server 에러 메시지에서 retMessage 추출
        if 'retMessage' in error_msg or '[ERROR]' in error_msg:
            print(f"     {error_msg}")
        else:
            print(f"   ✗ 오류: {error_msg}")
        return False

def main():
    print_header("📊 202510월 원가 데이터 생성")
    print(f"실행시각: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    SOURCE_YYYYMM = '202507'
    TARGET_YYYYMM = '202510'
    SITE = 'HQ'
    SELCODE = 'HQ'
    
    # 복사할 기본 정보 테이블
    BASE_TABLES = [
        ('DOI_ACCT', '원가계정정보'),
        ('DOI_DEPT', '부서정보'),
        ('DOI_DEPT_COST', '부서별비용'),
        ('DOI_MODEL_MAST', '면적정보'),
        ('DOI_CASSETTE_RESC', '카세트비용'),
        ('DOI_BOM_MAST', '자재BOM'),
        ('DOI_MATERIAL_RESC', '자재투입'),
        ('DOI_STOCK_BOH', '기초재고'),
    ]
    
    # 실행할 프로시저
    PROCEDURES = [
        ('Gen_EXPEN_MATL', '1. 경비집계'),
        ('UP_DOI_FAB_COST', '2. 공비배부'),
        ('UP_DOI_MAT_AMT', '3. 재료비집계'),
        ('UP_DOI_MAT_COST', '4. 재료비배부'),
        ('UP_DOI_COST_MAT', '5. 재공평가'),
        ('UP_DOI_STOCK_COST', '6. 제품수불'),
    ]
    
    conn = None
    try:
        # DB 연결
        print("\n📡 DB 연결 중...")
        conn = pymssql.connect(**DB_CONFIG, autocommit=False)
        cursor = conn.cursor(as_dict=True)
        print("✓ 연결 성공\n")
        
        # ========================================
        # STEP 1: 기본 정보 테이블 복사
        # ========================================
        print_header(f"STEP 1: 기본 정보 테이블 복사 ({SOURCE_YYYYMM} → {TARGET_YYYYMM})")
        
        for i, (table, desc) in enumerate(BASE_TABLES, 1):
            print(f"\n[{i}/{len(BASE_TABLES)}] {desc} ({table})")
            deleted, inserted = copy_table_data(cursor, table, SOURCE_YYYYMM, TARGET_YYYYMM, SITE)
            print(f"   → {deleted}건 삭제, {inserted}건 복사 완료")
        
        conn.commit()
        print("\n✓ 기본 정보 테이블 복사 완료")
        
        # ========================================
        # STEP 2: 원가 프로시저 순차 실행
        # ========================================
        print_header("STEP 2: 원가 프로시저 순차 실행")
        
        success_count = 0
        for proc_name, desc in PROCEDURES:
            print(f"\n{desc} ({proc_name})")
            print("-" * 70)
            
            success = execute_procedure(cursor, proc_name, TARGET_YYYYMM, SITE, SELCODE)
            
            if success:
                conn.commit()
                print(f"   ✓ {desc} 완료")
                success_count += 1
            else:
                conn.rollback()
                print(f"   ✗ {desc} 실패")
                
                # 첫 번째 단계(경비집계) 실패시 중단
                if proc_name == 'Gen_EXPEN_MATL':
                    print("\n⚠ 경비집계 실패로 작업을 중단합니다")
                    break
        
        # ========================================
        # STEP 3: 결과 확인
        # ========================================
        print_header("STEP 3: 생성 결과 확인")
        
        result_tables = [
            ('DOI_EXPEN_MATL', '경비집계', 'YYYYMM', 'SITE'),
            ('DOI_FAB_COST', '공비배부/재공평가', 'YYYYMM', 'SITE'),
            ('DOI_MAT_AMT', '재료비집계', 'YYYYMM', 'SITE'),
            ('DOI_MAT_COST', '재료비배부', 'YYYYMM', 'SITE'),
            ('DOI_STOCK_COST', '제품수불', 'yyyymm', 'site'),
        ]
        
        print()
        for table, desc, yyyymm_col, site_col in result_tables:
            try:
                cursor.execute(f"""
                    SELECT COUNT(*) as cnt 
                    FROM {table} 
                    WHERE {yyyymm_col} = '{TARGET_YYYYMM}' AND {site_col} = '{SITE}'
                """)
                result = cursor.fetchone()
                count = result['cnt'] if result else 0
                
                status = "✓" if count > 0 else "✗"
                print(f"{status} {desc:20} ({table:20}): {count:>6}건")
                
            except Exception as e:
                print(f"✗ {desc:20} ({table:20}): 확인 실패")
        
        # ========================================
        # 완료
        # ========================================
        print_header(f"✅ 작업 완료 ({success_count}/{len(PROCEDURES)} 성공)")
        
    except Exception as e:
        print(f"\n❌ 오류 발생: {str(e)}")
        if conn:
            conn.rollback()
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
            print("\n📡 DB 연결 종료\n")

if __name__ == '__main__':
    main()
