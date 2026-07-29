# VN 프로시저 백업 / 복구 안내 (2026-07-29)

## 상황
- 원가 DB `10.100.40.250`(SPS009 / 도우제조MES시스템TEST)가 **202510/HQ 스냅샷 상태로 되돌려짐** — 202606 VN 데이터·프로시저가 모두 사라짐.
- `10.100.40.244` 는 현재 접속 불가(TCP timeout).
- 현재 250에는 doi_stco 등 원천/결과 테이블에 **VN 202606 행이 0건**, VN/UP_VN/DOI 정산 프로시저도 없음.

## 복구 가능성 요약
| 대상 | 복구 가능 | 방법 |
|---|---|---|
| **VN 프로시저(14개)** | ✅ 가능 | 이 폴더 SQL 재배포 |
| **202606 VN 행-level 데이터** | ❌ 세션에서 불가 | 원천 재업로드 + 정산 재실행으로 **재생성** |

세션에는 집계값(매출원가·영업이익 등 총액)만 남아있고, 테이블 원본(행 단위)은 없습니다.

## 백업된 프로시저 (14)
- 보고서: `VN_PL_ByModel`, `VN_PL_ByModel_Detail`(신규 손익구조), `VN_PL_Qty`, `VN_TotalCost_Tree`,
  `VN_ManufacturingExpenseByDept`(+`_Cum`), `VN_ManufacturingExpenseByModel`,
  `VN_SalesAdminByDept`(+`_Cum`), `VN_SalesAdminByModel`
- 정산: `UP_VN_COST`, `UP_VN_EXPEN_MATL`, `UP_VN_SALE_COST`, `UP_VN_MAT_COST`
- 모두 `CREATE OR ALTER` 로 정리됨(재실행 가능).

## 복구 절차
1. **대상 DB 확정** — 244 복구 접속 또는 250에 재구축할지 결정.
2. **프로시저 재배포**: 이 폴더의 14개 `.sql`을 대상 DB에 실행.
3. **의존 오브젝트 확인/확보** (현재 250에 없음):
   - 프로시저: `DOI_변동비_ByModel`, `DOI_고정비_ByModel` (← `VN_TotalCost_Tree`가 호출)
   - 테이블: `DOI_원장상계` (← `VN_PL_ByModel_Detail` #MODEL)
4. **데이터 재생성**: 원천(원장 `doi_dept_cost`, 매출 `doi_sale_resc`/`doi_invoice_resc`, 계정 `doi_acct`) 202606 VN을 재업로드 → `UP_VN_MAT_COST → UP_VN_EXPEN_MATL → UP_VN_COST → UP_VN_SALE_COST` 순 정산 재실행.

## 미포함/주의
- 원천 데이터(원장·매출·계정 원본)는 백업에 없음(ERP/업로드 원본 필요).
- `VN_ManufacturingExpenseByModel_Cum`, `VN_SalesAdminByModel_Cum` 등 존재 시 별도 확보 필요(이번 세션 덤프 없음).
