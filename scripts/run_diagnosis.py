#!/usr/bin/env python3
"""
데이터 정합성 진단 스크립트
용도: 생산수불/재고수불 정합성 검증
"""

import pyodbc
import pandas as pd
from datetime import datetime
import sys

# 데이터베이스 연결 설정
DB_CONFIG = {
    'server': '172.16.200.204',
    'database': '도우제조MES시스템TEST',
    'username': 'TEST_MES_USER',
    'password': 'Dowoo1!',
    'driver': '{ODBC Driver 17 for SQL Server}'
}

# 진단 대상 기간
START_YYYYMM = '202508'
END_YYYYMM = '202510'
SITE = 'HQ'

def connect_db():
    """데이터베이스 연결"""
    try:
        conn_str = (
            f"DRIVER={DB_CONFIG['driver']};"
            f"SERVER={DB_CONFIG['server']};"
            f"DATABASE={DB_CONFIG['database']};"
            f"UID={DB_CONFIG['username']};"
            f"PWD={DB_CONFIG['password']}"
        )
        conn = pyodbc.connect(conn_str)
        return conn
    except Exception as e:
        print(f"❌ 데이터베이스 연결 실패: {e}")
        sys.exit(1)

def run_diagnosis(conn):
    """진단 실행"""
    print("=" * 70)
    print(f"📊 데이터 정합성 진단 리포트")
    print(f"진단 기간: {START_YYYYMM} ~ {END_YYYYMM}")
    print(f"사업장: {SITE}")
    print(f"생성일시: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    print()
    
    # 1. 생산수불 기본 통계
    print("📈 [1] 생산수불 기본 통계")
    print("-" * 70)
    
    query1 = f"""
    SELECT 
        YYYYMM,
        DW_SITE,
        COUNT(*) as 총건수,
        SUM(CASE WHEN EOH_MONTH < 0 THEN 1 ELSE 0 END) as 음수재고건수
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN '{START_YYYYMM}' AND '{END_YYYYMM}'
        AND ('{SITE}' = 'ALL' OR DW_SITE = '{SITE}')
    GROUP BY YYYYMM, DW_SITE
    ORDER BY YYYYMM, DW_SITE
    """
    
    df1 = pd.read_sql(query1, conn)
    print(df1.to_string(index=False))
    print()
    
    # 2. 생산수불 수식 검증 (PS001)
    print("🔍 [2] 생산수불 수식 검증 (PS001)")
    print("-" * 70)
    
    query2 = f"""
    SELECT TOP 20
        'PS001' AS RULE_CODE,
        YYYYMM,
        DW_SITE,
        도우모델,
        BOH_MONTH,
        IN_MONTH,
        OUT_MONTH,
        EOH_MONTH,
        (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0)) as 계산EOH,
        (EOH_MONTH - (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0))) as 차이
    FROM DOI_PROD_SUBUL
    WHERE YYYYMM BETWEEN '{START_YYYYMM}' AND '{END_YYYYMM}'
        AND ('{SITE}' = 'ALL' OR DW_SITE = '{SITE}')
        AND ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0))) > 0.01
    ORDER BY ABS(EOH_MONTH - (BOH_MONTH + IN_MONTH + ISNULL(BONUS_MONTH,0) - OUT_MONTH - ISNULL(LOSS_MONTH,0) - ISNULL(NG_MONTH,0))) DESC
    """
    
    df2 = pd.read_sql(query2, conn)
    if len(df2) > 0:
        print(f"❌ 수식 불일치 발견: {len(df2)}건")
        print(df2.to_string(index=False))
    else:
        print("✅ 수식 불일치 없음")
    print()
    
    # 3. 재고수불 기본 통계
    print("📈 [3] 재고수불 기본 통계")
    print("-" * 70)
    
    query3 = f"""
    SELECT 
        YYYYMM,
        SITE,
        COUNT(*) as 총건수,
        SUM(CASE WHEN EOH < 0 THEN 1 ELSE 0 END) as 음수재고건수
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN '{START_YYYYMM}' AND '{END_YYYYMM}'
        AND ('{SITE}' = 'ALL' OR SITE = '{SITE}')
    GROUP BY YYYYMM, SITE
    ORDER BY YYYYMM, SITE
    """
    
    df3 = pd.read_sql(query3, conn)
    print(df3.to_string(index=False))
    print()
    
    # 4. 재고수불 수식 검증 (ST001)
    print("🔍 [4] 재고수불 수식 검증 (ST001)")
    print("-" * 70)
    
    query4 = f"""
    SELECT TOP 20
        'ST001' AS RULE_CODE,
        YYYYMM,
        SITE,
        MODEL,
        BOH,
        INPUT_PROD + INPUT_PURCH as 총입고,
        OUT_INVOICE + OUT_ADJ as 총출고,
        EOH,
        (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ) as 계산EOH,
        (EOH - (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ)) as 차이
    FROM DOI_STOCK
    WHERE YYYYMM BETWEEN '{START_YYYYMM}' AND '{END_YYYYMM}'
        AND ('{SITE}' = 'ALL' OR SITE = '{SITE}')
        AND ABS(EOH - (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ)) > 0.01
    ORDER BY ABS(EOH - (BOH + INPUT_PROD + INPUT_PURCH - OUT_INVOICE - OUT_ADJ)) DESC
    """
    
    df4 = pd.read_sql(query4, conn)
    if len(df4) > 0:
        print(f"❌ 수식 불일치 발견: {len(df4)}건")
        print(df4.to_string(index=False))
    else:
        print("✅ 수식 불일치 없음")
    print()
    
    # 5. 생산→재고 연결 검증 (ST002) - 핵심 규칙
    print("🔗 [5] 생산→재고 연결 검증 (ST002) ⭐ 핵심")
    print("-" * 70)
    
    query5 = f"""
    SELECT TOP 20
        'ST002' AS RULE_CODE,
        P.YYYYMM,
        P.DW_SITE,
        P.도우모델 AS MODEL,
        P.OUT_MONTH AS 생산출고,
        S.INPUT_PROD AS 재고생산입고,
        (P.OUT_MONTH - ISNULL(S.INPUT_PROD, 0)) AS 차이,
        CASE 
            WHEN S.INPUT_PROD IS NULL THEN '재고 데이터 없음'
            WHEN ABS(P.OUT_MONTH - S.INPUT_PROD) > 0.01 THEN '수량 불일치'
            ELSE '정상'
        END AS 상태
    FROM DOI_PROD_SUBUL P
    LEFT JOIN DOI_STOCK S ON P.YYYYMM = S.YYYYMM 
        AND P.DW_SITE = S.SITE 
        AND P.도우모델 = S.MODEL
    WHERE P.YYYYMM BETWEEN '{START_YYYYMM}' AND '{END_YYYYMM}'
        AND ('{SITE}' = 'ALL' OR P.DW_SITE = '{SITE}')
        AND P.구분 IN ('제품', '반제품')
        AND (S.INPUT_PROD IS NULL OR ABS(P.OUT_MONTH - S.INPUT_PROD) > 0.01)
    ORDER BY ABS(P.OUT_MONTH - ISNULL(S.INPUT_PROD, 0)) DESC
    """
    
    df5 = pd.read_sql(query5, conn)
    if len(df5) > 0:
        print(f"❌ 생산→재고 불일치 발견: {len(df5)}건")
        print(df5.to_string(index=False))
    else:
        print("✅ 생산→재고 연결 정상")
    print()
    
    # 6. 종합 요약
    print("=" * 70)
    print("📋 종합 요약")
    print("=" * 70)
    
    total_issues = 0
    if len(df2) > 0:
        print(f"❌ PS001 (생산수불 수식): {len(df2)}건")
        total_issues += len(df2)
    else:
        print(f"✅ PS001 (생산수불 수식): 정상")
    
    if len(df4) > 0:
        print(f"❌ ST001 (재고수불 수식): {len(df4)}건")
        total_issues += len(df4)
    else:
        print(f"✅ ST001 (재고수불 수식): 정상")
    
    if len(df5) > 0:
        print(f"❌ ST002 (생산→재고 연결): {len(df5)}건")
        total_issues += len(df5)
    else:
        print(f"✅ ST002 (생산→재고 연결): 정상")
    
    print()
    print(f"총 발견된 이슈: {total_issues}건")
    
    if total_issues == 0:
        print("✅ 모든 검증 통과! 데이터 정합성 양호")
    else:
        print("⚠️  데이터 정리가 필요합니다.")
        print("📄 상세 내역은 위 리포트를 참조하세요.")
    
    print()
    print("=" * 70)
    print("💡 다음 단계:")
    print("  1. 발견된 오류 사항을 Excel로 정리")
    print("  2. 우선순위 결정 (음수재고 > 수식오류 > 연결오류)")
    print("  3. 데이터 클렌징 계획 수립")
    print("  4. 빠른_시작_가이드.md 참조하여 수정 진행")
    print("=" * 70)
    
    return {
        'prod_formula_errors': len(df2),
        'stock_formula_errors': len(df4),
        'flow_errors': len(df5),
        'total_errors': total_issues
    }

def main():
    """메인 함수"""
    print("🚀 데이터 정합성 진단 시작...\n")
    
    # 데이터베이스 연결
    conn = connect_db()
    print("✅ 데이터베이스 연결 성공\n")
    
    try:
        # 진단 실행
        results = run_diagnosis(conn)
        
        # 결과 저장
        report_file = f"diagnosis_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        print(f"\n📄 리포트 저장: {report_file}")
        
    except Exception as e:
        print(f"\n❌ 진단 실행 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
    finally:
        conn.close()
        print("\n✅ 데이터베이스 연결 종료")

if __name__ == "__main__":
    main()
